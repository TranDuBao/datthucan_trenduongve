import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:food_route/common/color_extension.dart';
import 'package:food_route/common/format_utils.dart';
import 'package:food_route/common/globs.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/notification_service.dart';
import '../menu/menu_view.dart';
import '../main_tabview/main_tabview.dart';
import 'my_order_view.dart';
import 'order_history_view.dart';
import '../../widgets/skeleton/notification_skeleton.dart';

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
      context.read<NotificationProvider>().refreshAll();
    }
  }

  void _markAllAsRead() {
    context.read<NotificationProvider>().markAllAsRead();
    setState(() {
      for (var n in notifications) {
        n.isUnread = false;
      }
    });
  }

  int get unreadCount => notifications.where((n) => n.isUnread).length;

  List<NotificationModel> get _filteredNotifications {
    if (selectTab == 1) {
      return notifications.where((n) => n.type.toLowerCase().contains('order')).toList();
    } else if (selectTab == 2) {
      return notifications.where((n) => n.type.toLowerCase().contains('voucher') || n.type.toLowerCase().contains('promo')).toList();
    } else if (selectTab == 3) {
      return notifications.where((n) => !n.type.toLowerCase().contains('order') && !n.type.toLowerCase().contains('voucher')).toList();
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
                  _buildFilterChip(context.l10n.notifTabAll, idx: 0, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(context.l10n.notifTabOrders, idx: 1, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(context.l10n.notifTabPromos, idx: 2, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip(context.l10n.notifTabSystem, idx: 3, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Notification Groups / Cards List
            Expanded(
              child: isLoading
                  ? const NotificationSkeletonList(itemCount: 4)
                  : _filteredNotifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 52, color: TColor.secondaryTextOf(context)),
                              const SizedBox(height: 12),
                              Text(
                                context.l10n.notifEmpty,
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
                                        context.l10n.notifSecurityEncrypted,
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
                        child: Icon(LucideIcons.store, size: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.notifCravingSomething,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            context.l10n.notifDiscoverFoodNearYou,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final mainTab = context.findAncestorStateOfType<MainTabViewState>();
                        if (mainTab != null) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                          mainTab.changeTab(0, popToRoot: true);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MenuView()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        children: [
                          Text(context.l10n.notifOrderNow, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14),
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
                context.l10n.moreNotifications,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (unreadCount > 0)
                Text(
                  context.l10n.notifNewCount(unreadCount),
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  context.l10n.notifAllRead,
                  style: TextStyle(
                    color: TColor.secondaryTextOf(context),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _showNotificationSettingsSheet,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF2F3F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.settings2,
                  size: 19,
                  color: TColor.secondaryTextOf(context),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
        ),
      ],
    );
  }

  void _showNotificationSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool systemNotif = Globs.udValueTrueBool('pref_system_notif');
        bool updateNotif = Globs.udValueTrueBool('pref_update_notif');
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: TColor.bgOf(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cài đặt thông báo',
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tùy chỉnh các loại thông báo bạn muốn nhận',
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 1. Đơn hàng (Khuyến nghị luôn bật)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: true,
                    onChanged: null,
                    activeColor: TColor.primary,
                    title: const Text('Thông báo đơn hàng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: const Text('Nhận tin khi món đã sẵn sàng hoặc hoàn tiền (Luôn bật)', style: TextStyle(fontSize: 12)),
                  ),
                  const Divider(height: 16),
                  // 2. Hệ thống
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: systemNotif,
                    activeColor: TColor.primary,
                    onChanged: (val) {
                      setSheetState(() => systemNotif = val);
                      Globs.udBoolSet(val, 'pref_system_notif');
                      NotificationService.updateNotificationSettings(systemNotif: val);
                    },
                    title: const Text('Thông báo hệ thống', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: const Text('Tin bảo trì, điều chỉnh dịch vụ từ ban quản trị', style: TextStyle(fontSize: 12)),
                  ),
                  const Divider(height: 16),
                  // 3. Cập nhật
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: updateNotif,
                    activeColor: TColor.primary,
                    onChanged: (val) {
                      setSheetState(() => updateNotif = val);
                      Globs.udBoolSet(val, 'pref_update_notif');
                      NotificationService.updateNotificationSettings(updateNotif: val);
                    },
                    title: const Text('Cập nhật phiên bản', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: const Text('Thông tin phiên bản mới và các tính năng nâng cấp', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            );
          },
        );
      },
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

  String _getLocalizedGroupName(BuildContext context, String groupName) {
    switch (groupName) {
      case 'HÔM NAY':
        return context.l10n.notifPeriodToday;
      case 'TUẦN NÀY':
        return context.l10n.notifPeriodThisWeek;
      case 'TRƯỚC ĐÓ':
      case 'CŨ HƠN':
        return context.l10n.notifPeriodEarlier;
      default:
        return groupName;
    }
  }

  String? _getLocalizedStatusTag(BuildContext context, String? tag) {
    if (tag == null || tag.isEmpty) return null;
    switch (tag.toUpperCase()) {
      case 'HOAN_TAT':
      case 'HOÀN TẤT':
      case 'COMPLETED':
        return context.l10n.notifTagCompleted;
      case 'SAN_SANG':
      case 'SẴN SÀNG':
      case 'READY':
      case 'READY_FOR_PICKUP':
        return context.l10n.notifTagReady;
      case 'DANG_CHUAN_BI':
      case 'ĐANG CHUẨN BỊ':
      case 'BẾP CHUẨN BỊ':
      case 'PREPARING':
        return context.l10n.notifTagPreparing;
      case 'DANG_GIAO':
      case 'ĐANG GIAO':
      case 'DELIVERING':
        return context.l10n.notifTagDelivering;
      case 'THANH_TOAN':
      case 'THANH TOÁN':
      case 'THÀNH CÔNG':
      case 'PAID':
        return context.l10n.notifTagPaid;
      case 'DA_HUY':
      case 'ĐÃ HỦY':
      case 'CANCELLED':
        return context.l10n.notifTagCancelled;
      default:
        return tag;
    }
  }

  String _getLocalizedTimeAgo(BuildContext context, NotificationModel item) {
    if (item.createdAt != null) {
      final diff = DateTime.now().difference(item.createdAt!);
      if (diff.inSeconds < 60) {
        return context.l10n.formatJustNow;
      } else if (diff.inMinutes < 60) {
        return context.l10n.formatMinutesAgo(diff.inMinutes);
      } else if (diff.inHours < 24) {
        return context.l10n.formatHoursAgo(diff.inHours);
      } else {
        return context.l10n.formatDaysAgo(diff.inDays);
      }
    }
    return item.timeAgo;
  }

  String _getLocalizedTitle(BuildContext context, String rawTitle) {
    final t = rawTitle.trim();
    if (t == 'Thanh toán thành công') return context.l10n.notifTitlePaymentSuccess;
    if (t == 'Đơn hàng hoàn tất') return context.l10n.notifTitleOrderCompleted;
    if (t == 'Món ăn đã sẵn sàng') return context.l10n.notifTitleFoodReady;
    if (t == 'Đang chuẩn bị món') return context.l10n.notifTitleFoodPreparing;
    if (t.contains('xác nhận') || t.contains('nhận đơn')) return context.l10n.notifTitleOrderConfirmed;
    if (t.contains('hủy')) return context.l10n.notifTitleOrderCancelled;
    return rawTitle;
  }

  String _getLocalizedBody(BuildContext context, NotificationModel item) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    if (!isEn) return item.body;

    final b = item.body;
    final code = item.orderCode ?? (item.orderId != null ? '#DH-${item.orderId}' : '');

    if (item.title.contains('Thanh toán thành công') || b.contains('xác nhận thanh toán thành công')) {
      final amountMatch = RegExp(r'\(([\d\.]+[đ|k|VND]?)\)').firstMatch(b);
      final amt = amountMatch != null ? ' ${amountMatch.group(0)}' : '';
      return 'Order $code payment was confirmed$amt. The store is receiving your order.';
    }
    if (item.title.contains('hoàn tất') || b.contains('đã hoàn tất')) {
      return 'Order $code is completed. Thank you for choosing our store!';
    }
    if (item.title.contains('sẵn sàng') || b.contains('đã sẵn sàng')) {
      return 'Order $code is ready! Please arrive to pick up your food.';
    }
    if (item.title.contains('chuẩn bị') || b.contains('đang chuẩn bị')) {
      return 'The store is currently preparing your order $code.';
    }
    if (item.title.contains('hủy') || b.contains('đã hủy') || b.contains('đã bị hủy')) {
      return 'Order $code has been cancelled.';
    }
    return item.body;
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
              _getLocalizedGroupName(context, groupName),
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
              context.l10n.notifMarkAllRead,
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

    final typeLower = item.type.toLowerCase();
    final statusLower = (item.statusTag ?? '').toLowerCase();

    if (typeLower == 'order_ready' || statusLower.contains('sẵn sàng') || statusLower.contains('san_sang') || statusLower.contains('hoan_tat')) {
      // 1. Đơn sẵn sàng / hoàn thành -> Xanh lá
      iconBgColor = const Color(0xFFE8F5E9);
      iconColor = const Color(0xFF2E7D32);
      iconData = LucideIcons.checkCircle;
    } else if (typeLower == 'order_cancelled' || statusLower.contains('hủy') || statusLower.contains('huy')) {
      // 2. Đơn bị hủy -> Đỏ
      iconBgColor = const Color(0xFFFFEBEE);
      iconColor = const Color(0xFFD32F2F);
      iconData = LucideIcons.xCircle;
    } else if (typeLower == 'refund' || statusLower.contains('hoàn') || statusLower.contains('refund')) {
      // 3. Hoàn tiền -> Cam
      iconBgColor = const Color(0xFFFFF3E0);
      iconColor = const Color(0xFFFF9800);
      iconData = LucideIcons.badgePercent;
    } else if (typeLower == 'update' || statusLower.contains('phiên bản') || statusLower.contains('version')) {
      // 4. Cập nhật phiên bản -> Xanh dương
      iconBgColor = const Color(0xFFEFF6FF);
      iconColor = const Color(0xFF2563EB);
      iconData = LucideIcons.arrowUpCircle;
    } else if (typeLower == 'alert' || statusLower.contains('khẩn cấp') || statusLower.contains('cảnh báo')) {
      // 5. Cảnh báo khẩn cấp -> Đỏ
      iconBgColor = const Color(0xFFFEF2F2);
      iconColor = const Color(0xFFDC2626);
      iconData = LucideIcons.megaphone;
    } else if (typeLower == 'promo' || statusLower.contains('ưu đãi') || statusLower.contains('khuyến mãi') || statusLower.contains('voucher')) {
      // 6. Ưu đãi lộ trình -> Xanh lá
      iconBgColor = const Color(0xFFF0FDF4);
      iconColor = const Color(0xFF16A34A);
      iconData = LucideIcons.gift;
    } else if (item.statusTag == 'ĐANG GIAO') {
      iconBgColor = const Color(0xFFFFECE5);
      iconColor = const Color(0xFFFF5722);
      iconData = Icons.two_wheeler_rounded;
    } else if (item.statusTag == 'BẾP CHUẨN BỊ') {
      iconBgColor = const Color(0xFFFFF8E1);
      iconColor = const Color(0xFFFFB300);
      iconData = Icons.soup_kitchen_outlined;
    } else {
      // 7. Hệ thống / Thông báo chung -> Cam thương hiệu
      iconBgColor = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFFC6011);
      iconData = LucideIcons.bell;
    }

    if (isDark) {
      iconBgColor = iconColor.withOpacity(0.18);
    }

    return InkWell(
      onTap: () {
        context.read<NotificationProvider>().markAsRead(item);
        setState(() {
          item.isUnread = false;
        });

        if (item.orderId != null && item.orderId! > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderHistoryView()),
          );
        }
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
                                    _getLocalizedStatusTag(context, item.statusTag) ?? item.statusTag!,
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
                                _getLocalizedTimeAgo(context, item),
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
                        (item.titleEn != null && item.titleEn!.isNotEmpty)
                            ? item.getLocalizedTitle(Localizations.localeOf(context).languageCode)
                            : _getLocalizedTitle(context, item.title),
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Body
                      Text(
                        (item.bodyEn != null && item.bodyEn!.isNotEmpty)
                            ? item.getLocalizedBody(Localizations.localeOf(context).languageCode)
                            : _getLocalizedBody(context, item),
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
