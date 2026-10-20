import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/restaurant_owner_service.dart';
import '../services/socket_service.dart';
import '../common/locator.dart';

class RestaurantOrdersProvider with ChangeNotifier {
  final RestaurantOwnerService _service = locator<RestaurantOwnerService>();
  final SocketService _socketService = locator<SocketService>();

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedPeriod = 'ALL'; // 'ALL', 'TODAY', '7DAYS', '30DAYS'
  int _selectedTab = 0; // 0: Cần xử lý, 1: Lịch sử

  // Callbacks for socket listeners so we can cleanly unsubscribe
  void Function(dynamic)? _orderCreatedCallback;
  void Function(dynamic)? _orderStatusChangedCallback;
  void Function(dynamic)? _paymentConfirmedCallback;
  VoidCallback? _reconnectCallback;

  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedPeriod => _selectedPeriod;
  int get selectedTab => _selectedTab;
  bool get isConnected => _socketService.isConnected;

  // Filtered lists
  List<Map<String, dynamic>> get activeOrders {
    return _applyFilter(_orders.where((o) {
      final st = (o['trangThai'] ?? o['status'] ?? '').toString().toUpperCase();
      return st == 'CHO_XAC_NHAN' ||
          st == 'DA_XAC_NHAN' ||
          st == 'DANG_CHUAN_BI' ||
          st == 'SAN_SANG';
    }).toList());
  }

  List<Map<String, dynamic>> get historyOrders {
    return _applyFilter(_orders.where((o) {
      final st = (o['trangThai'] ?? o['status'] ?? '').toString().toUpperCase();
      return st == 'HOAN_TAT' ||
          st == 'DA_HUY' ||
          st == 'DA_LAY' ||
          st == 'TU_CHOI';
    }).toList());
  }

  int get pendingCount {
    return _orders.where((o) {
      final st = (o['trangThai'] ?? o['status'] ?? '').toString().toUpperCase();
      return st == 'CHO_XAC_NHAN';
    }).length;
  }

  void setSelectedTab(int index) {
    if (_selectedTab != index) {
      _selectedTab = index;
      notifyListeners();
    }
  }

  void setSelectedPeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<Map<String, dynamic>> _applyFilter(List<Map<String, dynamic>> list) {
    var result = list;

    // Filter by period
    if (_selectedPeriod != 'ALL') {
      final now = DateTime.now();
      result = result.where((o) {
        final dateStr = o['thoiGianDat'] ?? o['createdAt'] ?? '';
        final date = DateTime.tryParse(dateStr.toString());
        if (date == null) return true;
        if (_selectedPeriod == 'TODAY') {
          return date.year == now.year && date.month == now.month && date.day == now.day;
        } else if (_selectedPeriod == '7DAYS') {
          return now.difference(date).inDays <= 7;
        } else if (_selectedPeriod == '30DAYS') {
          return now.difference(date).inDays <= 30;
        }
        return true;
      }).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      result = result.where((o) {
        final idStr = (o['maDonHang'] ?? o['id'] ?? '').toString().toLowerCase();
        final name = (o['customerName'] ?? o['tenKhachHang'] ?? '').toString().toLowerCase();
        final phone = (o['customerPhone'] ?? o['sdt'] ?? '').toString().toLowerCase();
        return idStr.contains(_searchQuery) ||
            name.contains(_searchQuery) ||
            phone.contains(_searchQuery);
      }).toList();
    }

    return result;
  }

  // ── Initialization & Realtime Subscription ────────────────────────────────
  void init(int? maQuan) {
    fetchOrders();

    if (maQuan != null && maQuan > 0) {
      _socketService.joinRestaurantRoom(maQuan);
    }

    // Setup Realtime Listeners
    _orderCreatedCallback = (data) => _handleOrderCreated(data);
    _orderStatusChangedCallback = (data) => _handleOrderStatusChanged(data);
    _paymentConfirmedCallback = (data) => _handlePaymentConfirmed(data);
    _reconnectCallback = () {
      debugPrint('⚡ [RestaurantOrdersProvider] Reconnected -> refetching orders');
      fetchOrders();
    };

    _socketService.subscribe('order:created', _orderCreatedCallback!);
    _socketService.subscribe('order:status_changed', _orderStatusChangedCallback!);
    _socketService.subscribe('payment:confirmed', _paymentConfirmedCallback!);
    _socketService.onReconnect(_reconnectCallback!);
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _service.getOrders();
      _orders = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể tải danh sách đơn hàng';
      notifyListeners();
    }
  }

  void _handleOrderCreated(dynamic data) {
    if (data == null) return;
    try {
      Map<String, dynamic>? newOrder;
      if (data is Map && data['data'] is Map) {
        newOrder = Map<String, dynamic>.from(data['data']);
      } else if (data is Map) {
        newOrder = Map<String, dynamic>.from(data);
      }

      if (newOrder != null) {
        final newId = newOrder['maDonHang'] ?? newOrder['id'];
        final exists = _orders.any((o) => (o['maDonHang'] ?? o['id']) == newId);
        if (!exists) {
          _orders.insert(0, newOrder);
          HapticFeedback.mediumImpact();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [RestaurantOrdersProvider] _handleOrderCreated error: $e');
    }
  }

  void _handleOrderStatusChanged(dynamic data) {
    if (data == null) return;
    try {
      final orderId = data['id'] ?? data['orderId'] ?? data['maDonHang'];
      final newStatus = data['status'] ?? data['trangThai'];
      if (orderId == null || newStatus == null) return;

      final index = _orders.indexWhere((o) => (o['maDonHang'] ?? o['id']) == orderId);
      if (index != -1) {
        _orders[index]['trangThai'] = newStatus;
        _orders[index]['status'] = newStatus;
        notifyListeners();
      } else {
        // Order not in local list, refetch
        fetchOrders();
      }
    } catch (e) {
      debugPrint('⚠️ [RestaurantOrdersProvider] _handleOrderStatusChanged error: $e');
    }
  }

  void _handlePaymentConfirmed(dynamic data) {
    if (data == null) return;
    try {
      final orderId = data['id'] ?? data['orderId'] ?? data['maDonHang'];
      if (orderId == null) return;

      final index = _orders.indexWhere((o) => (o['maDonHang'] ?? o['id']) == orderId);
      if (index != -1) {
        _orders[index]['trangThaiThanhToan'] = 'DA_THANH_TOAN';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ [RestaurantOrdersProvider] _handlePaymentConfirmed error: $e');
    }
  }

  // ── Optimistic Status Update ──────────────────────────────────────────────
  Future<bool> updateStatus(int orderId, String newStatus, {String? lyDo}) async {
    final index = _orders.indexWhere((o) => (o['maDonHang'] ?? o['id']) == orderId);
    if (index == -1) return false;

    final oldStatus = _orders[index]['trangThai'] ?? _orders[index]['status'];

    // Optimistic UI update
    _orders[index]['trangThai'] = newStatus;
    _orders[index]['status'] = newStatus;
    notifyListeners();

    final success = await _service.updateOrderStatus(orderId, newStatus, lyDo: lyDo);
    if (!success) {
      // Rollback on failure
      _orders[index]['trangThai'] = oldStatus;
      _orders[index]['status'] = oldStatus;
      notifyListeners();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    if (_orderCreatedCallback != null) {
      _socketService.unsubscribe('order:created', _orderCreatedCallback);
    }
    if (_orderStatusChangedCallback != null) {
      _socketService.unsubscribe('order:status_changed', _orderStatusChangedCallback);
    }
    if (_paymentConfirmedCallback != null) {
      _socketService.unsubscribe('payment:confirmed', _paymentConfirmedCallback);
    }
    if (_reconnectCallback != null) {
      _socketService.offReconnect(_reconnectCallback!);
    }
    super.dispose();
  }
}
