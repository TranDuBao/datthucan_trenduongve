import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import '../../common/service_call.dart';
import '../../common_widget/custom_selection_sheet.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/cart_provider.dart';
import '../../common/user_role_helper.dart';
import '../../services/order_service.dart';
import '../restaurant_owner/restaurant_owner_main_view.dart';
import 'about_us_view.dart';
import 'inbox_view.dart';
import 'my_order_view.dart';
import 'order_history_view.dart';
import 'notification_view.dart';
import 'payment_details_view.dart';
import '../../widgets/notification_bell.dart';
import '../../providers/notification_provider.dart';

class MoreView extends StatefulWidget {
  const MoreView({super.key});

  @override
  State<MoreView> createState() => _MoreViewState();
}

class _MoreViewState extends State<MoreView> {
  int _activeOrdersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchActiveOrdersCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().refreshAll();
      }
    });
  }

  Future<void> _fetchActiveOrdersCount() async {
    final list = await OrderService.fetchMyOrders();
    if (mounted) {
      setState(() {
        // Only count orders that are still active (not completed or cancelled)
        _activeOrdersCount = list.where((o) {
          final s = o.status.toUpperCase();
          return s != 'HOAN_TAT' && s != 'DA_HUY' && s != 'COMPLETED' && s != 'CANCELLED';
        }).length;
      });
    }
  }
  void _showLanguageBottomSheet(BuildContext context) {
    final langProvider = context.read<LanguageProvider>();

    CustomSelectionSheet.show<String>(
      context: context,
      title: langProvider.tr('select_language'),
      subtitle: langProvider.languageCode == 'vi'
          ? "Lựa chọn ngôn ngữ hiển thị chính"
          : "Select your primary display language",
      confirmText: langProvider.tr('confirm'),
      initialValue: langProvider.languageCode,
      onConfirm: (val) {
        langProvider.setLanguage(val);
      },
      options: [
        SelectionOptionItem<String>(
          value: 'vi',
          title: langProvider.tr('vietnamese'),
          subtitle: langProvider.languageCode == 'vi' ? "Mặc định hệ thống" : "System default",
          iconWidget: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDA251D),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFFFFCD00), size: 22),
          ),
        ),
        SelectionOptionItem<String>(
          value: 'en',
          title: langProvider.tr('english'),
          subtitle: langProvider.languageCode == 'vi' ? "Ngôn ngữ quốc tế" : "Global language",
          iconWidget: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF1B365D),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              "EN",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  void _showThemeBottomSheet(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final langProvider = context.read<LanguageProvider>();

    CustomSelectionSheet.show<ThemeMode>(
      context: context,
      title: langProvider.tr('select_theme'),
      subtitle: langProvider.languageCode == 'vi'
          ? "Lựa chọn chế độ giao diện cho ứng dụng"
          : "Choose app appearance theme mode",
      confirmText: langProvider.tr('confirm'),
      initialValue: themeProvider.themeMode,
      onConfirm: (val) {
        themeProvider.setThemeMode(val);
      },
      options: [
        SelectionOptionItem<ThemeMode>(
          value: ThemeMode.light,
          title: langProvider.tr('light_mode'),
          subtitle: langProvider.languageCode == 'vi' ? "Giao diện sáng rực rỡ" : "Bright & vibrant interface",
          iconWidget: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFFFB300),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 20),
          ),
        ),
        SelectionOptionItem<ThemeMode>(
          value: ThemeMode.dark,
          title: langProvider.tr('dark_mode'),
          subtitle: langProvider.languageCode == 'vi' ? "Tối màu diệu mắt, tiết kiệm pin" : "Easy on eyes, saves battery",
          iconWidget: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF3F51B5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nightlight_round, color: Colors.white, size: 20),
          ),
        ),
        SelectionOptionItem<ThemeMode>(
          value: ThemeMode.system,
          title: langProvider.tr('system_mode'),
          subtitle: langProvider.languageCode == 'vi' ? "Tự động đồng bộ cài đặt máy" : "Sync with OS system settings",
          iconWidget: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF607D8B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final theme = context.watch<ThemeProvider>();
    final notifCount = context.watch<NotificationProvider>().unreadCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String currentThemeLabel = lang.tr('system_mode');
    if (theme.themeMode == ThemeMode.light) currentThemeLabel = lang.tr('light_mode');
    if (theme.themeMode == ThemeMode.dark) currentThemeLabel = "${lang.tr('dark_mode')} •";

    List moreArr = [
      {
        "index": "lang",
        "name": lang.tr('language'),
        "subtitle": lang.tr(lang.languageCode == 'vi' ? 'vietnamese' : 'english'),
        "icon": Icons.language_rounded,
        "iconBg": const Color(0xFF3D271D),
        "iconColor": TColor.primary,
      },
      {
        "index": "theme",
        "name": lang.tr('theme_mode'),
        "subtitle": currentThemeLabel,
        "icon": Icons.palette_outlined,
        "iconBg": const Color(0xFF3D2D1B),
        "iconColor": const Color(0xFFFFB300),
      },
      {
        "index": "1",
        "name": lang.tr('payment_details'),
        "subtitle": lang.languageCode == 'vi' ? "Thẻ & ví điện tử" : "Cards & e-wallets",
        "icon": Icons.credit_card_rounded,
        "iconBg": const Color(0xFF1B2A3D),
        "iconColor": const Color(0xFF42A5F5),
      },
      {
        "index": "2",
        "name": lang.tr('my_order'),
        "subtitle": lang.languageCode == 'vi' ? "Lịch sử và theo dõi đơn" : "History & tracking",
        "icon": Icons.local_mall_outlined,
        "iconBg": const Color(0xFF1B332B),
        "iconColor": const Color(0xFF4CAF50),
        "base": _activeOrdersCount,
      },
      {
        "index": "3",
        "name": lang.tr('notifications'),
        "subtitle": lang.languageCode == 'vi' ? "Ưu đãi & tin tức quan trọng" : "Deals & important news",
        "icon": Icons.notifications_none_rounded,
        "iconBg": const Color(0xFF3B1E2B),
        "iconColor": const Color(0xFFFF5252),
        "base": notifCount,
      },
      {
        "index": "4",
        "name": lang.tr('inbox'),
        "subtitle": lang.languageCode == 'vi' ? "Kho voucher & mã giảm giá" : "Vouchers & promo codes",
        "icon": Icons.confirmation_number_outlined,
        "iconBg": const Color(0xFF3D271D),
        "iconColor": const Color(0xFFFC6011),
      },
      {
        "index": "5",
        "name": lang.tr('about_us'),
        "subtitle": lang.languageCode == 'vi' ? "Phiên bản v2.4.0 • Điều khoản" : "Version v2.4.0 • Terms",
        "icon": Icons.info_outline_rounded,
        "iconBg": const Color(0xFF222638),
        "iconColor": const Color(0xFF7E57C2),
      },
      {
        "index": "6",
        "name": lang.tr('logout'),
        "subtitle": lang.languageCode == 'vi' ? "Thoát tài khoản hiện tại" : "Sign out current account",
        "icon": Icons.logout_rounded,
        "iconBg": const Color(0xFF3D1B1B),
        "iconColor": const Color(0xFFFF3D00),
        "isDestructive": true,
      },
    ];

    if (UserRoleHelper.isMerchant) {
      moreArr.insert(0, {
        "index": "store_owner",
        "name": "Giao diện Cửa Hàng",
        "subtitle": "Quản lý đơn hàng, thực đơn & doanh thu",
        "icon": Icons.storefront_rounded,
        "iconBg": const Color(0xFFFC6011).withOpacity(0.15),
        "iconColor": const Color(0xFFFC6011),
      });
    }

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 46),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.tr('more'),
                      style: TextStyle(
                        color: TColor.primaryTextOf(context),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NotificationBell(
                          backgroundColor: TColor.cardOf(context),
                          iconColor: TColor.primaryTextOf(context),
                          border: Border.all(color: TColor.borderOf(context), width: 1),
                        ),
                        const SizedBox(width: 8),
                        Stack(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: TColor.cardOf(context),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: TColor.borderOf(context), width: 1),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MyOrderView()),
                              );
                            },
                            icon: Icon(
                              Icons.shopping_cart_outlined,
                              color: TColor.primaryTextOf(context),
                              size: 20,
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final cartCount = context.watch<CartProvider>().totalItemCount;
                            if (cartCount == 0) return const SizedBox.shrink();
                            return Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: TColor.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "$cartCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: moreArr.length,
                itemBuilder: (context, index) {
                  var mObj = moreArr[index] as Map? ?? {};
                  var countBase = mObj["base"] as int? ?? 0;
                  bool isDestructive = mObj["isDestructive"] == true;

                  return GestureDetector(
                    onTap: () async {
                      switch (mObj["index"].toString()) {
                        case "store_owner":
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const RestaurantOwnerMainView()),
                          );
                          break;
                        case "lang":
                          _showLanguageBottomSheet(context);
                          break;
                        case "theme":
                          _showThemeBottomSheet(context);
                          break;
                        case "1":
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const PaymentDetailsView()),
                          );
                          break;
                        case "2":
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderHistoryView()),
                          );
                          _fetchActiveOrdersCount();
                          break;
                        case "3":
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationsView()),
                          );
                          if (mounted) {
                            context.read<NotificationProvider>().refreshAll();
                          }
                          break;
                        case "4":
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const InboxView()),
                          );
                          break;
                        case "5":
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AboutUsView()),
                          );
                          break;
                        case "6":
                          ServiceCall.showLogoutDialog(context);
                          break;
                        default:
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: TColor.cardOf(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDestructive
                              ? const Color(0xFF421E1E)
                              : TColor.borderOf(context),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: isDark ? (mObj["iconBg"] as Color? ?? const Color(0xFF232733)) : const Color(0xFFF5F5F7),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              mObj["icon"] as IconData,
                              color: mObj["iconColor"] as Color? ?? TColor.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mObj["name"].toString(),
                                  style: TextStyle(
                                    color: isDestructive
                                        ? const Color(0xFFFF5252)
                                        : TColor.primaryTextOf(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (mObj["subtitle"] != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    mObj["subtitle"].toString(),
                                    style: TextStyle(
                                      color: (mObj["index"] == "lang" || mObj["index"] == "theme")
                                          ? TColor.primary
                                          : TColor.secondaryTextOf(context),
                                      fontSize: 12,
                                      fontWeight: (mObj["index"] == "lang" || mObj["index"] == "theme")
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (countBase > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                countBase.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: isDark ? const Color(0xFF525866) : const Color(0xFFCCCCCC),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
