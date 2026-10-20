import 'dart:math' as math;
import 'package:flutter/material.dart';

class CurvedHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 38);
    // Smooth quadratic curve bowing downward in the center
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 34,
      size.width,
      size.height - 38,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageAsset;
  final bool showBackButton;
  final VoidCallback? onBack;

  const AuthHeaderWidget({
    super.key,
    this.title = "FoodRoute",
    this.subtitle = "Món ngon dọc đường đi,\nĐặt món trước, ghé là có.",
    this.imageAsset,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = 220.0 + topPadding;

    return ClipPath(
      clipper: CurvedHeaderClipper(),
      child: Container(
        height: headerHeight,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF4200),
              Color(0xFFFF5714),
              Color(0xFFFF6D22),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background circle - Left
            Positioned(
              left: -50,
              top: topPadding - 40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),

            // Decorative background circle - Right
            Positioned(
              right: -30,
              top: topPadding + 10,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),

            // Optional Back Button
            if (showBackButton)
              Positioned(
                left: 16,
                top: topPadding + 10,
                child: InkWell(
                  onTap: onBack ?? () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),

            // Main Content Row
            Positioned(
              left: 24,
              right: 18,
              top: topPadding + (showBackButton ? 42 : 24),
              bottom: 30,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Text Area (Left)
                  Expanded(
                    flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  fontFamily: 'Metropolis',
                                ),
                              ),
                              const TextSpan(
                                text: ".",
                                style: TextStyle(
                                  color: Color(0xFFFFCA28),
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Metropolis',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Driver Illustration (Right)
                  Expanded(
                    flex: 9,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Soft glowing spotlight circle behind driver
                        Container(
                          width: 115,
                          height: 115,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),

                        // Speed dash lines
                        Positioned(
                          left: -6,
                          bottom: 28,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 18,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 10,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Delivery Driver Image
                        Image.asset(
                          imageAsset ?? "assets/img/on_boarding_2.png",
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
