import 'dart:async';
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
  final String restaurantName;
  final String restaurantAddress;
  final String size;
  final List<String> toppings;
  final String dishNote;
  final String note;

  CartItemModel({
    required this.foodId,
    required this.foodName,
    required this.price,
    this.quantity = 1,
    required this.image,
    required this.restaurantId,
    this.restaurantName = '',
    this.restaurantAddress = '',
    this.size = '',
    this.toppings = const [],
    this.dishNote = '',
    this.note = '',
  });

  Map<String, dynamic> toJson() {
    String finalName = foodName;
    if (size.isNotEmpty && !finalName.contains('($size)')) {
      finalName = '$foodName ($size)';
    }

    final structuredData = {
      if (size.isNotEmpty) 'size': size,
      if (toppings.isNotEmpty) 'toppings': toppings,
      if (dishNote.isNotEmpty) 'ghiChu': dishNote,
      if (note.isNotEmpty) 'rawNote': note,
    };

    return {
      'maMonAn': foodId,
      'tenMonAn': finalName,
      'gia': price,
      'soLuong': quantity,
      'size': size,
      'toppings': toppings,
      'dishNote': dishNote,
      'ghiChu': json.encode(structuredData),
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
  final String restaurantPhone;
  final double? lat;
  final double? lng;
  final String createdAt;
  final String? cancelReason;
  String? refundStatus;
  double? refundAmount;
  int? refundId;
  String? refundBank;
  String? refundAccountNumber;
  String? refundAccountName;
  final List<dynamic> items;
  final String paymentMethod;
  final String? note;

  OrderServiceModel({
    required this.orderId,
    this.restaurantId,
    required this.status,
    required this.totalAmount,
    required this.pickupTime,
    this.restaurantName = 'Nhà hàng lộ trình',
    this.restaurantAddress = 'Địa chỉ tự đến lấy',
    this.restaurantPhone = '',
    this.lat,
    this.lng,
    this.createdAt = '',
    this.cancelReason,
    this.refundStatus,
    this.refundAmount,
    this.refundId,
    this.refundBank,
    this.refundAccountNumber,
    this.refundAccountName,
    this.items = const [],
    this.paymentMethod = 'PAYOS',
    this.note,
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
      restaurantPhone: (json['sdt'] ?? json['cuaHang']?['sdt'] ?? '').toString(),
      lat: (json['lat'] ?? json['cuaHang']?['lat'] as num?)?.toDouble(),
      lng: (json['lng'] ?? json['cuaHang']?['lng'] as num?)?.toDouble(),
      createdAt: json['thoiGianDat'] ?? json['createdAt'] ?? '',
      cancelReason: json['lyDoHuy'] ?? json['cancelReason'],
      refundStatus: json['refundStatus'] ?? json['refund']?['trangThaiHoanTien'],
      refundAmount: (json['refundAmount'] ?? json['refund']?['soTienHoan'] as num?)?.toDouble(),
      refundId: json['refundId'] ?? json['refund']?['maHoanTien'] ?? json['refund']?['id'],
      refundBank: json['refundBank'] ?? json['refund']?['nganHangNhan'] ?? json['refund']?['nganHang'],
      refundAccountNumber: json['refundAccountNumber'] ?? json['refund']?['soTaiKhoanNhan'] ?? json['refund']?['soTaiKhoan'],
      refundAccountName: json['refundAccountName'] ?? json['refund']?['tenChuTaiKhoanNhan'] ?? json['refund']?['tenTaiKhoan'],
      items: json['items'] ?? json['chiTietDonHang'] ?? [],
      paymentMethod: (json['phuongThucThanhToan'] ?? json['paymentMethod'] ?? json['payment']?['phuongThucThanhToan'] ?? 'PAYOS').toString(),
      note: json['ghiChu'] ?? json['note'],
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
    String? note,
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
        if (note != null && note.trim().isNotEmpty) 'ghiChu': note.trim(),
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

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
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Kết nối quá thời gian chờ (Timeout). Vui lòng thử lại!',
      };
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

  static Future<Map<String, dynamic>> cancelOrder(
    int orderId, {
    String? reason,
    Map<String, dynamic>? bankInfo,
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.svOrders}/$orderId/status');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': 'DA_HUY',
          if (reason != null && reason.isNotEmpty) 'lyDo': reason,
          if (bankInfo != null) 'bankInfo': bankInfo,
        }),
      ).timeout(const Duration(seconds: 8));

      final resJson = json.decode(response.body);
      final isOk = (response.statusCode == 200 || response.statusCode == 201);
      return {
        'success': isOk,
        'message': resJson['message'] ?? (isOk ? 'Hủy đơn hàng thành công' : 'Không thể hủy đơn hàng'),
        'data': resJson['data'],
      };
    } catch (e) {
      debugPrint('[OrderService] cancelOrder exception: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối máy chủ: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateRefundBankInfo({
    required int refundId,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/refunds/$refundId/bank-info');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nganHang': bankName,
          'soTaiKhoan': accountNumber,
          'tenChuTaiKhoan': accountName,
        }),
      ).timeout(const Duration(seconds: 8));

      final resJson = json.decode(response.body);
      final isOk = (response.statusCode == 200 || response.statusCode == 201);
      return {
        'success': isOk,
        'message': resJson['message'] ?? (isOk ? 'Cập nhật tài khoản thành công' : 'Không thể cập nhật'),
        'data': resJson['data'],
      };
    } catch (e) {
      debugPrint('[OrderService] updateRefundBankInfo error: $e');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getOrderRefund(int orderId) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/orders/$orderId/refund');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final resJson = json.decode(response.body);
        return resJson['data'];
      }
      return null;
    } catch (e) {
      debugPrint('[OrderService] getOrderRefund error: $e');
      return null;
    }
  }
}
