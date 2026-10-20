import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class RestaurantOwnerService {
  Map<String, String> get _headers {
    final token = Globs.udValueString(KKey.authToken);
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Đơn hàng ─────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    String? period,
    String? search,
    int? page,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'ALL') queryParams['status'] = status;
    if (period != null && period.isNotEmpty) queryParams['period'] = period;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (page != null) queryParams['page'] = page.toString();
    if (limit != null) queryParams['limit'] = limit.toString();

    final uri = Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/orders').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = body['data'];
        if (data is Map && data['items'] is List) {
          return List<Map<String, dynamic>>.from(data['items']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint('[RestaurantOwnerService] getOrders error: $e');
    }
    return [];
  }

  Future<bool> updateOrderStatus(int orderId, String newStatus, {String? lyDo}) async {
    try {
      final res = await http.put(
        Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/orders/$orderId/status'),
        headers: _headers,
        body: json.encode({
          'trangThai': newStatus,
          if (lyDo != null && lyDo.isNotEmpty) 'lyDo': lyDo,
        }),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[RestaurantOwnerService] updateOrderStatus error: $e');
      return false;
    }
  }

  // ── Hồ sơ quán ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final res = await http.get(
        Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/profile'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['data'] is Map) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
    } catch (e) {
      debugPrint('[RestaurantOwnerService] getProfile error: $e');
    }
    return null;
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/profile'),
        headers: _headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[RestaurantOwnerService] updateProfile error: $e');
      return false;
    }
  }

  // ── Voucher ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getVouchers({String? status, String? search}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty && status != 'ALL') queryParams['status'] = status;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/vouchers').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    try {
      final res = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['data'] is Map) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
    } catch (e) {
      debugPrint('[RestaurantOwnerService] getVouchers error: $e');
    }
    return {'vouchers': [], 'summary': {}};
  }

  Future<bool> createVoucher(Map<String, dynamic> input) async {
    try {
      final res = await http.post(
        Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/vouchers'),
        headers: _headers,
        body: json.encode(input),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('[RestaurantOwnerService] createVoucher error: $e');
      return false;
    }
  }

  Future<bool> updateVoucher(int voucherId, Map<String, dynamic> input) async {
    try {
      final res = await http.put(
        Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/vouchers/$voucherId'),
        headers: _headers,
        body: json.encode(input),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[RestaurantOwnerService] updateVoucher error: $e');
      return false;
    }
  }

  Future<bool> toggleVoucher(int voucherId, {String? targetStatus}) async {
    try {
      final res = await http.patch(
        Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/vouchers/$voucherId/toggle'),
        headers: _headers,
        body: targetStatus != null ? json.encode({'trangThai': targetStatus}) : null,
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[RestaurantOwnerService] toggleVoucher error: $e');
      return false;
    }
  }

  Future<bool> deleteVoucher(int voucherId) async {
    try {
      final res = await http.delete(
        Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/vouchers/$voucherId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('[RestaurantOwnerService] deleteVoucher error: $e');
      return false;
    }
  }

  // ── Dashboard & Menu ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await http.get(
        Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/dashboard'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['data'] is Map) {
          return Map<String, dynamic>.from(body['data']);
        }
      }
    } catch (e) {
      debugPrint('[RestaurantOwnerService] getDashboardStats error: $e');
    }
    return {};
  }
}
