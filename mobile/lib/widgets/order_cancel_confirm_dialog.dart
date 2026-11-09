import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/format_utils.dart';
import '../services/order_service.dart';

/// Modal dialog xác nhận hủy đơn hàng thiết kế hiện đại theo tone của hệ thống
class OrderCancelConfirmDialog extends StatelessWidget {
  final OrderServiceModel order;

  const OrderCancelConfirmDialog({
    super.key,
    required this.order,
  });

  /// Hiển thị dialog xác nhận hủy đơn
  static Future<bool?> show(BuildContext context, OrderServiceModel order) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'OrderCancelConfirm',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => OrderCancelConfirmDialog(order: order),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF1E2430) : Colors.white;
    final infoBg = isDark ? const Color(0xFF262E3D) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF333C4D) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final warningBg = isDark ? const Color(0xFF362B1A) : const Color(0xFFFFFBEB);
    final warningBorder = isDark ? const Color(0xFF5E4924) : const Color(0xFFFDE68A);
    final warningText = isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);

    final cancelBtnBg = isDark ? const Color(0xFF2E384D) : const Color(0xFFF1F5F9);
    final cancelBtnText = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475467);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Hủy Đơn với Badge Pastel Đỏ
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF3B2025) : const Color(0xFFFEE4E2),
                      border: Border.all(
                        color: isDark ? const Color(0xFF662932) : const Color(0xFFFECDCA),
                        width: 2.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.remove_shopping_cart_rounded,
                        size: 32,
                        color: Color(0xFFD92D20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiêu đề
                  Text(
                    context.l10n.orderConfirmCancelTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nội dung hỏi xác nhận song ngữ
                  Text(
                    context.l10n.orderConfirmCancelPrompt(
                      order.orderId.toString(),
                      order.restaurantName,
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Khung tóm tắt thông tin đơn hàng
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: infoBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Mã đơn hàng
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#DH${order.orderId}',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFC6011),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            // Tổng tiền
                            Text(
                              FormatUtils.formatCurrency(order.totalAmount),
                              style: GoogleFonts.outfit(
                                color: textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        if (order.restaurantName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                size: 16,
                                color: Color(0xFFFC6011),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  order.restaurantName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Banner cảnh báo thao tác không thể hoàn tác
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: warningBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: warningBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: warningText,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.orderConfirmCancelWarning,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: warningText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Hai nút hành động: Giữ lại đơn & Xác nhận hủy
                  Row(
                    children: [
                      // Nút Giữ lại đơn
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: cancelBtnBg,
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              context.l10n.orderKeepOrderBtn,
                              style: GoogleFonts.outfit(
                                color: cancelBtnText,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nút Xác nhận hủy đơn
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Text(
                                context.l10n.orderConfirmCancelAction,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
