import 'package:flutter/material.dart';
import 'package:food_route/common/color_extension.dart';
import 'package:food_route/common/extension.dart';
import 'package:food_route/common/format_utils.dart';
import 'package:food_route/common_widget/auth_header_widget.dart';
import 'package:food_route/common_widget/auth_textfield.dart';
import 'package:food_route/view/login/otp_view.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final TextEditingController txtEmail = TextEditingController();

  @override
  void dispose() {
    txtEmail.dispose();
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
                    context.l10n.authForgotPassword,
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.authForgotPasswordSubtitle,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email Input Field
                  AuthTextfield(
                    label: context.l10n.authAccountOrEmail,
                    hintText: "foodroute@gmail.com",
                    controller: txtEmail,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
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
                          color: const Color(0xFFFF5216).withValues(alpha: 0.32),
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
                      child: Text(
                        context.l10n.authSendVerificationCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Back to Login Link
                  Center(
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 16,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              context.l10n.authBackTo,
                              style: TextStyle(
                                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              context.l10n.authLogin,
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
    final email = txtEmail.text.trim();
    if (!email.isEmail) {
      mdShowAlert(context.l10n.commonNotification, context.l10n.authEmailInvalid, () {}, isError: true);
      return;
    }

    endEditing();

    serviceCallForgotRequest({
      "email": email,
    });
  }

  void serviceCallForgotRequest(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(parameter, SVKey.svForgotPasswordRequest,
        withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        mdShowAlert(context.l10n.commonNotification, context.l10n.authResetCodeSentSuccess, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPView(email: txtEmail.text.trim()),
            ),
          );
        }, isError: false);
      } else {
        mdShowAlert(context.l10n.commonNotification, responseObj[KKey.message] as String? ?? context.l10n.authRequestFailed, () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert(context.l10n.commonNotification, err.toString(), () {}, isError: true);
    });
  }
}
