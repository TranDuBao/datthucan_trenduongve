import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class UploadService {
  /// Upload base64 image to backend and return relative image URL (e.g. /uploads/img_....jpg)
  static Future<String?> uploadImageBase64(String base64Image) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/upload/base64');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'image': base64Image}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        final rawUrl = resJson['url'] ?? resJson['data'];
        if (rawUrl != null && rawUrl.toString().isNotEmpty) {
          final cleanUrl = rawUrl.toString().trim();
          // Always return relative path e.g. /uploads/img_....jpg
          if (cleanUrl.contains('/uploads/')) {
            final fileName = cleanUrl.split('/uploads/').last;
            return '/uploads/$fileName';
          }
          return cleanUrl;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
