import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Service quản lý tiến trình di chuyển trên tuyến đường (Origin -> Quán -> Đích)
/// Cắt polyline mượt mà, bám sát vị trí thực tế, lọc nhiễu GPS và hỗ trợ 2 chặng
class NavigationProgressService {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _throttleTimer;
  DateTime _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Danh sách điểm gốc của 2 chặng
  List<LatLng> _leg1FullPoints = [];
  List<LatLng> _leg2FullPoints = [];

  // Vị trí mục tiêu
  LatLng? _storeLatLng;
  LatLng? _destinationLatLng;

  // Tiến trình hiện tại
  int _currentLeg = 1; // 1: Đang đi tới quán, 2: Đang đi tới đích
  int _leg1CurrentIndex = 0;
  int _leg2CurrentIndex = 0;
  bool _isNavigating = false;
  bool _isArrivedAtStore = false;
  bool _isArrivedAtDestination = false;

  // Polyline đã cắt còn lại
  final ValueNotifier<List<LatLng>> remainingLeg1 = ValueNotifier<List<LatLng>>([]);
  final ValueNotifier<List<LatLng>> remainingLeg2 = ValueNotifier<List<LatLng>>([]);
  final ValueNotifier<LatLng?> currentUserPosition = ValueNotifier<LatLng?>(null);

  // Callbacks thông báo sự kiện
  VoidCallback? onArrivedAtStore;
  VoidCallback? onArrivedAtDestination;
  void Function(bool isOffRoute)? onOffRouteChanged;

  bool _isOffRoute = false;

  bool get isNavigating => _isNavigating;
  int get currentLeg => _currentLeg;
  bool get isArrivedAtStore => _isArrivedAtStore;
  bool get isArrivedAtDestination => _isArrivedAtDestination;

  /// Bắt đầu dẫn đường với lộ trình 1 chặng hoặc 2 chặng
  void startNavigation({
    required List<LatLng> leg1Points,
    List<LatLng>? leg2Points,
    LatLng? storeLatLng,
    LatLng? destinationLatLng,
    LatLng? initialUserPosition,
  }) {
    stopNavigation();

    _leg1FullPoints = List<LatLng>.from(leg1Points);
    _leg2FullPoints = leg2Points != null ? List<LatLng>.from(leg2Points) : [];
    _storeLatLng = storeLatLng;
    _destinationLatLng = destinationLatLng;

    _currentLeg = (_leg1FullPoints.isNotEmpty) ? 1 : 2;
    _leg1CurrentIndex = 0;
    _leg2CurrentIndex = 0;
    _isNavigating = true;
    _isArrivedAtStore = false;
    _isArrivedAtDestination = false;
    _isOffRoute = false;

    remainingLeg1.value = List<LatLng>.from(_leg1FullPoints);
    remainingLeg2.value = List<LatLng>.from(_leg2FullPoints);

    if (initialUserPosition != null) {
      currentUserPosition.value = initialUserPosition;
      _processLocationUpdate(initialUserPosition, accuracy: 5.0, force: true);
    }

    _startLocationStream();
  }

  void _startLocationStream() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3, // Chỉ kích hoạt khi di chuyển tối thiểu 3m
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _onNewPosition(position);
        },
        onError: (err) {
          debugPrint('[NavigationProgressService] [Error] Location stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('[NavigationProgressService] [Warn] Cannot start location stream: $e');
    }
  }

  void _onNewPosition(Position position) {
    if (!_isNavigating) return;

    // 1. Lọc bỏ tọa độ có độ chính xác kém (> 40m)
    if (position.accuracy > 40.0) return;

    // 2. Lọc bỏ tọa độ máy ảo mặc định (Mỹ) hoặc ngoài lãnh thổ Việt Nam
    if (position.latitude < 8.0 || position.latitude > 24.0 ||
        position.longitude < 102.0 || position.longitude > 112.0) {
      return;
    }

    final userLatLng = LatLng(position.latitude, position.longitude);
    currentUserPosition.value = userLatLng;

    // 2. Throttling: Giới hạn tần suất xử lý tối đa 1 lần / giây
    final now = DateTime.now();
    if (now.difference(_lastUpdateTime).inMilliseconds < 1000) {
      _throttleTimer?.cancel();
      _throttleTimer = Timer(const Duration(milliseconds: 1000), () {
        if (_isNavigating) {
          _processLocationUpdate(userLatLng, accuracy: position.accuracy);
        }
      });
      return;
    }

    _lastUpdateTime = now;
    _processLocationUpdate(userLatLng, accuracy: position.accuracy);
  }

  /// Cập nhật vị trí và thực hiện cắt polyline
  void _processLocationUpdate(LatLng userPos, {double accuracy = 10.0, bool force = false}) {
    if (!_isNavigating) return;

    if (_currentLeg == 1 && _leg1FullPoints.isNotEmpty && !_isArrivedAtStore) {
      _processLeg(
        userPos: userPos,
        fullPoints: _leg1FullPoints,
        currentIndex: _leg1CurrentIndex,
        targetLatLng: _storeLatLng ?? _leg1FullPoints.last,
        isStoreTarget: true,
        onUpdatePoints: (newPoints, newIdx) {
          _leg1CurrentIndex = newIdx;
          remainingLeg1.value = newPoints;
        },
        onArrived: () {
          _isArrivedAtStore = true;
          remainingLeg1.value = []; // Xóa sạch chặng 1
          _currentLeg = 2; // Chuyển sang chặng 2
          debugPrint('[NavigationProgressService] [Info] Đã đến quán nhận hàng!');
          onArrivedAtStore?.call();
        },
      );
    } else if (_currentLeg == 2 && _leg2FullPoints.isNotEmpty && !_isArrivedAtDestination) {
      _processLeg(
        userPos: userPos,
        fullPoints: _leg2FullPoints,
        currentIndex: _leg2CurrentIndex,
        targetLatLng: _destinationLatLng ?? _leg2FullPoints.last,
        isStoreTarget: false,
        onUpdatePoints: (newPoints, newIdx) {
          _leg2CurrentIndex = newIdx;
          remainingLeg2.value = newPoints;
        },
        onArrived: () {
          _isArrivedAtDestination = true;
          remainingLeg2.value = []; // Xóa sạch chặng 2
          _isNavigating = false;
          _stopStream();
          debugPrint('[NavigationProgressService] [Info] Đã hoàn thành toàn bộ lộ trình!');
          onArrivedAtDestination?.call();
        },
      );
    }
  }

  /// Xử lý cắt polyline cho từng chặng cụ thể
  void _processLeg({
    required LatLng userPos,
    required List<LatLng> fullPoints,
    required int currentIndex,
    required LatLng targetLatLng,
    required bool isStoreTarget,
    required void Function(List<LatLng> newPoints, int newIdx) onUpdatePoints,
    required VoidCallback onArrived,
  }) {
    final n = fullPoints.length;
    if (n < 2) return;

    // 1. Kiểm tra đã đến đích / đến quán chưa (bán kính <= 35m)
    final distToTarget = calculateDistanceMeters(userPos, targetLatLng);
    if (distToTarget <= 35.0 || (currentIndex >= n - 2 && distToTarget <= 50.0)) {
      onArrived();
      return;
    }

    // 2. Tìm kiếm đoạn gần nhất trong sliding window 30 điểm liền trước [currentIndex, currentIndex + 30]
    final windowEnd = math.min(currentIndex + 30, n - 1);
    double minDistance = double.infinity;
    int bestSegmentIdx = currentIndex;
    LatLng? bestProjectedPoint;

    for (int i = currentIndex; i < windowEnd; i++) {
      final p1 = fullPoints[i];
      final p2 = fullPoints[i + 1];

      final proj = projectPointOnSegment(userPos, p1, p2);
      if (proj.distance < minDistance) {
        minDistance = proj.distance;
        bestSegmentIdx = i;
        bestProjectedPoint = proj.projectedPoint;
      }
    }

    // 3. Xử lý người dùng đi lệch tuyến (> 50m)
    if (minDistance > 50.0) {
      if (!_isOffRoute) {
        _isOffRoute = true;
        onOffRouteChanged?.call(true);
      }
      // Không tiếp tục cắt, giữ nguyên lộ trình hiện có
      return;
    } else {
      if (_isOffRoute) {
        _isOffRoute = false;
        onOffRouteChanged?.call(false);
      }
    }

    // 4. Cắt polyline mượt mà: Bắt đầu từ điểm chiếu vuông góc, bám sát xe người dùng
    if (bestProjectedPoint != null && bestSegmentIdx >= currentIndex) {
      final remaining = <LatLng>[bestProjectedPoint];
      for (int i = bestSegmentIdx + 1; i < n; i++) {
        remaining.add(fullPoints[i]);
      }
      onUpdatePoints(remaining, bestSegmentIdx);
    }
  }

  /// Bỏ qua chặng 1 thủ công (khi người dùng bấm nút "Đã lấy món" trước khi GPS chạm ngưỡng 35m)
  void manualConfirmPickup() {
    if (!_isNavigating) return;
    _isArrivedAtStore = true;
    remainingLeg1.value = [];
    _currentLeg = 2;
    _leg2CurrentIndex = 0;
    if (currentUserPosition.value != null) {
      _processLocationUpdate(currentUserPosition.value!, force: true);
    }
  }

  /// Dừng dẫn đường và hủy toàn bộ stream/timer
  void stopNavigation() {
    _isNavigating = false;
    _stopStream();
    remainingLeg1.value = [];
    remainingLeg2.value = [];
  }

  void _stopStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _throttleTimer?.cancel();
    _throttleTimer = null;
  }

  void dispose() {
    stopNavigation();
    remainingLeg1.dispose();
    remainingLeg2.dispose();
    currentUserPosition.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Thuật toán hình học khoảng cách & hình chiếu vuông góc cực nhanh
  // ──────────────────────────────────────────────────────────────────────────

  /// Tính khoảng cách giữa 2 tọa độ theo mét (Haversine formula)
  static double calculateDistanceMeters(LatLng p1, LatLng p2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        math.cos((p2.latitude - p1.latitude) * p) / 2 +
        math.cos(p1.latitude * p) *
            math.cos(p2.latitude * p) *
            (1 - math.cos((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742000.0 * math.asin(math.sqrt(math.max(0.0, a)));
  }

  /// Chiếu điểm P lên đoạn thẳng P1-P2 (Mặt phẳng cục bộ xấp xỉ Equirectangular)
  static ({LatLng projectedPoint, double distance}) projectPointOnSegment(
    LatLng p,
    LatLng p1,
    LatLng p2,
  ) {
    const degToRad = math.pi / 180.0;
    final midLat = ((p1.latitude + p2.latitude) / 2.0) * degToRad;
    final cosMidLat = math.cos(midLat);
    const r = 6371000.0; // Bán kính Trái Đất (mét)

    // Chuyển sang tọa độ phẳng đề các tương đối tại P1
    final dx = (p2.longitude - p1.longitude) * degToRad * r * cosMidLat;
    final dy = (p2.latitude - p1.latitude) * degToRad * r;

    final px = (p.longitude - p1.longitude) * degToRad * r * cosMidLat;
    final py = (p.latitude - p1.latitude) * degToRad * r;

    final l2 = dx * dx + dy * dy;
    if (l2 < 0.0001) {
      // P1 và P2 trùng nhau
      final dist = math.sqrt(px * px + py * py);
      return (projectedPoint: p1, distance: dist);
    }

    // Hệ số t = vô hướng (P - P1) . (P2 - P1) / |P2 - P1|^2
    final t = (px * dx + py * dy) / l2;
    final tClamped = math.max(0.0, math.min(1.0, t));

    final projX = tClamped * dx;
    final projY = tClamped * dy;

    final dist = math.sqrt((px - projX) * (px - projX) + (py - projY) * (py - projY));

    final projLat = p1.latitude + tClamped * (p2.latitude - p1.latitude);
    final projLon = p1.longitude + tClamped * (p2.longitude - p1.longitude);

    return (projectedPoint: LatLng(projLat, projLon), distance: dist);
  }
}
