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
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      id: json['maVoucher'] ?? json['id'] ?? 0,
      code: json['maCode'] ?? json['code'] ?? '',
      name: json['tenVoucher'] ?? json['name'] ?? '',
      discount: double.parse((json['giamGia'] ?? json['discount'] ?? 0).toString()),
      discountType: json['loaiGiam'] ?? 'VND',
      maxDiscount: double.parse((json['giaTriGiamToiDa'] ?? 0).toString()),
      minOrder: double.parse((json['dieuKienDonToiThieu'] ?? 0).toString()),
      expiryDate: json['ngayHetHan'],
      tag: json['tag'] ?? (json['loaiGiam'] == 'PERCENT' ? 'MÃ GIẢM GIÁ' : 'ƯU ĐÃI'),
      description: json['description'] ?? json['moTa'] ?? 'Áp dụng cho mọi đơn hàng đủ điều kiện.',
      isVip: json['isVip'] ?? false,
    );
  }
}

class VoucherService {
  static Future<List<VoucherModel>> fetchVouchers() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/vouchers');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body.map((item) => VoucherModel.fromJson(item)).toList();
      }
    } catch (e) {
      // Return empty list if backend/DB has no vouchers
    }

    // STRICT RULE: No hardcoded fake data! Extract strictly from database response.
    return [];
  }
}
