import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String? titleEn;
  final String? bodyEn;
  final String type; // 'order_ready' | 'order_cancelled' | 'refund' | 'system' | 'update'
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
    this.titleEn,
    this.bodyEn,
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

  String getLocalizedTitle(String langCode) {
    if (langCode == 'en' && titleEn != null && titleEn!.trim().isNotEmpty) {
      return titleEn!;
    }
    return title;
  }

  String getLocalizedBody(String langCode) {
    if (langCode == 'en' && bodyEn != null && bodyEn!.trim().isNotEmpty) {
      return bodyEn!;
    }
    return body;
  }

  static int _safeInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) {
      final parsed = int.tryParse(val);
      if (parsed != null) return parsed;
      final digits = RegExp(r'\d+').firstMatch(val)?.group(0);
      if (digits != null) return int.tryParse(digits) ?? fallback;
    }
    return fallback;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Check if wrapped in user_notification inbox format
    final Map<String, dynamic> notifData = (json['notification'] is Map<String, dynamic>)
        ? json['notification'] as Map<String, dynamic>
        : json;

    final extraData = notifData['data'] is Map<String, dynamic>
        ? notifData['data'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null);

    final int ordId = _safeInt(extraData?['orderId']) != 0
        ? _safeInt(extraData?['orderId'])
        : (_safeInt(notifData['orderId']) != 0
            ? _safeInt(notifData['orderId'])
            : (_safeInt(json['orderId']) != 0
                ? _safeInt(json['orderId'])
                : _safeInt(json['maDonHang'])));

    final int resId = _safeInt(extraData?['reservationId']) != 0
        ? _safeInt(extraData?['reservationId'])
        : (_safeInt(notifData['reservationId']) != 0
            ? _safeInt(notifData['reservationId'])
            : (_safeInt(json['reservationId']) != 0
                ? _safeInt(json['reservationId'])
                : _safeInt(json['maDatBan'])));

    DateTime? created;
    final rawDate = json['createdAt'] ??
        json['created_at'] ??
        notifData['createdAt'] ??
        notifData['created_at'] ??
        notifData['sentAt'];

    if (rawDate != null) {
      created = DateTime.tryParse(rawDate.toString());
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
      timeStr = (json['timeAgo'] ?? json['thoiGian'] ?? '').toString();
    }

    bool isReadVal = false;
    final rawIsRead = json['isRead'] ?? json['is_read'] ?? json['is_da_xem'] ?? notifData['isRead'];
    if (rawIsRead is bool) {
      isReadVal = rawIsRead;
    } else if (rawIsRead is num) {
      isReadVal = rawIsRead == 1;
    } else if (rawIsRead is String) {
      isReadVal = rawIsRead.toLowerCase() == 'true' || rawIsRead == '1';
    }

    final int finalId = _safeInt(notifData['id']) != 0
        ? _safeInt(notifData['id'])
        : (_safeInt(json['id']) != 0
            ? _safeInt(json['id'])
            : (_safeInt(json['notificationId']) != 0
                ? _safeInt(json['notificationId'])
                : _safeInt(json['maThongBao'])));

    final String finalTitle = (notifData['title'] ?? json['title'] ?? json['tieuDe'] ?? 'Thông báo').toString();
    final String finalBody = (notifData['body'] ?? json['body'] ?? json['noiDung'] ?? json['detail'] ?? '').toString();
    final String? finalTitleEn = (notifData['titleEn'] ?? notifData['title_en'] ?? json['titleEn'] ?? json['title_en'])?.toString();
    final String? finalBodyEn = (notifData['bodyEn'] ?? notifData['body_en'] ?? json['bodyEn'] ?? json['body_en'])?.toString();
    final String finalType = (notifData['type'] ?? json['type'] ?? json['loaiThongBao'] ?? 'system').toString();

    return NotificationModel(
      id: finalId,
      title: finalTitle,
      body: finalBody,
      titleEn: finalTitleEn,
      bodyEn: finalBodyEn,
      type: finalType,
      statusTag: json['statusTag']?.toString() ?? extraData?['status']?.toString(),
      orderCode: ordId > 0 ? '#DH-$ordId' : (resId > 0 ? '#DB-$resId' : null),
      distanceText: json['distanceText']?.toString() ?? json['khoangCach']?.toString() ?? extraData?['distanceText']?.toString(),
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
  /**
   * Fetch paginated notification inbox from backend API
   */
  static Future<List<NotificationModel>> fetchNotificationsFromDB({int page = 1, int limit = 20}) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      // Try /inbox first, fallback to /notifications
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications/inbox?page=$page&limit=$limit');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> list = [];
        if (decoded is Map<String, dynamic> && decoded['data'] != null) {
          if (decoded['data']['items'] is List) {
            list = decoded['data']['items'];
          } else if (decoded['data']['notifications'] is List) {
            list = decoded['data']['notifications'];
          } else if (decoded['data'] is List) {
            list = decoded['data'];
          }
        } else if (decoded is List) {
          list = decoded;
        }

        final List<NotificationModel> result = [];
        for (final raw in list) {
          try {
            if (raw is Map<String, dynamic>) {
              result.add(NotificationModel.fromJson(raw));
            } else if (raw is Map) {
              result.add(NotificationModel.fromJson(Map<String, dynamic>.from(raw)));
            }
          } catch (itemErr) {
            debugPrint('[NotificationService] [Error] Parsing item: $itemErr');
          }
        }
        return result;
      }
    } catch (e) {
      debugPrint('[NotificationService] [Warn] Error fetching inbox notifications: $e');
    }
    return [];
  }

  /**
   * Fetch unread notification badge count
   */
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
      debugPrint('[NotificationService] [Warn] Error fetching unread count: $e');
    }
    return 0;
  }

  /**
   * Mark a specific notification as read
   */
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

  /**
   * Mark all notifications as read
   */
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

  /**
   * Register or update FCM device token with backend
   */
  static Future<bool> registerDeviceToken({
    required String token,
    required String platform,
    String? language,
    String? appVersion,
  }) async {
    try {
      final authToken = Globs.udValueString(KKey.authToken);
      if (authToken.isEmpty) return false;

      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications/device-token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'token': token,
          'platform': platform,
          'language': language ?? 'vi',
          'appVersion': appVersion ?? '1.0.0',
        }),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[NotificationService] registerDeviceToken error: $e');
      return false;
    }
  }

  /**
   * Delete FCM device token on user logout
   */
  static Future<bool> unregisterDeviceToken(String token) async {
    try {
      if (token.isEmpty) return true;
      final authToken = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications/device-token');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
        },
        body: json.encode({ 'token': token }),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[NotificationService] unregisterDeviceToken error: $e');
      return false;
    }
  }

  /**
   * Update notification settings & preferred language
   */
  static Future<bool> updateNotificationSettings({
    bool? systemNotif,
    bool? updateNotif,
    String? language,
  }) async {
    try {
      final authToken = Globs.udValueString(KKey.authToken);
      if (authToken.isEmpty) return false;

      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications/settings');
      final Map<String, dynamic> body = {};
      if (systemNotif != null) body['systemNotif'] = systemNotif;
      if (updateNotif != null) body['updateNotif'] = updateNotif;
      if (language != null) body['language'] = language;

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 4));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[NotificationService] updateNotificationSettings error: $e');
      return false;
    }
  }

  /**
   * Fetch app version configuration (latest & minimum required version)
   */
  static Future<Map<String, dynamic>?> fetchAppVersionConfig({String platform = 'android'}) async {
    try {
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/notifications/app-version?platform=$platform');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['data'] != null) {
          return decoded['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] fetchAppVersionConfig note: $e');
    }
    return null;
  }
}
