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
import '../config/api_config.dart';

enum MapState { idle, searchingOrigin, searchingDestination, loadingRoute, showingRoute }

class MapProvider extends ChangeNotifier {
  final PlacesService _placesService = PlacesService();
  final DirectionsService _directionsService = DirectionsService();

  // ── Controllers ──────────────────────────────────────────────────────────
  final MapController mapController = MapController();
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────
  MapState _state = MapState.idle;
  MapState get state => _state;

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
          debugPrint('🌐 Lấy vị trí thành công qua IP (ipapi.co): $lat, $lon');
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Thử lấy vị trí qua IP (ipapi.co) thất bại: $e');
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
            debugPrint('🌐 Lấy vị trí thành công qua IP (ipinfo.io): $lat, $lon');
            return LatLng(lat, lon);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Thử lấy vị trí qua IP (ipinfo.io) thất bại: $e');
    }

    return null;
  }

  Future<void> _getCurrentLocation() async {
    LatLng? detectedPosition;
    bool isMockLocation = false;

    try {
      debugPrint('🛰️ Đang thử lấy vị trí bằng GPS của thiết bị...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      final gpsLatLng = LatLng(position.latitude, position.longitude);
      
      final double latDiff = (gpsLatLng.latitude - 37.422).abs();
      final double lonDiff = (gpsLatLng.longitude - (-122.084)).abs();
      if (latDiff < 0.01 && lonDiff < 0.01) {
        isMockLocation = true;
        debugPrint('ℹ️ Phát hiện tọa độ máy ảo mặc định (Mỹ). Sẽ dùng IP để chuyển về Việt Nam.');
      } else {
        detectedPosition = gpsLatLng;
        debugPrint('🛰️ Lấy vị trí GPS thực tế thành công: ${detectedPosition.latitude}, ${detectedPosition.longitude}');
      }
    } catch (e) {
      debugPrint('❌ Lấy GPS thiết bị thất bại (hoặc không bật định vị): $e');
    }

    if (detectedPosition == null || isMockLocation) {
      debugPrint('📍 Đang dùng máy ảo hoặc chưa bật GPS. Mặc định chọn Trần Quý Cáp, Bình Thạnh (10.8038, 106.6975).');
      detectedPosition = const LatLng(ApiConfig.defaultLat, ApiConfig.defaultLng);
    }

    _currentPosition = detectedPosition;
    _moveCamera(_currentPosition, zoom: 16);

    if (_originPlace == null) {
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

    _state = MapState.loadingRoute;
    _errorMessage = null;
    notifyListeners();

    final route = await _directionsService.getDirections(
      origin: _originPlace!.latLng,
      destination: _destinationPlace!.latLng,
      mode: _travelMode,
    );

    if (route != null) {
      _currentRoute = route;
      _state = MapState.showingRoute;
      _showRouteDetails = true;
      _fitBoundsToRoute(route.polylinePoints);
    } else {
      _errorMessage = 'Không tìm thấy đường đi. Vui lòng thử lại.';
      _state = MapState.idle;
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
    _showRouteDetails = false;
    _isFocusMode = false;
    _state = MapState.idle;
    _errorMessage = null;
    originController.clear();
    destinationController.clear();
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
    originController.dispose();
    destinationController.dispose();
    mapController.dispose();
    super.dispose();
  }
}
