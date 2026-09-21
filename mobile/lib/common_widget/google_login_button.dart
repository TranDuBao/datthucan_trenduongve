import 'package:flutter/material.dart';

class GoogleLogoWidget extends StatelessWidget {
  final double size;
  const GoogleLogoWidget({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

/// Precise official Google "G" logo SVG vector path rendering
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.save();
    canvas.scale(w / 24.0, h / 24.0);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // 1. Blue segment (#4285F4)
    paint.color = const Color(0xFF4285F4);
    final pathBlue = Path()
      ..moveTo(22.56, 12.25)
      ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10.0)
      ..lineTo(12.0, 10.0)
      ..lineTo(12.0, 14.26)
      ..lineTo(17.92, 14.26)
      ..cubicTo(17.67, 15.63, 16.89, 16.79, 15.73, 17.57)
      ..lineTo(15.73, 20.33)
      ..lineTo(19.28, 20.33)
      ..cubicTo(21.36, 18.41, 22.56, 15.6, 22.56, 12.25)
      ..close();
    canvas.drawPath(pathBlue, paint);

    // 2. Green segment (#34A853)
    paint.color = const Color(0xFF34A853);
    final pathGreen = Path()
      ..moveTo(12.0, 23.0)
      ..cubicTo(14.97, 23.0, 17.46, 22.02, 19.28, 20.33)
      ..lineTo(15.73, 17.57)
      ..cubicTo(14.75, 18.23, 13.48, 18.63, 12.0, 18.63)
      ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
      ..lineTo(2.18, 14.1)
      ..lineTo(2.18, 16.94)
      ..cubicTo(3.99, 20.53, 7.7, 23.0, 12.0, 23.0)
      ..close();
    canvas.drawPath(pathGreen, paint);

    // 3. Yellow segment (#FBBC05)
    paint.color = const Color(0xFFFBBC05);
    final pathYellow = Path()
      ..moveTo(5.84, 14.1)
      ..cubicTo(5.62, 13.44, 5.5, 12.73, 5.5, 12.0)
      ..cubicTo(5.5, 11.27, 5.62, 10.56, 5.84, 9.9)
      ..lineTo(5.84, 7.06)
      ..lineTo(2.18, 7.06)
      ..cubicTo(1.43, 8.55, 1.0, 10.22, 1.0, 12.0)
      ..cubicTo(1.0, 13.78, 1.43, 15.45, 2.18, 16.94)
      ..lineTo(5.84, 14.1)
      ..close();
    canvas.drawPath(pathYellow, paint);

    // 4. Red segment (#EA4335)
    paint.color = const Color(0xFFEA4335);
    final pathRed = Path()
      ..moveTo(12.0, 5.38)
      ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
      ..lineTo(19.36, 3.87)
      ..cubicTo(17.45, 2.09, 14.97, 1.0, 12.0, 1.0)
      ..cubicTo(7.7, 1.0, 3.99, 3.47, 2.18, 7.06)
      ..lineTo(5.84, 9.9)
      ..cubicTo(6.71, 7.3, 9.14, 5.38, 12.0, 5.38)
      ..close();
    canvas.drawPath(pathRed, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;

  const GoogleLoginButton({
    super.key,
    required this.onPressed,
    this.title = "Login with Google",
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GoogleLogoWidget(size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF3C4043),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
