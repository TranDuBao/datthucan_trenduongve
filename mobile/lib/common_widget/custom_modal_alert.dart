import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class CustomModalAlert extends StatelessWidget {
  final String title;
  final String message;
  final String? infoTag;
  final String buttonTitle;
  final bool isError;
  final VoidCallback? onConfirm;

  const CustomModalAlert({
    super.key,
    required this.title,
    required this.message,
    this.infoTag,
    this.buttonTitle = "Hoàn tất",
    this.isError = false,
    this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String? infoTag,
    String buttonTitle = "Hoàn tất",
    bool isError = false,
    VoidCallback? onConfirm,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1B1E28) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: CustomModalAlert(
            title: title,
            message: message,
            infoTag: infoTag,
            buttonTitle: buttonTitle,
            isError: isError,
            onConfirm: onConfirm,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF222222);
    final secondaryTextColor = isDark ? const Color(0xFFA0A5B1) : const Color(0xFF666666);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Close X Button
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B303E) : const Color(0xFFF2F3F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: secondaryTextColor,
                  size: 18,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Center Icon Badge with Sparkles
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Translucent Glow Ring
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.red.withOpacity(0.12)
                      : const Color(0xFF00E676).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
              // Inner Solid Circle Badge
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: isError ? const Color(0xFFFF3D00) : const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isError ? Colors.red : const Color(0xFF00E676)).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isError ? Icons.close_rounded : Icons.check_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              // Sparkle Dots Accent
              if (!isError) ...[
                Positioned(
                  top: 4,
                  right: 8,
                  child: Icon(Icons.star_rounded, color: const Color(0xFFFFB300), size: 14),
                ),
                Positioned(
                  bottom: 8,
                  left: 6,
                  child: Icon(Icons.star_rounded, color: const Color(0xFFFF8A80), size: 10),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryTextColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          // Message Body
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),

          // Optional Info Tag Pill
          if (infoTag != null && infoTag!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262B37) : const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: isError ? Colors.redAccent : const Color(0xFF00E676),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    infoTag!,
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Full-width Main Orange Confirm Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                if (onConfirm != null) onConfirm!();
              },
              child: Text(
                buttonTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
