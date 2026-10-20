import 'package:flutter/material.dart';

import '../../common/color_extension.dart';
import '../../common_widget/custom_modal_alert.dart';
import '../../providers/language_provider.dart';

void showProfileSettingsSheet({
  required BuildContext context,
  required LanguageProvider lang,
  required bool isGoogleUser,
  required VoidCallback onChangePassword,
  required VoidCallback onOpenOrders,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF161920) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (bottomSheetContext) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C3242) : const Color(0xFFE2E4E9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: TColor.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.settings_outlined, color: TColor.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.languageCode == 'vi' ? "Cài đặt & Tùy chọn" : "Settings & Options",
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        lang.languageCode == 'vi'
                            ? "Quản lý mật khẩu và đơn hàng của bạn"
                            : "Manage your password and order history",
                        style: TextStyle(
                          color: TColor.secondaryTextOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: TColor.borderOf(context), height: 1),
            const SizedBox(height: 12),
            _buildSettingsOptionItem(
              context: context,
              icon: Icons.lock_reset_rounded,
              iconBg: isGoogleUser ? Colors.grey.withValues(alpha: 0.12) : const Color(0xFFFFF3E0),
              iconColor: isGoogleUser ? Colors.grey : const Color(0xFFFF6D00),
              title: lang.languageCode == 'vi' ? "Thay đổi mật khẩu" : "Change Password",
              subtitle: isGoogleUser
                  ? (lang.languageCode == 'vi'
                      ? "Đăng nhập Google (Không sử dụng mật khẩu app)"
                      : "Signed in via Google (Password managed by Google)")
                  : (lang.languageCode == 'vi'
                      ? "Cập nhật mật khẩu bảo mật tài khoản"
                      : "Update your account security password"),
              onTap: () {
                Navigator.pop(bottomSheetContext);
                if (isGoogleUser) {
                  CustomModalAlert.show(
                    context: context,
                    title: lang.languageCode == 'vi' ? "Tài khoản Google" : "Google Account",
                    message: lang.languageCode == 'vi'
                        ? "Tài khoản của bạn được liên kết và xác thực bảo mật bởi Google.\nBạn không cần quản lý hoặc thay đổi mật khẩu trên ứng dụng."
                        : "Your account is authenticated securely via Google OAuth.\nYou do not need to manage or change passwords on this app.",
                    infoTag: "Google OAuth 2.0",
                    buttonTitle: lang.languageCode == 'vi' ? "Đã hiểu" : "Got it",
                  );
                } else {
                  onChangePassword();
                }
              },
            ),
            const SizedBox(height: 10),
            _buildSettingsOptionItem(
              context: context,
              icon: Icons.receipt_long_rounded,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
              title: lang.languageCode == 'vi' ? "Lịch sử mua hàng" : "Order History",
              subtitle: lang.languageCode == 'vi'
                  ? "Xem danh sách và trạng thái các đơn hàng"
                  : "View your order history & details",
              onTap: () {
                Navigator.pop(bottomSheetContext);
                onOpenOrders();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

Widget _buildSettingsOptionItem({
  required BuildContext context,
  required IconData icon,
  required Color iconBg,
  required Color iconColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1E29) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2F3D) : const Color(0xFFEEF0F4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? iconColor.withValues(alpha: 0.18) : iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: TColor.secondaryTextOf(context).withValues(alpha: 0.6),
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
}
