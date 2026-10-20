import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class AuthTextfield extends StatelessWidget {
  final String? label;
  final String hintText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool isPassword;
  final bool obscureText;
  final VoidCallback? onTogglePassword;
  final String? Function(String?)? validator;

  const AuthTextfield({
    super.key,
    this.label,
    required this.hintText,
    this.controller,
    this.prefixIcon,
    this.keyboardType,
    this.isPassword = false,
    this.obscureText = false,
    this.onTogglePassword,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1F2937),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2230) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2C3244) : const Color(0xFFE5E7EB),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              if (prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  child: Icon(
                    prefixIcon,
                    color: isDark ? const Color(0xFF8E95A5) : const Color(0xFF9CA3AF),
                    size: 20,
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: isPassword ? obscureText : false,
                  keyboardType: keyboardType,
                  autocorrect: false,
                  style: TextStyle(
                    color: TColor.primaryTextOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: prefixIcon != null ? 6 : 16,
                      vertical: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (isPassword)
                InkWell(
                  onTap: onTogglePassword,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14, left: 6),
                    child: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: isDark ? const Color(0xFF8E95A5) : const Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
