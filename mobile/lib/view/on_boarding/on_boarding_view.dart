import 'dart:math';
import 'package:flutter/material.dart';
import 'package:food_route/common/color_extension.dart';
import 'package:food_route/common/format_utils.dart';
import 'package:food_route/common_widget/round_button.dart';
import 'package:food_route/providers/language_provider.dart';
import 'package:food_route/view/main_tabview/main_tabview.dart';
import 'package:food_route/widgets/phone_with_hand_widget.dart';
import 'package:provider/provider.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => _OnBoardingViewState();
}

class _OnBoardingViewState extends State<OnBoardingView>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int selectPage = 0;
  final PageController controller = PageController();
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();

    controller.addListener(() {
      setState(() {
        selectPage = controller.page?.round() ?? 0;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage("assets/img/on_boarding_1.png"), context);
    precacheImage(const AssetImage("assets/img/on_boarding_2.png"), context);
    precacheImage(
        const AssetImage("assets/img/hand_holding_phone.png"), context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_animController.isAnimating) {
        _animController.repeat();
      }
    } else {
      if (_animController.isAnimating) {
        _animController.stop();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animController.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final lang = context.watch<LanguageProvider>();

    final l10n = context.l10n;

    final List<Map<String, String>> pageArr = [
      {
        "title": l10n.onboardingTitle1,
        "subtitle": l10n.onboardingSubtitle1,
        "image": "assets/img/on_boarding_1.png",
      },
      {
        "title": l10n.onboardingTitle2,
        "subtitle": l10n.onboardingSubtitle2,
        "image": "assets/img/on_boarding_2.png",
      },
      {
        "title": l10n.onboardingTitle3,
        "subtitle": l10n.onboardingSubtitle3,
        "image": "assets/img/on_boarding_3.png",
      },
    ];

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: controller,
            itemCount: pageArr.length,
            itemBuilder: ((context, index) {
              var pObj = pageArr[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: media.width,
                    height: media.width,
                    alignment: Alignment.center,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // Họa tiết mây trôi và sao nền phía sau xe (Slide 2: Tài xế chạy xe)
                        if (index == 1)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: ScooterBackgroundPainter(
                                    progress: _animController.value,
                                  ),
                                );
                              },
                            ),
                          ),

                        // Minh họa chính
                        AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            final bounce = index == 2
                                ? 0.0
                                : sin((_animController.value *
                                                2 *
                                                pi) +
                                        (index * 0.8)) *
                                    (index == 1 ? 4.5 : 3.0);
                            final tilt = index == 1
                                ? sin(_animController.value * 2 * pi) * 0.012
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(0, bounce),
                              child: Transform.rotate(
                                angle: tilt,
                                child: child,
                              ),
                            );
                          },
                          child: index == 2
                              ? RepaintBoundary(
                                  child: SizedBox(
                                    width: (media.width * 0.96) *
                                        PhoneWithHandConfig.imageAspectRatio,
                                    height: media.width * 0.96,
                                    child: PhoneWithHandWidget(
                                      animation: _animController,
                                      isVietnamese: lang.languageCode == 'vi',
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  pObj["image"].toString(),
                                  width: index == 0
                                      ? media.width * 0.78
                                      : media.width * 0.68,
                                  fit: BoxFit.contain,
                                ),
                        ),

                        // Hiệu ứng vệt gió lướt từ trước xe ra sau xe (Slide 2: Tài xế chạy xe)
                        if (index == 1)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: ScooterForegroundPainter(
                                    progress: _animController.value,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: media.width * 0.2,
                  ),
                  Text(
                    pObj["title"].toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: TColor.primaryText,
                        fontSize: 28,
                        fontWeight: FontWeight.w800),
                  ),
                  SizedBox(
                    height: media.width * 0.05,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      pObj["subtitle"].toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: TColor.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    height: media.width * 0.20,
                  ),
                ],
              );
            }),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: media.height * 0.6,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: pageArr.asMap().entries.map((entry) {
                  var index = entry.key;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: 6,
                    decoration: BoxDecoration(
                        color: index == selectPage
                            ? TColor.primary
                            : TColor.placeholder,
                        borderRadius: BorderRadius.circular(4)),
                  );
                }).toList(),
              ),
              SizedBox(
                height: media.height * 0.28,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: RoundButton(
                    title: selectPage >= 2
                        ? l10n.commonGetStarted
                        : l10n.commonNext,
                    onPressed: () {
                      if (selectPage >= 2) {
                        // Home Screen
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainTabView(),
                          ),
                        );
                      } else {
                        // Next Screen
                        setState(() {
                          selectPage = selectPage + 1;
                          controller.animateToPage(selectPage,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.bounceInOut);
                        });
                      }
                    }),
              ),
            ],
          ),

          // Nút chuyển đổi nhanh song ngữ Tiếng Việt / Tiếng Anh góc trên bên phải
          Positioned(
            top: 10,
            right: 20,
            child: SafeArea(
              child: GestureDetector(
                onTap: () {
                  final newCode = lang.languageCode == 'vi' ? 'en' : 'vi';
                  lang.setLanguage(newCode);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: TColor.placeholder.withValues(alpha: 0.25)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang.languageCode == 'vi' ? '🇻🇳 VN' : '🇬🇧 EN',
                        style: TextStyle(
                          color: TColor.primaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: TColor.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Họa tiết vẽ phía sau xe: Áng mây trôi bồng bềnh và sao nền (không có vòng tròn cam)
class ScooterBackgroundPainter extends CustomPainter {
  final double progress;

  ScooterBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Áng mây trôi bồng bềnh (Xe chạy sang trái -> Mây lướt từ trái sang phải: từ trước đầu xe ra sau đuôi xe)
    final cloudPaint = Paint()
      ..color = const Color(0xFFFFE0D4).withValues(alpha: 0.80)
      ..style = PaintingStyle.fill;

    _drawCloud(canvas, w, h * 0.10, progress % 1.0, 1.15, cloudPaint);
    _drawCloud(canvas, w, h * 0.20, (progress + 0.45) % 1.0, 0.90, cloudPaint);
    _drawCloud(canvas, w, h * 0.32, (progress + 0.75) % 1.0, 0.75, cloudPaint);

    // 2. Ngôi sao 4 cánh nền lấp lánh nhẹ nhàng
    _drawStar(canvas, w * 0.28, h * 0.23, 7.5, (progress * 2 * pi));
    _drawStar(canvas, w * 0.76, h * 0.18, 6.0, (progress * 2 * pi + 2.0));
    _drawStar(canvas, w * 0.82, h * 0.48, 7.0, (progress * 2 * pi + 3.5));
  }

  void _drawCloud(
      Canvas canvas, double w, double y, double prog, double scale, Paint paint) {
    final totalWidth = w + 180.0;
    final x = -100.0 + (prog * totalWidth);

    final r = 18.0 * scale;
    canvas.drawCircle(Offset(x, y), r, paint);
    canvas.drawCircle(Offset(x + 16 * scale, y - 6 * scale), r * 0.88, paint);
    canvas.drawCircle(Offset(x + 30 * scale, y + 2 * scale), r * 0.72, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - r, y, 52 * scale, r),
        Radius.circular(9 * scale),
      ),
      paint,
    );
  }

  void _drawStar(
      Canvas canvas, double cx, double cy, double baseSize, double phase) {
    final scale = 0.6 + 0.4 * sin(phase);
    final alpha = (0.4 + 0.6 * sin(phase)).clamp(0.0, 1.0);
    final size = baseSize * scale;

    final paint = Paint()
      ..color = const Color(0xFFFFB703).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(cx, cy - size);
    path.quadraticBezierTo(cx, cy, cx + size, cy);
    path.quadraticBezierTo(cx, cy, cx, cy + size);
    path.quadraticBezierTo(cx, cy, cx - size, cy);
    path.quadraticBezierTo(cx, cy, cx, cy - size);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScooterBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Họa tiết vẽ tiền cảnh: Vệt gió lướt chuyển động (từ đầu xe ra sau) & Ngôi sao 4 cánh lấp lánh
class ScooterForegroundPainter extends CustomPainter {
  final double progress;

  ScooterForegroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Vệt gió lướt ngang từ trước xe (trái) ra sau xe (phải)
    final windOrange = Paint()
      ..color = const Color(0xFFFF7A00).withValues(alpha: 0.38)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final windGrey = Paint()
      ..color = const Color(0xFF9E9E9E).withValues(alpha: 0.22)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _drawWindStreak(canvas, w, h * 0.32, progress, 1.3, 48, windOrange);
    _drawWindStreak(
        canvas, w, h * 0.54, (progress + 0.38) % 1.0, 1.6, 60, windGrey);
    _drawWindStreak(
        canvas, w, h * 0.74, (progress + 0.68) % 1.0, 1.8, 52, windOrange);
    _drawWindStreak(
        canvas, w, h * 0.86, (progress + 0.18) % 1.0, 2.1, 44, windGrey);

    // 2. Ngôi sao 4 cánh lấp lánh tiền cảnh
    _drawStar(canvas, w * 0.16, h * 0.40, 7.5, (progress * 2 * pi + 1.2));
    _drawStar(canvas, w * 0.86, h * 0.36, 8.5, (progress * 2 * pi + 3.4));
    _drawStar(canvas, w * 0.32, h * 0.68, 6.0, (progress * 2 * pi + 4.8));
    _drawStar(canvas, w * 0.84, h * 0.66, 7.0, (progress * 2 * pi + 0.6));
  }

  void _drawWindStreak(Canvas canvas, double w, double y, double prog,
      double speedMult, double length, Paint paint) {
    final totalDist = w + length + 80;
    final x = -length - 20 + (((prog * speedMult) % 1.0) * totalDist);
    if (x > -length && x < w + length) {
      canvas.drawLine(Offset(x, y), Offset(x + length, y), paint);
    }
  }

  void _drawStar(
      Canvas canvas, double cx, double cy, double baseSize, double phase) {
    final scale = 0.5 + 0.5 * sin(phase);
    final alpha = (0.35 + 0.65 * sin(phase)).clamp(0.0, 1.0);
    final size = baseSize * scale;

    final paint = Paint()
      ..color = const Color(0xFFFFB703).withValues(alpha: alpha)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(cx, cy - size);
    path.quadraticBezierTo(cx, cy, cx + size, cy);
    path.quadraticBezierTo(cx, cy, cx, cy + size);
    path.quadraticBezierTo(cx, cy, cx - size, cy);
    path.quadraticBezierTo(cx, cy, cx, cy - size);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ScooterForegroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
