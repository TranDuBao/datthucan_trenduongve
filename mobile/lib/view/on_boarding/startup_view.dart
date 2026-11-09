import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../../common/user_role_helper.dart';
import '../../providers/notification_provider.dart';
import '../login/welcome_view.dart';
import '../main_tabview/main_tabview.dart';
import '../restaurant_owner/restaurant_owner_main_view.dart';
import '../../services/fcm_push_service.dart';
import '../../common/locator.dart';

/// Màn hình Splash Food Route hoàn chỉnh & chuyên nghiệp:
/// - Frame 0: Hiển thị ĐẦY ĐỦ Logo (Vòng tròn cam + Người lái xe máy + Tên thương hiệu "Food Route")
///   khớp 100% với màn hình khởi động gốc của Android, TUYỆT ĐỐI KHÔNG CÒN VÒNG CAM TRỐNG TRƠN.
/// - Nhịp 1 (0.0s - 0.45s): Logo sinh động tại tâm, xe nhún nổ máy rồ ga êm ái, vòng sóng nhẹ lan tỏa.
/// - Nhịp 2 (0.45s - 1.25s): Xe vặn ga tăng tốc phóng tiến về phía trước (hướng TRÁI), có 3 vệt gió mảnh
///   phía sau đuôi xe, đồng thời vòng cam mở rộng bao phủ toàn màn hình.
/// - Nhịp 3 (1.25s - 1.50s): Chuyển tiếp mượt mà vào trang chính của ứng dụng.
class StartupView extends StatefulWidget {
  const StartupView({super.key});

  // ══════════════════════════════════════════════════════════════
  // THAM SỐ CẤU HÌNH TỐC ĐỘ & HIỆU ỨNG (DỄ DÀNG ĐIỀU CHỈNH)
  // ══════════════════════════════════════════════════════════════
  /// Đường kính vòng cam tại tâm: 192.0 dp
  static const double circleDiameterDp = 192.0;

  /// Tổng thời lượng animation chuyển trang: 1400ms (~1.4 giây)
  static const Duration totalDuration = Duration(milliseconds: 1400);

  /// Độ nhún ga nổ máy tại tâm (px): 3.5px
  static const double bounceDipPx = 3.5;

  /// Chu kỳ và biên độ nhịp thở khi mạng chậm chờ tải lâu
  static const Duration idleDuration = Duration(milliseconds: 1400);
  static const double idleFloatPx = 2.5;

  /// Timeout an toàn nếu dịch vụ mạng gặp sự cố: 8 giây
  static const Duration safeTimeout = Duration(seconds: 8);

  /// Màu cam thương hiệu chuẩn (#FF5A0E)
  static const Color orangeColor = Color(0xFFFF5A0E);

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView>
    with TickerProviderStateMixin {
  // Controller chính điều khiển animation
  late AnimationController _controller;

  // Controller phụ cho nhịp thở nổ máy nếu app tải ngầm lâu
  late AnimationController _idleController;

  bool _isInitCompleted = false;
  bool _hasNavigated = false;
  bool _hasPrecached = false;

  @override
  void initState() {
    super.initState();
    _initControllers();

    // Bắt đầu chạy ngay sau khi frame đầu tiên được vẽ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _runAnimationAndInitFlow();
      }
    });
  }

  void _initControllers() {
    _controller = AnimationController(
      vsync: this,
      duration: StartupView.totalDuration,
    );

    _idleController = AnimationController(
      vsync: this,
      duration: StartupView.idleDuration,
    );

    // Lắng nghe tiến trình
    _controller.addListener(() {
      // Điểm tạm dừng chờ ở mốc 450ms (~0.32) nếu app nạp chưa xong
      if (_controller.value >= 0.32 && !_isInitCompleted && _controller.isAnimating) {
        _controller.stop();
        _idleController.repeat(reverse: true);
      }
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToTarget();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPrecached) {
      _hasPrecached = true;
      precacheImage(const AssetImage("assets/img/splash_bg.png"), context);
      precacheImage(const AssetImage("assets/img/on_boarding_2.png"), context);
    }
  }

  /// Chạy song song nạp dữ liệu và chuyển động
  Future<void> _runAnimationAndInitFlow() async {
    _controller.forward();

    final initFuture = _initAppServices().timeout(
      StartupView.safeTimeout,
      onTimeout: () {
        debugPrint("[Splash] Safe timeout reached after 8s, navigating.");
      },
    );

    await initFuture;
    if (!mounted) return;

    _isInitCompleted = true;

    // Nếu đang tạm dừng ở nhịp rồ ga, tiếp tục phóng xe đi ngay
    if (!_controller.isAnimating && _controller.value < 1.0) {
      _idleController.stop();
      _controller.forward();
    }
  }

  /// Khởi tạo các dịch vụ ngầm (Socket, Notification, Session)
  Future<void> _initAppServices() async {
    try {
      final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
      notifProvider.initialize();
    } catch (e) {
      debugPrint("[Splash] Init error: $e");
    }

    if (Globs.udValueBool(Globs.userLogin)) {
      ServiceCall.userPayload = Globs.udValue(Globs.userPayload);
    }

    await Future.delayed(const Duration(milliseconds: 150));
  }

  /// Chuyển sang màn hình tiếp theo với hiệu ứng Fade ngắn 250ms
  void _navigateToTarget() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final Widget targetPage;
    if (Globs.udValueBool(Globs.userLogin)) {
      if (UserRoleHelper.isMerchant) {
        targetPage = const RestaurantOwnerMainView();
      } else {
        targetPage = const MainTabView();
      }
    } else {
      targetPage = const WelcomeView();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => targetPage,
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );

    // Non-blocking post-navigation tasks (Token registration, Cold-start routing, Version check)
    Future.microtask(() {
      if (Globs.udValueBool(Globs.userLogin)) {
        FcmPushService.instance.registerTokenWithBackend();
      }
      FcmPushService.instance.handleInitialMessage();
      final navContext = locator<NavigationService>().navigatorKey.currentContext;
      if (navContext != null) {
        FcmPushService.instance.checkAppVersion(navContext);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runFallbackNavigation();
      });
      return _buildStaticLogo(context);
    }

    final media = MediaQuery.of(context).size;
    const circleDiameter = StartupView.circleDiameterDp;
    const baseRadius = circleDiameter / 2;
    const riderWidth = circleDiameter * 0.72;
    const riderHeight = riderWidth * 1.05;
    final maxScreenRadius = Offset(media.width, media.height).distance;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Nền Splash có sẵn trong assets
          Image.asset(
            "assets/img/splash_bg.png",
            width: media.width,
            height: media.height,
            fit: BoxFit.cover,
          ),

          // Lớp Animation được bọc riêng bằng RepaintBoundary cho hiệu năng 60fps
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: Listenable.merge([_controller, _idleController]),
              builder: (context, child) {
                final t = _controller.value;

                // ── 1. Giai đoạn nổ máy nhún nhẹ tại tâm (0.0s -> 0.45s, t = 0.0 -> 0.32)
                double bounceY = 0.0;
                double shadowScale = 1.0;
                double pulseProgress = 0.0;

                if (t <= 0.32) {
                  final p = t / 0.32;
                  // Nhún 2 nhịp nổ máy rồ ga sinh động
                  bounceY = math.sin(p * 2 * math.pi) * StartupView.bounceDipPx;
                  shadowScale = 1.0 + (bounceY / StartupView.bounceDipPx) * 0.15;
                  pulseProgress = p;
                }

                // Nhịp thở Idle nếu mạng chậm chờ tải lâu
                double idleOffset = 0.0;
                if (_idleController.isAnimating) {
                  idleOffset = math.sin(_idleController.value * 2 * math.pi) *
                      StartupView.idleFloatPx;
                }

                // ── 2. Giai đoạn xe tăng tốc phóng đi & vòng cam mở rộng (0.45s -> 1.4s, t = 0.32 -> 1.0)
                double slideX = 0.0;
                double riderOpacity = 1.0;
                double textOpacity = 1.0;
                double speedFactor = 0.0;
                double tiltAngle = 0.0;
                double expandRadius = baseRadius;

                if (t > 0.32) {
                  final p = (t - 0.32) / (1.0 - 0.32);

                  // Xe phóng tiến về bên TRÁI (tọa độ âm)
                  final driveCurve = Curves.easeInCubic.transform(p);
                  slideX = -driveCurve * (media.width * 0.90);

                  // Nghiêng chúi đầu xe nhẹ tự nhiên khi vặn ga
                  tiltAngle = -0.04 * math.sin(p.clamp(0.0, 1.0) * math.pi);

                  // Vệt gió xuất hiện khi xe chạy và tan dần
                  speedFactor = math.sin(p * math.pi);

                  // Vòng tròn cam mở rộng phủ kín màn hình
                  final circleP = Curves.easeInOutCubic.transform(p);
                  expandRadius = baseRadius + (maxScreenRadius - baseRadius) * circleP;

                  // Xe và chữ mờ dần khi vòng cam phủ kín
                  if (p > 0.30) {
                    final fadeP = ((p - 0.30) / 0.45).clamp(0.0, 1.0);
                    riderOpacity = 1.0 - fadeP;
                    textOpacity = 1.0 - fadeP;
                  }
                }

                return Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    // Sóng lan tỏa nhẹ ở đầu
                    if (pulseProgress > 0.0 && pulseProgress < 1.0 && t <= 0.32)
                      CustomPaint(
                        painter: PulseRipplePainter(
                          progress: pulseProgress,
                          baseRadius: baseRadius,
                          color: StartupView.orangeColor,
                        ),
                      ),

                    // Vòng tròn cam (vẽ bằng CustomPainter drawCircle, sắc nét và nhẹ)
                    CustomPaint(
                      painter: CircleExpansionPainter(
                        currentRadius: expandRadius,
                        color: StartupView.orangeColor,
                      ),
                    ),

                    // Cụm nội dung: Xe máy, bóng đổ, vệt gió và tên thương hiệu
                    Center(
                      child: Transform.translate(
                        offset: Offset(0, idleOffset),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: circleDiameter,
                              height: circleDiameter,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  // Bóng mờ ellipse dưới bánh xe
                                  if (riderOpacity > 0.01)
                                    Positioned(
                                      bottom: (circleDiameter - riderHeight) / 2 + circleDiameter * 0.25,
                                      child: Transform.translate(
                                        offset: Offset(slideX, 0),
                                        child: Opacity(
                                          opacity: (riderOpacity * 0.30).clamp(0.0, 0.30),
                                          child: Container(
                                            width: riderWidth * 0.65 * shadowScale,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.all(
                                                Radius.elliptical(50, 7),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                  // 3 vệt gió mảnh bo đầu PHÍA SAU xe (bên phải), chỉ hiện khi xe phóng đi
                                  if (speedFactor > 0.05 && riderOpacity > 0.05)
                                    Positioned.fill(
                                      child: Transform.translate(
                                        offset: Offset(slideX, 0),
                                        child: CustomPaint(
                                          painter: WindStreaksPainter(
                                            speedFactor: speedFactor,
                                            riderWidth: riderWidth,
                                            riderHeight: riderHeight,
                                          ),
                                        ),
                                      ),
                                    ),

                                  // Người lái xe máy (luôn có mặt ngay từ frame 0, nổ máy -> phóng đi)
                                  if (riderOpacity > 0.01)
                                    Transform.translate(
                                      offset: Offset(slideX, bounceY),
                                      child: Transform.rotate(
                                        angle: tiltAngle,
                                        child: Opacity(
                                          opacity: riderOpacity.clamp(0.0, 1.0),
                                          child: Image.asset(
                                            "assets/img/on_boarding_2.png",
                                            width: riderWidth,
                                            height: riderHeight,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Chữ thương hiệu "Food Route"
                            if (textOpacity > 0.01) ...[
                              const SizedBox(height: 16),
                              Opacity(
                                opacity: textOpacity.clamp(0.0, 1.0),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Food ",
                                        style: TextStyle(
                                          color: TColor.primaryText,
                                          fontSize: 24,
                                          fontFamily: "Metropolis",
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: "Route",
                                        style: TextStyle(
                                          color: StartupView.orangeColor,
                                          fontSize: 24,
                                          fontFamily: "Metropolis",
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _runFallbackNavigation() async {
    await _initAppServices().timeout(
      StartupView.safeTimeout,
      onTimeout: () {},
    );
    _navigateToTarget();
  }

  /// Giao diện tĩnh dự phòng
  Widget _buildStaticLogo(BuildContext context) {
    const circleDiameter = StartupView.circleDiameterDp;
    const riderWidth = circleDiameter * 0.72;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            "assets/img/splash_bg.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            width: circleDiameter,
            height: circleDiameter,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: StartupView.orangeColor,
            ),
          ),
          Image.asset(
            "assets/img/on_boarding_2.png",
            width: riderWidth,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

/// CustomPainter vẽ 3 vệt gió mảnh bo đầu phía sau xe (bên phải xe)
class WindStreaksPainter extends CustomPainter {
  final double speedFactor;
  final double riderWidth;
  final double riderHeight;

  WindStreaksPainter({
    required this.speedFactor,
    required this.riderWidth,
    required this.riderHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (speedFactor <= 0.02) return;

    final alpha = (0.60 * speedFactor).clamp(0.0, 0.60);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    final startX = size.width / 2 + riderWidth * 0.36;

    // 3 vệt gió mảnh phía sau xe
    final y1 = size.height / 2 - riderHeight * 0.12;
    final len1 = 36.0 * speedFactor;
    canvas.drawLine(Offset(startX + 8, y1), Offset(startX + 8 + len1, y1), paint);

    final y2 = size.height / 2 + riderHeight * 0.08;
    final len2 = 52.0 * speedFactor;
    canvas.drawLine(Offset(startX, y2), Offset(startX + len2, y2), paint);

    final y3 = size.height / 2 + riderHeight * 0.26;
    final len3 = 28.0 * speedFactor;
    canvas.drawLine(Offset(startX + 12, y3), Offset(startX + 12 + len3, y3), paint);
  }

  @override
  bool shouldRepaint(covariant WindStreaksPainter oldDelegate) {
    return oldDelegate.speedFactor != speedFactor;
  }
}

/// CustomPainter vẽ vòng tròn cam mở rộng phủ kín màn hình
class CircleExpansionPainter extends CustomPainter {
  final double currentRadius;
  final Color color;

  CircleExpansionPainter({
    required this.currentRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentRadius <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, currentRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CircleExpansionPainter oldDelegate) {
    return oldDelegate.currentRadius != currentRadius || oldDelegate.color != color;
  }
}

/// CustomPainter vẽ hiệu ứng sóng lan tỏa nhẹ ở đầu
class PulseRipplePainter extends CustomPainter {
  final double progress;
  final double baseRadius;
  final Color color;

  PulseRipplePainter({
    required this.progress,
    required this.baseRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final r = baseRadius * (1.0 + 0.28 * progress);
    final alpha = (0.35 * (1.0 - progress)).clamp(0.0, 0.35);
    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * (1.0 - progress * 0.5);
    canvas.drawCircle(center, r, paint);
  }

  @override
  bool shouldRepaint(covariant PulseRipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
