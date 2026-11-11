import 'package:flutter/material.dart';

/// Trạng thái đặt bàn đồng bộ với hệ thống Backend & Web
class ReservationStatus {
  static const String choXacNhan = 'CHO_XAC_NHAN';
  static const String daXacNhan = 'DA_XAC_NHAN';
  static const String daDen = 'DA_DEN';
  static const String dangSuDung = 'DANG_SU_DUNG';
  static const String daHoanTat = 'DA_HOAN_TAT';
  static const String tuChoi = 'TU_CHOI';
  static const String daHuy = 'DA_HUY';
  static const String khachKhongDen = 'KHACH_KHONG_DEN';

  static String getTitle(String status) {
    switch (status.toUpperCase()) {
      case choXacNhan:
        return 'Chờ xác nhận';
      case daXacNhan:
        return 'Đã xác nhận';
      case daDen:
        return 'Đã đến';
      case dangSuDung:
        return 'Đang dùng bữa';
      case daHoanTat:
        return 'Hoàn tất';
      case tuChoi:
        return 'Bị từ chối';
      case daHuy:
        return 'Đã hủy';
      case khachKhongDen:
        return 'Khách không đến';
      default:
        return status;
    }
  }

  static Color getColor(String status) {
    switch (status.toUpperCase()) {
      case choXacNhan:
        return const Color(0xffFFA500); // Cam cảnh báo
      case daXacNhan:
        return const Color(0xff2196F3); // Xanh dương
      case daDen:
      case dangSuDung:
        return const Color(0xff4CAF50); // Xanh lá
      case daHoanTat:
        return const Color(0xff2E7D32); // Xanh lá đậm
      case tuChoi:
      case daHuy:
      case khachKhongDen:
        return const Color(0xffE53935); // Đỏ
      default:
        return const Color(0xff757575);
    }
  }
}

/// Thông tin bàn ăn
class ReservationTableModel {
  final int maBan;
  final String tenBan;
  final int sucChua;
  final String? trangThai;

  const ReservationTableModel({
    required this.maBan,
    required this.tenBan,
    required this.sucChua,
    this.trangThai,
  });

  factory ReservationTableModel.fromJson(Map<String, dynamic> json) {
    return ReservationTableModel(
      maBan: json['maBan'] ?? json['maban'] ?? 0,
      tenBan: json['tenBan'] ?? json['tenban'] ?? 'Bàn',
      sucChua: json['sucChua'] ?? json['succhua'] ?? 2,
      trangThai: json['trangThai'] ?? json['trangthai'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maBan': maBan,
      'tenBan': tenBan,
      'sucChua': sucChua,
      if (trangThai != null) 'trangThai': trangThai,
    };
  }
}

/// Thông tin quán ăn đính kèm trong lượt đặt bàn
class ReservationRestaurantModel {
  final int maQuan;
  final String tenQuan;
  final String diaChi;
  final String? img;
  final String? sdt;
  final dynamic gioHoatDong;
  final bool coChoDatTruoc;
  final double danhGiaTrungBinh;
  final int soLuongDanhGia;

  const ReservationRestaurantModel({
    required this.maQuan,
    required this.tenQuan,
    required this.diaChi,
    this.img,
    this.sdt,
    this.gioHoatDong,
    this.coChoDatTruoc = true,
    this.danhGiaTrungBinh = 0.0,
    this.soLuongDanhGia = 0,
  });

  factory ReservationRestaurantModel.fromJson(Map<String, dynamic> json) {
    return ReservationRestaurantModel(
      maQuan: json['maQuan'] ?? json['maquan'] ?? 0,
      tenQuan: json['tenQuan'] ?? json['tenquan'] ?? json['name'] ?? 'Quán ăn',
      diaChi: json['diaChi'] ?? json['diachi'] ?? json['address'] ?? '',
      img: json['img'] ?? json['image'] ?? json['hinhAnh'] ?? json['avatar'],
      sdt: json['sdt'] ?? json['phone'] ?? json['soDienThoai'],
      gioHoatDong: json['gioHoatDong'] ?? json['giohoatdong'],
      coChoDatTruoc: json['coChoDatTruoc'] ?? json['cochodattruoc'] ?? true,
      danhGiaTrungBinh: double.tryParse((json['danhGiaTrungBinh'] ?? json['danhgiatb'] ?? 0).toString()) ?? 0.0,
      soLuongDanhGia: int.tryParse((json['soLuongDanhGia'] ?? json['soluotdanhgia'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maQuan': maQuan,
      'tenQuan': tenQuan,
      'diaChi': diaChi,
      'img': img,
      'sdt': sdt,
      'gioHoatDong': gioHoatDong,
      'coChoDatTruoc': coChoDatTruoc,
      'danhGiaTrungBinh': danhGiaTrungBinh,
      'soLuongDanhGia': soLuongDanhGia,
    };
  }
}

/// Model Đặt bàn chính thức
class ReservationModel {
  final int maDatBan;
  final int maQuan;
  final int? maKhachHang;
  final int maBan;
  final DateTime thoiGianBatDau;
  final DateTime thoiGianKetThuc;
  final int soNguoi;
  final String trangThai;
  final String? ghiChu;
  final String? tenKhachHang;
  final String? sdtKhachHang;
  final String? emailKhachHang;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ReservationTableModel? ban;
  final ReservationRestaurantModel? cuaHang;

  ReservationModel({
    required this.maDatBan,
    required this.maQuan,
    this.maKhachHang,
    required this.maBan,
    required this.thoiGianBatDau,
    required this.thoiGianKetThuc,
    required this.soNguoi,
    required this.trangThai,
    this.ghiChu,
    this.tenKhachHang,
    this.sdtKhachHang,
    this.emailKhachHang,
    this.createdAt,
    this.updatedAt,
    this.ban,
    this.cuaHang,
  });

  bool get isPending => trangThai.toUpperCase() == ReservationStatus.choXacNhan;
  bool get isConfirmed => trangThai.toUpperCase() == ReservationStatus.daXacNhan;
  bool get isSeated =>
      trangThai.toUpperCase() == ReservationStatus.daDen ||
      trangThai.toUpperCase() == ReservationStatus.dangSuDung;
  bool get isCompleted => trangThai.toUpperCase() == ReservationStatus.daHoanTat;
  bool get isCancelled => trangThai.toUpperCase() == ReservationStatus.daHuy;
  bool get isRejected => trangThai.toUpperCase() == ReservationStatus.tuChoi;
  bool get isNoShow => trangThai.toUpperCase() == ReservationStatus.khachKhongDen;

  bool get canCancel => isPending || isConfirmed;

  String get statusTitle => ReservationStatus.getTitle(trangThai);
  Color get statusColor => ReservationStatus.getColor(trangThai);

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      maDatBan: json['maDatBan'] ?? json['madatban'] ?? 0,
      maQuan: json['maQuan'] ?? json['maquan'] ?? 0,
      maKhachHang: json['maKhachHang'] ?? json['makhachhang'],
      maBan: json['maBan'] ?? json['maban'] ?? 0,
      thoiGianBatDau: json['thoiGianBatDau'] != null
          ? DateTime.parse(json['thoiGianBatDau'].toString()).toLocal()
          : DateTime.now(),
      thoiGianKetThuc: json['thoiGianKetThuc'] != null
          ? DateTime.parse(json['thoiGianKetThuc'].toString()).toLocal()
          : DateTime.now().add(const Duration(hours: 1, minutes: 30)),
      soNguoi: json['soNguoi'] ?? json['songuoi'] ?? 2,
      trangThai: json['trangThai'] ?? json['trangthai'] ?? ReservationStatus.choXacNhan,
      ghiChu: json['ghiChu'] ?? json['ghichu'],
      tenKhachHang: json['tenKhachHang'] ?? json['tenkhachhang'],
      sdtKhachHang: json['sdtKhachHang'] ?? json['sdtkhachhang'],
      emailKhachHang: json['emailKhachHang'] ?? json['emailkhachhang'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      ban: json['ban'] != null && json['ban'] is Map<String, dynamic>
          ? ReservationTableModel.fromJson(json['ban'])
          : null,
      cuaHang: () {
        final storeData = json['cuaHang'] ?? json['cuahang'] ?? json['restaurant'];
        if (storeData != null && storeData is Map<String, dynamic>) {
          return ReservationRestaurantModel.fromJson(storeData);
        }
        if (json['tenQuan'] != null || json['tenquan'] != null) {
          return ReservationRestaurantModel.fromJson(json);
        }
        return null;
      }(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maDatBan': maDatBan,
      'maQuan': maQuan,
      'maKhachHang': maKhachHang,
      'maBan': maBan,
      'thoiGianBatDau': thoiGianBatDau.toIso8601String(),
      'thoiGianKetThuc': thoiGianKetThuc.toIso8601String(),
      'soNguoi': soNguoi,
      'trangThai': trangThai,
      'ghiChu': ghiChu,
      'tenKhachHang': tenKhachHang,
      'sdtKhachHang': sdtKhachHang,
      'emailKhachHang': emailKhachHang,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (ban != null) 'ban': ban!.toJson(),
      if (cuaHang != null) 'cuaHang': cuaHang!.toJson(),
    };
  }

  ReservationModel copyWith({
    int? maDatBan,
    int? maQuan,
    int? maKhachHang,
    int? maBan,
    DateTime? thoiGianBatDau,
    DateTime? thoiGianKetThuc,
    int? soNguoi,
    String? trangThai,
    String? ghiChu,
    String? tenKhachHang,
    String? sdtKhachHang,
    String? emailKhachHang,
    DateTime? createdAt,
    DateTime? updatedAt,
    ReservationTableModel? ban,
    ReservationRestaurantModel? cuaHang,
  }) {
    return ReservationModel(
      maDatBan: maDatBan ?? this.maDatBan,
      maQuan: maQuan ?? this.maQuan,
      maKhachHang: maKhachHang ?? this.maKhachHang,
      maBan: maBan ?? this.maBan,
      thoiGianBatDau: thoiGianBatDau ?? this.thoiGianBatDau,
      thoiGianKetThuc: thoiGianKetThuc ?? this.thoiGianKetThuc,
      soNguoi: soNguoi ?? this.soNguoi,
      trangThai: trangThai ?? this.trangThai,
      ghiChu: ghiChu ?? this.ghiChu,
      tenKhachHang: tenKhachHang ?? this.tenKhachHang,
      sdtKhachHang: sdtKhachHang ?? this.sdtKhachHang,
      emailKhachHang: emailKhachHang ?? this.emailKhachHang,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ban: ban ?? this.ban,
      cuaHang: cuaHang ?? this.cuaHang,
    );
  }
}

/// Kết quả kiểm tra bàn trống (Availability)
class ReservationAvailabilityResult {
  final bool isOpen;
  final bool allowReservation;
  final bool hasTables;
  final String message;
  final List<ReservationTableModel> availableTables;

  const ReservationAvailabilityResult({
    required this.isOpen,
    required this.allowReservation,
    this.hasTables = true,
    required this.message,
    required this.availableTables,
  });

  factory ReservationAvailabilityResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final rawTables = data['availableTables'] as List<dynamic>? ?? [];
    return ReservationAvailabilityResult(
      isOpen: data['isOpen'] ?? true,
      allowReservation: data['allowReservation'] ?? data['canBook'] ?? (rawTables.isNotEmpty),
      hasTables: data['hasTables'] ?? true,
      message: data['message'] ?? '',
      availableTables: rawTables
          .map((e) => ReservationTableModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
