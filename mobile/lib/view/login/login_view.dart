import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common_widget/auth_header_widget.dart';
import 'package:food_delivery/common_widget/auth_textfield.dart';
import 'package:food_delivery/view/login/rest_password_view.dart';
import 'package:food_delivery/view/login/sing_up_view.dart';
import 'package:food_delivery/view/on_boarding/on_boarding_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../common/service_call.dart';
import '../../common_widget/google_login_button.dart';
import '../../providers/language_provider.dart';
import '../../common/user_role_helper.dart';
import '../../providers/notification_provider.dart';
import '../restaurant_owner/restaurant_owner_main_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '963558323583-t3295k9m03vpbrqjaimfp7d8o3gsaaqd.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _rememberMe = Globs.udValueBool("remember_me_pref");
  }

  @override
  void dispose() {
    txtEmail.dispose();
    txtPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top curved orange header with Foodie branding & delivery driver
            const AuthHeaderWidget(),

            // Form Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Subtitle
                  Text(
                    "Chào mừng trở lại",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Đăng nhập để khám phá hàng ngàn quán ngon",
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Email/Account Field
                  AuthTextfield(
                    label: "Tài khoản hoặc Email",
                    hintText: "foodroute@gmail.com",
                    controller: txtEmail,
                    prefixIcon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  AuthTextfield(
                    label: "Mật khẩu",
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

                  // Remember me & Forgot password row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remember me Checkbox
                      InkWell(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                            Globs.udBoolSet(_rememberMe, "remember_me_pref");
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _rememberMe
                                    ? const Color(0xFFFF5216)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _rememberMe
                                      ? const Color(0xFFFF5216)
                                      : (isDark ? const Color(0xFF4B5563) : const Color(0xFFD1D5DB)),
                                  width: 1.5,
                                ),
                              ),
                              child: _rememberMe
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Ghi nhớ đăng nhập",
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFFD1D5DB)
                                    : const Color(0xFF4B5563),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Forgot password link
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ResetPasswordView(),
                            ),
                          );
                        },
                        child: const Text(
                          "Quên mật khẩu?",
                          style: TextStyle(
                            color: Color(0xFFFF5216),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button
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
                      onPressed: btnLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        "Đăng nhập",
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

                  // Or Login With Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF2C3244) : const Color(0xFFE5E7EB),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          "HOẶC ĐĂNG NHẬP VỚI",
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8E95A5) : const Color(0xFF9CA3AF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: isDark ? const Color(0xFF2C3244) : const Color(0xFFE5E7EB),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Social Buttons Row (Google & Apple)
                  Row(
                    children: [
                      // Google Button
                      Expanded(
                        child: InkWell(
                          onTap: btnGoogleLogin,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2230) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C3244) : const Color(0xFFE5E7EB),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const GoogleLogoWidget(size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Google",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Apple Button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            mdShowAlert(
                              "Thông báo",
                              "Đăng nhập với Apple đang được cập nhật và sẽ sẵn sàng trong phiên bản tới!",
                              () {},
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2230) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C3244) : const Color(0xFFE5E7EB),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.apple,
                                  size: 22,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Apple",
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Bottom Sign Up Link
                  Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpView(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Chưa có tài khoản? ",
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                text: "Đăng ký ngay",
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

  void btnLogin() {
    final accountStr = txtEmail.text.trim();
    final passStr = txtPassword.text.trim();

    if (accountStr.isEmpty || passStr.isEmpty) {
      mdShowAlert("Thông báo", "Vui lòng nhập đầy đủ tài khoản và mật khẩu", () {}, isError: true);
      return;
    }

    endEditing();
    serviceCallLogin({
      "email": accountStr,
      "password": passStr,
      "push_token": ""
    });
  }

  Future<void> btnGoogleLogin() async {
    endEditing();
    Globs.showHUD();
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();

      if (googleAccount == null) {
        Globs.hideHUD();
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleAccount.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        Globs.hideHUD();
        if (!mounted) return;
        mdShowAlert("Thông báo", "Không lấy được Google ID Token. Vui lòng thử lại!", () {}, isError: true);
        return;
      }

      serviceCallGoogleAuth({
        "idToken": idToken,
        "googleId": googleAccount.id,
        "email": googleAccount.email,
        "fullName": googleAccount.displayName ?? googleAccount.email.split('@')[0],
        "avatarUrl": googleAccount.photoUrl ?? "",
      });
    } catch (e) {
      Globs.hideHUD();
      debugPrint("Google Sign In error: $e");
      if (!mounted) return;
      mdShowAlert(
        "Thông báo",
        "Đăng nhập Google thất bại.\nVui lòng kiểm tra cấu hình OAuth Client ID.\nLỗi: ${e.toString()}",
        () {},
        isError: true,
      );
    }
  }

  void serviceCallLogin(Map<String, dynamic> parameter) {
    Globs.showHUD();
    ServiceCall.post(parameter, SVKey.svLogin,
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

        if (mounted) {
          context.read<NotificationProvider>().initialize();
        }

        final isStoreOwner = UserRoleHelper.isMerchant;

        mdShowAlert("Thông báo", "Đăng nhập thành công", () {
          if (isStoreOwner) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const RestaurantOwnerMainView(),
              ),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const OnBoardingView(),
              ),
              (route) => false,
            );
          }
        }, isError: false);
      } else {
        mdShowAlert("Thông báo", "Tài khoản hoặc mật khẩu chưa đúng", () {}, isError: true);
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert("Thông báo", "Tài khoản hoặc mật khẩu chưa đúng", () {}, isError: true);
    });
  }

  void serviceCallGoogleAuth(Map<String, dynamic> parameter) {
    ServiceCall.post(parameter, SVKey.svGoogleAuth,
        withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        var rawPayload = responseObj[KKey.payload] as Map? ?? {};
        var payload = Map<String, dynamic>.from(rawPayload);
        payload["isGoogle"] = true;
        payload["loginType"] = "google";
        ServiceCall.userPayload = payload;
        Globs.udSet(payload, Globs.userPayload);
        if (payload[KKey.authToken] != null || payload['accessToken'] != null) {
          Globs.udStringSet((payload['accessToken'] ?? payload[KKey.authToken]).toString(), KKey.authToken);
        }
        Globs.udBoolSet(true, Globs.userLogin);

        if (mounted) {
          context.read<NotificationProvider>().initialize();
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const OnBoardingView(),
          ),
          (route) => false,
        );
      } else {
        mdShowAlert(Globs.appName, responseObj[KKey.message] as String? ?? MSG.fail, () {});
      }
    }, failure: (err) async {
      Globs.hideHUD();
      mdShowAlert(Globs.appName, err.toString(), () {});
    });
  }
}
