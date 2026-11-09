import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../common/format_utils.dart';
import '../providers/map_provider.dart';

class OrderEnjoyMealModal extends StatefulWidget {
  final String storeName;
  final String orderCode;
  final VoidCallback onComplete;
  final String? buttonText;

  const OrderEnjoyMealModal({
    super.key,
    required this.storeName,
    required this.orderCode,
    required this.onComplete,
    this.buttonText,
  });

  static Future<void> show({
    required BuildContext context,
    required String storeName,
    required String orderCode,
    required VoidCallback onComplete,
    String? buttonText,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'OrderEnjoyMeal',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => OrderEnjoyMealModal(
        storeName: storeName,
        orderCode: orderCode,
        onComplete: onComplete,
        buttonText: buttonText,
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
  State<OrderEnjoyMealModal> createState() => _OrderEnjoyMealModalState();
}

class _OrderEnjoyMealModalState extends State<OrderEnjoyMealModal>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _entranceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );
    _entranceController.forward();

    // Subtle pulsing animation for food/heart icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFC6011).withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Animated Icon with glowing pulse ──
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ambient outer glow (warm pastel orange)
                          Container(
                            width: 92,
                            height: 92,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFF3ED),
                            ),
                          ),
                          // Inner circle with gradient
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFF7A2F), Color(0xFFFC6011)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x40FC6011),
                                  blurRadius: 14,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          // Small driving/safety badge
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_bike_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Title ──
                  Text(
                    context.l10n.orderEnjoyMealTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF1E293B),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Safe journey message ──
                  Text(
                    context.l10n.orderEnjoyMealSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Store & Order info chip ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.storeName,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF1E293B),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đơn #${widget.orderCode} • Đã nhận món',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF10B981),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Action Buttons ──
                  // Button 1: Hoàn tất chuyến đi
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onComplete();
                        },
                        icon: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
                        label: Text(
                          widget.buttonText ?? context.l10n.orderEnjoyMealContinue,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Button 2: Xem lại bản đồ (nếu bấm nhầm) → hoàn tác trạng thái đã lấy món
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: TextButton.icon(
                      onPressed: () {
                        // Revert pickup status so the card reappears
                        final mapProvider = context.read<MapProvider>();
                        mapProvider.markOrderPickedUp(false);
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.map_outlined,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      label: Text(
                        context.l10n.orderEnjoyMealReviewMap,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
