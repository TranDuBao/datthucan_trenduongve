import 'package:flutter/material.dart';

import '../../common/color_extension.dart';

class ProfileFieldItem extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String? hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final bool enabled;

  const ProfileFieldItem({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.hintText,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF9096A5) : const Color(0xFF8C93A3);
    final disabledBg = isDark ? const Color(0xFF13161F) : const Color(0xFFF7F8FA);
    final enabledBg = isDark ? const Color(0xFF1A1F30) : const Color(0xFFFFFFFF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: enabled ? enabledBg : disabledBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? TColor.primary.withOpacity(0.5)
                  : (isDark ? const Color(0xFF232836) : const Color(0xFFEBECEF)),
              width: enabled ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled
                    ? TColor.primary
                    : (isDark ? const Color(0xFF6C727F) : const Color(0xFFA0A5B1)),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  enabled: enabled,
                  style: TextStyle(
                    color: TColor.primaryTextOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: TColor.secondaryTextOf(context).withOpacity(0.4),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (suffixIcon != null) suffixIcon!,
            ],
          ),
        ),
      ],
    );
  }
}
