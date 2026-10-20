import 'package:flutter/foundation.dart';
import '../services/restaurant_owner_service.dart';
import '../services/socket_service.dart';
import '../common/locator.dart';

class RestaurantVouchersProvider with ChangeNotifier {
  final RestaurantOwnerService _service = locator<RestaurantOwnerService>();
  final SocketService _socketService = locator<SocketService>();

  List<Map<String, dynamic>> _vouchers = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = false;
  String _errorMessage = '';
  String _statusFilter = 'ALL';
  String _searchQuery = '';

  void Function(dynamic)? _voucherUpdatedCallback;
  void Function(dynamic)? _orderCreatedCallback;
  VoidCallback? _reconnectCallback;

  List<Map<String, dynamic>> get vouchers => _vouchers;
  Map<String, dynamic> get summary => _summary;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;

  List<Map<String, dynamic>> get filteredVouchers {
    return _vouchers.where((v) {
      // Filter by status
      if (_statusFilter != 'ALL') {
        final st = (v['computedStatus'] ?? v['trangThai'] ?? '').toString().toUpperCase();
        if (_statusFilter == 'HOAT_DONG' && st != 'HOAT_DONG') return false;
        if (_statusFilter == 'TAM_TAT' && st != 'TAM_TAT') return false;
        if (_statusFilter == 'HET_HAN' && st != 'HET_HAN') return false;
        if (_statusFilter == 'HET_LUOT' && st != 'HET_LUOT') return false;
      }
      // Filter by search
      if (_searchQuery.isNotEmpty) {
        final code = (v['maCode'] ?? '').toString().toLowerCase();
        final name = (v['tenVoucher'] ?? '').toString().toLowerCase();
        if (!code.contains(_searchQuery) && !name.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void setStatusFilter(String filter) {
    if (_statusFilter != filter) {
      _statusFilter = filter;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void init(int? maQuan) {
    fetchVouchers();

    if (maQuan != null && maQuan > 0) {
      _socketService.joinRestaurantRoom(maQuan);
    }

    _voucherUpdatedCallback = (data) => _handleRealtimeUpdate(data);
    _orderCreatedCallback = (data) => _handleRealtimeUpdate(data);
    _reconnectCallback = () {
      debugPrint('⚡ [RestaurantVouchersProvider] Reconnected -> refetching vouchers');
      fetchVouchers();
    };

    _socketService.subscribe('voucher:updated', _voucherUpdatedCallback!);
    _socketService.subscribe('order:created', _orderCreatedCallback!);
    _socketService.onReconnect(_reconnectCallback!);
  }

  Future<void> fetchVouchers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final res = await _service.getVouchers();
      final list = res['vouchers'];
      if (list is List) {
        _vouchers = List<Map<String, dynamic>>.from(list);
      } else {
        _vouchers = [];
      }
      if (res['summary'] is Map) {
        _summary = Map<String, dynamic>.from(res['summary']);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Không thể tải danh sách voucher';
      notifyListeners();
    }
  }

  void _handleRealtimeUpdate(dynamic data) {
    debugPrint('⚡ [RestaurantVouchersProvider] Realtime voucher event received');
    fetchVouchers();
  }

  // ── Optimistic Toggle Status ─────────────────────────────────────────────
  Future<bool> toggleVoucherStatus(int voucherId, String currentStatus) async {
    final index = _vouchers.indexWhere((v) => (v['maVoucher'] ?? v['id']) == voucherId);
    if (index == -1) return false;

    final targetStatus = currentStatus == 'HOAT_DONG' ? 'TAM_TAT' : 'HOAT_DONG';
    _vouchers[index]['trangThai'] = targetStatus;
    _vouchers[index]['computedStatus'] = targetStatus;
    notifyListeners();

    final success = await _service.toggleVoucher(voucherId, targetStatus: targetStatus);
    if (!success) {
      _vouchers[index]['trangThai'] = currentStatus;
      _vouchers[index]['computedStatus'] = currentStatus;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> deleteVoucher(int voucherId) async {
    final success = await _service.deleteVoucher(voucherId);
    if (success) {
      _vouchers.removeWhere((v) => (v['maVoucher'] ?? v['id']) == voucherId);
      notifyListeners();
      fetchVouchers();
    }
    return success;
  }

  Future<bool> saveVoucher(Map<String, dynamic> input, {int? voucherId}) async {
    bool success = false;
    if (voucherId != null && voucherId > 0) {
      success = await _service.updateVoucher(voucherId, input);
    } else {
      success = await _service.createVoucher(input);
    }
    if (success) {
      fetchVouchers();
    }
    return success;
  }

  @override
  void dispose() {
    if (_voucherUpdatedCallback != null) {
      _socketService.unsubscribe('voucher:updated', _voucherUpdatedCallback);
    }
    if (_orderCreatedCallback != null) {
      _socketService.unsubscribe('order:created', _orderCreatedCallback);
    }
    if (_reconnectCallback != null) {
      _socketService.offReconnect(_reconnectCallback!);
    }
    super.dispose();
  }
}
