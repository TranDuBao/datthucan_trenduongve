import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class SystemInfoService {
  static Future<Map<String, dynamic>?> fetchAboutUs() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/system/about-us');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> res = json.decode(response.body);
        if (res['status'] == 'success' && res['data'] is Map) {
          return Map<String, dynamic>.from(res['data']);
        }
      }
    } catch (e) {
      debugPrint('[SystemInfoService] [Error] Error fetchAboutUs: $e');
    }
    return null;
  }
}
