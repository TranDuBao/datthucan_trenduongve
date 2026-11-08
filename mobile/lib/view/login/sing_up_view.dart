import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_route/common/color_extension.dart';
import 'package:food_route/common/extension.dart';
import 'package:food_route/common_widget/auth_header_widget.dart';
import 'package:food_route/common_widget/auth_textfield.dart';
import 'package:food_route/view/login/login_view.dart';

import '../../common/format_utils.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../on_boarding/on_boarding_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController txtName = TextEditingController();
  final TextEditingController txtMobile = TextEditingController();
  final TextEditingController txtAddress = TextEditingController();
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  final TextEditingController txtConfirmPassword = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;

  @override
  void dispose() {
    txtName.dispose();
    txtMobile.dispose();
    txtAddress.dispose();
    txtEmail.dispose();
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
            // Top curved orange header with Foodie branding & delivery driver
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
                  // Title & Subtitle
                  Text(
                    context.l10n.authSignUpTitle,
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.authSignUpSubtitle,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Full Name
                  AuthTextfield(
                    label: context.l10n.authFullName,
                    hintText: "Nguyễn Văn A",
                    controller: txtName,
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),

                  // Email
                  AuthTextfield(
                    label: context.l10n.authYourEmail,
                    hintText: "foodroute@gmail.com",
                    controller: txtEmail,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // Mobile Phone
                  AuthTextfield(
                    label: context.l10n.authPhone,
                    hintText: "0912345678",
                    controller: txtMobile,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  // Address
                  AuthTextfield(
                    label: context.l10n.authAddress,
                    hintText: "Số nhà, tên đường, quận/huyện...",
                    controller: txtAddress,
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),

                  // Password
                  AuthTextfield(
                    label: context.l10n.authPassword,
                    hintText: "••••••••••••",
                    controller: txtPassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onTogglePassword: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Confirm Password
                  AuthTextfield(
                    label: context.l10n.authConfirmPassword,
                    hintText: "••••••••••••",
                    controller: txtConfirmPassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    obscureText: _obscureConfirmPassword,
                    onTogglePassword: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Terms & Conditions Checkbox
                  InkWell(
                    onTap: () {
                      setState(() => _agreeTerms = !_agreeTerms);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _agreeTerms
                                ? const Color(0xFFFF5216)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _agreeTerms
                                  ? const Color(0xFFFF5216)
                                  : (isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                              width: 1.5,
                            ),
                          ),
                          child: _agreeTerms
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.authAgreeTerms,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
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
                          color: const Color(0xFFFF5216).withValues(alpha: 0.32),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: btnSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        context.l10n.authSignUp,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Bottom Already have account link
                  Center(
                    child: InkWell(
                      onTap: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginView()),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: context.l10n.authAlreadyHaveAccount,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: context.l10n.authLoginNow,
                                style: const TextStyle(
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void btnSignUp() {
    if (txtName.text.trim().isEmpty) {
      mdShowAlert(context.l10n.commonNotification, context.l10n.authNameRequired, () {}, isError: true);
      return;
    }

    if (!txtEmail.text.trim().isEmail) {
      mdShowAlert(context.l10n.commonNotification, context.l10n.authEmailInvalid, () {}, isError: true);
      return;
    }

    if (txtMobile.text.trim().isEmpty) {
      mdShowAlert(context.l10n.commonNotification, context.l10n.authPhoneRequired, () {}, isError: true);
      return;
    }

    if (txtAddress.text.trim().isEmpty) {
      mdShowAlert(context.l10n.commonNotification, context.l10n.authAddressRequired, () {}, isError: true);
      return;
    }

    if (txtPassword.text.length < 6) {
      mdShowAlert(context.l10n.commonNotification, context.l10n.authPasswordMinLength, () {}, isError: true);
      return;
    }

    if (txtPassword.text != txtConfirmPassword.text) {
      mdShowAlert(context.l10n.commonNotification, context.l10n.authPasswordMismatch, () {}, isError: true);
      return;
    }

    if (!_agreeTerms) {
      mdShowAlert(context.l10n.commonNotification, context.l10n.authAgreeTermsRequired, () {}, isError: true);
      return;
    }

    endEditing();

    serviceCallSignUp({
      "name": txtName.text.trim(),
      "mobile": txtMobile.text.trim(),
      "email": txtEmail.text.trim(),
      "address": txtAddress.text.trim(),
      "password": txtPassword.text,
      "push_token": "",
      "device_type": Platform.isAndroid ? "A" : "I"
    });
  }

  void serviceCallSignUp(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(parameter, SVKey.svSignUp,
        withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        var payload = responseObj[KKey.payload] as Map? ?? {};
        ServiceCall.userPayload = payload;
        Globs.udSet(payload, Globs.userPayload);
        if (payload[KKey.authToken] != null || payload['accessToken'] != null) {
          Globs.udStringSet((payload['accessToken'] ?? payload[KKey.authToken]).toString(), KKey.authToken);
        }
        Globs.udBoolSet(true, Globs.userLogin);

        mdShowAlert(context.l10n.commonNotification, context.l10n.authSignUpSuccess, () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const OnBoardingView(),
            ),
            (route) => false,
          );
        }, isError: false);
      } else {
        String msg = (responseObj[KKey.message] as String?)?.trim() ?? '';
        final lower = msg.toLowerCase();
        if (msg.isEmpty ||
            lower.contains('null value') ||
            lower.contains('violates') ||
            lower.contains('constraint') ||
            lower.contains('relation') ||
            lower.contains('column') ||
            lower.contains('syntax') ||
            lower.contains('database') ||
            lower.contains('typeorm') ||
            lower.contains('postgres') ||
            lower.contains('query') ||
            lower.contains('table') ||
            lower.contains('error')) {
          msg = "Hệ thống đang gặp lỗi, vui lòng thử lại";
        }
        mdShowAlert(context.l10n.commonNotification, msg, () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      String msg = err.toString();
      final lower = msg.toLowerCase();
      if (lower.contains('null value') ||
          lower.contains('violates') ||
          lower.contains('constraint') ||
          lower.contains('relation') ||
          lower.contains('column') ||
          lower.contains('socketexception') ||
          lower.contains('connection refused') ||
          lower.contains('handshake') ||
          lower.contains('clientexception') ||
          lower.contains('exception') ||
          lower.contains('error')) {
        msg = "Hệ thống đang gặp lỗi, vui lòng thử lại";
      }
      mdShowAlert(context.l10n.commonNotification, msg, () {}, isError: true);
    });
  }
}
