class LegalDocumentItem {
  final int maPhienBan;
  final String loaiTaiLieu;
  final String soPhienBan;
  final String tieuDe;
  final String noiDung;
  final String trangThai;
  final String? ngayHieuLuc;

  LegalDocumentItem({
    required this.maPhienBan,
    required this.loaiTaiLieu,
    required this.soPhienBan,
    required this.tieuDe,
    required this.noiDung,
    required this.trangThai,
    this.ngayHieuLuc,
  });

  factory LegalDocumentItem.fromJson(Map<String, dynamic> json) {
    return LegalDocumentItem(
      maPhienBan: json['maPhienBan'] ?? json['maphienban'] ?? 0,
      loaiTaiLieu: json['loaiTaiLieu'] ?? json['loaitailieu'] ?? '',
      soPhienBan: json['soPhienBan'] ?? json['sophienban'] ?? '1.0',
      tieuDe: json['tieuDe'] ?? json['tieude'] ?? '',
      noiDung: json['noiDung'] ?? json['noidung'] ?? '',
      trangThai: json['trangThai'] ?? json['trangthai'] ?? 'DANG_HIEU_LUC',
      ngayHieuLuc: json['ngayHieuLuc']?.toString() ?? json['ngayhieuluc']?.toString(),
    );
  }
}

class ActiveLegalDocumentsResponse {
  final LegalDocumentItem? dieuKhoan;
  final LegalDocumentItem? chinhSach;

  ActiveLegalDocumentsResponse({
    this.dieuKhoan,
    this.chinhSach,
  });

  bool get isReady => dieuKhoan != null && chinhSach != null;

  factory ActiveLegalDocumentsResponse.fromJson(Map<String, dynamic> json) {
    return ActiveLegalDocumentsResponse(
      dieuKhoan: json['dieuKhoan'] != null ? LegalDocumentItem.fromJson(json['dieuKhoan']) : null,
      chinhSach: json['chinhSach'] != null ? LegalDocumentItem.fromJson(json['chinhSach']) : null,
    );
  }
}

