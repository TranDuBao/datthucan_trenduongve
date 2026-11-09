import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';
import '../../services/category_service.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/order_progress_stepper.dart';
import '../main_tabview/main_tabview.dart';
import '../../common_widget/smart_network_image.dart';
import '../../services/order_route_storage.dart';
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
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12141C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Chi tiết đơn #DH${currentOrder.orderId}',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF101828),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(10),
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
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2230) : const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 11,
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
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF2F4F7)),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Progress tracker / Cancellation & Refund card
                  if (isCancelled)
                    _buildCard(
                      isDark: isDark,
                      borderColor: currentOrder.refundStatus == 'HOAN_TIEN_THANH_CONG'
                          ? const Color(0xFF6CE9A6)
                          : const Color(0xFFFDA29B),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: currentOrder.refundStatus == 'HOAN_TIEN_THANH_CONG'
                                      ? (isDark ? const Color(0xFF0F291E) : const Color(0xFFECFDF3))
                                      : (isDark ? const Color(0xFF2E1715) : const Color(0xFFFEF3F2)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  currentOrder.refundStatus == 'HOAN_TIEN_THANH_CONG'
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.cancel_outlined,
                                  color: currentOrder.refundStatus == 'HOAN_TIEN_THANH_CONG'
                                      ? const Color(0xFF027A48)
                                      : const Color(0xFFD92D20),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Đơn hàng đã hủy',
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF101828),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentOrder.refundStatus != null
                                          ? 'Chính sách hoàn tiền tự động 100%'
                                          : 'Đơn hàng không phát sinh thanh toán',
                                      style: TextStyle(
                                        color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (currentOrder.refundStatus != null) ...[
                            const SizedBox(height: 14),
                            Divider(
                              height: 1,
                              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF2F4F7),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Trạng thái hoàn tiền:',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                                    fontSize: 13,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: currentOrder.refundStatus == 'HOAN_TIEN_THANH_CONG'
                                        ? const Color(0xFFECFDF3)
                                        : const Color(0xFFFFF6ED),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    currentOrder.refundStatus == 'HOAN_TIEN_THANH_CONG'
                                        ? 'Hoàn tiền thành công'
                                        : (currentOrder.refundStatus == 'DANG_XU_LY'
                                            ? 'Đang chuyển khoản hoàn tiền'
                                            : 'Chờ duyệt hoàn tiền'),
                                    style: TextStyle(
                                      color: currentOrder.refundStatus == 'HOAN_TIEN_THANH_CONG'
                                          ? const Color(0xFF027A48)
                                          : const Color(0xFFB54708),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Số tiền hoàn:',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  formatOrderTotal(currentOrder.refundAmount ?? currentOrder.totalAmount),
                                  style: const TextStyle(
                                    color: Color(0xFFFC6011),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    )
                  else
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
                                  onPressed: () {
                                    final phone = currentOrder.restaurantPhone.isNotEmpty
                                        ? currentOrder.restaurantPhone
                                        : '0909998877';
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                        title: Row(
                                          children: [
                                            const Icon(Icons.call_rounded, color: Color(0xFFFC6011), size: 22),
                                            const SizedBox(width: 8),
                                            const Text('Liên hệ nhà hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        content: Text(
                                          'Số điện thoại của ${currentOrder.restaurantName}:\n$phone',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFC6011),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              CustomToast.showSuccess(context, 'Đang kết nối cuộc gọi tới $phone...');
                                            },
                                            child: const Text('Gọi ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
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
                                  onPressed: () async {
                                    // 1. Tìm tọa độ điểm đến của quán
                                    double? sLat = currentOrder.lat;
                                    double? sLng = currentOrder.lng;

                                    if (sLat == null || sLng == null) {
                                      try {
                                        final stores = await CategoryService.fetchRestaurantsFromDB();
                                        final matched = stores.firstWhere(
                                          (s) => s['maQuan'] == currentOrder.restaurantId || s['tenQuan'] == currentOrder.restaurantName,
                                          orElse: () => null,
                                        );
                                        if (matched != null) {
                                          sLat = (matched['lat'] as num?)?.toDouble();
                                          sLng = (matched['lng'] as num?)?.toDouble();
                                        }
                                      } catch (_) {}
                                    }

                                    // Tọa độ mặc định an toàn nếu chưa cập nhật GPS quán
                                    sLat ??= 10.7812;
                                    sLng ??= 106.6985;

                                    final storePos = LatLng(sLat, sLng);

                                    // 2. Đóng bottom sheet
                                    Navigator.pop(context);

                                    // 3. Chuyển Tab về Home Map (Tab 2)
                                    MainTabView.switchTab(context, 2);

                                    // 4. Kích hoạt tính năng Dẫn đường trên MapProvider khôi phục cả 2 chặng
                                    final mapProvider = Provider.of<MapProvider>(context, listen: false);
                                    final routeInfo = await OrderRouteStorage.getOrderRoute(currentOrder.orderId);
                                    await mapProvider.navigateToOrderStore(
                                      orderId: currentOrder.orderId,
                                      storeName: currentOrder.restaurantName,
                                      storeAddress: currentOrder.restaurantAddress,
                                      storeLatLng: storePos,
                                      destinationLatLng: routeInfo != null ? LatLng(routeInfo.destLat, routeInfo.destLng) : null,
                                      destinationName: routeInfo?.destName,
                                      destinationAddress: routeInfo?.destAddress,
                                      pickupTime: currentOrder.pickupTime,
                                      status: currentOrder.status,
                                    );

                                    CustomToast.showSuccess(context, "Đang dẫn đường đến ${currentOrder.restaurantName}");
                                  },
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
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SmartNetworkImage(
                                    imageUrl: (item['img'] ?? item['image'] ?? item['hinhAnh'] ?? '').toString(),
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(12),
                                    placeholderIcon: Icons.lunch_dining_rounded,
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
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                currentOrder.paymentMethod.toUpperCase() == 'MOMO'
                                    ? 'Ví MoMo'
                                    : 'VietQR / PayOS',
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF00A86B),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
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
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF101828),
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
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
