import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/tab_button.dart';
import 'package:provider/provider.dart';

import '../../common/user_role_helper.dart';
import '../../providers/language_provider.dart';
import '../home/home_view.dart';
import '../menu/menu_view.dart';
import '../more/more_view.dart';
import '../offer/offer_view.dart';
import '../profile/profile_view.dart';
import '../restaurant_owner/restaurant_owner_main_view.dart';
import '../../providers/notification_provider.dart';

class MainTabView extends StatefulWidget {
  final int initialTab;
  const MainTabView({super.key, this.initialTab = 2});

  @override
  State<MainTabView> createState() => MainTabViewState();
}

class MainTabViewState extends State<MainTabView> {
  late int selctTab;

  // 5 dedicated navigators for the 5 tabs
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // 0: MenuView (Thực đơn)
    GlobalKey<NavigatorState>(), // 1: OfferView (Cửa hàng / Nhà hàng)
    GlobalKey<NavigatorState>(), // 2: HomeView (Home / Bản đồ)
    GlobalKey<NavigatorState>(), // 3: ProfileView (Hồ sơ)
    GlobalKey<NavigatorState>(), // 4: MoreView (Khác)
  ];

  @override
  void initState() {
    super.initState();
    selctTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().initialize();
      }
    });
  }

  Widget _getPageView(int tab) {
    switch (tab) {
      case 0:
        return const MenuView();
      case 1:
        return const OfferView();
      case 2:
        return const HomeView();
      case 3:
        return const ProfileView();
      case 4:
        return const MoreView();
      default:
        return const HomeView();
    }
  }

  Widget _buildTabNavigator(int tab) {
    return Navigator(
      key: _navigatorKeys[tab],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => _getPageView(tab),
        );
      },
    );
  }

  void changeTab(int tab, {bool popToRoot = true}) {
    if (mounted) {
      // Pop the tab we are leaving back to its root so it doesn't get stuck on a sub-screen
      if (selctTab >= 0 && selctTab < _navigatorKeys.length && selctTab != tab) {
        _navigatorKeys[selctTab].currentState?.popUntil((route) => route.isFirst);
      }
      setState(() {
        selctTab = tab;
      });
      if (popToRoot && tab >= 0 && tab < _navigatorKeys.length) {
        _navigatorKeys[tab].currentState?.popUntil((route) => route.isFirst);
      }
    }
  }

  void _onTabTapped(int tab) {
    if (selctTab == tab) {
      // Tap on the current active tab: pop back to root of this tab
      _navigatorKeys[tab].currentState?.popUntil((route) => route.isFirst);
    } else {
      // Pop the active tab before switching so it resets to root
      if (selctTab >= 0 && selctTab < _navigatorKeys.length) {
        _navigatorKeys[selctTab].currentState?.popUntil((route) => route.isFirst);
      }
      changeTab(tab, popToRoot: true);
    }
  }

  Future<T?> pushToTab<T>(int tab, Widget page) {
    changeTab(tab, popToRoot: false);
    return _navigatorKeys[tab].currentState!.push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  Future<T?> pushToCurrentTab<T>(Widget page) {
    return _navigatorKeys[selctTab].currentState!.push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMerchant = UserRoleHelper.isMerchant;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final currentNav = _navigatorKeys[selctTab].currentState;
        if (currentNav != null && currentNav.canPop()) {
          currentNav.pop();
        } else if (selctTab != 2) {
          // If on a tab other than Home, switch back to Home tab
          changeTab(2);
        } else {
          // Already at root of Home tab: minimize/exit app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: TColor.bgOf(context),
        body: isMerchant
            ? Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFC6011), Color(0xFFFF7A38)],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Chế độ Khách Hàng (Tài khoản Cửa Hàng)",
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const RestaurantOwnerMainView()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.store_rounded, color: Color(0xFFFC6011), size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    "Về Cửa Hàng",
                                    style: TextStyle(color: Color(0xFFFC6011), fontSize: 11, fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: selctTab,
                      children: List.generate(5, (index) => _buildTabNavigator(index)),
                    ),
                  ),
                ],
              )
            : IndexedStack(
                index: selctTab,
                children: List.generate(5, (index) => _buildTabNavigator(index)),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
        floatingActionButton: isKeyboardOpen
            ? null
            : Container(
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
                  onPressed: () => _onTabTapped(2),
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
        bottomNavigationBar: isKeyboardOpen
            ? null
            : BottomAppBar(
                color: TColor.navBgOf(context),
                surfaceTintColor: TColor.navBgOf(context),
                shadowColor: Colors.black,
                elevation: 8,
                notchMargin: 8,
                height: 68,
                padding: EdgeInsets.zero,
                shape: const CircularNotchedRectangle(),
                child: Row(
                  children: [
                    Expanded(
                      child: TabButton(
                        title: lang.tr('menu'),
                        icon: "assets/img/tab_menu.png",
                        onTap: () => _onTabTapped(0),
                        isSelected: selctTab == 0,
                      ),
                    ),
                    Expanded(
                      child: TabButton(
                        title: lang.tr('offer'),
                        iconData: Icons.storefront_rounded,
                        onTap: () => _onTabTapped(1),
                        isSelected: selctTab == 1,
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      child: TabButton(
                        title: lang.tr('profile'),
                        icon: "assets/img/tab_profile.png",
                        onTap: () => _onTabTapped(3),
                        isSelected: selctTab == 3,
                      ),
                    ),
                    Expanded(
                      child: TabButton(
                        title: lang.tr('more'),
                        icon: "assets/img/tab_more.png",
                        onTap: () => _onTabTapped(4),
                        isSelected: selctTab == 4,
                        badgeCount: context.watch<NotificationProvider>().unreadCount,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
