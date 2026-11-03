import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../common/color_extension.dart';
import '../view/main_tabview/main_tabview.dart';
import '../view/more/order_history_view.dart';

class OrderCancelledModal extends StatefulWidget {
  final int orderId;
  final String? message;

  const OrderCancelledModal({
    super.key,
    required this.orderId,
    this.message,
  });

  static Future<void> show({
    required BuildContext context,
    required int orderId,
    String? message,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'OrderCancelled',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => OrderCancelledModal(
        orderId: orderId,
        message: message,
      ),
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
  State<OrderCancelledModal> createState() => _OrderCancelledModalState();
}

class _OrderCancelledModalState extends State<OrderCancelledModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E222D) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Hủy Đơn với Animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFEE4E2),
                          border: Border.all(
                            color: const Color(0xFFFECDCA),
                            width: 3,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 44,
                            color: Color(0xFFD92D20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tiêu đề
                    Text(
                      'Đã hủy đơn hàng',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Badge Mã đơn
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#DH-${widget.orderId}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFD0D4E0) : const Color(0xFF475467),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nội dung giải thích
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        widget.message ??
                            'Đơn hàng chưa thanh toán đã được hủy thành công.\nKhông phát sinh giao dịch hoàn tiền.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Nút Hành động
                    Row(
                      children: [
                        // Nút Về Trang Chủ
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () {
                                try {
                                  context.read<MapProvider>().cancelStopoverOrder();
                                } catch (_) {}
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const MainTabView(initialTab: 2),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D5DD),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Về trang chủ',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF344054),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Nút Xem Đơn Hàng
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () {
                                try {
                                  context.read<MapProvider>().cancelStopoverOrder();
                                } catch (_) {}
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => const MainTabView(initialTab: 2),
                                  ),
                                  (route) => false,
                                );
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const OrderHistoryView(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFC6011),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Xem đơn hàng',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
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
