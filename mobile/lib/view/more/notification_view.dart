import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../services/notification_service.dart';
import '../menu/menu_view.dart';
import 'my_order_view.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  int selectTab = 0; // 0: Tất cả, 1: Đơn hàng, 2: Ưu đãi, 3: Hệ thống
  bool isLoading = true;
  List<NotificationModel> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotificationsFromDatabase();
  }

  Future<void> _loadNotificationsFromDatabase() async {
    setState(() => isLoading = true);
    final list = await NotificationService.fetchNotificationsFromDB();
    if (mounted) {
      setState(() {
        notifications = list;
        isLoading = false;
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n.isUnread = false;
      }
    });
  }

  int get unreadCount => notifications.where((n) => n.isUnread).length;

  List<NotificationModel> get _filteredNotifications {
    if (selectTab == 1) {
      return notifications.where((n) => n.type == 'ORDER').toList();
    } else if (selectTab == 2) {
      return notifications.where((n) => n.type == 'PROMO').toList();
    } else if (selectTab == 3) {
      return notifications.where((n) => n.type == 'SYSTEM').toList();
    }
    return notifications;
  }

  Map<String, List<NotificationModel>> get _groupedNotifications {
    final Map<String, List<NotificationModel>> map = {};
    for (var n in _filteredNotifications) {
      final key = n.groupPeriod;
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(n);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();
    final grouped = _groupedNotifications;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildHeader(context, lang, isDark),
            ),

            // Horizontal Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFilterChip("Tất cả", idx: 0, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip("Đơn hàng", idx: 1, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(isDark ? "Ưu đãi" : "Ưu đãi hot 🔥", idx: 2, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(isDark ? "Hệ thống" : "Cập nhật", idx: 3, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Notification Groups / Cards List
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: TColor.primary))
                  : _filteredNotifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 52, color: TColor.secondaryTextOf(context)),
                              const SizedBox(height: 12),
                              Text(
                                "Bạn chưa có thông báo nào",
                                style: TextStyle(
                                  color: TColor.primaryTextOf(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotificationsFromDatabase,
                          color: TColor.primary,
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            children: [
                              for (var entry in grouped.entries) ...[
                                _buildGroupHeader(entry.key, isDark),
                                const SizedBox(height: 8),
                                for (var item in entry.value) ...[
                                  _buildNotificationCard(item, isDark),
                                  const SizedBox(height: 12),
                                ],
                                const SizedBox(height: 8),
                              ],

                              // Security Banner
                              const SizedBox(height: 12),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF171B26) : const Color(0xFFF2F3F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: TColor.borderOf(context)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.shield_outlined, color: Color(0xFF4CAF50), size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Tất cả thông báo đều được mã hóa an toàn",
                                        style: TextStyle(
                                          color: TColor.secondaryTextOf(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
            ),

            // Bottom Order Banner in Light Mode (Screenshot 2)
            if (!isDark)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2430),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: TColor.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text("🍴", style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Đang thèm gì đó?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "Khám phá món ngon gần bạn",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MenuView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        children: [
                          Text("Đặt món", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LanguageProvider lang, bool isDark) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF2F3F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: TColor.primaryTextOf(context),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                "Thông Báo",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (unreadCount > 0)
                Text(
                  "$unreadCount thông báo mới",
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  "Đã đọc tất cả",
                  style: TextStyle(
                    color: TColor.secondaryTextOf(context),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        InkWell(
          onTap: _markAllAsRead,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF2F3F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.done_all_rounded,
              size: 20,
              color: unreadCount > 0 ? TColor.primary : TColor.secondaryTextOf(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {required int idx, required bool isDark}) {
    final isSelected = selectTab == idx;
    return InkWell(
      onTap: () => setState(() => selectTab = idx),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? TColor.primary
              : (isDark ? const Color(0xFF171B26) : const Color(0xFFEFEFEF)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? TColor.primary
                : (isDark ? const Color(0xFF232836) : Colors.transparent),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : TColor.primaryText),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader(String groupName, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: TColor.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              groupName,
              style: TextStyle(
                color: TColor.secondaryTextOf(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        if (groupName == 'HÔM NAY')
          InkWell(
            onTap: _markAllAsRead,
            child: Text(
              "Đánh dấu đã đọc",
              style: TextStyle(
                color: TColor.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel item, bool isDark) {
    Color iconBgColor;
    Color iconColor;
    IconData iconData;

    if (item.statusTag == 'ĐANG GIAO') {
      iconBgColor = const Color(0xFFFFECE5);
      iconColor = const Color(0xFFFF5722);
      iconData = Icons.two_wheeler_rounded;
    } else if (item.statusTag == 'BẾP CHUẨN BỊ') {
      iconBgColor = const Color(0xFFFFF8E1);
      iconColor = const Color(0xFFFFB300);
      iconData = Icons.soup_kitchen_outlined;
    } else if (item.statusTag == 'THÀNH CÔNG' || item.statusTag == 'HOÀN TẤT') {
      iconBgColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
      iconData = Icons.check_circle_outline_rounded;
    } else if (item.type == 'PROMO') {
      iconBgColor = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFFB8C00);
      iconData = Icons.card_giftcard_rounded;
    } else {
      iconBgColor = const Color(0xFFE3F2FD);
      iconColor = const Color(0xFF1E88E5);
      iconData = Icons.account_balance_wallet_outlined;
    }

    if (isDark) {
      iconBgColor = iconColor.withOpacity(0.18);
    }

    return InkWell(
      onTap: () {
        setState(() {
          item.isUnread = false;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TColor.cardOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.isUnread
                ? TColor.primary.withOpacity(0.4)
                : TColor.borderOf(context),
            width: item.isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag & Time & Unread Dot Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (item.statusTag != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.statusTag!,
                                    style: TextStyle(
                                      color: iconColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                item.timeAgo,
                                style: TextStyle(
                                  color: TColor.secondaryTextOf(context),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          if (item.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5722),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        item.title,
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Body
                      Text(
                        item.body,
                        style: TextStyle(
                          color: TColor.secondaryTextOf(context),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Optional Actions/Chips Row (Tracking / Order Rating)
            if (item.distanceText != null || item.statusTag == 'THÀNH CÔNG') ...[
              const SizedBox(height: 12),
              Divider(color: TColor.borderOf(context), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (item.distanceText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: TColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TColor.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.near_me_rounded, color: TColor.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            item.distanceText!,
                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (item.orderCode != null)
                    Text(
                      item.orderCode!,
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  if (item.statusTag == 'THÀNH CÔNG')
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyOrderView()),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            "Đánh giá đơn hàng",
                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: TColor.primary, size: 14),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
