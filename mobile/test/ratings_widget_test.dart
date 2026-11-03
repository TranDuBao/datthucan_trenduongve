import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_route/common_widget/menu_item_row.dart';
import 'package:food_route/widgets/route_pickup_food_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ratings Realtime & Elimination of Fake 5.0 Tests', () {
    testWidgets('MenuItemRow: Does NOT show fake 5.0 badge when food has no reviews', (WidgetTester tester) async {
      final unratedItem = {
        'tenMonAn': 'Món Mới Chưa Có Review',
        'giaMonAn': 45000,
        'rate': 0.0,
        'diemDanhGiaTB': 0.0,
        'soLuotDanhGia': 0,
        'chuaCoDanhGia': true,
        'soLuongMon': 50,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemRow(
              mObj: unratedItem,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify that NO fake 5.0 badge is rendered
      expect(find.text('5.0'), findsNothing);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('MenuItemRow: Shows exact rating when food has real reviews', (WidgetTester tester) async {
      final ratedItem = {
        'tenMonAn': 'Trà Sữa Trân Châu Hoàng Kim',
        'giaMonAn': 55000,
        'rate': 4.7,
        'diemDanhGiaTB': 4.7,
        'soLuotDanhGia': 10,
        'chuaCoDanhGia': false,
        'soLuongMon': 50,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemRow(
              mObj: ratedItem,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify real rating 4.7 is rendered
      expect(find.text('4.7'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('RoutePickupFoodCard: Does NOT show fake 5.0 or star for unrated food', (WidgetTester tester) async {
      final unratedFood = {
        'id': 70,
        'name': 'Cơm Lam Ống Tre',
        'price': 35000,
        'rating': 0.0,
        'soLuotDanhGia': 0,
        'chuaCoDanhGia': true,
        'soLuongMon': 20,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePickupFoodCard(
              item: unratedFood,
              width: 170,
            ),
          ),
        ),
      );

      // Must NOT show fake "5.0"
      expect(find.text('5.0'), findsNothing);
      // Must NOT show star icon when there is no rating
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('RoutePickupFoodCard: Shows exact real rating and star when food is rated', (WidgetTester tester) async {
      final ratedFood = {
        'id': 71,
        'name': 'Bánh Canh Cua',
        'price': 45000,
        'rating': 4.6,
        'soLuotDanhGia': 8,
        'chuaCoDanhGia': false,
        'soLuongMon': 15,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RoutePickupFoodCard(
              item: ratedFood,
              width: 170,
            ),
          ),
        ),
      );

      // Must show exact rating "4.6"
      expect(find.text('4.6'), findsOneWidget);
      // Must show star icon
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      // Must NOT show fake "5.0"
      expect(find.text('5.0'), findsNothing);
    });
  });
}

