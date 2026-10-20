import 'dart:convert';
import 'package:flutter/material.dart';

class RestaurantFormatUtils {
  static String formatVND(dynamic amount) {
    final val = double.tryParse((amount ?? 0).toString()) ?? 0.0;
    final formatted = val.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '$formatted₫';
  }

  static String formatDateTime(dynamic dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return dateStr.toString();
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute - $day/$month/$year';
  }

  static String formatRelativeTime(dynamic dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return dateStr.toString();
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    final day = date.toLocal().day.toString().padLeft(2, '0');
    final month = date.toLocal().month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static Map<String, dynamic> getStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'CHO_XAC_NHAN':
        return {
          'text': 'Chờ xác nhận',
          'bg': const Color(0xFFFEF3C7),
          'fg': const Color(0xFFD97706),
          'border': const Color(0xFFFDE68A),
        };
      case 'DA_XAC_NHAN':
      case 'DANG_CHUAN_BI':
        return {
          'text': 'Đang chuẩn bị',
          'bg': const Color(0xFFE0F2FE),
          'fg': const Color(0xFF0284C7),
          'border': const Color(0xFFBAE6FD),
        };
      case 'SAN_SANG':
        return {
          'text': 'Sẵn sàng lấy',
          'bg': const Color(0xFFCCFBF1),
          'fg': const Color(0xFF0D9488),
          'border': const Color(0xFF99F6E4),
        };
      case 'HOAN_TAT':
      case 'DA_LAY':
        return {
          'text': 'Đã hoàn tất',
          'bg': const Color(0xFFD1FAE5),
          'fg': const Color(0xFF059669),
          'border': const Color(0xFFA7F3D0),
        };
      case 'DA_HUY':
      case 'TU_CHOI':
        return {
          'text': 'Đã hủy',
          'bg': const Color(0xFFFEE2E2),
          'fg': const Color(0xFFDC2626),
          'border': const Color(0xFFFECACA),
        };
      default:
        return {
          'text': status,
          'bg': const Color(0xFFF1F5F9),
          'fg': const Color(0xFF475569),
          'border': const Color(0xFFE2E8F0),
        };
    }
  }

  static String formatOperatingHours(dynamic raw) {
    if (raw == null) return '07:00 – 22:00';
    final str = raw.toString().trim();
    if (!str.startsWith('{')) {
      return str.isEmpty ? '07:00 – 22:00' : str;
    }
    try {
      final decoded = (raw is Map) ? raw : jsonDecode(str);
      if (decoded is Map) {
        final now = DateTime.now();
        const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
        final todayKey = days[now.weekday - 1];
        final todaySched = decoded[todayKey] ?? decoded['mon'];
        if (todaySched is Map) {
          final isOpen = todaySched['open'] == true;
          if (!isOpen) return 'Hôm nay: Đóng cửa';
          final from = todaySched['from'] ?? '07:00';
          final to = todaySched['to'] ?? '22:00';
          return '$from – $to';
        }
      }
    } catch (_) {}
    return '07:00 – 22:00';
  }

  static List<Map<String, String>> parseWeeklyOperatingHours(dynamic raw) {
    const dayNames = {
      'mon': 'Thứ Hai',
      'tue': 'Thứ Ba',
      'wed': 'Thứ Tư',
      'thu': 'Thứ Năm',
      'fri': 'Thứ Sáu',
      'sat': 'Thứ Bảy',
      'sun': 'Chủ Nhật',
    };
    if (raw == null) return [];
    final str = raw.toString().trim();
    if (!str.startsWith('{')) {
      return [
        {'day': 'Mỗi ngày', 'time': str.isEmpty ? '07:00 – 22:00' : str, 'isOpen': 'true'}
      ];
    }
    try {
      final decoded = (raw is Map) ? raw : jsonDecode(str);
      if (decoded is Map) {
        final result = <Map<String, String>>[];
        for (final key in dayNames.keys) {
          final item = decoded[key];
          if (item is Map) {
            final isOpen = item['open'] == true;
            final from = item['from'] ?? '07:00';
            final to = item['to'] ?? '22:00';
            result.add({
              'day': dayNames[key]!,
              'time': isOpen ? '$from – $to' : 'Đóng cửa',
              'isOpen': isOpen ? 'true' : 'false',
            });
          }
        }
        return result;
      }
    } catch (_) {}
    return [];
  }
}
