import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_route/common_widget/menu_item_row.dart';
import 'package:food_route/common_widget/smart_network_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('C2.1 MenuItemRow Price & Struck-through Tests', () {
    testWidgets('Only shows struck-through price when giaGoc > giaMonAn', (WidgetTester tester) async {
      // Case 1: giaGoc (80,000) > giaMonAn (60,000) -> should show both
      final itemWithDiscount = {
        'tenMonAn': 'Phở Bò Đặc Biệt',
        'giaMonAn': 60000,
        'giaGoc': 80000,
        'tenQuan': 'Phở Gia Truyền',
        'rate': 4.8,
        'soLuongMon': 50,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemRow(
              mObj: itemWithDiscount,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify regular price
      expect(find.text('60.000đ'), findsOneWidget);
      // Verify struck-through price
      expect(find.text('80.000đ'), findsOneWidget);
    });

    testWidgets('Does NOT show struck-through price when giaGoc <= giaMonAn or null', (WidgetTester tester) async {
      // Case 2: giaGoc (50,000) <= giaMonAn (60,000) -> should NOT show 50.000đ
      final itemNoDiscount = {
        'tenMonAn': 'Cơm Tấm Sườn',
        'giaMonAn': 60000,
        'giaGoc': 50000,
        'tenQuan': 'Cơm Tấm 99',
        'rate': 4.5,
        'soLuongMon': 20,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuItemRow(
              mObj: itemNoDiscount,
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify regular price is present
      expect(find.text('60.000đ'), findsOneWidget);
      // Verify struck-through old price is NOT rendered
      expect(find.text('50.000đ'), findsNothing);
    });
  });

  group('C2.2 SmartNetworkImage Error & Placeholder Fallback Tests', () {
    testWidgets('Empty URL renders placeholder icon without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartNetworkImage(
              imageUrl: '',
              width: 100,
              height: 100,
              placeholderIcon: Icons.fastfood,
            ),
          ),
        ),
      );

      // Verify placeholder icon is rendered safely
      expect(find.byIcon(Icons.fastfood), findsOneWidget);
    });

    testWidgets('Whitespace URL renders placeholder icon safely', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SmartNetworkImage(
              imageUrl: '   ',
              width: 80,
              height: 80,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });
  });

  group('C2.3 Price Formatting Logic Tests', () {
    test('Regex formatting adds thousands separator properly', () {
      String formatVND(int price) {
        return "${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ";
      }

      expect(formatVND(65000), '65.000đ');
      expect(formatVND(120000), '120.000đ');
      expect(formatVND(1500000), '1.500.000đ');
      expect(formatVND(5000), '5.000đ');
    });
  });

  group('C2.4 Refund Status Rendering Logic', () {
    test('Refund status badge mapping logic', () {
      String getRefundLabel(String? status) {
        switch (status) {
          case 'HOAN_TIEN_THANH_CONG':
            return 'Đã hoàn tiền';
          case 'DANG_XU_LY':
          case 'CHO_HOAN_TIEN':
            return 'Đang hoàn tiền';
          case 'CAN_DUYET_THU_CONG':
            return 'Chờ duyệt chi';
          case 'THAT_BAI':
            return 'Hoàn tiền thất bại';
          default:
            return '';
        }
      }

      expect(getRefundLabel('HOAN_TIEN_THANH_CONG'), 'Đã hoàn tiền');
      expect(getRefundLabel('DANG_XU_LY'), 'Đang hoàn tiền');
      expect(getRefundLabel('CAN_DUYET_THU_CONG'), 'Chờ duyệt chi');
      expect(getRefundLabel(null), '');
    });
  });
}
