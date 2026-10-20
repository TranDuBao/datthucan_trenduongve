import 'package:flutter/material.dart';
import 'skeleton_box.dart';

class SkeletonCircle extends StatelessWidget {
  final double radius;
  final EdgeInsetsGeometry? margin;

  const SkeletonCircle({
    super.key,
    double? radius,
    double? size,
    this.margin,
  }) : radius = radius ?? (size != null ? size / 2 : 20.0);

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: radius * 2,
      height: radius * 2,
      borderRadius: radius,
      margin: margin,
    );
  }
}
