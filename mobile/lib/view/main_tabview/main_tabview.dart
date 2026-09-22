import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/tab_button.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../home/home_view.dart';
import '../menu/menu_view.dart';
import '../more/more_view.dart';
import '../offer/offer_view.dart';
import '../profile/profile_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selctTab = 2;
  PageStorageBucket storageBucket = PageStorageBucket();
  Widget selectPageView = const HomeView();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PageStorage(bucket: storageBucket, child: selectPageView),
      backgroundColor: TColor.bgOf(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: selctTab == 2
                  ? TColor.primary.withOpacity(0.35)
                  : Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            if (selctTab != 2) {
              selctTab = 2;
              selectPageView = const HomeView();
            }
            if (mounted) {
              setState(() {});
            }
          },
          shape: CircleBorder(
            side: BorderSide(
              color: selctTab == 2
                  ? TColor.primary
                  : (isDark ? const Color(0xFF2C3240) : const Color(0xFFE0E0E0)),
              width: 2,
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF1B1E28) : Colors.white,
          child: Image.asset(
            "assets/img/tab_home.png",
            width: 26,
            height: 26,
            color: selctTab == 2
                ? TColor.primary
                : (isDark ? Colors.white70 : TColor.placeholder),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: TColor.navBgOf(context),
        surfaceTintColor: TColor.navBgOf(context),
        shadowColor: Colors.black,
        elevation: 8,
        notchMargin: 8,
        height: 68,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            TabButton(
              title: lang.tr('menu'),
              icon: "assets/img/tab_menu.png",
              onTap: () {
                if (selctTab != 0) {
                  selctTab = 0;
                  selectPageView = const MenuView();
                }
                if (mounted) {
                  setState(() {});
                }
              },
              isSelected: selctTab == 0,
            ),
            TabButton(
              title: lang.tr('offer'),
              icon: "assets/img/tab_offer.png",
              onTap: () {
                if (selctTab != 1) {
                  selctTab = 1;
                  selectPageView = const OfferView();
                }
                if (mounted) {
                  setState(() {});
                }
              },
              isSelected: selctTab == 1,
            ),
            const SizedBox(width: 40, height: 40),
            TabButton(
              title: lang.tr('profile'),
              icon: "assets/img/tab_profile.png",
              onTap: () {
                if (selctTab != 3) {
                  selctTab = 3;
                  selectPageView = const ProfileView();
                }
                if (mounted) {
                  setState(() {});
                }
              },
              isSelected: selctTab == 3,
            ),
            TabButton(
              title: lang.tr('more'),
              icon: "assets/img/tab_more.png",
              onTap: () {
                if (selctTab != 4) {
                  selctTab = 4;
                  selectPageView = const MoreView();
                }
                if (mounted) {
                  setState(() {});
                }
              },
              isSelected: selctTab == 4,
            ),
          ],
        ),
      ),
    );
  }
}
