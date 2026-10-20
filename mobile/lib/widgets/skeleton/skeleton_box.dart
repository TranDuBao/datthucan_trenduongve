import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final dynamic borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? const Color(0xFF232836) : const Color(0xFFE2E8F0);

    BorderRadiusGeometry radius;
    if (borderRadius is BorderRadiusGeometry) {
      radius = borderRadius as BorderRadiusGeometry;
    } else if (borderRadius is num) {
      radius = BorderRadius.circular((borderRadius as num).toDouble());
    } else {
      radius = BorderRadius.circular(8.0);
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
      ),
    );
  }
}
