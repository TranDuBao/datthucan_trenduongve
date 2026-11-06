import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../widgets/custom_toast.dart';
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
import 'widgets/food_form_sheet.dart';
import 'widgets/restaurant_format_utils.dart';

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
  String _menuSearchQuery = '';
  String _menuStatusFilter = 'ALL'; // 'ALL', 'DANG_BAN', 'HET_HANG', 'TAM_NGUNG'
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
                      _buildMenuTab(context),
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

  // ── TAB 2: Quản lý Thực đơn Cửa Hàng (CRUD Món Ăn) ──────────────────────
  void _openAddFoodSheet() {
    FoodFormSheet.show(
      context,
      categories: _categories,
      onSave: (payload) async {
        final success = await _service.createFoodItem(payload);
        if (success) {
          if (mounted) CustomToast.showSuccess(context, 'Thêm món ăn mới thành công');
          _loadRestaurantData();
        } else {
          if (mounted) CustomToast.showError(context, 'Không thể tạo món ăn');
        }
      },
    );
  }

  void _openEditFoodSheet(Map<String, dynamic> food) {
    final foodId = food['maMonAn'] is int
        ? food['maMonAn'] as int
        : int.tryParse((food['maMonAn'] ?? food['id']).toString()) ?? 0;

    FoodFormSheet.show(
      context,
      initialData: food,
      categories: _categories,
      onSave: (payload) async {
        final success = await _service.updateFoodItem(foodId, payload);
        if (success) {
          if (mounted) CustomToast.showSuccess(context, 'Cập nhật món ăn thành công');
          _loadRestaurantData();
        } else {
          if (mounted) CustomToast.showError(context, 'Không thể cập nhật món ăn');
        }
      },
    );
  }

  void _confirmDeleteFood(Map<String, dynamic> food) {
    final foodId = food['maMonAn'] is int
        ? food['maMonAn'] as int
        : int.tryParse((food['maMonAn'] ?? food['id']).toString()) ?? 0;
    final foodName = food['tenMonAn'] ?? 'món ăn này';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa món ăn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa món "$foodName" khỏi thực đơn không?\nHành động này không thể hoàn tác.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _service.deleteFoodItem(foodId);
              if (success) {
                if (mounted) CustomToast.showSuccess(context, 'Đã xóa món ăn thành công');
                _loadRestaurantData();
              } else {
                if (mounted) CustomToast.showError(context, 'Không thể xóa món ăn');
              }
            },
            child: const Text('Xóa món', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _quickToggleStatus(Map<String, dynamic> food, String newStatus) async {
    final foodId = food['maMonAn'] is int
        ? food['maMonAn'] as int
        : int.tryParse((food['maMonAn'] ?? food['id']).toString()) ?? 0;
    final success = await _service.updateFoodItem(foodId, {'trangThaiMon': newStatus});
    if (success) {
      if (mounted) CustomToast.showSuccess(context, 'Cập nhật trạng thái thành công');
      _loadRestaurantData();
    } else {
      if (mounted) CustomToast.showError(context, 'Không thể cập nhật trạng thái');
    }
  }

  Widget _buildMenuTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _menu.where((item) {
      final food = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
      final name = (food['tenMonAn'] ?? '').toString().toLowerCase();
      if (_menuSearchQuery.isNotEmpty && !name.contains(_menuSearchQuery.toLowerCase())) {
        return false;
      }
      final rawStatus = (food['trangThaiMon'] ?? 'DANG_BAN').toString().toUpperCase();
      if (_menuStatusFilter == 'DANG_BAN' && rawStatus != 'DANG_BAN') return false;
      if (_menuStatusFilter == 'HET_HANG' && rawStatus != 'HET_HANG' && rawStatus != 'HET_MON') return false;
      if (_menuStatusFilter == 'TAM_NGUNG' && rawStatus != 'TAM_NGUNG') return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Top Toolbar: Search & Add button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: TColor.cardOf(context),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF28303D) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TColor.borderOf(context), width: 0.8),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _menuSearchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên món ăn...',
                          hintStyle: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: TColor.secondaryTextOf(context)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: TextStyle(fontSize: 13, color: TColor.primaryTextOf(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6011),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: _openAddFoodSheet,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm Món', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'Tất cả (${_menu.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('DANG_BAN', 'Đang bán'),
                    const SizedBox(width: 8),
                    _buildFilterChip('HET_HANG', 'Hết món'),
                    const SizedBox(width: 8),
                    _buildFilterChip('TAM_NGUNG', 'Tạm ngưng'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List View of Dishes
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadRestaurantData,
            color: const Color(0xFFFC6011),
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.restaurant_menu_rounded, size: 56, color: TColor.secondaryTextOf(context).withOpacity(0.4)),
                            const SizedBox(height: 12),
                            Text(
                              _menu.isEmpty
                                  ? 'Quán chưa có món ăn nào'
                                  : 'Không tìm thấy món ăn phù hợp',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: TColor.secondaryTextOf(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _menu.isEmpty ? 'Bấm nút "Thêm Món" phía trên để tạo món đầu tiên' : 'Thử đổi từ khóa hoặc bộ lọc trạng thái',
                              style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final rawFood = filtered[index];
                      final food = rawFood is Map<String, dynamic> ? rawFood : Map<String, dynamic>.from(rawFood as Map);

                      final name = (food['tenMonAn'] ?? 'Món ăn').toString();
                      final price = RestaurantFormatUtils.formatVND(food['giaMonAn'] ?? food['gia']);
                      final img = (food['img'] ?? food['image'] ?? '').toString();
                      final qty = int.tryParse((food['soLuongMon'] ?? food['quantity'] ?? 0).toString()) ?? 0;
                      final rawStatus = (food['trangThaiMon'] ?? 'DANG_BAN').toString().toUpperCase();

                      final bool isOutOfStock = qty <= 0 || rawStatus == 'HET_HANG' || rawStatus == 'HET_MON';
                      final bool isPaused = rawStatus == 'TAM_NGUNG';

                      Color statusColor = const Color(0xFF10B981);
                      String statusLabel = 'Còn Hàng';
                      if (isPaused) {
                        statusColor = const Color(0xFFF59E0B);
                        statusLabel = 'Tạm Ngưng';
                      } else if (isOutOfStock) {
                        statusColor = const Color(0xFFEF4444);
                        statusLabel = 'Hết Món';
                      }

                      final catName = food['danhMuc'] is Map ? (food['danhMuc']['tenDanhMuc'] ?? '') : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColor.cardOf(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TColor.borderOf(context), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    color: isDark ? const Color(0xFF28303D) : const Color(0xFFF1F5F9),
                                    child: _buildFoodThumbnail(img),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Food Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                          color: TColor.primaryTextOf(context),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            price,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                              color: Color(0xFFFC6011),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '• $qty phần',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isOutOfStock ? const Color(0xFFEF4444) : TColor.secondaryTextOf(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (catName.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: TColor.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            catName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: TColor.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                      Builder(
                                        builder: (context) {
                                          final moTa = (food['moTa'] ?? food['mota'] ?? '').toString();
                                          if (moTa.isEmpty) return const SizedBox.shrink();
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              moTa,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: TColor.secondaryTextOf(context),
                                                height: 1.3,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // Status Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withOpacity(0.3), width: 0.8),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Divider(height: 1, color: TColor.borderOf(context).withOpacity(0.6)),
                            const SizedBox(height: 6),

                            // Action Bar: Quick Status, Edit, Delete
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Quick Status Menu
                                PopupMenuButton<String>(
                                  tooltip: 'Chuyển trạng thái nhanh',
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (val) => _quickToggleStatus(food, val),
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'DANG_BAN',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                                          SizedBox(width: 8),
                                          Text('Còn hàng / Đang bán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'HET_HANG',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFEF4444)),
                                          SizedBox(width: 8),
                                          Text('Hết món', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'TAM_NGUNG',
                                      child: Row(
                                        children: [
                                          Icon(Icons.pause_circle_rounded, size: 16, color: Color(0xFFF59E0B)),
                                          SizedBox(width: 8),
                                          Text('Tạm ngưng phục vụ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF28303D) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.swap_vert_rounded, size: 14, color: TColor.secondaryTextOf(context)),
                                        const SizedBox(width: 4),
                                        Text('Đổi trạng thái', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TColor.secondaryTextOf(context))),
                                      ],
                                    ),
                                  ),
                                ),

                                Row(
                                  children: [
                                    // Edit Button
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _openEditFoodSheet(food),
                                      icon: const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF0284C7)),
                                      label: const Text('Sửa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                                    ),
                                    const SizedBox(width: 8),

                                    // Delete Button
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => _confirmDeleteFood(food),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.redAccent),
                                      label: const Text('Xóa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _menuStatusFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => setState(() => _menuStatusFilter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFC6011)
              : (isDark ? const Color(0xFF28303D) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFC6011) : TColor.borderOf(context),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : TColor.secondaryTextOf(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodThumbnail(String imgUrl) {
    if (imgUrl.isEmpty) {
      return const Center(child: Icon(Icons.fastfood_rounded, color: Color(0xFFFC6011), size: 28));
    }
    if (imgUrl.startsWith('data:image')) {
      try {
        final base64Str = imgUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded, color: Color(0xFFFC6011), size: 28),
        );
      } catch (_) {
        return const Icon(Icons.fastfood_rounded, color: Color(0xFFFC6011), size: 28);
      }
    }
    final formatted = SVKey.formatImageUrl(imgUrl);
    return Image.network(
      formatted,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded, color: Color(0xFFFC6011), size: 28),
    );
  }
}
