import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/extension.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:food_delivery/view/login/rest_password_view.dart';
import 'package:food_delivery/view/login/sing_up_view.dart';
import 'package:food_delivery/view/on_boarding/on_boarding_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../common/service_call.dart';
import '../../common_widget/google_login_button.dart';
import '../../common_widget/round_textfield.dart';
import '../../providers/language_provider.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '963558323583-t3295k9m03vpbrqjaimfp7d8o3gsaaqd.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              Text(
                lang.tr('login_title'),
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                lang.tr('login_subtitle'),
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: lang.tr('your_email'),
                controller: txtEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 25),
              RoundTextfield(
                hintText: lang.tr('password'),
                controller: txtPassword,
                obscureText: true,
              ),
              const SizedBox(height: 25),
              RoundButton(
                title: lang.tr('login'),
                onPressed: () {
                  btnLogin();
                },
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordView(),
                    ),
                  );
                },
                child: Text(
                  lang.tr('forgot_password'),
                  style: TextStyle(
                    color: TColor.secondaryTextOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                lang.tr('or_login_with'),
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              GoogleLoginButton(
                title: lang.tr('login_google'),
                onPressed: () {
                  btnGoogleLogin();
                },
              ),
              const SizedBox(height: 80),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpView(),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${lang.tr('dont_have_account')} ",
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      lang.tr('sign_up'),
                      style: TextStyle(
                        color: TColor.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void btnLogin() {
    if (!txtEmail.text.isEmail) {
      mdShowAlert(Globs.appName, MSG.enterEmail, () {});
      return;
    }

    if (txtPassword.text.length < 6) {
      mdShowAlert(Globs.appName, MSG.enterPassword, () {});
      return;
    }

    endEditing();
    serviceCallLogin({
      "email": txtEmail.text,
      "password": txtPassword.text,
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

      serviceCallGoogleAuth({
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
        Globs.appName,
        "Đăng nhập Google thất bại.\nVui lòng kiểm tra cấu hình OAuth Client ID.\nLỗi: ${e.toString()}",
        () {},
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
        Globs.udBoolSet(true, Globs.userLogin);

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
        Globs.udBoolSet(true, Globs.userLogin);

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
