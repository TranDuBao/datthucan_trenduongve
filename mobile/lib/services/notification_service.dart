import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type; // 'order:created', 'order:confirmed', 'reservation:confirmed', etc.
  final String? statusTag;
  final String? orderCode;
  final String? distanceText;
  final String timeAgo;
  final String groupPeriod;
  bool isUnread;
  final int? orderId;
  final int? reservationId;
  final Map<String, dynamic>? rawData;
  final DateTime? createdAt;

  bool get isRead => !isUnread;
  set isRead(bool val) => isUnread = !val;

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
    this.reservationId,
    this.rawData,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final extraData = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null;
    final int ordId = extraData?['orderId'] ?? json['orderId'] ?? json['maDonHang'] ?? 0;
    final int resId = extraData?['reservationId'] ?? json['reservationId'] ?? json['maDatBan'] ?? 0;

    DateTime? created;
    if (json['createdAt'] != null || json['created_at'] != null) {
      created = DateTime.tryParse(json['createdAt'] ?? json['created_at']);
    }

    // Relative time string
    String timeStr = '';
    String groupStr = 'HÔM NAY';
    if (created != null) {
      final now = DateTime.now();
      final diff = now.difference(created);
      if (diff.inSeconds < 60) {
        timeStr = 'Vừa xong';
      } else if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes} phút trước';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours} giờ trước';
      } else {
        timeStr = '${diff.inDays} ngày trước';
      }

      if (diff.inDays == 0) {
        groupStr = 'HÔM NAY';
      } else if (diff.inDays <= 7) {
        groupStr = 'TUẦN NÀY';
      } else {
        groupStr = 'CŨ HƠN';
      }
    } else {
      timeStr = json['timeAgo'] ?? json['thoiGian'] ?? '';
    }

    bool isReadVal = false;
    final rawIsRead = json['isRead'] ?? json['is_read'] ?? json['is_da_xem'];
    if (rawIsRead is bool) {
      isReadVal = rawIsRead;
    } else if (rawIsRead is num) {
      isReadVal = rawIsRead == 1;
    } else if (rawIsRead is String) {
      isReadVal = rawIsRead.toLowerCase() == 'true' || rawIsRead == '1';
    }

    return NotificationModel(
      id: json['id'] ?? json['maThongBao'] ?? 0,
      title: json['title'] ?? json['tieuDe'] ?? 'Thông báo',
      body: json['body'] ?? json['noiDung'] ?? json['detail'] ?? '',
      type: json['type'] ?? json['loaiThongBao'] ?? 'SYSTEM',
      statusTag: json['statusTag'] ?? extraData?['status'],
      orderCode: ordId > 0 ? '#DH-$ordId' : (resId > 0 ? '#DB-$resId' : null),
      distanceText: json['distanceText'] ?? json['khoangCach'] ?? extraData?['distanceText'],
      timeAgo: timeStr,
      groupPeriod: groupStr,
      isUnread: !isReadVal,
      orderId: ordId > 0 ? ordId : null,
      reservationId: resId > 0 ? resId : null,
      rawData: extraData,
      createdAt: created,
    );
  }
}

class NotificationService {
  static Future<List<NotificationModel>> fetchNotificationsFromDB({int page = 1, int limit = 20}) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications?page=$page&limit=$limit');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> list = [];
        if (decoded is Map<String, dynamic> && decoded['data'] != null) {
          if (decoded['data']['notifications'] is List) {
            list = decoded['data']['notifications'];
          } else if (decoded['data'] is List) {
            list = decoded['data'];
          }
        } else if (decoded is List) {
          list = decoded;
        }
        return list.map((item) => NotificationModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching notifications: $e');
    }
    return [];
  }

  static Future<int> fetchUnreadCount() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications/unread-count');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['data'] != null && decoded['data']['unreadCount'] != null) {
          return (decoded['data']['unreadCount'] as num).toInt();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error fetching unread count: $e');
    }
    return 0;
  }

  static Future<bool> markAsRead(int notificationId) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications/$notificationId/read');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> markAllAsReadApi() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications/read-all');
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markAllAsRead(List<NotificationModel> list) async {
    for (var n in list) {
      n.isUnread = false;
    }
    await markAllAsReadApi();
  }
}
