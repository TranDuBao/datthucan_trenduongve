import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class VoucherModel {
  final int id;
  final String code;
  final String name;
  final double discount;
  final String discountType; // 'VND', 'PERCENT'
  final double maxDiscount;
  final double minOrder;
  final String? expiryDate;
  final String tag;
  final String description;
  final bool isVip;
  final int soLuongToiDa;
  final int soLuongDaLuu;
  final int soLuongDaSuDung;
  final String computedStatus;
  final bool isCollected;
  final int? maQuan;
  final String? trangThai;

  VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    required this.discount,
    required this.discountType,
    required this.maxDiscount,
    required this.minOrder,
    this.expiryDate,
    required this.tag,
    required this.description,
    this.isVip = false,
    this.soLuongToiDa = 0,
    this.soLuongDaLuu = 0,
    this.soLuongDaSuDung = 0,
    this.computedStatus = 'DANG_HOAT_DONG',
    this.isCollected = false,
    this.maQuan,
    this.trangThai,
  });

  bool get isExpired {
    if (computedStatus == 'HET_HAN') return true;
    if (expiryDate != null && expiryDate!.isNotEmpty) {
      try {
        final dt = DateTime.parse(expiryDate!);
        if (dt.isBefore(DateTime.now())) return true;
      } catch (_) {}
    }
    return false;
  }

  bool get isExhausted {
    if (computedStatus == 'HET_LUOT') return true;
    if (soLuongToiDa > 0 && (soLuongDaLuu >= soLuongToiDa || soLuongDaSuDung >= soLuongToiDa)) {
      return true;
    }
    return false;
  }

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['maVoucher'] ?? json['id'] ?? 0,
      code: json['maCode'] ?? json['code'] ?? '',
      name: json['tenVoucher'] ?? json['name'] ?? '',
      discount: double.parse((json['giamGia'] ?? json['discount'] ?? 0).toString()),
      discountType: json['loaiGiam'] ?? 'VND',
      maxDiscount: double.parse((json['giaTriGiamToiDa'] ?? 0).toString()),
      minOrder: double.parse((json['dieuKienDonToiThieu'] ?? 0).toString()),
      expiryDate: json['ngayHetHan'] != null ? json['ngayHetHan'].toString() : null,
      tag: json['tag'] ?? (json['loaiGiam'] == 'PERCENT' ? 'MÃ GIẢM GIÁ' : 'ƯU ĐÃI'),
      description: json['description'] ?? json['moTa'] ?? 'Áp dụng cho mọi đơn hàng đủ điều kiện.',
      isVip: json['isVip'] ?? false,
      soLuongToiDa: int.tryParse((json['soLuongToiDa'] ?? 0).toString()) ?? 0,
      soLuongDaLuu: int.tryParse((json['soLuongDaLuu'] ?? 0).toString()) ?? 0,
      soLuongDaSuDung: int.tryParse((json['soLuongDaSuDung'] ?? 0).toString()) ?? 0,
      computedStatus: json['computedStatus'] ?? json['trangThai'] ?? 'DANG_HOAT_DONG',
      isCollected: json['isCollected'] ?? json['daLuu'] ?? false,
      maQuan: json['maQuan'] != null ? int.tryParse(json['maQuan'].toString()) : null,
      trangThai: json['trangThai']?.toString(),
    );
  }
}

class VoucherService {
  static Future<List<VoucherModel>> fetchVouchers({int? maQuan}) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final query = maQuan != null ? '?maQuan=$maQuan' : '';
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/vouchers$query');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final resJson = json.decode(response.body);
        final List<dynamic> list = resJson['data'] is List ? resJson['data'] : [];
        return list
            .map((item) => VoucherModel.fromJson(item))
            .where((v) {
              if (v.code.toUpperCase().contains('FREESHIP') || v.name.toLowerCase().contains('freeship')) {
                return false;
              }
              if (v.computedStatus == 'TAM_TAT' || v.trangThai == 'TAM_TAT' || v.isExpired || v.isExhausted) {
                return false;
              }
              if (maQuan != null && v.maQuan != null && v.maQuan != maQuan) {
                return false;
              }
              return true;
            })
            .toList();
      }
    } catch (e) {
      // Return empty list if network fails
    }

    return [];
  }

  static Future<Map<String, dynamic>> collectVoucher(int maVoucher) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/vouchers/collect');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'maVoucher': maVoucher}),
      ).timeout(const Duration(seconds: 5));

      final resJson = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': resJson['message'] ?? 'Lưu voucher thành công!'};
      } else {
        return {'success': false, 'message': resJson['message'] ?? 'Không thể lưu voucher'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối máy chủ'};
    }
  }

  static Future<List<VoucherModel>> fetchMyCollectedVouchers() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/vouchers/my-vouchers');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final resJson = json.decode(response.body);
        final List<dynamic> list = resJson['data'] is List ? resJson['data'] : [];
        return list
            .map((item) => VoucherModel.fromJson(item))
            .where((v) => !v.code.toUpperCase().contains('FREESHIP') && !v.name.toLowerCase().contains('freeship'))
            .toList();
      }
    } catch (e) {
      // Return empty list if network fails
    }

    return [];
  }
}
