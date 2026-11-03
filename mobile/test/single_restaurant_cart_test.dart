import 'package:flutter_test/flutter_test.dart';
import 'package:food_route/providers/cart_provider.dart';
import 'package:food_route/services/order_service.dart';

void main() {
  group('CartProvider Single Restaurant Restriction Tests', () {
    late CartProvider cart;

    setUp(() {
      cart = CartProvider();
    });

    test('Initial empty cart has no conflict with any restaurant', () {
      expect(cart.items.isEmpty, isTrue);
      expect(cart.hasConflictWith(10), isFalse);
      expect(cart.hasConflictWith(20), isFalse);
      expect(cart.activeRestaurantId, isNull);
    });

    test('Adding item from Restaurant A sets activeRestaurantId and permits adding more from Restaurant A', () {
      cart.registerRestaurant(id: 10, name: 'Quán Phở A', address: '123 Đường A');
      cart.addToCart(CartItemModel(
        foodId: 101,
        foodName: 'Phở Bò',
        price: 50000,
        quantity: 1,
        image: 'img_pho.jpg',
        restaurantId: 10,
      ));

      expect(cart.activeRestaurantId, equals(10));
      expect(cart.activeRestaurantName, equals('Quán Phở A'));
      expect(cart.hasConflictWith(10), isFalse); // Cùng quán -> không xung đột
    });

    test('Adding item from Restaurant B conflicts when cart already has items from Restaurant A', () {
      cart.registerRestaurant(id: 10, name: 'Quán Phở A', address: '123 Đường A');
      cart.addToCart(CartItemModel(
        foodId: 101,
        foodName: 'Phở Bò',
        price: 50000,
        quantity: 1,
        image: 'img_pho.jpg',
        restaurantId: 10,
      ));

      // Quán B khác quán A -> Xung đột!
      expect(cart.hasConflictWith(20), isTrue);
      expect(cart.restaurantIds, equals([10]));
    });

    test('Clearing cart resolves conflict and allows ordering from Restaurant B', () {
      cart.registerRestaurant(id: 10, name: 'Quán Phở A', address: '123 Đường A');
      cart.addToCart(CartItemModel(
        foodId: 101,
        foodName: 'Phở Bò',
        price: 50000,
        quantity: 1,
        image: 'img_pho.jpg',
        restaurantId: 10,
      ));

      expect(cart.hasConflictWith(20), isTrue);

      // Người dùng chọn "Xóa giỏ hàng & đặt quán mới"
      cart.clearCart();

      expect(cart.items.isEmpty, isTrue);
      expect(cart.hasConflictWith(20), isFalse);

      cart.registerRestaurant(id: 20, name: 'Quán Cơm B', address: '456 Đường B');
      cart.addToCart(CartItemModel(
        foodId: 201,
        foodName: 'Cơm Tấm',
        price: 45000,
        quantity: 1,
        image: 'img_com.jpg',
        restaurantId: 20,
      ));

      expect(cart.activeRestaurantId, equals(20));
      expect(cart.activeRestaurantName, equals('Quán Cơm B'));
      expect(cart.hasConflictWith(20), isFalse);
      expect(cart.hasConflictWith(10), isTrue);
    });
  });
}
