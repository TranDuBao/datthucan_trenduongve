import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../view/main_tabview/main_tabview.dart';
import '../../widgets/order_progress_stepper.dart';
import 'order_history_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Active Order Card (Đang chuẩn bị / chờ lấy)
// ─────────────────────────────────────────────────────────────────────────────
class ActiveOrderCard extends StatelessWidget {
  final OrderServiceModel order;
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onShowDetail;
  final void Function(dynamic item, OrderServiceModel order) onNavigateToItem;

  const ActiveOrderCard({
    super.key,
    required this.order,
    required this.isDark,
    required this.onCancel,
    required this.onShowDetail,
    required this.onNavigateToItem,
  });

  @override
  Widget build(BuildContext context) {
    final stepNum = OrderProgressStepper.getStepFromStatus(order.status);
    final formattedTotal = formatOrderTotal(order.totalAmount);
    final (:qty, :summary) = buildFoodSummary(order.items);

    String stepTitle = 'Bước 1: Đã đặt món';
    String stepSubText = 'Quán đang tiếp nhận';
    if (stepNum == 2) {
      stepTitle = 'Bước 2: Quán đã xác nhận';
      final formattedPickup = formatPickupTime(order.pickupTime);
      stepSubText = formattedPickup.isNotEmpty ? 'Dự kiến lấy: $formattedPickup' : 'Quán đã duyệt đơn';
    } else if (stepNum == 3) {
      stepTitle = 'Bước 3: Đang chuẩn bị';
      stepSubText = 'Bếp đang thực hiện';
    } else if (stepNum == 4) {
      stepTitle = 'Bước 4: Sẵn sàng ghé lấy';
      stepSubText = 'Có thể đến lấy ngay';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E28) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#DH${order.orderId}',
                      style: const TextStyle(
                        color: Color(0xFFFC6011),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (order.createdAt.isNotEmpty)
                    Text(
                      order.createdAt.length > 16 ? order.createdAt.substring(0, 16) : order.createdAt,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF707688) : const Color(0xFF98A2B3),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Tổng tiền ',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF707688) : const Color(0xFF98A2B3),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    formattedTotal,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF101828),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Food name
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${qty}x ',
                  style: const TextStyle(
                    color: Color(0xFFFC6011),
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                TextSpan(
                  text: summary,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF101828),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Store name row
          Row(
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 15,
                color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  order.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tự ghé lấy',
                  style: TextStyle(color: Color(0xFF00A86B), fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Step indicator row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Color(0xFFFC6011), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    stepTitle,
                    style: const TextStyle(
                      color: Color(0xFFFC6011),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stepSubText,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF707688) : const Color(0xFF667085),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          OrderFiveStepStepper(currentStep: stepNum, isDark: isDark),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              if (stepNum <= 2) ...[
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? const Color(0xFF3B4052) : const Color(0xFFFFD4D4),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        '✕ Hủy đơn',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFF04438) : const Color(0xFFD92D20),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => onNavigateToItem(
                      order.items.isNotEmpty ? order.items[0] : null,
                      order,
                    ),
                    icon: const Icon(Icons.arrow_outward_rounded, color: Color(0xFFFC6011), size: 14),
                    label: const Text(
                      'Đi đến sản phẩm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFFFC6011), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: const Color(0xFFFFF4EE),
                      side: const BorderSide(color: Color(0xFFFFE5D6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: onShowDetail,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: const Color(0xFFFC6011),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Xem chi tiết',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completed Order Card (Đã lấy hàng)
// ─────────────────────────────────────────────────────────────────────────────
class CompletedOrderCard extends StatelessWidget {
  final OrderServiceModel order;
  final bool isDark;
  final bool isReviewed;
  final VoidCallback onReview;
  final VoidCallback onShowDetail;
  final void Function(dynamic item, OrderServiceModel order) onNavigateToItem;

  const CompletedOrderCard({
    super.key,
    required this.order,
    required this.isDark,
    required this.isReviewed,
    required this.onReview,
    required this.onShowDetail,
    required this.onNavigateToItem,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTotal = formatOrderTotal(order.totalAmount);
    final (:qty, :summary) = buildFoodSummary(order.items);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E28) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#DH${order.orderId}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (order.createdAt.isNotEmpty)
                      Flexible(
                        child: Text(
                          formatDateTimeShort(order.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF707688) : const Color(0xFF98A2B3),
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTotal,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF101828),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '● Đã lấy',
                      style: TextStyle(
                        color: Color(0xFFFC6011),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Food name (clickable)
          InkWell(
            onTap: () => onNavigateToItem(
              order.items.isNotEmpty ? order.items[0] : null,
              order,
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${qty}x ',
                          style: const TextStyle(
                            color: Color(0xFFFC6011),
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                        TextSpan(
                          text: summary,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF101828),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFFC6011)),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // Store name
          Row(
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 15,
                color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  order.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: onReview,
                    icon: Icon(
                      isReviewed ? Icons.check_circle_rounded : Icons.star_rounded,
                      color: isReviewed ? const Color(0xFF10B981) : const Color(0xFFFFB000),
                      size: 14,
                    ),
                    label: Text(
                      isReviewed ? 'Đã đánh giá' : 'Đánh giá',
                      style: TextStyle(
                        color: isReviewed ? const Color(0xFF10B981) : const Color(0xFFFFB000),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      side: BorderSide(
                        color: isReviewed ? const Color(0xFF10B981) : const Color(0xFFFFB000),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => onNavigateToItem(
                      order.items.isNotEmpty ? order.items[0] : null,
                      order,
                    ),
                    icon: const Icon(Icons.arrow_outward_rounded, color: Color(0xFFFC6011), size: 14),
                    label: const Text(
                      'Đi đến sản phẩm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFFFC6011), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: const Color(0xFFFFF4EE),
                      side: const BorderSide(color: Color(0xFFFFE5D6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: onShowDetail,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: const Color(0xFFFC6011),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Xem chi tiết',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cancelled Order Card (Đã hủy)
// ─────────────────────────────────────────────────────────────────────────────
class CancelledOrderCard extends StatelessWidget {
  final OrderServiceModel order;
  final bool isDark;
  final VoidCallback onShowDetail;
  final void Function(dynamic item, OrderServiceModel order) onNavigateToItem;

  const CancelledOrderCard({
    super.key,
    required this.order,
    required this.isDark,
    required this.onShowDetail,
    required this.onNavigateToItem,
  });

  void _reorder(BuildContext context) {
    final mainTab = context.findAncestorStateOfType<MainTabViewState>();
    if (mainTab != null) {
      mainTab.changeTab(0, popToRoot: true);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainTabView(initialTab: 0)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTotal = formatOrderTotal(order.totalAmount);
    final (:qty, :summary) = buildFoodSummary(order.items);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E28) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#DH${order.orderId}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (order.createdAt.isNotEmpty)
                      Flexible(
                        child: Text(
                          formatDateTimeShort(order.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? const Color(0xFF707688) : const Color(0xFF98A2B3),
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTotal,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF101828),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '● Đã hủy',
                      style: TextStyle(color: Color(0xFFF04438), fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Food name (clickable)
          InkWell(
            onTap: () => onNavigateToItem(
              order.items.isNotEmpty ? order.items[0] : null,
              order,
            ),
            child: Row(
              children: [
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${qty}x ',
                          style: const TextStyle(
                            color: Color(0xFFFC6011),
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                        TextSpan(
                          text: summary,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF101828),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFFC6011)),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // Store name
          Row(
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 15,
                color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  order.restaurantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: onShowDetail,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: isDark ? const Color(0xFF1E222D) : const Color(0xFFF9FAFB),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF2C3240) : const Color(0xFFEAECF0),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Xem chi tiết',
                      style: TextStyle(
                        color: isDark ? const Color(0xFFD0D4E0) : const Color(0xFF344054),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => onNavigateToItem(
                      order.items.isNotEmpty ? order.items[0] : null,
                      order,
                    ),
                    icon: const Icon(Icons.arrow_outward_rounded, color: Color(0xFFFC6011), size: 14),
                    label: const Text(
                      'Đi đến sản phẩm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Color(0xFFFC6011), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: const Color(0xFFFFF4EE),
                      side: const BorderSide(color: Color(0xFFFFE5D6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () => _reorder(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: const Color(0xFFFC6011),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Đặt lại',
                      style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
