import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../common/color_extension.dart';
import '../common/user_role_helper.dart';
import '../providers/language_provider.dart';
import '../view/login/login_view.dart';

class GuestLoginDialog extends StatelessWidget {
  final String? featureName;
  final String? customMessage;

  const GuestLoginDialog({
    super.key,
    this.featureName,
    this.customMessage,
  });

  /// Returns true if the user is a guest (and triggers the login prompt dialog),
  /// or false if the user is already authenticated.
  static bool checkGuestAndPrompt(
    BuildContext context, {
    String? featureName,
    String? customMessage,
  }) {
    if (UserRoleHelper.isGuest) {
      show(context, featureName: featureName, customMessage: customMessage);
      return true;
    }
    return false;
  }

  /// Displays the guest login prompt modal/dialog
  static Future<void> show(
    BuildContext context, {
    String? featureName,
    String? customMessage,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => GuestLoginDialog(
        featureName: featureName,
        customMessage: customMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LanguageProvider>().isEn;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = isEn ? "Login Required" : "Yêu Cầu Đăng Nhập";

    String message = customMessage ??
        (featureName != null
            ? (isEn
                ? "Please log in to use $featureName and enjoy the complete Food Route experience."
                : "Vui lòng đăng nhập để sử dụng tính năng $featureName và trải nghiệm trọn vẹn dịch vụ của Food Route.")
            : (isEn
                ? "You are currently browsing as a Guest. Please log in to your account to continue."
                : "Bạn đang trải nghiệm ứng dụng với tư cách Khách. Vui lòng đăng nhập để tiếp tục."));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E212B) : Colors.white,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon lock/user banner
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: Color(0xFFFC6011),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 10),

            // Message
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: isDark ? Colors.white70 : const Color(0xFF636366),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                // Cancel / Later button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF383C4A) : const Color(0xFFE5E5EA),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      isEn ? "Later" : "Để sau",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white60 : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Login button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(builder: (_) => const LoginView()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isEn ? "Login" : "Đăng nhập",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

