import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Tiện ích định dạng tiền tệ, ngày giờ, số lượng và ánh xạ nhãn nghiệp vụ tập trung
class FormatUtils {
  /// Định dạng tiền tệ theo ngôn ngữ (VNĐ / VND)
  static String formatCurrency(dynamic amount, {Locale? locale}) {
    final val = double.tryParse((amount ?? 0).toString()) ?? 0.0;
    final isEn = locale?.languageCode == 'en';

    if (isEn) {
      final f = NumberFormat('#,###', 'en_US');
      return '${f.format(val.toInt())} VND';
    } else {
      final f = NumberFormat('#,###', 'vi_VN');
      return '${f.format(val.toInt())}₫';
    }
  }

  /// Định dạng ngày giờ chuẩn theo ngôn ngữ
  static String formatDateTime(dynamic dateStr, {Locale? locale}) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return dateStr.toString();

    final local = date.toLocal();
    final isEn = locale?.languageCode == 'en';

    if (isEn) {
      return DateFormat('hh:mm a - MMM d, yyyy', 'en_US').format(local);
    } else {
      return DateFormat('HH:mm - dd/MM/yyyy', 'vi_VN').format(local);
    }
  }

  /// Định dạng thời gian tương đối ("Vừa xong" vs "Just now", "x phút trước" vs "x mins ago")
  static String formatRelativeTime(dynamic dateStr, BuildContext context) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr.toString());
    if (date == null) return dateStr.toString();

    final diff = DateTime.now().difference(date.toLocal());
    final l10n = context.l10n;

    if (diff.inSeconds < 60) return l10n.formatJustNow;
    if (diff.inMinutes < 60) return l10n.formatMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.formatHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.formatDaysAgo(diff.inDays);

    final local = date.toLocal();
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    return isEn
        ? DateFormat('MMM d').format(local)
        : DateFormat('dd/MM').format(local);
  }

  /// Ánh xạ trạng thái đơn hàng sang nhãn theo ngôn ngữ hiện tại
  static String getOrderStatusLabel(String status, BuildContext context) {
    final s = status.trim().toUpperCase();
    final l10n = context.l10n;

    switch (s) {
      case 'CHO_THANH_TOAN':
      case 'UNPAID':
        return l10n.orderStatusUnpaid;
      case 'CHO_XAC_NHAN':
      case 'PENDING':
        return l10n.orderStatusAwaitingConfirmation;
      case 'DA_XAC_NHAN':
      case 'CONFIRMED':
        return l10n.orderStatusConfirmed;
      case 'DANG_CHUAN_BI':
      case 'PREPARING':
        return l10n.orderStatusPreparing;
      case 'SAN_SANG':
      case 'READY':
      case 'READY_FOR_PICKUP':
        return l10n.orderStatusReadyForPickup;
      case 'HOAN_TAT':
      case 'HOAN_THANH':
      case 'COMPLETED':
      case 'PICKED_UP':
        return l10n.orderStatusCompleted;
      case 'DA_HUY':
      case 'CANCELLED':
      case 'TU_CHOI':
        return l10n.orderStatusCancelled;
      default:
        return status;
    }
  }

  /// Ánh xạ chế độ đơn hàng
  static String getOrderModeLabel(String mode, BuildContext context) {
    final m = mode.trim().toUpperCase();
    final l10n = context.l10n;

    switch (m) {
      case 'GHE_MUA':
      case 'QUICK_STOP':
        return l10n.orderModeQuickStop;
      case 'DAT_TRUOC':
      case 'PRE_ORDER':
        return l10n.orderModePreOrder;
      case 'AN_TAI_QUAN':
      case 'DINE_IN':
        return l10n.orderModeDineIn;
      default:
        return mode;
    }
  }

  /// Ánh xạ phương thức thanh toán
  static String getPaymentMethodLabel(String method, BuildContext context) {
    final p = method.trim().toUpperCase();
    final l10n = context.l10n;

    switch (p) {
      case 'TIEN_MAT':
      case 'CASH':
        return l10n.paymentMethodCash;
      case 'VIETQR':
        return l10n.paymentMethodVietQR;
      case 'VNPAY':
        return l10n.paymentMethodVNPay;
      case 'MOMO':
        return l10n.paymentMethodMoMo;
      default:
        return method;
    }
  }
}
