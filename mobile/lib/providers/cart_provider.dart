import 'package:flutter/material.dart';
import '../services/order_service.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  int _restaurantId = 1;
  String _restaurantName = 'Phở Bò Gia Truyền Hà Nội - Nguyễn Trãi';
  String _restaurantAddress = '235 Nguyễn Trãi, Quận 1, TP.HCM';

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + (TimeOfDay.now().minute + 30 >= 60 ? 1 : 0)) % 24,
    minute: (TimeOfDay.now().minute + 30) % 60,
  );

  List<CartItemModel> get items => List.unmodifiable(_items);
  int get restaurantId => _restaurantId;
  String get restaurantName => _restaurantName;
  String get restaurantAddress => _restaurantAddress;

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

  void setRestaurant({required int id, required String name, required String address}) {
    if (_restaurantId != id) {
      _items.clear(); // Clear cart if switching restaurant
    }
    _restaurantId = id;
    _restaurantName = name;
    _restaurantAddress = address;
    notifyListeners();
  }

  void addToCart(CartItemModel item) {
    if (_items.isEmpty && item.restaurantId > 0) {
      _restaurantId = item.restaurantId;
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
    notifyListeners();
  }

  void updateQuantity(int foodId, int delta) {
    final index = _items.indexWhere((i) => i.foodId == foodId);
    if (index >= 0) {
      _items[index].quantity += delta;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      notifyListeners();
    }
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
    // Must be at least 5 minutes in the future
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
}
