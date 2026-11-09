import 'package:flutter/material.dart';
import 'package:food_route/common_widget/auth_language_toggle.dart';
import 'package:food_route/view/login/login_view.dart';
import 'package:food_route/view/login/sing_up_view.dart';

import '../../common/color_extension.dart';
import '../../common_widget/round_button.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

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
                "Discover delicious food from over 1,000 restaurants along your route. Order ahead, pick up with ease, or reserve your table!",
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
                title: "Login",
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
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: RoundButton(
                title: "Create an Account",
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
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
