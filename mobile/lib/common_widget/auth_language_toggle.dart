import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';

/// Nút chuyển đổi ngôn ngữ thu gọn (Compact Dropdown Selector)
/// Chỉ hiển thị duy nhất ngôn ngữ đang dùng ở góc trên bên phải (VD: 🇻🇳 VI ▾).
/// Khi bấm vào, xổ menu nhỏ gọn ngay sát dưới nút với hiệu ứng kính mờ tinh tế,
/// không chiếm diện tích thừa và giữ độ tương phản cao, rõ chữ/logo.
class AuthLanguageToggle extends StatelessWidget {
  final bool isDarkHeader;

  const AuthLanguageToggle({
    super.key,
    this.isDarkHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final isVi = langProvider.languageCode == 'vi';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerBg = isDarkHeader
        ? Colors.black.withValues(alpha: 0.20)
        : Colors.black.withValues(alpha: 0.06);

    final borderColor = isDarkHeader
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.12);

    final textColor = isDarkHeader
        ? Colors.white
        : const Color(0xFF1E293B);

    final chevronColor = isDarkHeader
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF64748B);

    // Nền hơi trong suốt (frosted glass 92%) đảm bảo tương phản cao, không mất chữ/logo
    final menuBg = isDark
        ? const Color(0xFF1E232E).withValues(alpha: 0.92)
        : Colors.white.withValues(alpha: 0.92);

    final menuBorder = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.60);

    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 4),
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(
        minWidth: 120,
        maxWidth: 132,
      ),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.16),
      color: menuBg,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: menuBorder, width: 1.2),
      ),
      onSelected: (String code) {
        if (code != langProvider.languageCode) {
          HapticFeedback.lightImpact();
          langProvider.setLanguage(code);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'vi',
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Text('🇻🇳', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tiếng Việt',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isVi ? FontWeight.w700 : FontWeight.w500,
                    color: isVi
                        ? const Color(0xFFFF4500)
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ),
              if (isVi)
                const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: Color(0xFFFF4500),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'en',
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Text('🇬🇧', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'English',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: !isVi ? FontWeight.w700 : FontWeight.w500,
                    color: !isVi
                        ? const Color(0xFFFF4500)
                        : (isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ),
              if (!isVi)
                const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: Color(0xFFFF4500),
                ),
            ],
          ),
        ),
      ],
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: isDarkHeader
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              isVi ? '🇻🇳' : '🇬🇧',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(width: 4),
            Text(
              isVi ? 'VI' : 'EN',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: chevronColor,
            ),
          ],
        ),
      ),
    );
  }
}
