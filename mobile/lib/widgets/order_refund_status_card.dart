import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/format_utils.dart';
import '../common/globs.dart';
import '../common/vietqr_banks.dart';
import '../common_widget/smart_network_image.dart';
import '../services/order_service.dart';

/// Card hiển thị chi tiết tiến trình hoàn tiền và tài khoản nhận tiền của đơn hàng đã hủy
class OrderRefundStatusCard extends StatefulWidget {
  final OrderServiceModel order;
  final bool isDark;
  final VoidCallback onEditBank;
  final VoidCallback? onStatusUpdated;

  const OrderRefundStatusCard({
    super.key,
    required this.order,
    required this.isDark,
    required this.onEditBank,
    this.onStatusUpdated,
  });

  @override
  State<OrderRefundStatusCard> createState() => _OrderRefundStatusCardState();
}

class _OrderRefundStatusCardState extends State<OrderRefundStatusCard> {
  bool _isSubmitting = false;

  void _showReceiptDialog(BuildContext context, String rawUrl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1E2430) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Biên lai chuyển tiền của quán',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF333C4D) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: widget.isDark ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Image Body
              Flexible(
                child: Container(
                  color: Colors.black,
                  constraints: const BoxConstraints(maxHeight: 480),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 3.5,
                    child: Center(
                      child: SmartNetworkImage(
                        imageUrl: rawUrl,
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: 440,
                        fit: BoxFit.contain,
                        placeholderIcon: Icons.receipt_long_rounded,
                      ),
                    ),
                  ),
                ),
              ),

              // Footer Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFF1E2430) : Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Text(
                  'Dùng 2 ngón tay để phóng to/thu nhỏ kiểm tra chi tiết biên lai.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleConfirmReceived() async {
    final refundId = widget.order.refundId;
    if (refundId == null || refundId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã yêu cầu hoàn tiền.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Xác nhận đã nhận tiền',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Text(
          'Bạn đã kiểm tra tài khoản ngân hàng và xác nhận đã nhận đủ số tiền ${FormatUtils.formatCurrency(widget.order.refundAmount ?? widget.order.totalAmount)} từ quán?',
          style: GoogleFonts.outfit(fontSize: 13.5, color: const Color(0xFF334155)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Chưa', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Đúng, đã nhận đủ', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final res = await OrderService.customerConfirmRefund(
      refundId: refundId,
      confirmed: true,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      widget.order.refundStatus = 'HOAN_TIEN_THANH_CONG';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16A34A),
          content: Text('Xác nhận nhận tiền hoàn thành công! Cảm ơn bạn.'),
        ),
      );
      widget.onStatusUpdated?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(res['message'] ?? 'Lỗi khi xác nhận hoàn tiền'),
        ),
      );
    }
  }

  Future<void> _handleDispute() async {
    final refundId = widget.order.refundId;
    if (refundId == null || refundId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy mã yêu cầu hoàn tiền.')),
      );
      return;
    }

    final reasonCtrl = TextEditingController();
    final shouldDispute = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Báo chưa nhận được tiền',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 17, color: const Color(0xFFDC2626)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nếu bạn đã kiểm tra tài khoản mà vẫn chưa thấy biến động số dư, vui lòng cho quán biết lý do để tiến hành tra soát ngân hàng:',
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Đã qua 30 phút nhưng tài khoản chưa có tiền về, nhờ quán kiểm tra lại mã FT...',
                hintStyle: GoogleFonts.outfit(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: GoogleFonts.outfit(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Đóng', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập lý do khiếu nại')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Gửi khiếu nại', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (shouldDispute != true) return;

    final reason = reasonCtrl.text.trim();
    setState(() => _isSubmitting = true);
    final res = await OrderService.customerConfirmRefund(
      refundId: refundId,
      confirmed: false,
      disputeReason: reason,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      widget.order.refundStatus = 'TRANH_CHAP';
      widget.order.refundDisputeReason = reason;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFD97706),
          content: Text('Đã gửi khiếu nại thành công. Quán sẽ tra soát lại với ngân hàng!'),
        ),
      );
      widget.onStatusUpdated?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(res['message'] ?? 'Lỗi khi gửi khiếu nại'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDark = widget.isDark;
    final isCash = order.paymentMethod.toUpperCase() == 'TIEN_MAT';
    final isRefunded = order.refundStatus == 'HOAN_TIEN_THANH_CONG';
    final isWaitingCustomer = order.refundStatus == 'CHO_KHACH_XAC_NHAN';
    final isDisputed = order.refundStatus == 'TRANH_CHAP';
    final isProcessing = order.refundStatus == 'DANG_XU_LY';
    final hasBank = (order.refundAccountNumber != null && order.refundAccountNumber!.trim().isNotEmpty);
    final hasReceipt = order.refundReceiptUrl != null && order.refundReceiptUrl!.trim().isNotEmpty;

    final cardBg = isDark ? const Color(0xFF1E2430) : Colors.white;
    final borderColor = isRefunded
        ? const Color(0xFF6CE9A6)
        : (isWaitingCustomer
            ? const Color(0xFF7DD3FC)
            : (isDisputed
                ? const Color(0xFFFDA29B)
                : (isCash ? (isDark ? const Color(0xFF333C4D) : const Color(0xFFE2E8F0)) : const Color(0xFFFED7AA))));
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
                      : (isWaitingCustomer
                          ? (isDark ? const Color(0xFF0C243B) : const Color(0xFFF0F9FF))
                          : (isDisputed
                              ? (isDark ? const Color(0xFF2E1715) : const Color(0xFFFEF2F2))
                              : (isDark ? const Color(0xFF2B1D12) : const Color(0xFFFFF7ED)))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isRefunded
                      ? Icons.check_circle_outline_rounded
                      : (isWaitingCustomer
                          ? Icons.access_time_rounded
                          : (isDisputed ? Icons.warning_amber_rounded : Icons.info_outline_rounded)),
                  color: isRefunded
                      ? const Color(0xFF027A48)
                      : (isWaitingCustomer
                          ? const Color(0xFF0284C7)
                          : (isDisputed ? const Color(0xFFDC2626) : const Color(0xFFEA580C))),
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
                              ? 'Quán đã hoàn tiền thành công về tài khoản'
                              : (isWaitingCustomer
                                  ? 'Quán đã chuyển khoản và gửi biên lai đối soát'
                                  : (isDisputed
                                      ? 'Đang khiếu nại chưa nhận được tiền'
                                      : 'Quán sẽ quét mã VietQR để hoàn tiền trực tiếp'))),
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
                        : (isWaitingCustomer
                            ? const Color(0xFFF0F9FF)
                            : (isDisputed
                                ? const Color(0xFFFEF2F2)
                                : (isProcessing ? const Color(0xFFEFF8FF) : const Color(0xFFFFF6ED)))),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isRefunded
                          ? const Color(0xFF6CE9A6)
                          : (isWaitingCustomer
                              ? const Color(0xFFBAE6FD)
                              : (isDisputed
                                  ? const Color(0xFFFECACA)
                                  : (isProcessing ? const Color(0xFF84CAFF) : const Color(0xFFFDB022)))),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    isRefunded
                        ? '✓ Hoàn tiền thành công'
                        : (isWaitingCustomer
                            ? '⏳ Chờ bạn xác nhận'
                            : (isDisputed
                                ? '⚠️ Đang khiếu nại'
                                : (isProcessing ? '⏳ Đang chuyển khoản' : (hasBank ? '⏳ Chờ quán chuyển tiền' : '⚠️ Chờ nhập STK')))),
                    style: GoogleFonts.outfit(
                      color: isRefunded
                          ? const Color(0xFF027A48)
                          : (isWaitingCustomer
                              ? const Color(0xFF0284C7)
                              : (isDisputed
                                  ? const Color(0xFFDC2626)
                                  : (isProcessing ? const Color(0xFF175CD3) : const Color(0xFFB54708)))),
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

            // Disputed Warning Box if any
            if (isDisputed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 6),
                        Text(
                          'Đang tra soát ngân hàng',
                          style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bạn đã báo chưa nhận được tiền. Quán và Admin đang kiểm tra lại giao dịch với ngân hàng.',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFFB91C1C)),
                    ),
                    if (order.refundDisputeReason != null && order.refundDisputeReason!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lý do: "${order.refundDisputeReason}"',
                        style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF7F1D1D)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Waiting Customer Action Box
            if (isWaitingCustomer) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Quán đã gửi biên lai chuyển tiền',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF0369A1)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Vui lòng xem ảnh biên lai và kiểm tra tài khoản ngân hàng của bạn:',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF0284C7)),
                    ),
                    const SizedBox(height: 10),

                    // Button: Xem biên lai
                    if (hasReceipt)
                      SizedBox(
                        width: double.infinity,
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: () => _showReceiptDialog(context, order.refundReceiptUrl!),
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                          label: Text(
                            'Xem Ảnh Biên Lai Chuyển Tiền',
                            style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0284C7),
                            side: const BorderSide(color: Color(0xFF38BDF8), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Action buttons: Đã nhận tiền vs Chưa nhận tiền
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton(
                              onPressed: _isSubmitting ? null : _handleDispute,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                backgroundColor: Colors.white,
                              ),
                              child: Text(
                                'Chưa nhận tiền',
                                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _handleConfirmReceived,
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: Text(
                                'Đã nhận tiền',
                                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w800),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF16A34A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Bank Account Info Card
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
                        if (!isRefunded && !isWaitingCustomer)
                          InkWell(
                            onTap: widget.onEditBank,
                            child: Text(
                              'Đổi STK',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFFC6011)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        VietQrBankLogo(
                          bank: VietQrBanks.findByCodeOrBin(order.refundBank),
                          width: 36,
                          height: 36,
                          borderRadius: 8,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${VietQrBanks.findByCodeOrBin(order.refundBank).shortName} • ${order.refundAccountNumber}',
                                style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w800, color: textPrimary),
                              ),
                              if (order.refundAccountName != null && order.refundAccountName!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  order.refundAccountName!.toUpperCase(),
                                  style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
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
                        onPressed: widget.onEditBank,
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

            // Receipt Button when isRefunded or isDisputed
            if ((isRefunded || isDisputed) && hasReceipt) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _showReceiptDialog(context, order.refundReceiptUrl!),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.remove_red_eye_outlined, size: 15, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Text(
                      'Xem lại ảnh biên lai chuyển tiền',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0284C7),
                        decoration: TextDecoration.underline,
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
