class StoreRegistrationModel {
  final int? maDon;
  final int? maTaiKhoan;
  final String tenQuan;
  final String? danhMuc;
  final String diaChi;
  final double? lat;
  final double? lng;
  final String sdt;
  final String hoTenChuQuan;
  final String? ngaySinhChuQuan;
  final String soCCCD;
  final String? diaChiThuongTru;
  final String tenNganHang;
  final String soTaiKhoanNganHang;
  final String tenChuTaiKhoan;
  final String? loaiHinhPhapLy;
  final String? maSoThue;
  final String? soGiayPhepKinhDoanh;
  final String? soGiayAttp;
  final int? maPhienBanDieuKhoan;
  final int? maPhienBanChinhSach;
  final DateTime? thoiGianDongY;
  final bool dongYDieuKhoan;
  final bool dongYChinhSachDuLieu;
  final String trangThai; // CHO_DUYET | DA_DUYET | TU_CHOI
  final String? lyDoTuChoi;
  final DateTime? ngayTao;
  final DateTime? ngayDuyet;

  StoreRegistrationModel({
    this.maDon,
    this.maTaiKhoan,
    required this.tenQuan,
    this.danhMuc,
    required this.diaChi,
    this.lat,
    this.lng,
    required this.sdt,
    required this.hoTenChuQuan,
    this.ngaySinhChuQuan,
    required this.soCCCD,
    this.diaChiThuongTru,
    required this.tenNganHang,
    required this.soTaiKhoanNganHang,
    required this.tenChuTaiKhoan,
    this.loaiHinhPhapLy,
    this.maSoThue,
    this.soGiayPhepKinhDoanh,
    this.soGiayAttp,
    this.maPhienBanDieuKhoan,
    this.maPhienBanChinhSach,
    this.thoiGianDongY,
    this.dongYDieuKhoan = false,
    this.dongYChinhSachDuLieu = false,
    this.trangThai = 'CHO_DUYET',
    this.lyDoTuChoi,
    this.ngayTao,
    this.ngayDuyet,
  });

  bool get isPending => trangThai == 'CHO_DUYET';
  bool get isApproved => trangThai == 'DA_DUYET';
  bool get isRejected => trangThai == 'TU_CHOI';

  factory StoreRegistrationModel.fromJson(Map<String, dynamic> json) {
    return StoreRegistrationModel(
      maDon: json['maDon'] != null ? int.tryParse(json['maDon'].toString()) : null,
      maTaiKhoan: json['maTaiKhoan'] != null ? int.tryParse(json['maTaiKhoan'].toString()) : null,
      tenQuan: json['tenQuan']?.toString() ?? '',
      danhMuc: json['danhMuc']?.toString(),
      diaChi: json['diaChi']?.toString() ?? '',
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      sdt: json['sdt']?.toString() ?? '',
      hoTenChuQuan: json['hoTenChuQuan']?.toString() ?? '',
      ngaySinhChuQuan: json['ngaySinhChuQuan']?.toString(),
      soCCCD: json['soCCCD']?.toString() ?? '',
      diaChiThuongTru: json['diaChiThuongTru']?.toString(),
      tenNganHang: json['tenNganHang']?.toString() ?? '',
      soTaiKhoanNganHang: json['soTaiKhoanNganHang']?.toString() ?? '',
      tenChuTaiKhoan: json['tenChuTaiKhoan']?.toString() ?? '',
      loaiHinhPhapLy: json['loaiHinhPhapLy']?.toString(),
      maSoThue: json['maSoThue']?.toString(),
      soGiayPhepKinhDoanh: json['soGiayPhepKinhDoanh']?.toString(),
      soGiayAttp: json['soGiayAttp']?.toString(),
      maPhienBanDieuKhoan: json['maPhienBanDieuKhoan'] != null ? int.tryParse(json['maPhienBanDieuKhoan'].toString()) : null,
      maPhienBanChinhSach: json['maPhienBanChinhSach'] != null ? int.tryParse(json['maPhienBanChinhSach'].toString()) : null,
      thoiGianDongY: json['thoiGianDongY'] != null ? DateTime.tryParse(json['thoiGianDongY'].toString()) : null,
      dongYDieuKhoan: json['dongYDieuKhoan'] == true,
      dongYChinhSachDuLieu: json['dongYChinhSachDuLieu'] == true,
      trangThai: (json['trangThai']?.toString() ?? 'CHO_DUYET').toUpperCase(),
      lyDoTuChoi: json['lyDoTuChoi']?.toString(),
      ngayTao: json['ngayTao'] != null ? DateTime.tryParse(json['ngayTao'].toString()) : null,
      ngayDuyet: json['ngayDuyet'] != null ? DateTime.tryParse(json['ngayDuyet'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenQuan': tenQuan,
      if (danhMuc != null) 'danhMuc': danhMuc,
      'diaChi': diaChi,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      'sdt': sdt,
      'hoTenChuQuan': hoTenChuQuan,
      if (ngaySinhChuQuan != null) 'ngaySinhChuQuan': ngaySinhChuQuan,
      'soCCCD': soCCCD,
      if (diaChiThuongTru != null) 'diaChiThuongTru': diaChiThuongTru,
      'tenNganHang': tenNganHang,
      'soTaiKhoanNganHang': soTaiKhoanNganHang,
      'tenChuTaiKhoan': tenChuTaiKhoan,
      if (loaiHinhPhapLy != null) 'loaiHinhPhapLy': loaiHinhPhapLy,
      if (maSoThue != null) 'maSoThue': maSoThue,
      if (soGiayPhepKinhDoanh != null) 'soGiayPhepKinhDoanh': soGiayPhepKinhDoanh,
      if (soGiayAttp != null) 'soGiayAttp': soGiayAttp,
      if (maPhienBanDieuKhoan != null) 'maPhienBanDieuKhoan': maPhienBanDieuKhoan,
      if (maPhienBanChinhSach != null) 'maPhienBanChinhSach': maPhienBanChinhSach,
      'dongYDieuKhoan': dongYDieuKhoan,
      'dongYChinhSachDuLieu': dongYChinhSachDuLieu,
    };
  }
}

