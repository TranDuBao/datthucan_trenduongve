import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/globs.dart';
import '../common/service_call.dart';
import '../models/reservation_model.dart';

class ReservationService {
  static String _formatDateTimeWithTimezone(DateTime dt) {
    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${dt.toIso8601String()}$sign$hours:$minutes';
  }

  /// Tạo lượt đặt bàn mới
  static Future<Map<String, dynamic>> createReservation({
    required int restaurantId,
    required DateTime startTime,
    required int guestCount,
    int? tableId,
    String? customerName,
    String? customerPhone,
    String? note,
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse(SVKey.svReservations);

      final Map<String, dynamic> payload = {
        'maQuan': restaurantId,
        'thoiGianBatDau': _formatDateTimeWithTimezone(startTime),
        'soNguoi': guestCount,
      };

      if (tableId != null && tableId > 0) {
        payload['maBan'] = tableId;
      }
      if (customerName != null && customerName.trim().isNotEmpty) {
        payload['tenKhachHang'] = customerName.trim();
      }
      if (customerPhone != null && customerPhone.trim().isNotEmpty) {
        payload['sdtKhachHang'] = customerPhone.trim();
      }
      if (note != null && note.trim().isNotEmpty) {
        payload['ghiChu'] = note.trim();
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));

      final resJson = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': resJson['message'] ?? 'Đặt bàn thành công!',
          'data': resJson['data'] != null ? ReservationModel.fromJson(resJson['data']) : null,
        };
      } else {
        if (response.statusCode == 401) {
          ServiceCall.logout();
        }
        return {
          'success': false,
          'message': resJson['message'] ?? 'Không thể đặt bàn. Vui lòng thử lại!',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Kết nối quá thời gian chờ (Timeout). Vui lòng thử lại!',
      };
    } catch (e) {
      debugPrint('[ReservationService] [Error] createReservation error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối máy chủ: $e',
      };
    }
  }

  /// Lấy danh sách lượt đặt bàn của khách hàng đang đăng nhập
  static Future<Map<String, dynamic>> fetchMyReservations({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final url = Uri.parse('${SVKey.svReservations}/my-reservations')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final resJson = json.decode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> rawList = resJson['data'] ?? [];
        final reservations = rawList
            .map((item) => ReservationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        final pagination = resJson['pagination'] ?? {};
        return {
          'success': true,
          'reservations': reservations,
          'total': pagination['total'] ?? reservations.length,
          'totalPages': pagination['totalPages'] ?? 1,
        };
      } else {
        if (response.statusCode == 401) {
          ServiceCall.logout();
        }
        return {
          'success': false,
          'message': resJson['message'] ?? 'Không thể tải danh sách đặt bàn',
          'reservations': <ReservationModel>[],
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Kết nối quá thời gian chờ (Timeout).',
        'reservations': <ReservationModel>[],
      };
    } catch (e) {
      debugPrint('[ReservationService] [Error] fetchMyReservations error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối máy chủ: $e',
        'reservations': <ReservationModel>[],
      };
    }
  }

  /// Lấy chi tiết một lượt đặt bàn
  static Future<Map<String, dynamic>> fetchReservationDetail(int reservationId) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.svReservations}/$reservationId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final resJson = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'reservation': resJson['data'] != null
              ? ReservationModel.fromJson(resJson['data'])
              : null,
        };
      } else {
        if (response.statusCode == 401) {
          ServiceCall.logout();
        }
        return {
          'success': false,
          'message': resJson['message'] ?? 'Không tìm thấy thông tin đặt bàn',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Kết nối quá thời gian chờ (Timeout).',
      };
    } catch (e) {
      debugPrint('[ReservationService] [Error] fetchReservationDetail error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối máy chủ: $e',
      };
    }
  }

  /// Khách hàng hủy đặt bàn
  static Future<Map<String, dynamic>> cancelReservation({
    required int reservationId,
    String? reason,
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.svReservations}/$reservationId/cancel');

      final body = <String, dynamic>{};
      if (reason != null && reason.trim().isNotEmpty) {
        body['lyDoHuy'] = reason.trim();
      }

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      final resJson = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': resJson['message'] ?? 'Hủy đặt bàn thành công',
          'data': resJson['data'] != null ? ReservationModel.fromJson(resJson['data']) : null,
        };
      } else {
        if (response.statusCode == 401) {
          ServiceCall.logout();
        }
        return {
          'success': false,
          'message': resJson['message'] ?? 'Không thể hủy đặt bàn',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Kết nối quá thời gian chờ (Timeout).',
      };
    } catch (e) {
      debugPrint('[ReservationService] [Error] cancelReservation error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối máy chủ: $e',
      };
    }
  }

  /// Kiểm tra bàn trống và giờ mở cửa tại quán
  static Future<ReservationAvailabilityResult> checkAvailability({
    required int restaurantId,
    required DateTime startTime,
    required int guestCount,
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse(SVKey.svRestaurantAvailability(restaurantId)).replace(
        queryParameters: {
          'thoiGianBatDau': _formatDateTimeWithTimezone(startTime),
          'soNguoi': guestCount.toString(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final resJson = json.decode(response.body);

      if (response.statusCode == 200) {
        return ReservationAvailabilityResult.fromJson(resJson);
      } else {
        if (response.statusCode == 401) {
          ServiceCall.logout();
        }
        return ReservationAvailabilityResult(
          isOpen: resJson['isOpen'] ?? false,
          allowReservation: resJson['allowReservation'] ?? false,
          message: resJson['message'] ?? 'Không thể kiểm tra tình trạng bàn.',
          availableTables: const [],
        );
      }
    } catch (e) {
      debugPrint('[ReservationService] [Error] checkAvailability error: $e');
      return ReservationAvailabilityResult(
        isOpen: false,
        allowReservation: false,
        message: 'Lỗi kiểm tra bàn: $e',
        availableTables: const [],
      );
    }
  }
}
