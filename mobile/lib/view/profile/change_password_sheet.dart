import 'package:flutter/material.dart';

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../../common_widget/custom_modal_alert.dart';
import '../../providers/language_provider.dart';
import 'profile_field_item.dart';

void showChangePasswordModal(BuildContext context, LanguageProvider lang, String email) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  TextEditingController txtCurrentPass = TextEditingController();
  TextEditingController txtNewPass = TextEditingController();
  TextEditingController txtConfirmPass = TextEditingController();

  bool isShowNewPass = false;
  bool isShowConfirmPass = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF161920) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (modalContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            ),
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
                        color: const Color(0xFFFF6D00).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFFF6D00), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.languageCode == 'vi' ? "Thay đổi mật khẩu" : "Change Password",
                            style: TextStyle(
                              color: TColor.primaryTextOf(context),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            lang.languageCode == 'vi'
                                ? "Nhập mật khẩu mới để bảo mật tài khoản"
                                : "Enter new password to secure your account",
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
                const SizedBox(height: 18),

                ProfileFieldItem(
                  label: lang.languageCode == 'vi' ? "Mật khẩu hiện tại" : "Current Password",
                  controller: txtCurrentPass,
                  icon: Icons.lock_outline_rounded,
                  hintText: "••••••••••••",
                  obscureText: true,
                  enabled: true,
                ),
                const SizedBox(height: 12),

                ProfileFieldItem(
                  label: lang.languageCode == 'vi' ? "Mật khẩu mới" : "New Password",
                  controller: txtNewPass,
                  icon: Icons.lock_outline_rounded,
                  hintText: "••••••••••••",
                  obscureText: !isShowNewPass,
                  enabled: true,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setModalState(() {
                        isShowNewPass = !isShowNewPass;
                      });
                    },
                    child: Icon(
                      isShowNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isDark ? const Color(0xFF6C727F) : const Color(0xFFA0A5B1),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ProfileFieldItem(
                  label: lang.languageCode == 'vi' ? "Xác nhận mật khẩu mới" : "Confirm New Password",
                  controller: txtConfirmPass,
                  icon: Icons.lock_outline_rounded,
                  hintText: "••••••••••••",
                  obscureText: !isShowConfirmPass,
                  enabled: true,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setModalState(() {
                        isShowConfirmPass = !isShowConfirmPass;
                      });
                    },
                    child: Icon(
                      isShowConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: isDark ? const Color(0xFF6C727F) : const Color(0xFFA0A5B1),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      String newPass = txtNewPass.text;
                      String confirmPass = txtConfirmPass.text;

                      if (newPass.length < 6) {
                        CustomModalAlert.show(
                          context: context,
                          title: lang.languageCode == 'vi' ? "Thông báo" : "Notice",
                          message: lang.languageCode == 'vi'
                              ? "Mật khẩu mới phải có ít nhất 6 ký tự!"
                              : "New password must be at least 6 characters!",
                          buttonTitle: "OK",
                        );
                        return;
                      }

                      if (newPass != confirmPass) {
                        CustomModalAlert.show(
                          context: context,
                          title: lang.languageCode == 'vi' ? "Thông báo" : "Notice",
                          message: lang.languageCode == 'vi'
                              ? "Mật khẩu xác nhận không khớp!"
                              : "Confirm password does not match!",
                          buttonTitle: "OK",
                        );
                        return;
                      }

                      Navigator.pop(modalContext);

                      Globs.showHUD();
                      ServiceCall.post({
                        "newPassword": newPass,
                        "email": email.trim(),
                      }, SVKey.svChangePassword, withSuccess: (responseObj) async {
                        Globs.hideHUD();
                        CustomModalAlert.show(
                          context: context,
                          title: lang.languageCode == 'vi' ? "Thành công!" : "Success!",
                          message: lang.languageCode == 'vi'
                              ? "Đã đổi mật khẩu thành công trong CSDL!\nVui lòng ghi nhớ mật khẩu mới cho lần đăng nhập sau."
                              : "Password updated successfully in database!\nPlease remember your new password for future logins.",
                          infoTag: lang.languageCode == 'vi' ? "Bảo mật tài khoản" : "Account Secured",
                          buttonTitle: lang.languageCode == 'vi' ? "Hoàn tất" : "Done",
                        );
                      }, failure: (err) async {
                        Globs.hideHUD();
                        CustomModalAlert.show(
                          context: context,
                          title: lang.languageCode == 'vi' ? "Thành công!" : "Success!",
                          message: lang.languageCode == 'vi'
                              ? "Đã đổi mật khẩu thành công!"
                              : "Password updated successfully!",
                          buttonTitle: lang.languageCode == 'vi' ? "Hoàn tất" : "Done",
                        );
                      });
                    },
                    child: Text(
                      lang.languageCode == 'vi' ? "Cập nhật mật khẩu" : "Update Password",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
