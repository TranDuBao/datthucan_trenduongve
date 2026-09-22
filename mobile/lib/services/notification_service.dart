import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type; // 'ORDER', 'PROMO', 'SYSTEM'
  final String? statusTag; // 'ĐANG GIAO', 'THÀNH CÔNG', 'BẾP CHUẨN BỊ', 'HOÀN TẤT'
  final String? orderCode;
  final String? distanceText;
  final String timeAgo;
  final String groupPeriod;
  bool isUnread;
  final int? orderId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.statusTag,
    this.orderCode,
    this.distanceText,
    required this.timeAgo,
    required this.groupPeriod,
    this.isUnread = false,
    this.orderId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['maThongBao'] ?? json['id'] ?? 0,
      title: json['tieuDe'] ?? json['title'] ?? 'Thông báo hệ thống',
      body: json['noiDung'] ?? json['body'] ?? json['detail'] ?? '',
      type: json['loaiThongBao'] ?? json['type'] ?? 'SYSTEM',
      statusTag: json['trangThaiTag'] ?? json['statusTag'] ?? json['trangThai'],
      orderCode: json['maCodeDon'] ?? json['orderCode'] ?? (json['maDonHang'] != null ? '#FD-${json['maDonHang']}' : null),
      distanceText: json['khoangCach'] ?? json['distanceText'],
      timeAgo: json['thoiGian'] ?? json['timeAgo'] ?? json['time'] ?? '',
      groupPeriod: json['nhomThoiGian'] ?? json['groupPeriod'] ?? 'HÔM NAY',
      isUnread: json['chuaDoc'] ?? json['isUnread'] ?? false,
      orderId: json['maDonHang'] ?? json['orderId'],
    );
  }
}

class NotificationService {
  static Future<List<NotificationModel>> fetchNotificationsFromDB() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);
        return list.map((item) => NotificationModel.fromJson(item)).toList();
      }
    } catch (e) {
      // Return empty list if network/DB has no notifications
    }

    // STRICT RULE: No hardcoded fake data! Extract strictly from database response.
    return [];
  }

  static Future<void> markAllAsRead(List<NotificationModel> list) async {
    for (var n in list) {
      n.isUnread = false;
    }
  }
}
