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
import '../services/navigation_progress_service.dart';
import '../widgets/navigation_arrival_modals.dart';

enum MapState { idle, searchingOrigin, searchingDestination, loadingRoute, showingRoute }
enum FoodRouteOption { takeaway, preOrder, dineIn }

class MapProvider extends ChangeNotifier {
  final PlacesService _placesService = PlacesService();
  final DirectionsService _directionsService = DirectionsService();
  final NavigationProgressService _navService = NavigationProgressService();

  NavigationProgressService get navService => _navService;
  BuildContext? navigationContext;

  ValueNotifier<List<LatLng>> get remainingLeg1 => _navService.remainingLeg1;
  ValueNotifier<List<LatLng>> get remainingLeg2 => _navService.remainingLeg2;
  bool get isNavigating => _navService.isNavigating;

  MapProvider() {
    _navService.onArrivedAtStore = () {
      _onArrivedAtStore();
    };
    _navService.onArrivedAtDestination = () {
      _onArrivedAtDestination();
    };
    _navService.currentUserPosition.addListener(() {
      final pos = _navService.currentUserPosition.value;
      if (pos != null &&
          pos.latitude >= 8.0 && pos.latitude <= 24.0 &&
          pos.longitude >= 102.0 && pos.longitude <= 112.0) {
        _currentPosition = pos;
        notifyListeners();
      }
    });
  }

  void _onArrivedAtStore() {
    _isOrderPickedUp = false;
    notifyListeners();

    if (navigationContext != null) {
      final storeName = _activeStopoverOrder?['tenQuan'] ?? _selectedStopoverStore?['tenQuan'] ?? 'Quán ăn';
      final orderCode = _activeStopoverOrder?['maDonHang']?.toString() ?? _activeStopoverOrder?['orderId']?.toString();
      StoreArrivalModal.show(
        context: navigationContext!,
        storeName: storeName,
        orderCode: orderCode,
        onConfirmPickedUp: () {
          confirmPickedUpFood();
        },
      );
    }
  }

  void _onArrivedAtDestination() {
    _navService.stopNavigation();
    notifyListeners();

    if (navigationContext != null) {
      RouteCompletedModal.show(
        context: navigationContext!,
        onFinish: () {
          clearAll();
        },
      );
    }
  }

  void _startNavService() {
    if (_stopoverRoute != null && _stopoverRoute!.legs.length >= 2) {
      _navService.startNavigation(
        leg1Points: _stopoverRoute!.legs[0].polylinePoints,
        leg2Points: _stopoverRoute!.legs[1].polylinePoints,
        storeLatLng: activeStopoverLatLng,
        destinationLatLng: _destinationPlace?.latLng,
        initialUserPosition: _currentPosition,
      );
    } else if (_stopoverRoute != null && _stopoverRoute!.simplifiedPolylinePoints.isNotEmpty) {
      _navService.startNavigation(
        leg1Points: _stopoverRoute!.simplifiedPolylinePoints,
        storeLatLng: activeStopoverLatLng,
        destinationLatLng: _destinationPlace?.latLng,
        initialUserPosition: _currentPosition,
      );
    } else if (_originalRoute != null && _originalRoute!.simplifiedPolylinePoints.isNotEmpty) {
      _navService.startNavigation(
        leg1Points: _originalRoute!.simplifiedPolylinePoints,
        destinationLatLng: _destinationPlace?.latLng,
        initialUserPosition: _currentPosition,
      );
    }
  }

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
      return mins > 0 ? mins : 1;
    }
    return 0;
  }

  int get prepMinutes {
    switch (_foodRouteOption) {
      case FoodRouteOption.takeaway:
        return 10;
      case FoodRouteOption.preOrder:
        return 45;
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
  LatLng get currentPosition => validCurrentPosition;
  LatLng get validCurrentPosition =>
      (_currentPosition.latitude >= 8.0 && _currentPosition.latitude <= 24.0 &&
       _currentPosition.longitude >= 102.0 && _currentPosition.longitude <= 112.0)
          ? _currentPosition
          : const LatLng(ApiConfig.defaultLat, ApiConfig.defaultLng);

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

  Future<void> setActiveStopoverOrder(Map<String, dynamic>? order) async {
    _activeStopoverOrder = order;
    _isOrderPickedUp = false;
    _state = MapState.showingRoute;
    _showRouteDetails = true;
    _foodKeyword = '';
    foodKeywordController.clear();
    _routeRestaurants = [];
    _isSearchingFood = false;
    notifyListeners();

    if (order != null) {
      final storeLat = (order['lat'] as num?)?.toDouble();
      final storeLng = (order['lng'] as num?)?.toDouble();

      final origPos = validCurrentPosition;
      if (_originPlace == null ||
          _originPlace!.latLng.latitude < 8.0 || _originPlace!.latLng.latitude > 24.0 ||
          _originPlace!.latLng.longitude < 102.0 || _originPlace!.latLng.longitude > 112.0) {
        _originPlace = PlaceModel(
          id: 'gps_origin',
          name: currentLocationText,
          address: currentLocationText,
          latLng: origPos,
        );
        originController.text = _originPlace!.name;
      }

      // Nếu chưa có stopoverRoute với 2 legs, tự động tính lộ trình ghé quán
      if (storeLat != null && storeLng != null) {
        final storePos = LatLng(storeLat, storeLng);
        if (_stopoverRoute == null || _stopoverRoute!.legs.length < 2) {
          final orig = _originPlace?.latLng ?? _currentPosition;
          final dest = _destinationPlace?.latLng ?? storePos;
          final detour = await _directionsService.getDirections(
            origin: orig,
            destination: dest,
            stopover: storePos,
            mode: _travelMode,
          );
          if (detour != null) {
            _stopoverRoute = detour;
            _fitBoundsToRoute(detour.simplifiedPolylinePoints);
            notifyListeners();
          }
        } else {
          _fitBoundsToRoute(_stopoverRoute!.simplifiedPolylinePoints);
        }
      }
      _startNavService();
    } else {
      _navService.stopNavigation();
    }
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
    _navService.manualConfirmPickup();
    _isOrderPickedUp = true;

    // 1. Trả bộ lọc tìm kiếm món về ban đầu và đóng thẻ chi tiết lộ trình
    _foodKeyword = '';
    foodKeywordController.clear();
    _routeRestaurants = [];
    _isSearchingFood = false;
    _selectedStopoverStore = null;
    _selectedStopoverFood = null;
    _showRouteDetails = false;

    final storeLocation = activeStopoverLatLng;
    final dest = _destinationPlace;

    // Kiểm tra xem có chặng 2 tới điểm đến B không (đích đến khác vị trí quán)
    bool hasNextDestination = false;
    if (dest != null && storeLocation != null) {
      final double distDiff = (dest.latLng.latitude - storeLocation.latitude).abs() +
          (dest.latLng.longitude - storeLocation.longitude).abs();
      if (distDiff >= 0.0005) {
        hasNextDestination = true;
      }
    } else if (dest != null && storeLocation == null) {
      hasNextDestination = true;
    }

    if (hasNextDestination && dest != null) {
      debugPrint('[MapProvider] [Info] Đã nhận món tại quán! Tiếp tục dẫn đường chặng 2 tới ${dest.name}');
      if (_activeStopoverOrder != null) {
        _activeStopoverOrder = Map<String, dynamic>.from(_activeStopoverOrder!)
          ..['trangThai'] = 'ĐÃ LẤY MÓN'
          ..['isPickedUp'] = true;
      }

      final remainingPts = _navService.remainingLeg2.value;
      if (remainingPts.length >= 2) {
        _fitBoundsToRoute(remainingPts);
      } else if (_stopoverRoute != null && _stopoverRoute!.legs.length >= 2) {
        _fitBoundsToRoute(_stopoverRoute!.legs[1].polylinePoints);
      }
      notifyListeners();
    } else {
      // Đích đến chính là quán ăn: hoàn thành toàn bộ lộ trình
      debugPrint('[MapProvider] [Info] Đã đến quán và nhận món, hoàn tất lộ trình!');
      clearAll();
    }
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

    final origPos = validCurrentPosition;
    if (_originPlace == null ||
        _originPlace!.latLng.latitude < 8.0 || _originPlace!.latLng.latitude > 24.0 ||
        _originPlace!.latLng.longitude < 102.0 || _originPlace!.latLng.longitude > 112.0) {
      _originPlace = PlaceModel(
        id: 'gps_origin',
        name: currentLocationText,
        address: currentLocationText,
        latLng: origPos,
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
  List<dynamic> get routeRestaurants {
    if (_routeRestaurants.isEmpty) return [];

    switch (_foodRouteOption) {
      case FoodRouteOption.takeaway:
        return _routeRestaurants.where((r) {
          final tienIch = (r['tienIch'] ?? r['tienich'] ?? '').toString().toLowerCase();
          final hasTakeaway = r['hasTakeaway'] == true ||
              r['hasTakeaway'] == null ||
              tienIch.contains('take-away') ||
              tienIch.contains('mang về') ||
              tienIch.contains('mang ve');
          return hasTakeaway;
        }).toList();

      case FoodRouteOption.preOrder:
        return _routeRestaurants.where((r) {
          final coDatTruoc = r['coChoDatTruoc'] == true ||
              r['cochodattruoc'] == true ||
              r['hasPreOrder'] == true;
          return coDatTruoc;
        }).toList();

      case FoodRouteOption.dineIn:
        return _routeRestaurants.where((r) {
          final tienIch = (r['tienIch'] ?? r['tienich'] ?? '').toString().toLowerCase();
          final hasDineIn = r['hasDineIn'] == true ||
              r['coChoNgoi'] == true ||
              tienIch.contains('chỗ ngồi') ||
              tienIch.contains('cho ngoi') ||
              tienIch.contains('tại chỗ') ||
              tienIch.contains('tai cho') ||
              tienIch.contains('dine-in');
          return hasDineIn;
        }).toList();
    }
  }

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

  // Init

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

  /// Lấy vị trí thông qua địa chỉ IP (rất hữu ích khi chạy trên emulator)
  Future<LatLng?> _getLocationByIP() async {
    for (final url in ['https://ipapi.co/json/', 'https://ipinfo.io/json']) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = json.decode(utf8.decode(res.bodyBytes));
          final lat = (data['latitude'] as num?)?.toDouble() ??
              (data['loc'] != null ? double.tryParse(data['loc'].toString().split(',')[0]) : null);
          final lon = (data['longitude'] as num?)?.toDouble() ??
              (data['loc'] != null ? double.tryParse(data['loc'].toString().split(',')[1]) : null);
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
      } catch (_) {}
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
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 2),
      );

      final gpsLatLng = LatLng(position.latitude, position.longitude);
      final bool inVietnam = gpsLatLng.latitude >= 8.0 && gpsLatLng.latitude <= 24.0 &&
                             gpsLatLng.longitude >= 102.0 && gpsLatLng.longitude <= 112.0;

      if (!inVietnam) {
        isMockLocation = true;
        debugPrint('[MapProvider] [Info] Tọa độ GPS ngoài lãnh thổ VN (${gpsLatLng.latitude}, ${gpsLatLng.longitude}). Sẽ dùng tọa độ mặc định TP.HCM.');
      } else {
        detectedPosition = gpsLatLng;
        debugPrint('[MapProvider] [Info] Lấy vị trí GPS thực tế thành công: ${detectedPosition.latitude}, ${detectedPosition.longitude}');
      }
    } catch (e) {
      debugPrint('[MapProvider] [Error] Lấy GPS thiết bị thất bại (hoặc không bật định vị): $e');
    }

    if (detectedPosition == null || isMockLocation) {
      final ipPos = await _getLocationByIP();
      if (ipPos != null && ipPos.latitude >= 8.0 && ipPos.latitude <= 24.0 &&
          ipPos.longitude >= 102.0 && ipPos.longitude <= 112.0) {
        detectedPosition = ipPos;
      } else {
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

  // Search / Autocomplete

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

  // Route

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

    _isSearchingFood = true;
    notifyListeners();

    try {
      final kw = _foodKeyword.trim();
      _routeRestaurants = await CategoryService.fetchRestaurantsAlongRoute(
        route.simplifiedPolylinePoints,
        maxDistanceMeters: 800,
        keyword: kw.isNotEmpty ? kw : null,
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
      _currentRoute = _originalRoute;
      _fitBoundsToRoute(_originalRoute!.simplifiedPolylinePoints);
    }
    notifyListeners();
  }

  /// Dọn sạch hoàn toàn lộ trình ghé quán khi người dùng hủy món / hủy đơn / không thanh toán:
  /// - Xóa bỏ chặng rẽ vào quán (_stopoverRoute = null)
  /// - Xóa quán dừng chân (_selectedStopoverStore = null, _selectedStopoverFood = null)
  /// - Xóa đơn hàng ghé lấy (_activeStopoverOrder = null, _isOrderPickedUp = false)
  /// - Khôi phục lại tuyến đường thẳng ban đầu A -> B (_currentRoute = _originalRoute)
  void cancelStopoverOrder() {
    _navService.stopNavigation();
    _stopoverRoute = null;
    _selectedStopoverStore = null;
    _selectedStopoverFood = null;
    _activeStopoverOrder = null;
    _isOrderPickedUp = false;
    if (_originalRoute != null) {
      _currentRoute = _originalRoute;
      _fitBoundsToRoute(_originalRoute!.simplifiedPolylinePoints);
    }
    notifyListeners();
  }

  @visibleForTesting
  void setStopoverRouteForTesting({RouteModel? original, RouteModel? stopover, Map<String, dynamic>? store, Map<String, dynamic>? food, Map<String, dynamic>? order}) {
    if (original != null) { _originalRoute = original; _currentRoute = original; }
    _stopoverRoute = stopover; _selectedStopoverStore = store; _selectedStopoverFood = food; _activeStopoverOrder = order;
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
    final validPoints = points.where((p) =>
      p.latitude != 0.0 && p.longitude != 0.0 && p.latitude > 5.0 && p.latitude < 25.0 && p.longitude > 100.0 && p.longitude < 115.0
    ).toList();
    if (validPoints.isEmpty) { _moveCamera(_currentPosition, zoom: 16); return; }
    try {
      mapController.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(validPoints),
        padding: const EdgeInsets.all(60.0),
        maxZoom: 17, minZoom: 12,
      ));
    } catch (_) {
      _moveCamera(_currentPosition, zoom: 16);
    }
  }

  // Map tap — đặt điểm trực tiếp

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

  // Helpers

  void _moveCamera(LatLng position, {double zoom = 14}) {
    final safePos = (position.latitude < 8.0 || position.latitude > 24.0 || position.longitude < 102.0 || position.longitude > 112.0)
        ? const LatLng(ApiConfig.defaultLat, ApiConfig.defaultLng)
        : position;
    if (!_mapReady) { _pendingMoveTarget = safePos; _pendingMoveZoom = zoom; return; }
    try { mapController.move(safePos, zoom); } catch (_) {}
  }

  void clearAll() {
    _navService.stopNavigation();
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

    final safePos = validCurrentPosition;
    _currentPosition = safePos;
    _originPlace = PlaceModel(
      id: 'current_loc',
      name: currentLocationText,
      address: currentLocationText,
      latLng: safePos,
    );
    originController.text = _originPlace!.name;

    // Đưa camera về vị trí hiện tại ở zoom 16, tuyệt đối không bao giờ ra nước ngoài hay văng ra thế giới
    _moveCamera(safePos, zoom: 16);
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
    _navService.dispose();
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
