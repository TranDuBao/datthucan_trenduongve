import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Thông tin lộ trình ban đầu khi người dùng đặt hàng trên bản đồ
class OrderRouteInfo {
  final int orderId;
  final double destLat;
  final double destLng;
  final String destName;
  final String destAddress;
  final double? originLat;
  final double? originLng;
  final String? originName;

  OrderRouteInfo({
    required this.orderId,
    required this.destLat,
    required this.destLng,
    required this.destName,
    required this.destAddress,
    this.originLat,
    this.originLng,
    this.originName,
  });

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'destLat': destLat,
    'destLng': destLng,
    'destName': destName,
    'destAddress': destAddress,
    'originLat': originLat,
    'originLng': originLng,
    'originName': originName,
  };

  factory OrderRouteInfo.fromJson(Map<String, dynamic> json) => OrderRouteInfo(
    orderId: (json['orderId'] as num).toInt(),
    destLat: (json['destLat'] as num).toDouble(),
    destLng: (json['destLng'] as num).toDouble(),
    destName: json['destName']?.toString() ?? 'Điểm đến',
    destAddress: json['destAddress']?.toString() ?? '',
    originLat: (json['originLat'] as num?)?.toDouble(),
    originLng: (json['originLng'] as num?)?.toDouble(),
    originName: json['originName']?.toString(),
  );
}

/// Dịch vụ lưu trữ và khôi phục lộ trình của đơn hàng ghé quán
class OrderRouteStorage {
  static const _prefix = 'order_route_';

  static Future<void> saveOrderRoute(OrderRouteInfo info) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('$_prefix${info.orderId}', jsonEncode(info.toJson()));
    } catch (_) {}
  }

  static Future<OrderRouteInfo?> getOrderRoute(int orderId) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final str = sp.getString('$_prefix$orderId');
      if (str != null) {
        return OrderRouteInfo.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}

