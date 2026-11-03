import 'package:flutter/material.dart';

enum SocialPlatform {
  facebook,
  instagram,
  telegram,
  gmail,
}

class SocialBrandIcon extends StatelessWidget {
  final SocialPlatform platform;
  final double size;
  final VoidCallback? onTap;

  const SocialBrandIcon({
    super.key,
    required this.platform,
    this.size = 40,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: _buildDecoration(),
        child: Center(
          child: _buildIconContent(),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    switch (platform) {
      case SocialPlatform.facebook:
        return BoxDecoration(
          color: const Color(0xFF1877F2),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1877F2).withValues(alpha: 0.28),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case SocialPlatform.instagram:
        return BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFFFEDA75), // Yellow
              Color(0xFFFA7E1E), // Orange
              Color(0xFFD62976), // Magenta Pink
              Color(0xFF962FBF), // Purple
              Color(0xFF4F5BD5), // Indigo
            ],
            stops: [0.0, 0.22, 0.50, 0.78, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD62976).withValues(alpha: 0.32),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case SocialPlatform.telegram:
        return BoxDecoration(
          color: const Color(0xFF24A1DE),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF24A1DE).withValues(alpha: 0.32),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case SocialPlatform.gmail:
        return BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );
    }
  }

  Widget _buildIconContent() {
    switch (platform) {
      case SocialPlatform.facebook:
        return CustomPaint(
          size: Size(size * 0.56, size * 0.56),
          painter: const FacebookIconPainter(),
        );

      case SocialPlatform.instagram:
        return CustomPaint(
          size: Size(size * 0.52, size * 0.52),
          painter: const InstagramIconPainter(),
        );

      case SocialPlatform.telegram:
        return Transform.translate(
          offset: Offset(-size * 0.03, size * 0.01),
          child: CustomPaint(
            size: Size(size * 0.54, size * 0.54),
            painter: const TelegramIconPainter(),
          ),
        );

      case SocialPlatform.gmail:
        return CustomPaint(
          size: Size(size * 0.58, size * 0.46),
          painter: const GmailIconPainter(),
        );
    }
  }
}

/// Official Facebook Klavika 'f' vector geometry (Direct normalized viewBox 0 0 24 24)
class FacebookIconPainter extends CustomPainter {
  final Color color;
  const FacebookIconPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(w * (14.0 / 24), h * (13.5 / 24));
    path.lineTo(w * (16.5 / 24), h * (13.5 / 24));
    path.lineTo(w * (17.5 / 24), h * (9.5 / 24));
    path.lineTo(w * (14.0 / 24), h * (9.5 / 24));
    path.lineTo(w * (14.0 / 24), h * (7.5 / 24));
    path.cubicTo(
      w * (14.0 / 24), h * (6.47 / 24),
      w * (14.32 / 24), h * (5.76 / 24),
      w * (15.77 / 24), h * (5.76 / 24),
    );
    path.lineTo(w * (17.5 / 24), h * (5.76 / 24));
    path.lineTo(w * (17.5 / 24), h * (2.18 / 24));
    path.cubicTo(
      w * (16.92 / 24), h * (2.10 / 24),
      w * (15.86 / 24), h * (2.00 / 24),
      w * (14.62 / 24), h * (2.00 / 24),
    );
    path.cubicTo(
      w * (11.83 / 24), h * (2.00 / 24),
      w * (9.92 / 24), h * (3.70 / 24),
      w * (9.92 / 24), h * (6.82 / 24),
    );
    path.lineTo(w * (9.92 / 24), h * (9.5 / 24));
    path.lineTo(w * (6.52 / 24), h * (9.5 / 24));
    path.lineTo(w * (6.52 / 24), h * (13.5 / 24));
    path.lineTo(w * (9.92 / 24), h * (13.5 / 24));
    path.lineTo(w * (9.92 / 24), h * (22.5 / 24));
    path.lineTo(w * (14.0 / 24), h * (22.5 / 24));
    path.lineTo(w * (14.0 / 24), h * (13.5 / 24));
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Instagram squircle camera glyph (Preserved exactly as approved)
class InstagramIconPainter extends CustomPainter {
  final Color color;
  const InstagramIconPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.10
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 1. Outer rounded squircle
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.06, w * 0.88, h * 0.88),
      Radius.circular(w * 0.26),
    );
    canvas.drawRRect(rect, strokePaint);

    // 2. Center lens circle
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.22, strokePaint);

    // 3. Top-right flash dot
    canvas.drawCircle(Offset(w * 0.73, h * 0.27), w * 0.065, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Telegram paper airplane vector (Preserved exactly as approved)
class TelegramIconPainter extends CustomPainter {
  final Color color;
  const TelegramIconPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(w * (21.5 / 24), h * (2.8 / 24));
    path.lineTo(w * (2.2 / 24), h * (10.6 / 24));
    path.lineTo(w * (7.2 / 24), h * (12.8 / 24));
    path.lineTo(w * (17.5 / 24), h * (6.5 / 24));
    path.lineTo(w * (9.5 / 24), h * (14.2 / 24));
    path.lineTo(w * (9.0 / 24), h * (19.2 / 24));
    path.lineTo(w * (12.5 / 24), h * (16.0 / 24));
    path.lineTo(w * (17.5 / 24), h * (19.8 / 24));
    path.close();

    canvas.drawPath(path, paint);

    final foldPaint = Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;

    final foldPath = Path();
    foldPath.moveTo(w * (7.2 / 24), h * (12.8 / 24));
    foldPath.lineTo(w * (12.5 / 24), h * (16.0 / 24));
    foldPath.lineTo(w * (9.0 / 24), h * (19.2 / 24));
    foldPath.close();

    canvas.drawPath(foldPath, foldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Google Gmail "M" envelope vector geometry (Clean ribbon V & hollow center opening)
class GmailIconPainter extends CustomPainter {
  const GmailIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Left Blue pillar
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path();
    bluePath.moveTo(w * (3.0 / 24), h * (18.0 / 24));
    bluePath.lineTo(w * (3.0 / 24), h * (7.5 / 24));
    bluePath.lineTo(w * (7.0 / 24), h * (10.5 / 24));
    bluePath.lineTo(w * (7.0 / 24), h * (20.0 / 24));
    bluePath.lineTo(w * (4.5 / 24), h * (20.0 / 24));
    bluePath.quadraticBezierTo(w * (3.0 / 24), h * (20.0 / 24), w * (3.0 / 24), h * (18.5 / 24));
    bluePath.close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Right Green pillar
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path();
    greenPath.moveTo(w * (21.0 / 24), h * (18.0 / 24));
    greenPath.lineTo(w * (21.0 / 24), h * (7.5 / 24));
    greenPath.lineTo(w * (17.0 / 24), h * (10.5 / 24));
    greenPath.lineTo(w * (17.0 / 24), h * (20.0 / 24));
    greenPath.lineTo(w * (19.5 / 24), h * (20.0 / 24));
    greenPath.quadraticBezierTo(w * (21.0 / 24), h * (20.0 / 24), w * (21.0 / 24), h * (18.5 / 24));
    greenPath.close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Top-left Dark Red corner fold
    final darkRedPaint = Paint()
      ..color = const Color(0xFFC5221F)
      ..style = PaintingStyle.fill;
    final darkRedPath = Path();
    darkRedPath.moveTo(w * (3.0 / 24), h * (6.5 / 24));
    darkRedPath.quadraticBezierTo(w * (3.0 / 24), h * (5.0 / 24), w * (4.5 / 24), h * (5.0 / 24));
    darkRedPath.lineTo(w * (7.0 / 24), h * (5.0 / 24));
    darkRedPath.lineTo(w * (7.0 / 24), h * (10.5 / 24));
    darkRedPath.lineTo(w * (3.0 / 24), h * (7.5 / 24));
    darkRedPath.close();
    canvas.drawPath(darkRedPath, darkRedPaint);

    // 4. Top-right Yellow corner fold
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path();
    yellowPath.moveTo(w * (21.0 / 24), h * (6.5 / 24));
    yellowPath.quadraticBezierTo(w * (21.0 / 24), h * (5.0 / 24), w * (19.5 / 24), h * (5.0 / 24));
    yellowPath.lineTo(w * (17.0 / 24), h * (5.0 / 24));
    yellowPath.lineTo(w * (17.0 / 24), h * (10.5 / 24));
    yellowPath.lineTo(w * (21.0 / 24), h * (7.5 / 24));
    yellowPath.close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 5. Center Red M fold ribbon
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path();
    redPath.moveTo(w * (4.5 / 24), h * (5.0 / 24));
    redPath.lineTo(w * (12.0 / 24), h * (10.8 / 24));
    redPath.lineTo(w * (19.5 / 24), h * (5.0 / 24));
    redPath.lineTo(w * (17.0 / 24), h * (5.0 / 24));
    redPath.lineTo(w * (12.0 / 24), h * (8.8 / 24));
    redPath.lineTo(w * (7.0 / 24), h * (5.0 / 24));
    redPath.close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
