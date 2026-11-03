import 'package:flutter_test/flutter_test.dart';
import 'package:food_route/models/reservation_model.dart';

void main() {
  group('ReservationModel Serialization & Business Logic Tests', () {
    test('ReservationModel.fromJson parses complete backend payload correctly', () {
      final jsonMap = {
        'maDatBan': 101,
        'maQuan': 5,
        'maKhachHang': 8,
        'maBan': 12,
        'thoiGianBatDau': '2026-11-02T12:00:00.000Z',
        'thoiGianKetThuc': '2026-11-02T13:30:00.000Z',
        'soNguoi': 4,
        'trangThai': 'CHO_XAC_NHAN',
        'ghiChu': 'Bàn gần cửa sổ',
        'tenKhachHang': 'Nguyễn Văn A',
        'sdtKhachHang': '0901234567',
        'emailKhachHang': 'test@gmail.com',
        'createdAt': '2026-11-01T10:00:00.000Z',
        'updatedAt': '2026-11-01T10:00:00.000Z',
        'ban': {
          'maBan': 12,
          'tenBan': 'Bàn VIP 1',
          'sucChua': 6,
          'trangThai': 'TRONG',
        },
        'cuaHang': {
          'maQuan': 5,
          'tenQuan': 'Phở Gia Truyền',
          'diaChi': '123 Đường Láng',
          'img': '/uploads/store.jpg',
          'sdt': '0912345678',
          'gioHoatDong': '08:00 - 22:00',
          'coChoDatTruoc': true,
          'danhGiaTrungBinh': 4.8,
          'soLuongDanhGia': 25,
        },
      };

      final model = ReservationModel.fromJson(jsonMap);

      expect(model.maDatBan, 101);
      expect(model.maQuan, 5);
      expect(model.maKhachHang, 8);
      expect(model.maBan, 12);
      expect(model.soNguoi, 4);
      expect(model.trangThai, ReservationStatus.choXacNhan);
      expect(model.isPending, isTrue);
      expect(model.isConfirmed, isFalse);
      expect(model.canCancel, isTrue);
      expect(model.statusTitle, 'Chờ xác nhận');

      // Table details
      expect(model.ban, isNotNull);
      expect(model.ban!.tenBan, 'Bàn VIP 1');
      expect(model.ban!.sucChua, 6);

      // Restaurant details
      expect(model.cuaHang, isNotNull);
      expect(model.cuaHang!.tenQuan, 'Phở Gia Truyền');
      expect(model.cuaHang!.coChoDatTruoc, isTrue);
      expect(model.cuaHang!.danhGiaTrungBinh, 4.8);
    });

    test('ReservationStatus enum titles and colors cover all backend states', () {
      final statuses = [
        ReservationStatus.choXacNhan,
        ReservationStatus.daXacNhan,
        ReservationStatus.daDen,
        ReservationStatus.dangSuDung,
        ReservationStatus.daHoanTat,
        ReservationStatus.tuChoi,
        ReservationStatus.daHuy,
        ReservationStatus.khachKhongDen,
      ];

      for (final st in statuses) {
        final title = ReservationStatus.getTitle(st);
        expect(title.isNotEmpty, isTrue, reason: 'Status $st should have non-empty title');
        final color = ReservationStatus.getColor(st);
        expect(color, isNotNull, reason: 'Status $st should have valid color');
      }
    });

    test('ReservationAvailabilityResult.fromJson parses available tables', () {
      final jsonMap = {
        'isOpen': true,
        'allowReservation': true,
        'message': 'Quán đang mở cửa và nhận đặt bàn',
        'availableTables': [
          {'maBan': 1, 'tenBan': 'Bàn 1', 'sucChua': 2},
          {'maBan': 2, 'tenBan': 'Bàn 2', 'sucChua': 4},
        ],
      };

      final result = ReservationAvailabilityResult.fromJson(jsonMap);

      expect(result.isOpen, isTrue);
      expect(result.allowReservation, isTrue);
      expect(result.availableTables.length, 2);
      expect(result.availableTables.first.tenBan, 'Bàn 1');
    });

    test('ReservationModel.copyWith updates fields without mutating original', () {
      final original = ReservationModel(
        maDatBan: 1,
        maQuan: 1,
        maBan: 1,
        thoiGianBatDau: DateTime(2026, 11, 2, 12, 0),
        thoiGianKetThuc: DateTime(2026, 11, 2, 13, 30),
        soNguoi: 2,
        trangThai: ReservationStatus.choXacNhan,
      );

      final updated = original.copyWith(trangThai: ReservationStatus.daXacNhan);

      expect(original.trangThai, ReservationStatus.choXacNhan);
      expect(updated.trangThai, ReservationStatus.daXacNhan);
      expect(updated.isConfirmed, isTrue);
    });
  });
}
