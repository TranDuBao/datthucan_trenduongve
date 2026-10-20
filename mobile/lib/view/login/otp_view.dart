import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/extension.dart';
import 'package:food_delivery/common_widget/auth_header_widget.dart';
import 'package:food_delivery/view/login/new_password_view.dart';
import 'package:otp_pin_field/otp_pin_field.dart';

import '../../common/globs.dart';
import '../../common/service_call.dart';

class OTPView extends StatefulWidget {
  final String email;
  const OTPView({super.key, required this.email});

  @override
  State<OTPView> createState() => _OTPViewState();
}

class _OTPViewState extends State<OTPView> {
  final _otpPinFieldController = GlobalKey<OtpPinFieldState>();
  String code = "";

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
                    "Xác thực mã OTP",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Mã xác thực đã được gửi tới email ${widget.email}.\nVui lòng nhập mã gồm 6 chữ số bên dưới:",
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // OTP Pin Field
                  Center(
                    child: SizedBox(
                      height: 60,
                      child: OtpPinField(
                        key: _otpPinFieldController,
                        autoFillEnable: true,
                        textInputAction: TextInputAction.done,
                        onSubmit: (newCode) {
                          code = newCode;
                          btnSubmit();
                        },
                        onChange: (newCode) {
                          code = newCode;
                        },
                        onCodeChanged: (newCode) {
                          code = newCode;
                        },
                        fieldWidth: 44,
                        otpPinFieldStyle: OtpPinFieldStyle(
                          defaultFieldBorderColor: isDark ? const Color(0xFF2C3244) : const Color(0xFFE5E7EB),
                          activeFieldBorderColor: const Color(0xFFFF5216),
                          defaultFieldBackgroundColor: isDark ? const Color(0xFF1E2230) : const Color(0xFFF9FAFB),
                          activeFieldBackgroundColor: isDark ? const Color(0xFF1E2230) : const Color(0xFFF9FAFB),
                        ),
                        maxLength: 6,
                        showCursor: true,
                        cursorColor: const Color(0xFFFF5216),
                        showCustomKeyboard: false,
                        cursorWidth: 2,
                        mainAxisAlignment: MainAxisAlignment.center,
                        otpPinFieldDecoration: OtpPinFieldDecoration.defaultPinBoxDecoration,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

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
                        "Xác nhận mã",
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

                  // Resend Code Link
                  Center(
                    child: InkWell(
                      onTap: () {
                        serviceCallForgotRequest({"email": widget.email});
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Chưa nhận được mã? ",
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                text: "Gửi lại",
                                style: TextStyle(
                                  color: Color(0xFFFF5216),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void btnSubmit() {
    if (code.length != 6) {
      mdShowAlert("Thông báo", "Vui lòng nhập đủ 6 chữ số mã OTP", () {}, isError: true);
      return;
    }

    endEditing();

    serviceCallForgotVerify({"email": widget.email, "reset_code": code});
  }

  void serviceCallForgotVerify(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(parameter, SVKey.svForgotPasswordVerify,
        withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        var payloadObj = responseObj[KKey.payload] as Map? ?? {};
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewPasswordView(nObj: payloadObj),
          ),
        );
      } else {
        mdShowAlert("Thông báo", responseObj[KKey.message] as String? ?? "Mã xác thực không hợp lệ", () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert("Thông báo", err.toString(), () {}, isError: true);
    });
  }

  void serviceCallForgotRequest(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(parameter, SVKey.svForgotPasswordRequest,
        withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        mdShowAlert("Thông báo", "Đã gửi lại mã xác thực tới email của bạn", () {}, isError: false);
      } else {
        mdShowAlert("Thông báo", responseObj[KKey.message] as String? ?? "Gửi lại thất bại", () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert("Thông báo", err.toString(), () {}, isError: true);
    });
  }
}
