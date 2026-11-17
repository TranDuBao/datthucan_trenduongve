import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class UploadService {
  /// Upload base64 image to backend and return relative image URL (e.g. /uploads/img_....jpg) or CDN URL
  static Future<String?> uploadImageBase64(String base64Image) async {
    try {
      var token = Globs.udValueString(KKey.authToken);
      if (token.isEmpty) {
        final payload = Globs.udValue(Globs.userPayload);
        if (payload is Map) {
          token = (payload['accessToken'] ?? payload[KKey.authToken] ?? '').toString();
        }
      }

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
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        final rawUrl = resJson['url'] ?? resJson['data'];
        if (rawUrl != null && rawUrl.toString().isNotEmpty) {
          final cleanUrl = rawUrl.toString().trim();
          // Full remote URL (e.g. Cloudinary, HTTPS CDN) -> return directly
          if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
            return cleanUrl;
          }
          // Relative path e.g. /uploads/img_....jpg
          if (cleanUrl.contains('/uploads/')) {
            final fileName = cleanUrl.split('/uploads/').last;
            return '/uploads/$fileName';
          }
          return cleanUrl;
        }
      } else {
        debugPrint('[UploadService] Upload failed (${response.statusCode}): ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('[UploadService] Upload exception: $e');
      return null;
    }
  }
}
