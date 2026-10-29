import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/globs.dart';
import '../models/banner_item_model.dart';

class BannerService {
  static Future<List<BannerItemModel>> fetchBanners() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/banners');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> res = json.decode(response.body);
        final List<dynamic> data = res['data'] ?? [];
        return data.map((item) => BannerItemModel.fromJson(item)).toList();
      }
    } catch (e) {
      // ignore: avoid_print
      print('[BannerService] [Error] Error fetchBanners: $e');
    }
    return [];
  }
}
