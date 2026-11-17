import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/format_utils.dart';
import '../services/order_service.dart';
import 'order_refund_bank_sheet.dart';

/// Modal dialog xác nhận hủy đơn hàng thiết kế hiện đại theo tone của hệ thống
class OrderCancelConfirmDialog extends StatefulWidget {
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
  State<OrderCancelConfirmDialog> createState() => _OrderCancelConfirmDialogState();
}

class _OrderCancelConfirmDialogState extends State<OrderCancelConfirmDialog> {
  String? _savedBank;
  String? _savedAccountNumber;
  String? _savedAccountName;
  bool _isLoadingBank = true;

  @override
  void initState() {
    super.initState();
    _loadSavedBank();
  }

  Future<void> _loadSavedBank() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _savedBank = widget.order.refundBank ?? prefs.getString('saved_refund_bank');
          _savedAccountNumber = widget.order.refundAccountNumber ?? prefs.getString('saved_refund_account_num');
          _savedAccountName = widget.order.refundAccountName ?? prefs.getString('saved_refund_account_name');
          _isLoadingBank = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBank = false);
    }
  }

  Future<void> _openBankSheet() async {
    final result = await OrderRefundBankSheet.show(
      context,
      orderId: widget.order.orderId,
      refundId: widget.order.refundId,
      initialBank: _savedBank,
      initialAccountNumber: _savedAccountNumber,
      initialAccountName: _savedAccountName,
      refundAmount: widget.order.refundAmount ?? widget.order.totalAmount,
    );

    if (result != null && mounted) {
      setState(() {
        _savedBank = result['bankName'];
        _savedAccountNumber = result['accountNumber'];
        _savedAccountName = result['accountName'];
      });
    }
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

    final isOnlinePayment = widget.order.paymentMethod.toUpperCase() != 'TIEN_MAT';
    final hasBankInfo = _savedAccountNumber != null && _savedAccountNumber!.trim().isNotEmpty;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 390),
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
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Hủy Đơn với Badge Pastel Đỏ
                    Container(
                      width: 62,
                      height: 62,
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
                          size: 30,
                          color: Color(0xFFD92D20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tiêu đề
                    Text(
                      context.l10n.orderConfirmCancelTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Nội dung hỏi xác nhận
                    Text(
                      context.l10n.orderConfirmCancelPrompt(
                        widget.order.orderId.toString(),
                        widget.order.restaurantName,
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#DH${widget.order.orderId}',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFFFC6011),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                FormatUtils.formatCurrency(widget.order.totalAmount),
                                style: GoogleFonts.outfit(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (widget.order.restaurantName.isNotEmpty) ...[
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
                                    widget.order.restaurantName,
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

                    // Khung hoàn tiền trực tuyến (VietQR)
                    if (isOnlinePayment) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasBankInfo
                              ? (isDark ? const Color(0xFF132D21) : const Color(0xFFECFDF3))
                              : (isDark ? const Color(0xFF382A13) : const Color(0xFFFFFBEB)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasBankInfo
                                ? (isDark ? const Color(0xFF1E523A) : const Color(0xFFA6F4C5))
                                : (isDark ? const Color(0xFF5E4924) : const Color(0xFFFDE68A)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  hasBankInfo ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                                  size: 16,
                                  color: hasBankInfo ? const Color(0xFF027A48) : const Color(0xFFB45309),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Hoàn tiền qua VietQR:',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: hasBankInfo ? const Color(0xFF027A48) : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                                if (hasBankInfo)
                                  InkWell(
                                    onTap: _openBankSheet,
                                    child: Text(
                                      'Đổi STK',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFFC6011),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (_isLoadingBank)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            else if (hasBankInfo)
                              Text(
                                '${_savedBank ?? 'Ngân hàng'} • $_savedAccountNumber (${_savedAccountName ?? ''})',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              )
                            else ...[
                              Text(
                                'Quán sẽ quét mã VietQR để chuyển trả tiền cho bạn.',
                                style: GoogleFonts.outfit(fontSize: 11.5, color: textSecondary),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 32,
                                child: TextButton.icon(
                                  onPressed: _openBankSheet,
                                  icon: const Icon(Icons.add_card_rounded, size: 14),
                                  label: Text(
                                    'Nhập STK nhận tiền hoàn',
                                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFFC6011),
                                    padding: EdgeInsets.zero,
                                    alignment: Alignment.centerLeft,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

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
                    const SizedBox(height: 18),

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
      ),
    );
  }
}
