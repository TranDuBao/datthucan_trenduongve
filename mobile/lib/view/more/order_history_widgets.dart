import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../services/order_service.dart';
import '../../widgets/order_progress_stepper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Format date-time to compact display
// ─────────────────────────────────────────────────────────────────────────────
String formatDateTimeShort(String dtStr) {
  if (dtStr.isEmpty) return '';
  try {
    if (dtStr.contains('T')) {
      final parts = dtStr.split('T');
      if (parts.length >= 2) {
        final dateParts = parts[0].split('-');
        final timeStr = parts[1].length >= 5 ? parts[1].substring(0, 5) : parts[1];
        if (dateParts.length == 3) {
          return '${dateParts[1]}-${dateParts[2]} $timeStr';
        }
        return '${parts[0]} $timeStr';
      }
    }
  } catch (_) {}
  return dtStr;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Format pickup time HH:mm
// ─────────────────────────────────────────────────────────────────────────────
String formatPickupTime(String timeStr) {
  if (timeStr.isEmpty) return '';
  try {
    if (timeStr.contains('T')) {
      final parts = timeStr.split('T');
      if (parts.length > 1) {
        final timePart = parts[1];
        if (timePart.length >= 5) return timePart.substring(0, 5);
      }
    }
  } catch (_) {}
  return timeStr;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: Format currency VND
// ─────────────────────────────────────────────────────────────────────────────
String formatOrderTotal(double amount) {
  return '${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
}

// ─────────────────────────────────────────────────────────────────────────────
// Round icon button (header buttons)
// ─────────────────────────────────────────────────────────────────────────────
class OrderHistoryRoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const OrderHistoryRoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: isDark ? const Color(0xFFD0D4E0) : const Color(0xFF344054),
          size: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter tab bar (Tất cả / Đang xử lý / Đã hoàn thành / Đã hủy)
// ─────────────────────────────────────────────────────────────────────────────
class OrderFilterTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<OrderServiceModel> allOrders;
  final List<OrderServiceModel> activeOrders;
  final List<OrderServiceModel> completedOrders;
  final List<OrderServiceModel> cancelledOrders;
  final ValueChanged<int> onTabSelected;

  const OrderFilterTabBar({
    super.key,
    required this.selectedIndex,
    required this.allOrders,
    required this.activeOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = [
      {'title': 'Tất cả', 'count': allOrders.length},
      {'title': 'Đang xử lý', 'count': activeOrders.length},
      {'title': 'Đã hoàn thành', 'count': completedOrders.length},
      {'title': 'Đã hủy', 'count': cancelledOrders.length},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          final tab = tabs[index];
          final count = tab['count'] as int;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => onTabSelected(index),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFC6011)
                      : (isDark ? const Color(0xFF1E222D) : Colors.white),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFC6011)
                        : (isDark ? const Color(0xFF2C3240) : const Color(0xFFE4E7EC)),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFC6011).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab['title'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFFD0D4E0) : const Color(0xFF344054)),
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.28)
                            : (isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085)),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header (Đang chuẩn bị / Lịch sử / Đã hủy)
// ─────────────────────────────────────────────────────────────────────────────
class OrderSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final bool iconDot;
  final bool iconCheck;
  final bool iconClose;
  final bool isDark;

  const OrderSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.iconDot = false,
    this.iconCheck = false,
    this.iconClose = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (iconDot) ...[
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFFFC6011), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ],
            if (iconCheck) ...[
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(color: Color(0xFFFFF2EB), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Color(0xFFFC6011), size: 12),
              ),
              const SizedBox(width: 8),
            ],
            if (iconClose) ...[
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(color: Color(0xFFFEF3F2), shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded, color: Color(0xFFF04438), size: 12),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                color: iconDot
                    ? (isDark ? const Color(0xFFFF7A38) : const Color(0xFFD94F04))
                    : (isDark ? Colors.white : const Color(0xFF101828)),
                fontSize: iconDot ? 12 : 15,
                fontWeight: FontWeight.w800,
                letterSpacing: iconDot ? 0.4 : 0,
              ),
            ),
          ],
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(color: Color(0xFFFC6011), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E222D) : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText!,
              style: TextStyle(
                color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5-step icon stepper
// ─────────────────────────────────────────────────────────────────────────────
class OrderFiveStepStepper extends StatelessWidget {
  final int currentStep;
  final bool isDark;

  const OrderFiveStepStepper({
    super.key,
    required this.currentStep,
    required this.isDark,
  });

  static const _stepIcons = [
    Icons.receipt_long_rounded,
    Icons.storefront_rounded,
    Icons.menu_book_rounded,
    Icons.shopping_bag_outlined,
    Icons.check_rounded,
  ];

  static const _stepLabels = ['Đã đặt', 'Xác nhận', 'Chuẩn bị', 'Chờ lấy', 'Đã lấy'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final sidePadding = totalWidth / 10;

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // Connecting lines
            Positioned(
              left: sidePadding,
              right: sidePadding,
              top: 15.5,
              child: Row(
                children: List.generate(4, (index) {
                  final isLinePassed = index + 1 < currentStep;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: isLinePassed
                          ? const Color(0xFFFC6011)
                          : (isDark ? const Color(0xFF2C3240) : const Color(0xFFEAECF0)),
                    ),
                  );
                }),
              ),
            ),

            // Step nodes + labels
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(5, (index) {
                final stepNum = index + 1;
                final isPassed = stepNum < currentStep;
                final isActive = stepNum == currentStep;

                late Widget nodeWidget;
                if (isPassed) {
                  nodeWidget = Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Color(0xFFFC6011), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  );
                } else if (isActive) {
                  nodeWidget = Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC6011),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFC6011).withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(_stepIcons[index], color: Colors.white, size: 18),
                  );
                } else {
                  nodeWidget = Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1E28) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _stepIcons[index],
                      color: isDark ? const Color(0xFF707688) : const Color(0xFF98A2B3),
                      size: 16,
                    ),
                  );
                }

                Color labelColor = isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085);
                if (isPassed || isActive) labelColor = const Color(0xFFFC6011);

                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 34, child: Center(child: nodeWidget)),
                      const SizedBox(height: 6),
                      Text(
                        _stepLabels[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: 10.5,
                          fontWeight: isActive
                              ? FontWeight.w800
                              : (isPassed ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state (no orders at all)
// ─────────────────────────────────────────────────────────────────────────────
class OrderHistoryEmptyState extends StatelessWidget {
  const OrderHistoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: TColor.secondaryTextOf(context).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(
                color: TColor.primaryTextOf(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các đơn hàng đã đặt sẽ hiển thị tiến trình theo dõi tại đây!',
              textAlign: TextAlign.center,
              style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty filter state (filtered tab has no results)
// ─────────────────────────────────────────────────────────────────────────────
class OrderEmptyFilterState extends StatelessWidget {
  final String message;

  const OrderEmptyFilterState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared food summary helper
// ─────────────────────────────────────────────────────────────────────────────
({int qty, String summary}) buildFoodSummary(List<dynamic> items) {
  final int firstQty = (items.isNotEmpty && items[0]['soLuong'] != null)
      ? (int.tryParse(items[0]['soLuong'].toString()) ?? 1)
      : (items.isNotEmpty && items[0]['quantity'] != null
          ? (int.tryParse(items[0]['quantity'].toString()) ?? 1)
          : 1);
  final String firstDishName = items.isNotEmpty
      ? (items[0]['tenMonAn'] ?? items[0]['name'] ?? items[0]['foodName'] ?? 'Món ăn')
      : 'Món ăn';
  final String foodSummary = items.length > 1
      ? '$firstDishName (+${items.length - 1} món khác)'
      : firstDishName;
  return (qty: firstQty, summary: foodSummary);
}

// ─────────────────────────────────────────────────────────────────────────────
// Status helpers (delegates to OrderProgressStepper)
// ─────────────────────────────────────────────────────────────────────────────
bool isCompletedOrder(String status) =>
    OrderProgressStepper.getStepFromStatus(status) == 5;

bool isCancelledOrder(String status) =>
    OrderProgressStepper.isCancelledStatus(status);
