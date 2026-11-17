import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:food_route/common/color_extension.dart';
import 'package:food_route/common/extension.dart';
import 'package:food_route/common/format_utils.dart';
import 'package:food_route/common_widget/auth_header_widget.dart';
import 'package:food_route/view/login/new_password_view.dart';
import 'package:otp_pin_field/otp_pin_field.dart';

import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../../providers/cart_provider.dart';
import '../../providers/map_provider.dart';
import '../../providers/notification_provider.dart';
import '../on_boarding/on_boarding_view.dart';

class OTPView extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? signUpData;
  final String? fallbackOtp;
  const OTPView({super.key, required this.email, this.signUpData, this.fallbackOtp});

  @override
  State<OTPView> createState() => _OTPViewState();
}

class _OTPViewState extends State<OTPView> {
  final _otpPinFieldController = GlobalKey<OtpPinFieldState>();
  String code = "";
  late String? _currentFallbackOtp;

  @override
  void initState() {
    super.initState();
    _currentFallbackOtp = widget.fallbackOtp;
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
                    context.l10n.authOtpTitle,
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.authOtpSubtitle(widget.email),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_currentFallbackOtp != null && _currentFallbackOtp!.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD8A8)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Mã OTP (Cloud Free): $_currentFallbackOtp",
                              style: const TextStyle(
                                color: Color(0xFFC2410C),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                        context.l10n.authOtpConfirm,
                        style: const TextStyle(
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
                        if (widget.signUpData != null) {
                          serviceCallSignUpRequestOtp({
                            "email": widget.email,
                            "name": widget.signUpData!["name"] ?? "",
                          });
                        } else {
                          serviceCallForgotRequest({"email": widget.email});
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: context.l10n.authOtpDidNotReceive,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: context.l10n.authOtpResend,
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
      mdShowAlert(context.l10n.commonNotification, context.l10n.authOtpInput6Digits, () {}, isError: true);
      return;
    }

    endEditing();

    if (widget.signUpData != null) {
      serviceCallSignUpVerify(code);
    } else {
      serviceCallForgotVerify({"email": widget.email, "reset_code": code});
    }
  }

  void serviceCallSignUpVerify(String otpCode) {
    Globs.showHUD();
    final parameter = Map<String, dynamic>.from(widget.signUpData!);
    parameter["otp"] = otpCode;

    ServiceCall.post(parameter, SVKey.svSignUp, withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        var payload = responseObj[KKey.payload] as Map? ?? {};
        ServiceCall.userPayload = payload;
        Globs.udSet(payload, Globs.userPayload);
        if (payload[KKey.authToken] != null || payload['accessToken'] != null) {
          Globs.udStringSet((payload['accessToken'] ?? payload[KKey.authToken]).toString(), KKey.authToken);
        }
        Globs.udBoolSet(true, Globs.userLogin);
        Globs.udBoolSet(false, Globs.isGuestMode);

        if (context.mounted) {
          context.read<MapProvider>().clearAll();
          context.read<CartProvider>().clearCart();
          context.read<NotificationProvider>().clearAllData();
          context.read<NotificationProvider>().initialize();
        }

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
        mdShowAlert(context.l10n.commonNotification, msg.isNotEmpty ? msg : context.l10n.commonError, () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert(context.l10n.commonNotification, err.toString(), () {}, isError: true);
    });
  }

  void serviceCallSignUpRequestOtp(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(parameter, SVKey.svSignUpRequestOtp, withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        final payload = responseObj[KKey.payload] as Map? ?? {};
        final serverOtp = (payload["otp"] ?? responseObj["data"]?["otp"])?.toString() ?? "";
        if (serverOtp.isNotEmpty) {
          setState(() {
            _currentFallbackOtp = serverOtp;
          });
          mdShowAlert(
            context.l10n.commonNotification,
            "Mã OTP mới của bạn là: $serverOtp\n(Do máy chủ Cloud Free chặn gửi email)",
            () {},
            isError: false,
          );
        } else {
          mdShowAlert(context.l10n.commonNotification, context.l10n.authOtpResentSuccess, () {}, isError: false);
        }
      } else {
        String msg = (responseObj[KKey.message] as String?)?.trim() ?? '';
        mdShowAlert(context.l10n.commonNotification, msg.isNotEmpty ? msg : context.l10n.commonError, () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert(context.l10n.commonNotification, err.toString(), () {}, isError: true);
    });
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
        mdShowAlert(context.l10n.commonNotification, responseObj[KKey.message] as String? ?? context.l10n.commonError, () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert(context.l10n.commonNotification, err.toString(), () {}, isError: true);
    });
  }

  void serviceCallForgotRequest(Map<String, dynamic> parameter) {
    Globs.showHUD();

    ServiceCall.post(parameter, SVKey.svForgotPasswordRequest,
        withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        mdShowAlert(context.l10n.commonNotification, context.l10n.authOtpResentSuccess, () {}, isError: false);
      } else {
        mdShowAlert(context.l10n.commonNotification, responseObj[KKey.message] as String? ?? context.l10n.commonError, () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert(context.l10n.commonNotification, err.toString(), () {}, isError: true);
    });
  }
}
