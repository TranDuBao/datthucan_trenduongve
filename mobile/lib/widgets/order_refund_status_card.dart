import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/format_utils.dart';
import '../common/vietqr_banks.dart';
import '../services/order_service.dart';

/// Card hiển thị chi tiết tiến trình hoàn tiền và tài khoản nhận tiền của đơn hàng đã hủy
class OrderRefundStatusCard extends StatelessWidget {
  final OrderServiceModel order;
  final bool isDark;
  final VoidCallback onEditBank;

  const OrderRefundStatusCard({
    super.key,
    required this.order,
    required this.isDark,
    required this.onEditBank,
  });

  @override
  Widget build(BuildContext context) {
    final isCash = order.paymentMethod.toUpperCase() == 'TIEN_MAT';
    final isRefunded = order.refundStatus == 'HOAN_TIEN_THANH_CONG';
    final isProcessing = order.refundStatus == 'DANG_XU_LY';
    final hasBank = (order.refundAccountNumber != null && order.refundAccountNumber!.trim().isNotEmpty);

    final cardBg = isDark ? const Color(0xFF1E2430) : Colors.white;
    final borderColor = isRefunded
        ? const Color(0xFF6CE9A6)
        : (isCash ? (isDark ? const Color(0xFF333C4D) : const Color(0xFFE2E8F0)) : const Color(0xFFFDA29B));
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRefunded
                      ? (isDark ? const Color(0xFF0F291E) : const Color(0xFFECFDF3))
                      : (isDark ? const Color(0xFF2E1715) : const Color(0xFFFEF3F2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isRefunded ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                  color: isRefunded ? const Color(0xFF027A48) : const Color(0xFFD92D20),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đơn hàng đã hủy',
                      style: GoogleFonts.outfit(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCash
                          ? 'Đơn hàng thanh toán tiền mặt (Không phát sinh hoàn tiền)'
                          : (isRefunded
                              ? 'Quán đã chuyển khoản hoàn tiền thành công'
                              : 'Quán sẽ quét mã VietQR để hoàn tiền trực tiếp'),
                      style: GoogleFonts.outfit(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isCash) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7)),
            const SizedBox(height: 12),

            // Trạng thái hoàn tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trạng thái hoàn tiền:',
                  style: GoogleFonts.outfit(color: textSecondary, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRefunded
                        ? const Color(0xFFECFDF3)
                        : (isProcessing ? const Color(0xFFEFF8FF) : const Color(0xFFFFF6ED)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isRefunded
                          ? const Color(0xFF6CE9A6)
                          : (isProcessing ? const Color(0xFF84CAFF) : const Color(0xFFFDB022)),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isRefunded
                        ? '✓ Hoàn tiền thành công'
                        : (isProcessing ? '⏳ Đang chuyển khoản' : (hasBank ? '⏳ Chờ quán chuyển tiền' : '⚠️ Chờ nhập STK')),
                    style: GoogleFonts.outfit(
                      color: isRefunded
                          ? const Color(0xFF027A48)
                          : (isProcessing ? const Color(0xFF175CD3) : const Color(0xFFB54708)),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Số tiền hoàn
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Số tiền hoàn lại:',
                  style: GoogleFonts.outfit(color: textSecondary, fontSize: 13),
                ),
                Text(
                  FormatUtils.formatCurrency(order.refundAmount ?? order.totalAmount),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFC6011),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Thông tin tài khoản ngân hàng hoặc nút bổ sung
            if (hasBank) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262E3D) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF333C4D) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFFFC6011)),
                            const SizedBox(width: 6),
                            Text(
                              'Tài khoản nhận tiền:',
                              style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700, color: textPrimary),
                            ),
                          ],
                        ),
                        if (!isRefunded)
                          InkWell(
                            onTap: onEditBank,
                            child: Text(
                              'Đổi STK',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFFC6011)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${VietQrBanks.findByCodeOrBin(order.refundBank).shortName} • ${order.refundAccountNumber}',
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    if (order.refundAccountName != null && order.refundAccountName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        order.refundAccountName!.toUpperCase(),
                        style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chưa có số tài khoản nhận tiền hoàn',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quán cần số tài khoản của bạn để quét mã VietQR và chuyển trả tiền.',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: onEditBank,
                        icon: const Icon(Icons.add_card_rounded, size: 16),
                        label: Text(
                          'Cung Cấp Tài Khoản Nhận Tiền',
                          style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC6011),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

