import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

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
  final String status;
  final double totalAmount;
  final String pickupTime;
  final String restaurantName;
  final String restaurantAddress;
  final List<dynamic> items;

  OrderServiceModel({
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.pickupTime,
    this.restaurantName = 'Nhà hàng lộ trình',
    this.restaurantAddress = 'Địa chỉ tự đến lấy',
    this.items = const [],
  });

  factory OrderServiceModel.fromJson(Map<String, dynamic> json) {
    return OrderServiceModel(
      orderId: json['maDonHang'] ?? json['orderId'] ?? 0,
      status: json['trangThai'] ?? json['status'] ?? 'chờ xử lý',
      totalAmount: double.tryParse((json['tongTien'] ?? json['totalAmount'] ?? 0).toString()) ?? 0.0,
      pickupTime: json['thoiGianHenNhan'] ?? json['pickupTime'] ?? '',
      restaurantName: json['tenQuan'] ?? 'Nhà hàng lộ trình',
      restaurantAddress: json['diaChi'] ?? 'Địa chỉ tự đến lấy',
      items: json['items'] ?? [],
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
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse(SVKey.svOrders);
      final body = json.encode({
        'maQuan': restaurantId,
        'thoiGianHenNhan': pickupTime.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'tongTien': totalAmount,
        'phuongThucThanhToan': paymentMethod,
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
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final resJson = json.decode(response.body);
        final List<dynamic> list = resJson['data'] ?? [];
        return list.map((item) => OrderServiceModel.fromJson(item)).toList();
      }
    } catch (_) {}

    return [];
  }
}
