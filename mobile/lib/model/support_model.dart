class SupportConfigModel {
  final int? id;
  final String hotline;
  final String gioLamViec;
  final String emailHoTro;
  final DateTime? updatedAt;

  SupportConfigModel({
    this.id,
    required this.hotline,
    required this.gioLamViec,
    required this.emailHoTro,
    this.updatedAt,
  });

  factory SupportConfigModel.fromJson(Map<String, dynamic> json) {
    return SupportConfigModel(
      id: json['id'] as int?,
      hotline: json['hotline']?.toString() ?? '1900 6868',
      gioLamViec: json['gioLamViec']?.toString() ?? '08:00 - 22:00 hàng ngày',
      emailHoTro: json['emailHoTro']?.toString() ?? 'support@foodroute.vn',
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotline': hotline,
      'gioLamViec': gioLamViec,
      'emailHoTro': emailHoTro,
    };
  }
}

class FaqQuestionModel {
  final int maFaq;
  final int maNhom;
  final String cauHoi;
  final String cauTraLoi;
  final int thuTu;
  final bool kichHoat;

  FaqQuestionModel({
    required this.maFaq,
    required this.maNhom,
    required this.cauHoi,
    required this.cauTraLoi,
    this.thuTu = 0,
    this.kichHoat = true,
  });

  factory FaqQuestionModel.fromJson(Map<String, dynamic> json) {
    return FaqQuestionModel(
      maFaq: json['maFaq'] is int ? json['maFaq'] : int.tryParse(json['maFaq']?.toString() ?? '0') ?? 0,
      maNhom: json['maNhom'] is int ? json['maNhom'] : int.tryParse(json['maNhom']?.toString() ?? '0') ?? 0,
      cauHoi: json['cauHoi']?.toString() ?? '',
      cauTraLoi: json['cauTraLoi']?.toString() ?? '',
      thuTu: json['thuTu'] is int ? json['thuTu'] : int.tryParse(json['thuTu']?.toString() ?? '0') ?? 0,
      kichHoat: json['kichHoat'] == true,
    );
  }
}

class FaqGroupModel {
  final int maNhom;
  final String tenNhom;
  final int thuTu;
  final bool kichHoat;
  final List<FaqQuestionModel> cauHoi;

  FaqGroupModel({
    required this.maNhom,
    required this.tenNhom,
    this.thuTu = 0,
    this.kichHoat = true,
    this.cauHoi = const [],
  });

  factory FaqGroupModel.fromJson(Map<String, dynamic> json) {
    var rawList = json['cauHoi'] as List? ?? [];
    List<FaqQuestionModel> questions = rawList
        .map((q) => FaqQuestionModel.fromJson(q as Map<String, dynamic>))
        .toList();

    return FaqGroupModel(
      maNhom: json['maNhom'] is int ? json['maNhom'] : int.tryParse(json['maNhom']?.toString() ?? '0') ?? 0,
      tenNhom: json['tenNhom']?.toString() ?? '',
      thuTu: json['thuTu'] is int ? json['thuTu'] : int.tryParse(json['thuTu']?.toString() ?? '0') ?? 0,
      kichHoat: json['kichHoat'] == true,
      cauHoi: questions,
    );
  }
}

class SupportFeedbackRequest {
  final String loaiGopY;
  final String noiDung;
  final int? danhGiaSao;
  final List<String> danhSachAnh;

  SupportFeedbackRequest({
    required this.loaiGopY,
    required this.noiDung,
    this.danhGiaSao,
    this.danhSachAnh = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'loaiGopY': loaiGopY,
      'noiDung': noiDung,
      if (danhGiaSao != null && danhGiaSao! > 0) 'danhGiaSao': danhGiaSao,
      if (danhSachAnh.isNotEmpty) 'danhSachAnh': danhSachAnh,
    };
  }
}

class SupportTicketModel {
  final int maPhieu;
  final int maTaiKhoan;
  final String? tieuDe;
  final String loaiSuCo;
  final String moTa;
  final int? maDonHang;
  final List<String> danhSachAnh;
  final String trangThai; // MOI, DANG_XU_LY, DA_GIAI_QUYET, DA_DONG
  final int soTinChuaDocUser;
  final int soTinChuaDocAdmin;
  final String? tinNhanCuoi;
  final DateTime? thoiGianTinCuoi;
  final DateTime ngayTao;
  final DateTime ngayCapNhat;

  SupportTicketModel({
    required this.maPhieu,
    required this.maTaiKhoan,
    this.tieuDe,
    required this.loaiSuCo,
    required this.moTa,
    this.maDonHang,
    this.danhSachAnh = const [],
    required this.trangThai,
    this.soTinChuaDocUser = 0,
    this.soTinChuaDocAdmin = 0,
    this.tinNhanCuoi,
    this.thoiGianTinCuoi,
    required this.ngayTao,
    required this.ngayCapNhat,
  });

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['danhSachAnh'] is List) {
      images = (json['danhSachAnh'] as List).map((e) => e.toString()).toList();
    }

    return SupportTicketModel(
      maPhieu: json['maPhieu'] is int ? json['maPhieu'] : int.tryParse(json['maPhieu']?.toString() ?? '0') ?? 0,
      maTaiKhoan: json['maTaiKhoan'] is int ? json['maTaiKhoan'] : int.tryParse(json['maTaiKhoan']?.toString() ?? '0') ?? 0,
      tieuDe: json['tieuDe']?.toString(),
      loaiSuCo: json['loaiSuCo']?.toString() ?? 'KHAC',
      moTa: json['moTa']?.toString() ?? '',
      maDonHang: json['maDonHang'] != null ? int.tryParse(json['maDonHang'].toString()) : null,
      danhSachAnh: images,
      trangThai: json['trangThai']?.toString() ?? 'MOI',
      soTinChuaDocUser: json['soTinChuaDocUser'] is int ? json['soTinChuaDocUser'] : int.tryParse(json['soTinChuaDocUser']?.toString() ?? '0') ?? 0,
      soTinChuaDocAdmin: json['soTinChuaDocAdmin'] is int ? json['soTinChuaDocAdmin'] : int.tryParse(json['soTinChuaDocAdmin']?.toString() ?? '0') ?? 0,
      tinNhanCuoi: json['tinNhanCuoi']?.toString(),
      thoiGianTinCuoi: json['thoiGianTinCuoi'] != null ? DateTime.tryParse(json['thoiGianTinCuoi'].toString()) : null,
      ngayTao: json['ngayTao'] != null ? DateTime.tryParse(json['ngayTao'].toString()) ?? DateTime.now() : DateTime.now(),
      ngayCapNhat: json['ngayCapNhat'] != null ? DateTime.tryParse(json['ngayCapNhat'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class SupportTicketMessageModel {
  final int maTinNhan;
  final int maPhieu;
  final int maTaiKhoanGui;
  final String vaiTroGui; // USER, ADMIN, STORE
  final String noiDung;
  final List<String> danhSachAnh;
  final bool daXem;
  final DateTime? thoiGianXem;
  final DateTime ngayTao;

  SupportTicketMessageModel({
    required this.maTinNhan,
    required this.maPhieu,
    required this.maTaiKhoanGui,
    required this.vaiTroGui,
    required this.noiDung,
    this.danhSachAnh = const [],
    this.daXem = false,
    this.thoiGianXem,
    required this.ngayTao,
  });

  factory SupportTicketMessageModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['danhSachAnh'] is List) {
      images = (json['danhSachAnh'] as List).map((e) => e.toString()).toList();
    }

    return SupportTicketMessageModel(
      maTinNhan: json['maTinNhan'] is int ? json['maTinNhan'] : int.tryParse(json['maTinNhan']?.toString() ?? '0') ?? 0,
      maPhieu: json['maPhieu'] is int ? json['maPhieu'] : int.tryParse(json['maPhieu']?.toString() ?? '0') ?? 0,
      maTaiKhoanGui: json['maTaiKhoanGui'] is int ? json['maTaiKhoanGui'] : int.tryParse(json['maTaiKhoanGui']?.toString() ?? '0') ?? 0,
      vaiTroGui: json['vaiTroGui']?.toString() ?? 'USER',
      noiDung: json['noiDung']?.toString() ?? '',
      danhSachAnh: images,
      daXem: json['daXem'] == true,
      thoiGianXem: json['thoiGianXem'] != null ? DateTime.tryParse(json['thoiGianXem'].toString()) : null,
      ngayTao: json['ngayTao'] != null ? DateTime.tryParse(json['ngayTao'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class CreateTicketRequest {
  final String loaiSuCo;
  final String moTa;
  final String? tieuDe;
  final int? maDonHang;
  final List<String> danhSachAnh;

  CreateTicketRequest({
    required this.loaiSuCo,
    required this.moTa,
    this.tieuDe,
    this.maDonHang,
    this.danhSachAnh = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'loaiSuCo': loaiSuCo,
      'moTa': moTa,
      if (tieuDe != null && tieuDe!.isNotEmpty) 'tieuDe': tieuDe,
      if (maDonHang != null) 'maDonHang': maDonHang,
      if (danhSachAnh.isNotEmpty) 'danhSachAnh': danhSachAnh,
    };
  }
}
