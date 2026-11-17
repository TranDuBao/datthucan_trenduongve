import 'package:flutter/material.dart';
import '../common_widget/smart_network_image.dart';

class ImageViewerDialog {
  static void show(BuildContext context, String imageUrl) {
    if (imageUrl.trim().isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SmartNetworkImage(
                      imageUrl: imageUrl,
                      width: MediaQuery.of(ctx).size.width * 0.95,
                      height: MediaQuery.of(ctx).size.height * 0.8,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 45,
                right: 16,
                child: SafeArea(
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(ctx).pop(),
                      tooltip: 'Đóng',
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
