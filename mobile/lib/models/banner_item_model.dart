class BannerItemModel {
  final int maBanner;
  final String tieuDe;
  final String phuDe;
  final String hinhAnh;
  final String? lienKet;
  final String mauSac;
  final int thuTu;
  final String trangThai;
  final String loaiBanner;

  BannerItemModel({
    required this.maBanner,
    required this.tieuDe,
    this.phuDe = '',
    required this.hinhAnh,
    this.lienKet,
    this.mauSac = '#FC6011',
    this.thuTu = 0,
    this.trangThai = 'HOAT_DONG',
    this.loaiBanner = 'TRAN_VIEN',
  });

  factory BannerItemModel.fromJson(Map<String, dynamic> json) {
    return BannerItemModel(
      maBanner: json['maBanner'] ?? json['mabanner'] ?? 0,
      tieuDe: json['tieuDe'] ?? json['tieude'] ?? '',
      phuDe: json['phuDe'] ?? json['phude'] ?? '',
      hinhAnh: json['hinhAnh'] ?? json['hinhanh'] ?? '',
      lienKet: json['lienKet'] ?? json['lienket'],
      mauSac: json['mauSac'] ?? json['mausac'] ?? '#FC6011',
      thuTu: json['thuTu'] ?? json['thutu'] ?? 0,
      trangThai: json['trangThai'] ?? json['trangthai'] ?? 'HOAT_DONG',
      loaiBanner: json['loaiBanner'] ?? json['loaibanner'] ?? 'TRAN_VIEN',
    );
  }
}
