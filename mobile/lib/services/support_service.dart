import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/globs.dart';
import '../model/support_model.dart';

class SupportService {
  /// Lấy cấu hình liên hệ công khai (Hotline, Giờ làm việc, Email)
  static Future<SupportConfigModel?> getPublicConfig() async {
    try {
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/support/config');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['success'] == true && resJson['data'] != null) {
          return SupportConfigModel.fromJson(resJson['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[SupportService] getPublicConfig error: $e');
      return null;
    }
  }

  /// Lấy danh sách câu hỏi FAQ công khai theo nhóm
  static Future<List<FaqGroupModel>> getPublicFaqs() async {
    try {
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/support/faq');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['success'] == true && resJson['data'] is List) {
          final list = resJson['data'] as List;
          return list.map((g) => FaqGroupModel.fromJson(g as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SupportService] getPublicFaqs error: $e');
      return [];
    }
  }

  /// Gửi góp ý / phản hồi từ người dùng
  static Future<Map<String, dynamic>> submitFeedback(SupportFeedbackRequest request) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/support/feedback');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final resJson = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': resJson['message'] ?? 'Gửi góp ý thành công!',
          'data': resJson['data'],
        };
      } else {
        return {
          'success': false,
          'message': resJson['message'] ?? 'Gửi góp ý thất bại. Vui lòng thử lại!',
        };
      }
    } catch (e) {
      debugPrint('[SupportService] submitFeedback error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối máy chủ: $e',
      };
    }
  }

  /// Tạo phiếu hỗ trợ mới
  static Future<SupportTicketModel?> createTicket(CreateTicketRequest request) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/support/tickets');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      final resJson = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && resJson['success'] == true) {
        return SupportTicketModel.fromJson(resJson['data']);
      }
      return null;
    } catch (e) {
      debugPrint('[SupportService] createTicket error: $e');
      return null;
    }
  }

  /// Lấy danh sách phiếu của người dùng hiện tại
  static Future<List<SupportTicketModel>> getMyTickets({int page = 1, String? status}) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': '30',
        if (status != null && status != 'ALL') 'status': status,
      };

      final url = Uri.parse('${SVKey.mainUrl}/api/v1/support/tickets/my').replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['success'] == true && resJson['items'] is List) {
          final list = resJson['items'] as List;
          return list.map((item) => SupportTicketModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SupportService] getMyTickets error: $e');
      return [];
    }
  }

  /// Chi tiết một phiếu hỗ trợ
  static Future<SupportTicketModel?> getTicketDetail(int ticketId) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/support/tickets/$ticketId');

      final response = await http.get(
        url,
        headers: {
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['success'] == true && resJson['data'] != null) {
          return SupportTicketModel.fromJson(resJson['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[SupportService] getTicketDetail error: $e');
      return null;
    }
  }

  /// Lấy lịch sử tin nhắn của phiếu
  static Future<List<SupportTicketMessageModel>> getTicketMessages(int ticketId, {int? beforeId}) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final queryParams = <String, String>{
        'limit': '50',
        if (beforeId != null) 'beforeId': beforeId.toString(),
      };

      final url = Uri.parse('${SVKey.mainUrl}/api/v1/support/tickets/$ticketId/messages').replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['success'] == true && resJson['data'] is List) {
          final list = resJson['data'] as List;
          return list.map((item) => SupportTicketMessageModel.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SupportService] getTicketMessages error: $e');
      return [];
    }
  }

  /// Gửi tin nhắn mới vào phiếu
  static Future<SupportTicketMessageModel?> sendTicketMessage(
    int ticketId, {
    required String noiDung,
    List<String> danhSachAnh = const [],
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/support/tickets/$ticketId/messages');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              if (token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'noiDung': noiDung,
              if (danhSachAnh.isNotEmpty) 'danhSachAnh': danhSachAnh,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final resJson = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && resJson['success'] == true) {
        return SupportTicketMessageModel.fromJson(resJson['data']);
      }
      return null;
    } catch (e) {
      debugPrint('[SupportService] sendTicketMessage error: $e');
      return null;
    }
  }

  /// Đánh dấu đã đọc các tin nhắn trong phiếu
  static Future<void> markTicketMessagesAsRead(int ticketId) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/support/tickets/$ticketId/read');

      await http.post(
        url,
        headers: {
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[SupportService] markTicketMessagesAsRead error: $e');
    }
  }
}
