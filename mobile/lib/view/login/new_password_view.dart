import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/extension.dart';
import 'package:food_delivery/common_widget/auth_header_widget.dart';
import 'package:food_delivery/common_widget/auth_textfield.dart';
import 'package:food_delivery/view/login/login_view.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class NewPasswordView extends StatefulWidget {
  final Map nObj;
  const NewPasswordView({super.key, required this.nObj});

  @override
  State<NewPasswordView> createState() => _NewPasswordViewState();
}

class _NewPasswordViewState extends State<NewPasswordView> {
  final TextEditingController txtPassword = TextEditingController();
  final TextEditingController txtConfirmPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    txtPassword.dispose();
    txtConfirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top curved orange header
            AuthHeaderWidget(
              showBackButton: true,
              onBack: () => Navigator.pop(context),
            ),

            // Form Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mật khẩu mới",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Vui lòng nhập mật khẩu mới cho tài khoản của bạn",
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // New Password
                  AuthTextfield(
                    label: "Mật khẩu mới",
                    hintText: "••••••••••••",
                    controller: txtPassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onTogglePassword: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  AuthTextfield(
                    label: "Xác nhận mật khẩu mới",
                    hintText: "••••••••••••",
                    controller: txtConfirmPassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    onTogglePassword: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4800), Color(0xFFFF5F15)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5216).withOpacity(0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: btnSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Đổi mật khẩu",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void btnSubmit() {
    if (txtPassword.text.length < 6) {
      mdShowAlert("Thông báo", "Mật khẩu mới phải có ít nhất 6 ký tự", () {}, isError: true);
      return;
    }

    if (txtPassword.text != txtConfirmPassword.text) {
      mdShowAlert("Thông báo", "Mật khẩu xác nhận không khớp", () {}, isError: true);
      return;
    }

    endEditing();

    serviceCallForgotSetNew({
      "user_id": widget.nObj[KKey.userId].toString(),
      "reset_code": widget.nObj[KKey.resetCode].toString(),
      "new_password": txtPassword.text
    });
  }

  void serviceCallForgotSetNew(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(parameter, SVKey.svForgotPasswordSetNew,
        withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        mdShowAlert("Thông báo", "Đổi mật khẩu thành công! Vui lòng đăng nhập lại.", () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
            (route) => false,
          );
        }, isError: false);
      } else {
        mdShowAlert("Thông báo", responseObj[KKey.message] as String? ?? "Đổi mật khẩu thất bại", () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert("Thông báo", err.toString(), () {}, isError: true);
    });
  }
}
