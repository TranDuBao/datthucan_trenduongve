import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/locator.dart';
import '../../common/service_call.dart';
import '../../common/user_role_helper.dart';
import '../../providers/restaurant_orders_provider.dart';
import '../../services/restaurant_owner_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/notification_bell.dart';
import '../main_tabview/main_tabview.dart';
import 'restaurant_revenue_view.dart';
import 'restaurant_store_profile_tab.dart';
import 'restaurant_vouchers_view.dart';
import 'widgets/owner_orders_tab.dart';
import 'widgets/owner_menu_tab.dart';

class RestaurantOwnerMainView extends StatefulWidget {
  const RestaurantOwnerMainView({super.key});

  @override
  State<RestaurantOwnerMainView> createState() => _RestaurantOwnerMainViewState();
}

class _RestaurantOwnerMainViewState extends State<RestaurantOwnerMainView> {
  final RestaurantOwnerService _service = locator<RestaurantOwnerService>();
  late RestaurantOrdersProvider _ordersProvider;

  int _selectTab = 0;
  bool _loading = false;
  List<dynamic> _menu = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic> _storeProfile = {};

  int? get _maQuan => _storeProfile['maQuan'] ?? _storeProfile['id'];

  @override
  void initState() {
    super.initState();
    _ordersProvider = RestaurantOrdersProvider();
    _loadRestaurantData();
    locator<SocketService>().listenToMenuUpdates(_onMenuUpdated);
  }

  void _onMenuUpdated(dynamic data) {
    if (!mounted) return;
    _loadRestaurantData();
  }

  @override
  void dispose() {
    locator<SocketService>().offMenuUpdates(_onMenuUpdated);
    _ordersProvider.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantData() async {
    setState(() => _loading = true);
    final token = Globs.udValueString(KKey.authToken);

    final headers = {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      // 1. Fetch Profile
      final prof = await _service.getProfile();
      if (prof != null) {
        _storeProfile = prof;
        final storeId = _storeProfile['maQuan'] ?? _storeProfile['id'];
        _ordersProvider.init(storeId is int ? storeId : int.tryParse(storeId.toString()));
      }
    } catch (e) {
      debugPrint('[RestaurantOwnerMainView] Error fetching profile: $e');
    }

    try {
      _categories = await _service.getCategories();
    } catch (e) {
      debugPrint('[RestaurantOwnerMainView] Error fetching categories: $e');
    }

    try {
      // 2. Fetch Menu
      final menuRes = await http
          .get(Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/menu'), headers: headers)
          .timeout(const Duration(seconds: 4));
      if (menuRes.statusCode == 200) {
        final body = json.decode(menuRes.body);
        final data = body['data'];
        if (data is List) {
          _menu = data;
        } else if (data is Map) {
          _menu = data['foods'] ?? data['items'] ?? [];
        } else {
          _menu = [];
        }
      }
    } catch (e) {
      debugPrint('[RestaurantOwnerMainView] Error fetching menu: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _showSwitchRoleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFF0284C7)),
            SizedBox(width: 8),
            Text('Chuyển giao diện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn sắp chuyển sang giao diện Khách Hàng để trải nghiệm ứng dụng.\n\nBạn có thể quay lại giao diện Cửa Hàng bất kỳ lúc nào qua thanh thông báo trên đỉnh màn hình hoặc trong mục Xem Thêm.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainTabView()),
                (route) => false,
              );
            },
            child: const Text('Xác nhận chuyển', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeName = _storeProfile['tenQuan'] ?? UserRoleHelper.userName;

    return ChangeNotifierProvider.value(
      value: _ordersProvider,
      child: Consumer<RestaurantOrdersProvider>(
        builder: (context, ordersProvider, _) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_selectTab != 0) {
                setState(() => _selectTab = 0);
              } else {
                SystemNavigator.pop();
              }
            },
            child: Scaffold(
            backgroundColor: TColor.bgOf(context),
            appBar: AppBar(
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF1E232A) : Colors.white,
              automaticallyImplyLeading: false,
              titleSpacing: 12,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: TColor.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.storefront_rounded, color: TColor.primary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFC6011).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'CHỦ QUÁN',
                                style: TextStyle(
                                  color: Color(0xFFFC6011),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'Mở cửa',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Center(
                    child: NotificationBell(
                      backgroundColor: Colors.transparent,
                      iconColor: Color(0xFFFC6011),
                      size: 22,
                      width: 36,
                      height: 36,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFC6011), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: _loadRestaurantData,
                  tooltip: 'Làm mới dữ liệu',
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: TColor.secondaryTextOf(context), size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'switch') {
                      _showSwitchRoleDialog();
                    } else if (val == 'logout') {
                      ServiceCall.showLogoutDialog(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'switch',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF0284C7)),
                          SizedBox(width: 10),
                          Text('Giao diện Khách hàng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                          SizedBox(width: 10),
                          Text('Đăng xuất tài khoản', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFC6011)))
                : IndexedStack(
                    index: _selectTab,
                    children: [
                      const OwnerOrdersTab(),
                      OwnerMenuTab(
                        menu: _menu,
                        categories: _categories,
                        onRefresh: _loadRestaurantData,
                      ),
                      RestaurantVouchersView(maQuan: _maQuan),
                      const RestaurantRevenueView(),
                      RestaurantStoreProfileTab(
                        storeProfile: _storeProfile,
                        onProfileUpdated: _loadRestaurantData,
                      ),
                    ],
                  ),
            bottomNavigationBar: _buildBottomTabBar(context, ordersProvider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomTabBar(BuildContext context, RestaurantOrdersProvider ordersProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: TColor.navBgOf(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: TColor.borderOf(context).withOpacity(0.6),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _buildNavItem(0, 'Đơn Hàng', Icons.receipt_long_rounded, badgeCount: ordersProvider.pendingCount),
              _buildNavItem(1, 'Thực Đơn', Icons.restaurant_menu_rounded),
              _buildNavItem(2, 'Voucher', Icons.confirmation_number_rounded),
              _buildNavItem(3, 'Doanh Thu', Icons.bar_chart_rounded),
              _buildNavItem(4, 'Hồ Sơ Quán', Icons.store_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, IconData icon, {int badgeCount = 0}) {
    final isSelected = _selectTab == index;
    final activeColor = TColor.primary;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (_selectTab != index) {
            setState(() {
              _selectTab = index;
            });
          }
        },
        splashColor: activeColor.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (isSelected)
              Positioned(
                top: 0,
                child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -8,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$badgeCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? activeColor : inactiveColor,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
