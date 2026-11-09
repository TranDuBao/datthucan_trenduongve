import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../common/color_extension.dart';
import '../common/format_utils.dart';
import '../view/main_tabview/main_tabview.dart';
import '../view/more/order_history_view.dart';

enum PaymentSuccessAction {
  viewNavigation,
  viewOrder,
  continueShopping,
}

class PaymentSuccessModal extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback? onDismiss;

  const PaymentSuccessModal({
    super.key,
    required this.orderData,
    this.onDismiss,
  });

  static Future<PaymentSuccessAction?> show({
    required BuildContext context,
    required Map<String, dynamic> orderData,
  }) {
    return showGeneralDialog<PaymentSuccessAction>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PaymentSuccess',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => PaymentSuccessModal(orderData: orderData),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curve,
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  State<PaymentSuccessModal> createState() => _PaymentSuccessModalState();
}

class _PaymentSuccessModalState extends State<PaymentSuccessModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _fadeContentAnimation;

  int get orderId =>
      widget.orderData['orderId'] ??
      widget.orderData['maDonHang'] ??
      widget.orderData['id'] ??
      0;

  double get totalAmount {
    final raw = widget.orderData['payment']?['soTien'] ??
        widget.orderData['tongTien'] ??
        widget.orderData['totalAmount'] ??
        widget.orderData['amount'] ??
        0;
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  String get formattedDateTime {
    final rawDate = widget.orderData['payment']?['ngayThanhToan'] ??
        widget.orderData['thoiGianDat'] ??
        widget.orderData['createdAt'];
    if (rawDate != null) {
      try {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        return DateFormat('HH:mm - dd/MM/yyyy').format(dt);
      } catch (_) {}
    }
    return DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.90, curve: Curves.easeInOutCubic),
    );

    _fadeContentAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToNavigation() {
    Navigator.of(context, rootNavigator: true).pop(PaymentSuccessAction.viewNavigation);
  }

  void _navigateToOrder() {
    Navigator.of(context, rootNavigator: true).pop(PaymentSuccessAction.viewOrder);
  }

  void _navigateToHome() {
    Navigator.of(context, rootNavigator: true).pop(PaymentSuccessAction.continueShopping);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedAmount = NumberFormat("#,###", "vi_VN").format(totalAmount.toInt());

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: BoxConstraints(maxWidth: 420, maxHeight: media.height * 0.85),
        decoration: BoxDecoration(
          color: TColor.cardOf(context),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
          border: Border.all(
            color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF0F1F5),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Icon vòng tròn với animation vẽ nét dấu tích ✓
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _AnimatedCheckmarkPainter(progress: _checkAnimation.value),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Nội dung xuất hiện theo hiệu ứng Fade + Slide
                FadeTransition(
                  opacity: _fadeContentAnimation,
                  child: Column(
                    children: [
                      Text(
                        context.l10n.paymentSuccessTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: TColor.primaryTextOf(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.paymentSuccessSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: TColor.secondaryTextOf(context),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Hộp thông tin chi tiết giao dịch
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2430) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              context,
                              label: context.l10n.paymentSuccessOrderId,
                              value: "#DH-$orderId",
                              isBold: true,
                              badgeColor: TColor.primary.withOpacity(0.12),
                              badgeTextColor: TColor.primary,
                            ),
                            const Divider(height: 18, thickness: 0.8),
                            _buildInfoRow(
                              context,
                              label: context.l10n.paymentSuccessAmount,
                              value: "$formattedAmount đ",
                              valueColor: const Color(0xFF10B981),
                              isBold: true,
                              fontSize: 16,
                            ),
                            const Divider(height: 18, thickness: 0.8),
                            _buildInfoRow(
                              context,
                              label: context.l10n.paymentSuccessTime,
                              value: formattedDateTime,
                            ),
                            const Divider(height: 18, thickness: 0.8),
                            _buildInfoRow(
                              context,
                              label: context.l10n.paymentSuccessMethod,
                              value: (widget.orderData['phuongThucThanhToan'] ?? '').toString().toUpperCase() == 'COD'
                                  ? context.l10n.paymentSuccessCashMethod
                                  : context.l10n.paymentSuccessVietQRMethod,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút thao tác
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _navigateToNavigation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColor.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(Icons.navigation_rounded, size: 18),
                          label: Text(context.l10n.paymentSuccessViewRoute),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: _navigateToOrder,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: TColor.primaryTextOf(context),
                            side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(context.l10n.paymentSuccessViewOrderDetails),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    double fontSize = 13,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.secondaryTextOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (badgeColor != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: badgeTextColor ?? TColor.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? TColor.primaryTextOf(context),
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _AnimatedCheckmarkPainter extends CustomPainter {
  final double progress;

  _AnimatedCheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Start at left arm of checkmark
    path.moveTo(size.width * 0.28, size.height * 0.52);
    // Draw line down to bottom vertex
    path.lineTo(size.width * 0.44, size.height * 0.68);
    // Draw line up to top right
    path.lineTo(size.width * 0.73, size.height * 0.36);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extract = metric.extractPath(0.0, metric.length * progress);
    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(_AnimatedCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
