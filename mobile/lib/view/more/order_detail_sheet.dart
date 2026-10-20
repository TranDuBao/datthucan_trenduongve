import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../widgets/order_progress_stepper.dart';
import 'order_history_widgets.dart';

/// Displays the full order detail as a bottom sheet.
/// [ordersList] is the live list so real-time updates are reflected.
/// [onCancelOrder] is called when the user taps "Hủy đơn" inside the sheet.
/// [onNavigateToItem] navigates to the food item details view.
void showOrderDetailSheet({
  required BuildContext context,
  required OrderServiceModel order,
  required List<OrderServiceModel> ordersList,
  required bool isDark,
  required void Function(StateSetter setState) setActiveSheetState,
  required VoidCallback clearActiveSheetState,
  required void Function(OrderServiceModel) onCancelOrder,
  required void Function(dynamic item, OrderServiceModel order) onNavigateToItem,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          setActiveSheetState(setSheetState);

          final currentOrder = ordersList.firstWhere(
            (o) => o.orderId == order.orderId,
            orElse: () => order,
          );

          final stepNum = OrderProgressStepper.getStepFromStatus(currentOrder.status);
          final formattedTotal = formatOrderTotal(currentOrder.totalAmount);
          final isCancelled = OrderProgressStepper.isCancelledStatus(currentOrder.status);

          String headerBadgeText = 'Chờ quán nhận';
          if (isCancelled) {
            headerBadgeText = 'Đã hủy đơn';
          } else {
            if (stepNum == 2) headerBadgeText = 'Quán đã nhận';
            if (stepNum == 3) headerBadgeText = 'Đang làm món';
            if (stepNum == 4) headerBadgeText = 'Chờ ghé lấy';
            if (stepNum == 5) headerBadgeText = 'Đã lấy hàng';
          }

          return _OrderDetailSheetContent(
            currentOrder: currentOrder,
            stepNum: stepNum,
            formattedTotal: formattedTotal,
            isCancelled: isCancelled,
            headerBadgeText: headerBadgeText,
            isDark: isDark,
            onCancelOrder: onCancelOrder,
            onNavigateToItem: onNavigateToItem,
          );
        },
      );
    },
  ).whenComplete(clearActiveSheetState);
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sheet content widget
// ─────────────────────────────────────────────────────────────────────────────
class _OrderDetailSheetContent extends StatelessWidget {
  final OrderServiceModel currentOrder;
  final int stepNum;
  final String formattedTotal;
  final bool isCancelled;
  final String headerBadgeText;
  final bool isDark;
  final void Function(OrderServiceModel) onCancelOrder;
  final void Function(dynamic item, OrderServiceModel order) onNavigateToItem;

  const _OrderDetailSheetContent({
    required this.currentOrder,
    required this.stepNum,
    required this.formattedTotal,
    required this.isCancelled,
    required this.headerBadgeText,
    required this.isDark,
    required this.onCancelOrder,
    required this.onNavigateToItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12141C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Chi tiết đơn #DH${currentOrder.orderId}',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF101828),
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFE5A3)),
                      ),
                      child: Text(
                        '● $headerBadgeText',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6011),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Tự ghé lấy trên lộ trình về • Đặt lúc '
                    '${currentOrder.createdAt.length > 16 ? currentOrder.createdAt.substring(11, 16) : ''}'
                    ', ${currentOrder.createdAt.length > 10 ? currentOrder.createdAt.substring(0, 10) : ''}',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF707688) : const Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF2F4F7)),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Progress tracker
                  _buildCard(
                    isDark: isDark,
                    borderColor: isDark ? const Color(0xFF2C3240) : const Color(0xFFFFF0EA),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tiến độ lấy món',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF101828),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Bước $stepNum/5',
                              style: const TextStyle(
                                color: Color(0xFFFC6011),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OrderFiveStepStepper(currentStep: stepNum, isDark: isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Store info
                  _buildCard(
                    isDark: isDark,
                    borderColor: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF4EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.home_outlined, color: Color(0xFFFC6011), size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentOrder.restaurantName,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF101828),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Điểm lấy món',
                                      style: TextStyle(
                                        color: Color(0xFF00A86B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (currentOrder.restaurantAddress.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            currentOrder.restaurantAddress,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.call_outlined, color: Color(0xFFFC6011), size: 16),
                                  label: const Text(
                                    'Gọi quán',
                                    style: TextStyle(
                                      color: Color(0xFF344054),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                      color: isDark ? const Color(0xFF3B4052) : const Color(0xFFE4E7EC),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.near_me_outlined, color: Color(0xFFFC6011), size: 16),
                                  label: const Text(
                                    'Dẫn đường',
                                    style: TextStyle(
                                      color: Color(0xFFFC6011),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFF4EE),
                                    side: const BorderSide(color: Color(0xFFFFE5D6)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Items list
                  _buildCard(
                    isDark: isDark,
                    borderColor: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MÓN ĂN ĐÃ ĐẶT (${currentOrder.items.length} MÓN)',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...currentOrder.items.map((item) {
                          final name = item['tenMonAn'] ?? item['foodName'] ?? item['name'] ?? 'Món ăn';
                          final qty = item['soLuong'] ?? item['quantity'] ?? 1;
                          final price = (item['gia'] ?? item['price'] ?? 0).toDouble();
                          final itemTotal = (price * qty).toInt();
                          final formattedItemTotal =
                              '${itemTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF4EE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.lunch_dining_rounded,
                                    color: Color(0xFFFC6011),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$qty × $name',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : const Color(0xFF101828),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF3),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Đóng gói mang về',
                                              style: TextStyle(
                                                color: Color(0xFF00A86B),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Navigator.pop(context);
                                              onNavigateToItem(item, currentOrder);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFF4EE),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFFE5D6)),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Đi đến sản phẩm',
                                                    style: TextStyle(
                                                      color: Color(0xFFFC6011),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                  SizedBox(width: 2),
                                                  Icon(Icons.arrow_forward_ios_rounded,
                                                      color: Color(0xFFFC6011), size: 9),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  formattedItemTotal,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF101828),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. Payment summary
                  _buildCard(
                    isDark: isDark,
                    borderColor: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHI TIẾT THANH TOÁN',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _paymentRow(
                          label: 'Tiền món ăn',
                          value: formattedTotal,
                          isDark: isDark,
                          isBold: false,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hình thức thanh toán',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                                fontSize: 13,
                              ),
                            ),
                            const Text(
                              'Tiền mặt khi nhận hàng',
                              style: TextStyle(
                                color: Color(0xFF00A86B),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tổng thanh toán',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF101828),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              formattedTotal,
                              style: const TextStyle(
                                color: Color(0xFFFC6011),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1E28) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
                ),
              ),
            ),
            child: Row(
              children: [
                if (stepNum >= 1 && stepNum <= 2 && !isCancelled) ...[
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onCancelOrder(currentOrder);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? const Color(0xFF3B4052) : const Color(0xFFFFD4D4),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Hủy đơn',
                          style: TextStyle(color: Color(0xFFD92D20), fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6011),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow({
    required String label,
    required String value,
    required bool isDark,
    required bool isBold,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF101828),
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card decoration helper
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildCard({
  required bool isDark,
  required Color borderColor,
  required Widget child,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1B1E28) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: borderColor, width: 1.2),
    ),
    child: child,
  );
}
