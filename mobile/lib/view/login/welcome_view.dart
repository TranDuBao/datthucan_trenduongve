import 'package:flutter/material.dart';
import 'package:food_route/common_widget/auth_language_toggle.dart';
import 'package:food_route/view/login/login_view.dart';
import 'package:food_route/view/login/sing_up_view.dart';
import 'package:food_route/view/main_tabview/main_tabview.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../../common_widget/round_button.dart';
import '../../providers/language_provider.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final isEn = context.watch<LanguageProvider>().isEn;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Image.asset(
                  "assets/img/welcome_top_shape.png",
                  width: media.width,
                ),
                Image.asset(
                  "assets/img/app_logo.png",
                  width: media.width * 0.55,
                  height: media.width * 0.55,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 16,
                  child: const AuthLanguageToggle(isDarkHeader: true),
                ),
              ],
            ),
            SizedBox(
              height: media.width * 0.08,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                isEn
                    ? "Discover delicious food from over 1,000 restaurants along your route. Order ahead, pick up with ease, or reserve your table!"
                    : "Khám phá món ngon từ hơn 1.000 nhà hàng tiện đường. Đặt trước, ghé lấy dễ dàng hoặc đặt bàn nhanh chóng!",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: TColor.secondaryText,
                    fontSize: 12,
                    height: 1.45,
                    fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(
              height: media.width * 0.08,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: RoundButton(
                title: isEn ? "Login" : "Đăng nhập",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: RoundButton(
                title: isEn ? "Create an Account" : "Tạo tài khoản",
                type: RoundButtonType.textPrimary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: RoundButton(
                title: isEn ? "Guest" : "Khách",
                type: RoundButtonType.textPrimary,
                onPressed: () {
                  Globs.udBoolSet(true, Globs.isGuestMode);
                  Globs.udBoolSet(false, Globs.userLogin);
                  ServiceCall.userPayload = {};
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainTabView(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}
