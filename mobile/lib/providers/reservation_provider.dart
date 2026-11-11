import 'package:flutter/foundation.dart';
import '../common/locator.dart';
import '../models/reservation_model.dart';
import '../services/reservation_service.dart';
import '../services/socket_service.dart';

class ReservationProvider with ChangeNotifier {
  final SocketService _socketService = locator<SocketService>();

  List<ReservationModel> _reservations = [];
  ReservationModel? _currentReservation;
  ReservationAvailabilityResult? _availabilityResult;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isCheckingAvailability = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String _selectedTab = 'UPCOMING'; // 'UPCOMING' | 'HISTORY' | 'ALL'

  // Socket listener callbacks for clean lifecycle disposal
  void Function(dynamic)? _reservationCreatedCallback;
  void Function(dynamic)? _reservationUpdatedCallback;
  VoidCallback? _reconnectCallback;

  // Getters
  List<ReservationModel> get reservations => _reservations;
  ReservationModel? get currentReservation => _currentReservation;
  ReservationAvailabilityResult? get availabilityResult => _availabilityResult;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isCheckingAvailability => _isCheckingAvailability;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get total => _total;
  String get selectedTab => _selectedTab;

  /// Lượt đặt sắp tới (chờ xác nhận, đã xác nhận, đã đến, đang dùng bữa)
  List<ReservationModel> get upcomingReservations {
    return _reservations.where((r) {
      final st = r.trangThai.toUpperCase();
      return st == ReservationStatus.choXacNhan ||
          st == ReservationStatus.daXacNhan ||
          st == ReservationStatus.daDen ||
          st == ReservationStatus.dangSuDung;
    }).toList();
  }

  /// Lịch sử đặt bàn (hoàn tất, đã hủy, từ chối, vắng mặt)
  List<ReservationModel> get historyReservations {
    return _reservations.where((r) {
      final st = r.trangThai.toUpperCase();
      return st == ReservationStatus.daHoanTat ||
          st == ReservationStatus.daHuy ||
          st == ReservationStatus.tuChoi ||
          st == ReservationStatus.khachKhongDen;
    }).toList();
  }

  int get upcomingCount => upcomingReservations.length;

  ReservationProvider() {
    _initRealtimeListeners();
  }

  void setSelectedTab(String tab) {
    if (_selectedTab != tab) {
      _selectedTab = tab;
      notifyListeners();
    }
  }

  /// Khởi tạo lắng nghe Socket.io realtime
  void _initRealtimeListeners() {
    _reservationCreatedCallback = (data) {
      debugPrint('[ReservationProvider] [Socket] reservation:created received: $data');
      // Khi có đơn mới (ví dụ vừa tạo hoặc server push), refetch hoặc insert
      fetchMyReservations(refresh: true);
    };

    _reservationUpdatedCallback = (data) {
      debugPrint('[ReservationProvider] [Socket] reservation:status_changed received: $data');
      if (data is Map) {
        final int? id = data['id'] ?? data['maDatBan'];
        final String? newStatus = data['status'] ?? data['trangThai'];
        if (id != null && newStatus != null) {
          _updateReservationStatusInMemory(id, newStatus);
        } else {
          fetchMyReservations(refresh: true);
        }
      } else {
        fetchMyReservations(refresh: true);
      }
    };

    _reconnectCallback = () {
      debugPrint('[ReservationProvider] [Socket] Reconnected, resyncing reservations...');
      fetchMyReservations(refresh: true);
    };

    _socketService.listenToReservationUpdates(_reservationUpdatedCallback!);
    _socketService.subscribe('reservation:created', _reservationCreatedCallback!);
    _socketService.onReconnect(_reconnectCallback!);
  }

  void _updateReservationStatusInMemory(int id, String newStatus) {
    bool changed = false;
    final index = _reservations.indexWhere((r) => r.maDatBan == id);
    if (index != -1) {
      _reservations[index] = _reservations[index].copyWith(trangThai: newStatus);
      changed = true;
    }
    if (_currentReservation?.maDatBan == id) {
      _currentReservation = _currentReservation!.copyWith(trangThai: newStatus);
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Tải danh sách đặt bàn của tôi từ REST API
  Future<void> fetchMyReservations({bool refresh = false, String? status}) async {
    if (refresh) {
      _currentPage = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ReservationService.fetchMyReservations(
      page: _currentPage,
      limit: 20,
      status: status,
    );

    _isLoading = false;
    if (result['success'] == true) {
      final List<ReservationModel> list = result['reservations'] ?? [];
      if (refresh) {
        _reservations = list;
      } else {
        _reservations.addAll(list);
      }
      _total = result['total'] ?? _reservations.length;
      _totalPages = result['totalPages'] ?? 1;
    } else {
      _errorMessage = result['message'] ?? 'Không thể tải danh sách đặt bàn';
    }

    notifyListeners();
  }

  /// Tải chi tiết 1 lượt đặt bàn
  Future<ReservationModel?> fetchReservationDetail(int reservationId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ReservationService.fetchReservationDetail(reservationId);
    _isLoading = false;

    if (result['success'] == true && result['reservation'] != null) {
      _currentReservation = result['reservation'];
      // Tham gia phòng Socket riêng của lượt đặt bàn để nhận realtime tức thì
      _socketService.joinReservationRoom(reservationId);
      notifyListeners();
      return _currentReservation;
    } else {
      _errorMessage = result['message'] ?? 'Không tìm thấy lượt đặt bàn';
      notifyListeners();
      return null;
    }
  }

  /// Thoát phòng Socket của chi tiết lượt đặt bàn
  void leaveCurrentReservationRoom() {
    if (_currentReservation != null) {
      _socketService.leaveReservationRoom(_currentReservation!.maDatBan);
    }
  }

  /// Kiểm tra bàn trống và giờ mở cửa tại quán
  Future<ReservationAvailabilityResult> checkAvailability({
    required int restaurantId,
    required DateTime startTime,
    required int guestCount,
  }) async {
    _isCheckingAvailability = true;
    _availabilityResult = null;
    notifyListeners();

    final result = await ReservationService.checkAvailability(
      restaurantId: restaurantId,
      startTime: startTime,
      guestCount: guestCount,
    );

    _isCheckingAvailability = false;
    _availabilityResult = result;
    notifyListeners();
    return result;
  }

  void clearAvailability() {
    _availabilityResult = null;
    notifyListeners();
  }

  /// Tạo lượt đặt bàn mới
  Future<Map<String, dynamic>> createReservation({
    required int restaurantId,
    required DateTime startTime,
    required int guestCount,
    int? tableId,
    String? customerName,
    String? customerPhone,
    String? note,
    Map<dynamic, dynamic>? restaurantData,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final result = await ReservationService.createReservation(
      restaurantId: restaurantId,
      startTime: startTime,
      guestCount: guestCount,
      tableId: tableId,
      customerName: customerName,
      customerPhone: customerPhone,
      note: note,
    );

    _isSubmitting = false;

    if (result['success'] == true && result['data'] != null) {
      ReservationModel newResv = result['data'];
      if (newResv.cuaHang == null && restaurantData != null) {
        newResv = newResv.copyWith(
          cuaHang: ReservationRestaurantModel.fromJson(
            Map<String, dynamic>.from(restaurantData),
          ),
        );
      }
      _reservations.insert(0, newResv);
      _currentReservation = newResv;
      _socketService.joinReservationRoom(newResv.maDatBan);
      notifyListeners();
    } else {
      _errorMessage = result['message'];
      notifyListeners();
    }

    return result;
  }

  /// Khách hàng hủy lượt đặt bàn
  Future<Map<String, dynamic>> cancelReservation(int reservationId, {String? reason}) async {
    _isSubmitting = true;
    notifyListeners();

    final result = await ReservationService.cancelReservation(
      reservationId: reservationId,
      reason: reason,
    );

    _isSubmitting = false;

    if (result['success'] == true) {
      _updateReservationStatusInMemory(reservationId, ReservationStatus.daHuy);
    } else {
      _errorMessage = result['message'];
      notifyListeners();
    }

    return result;
  }

  @override
  void dispose() {
    // Unsubscribe all socket listeners cleanly to avoid leaks and duplicate handlers
    if (_reservationCreatedCallback != null) {
      _socketService.unsubscribe('reservation:created', _reservationCreatedCallback!);
    }
    if (_reservationUpdatedCallback != null) {
      _socketService.offReservationUpdates(_reservationUpdatedCallback!);
    }
    if (_reconnectCallback != null) {
      _socketService.offReconnect(_reconnectCallback!);
    }
    super.dispose();
  }
}
