import '../services/category_service.dart';
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../common/locator.dart';
import '../services/socket_service.dart';

class RestaurantMeta {
  final int id;
  final String name;
  final String address;
  const RestaurantMeta({required this.id, required this.name, required this.address});
}

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  CartProvider() {
    if (locator.isRegistered<SocketService>()) {
      locator<SocketService>().listenToVoucherUpdates(_onVoucherUpdated);
    }
  }

  void _onVoucherUpdated(dynamic data) {
    if (data is Map && _appliedVoucherId != null) {
      final vId = data['maVoucher'] ?? data['data']?['maVoucher'];
      final status = data['status'] ?? data['data']?['status'];
      final action = data['action'] ?? data['data']?['action'];
      if (vId == _appliedVoucherId) {
        if (status == 'TAM_TAT' || action == 'DELETED') {
          removeVoucher();
        }
      }
    }
  }

  @override
  void dispose() {
    if (locator.isRegistered<SocketService>()) {
      locator<SocketService>().offVoucherUpdates(_onVoucherUpdated);
    }
    super.dispose();
  }
  // Lưu thông tin tên/địa chỉ của từng quán đang có món trong giỏ
  final Map<int, RestaurantMeta> _restaurantMetas = {};

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + (TimeOfDay.now().minute + 30 >= 60 ? 1 : 0)) % 24,
    minute: (TimeOfDay.now().minute + 30) % 60,
  );

  List<CartItemModel> get items => List.unmodifiable(_items);

  /// Danh sách ID các quán đang có món trong giỏ
  List<int> get restaurantIds =>
      _items.map((i) => i.restaurantId).toSet().toList();

  /// ID quán đại diện (hoặc quán đầu tiên trong giỏ)
  int? get restaurantId => _items.isNotEmpty
      ? _items.first.restaurantId
      : (_restaurantMetas.isNotEmpty ? _restaurantMetas.keys.first : null);

  /// ID quán đang có món trong giỏ
  int? get activeRestaurantId => _items.isNotEmpty ? _items.first.restaurantId : null;

  /// Tên quán đang có món trong giỏ
  String get activeRestaurantName {
    final id = activeRestaurantId;
    if (id == null) return '';
    return restaurantName(id);
  }

  /// Kiểm tra xem giỏ hàng hiện tại có món thuộc quán khác không
  bool hasConflictWith(int newRestaurantId) {
    if (_items.isEmpty) return false;
    final ids = restaurantIds;
    return ids.isNotEmpty && !ids.contains(newRestaurantId);
  }

  final Set<int> _resolvingIds = {};

  Future<void> _resolveRestaurantMeta(int id) async {
    if (_resolvingIds.contains(id)) return;
    _resolvingIds.add(id);
    try {
      final res = await CategoryService.fetchRestaurantById(id);
      if (res != null) {
        final name = (res['tenQuan'] ?? res['name'] ?? '').toString();
        final addr = (res['diaChi'] ?? res['address'] ?? '').toString();
        if (name.isNotEmpty) {
          _restaurantMetas[id] = RestaurantMeta(id: id, name: name, address: addr);
          notifyListeners();
        }
      }
    } catch (_) {} finally {
      _resolvingIds.remove(id);
    }
  }

  /// Trả về tên quán theo ID (dùng cho UI)
  String restaurantName(int id) {
    final meta = _restaurantMetas[id];
    if (meta != null && meta.name.isNotEmpty && !meta.name.startsWith('Quán ')) {
      return meta.name;
    }
    for (var i in _items) {
      if (i.restaurantId == id && i.restaurantName.isNotEmpty && !i.restaurantName.startsWith('Quán ')) {
        _restaurantMetas[id] = RestaurantMeta(
          id: id,
          name: i.restaurantName,
          address: i.restaurantAddress,
        );
        return i.restaurantName;
      }
    }
    _resolveRestaurantMeta(id);
    return meta?.name ?? 'Quán $id';
  }

  /// Trả về địa chỉ quán theo ID
  String restaurantAddress(int id) {
    final meta = _restaurantMetas[id];
    if (meta != null && meta.address.isNotEmpty) {
      return meta.address;
    }
    for (var i in _items) {
      if (i.restaurantId == id && i.restaurantAddress.isNotEmpty) {
        return i.restaurantAddress;
      }
    }
    return '';
  }

  /// Lấy các món thuộc một quán cụ thể
  List<CartItemModel> itemsForRestaurant(int restaurantId) =>
      _items.where((i) => i.restaurantId == restaurantId).toList();

  /// Tổng tiền các món thuộc một quán cụ thể
  double subTotalForRestaurant(int restaurantId) =>
      _items
          .where((i) => i.restaurantId == restaurantId)
          .fold(0.0, (sum, i) => sum + i.price * i.quantity);

  int get itemCount => totalItemCount;
  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  DateTime get selectedDate => _selectedDate;
  TimeOfDay get selectedTime => _selectedTime;

  DateTime get combinedPickupDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  /// Đăng ký / cập nhật thông tin tên-địa chỉ của một quán.
  /// Gọi mỗi lần mở trang chi tiết quán để luôn có meta mới nhất.
  void registerRestaurant({
    required int id,
    required String name,
    required String address,
  }) {
    _restaurantMetas[id] = RestaurantMeta(id: id, name: name, address: address);
    // Không notifyListeners ở đây vì chỉ cập nhật meta, không thay đổi items
  }

  /// Alias tương thích ngược cho registerRestaurant
  void setRestaurant({
    required int id,
    required String name,
    required String address,
  }) {
    registerRestaurant(id: id, name: name, address: address);
  }

  void addToCart(CartItemModel item) {
    if (item.restaurantName.isNotEmpty) {
      registerRestaurant(
        id: item.restaurantId,
        name: item.restaurantName,
        address: item.restaurantAddress,
      );
    } else {
      _resolveRestaurantMeta(item.restaurantId);
    }
    final index = _items.indexWhere((i) => i.foodId == item.foodId);
    if (index >= 0) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(int foodId) {
    _items.removeWhere((i) => i.foodId == foodId);
    _cleanOrphanMetas();
    notifyListeners();
  }

  void updateQuantity(int foodId, int delta) {
    final index = _items.indexWhere((i) => i.foodId == foodId);
    if (index >= 0) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      _cleanOrphanMetas();
      notifyListeners();
    }
  }

  void _cleanOrphanMetas() {
    final activeIds = _items.map((i) => i.restaurantId).toSet();
    _restaurantMetas.removeWhere((id, _) => !activeIds.contains(id));
  }

  void setPickupDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setPickupTime(TimeOfDay time) {
    _selectedTime = time;
    notifyListeners();
  }

  String? _appliedVoucherCode;
  double _discountAmount = 0.0;
  int? _appliedVoucherId;

  String? get appliedVoucherCode => _appliedVoucherCode;
  double get discountAmount => _discountAmount;
  int? get appliedVoucherId => _appliedVoucherId;

  void applyVoucher(String code, double discount, {int? voucherId}) {
    _appliedVoucherCode = code;
    _discountAmount = discount;
    _appliedVoucherId = voucherId;
    notifyListeners();
  }

  void removeVoucher() {
    _appliedVoucherCode = null;
    _discountAmount = 0.0;
    _appliedVoucherId = null;
    notifyListeners();
  }

  bool isPickupTimeValid() {
    final pickup = combinedPickupDateTime;
    final now = DateTime.now();
    return pickup.isAfter(now.add(const Duration(minutes: 5)));
  }

  double get subTotal {
    double sum = 0.0;
    for (var item in _items) {
      sum += item.price * item.quantity;
    }
    return sum;
  }

  double get discount => _discountAmount;

  double get total => (subTotal - _discountAmount).clamp(0.0, double.infinity);

  void clearCart() {
    _items.clear();
    removeVoucher();
    notifyListeners();
  }

  /// Xoá toàn bộ món của một quán cụ thể
  void clearRestaurant(int restaurantId) {
    _items.removeWhere((i) => i.restaurantId == restaurantId);
    _restaurantMetas.remove(restaurantId);
    notifyListeners();
  }
}
