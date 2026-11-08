import 'dart:math';
import 'package:flutter/material.dart';

/// Các hằng số cấu hình vị trí & kích thước ô màn hình và chuyển động
/// (Dễ dàng tinh chỉnh tỉ lệ khi thay đổi ảnh minh họa)
class PhoneWithHandConfig {
  // Kích thước ảnh bàn tay 3D gốc (hand_holding_phone.png)
  static const double imageOriginalWidth = 560.0;
  static const double imageOriginalHeight = 1156.0;
  static const double imageAspectRatio =
      imageOriginalWidth / imageOriginalHeight; // ~0.4844

  // Tỉ lệ chuẩn hóa của ô màn hình đục lỗ (đo chính xác trên ảnh 560x1156)
  static const double screenLeftRatio = 143.0 / imageOriginalWidth; // ~0.255357
  static const double screenTopRatio = 44.0 / imageOriginalHeight; // ~0.038062
  static const double screenWidthRatio = 274.0 / imageOriginalWidth; // ~0.489286
  static const double screenHeightRatio = 597.0 / imageOriginalHeight; // ~0.516436
  static const double screenRadiusRatio = 22.0 / imageOriginalWidth; // ~0.039286

  // Độ nới viền màn hình ra thêm phía sau ảnh để đảm bảo không bị hở mép (pixel)
  static const double screenBleed = 1.5;

  // Biên độ chuyển động trôi nhẹ nhàng của cả khối tay + điện thoại (±4px)
  static const double floatAmplitude = 4.0;
}

/// Widget Minh họa Onboarding Slide 3:
/// Bàn tay 3D chân thật cầm điện thoại với ô màn hình đục lỗ trong suốt,
/// lồng ghép bản đồ lộ trình chuyển động sống động bên trong.
class PhoneWithHandWidget extends StatelessWidget {
  final Animation<double> animation;
  final bool isVietnamese;

  const PhoneWithHandWidget({
    super.key,
    required this.animation,
    required this.isVietnamese,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final double progress = animation.value;

        // Chuyển động trôi lên xuống nhẹ nhàng (biên độ ±4px, chu kỳ ~4 giây, easeInOutSine)
        final double floatFactor =
            disableAnimations ? 0.0 : sin(progress * 2 * pi);
        final double floatOffset =
            -floatFactor * PhoneWithHandConfig.floatAmplitude;

        // Bóng mờ ellipse bên dưới co giãn ngược pha với chuyển động trôi
        final double shadowScale = 1.0 - (floatFactor * 0.08);
        final double shadowOpacity =
            (0.16 - floatFactor * 0.04).clamp(0.06, 0.22);

        return LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Vị trí và kích thước ô màn hình tính theo tỉ lệ chuẩn hóa
          final screenLeft = (w * PhoneWithHandConfig.screenLeftRatio) -
              PhoneWithHandConfig.screenBleed;
          final screenTop = (h * PhoneWithHandConfig.screenTopRatio) -
              PhoneWithHandConfig.screenBleed;
          final screenWidth = (w * PhoneWithHandConfig.screenWidthRatio) +
              (PhoneWithHandConfig.screenBleed * 2);
          final screenHeight = (h * PhoneWithHandConfig.screenHeightRatio) +
              (PhoneWithHandConfig.screenBleed * 2);
          final screenRadius = w * PhoneWithHandConfig.screenRadiusRatio;

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. Bóng mờ ellipse bên dưới co giãn ngược pha
              Positioned(
                bottom: 2.0,
                left: w * 0.16,
                right: w * 0.16,
                height: 12.0,
                child: Transform.scale(
                  scaleX: shadowScale,
                  scaleY: shadowScale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: shadowOpacity),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: shadowOpacity),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Khối tay + điện thoại trôi nhẹ nhàng (±4px)
              Transform.translate(
                offset: Offset(0, floatOffset),
                child: SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Lớp dưới: Widget màn hình hiện có (bản đồ + lộ trình animation + quán + điểm đến)
                      Positioned(
                        left: screenLeft,
                        top: screenTop,
                        width: screenWidth,
                        height: screenHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(screenRadius),
                          child: Container(
                            color: const Color(0xFFF8F9FA),
                            child: CustomPaint(
                              painter: InnerRouteMapPainter(
                                progress: disableAnimations ? 0.5 : progress,
                                isVietnamese: isVietnamese,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Lớp trên: Ảnh bàn tay 3D đục lỗ trong suốt phủ toàn bộ
                      // Ngón tay và ngón cái tự nhiên đè lên mép điện thoại tạo chiều sâu chân thật
                      Positioned.fill(
                        child: Image.asset(
                          'assets/img/hand_holding_phone.png',
                          width: w,
                          height: h,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}

/// Bản đồ lộ trình bên trong màn hình điện thoại:
/// Tuyến đường nối Điểm đi -> Quán ăn lấy hàng -> Về nhà với hoạt ảnh di chuyển đều đặn, mượt mà
class InnerRouteMapPainter extends CustomPainter {
  final double progress;
  final bool isVietnamese;

  InnerRouteMapPainter({
    required this.progress,
    required this.isVietnamese,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Mảng công viên cây xanh (góc trên bên trái)
    final parkPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.32, h * 0.18),
          const Radius.circular(10),
        ),
      );
    canvas.drawPath(parkPath, Paint()..color = const Color(0xFFE8F5E9));

    // Cây xanh nhỏ trong công viên
    final treePaint = Paint()..color = const Color(0xFF81C784);
    canvas.drawCircle(Offset(w * 0.12, h * 0.10), 4.0, treePaint);
    canvas.drawCircle(Offset(w * 0.22, h * 0.08), 3.0, treePaint);
    canvas.drawCircle(Offset(w * 0.18, h * 0.16), 3.5, treePaint);

    // 2. Mảng hồ nước xanh biếc (góc dưới bên phải)
    final lakePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.60, h * 0.70, w * 0.36, h * 0.22),
          const Radius.circular(12),
        ),
      );
    canvas.drawPath(lakePath, Paint()..color = const Color(0xFFE1F5FE));

    // Gợn sóng nhỏ trên mặt hồ
    final wavePaint = Paint()
      ..color = const Color(0xFF81D4FA)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(w * 0.66, h * 0.77), Offset(w * 0.78, h * 0.77), wavePaint);
    canvas.drawLine(
        Offset(w * 0.72, h * 0.83), Offset(w * 0.86, h * 0.83), wavePaint);

    // 3. Hệ thống đường phố đô thị
    final roadBorder = Paint()
      ..color = const Color(0xFFECEEF2)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke;

    final roadSurface = Paint()
      ..color = Colors.white
      ..strokeWidth = 9.5
      ..style = PaintingStyle.stroke;

    // Các tuyến phố ngang & dọc
    _drawRoad(canvas, Offset(0, h * 0.26), Offset(w, h * 0.26), roadBorder,
        roadSurface);
    _drawRoad(canvas, Offset(0, h * 0.48), Offset(w, h * 0.48), roadBorder,
        roadSurface);
    _drawRoad(canvas, Offset(0, h * 0.76), Offset(w, h * 0.76), roadBorder,
        roadSurface);
    _drawRoad(canvas, Offset(w * 0.28, 0), Offset(w * 0.28, h), roadBorder,
        roadSurface);
    _drawRoad(canvas, Offset(w * 0.72, 0), Offset(w * 0.72, h), roadBorder,
        roadSurface);

    // 4. Lộ trình kết nối: Điểm đi (A) -> Quán ăn lấy hàng (B) -> Về nhà (C)
    final pStart = Offset(w * 0.22, h * 0.76);
    final pStore = Offset(w * 0.54, h * 0.48);
    final pHome = Offset(w * 0.78, h * 0.19);

    final routePath = Path();
    routePath.moveTo(pStart.dx, pStart.dy);
    routePath.cubicTo(
      w * 0.20,
      h * 0.60,
      w * 0.38,
      h * 0.52,
      pStore.dx,
      pStore.dy,
    );
    routePath.cubicTo(
      w * 0.66,
      h * 0.44,
      w * 0.72,
      h * 0.30,
      pHome.dx,
      pHome.dy,
    );

    // Đường ray lộ trình nền (Pastel warm orange)
    final routeBgPaint = Paint()
      ..color = const Color(0xFFFFE0D2)
      ..strokeWidth = 4.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routeBgPaint);

    final metric = routePath.computeMetrics().first;
    final totalLen = metric.length;

    // Chuyển động ĐỀU ĐẶN TUYỆT ĐỐI - KHÔNG DỪNG KHÔNG GIẬT:
    // progress chạy tuần hoàn 0.0 -> 1.0 với vận tốc hằng số êm ái
    final double cycleProgress = progress % 1.0;
    final double currentDist = (totalLen * cycleProgress).clamp(0.0, totalLen);

    // Độ mờ chuyển tiếp mềm mại ở đầu và cuối chu kỳ để không bị giật hình khi lặp
    double trailAlpha = 1.0;
    if (cycleProgress > 0.92) {
      trailAlpha = ((1.0 - cycleProgress) / 0.08).clamp(0.0, 1.0);
    } else if (cycleProgress < 0.08) {
      trailAlpha = (cycleProgress / 0.08).clamp(0.0, 1.0);
    }

    // Vẽ vệt đường đang di chuyển với hiệu ứng phát sáng Neon
    if (currentDist > 2.0) {
      final activePath = metric.extractPath(0, currentDist);

      // Hào quang vệt sáng
      canvas.drawPath(
        activePath,
        Paint()
          ..color = const Color(0xFFFC6011).withValues(alpha: 0.25 * trailAlpha)
          ..strokeWidth = 8.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
      );

      // Nét sáng chính rực rỡ
      canvas.drawPath(
        activePath,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFFF9800).withValues(alpha: trailAlpha),
              const Color(0xFFFC6011).withValues(alpha: trailAlpha),
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, h))
          ..strokeWidth = 4.4
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // 5. Điểm định vị di chuyển mượt mà (Moving Beacon)
    final tangent = metric.getTangentForOffset(currentDist);
    if (tangent != null && trailAlpha > 0.05) {
      final pos = tangent.position;

      // Hào quang sóng radar tỏa ra từ điểm đang chạy
      final pulseRadius = 9.0 + 3.0 * sin(cycleProgress * 12 * pi).abs();
      canvas.drawCircle(
        pos,
        pulseRadius,
        Paint()
          ..color = const Color(0xFFFC6011).withValues(alpha: 0.25 * trailAlpha)
          ..style = PaintingStyle.fill,
      );

      // Điểm tròn định vị lõi trắng viền cam sắc nét
      canvas.drawCircle(
        pos,
        6.5,
        Paint()..color = const Color(0xFFFC6011).withValues(alpha: trailAlpha),
      );
      canvas.drawCircle(
        pos,
        3.8,
        Paint()..color = Colors.white.withValues(alpha: trailAlpha),
      );
      canvas.drawCircle(
        pos,
        2.0,
        Paint()..color = const Color(0xFFFC6011).withValues(alpha: trailAlpha),
      );
    }

    // 6. Hiệu ứng sóng Radar liên tục tại Quán ăn ghé lấy
    final storeRadar = 8.0 + 10.0 * ((cycleProgress * 2.5) % 1.0);
    final storeRadarAlpha =
        (0.35 * (1.0 - ((cycleProgress * 2.5) % 1.0))).clamp(0.0, 0.35);
    canvas.drawCircle(
      pStore,
      storeRadar,
      Paint()
        ..color = const Color(0xFFFC6011).withValues(alpha: storeRadarAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Trạng thái đã lấy món hay chưa (chuyển đổi mượt khi xe chạy qua quán)
    final bool hasPickedUp = cycleProgress >= 0.50 && cycleProgress <= 0.95;

    // 7. Sóng Radar xanh tỏa sáng tại Nhà
    final homeRadar = 8.0 + 9.0 * (((cycleProgress * 2.5) + 0.5) % 1.0);
    final homeRadarAlpha =
        (0.32 * (1.0 - (((cycleProgress * 2.5) + 0.5) % 1.0))).clamp(0.0, 0.32);
    canvas.drawCircle(
      pHome,
      homeRadar,
      Paint()
        ..color = const Color(0xFF2E7D32).withValues(alpha: homeRadarAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 8. Chốt mốc A: Điểm đi (Khách hàng khởi hành)
    _drawPin(canvas, pStart, const Color(0xFF1976D2));
    _drawBadge(
      canvas,
      Offset(pStart.dx, pStart.dy + 14),
      isVietnamese ? "Điểm đi" : "Start",
      const Color(0xFF1976D2),
    );

    // 9. Chốt mốc B: Quán ăn lấy hàng
    _drawPin(canvas, pStore, const Color(0xFFFC6011));
    _drawStoreBadge(
      canvas,
      Offset(pStore.dx, pStore.dy - 20),
      isVietnamese ? "Quán ăn" : "Food store",
      hasPickedUp
          ? (isVietnamese ? "✔ Đã lấy món" : "✔ Picked up")
          : (isVietnamese ? "Ghé lấy 1p" : "1 min pickup"),
      hasPickedUp,
    );

    // 10. Chốt mốc C: Về nhà
    _drawPin(canvas, pHome, const Color(0xFF2E7D32));
    _drawBadge(
      canvas,
      Offset(pHome.dx, pHome.dy - 14),
      isVietnamese ? "Về nhà" : "Home",
      const Color(0xFF2E7D32),
    );
  }

  void _drawRoad(
      Canvas canvas, Offset p1, Offset p2, Paint border, Paint road) {
    canvas.drawLine(p1, p2, border);
    canvas.drawLine(p1, p2, road);
  }

  void _drawPin(Canvas canvas, Offset pos, Color color) {
    canvas.drawCircle(
      Offset(pos.dx, pos.dy + 1.5),
      8.0,
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );
    canvas.drawCircle(pos, 7.5, Paint()..color = color);
    canvas.drawCircle(pos, 3.2, Paint()..color = Colors.white);
  }

  void _drawBadge(Canvas canvas, Offset center, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.0,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final w = tp.width + 8.0;
    final h = tp.height + 3.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      const Radius.circular(5.0),
    );

    canvas.drawRRect(
      rrect.shift(const Offset(0, 1.0)),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );
    canvas.drawRRect(rrect, Paint()..color = color);
    tp.paint(
        canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawStoreBadge(Canvas canvas, Offset center, String title,
      String subTitle, bool isHighlight) {
    final titleTp = TextPainter(
      text: TextSpan(
        text: "🍜 $title",
        style: TextStyle(
          color: isHighlight
              ? const Color(0xFF2E7D32)
              : const Color(0xFFFC6011),
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titleTp.layout();

    final subTp = TextPainter(
      text: TextSpan(
        text: subTitle,
        style: TextStyle(
          color: isHighlight
              ? const Color(0xFF2E7D32)
              : const Color(0xFF757575),
          fontSize: 6.8,
          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subTp.layout();

    final maxW = max(titleTp.width, subTp.width);
    final w = maxW + 10.0;
    final h = titleTp.height + subTp.height + 4.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      const Radius.circular(6.5),
    );

    canvas.drawRRect(
      rrect.shift(const Offset(0, 1.5)),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );
    canvas.drawRRect(rrect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = (isHighlight
                ? const Color(0xFF2E7D32)
                : const Color(0xFFFC6011))
            .withValues(alpha: 0.40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    titleTp.paint(
        canvas, Offset(center.dx - titleTp.width / 2, center.dy - h / 2 + 1.5));
    subTp.paint(
        canvas,
        Offset(center.dx - subTp.width / 2,
            center.dy + h / 2 - subTp.height - 1.5));
  }

  @override
  bool shouldRepaint(covariant InnerRouteMapPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isVietnamese != isVietnamese;
}
