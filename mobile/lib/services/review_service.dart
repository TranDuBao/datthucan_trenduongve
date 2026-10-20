import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/globs.dart';
import '../models/review_model.dart';

import 'upload_service.dart';

class ReviewService {
  static Future<String?> uploadImageBase64(String base64Image) async {
    return await UploadService.uploadImageBase64(base64Image);
  }

  static Future<Map<String, dynamic>> submitReview({
    required int orderId,
    required int rating,
    String? comment,
    String? image,
    List<Map<String, dynamic>>? dishRatings,
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/orders/$orderId/review');

      final body = {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
        if (image != null && image.isNotEmpty) 'image': image,
        if (dishRatings != null && dishRatings.isNotEmpty) 'dishRatings': dishRatings,
      };

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final resJson = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': resJson['message'] ?? 'Gửi đánh giá thành công',
          'data': resJson['data'] != null ? ReviewModel.fromJson(resJson['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': resJson['message'] ?? 'Không thể gửi đánh giá',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối mạng: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    int? rating,
    String? comment,
    String? image,
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/reviews/$reviewId');

      final body = {
        if (rating != null) 'rating': rating,
        if (comment != null) 'comment': comment.trim(),
        if (image != null) 'image': image,
      };

      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final resJson = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': resJson['message'] ?? 'Cập nhật đánh giá thành công',
          'data': resJson['data'] != null ? ReviewModel.fromJson(resJson['data']) : null,
        };
      } else {
        return {
          'success': false,
          'message': resJson['message'] ?? 'Không thể cập nhật đánh giá',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối mạng: $e'};
    }
  }

  static Future<Map<String, dynamic>> fetchRestaurantReviews(int storeId, {int page = 1, int limit = 10}) async {
    try {
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/restaurants/$storeId/reviews?page=$page&limit=$limit');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        final data = resJson['data'] ?? {};
        final List<dynamic> list = data['reviews'] is List ? data['reviews'] : [];
        final reviews = list.map((item) => ReviewModel.fromJson(item)).toList();

        return {
          'success': true,
          'reviews': reviews,
          'total': data['total'] ?? 0,
          'totalPages': data['totalPages'] ?? 1,
        };
      } else {
        return {'success': false, 'reviews': <ReviewModel>[], 'total': 0, 'totalPages': 1};
      }
    } catch (e) {
      return {'success': false, 'reviews': <ReviewModel>[], 'total': 0, 'totalPages': 1};
    }
  }

  static Future<Map<String, dynamic>> fetchDishReviews(int dishId, {int page = 1, int limit = 10}) async {
    try {
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/foods/$dishId/reviews?page=$page&limit=$limit');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        final data = resJson['data'] ?? {};
        final List<dynamic> list = data['reviews'] is List ? data['reviews'] : [];
        final reviews = list.map((item) => ReviewModel.fromJson(item)).toList();

        return {
          'success': true,
          'reviews': reviews,
          'total': data['total'] ?? 0,
          'averageRating': double.tryParse((data['averageRating'] ?? 0.0).toString()) ?? 0.0,
          'totalPages': data['totalPages'] ?? 1,
        };
      } else {
        return {'success': false, 'reviews': <ReviewModel>[], 'total': 0, 'averageRating': 0.0, 'totalPages': 1};
      }
    } catch (e) {
      return {'success': false, 'reviews': <ReviewModel>[], 'total': 0, 'averageRating': 0.0, 'totalPages': 1};
    }
  }

  static Future<ReviewModel?> getReviewByOrder(int orderId) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/orders/$orderId/review');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['data'] != null) {
          return ReviewModel.fromJson(resJson['data']);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
