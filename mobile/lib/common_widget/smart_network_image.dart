import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../common/color_extension.dart';
import '../common/globs.dart';

class SmartNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData? placeholderIcon;

  const SmartNetworkImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon,
  });

  String _formatUrl(String url) {
    if (url.isEmpty) return url;
    return SVKey.formatImageUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final double safeIconSize = (height > 0 && height.isFinite && height < 1000)
        ? height * 0.4
        : ((width > 0 && width.isFinite && width < 1000) ? width * 0.4 : 40.0);

    Widget fallbackWidget = Container(
      width: width,
      height: height,
      color: TColor.primary.withOpacity(0.12),
      child: Icon(placeholderIcon ?? Icons.restaurant, color: TColor.primary, size: safeIconSize),
    );

    final cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty) {
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: fallbackWidget)
          : fallbackWidget;
    }

    // Case 1: Base64 data URI (data:image/...;base64,...)
    if (cleanUrl.startsWith('data:image') || cleanUrl.contains('base64,')) {
      try {
        final base64String = cleanUrl.split('base64,').last.trim();
        final Uint8List bytes = base64Decode(base64String);
        Widget imgWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => fallbackWidget,
        );
        return borderRadius != null
            ? ClipRRect(borderRadius: borderRadius!, child: imgWidget)
            : imgWidget;
      } catch (e) {
        return borderRadius != null
            ? ClipRRect(borderRadius: borderRadius!, child: fallbackWidget)
            : fallbackWidget;
      }
    }

    // Case 2: Asset path (assets/img/...)
    if (cleanUrl.startsWith('assets/')) {
      Widget imgWidget = Image.asset(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => fallbackWidget,
      );
      return borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: imgWidget)
          : imgWidget;
    }

    // Case 3: Network URL (http://... or https://...)
    final formattedUrl = _formatUrl(cleanUrl);
    Widget imgWidget = Image.network(
      formattedUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => fallbackWidget,
    );

    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius!, child: imgWidget)
        : imgWidget;
  }
}
