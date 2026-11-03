import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_route/models/reservation_model.dart';
import 'package:food_route/view/reservation/reservation_card.dart';
import 'package:food_route/widgets/skeleton/reservation_item_skeleton.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reservation UI Widget Tests', () {
    testWidgets('ReservationCard renders correct details and status badge', (WidgetTester tester) async {
      final reservation = ReservationModel(
        maDatBan: 88,
        maQuan: 1,
        maBan: 3,
        thoiGianBatDau: DateTime(2026, 11, 2, 19, 0),
        thoiGianKetThuc: DateTime(2026, 11, 2, 20, 30),
        soNguoi: 4,
        trangThai: ReservationStatus.choXacNhan,
        ban: const ReservationTableModel(maBan: 3, tenBan: 'Bàn Ngoài Trời', sucChua: 4),
        cuaHang: const ReservationRestaurantModel(
          maQuan: 1,
          tenQuan: 'Cơm Tấm Ba Ghiền',
          diaChi: '84 Đặng Văn Ngữ, Phú Nhuận',
        ),
      );

      bool tapped = false;
      bool cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReservationCard(
              reservation: reservation,
              onTap: () => tapped = true,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      // Verify ID and Restaurant Name
      expect(find.text('Mã đặt bàn: #88'), findsOneWidget);
      expect(find.text('Cơm Tấm Ba Ghiền'), findsOneWidget);
      expect(find.text('84 Đặng Văn Ngữ, Phú Nhuận'), findsOneWidget);

      // Verify Table Name and Guest Count
      expect(find.text('Bàn Ngoài Trời'), findsOneWidget);
      expect(find.text('4 khách'), findsOneWidget);

      // Verify Status Title
      expect(find.text('Chờ xác nhận'), findsOneWidget);

      // Verify Cancel Button is present because reservation is cancellable
      expect(find.text('Hủy đặt'), findsOneWidget);

      // Test tap
      await tester.tap(find.text('Cơm Tấm Ba Ghiền'));
      expect(tapped, isTrue);

      await tester.tap(find.text('Hủy đặt'));
      expect(cancelled, isTrue);
    });

    testWidgets('ReservationItemSkeleton renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReservationItemSkeleton(),
          ),
        ),
      );

      expect(find.byType(ReservationItemSkeleton), findsOneWidget);
    });
  });
}
