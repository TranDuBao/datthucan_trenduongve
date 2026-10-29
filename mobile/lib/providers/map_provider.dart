import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../models/place_model.dart';
import '../models/route_model.dart';
import '../services/places_service.dart';
import '../services/directions_service.dart';
import '../services/category_service.dart';
import '../config/api_config.dart';

enum MapState { idle, searchingOrigin, searchingDestination, loadingRoute, showingRoute }
enum FoodRouteOption { takeaway, preOrder, dineIn }

class MapProvider extends ChangeNotifier {
  final PlacesService _placesService = PlacesService();
  final DirectionsService _directionsService = DirectionsService();

  // ── Food Route Option (Đặt thức ăn trên đường về) ─────────────────────────
  FoodRouteOption _foodRouteOption = FoodRouteOption.takeaway;
  FoodRouteOption get foodRouteOption => _foodRouteOption;

  void changeFoodRouteOption(FoodRouteOption option) {
    _foodRouteOption = option;
    notifyListeners();
  }

  int get travelMinutes {
    if (_currentRoute != null && _currentRoute!.totalDurationSeconds > 0) {
      final mins = (_currentRoute!.totalDurationSeconds / 60).round();
      return mins > 0 ? mins : 12;
    }
    return 12;
  }

  int get prepMinutes {
    switch (_foodRouteOption) {
      case FoodRouteOption.takeaway:
        return 10;
      case FoodRouteOption.preOrder:
        return 15;
      case FoodRouteOption.dineIn:
        return 20;
    }
  }

  String get pickupReadyTimeText => 'Chuẩn bị ~$prepMinutes phút';

  // ── Controllers ──────────────────────────────────────────────────────────
  final MapController mapController = MapController();
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  final TextEditingController foodKeywordController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  MapState _state = MapState.idle;
  MapState get state => _state;

  // ── Food Along Route Search ───────────────────────────────────────────────
  String _foodKeyword = '';
  String get foodKeyword => _foodKeyword;

  bool _isSearchingFood = false;
  bool get isSearchingFood => _isSearchingFood;

  int _routeRequestId = 0;
  Timer? _foodSearchDebounce;
  Timer? _errorDismissTimer;

  void setFoodKeyword(String kw) {
    _foodKeyword = kw.trim();
    if (foodKeywordController.text != kw) {
      foodKeywordController.text = kw;
    }
    notifyListeners();
    _foodSearchDebounce?.cancel();
    _foodSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (_currentRoute != null) {
        fetchRouteRestaurants();
      }
    });
  }

  void clearFoodKeyword() {
    _foodSearchDebounce?.cancel();
    _foodKeyword = '';
    foodKeywordController.clear();
    notifyListeners();
    if (_currentRoute != null) {
      fetchRouteRestaurants();
    }
  }

  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Location ──────────────────────────────────────────────────────────────
  LatLng _currentPosition = const LatLng(ApiConfig.defaultLat, ApiConfig.defaultLng);
  LatLng get currentPosition => _currentPosition;

  // ── Map ready state ───────────────────────────────────────────────────────
  bool _mapReady = false;
  LatLng? _pendingMoveTarget;
  double? _pendingMoveZoom;

  /// Called by FlutterMap's onMapReady callback once the map is fully attached
  void onMapReady() {
    _mapReady = true;
    if (_pendingMoveTarget != null) {
      mapController.move(_pendingMoveTarget!, _pendingMoveZoom ?? 14);
      _pendingMoveTarget = null;
      _pendingMoveZoom = null;
    }
  }

  // ── Places ────────────────────────────────────────────────────────────────
  PlaceModel? _originPlace;
  PlaceModel? _destinationPlace;
  PlaceModel? get originPlace => _originPlace;
  PlaceModel? get destinationPlace => _destinationPlace;

  List<PlaceModel> _suggestions = [];
  List<PlaceModel> get suggestions => _suggestions;

  bool _showSuggestions = false;
  bool get showSuggestions => _showSuggestions;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  // ── Route ─────────────────────────────────────────────────────────────────
  RouteModel? _currentRoute;
  RouteModel? get currentRoute => _currentRoute;

  RouteModel? _originalRoute;
  RouteModel? get originalRoute => _originalRoute ?? _currentRoute;

  // ── Stopover (Ghé quán Q: A -> Q -> B) ───────────────────────────────────
  RouteModel? _stopoverRoute;
  RouteModel? get stopoverRoute => _stopoverRoute;

  Map<String, dynamic>? _selectedStopoverStore;
  Map<String, dynamic>? get selectedStopoverStore => _selectedStopoverStore;

  Map<String, dynamic>? _selectedStopoverFood;
  Map<String, dynamic>? get selectedStopoverFood => _selectedStopoverFood;

  bool _isLoadingStopoverRoute = false;
  bool get isLoadingStopoverRoute => _isLoadingStopoverRoute;

  // ── Active Order Guidance (Sau khi đặt đơn thành công) ───────────────────
  Map<String, dynamic>? _activeStopoverOrder;
  Map<String, dynamic>? get activeStopoverOrder => _activeStopoverOrder;

  bool _isOrderPickedUp = false;
  bool get isOrderPickedUp => _isOrderPickedUp;

  LatLng? get activeStopoverLatLng {
    if (_activeStopoverOrder != null) {
      final lat = (_activeStopoverOrder!['lat'] as num?)?.toDouble();
      final lng = (_activeStopoverOrder!['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    if (_selectedStopoverStore != null) {
      final lat = (_selectedStopoverStore!['lat'] as num?)?.toDouble();
      final lng = (_selectedStopoverStore!['lng'] as num?)?.toDouble();
      if (lat != null && lng != null) return LatLng(lat, lng);
    }
    return null;
  }

  void setActiveStopoverOrder(Map<String, dynamic>? order) {
    _activeStopoverOrder = order;
    _isOrderPickedUp = false;
    notifyListeners();
  }

  void clearActiveStopoverOrder() {
    _activeStopoverOrder = null;
    _isOrderPickedUp = false;
    notifyListeners();
  }

  /// Đánh dấu trạng thái đã lấy món (hoặc bật lại hướng dẫn nếu bấm nhầm)
  void markOrderPickedUp(bool pickedUp) {
    _isOrderPickedUp = pickedUp;
    notifyListeners();
  }

  /// Hoàn tất ghé quán:
  /// - Nếu có điểm đích B tiếp theo: Chuyển sang chặng Quán -> B
  /// - Nếu đích đến chính là quán ăn: Dọn sạch lộ trình (clearAll) để tránh hiện thẻ "Xác nhận lộ trình ghé lấy"
  Future<void> finishStopoverOrder() async {
    final storeLocation = activeStopoverLatLng;
    final storeName = _activeStopoverOrder?['tenQuan'] ?? 'Quán ăn';
    final storeAddress = _activeStopoverOrder?['diaChi'] ?? '';
    final dest = _destinationPlace;

    _isOrderPickedUp = false;
    clearActiveStopoverOrder();
    clearStopover();

    // Nếu người dùng có điểm đến đích khác với quán (A -> Q -> B):
    if (dest != null && storeLocation != null) {
      final bool isDestStore = (dest.latLng.latitude - storeLocation.latitude).abs() < 0.0001 &&
          (dest.latLng.longitude - storeLocation.longitude).abs() < 0.0001;

      if (!isDestStore) {
        // Chuyển điểm xuất phát thành Quán ăn vừa lấy món -> Dẫn đường tiếp đến B
        _originPlace = PlaceModel(
          id: 'pickup_done_loc',
          name: storeName,
          address: storeAddress,
          latLng: storeLocation,
        );
        originController.text = storeName;
        await fetchRoute();
        return;
      }
    }

    // Nếu điểm đến chính là quán ăn: Dọn sạch hoàn toàn lộ trình để về màn hình chính bình thường
    clearAll();
  }

  /// Giữ lại confirmPickedUpFood để tương thích ngược
  Future<void> confirmPickedUpFood() async {
    await finishStopoverOrder();
  }

  /// Dẫn đường trực tiếp đến quán ăn theo đơn hàng
  Future<void> navigateToOrderStore({
    required int orderId,
    required String storeName,
    required String storeAddress,
    required LatLng storeLatLng,
    String? pickupTime,
    String? status,
  }) async {
    setActiveStopoverOrder({
      'maDonHang': orderId,
      'tenQuan': storeName,
      'diaChi': storeAddress,
      'lat': storeLatLng.latitude,
      'lng': storeLatLng.longitude,
      'trangThai': status ?? 'Đang chuẩn bị',
      'thoiGianHenNhan': pickupTime ?? 'Ghé lấy ngay',
    });

    if (_originPlace == null) {
      _originPlace = PlaceModel(
        id: 'gps_origin',
        name: currentLocationText,
        address: currentLocationText,
        latLng: _currentPosition,
      );
      originController.text = _originPlace!.name;
    }

    // Nếu chưa có điểm đến hoặc điểm đến đang trùng quán, gán đích đến là quán
    if (_destinationPlace == null ||
        ((_destinationPlace!.latLng.latitude - storeLatLng.latitude).abs() < 0.0001 &&
         (_destinationPlace!.latLng.longitude - storeLatLng.longitude).abs() < 0.0001)) {
      _destinationPlace = PlaceModel(
        id: 'store_dest_$orderId',
        name: storeName,
        address: storeAddress,
        latLng: storeLatLng,
      );
      destinationController.text = storeName;
    }

    _moveCamera(storeLatLng, zoom: 15);
    await fetchRoute();
    notifyListeners();
  }

  List<dynamic> _routeRestaurants = [];
  List<dynamic> get routeRestaurants => _routeRestaurants;

  TravelMode _travelMode = TravelMode.car;
  TravelMode get travelMode => _travelMode;

  bool _showRouteDetails = false;
  bool get showRouteDetails => _showRouteDetails;

  /// Focus Mode: ẩn search bar và route card để xem bản đồ rõ hơn
  bool _isFocusMode = false;
  bool get isFocusMode => _isFocusMode;

  void toggleFocusMode() {
    _isFocusMode = !_isFocusMode;
    notifyListeners();
  }

  void exitFocusMode() {
    if (_isFocusMode) {
      _isFocusMode = false;
      notifyListeners();
    }
  }

  Timer? _debounceTimer;

  // ─────────────────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    await _requestLocationPermission();
    notifyListeners();
  }

  Future<void> _requestLocationPermission() async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      await _getCurrentLocation();
    } catch (e) {
      try {
        await _getCurrentLocation();
      } catch (_) {
        _errorMessage = 'Không thể lấy vị trí hiện tại';
      }
    }

    _isLoadingLocation = false;
    notifyListeners();
  }

  /// Lấy vị trí thông qua địa chỉ IP (rất hữu ích khi chạy trên emulator hoặc không có GPS)
  Future<LatLng?> _getLocationByIP() async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final double? lat = (data['latitude'] as num?)?.toDouble();
        final double? lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          debugPrint('[MapProvider] [Info] Lấy vị trí thành công qua IP (ipapi.co): $lat, $lon');
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('[MapProvider] [Warn] Thử lấy vị trí qua IP (ipapi.co) thất bại: $e');
    }

    try {
      final response = await http.get(Uri.parse('https://ipinfo.io/json')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final String? loc = data['loc']?.toString();
        if (loc != null && loc.contains(',')) {
          final parts = loc.split(',');
          final double? lat = double.tryParse(parts[0]);
          final double? lon = double.tryParse(parts[1]);
          if (lat != null && lon != null) {
            debugPrint('[MapProvider] [Info] Lấy vị trí thành công qua IP (ipinfo.io): $lat, $lon');
            return LatLng(lat, lon);
          }
        }
      }
    } catch (e) {
      debugPrint('[MapProvider] [Warn] Thử lấy vị trí qua IP (ipinfo.io) thất bại: $e');
    }

    return null;
  }

  String get currentLocationText {
    if (_originPlace != null) {
      if (_originPlace!.name.isNotEmpty) return _originPlace!.name;
      if (_originPlace!.address.isNotEmpty) return _originPlace!.address;
    }
    return 'Trần Quý Cáp, Bình Thạnh';
  }

  Future<void> _getCurrentLocation() async {
    LatLng? detectedPosition;
    bool isMockLocation = false;

    try {
      debugPrint('[MapProvider] [Info] Đang thử lấy vị trí bằng GPS của thiết bị...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      final gpsLatLng = LatLng(position.latitude, position.longitude);

      final double latDiff = (gpsLatLng.latitude - 37.422).abs();
      final double lonDiff = (gpsLatLng.longitude - (-122.084)).abs();
      if (latDiff < 0.01 && lonDiff < 0.01) {
        isMockLocation = true;
        debugPrint('[MapProvider] [Info] Phát hiện tọa độ máy ảo mặc định (Mỹ). Sẽ dùng IP để chuyển về Việt Nam.');
      } else {
        detectedPosition = gpsLatLng;
        debugPrint('[MapProvider] [Info] Lấy vị trí GPS thực tế thành công: ${detectedPosition.latitude}, ${detectedPosition.longitude}');
      }
    } catch (e) {
      debugPrint('[MapProvider] [Error] Lấy GPS thiết bị thất bại (hoặc không bật định vị): $e');
    }

    if (detectedPosition == null || isMockLocation) {
      final ipPos = await _getLocationByIP();
      if (ipPos != null) {
        detectedPosition = ipPos;
      } else {
        debugPrint('[MapProvider] [Info] Đang dùng máy ảo hoặc chưa bật GPS. Mặc định chọn Trần Quý Cáp, Bình Thạnh (10.8038, 106.6975).');
        detectedPosition = const LatLng(ApiConfig.defaultLat, ApiConfig.defaultLng);
      }
    }

    _currentPosition = detectedPosition;
    _moveCamera(_currentPosition, zoom: 16);

    final place = await _placesService.reverseGeocode(_currentPosition);
    _originPlace = place ?? PlaceModel(
      id: 'current_loc',
      name: 'Trần Quý Cáp, Bình Thạnh',
      address: 'Trần Quý Cáp, Phường 11, Bình Thạnh, TP. Hồ Chí Minh',
      latLng: _currentPosition,
    );
    originController.text = _originPlace!.name;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Search / Autocomplete
  // ─────────────────────────────────────────────────────────────────────────

  void onSearchChanged(String query, {required bool isOrigin}) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      _suggestions = [];
      _showSuggestions = false;
      _isSearching = false;
      notifyListeners();
      return;
    }

    _state = isOrigin ? MapState.searchingOrigin : MapState.searchingDestination;
    _isSearching = true;

    // Không gọi notifyListeners() mỗi phím bấm nếu gợi ý đã mở sẵn
    // để tránh rebuild TextField làm ngắt bộ gõ tiếng Việt Telex/VNI
    bool needNotifyNow = !_showSuggestions;
    _showSuggestions = true;
    if (needNotifyNow) {
      notifyListeners();
    }

    final controller = isOrigin ? originController : destinationController;
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final currentText = controller.text.trim();
      if (currentText.isEmpty) {
        _isSearching = false;
        notifyListeners();
        return;
      }
      final results = await _placesService.getAutocompleteSuggestions(
        currentText,
        biasLocation: _currentPosition,
      );
      _suggestions = results;
      _isSearching = false;
      notifyListeners();
    });
  }

  Future<void> selectPlace(PlaceModel place, {required bool isOrigin}) async {
    _showSuggestions = false;
    _suggestions = [];
    notifyListeners();

    if (isOrigin) {
      _originPlace = place;
      originController.text = place.name;
      _moveCamera(place.latLng);
    } else {
      _destinationPlace = place;
      destinationController.text = place.name;
      _moveCamera(place.latLng);
    }

    if (_originPlace != null && _destinationPlace != null) {
      await fetchRoute();
    }

    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Route
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> fetchRoute() async {
    if (_originPlace == null || _destinationPlace == null) return;

    final int requestId = ++_routeRequestId;
    _state = MapState.loadingRoute;
    _errorMessage = null;
    _errorDismissTimer?.cancel();
    notifyListeners();

    final stopoverLoc = activeStopoverLatLng;
    final bool hasStopover = stopoverLoc != null &&
        ((stopoverLoc.latitude - _destinationPlace!.latLng.latitude).abs() >= 0.0001 ||
         (stopoverLoc.longitude - _destinationPlace!.latLng.longitude).abs() >= 0.0001);

    RouteModel? baselineRoute;
    RouteModel? detourRoute;

    if (hasStopover) {
      // 1. Tuyến đường cơ sở A -> B
      baselineRoute = await _directionsService.getDirections(
        origin: _originPlace!.latLng,
        destination: _destinationPlace!.latLng,
        mode: _travelMode,
      );

      // 2. Tuyến đường ghé quán A -> Q -> B (có 2 chặng: Hiện tại -> Quán -> Đích)
      detourRoute = await _directionsService.getDirections(
        origin: _originPlace!.latLng,
        destination: _destinationPlace!.latLng,
        stopover: stopoverLoc,
        mode: _travelMode,
      );
    } else {
      baselineRoute = await _directionsService.getDirections(
        origin: _originPlace!.latLng,
        destination: _destinationPlace!.latLng,
        mode: _travelMode,
      );
    }

    // Bỏ qua kết quả nếu có request mới hơn đang chạy
    if (requestId != _routeRequestId) {
      debugPrint('[MapProvider] [Info] Bỏ qua kết quả routing cũ (requestId: $requestId)');
      return;
    }

    final activeRoute = detourRoute ?? baselineRoute;
    if (activeRoute != null) {
      _currentRoute = activeRoute;
      _originalRoute = baselineRoute ?? activeRoute;
      _stopoverRoute = detourRoute;
      _state = MapState.showingRoute;
      _showRouteDetails = true;
      _fitBoundsToRoute(activeRoute.simplifiedPolylinePoints);
      notifyListeners();

      await fetchRouteRestaurants();
    } else {
      _errorMessage = 'Không tìm thấy đường đi. Vui lòng thử lại.';
      _state = MapState.idle;
      _routeRestaurants = [];
      _errorDismissTimer?.cancel();
      _errorDismissTimer = Timer(const Duration(seconds: 4), () {
        if (_errorMessage != null) {
          _errorMessage = null;
          notifyListeners();
        }
      });
    }

    notifyListeners();
  }

  Future<void> fetchRouteRestaurants() async {
    final route = _originalRoute ?? _currentRoute;
    if (route == null) return;

    // Chỉ tìm kiếm và hiển thị quán khi người dùng đã nhập món ăn tìm kiếm
    if (_foodKeyword.trim().isEmpty) {
      _routeRestaurants = [];
      _isSearchingFood = false;
      notifyListeners();
      return;
    }

    _isSearchingFood = true;
    notifyListeners();

    try {
      _routeRestaurants = await CategoryService.fetchRestaurantsAlongRoute(
        route.simplifiedPolylinePoints,
        keyword: _foodKeyword.trim(),
      );
    } catch (_) {
      _routeRestaurants = [];
    }

    _isSearchingFood = false;
    notifyListeners();
  }

  Future<void> selectStopoverRestaurant(Map<String, dynamic> store, [Map<String, dynamic>? food]) async {
    _selectedStopoverStore = store;
    _selectedStopoverFood = food ?? (store['primaryFood'] as Map<String, dynamic>?);
    notifyListeners();

    final sLat = (store['lat'] as num?)?.toDouble();
    final sLng = (store['lng'] as num?)?.toDouble();

    if (sLat != null && sLng != null && _originPlace != null && _destinationPlace != null) {
      final int stopoverReqId = ++_routeRequestId;
      _isLoadingStopoverRoute = true;
      notifyListeners();

      final detour = await _directionsService.getDirections(
        origin: _originPlace!.latLng,
        destination: _destinationPlace!.latLng,
        stopover: LatLng(sLat, sLng),
        mode: _travelMode,
      );

      if (stopoverReqId != _routeRequestId) return;

      if (detour != null) {
        _stopoverRoute = detour;
        _fitBoundsToRoute(detour.simplifiedPolylinePoints);
      }
      _isLoadingStopoverRoute = false;
      notifyListeners();
    }
  }

  void clearStopover() {
    _stopoverRoute = null;
    _selectedStopoverStore = null;
    _selectedStopoverFood = null;
    if (_originalRoute != null) {
      _fitBoundsToRoute(_originalRoute!.polylinePoints);
    }
    notifyListeners();
  }

  void changeTravelMode(TravelMode mode) {
    _travelMode = mode;
    notifyListeners();
    if (_originPlace != null && _destinationPlace != null) {
      fetchRoute();
    }
  }

  void _fitBoundsToRoute(List<LatLng> points) {
    if (points.isEmpty || !_mapReady) return;
    try {
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(60.0),
        ),
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Map tap — đặt điểm trực tiếp
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> onMapTapped(LatLng position) async {
    if (_originPlace == null) {
      final place = await _placesService.reverseGeocode(position);
      _originPlace = place ??
          PlaceModel(
            id: 'tap_origin',
            name: 'Điểm bắt đầu',
            address: '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
            latLng: position,
          );
      originController.text = _originPlace!.name;
    } else if (_destinationPlace == null) {
      final place = await _placesService.reverseGeocode(position);
      _destinationPlace = place ??
          PlaceModel(
            id: 'tap_dest',
            name: 'Điểm đến',
            address: '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
            latLng: position,
          );
      destinationController.text = _destinationPlace!.name;
      await fetchRoute();
    }
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _moveCamera(LatLng position, {double zoom = 14}) {
    if (!_mapReady) {
      _pendingMoveTarget = position;
      _pendingMoveZoom = zoom;
      return;
    }
    try {
      mapController.move(position, zoom);
    } catch (_) {}
  }

  void clearAll() {
    _originPlace = null;
    _destinationPlace = null;
    _currentRoute = null;
    _originalRoute = null;
    _stopoverRoute = null;
    _selectedStopoverStore = null;
    _selectedStopoverFood = null;
    _activeStopoverOrder = null;
    _isOrderPickedUp = false;
    _foodKeyword = '';
    _routeRestaurants = [];
    _showRouteDetails = false;
    _isFocusMode = false;
    _state = MapState.idle;
    _errorMessage = null;
    originController.clear();
    destinationController.clear();
    foodKeywordController.clear();
    notifyListeners();
  }

  void swapPlaces() {
    final temp = _originPlace;
    _originPlace = _destinationPlace;
    _destinationPlace = temp;
    originController.text = _originPlace?.name ?? '';
    destinationController.text = _destinationPlace?.name ?? '';
    if (_originPlace != null && _destinationPlace != null) {
      fetchRoute();
    }
    notifyListeners();
  }

  void dismissSuggestions() {
    _showSuggestions = false;
    _suggestions = [];
    notifyListeners();
  }

  Future<void> useCurrentLocationAsOrigin() async {
    final pos = _currentPosition;
    PlaceModel? place = await _placesService.reverseGeocode(pos);
    place ??= PlaceModel(
      id: 'current_loc',
      name: 'Vị trí của tôi',
      address: '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
      latLng: pos,
    );
    _originPlace = place;
    originController.text = place.name;
    _showSuggestions = false;
    _suggestions = [];
    if (_destinationPlace != null) {
      await fetchRoute();
    }
    notifyListeners();
  }

  Future<void> goToMyLocation() async {
    _isLoadingLocation = true;
    notifyListeners();
    await _getCurrentLocation();
    _isLoadingLocation = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _foodSearchDebounce?.cancel();
    _errorDismissTimer?.cancel();
    originController.dispose();
    destinationController.dispose();
    foodKeywordController.dispose();
    mapController.dispose();
    super.dispose();
  }
}
