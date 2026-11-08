import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../common/color_extension.dart';
import '../common/format_utils.dart';

enum NotificationModalType {
  success,
  info,
  warning,
}

class ModernNotificationModal extends StatefulWidget {
  final String title;
  final String message;
  final String? badgeText;
  final String buttonText;
  final NotificationModalType type;
  final VoidCallback? onConfirm;

  const ModernNotificationModal({
    super.key,
    required this.title,
    required this.message,
    this.badgeText,
    this.buttonText = 'Đóng',
    this.type = NotificationModalType.success,
    this.onConfirm,
  });

  /// Hiển thị modal thông báo thành công với animation đẹp mắt
  static Future<void> showSuccess({
    required BuildContext context,
    String? title,
    String? message,
    String? badgeText,
    String? buttonText,
    VoidCallback? onConfirm,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ModernNotificationModal',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (ctx, anim1, anim2) => ModernNotificationModal(
        title: title ?? context.l10n.modalFeedbackThanksTitle,
        message: message ?? context.l10n.modalFeedbackThanksMessage,
        badgeText: badgeText ?? context.l10n.modalFeedbackBadge,
        buttonText: buttonText ?? context.l10n.commonClose,
        type: NotificationModalType.success,
        onConfirm: onConfirm,
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
  State<ModernNotificationModal> createState() => _ModernNotificationModalState();
}

class _ModernNotificationModalState extends State<ModernNotificationModal>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _fadeContentAnimation;
  late Animation<double> _particlesAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );

    _checkAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeInOutCubic),
    );

    _fadeContentAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.40, 0.95, curve: Curves.easeOut),
    );

    _particlesAnimation = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.20, 0.75, curve: Curves.easeOutBack),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.type) {
      case NotificationModalType.success:
        return const Color(0xFF10B981);
      case NotificationModalType.warning:
        return const Color(0xFFF59E0B);
      case NotificationModalType.info:
        return TColor.primary;
    }
  }

  Color get _accentDarkColor {
    switch (widget.type) {
      case NotificationModalType.success:
        return const Color(0xFF059669);
      case NotificationModalType.warning:
        return const Color(0xFFD97706);
      case NotificationModalType.info:
        return const Color(0xFFE04F05);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: math.min(MediaQuery.of(context).size.width * 0.86, 380),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E232E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
              border: Border.all(
                color: isDark ? const Color(0xFF2E3646) : const Color(0xFFF1F3F7),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Animated Badge with pulse & floating decorative sparkles
                SizedBox(
                  width: 130,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Vòng hào quang phập phồng (Pulse glow)
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final pulseValue = _pulseController.value;
                          return Container(
                            width: 96 + (pulseValue * 14),
                            height: 96 + (pulseValue * 14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accentColor.withValues(
                                alpha: 0.08 + (pulseValue * 0.06),
                              ),
                            ),
                          );
                        },
                      ),

                      // Vòng đệm trung gian
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _accentColor.withValues(alpha: 0.14),
                        ),
                      ),

                      // Các đốm trang trí lấp lánh (Sparkles)
                      AnimatedBuilder(
                        animation: _particlesAnimation,
                        builder: (context, _) {
                          final p = _particlesAnimation.value;
                          return Stack(
                            children: [
                              Positioned(
                                top: 12 - (p * 4),
                                right: 18 + (p * 2),
                                child: Opacity(
                                  opacity: p.clamp(0.0, 1.0),
                                  child: const Icon(
                                    LucideIcons.sparkle,
                                    size: 16,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 16 - (p * 4),
                                left: 16 - (p * 2),
                                child: Opacity(
                                  opacity: p.clamp(0.0, 1.0),
                                  child: Icon(
                                    LucideIcons.sparkle,
                                    size: 14,
                                    color: _accentColor,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 32,
                                left: 10,
                                child: Opacity(
                                  opacity: (p * 0.8).clamp(0.0, 1.0),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFC6011),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Vòng tròn trung tâm chính
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_accentColor, _accentDarkColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withValues(alpha: 0.38),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: AnimatedBuilder(
                            animation: _checkAnimation,
                            builder: (context, _) {
                              if (widget.type == NotificationModalType.success) {
                                return CustomPaint(
                                  painter: _ModernCheckmarkPainter(
                                    progress: _checkAnimation.value,
                                  ),
                                );
                              } else {
                                return Center(
                                  child: Icon(
                                    widget.type == NotificationModalType.warning
                                        ? LucideIcons.alertTriangle
                                        : LucideIcons.info,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Nội dung xuất hiện theo hiệu ứng Fade + Slide
                FadeTransition(
                  opacity: _fadeContentAnimation,
                  child: Column(
                    children: [
                      // Tag badge nhỏ xinh xắn nếu có
                      if (widget.badgeText != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.badgeText!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _accentDarkColor,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Tiêu đề
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: TColor.primaryTextOf(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Mô tả
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Nút bấm Đóng / Xác nhận hiện đại
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [TColor.primary, const Color(0xFFFF7A3D)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: TColor.primary.withValues(alpha: 0.32),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              widget.onConfirm?.call();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.buttonText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  LucideIcons.check,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
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
}

class _ModernCheckmarkPainter extends CustomPainter {
  final double progress;

  _ModernCheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width * 0.30, size.height * 0.52);
    path.lineTo(size.width * 0.44, size.height * 0.67);
    path.lineTo(size.width * 0.72, size.height * 0.37);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final extract = metric.extractPath(0.0, metric.length * progress);
    canvas.drawPath(extract, paint);
  }

  @override
  bool shouldRepaint(_ModernCheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
