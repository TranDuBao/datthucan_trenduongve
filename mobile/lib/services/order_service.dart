import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/globs.dart';
import '../common/service_call.dart';

class CartItemModel {
  final int foodId;
  final String foodName;
  final double price;
  int quantity;
  final String image;
  final int restaurantId;

  CartItemModel({
    required this.foodId,
    required this.foodName,
    required this.price,
    this.quantity = 1,
    required this.image,
    required this.restaurantId,
  });

  Map<String, dynamic> toJson() {
    return {
      'maMonAn': foodId,
      'tenMonAn': foodName,
      'gia': price,
      'soLuong': quantity,
    };
  }
}

class OrderServiceModel {
  final int orderId;
  final int? restaurantId;
  String status;
  final double totalAmount;
  final String pickupTime;
  final String restaurantName;
  final String restaurantAddress;
  final String createdAt;
  final String? cancelReason;
  final List<dynamic> items;

  OrderServiceModel({
    required this.orderId,
    this.restaurantId,
    required this.status,
    required this.totalAmount,
    required this.pickupTime,
    this.restaurantName = 'Nhà hàng lộ trình',
    this.restaurantAddress = 'Địa chỉ tự đến lấy',
    this.createdAt = '',
    this.cancelReason,
    this.items = const [],
  });

  factory OrderServiceModel.fromJson(Map<String, dynamic> json) {
    return OrderServiceModel(
      orderId: json['maDonHang'] ?? json['orderId'] ?? json['id'] ?? 0,
      restaurantId: json['maQuan'] ?? json['restaurantId'] ?? json['cuaHang']?['maQuan'],
      status: json['trangThai'] ?? json['status'] ?? 'chờ xử lý',
      totalAmount: double.tryParse((json['tongTien'] ?? json['totalAmount'] ?? 0).toString()) ?? 0.0,
      pickupTime: json['thoiGianHenNhan'] ?? json['pickupTime'] ?? '',
      restaurantName: json['tenQuan'] ?? json['cuaHang']?['tenQuan'] ?? 'Nhà hàng lộ trình',
      restaurantAddress: json['diaChi'] ?? json['cuaHang']?['diaChi'] ?? 'Địa chỉ tự đến lấy',
      createdAt: json['thoiGianDat'] ?? json['createdAt'] ?? '',
      cancelReason: json['lyDoHuy'] ?? json['cancelReason'],
      items: json['items'] ?? json['chiTietDonHang'] ?? [],
    );
  }
}

class OrderService {
  static Future<Map<String, dynamic>> createPreOrder({
    required int restaurantId,
    required DateTime pickupTime,
    required List<CartItemModel> items,
    required double totalAmount,
    required String paymentMethod,
    String? voucherCode,
    int? voucherId,
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse(SVKey.svOrders);
      final body = json.encode({
        'maQuan': restaurantId,
        'thoiGianHenNhan': pickupTime.toUtc().toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'tongTien': totalAmount,
        'phuongThucThanhToan': paymentMethod,
        if (voucherCode != null && voucherCode.isNotEmpty) 'maCodeVoucher': voucherCode,
        if (voucherId != null) 'maVoucher': voucherId,
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final resJson = json.decode(response.body);
        return {
          'success': true,
          'data': resJson['data'],
        };
      } else {
        final resJson = json.decode(response.body);
        if (response.statusCode == 401) {
          // Auto-logout user and redirect to login screen when token expires
          ServiceCall.logout();
        }
        return {
          'success': false,
          'message': resJson['message'] ?? 'Không thể tạo đơn hàng pre-order',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối máy chủ: $e',
      };
    }
  }

  static Future<List<OrderServiceModel>> fetchMyOrders() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.svOrders}/my-orders');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      // Log status để debug khi có lỗi
      debugPrint('[OrderService] fetchMyOrders → HTTP ${response.statusCode}');

      if (response.statusCode == 200) {
        final resJson = json.decode(response.body);
        final List<dynamic> list = resJson['data'] ?? [];
        debugPrint('[OrderService] fetchMyOrders → ${list.length} đơn hàng');
        return list.map((item) => OrderServiceModel.fromJson(item)).toList();
      } else {
        // Log nội dung lỗi từ server
        debugPrint('[OrderService] fetchMyOrders lỗi: ${response.body}');
      }
    } catch (e) {
      // Log lỗi mạng / parse / timeout
      debugPrint('[OrderService] fetchMyOrders exception: $e');
    }

    return [];
  }

  static Future<bool> cancelOrder(int orderId) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.svOrders}/$orderId/status');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': 'DA_HUY'}),
      ).timeout(const Duration(seconds: 5));

      return (response.statusCode == 200 || response.statusCode == 201);
    } catch (e) {
      debugPrint('[OrderService] cancelOrder exception: $e');
    }
    return false;
  }
}
