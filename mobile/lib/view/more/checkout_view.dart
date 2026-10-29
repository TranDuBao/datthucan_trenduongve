import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/map_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/vietqr_payment_modal.dart';
import '../../widgets/payment_success_modal.dart';
import '../../common_widget/smart_network_image.dart';
import 'checkout_message_view.dart';
import 'order_history_view.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final List<Map<String, String>> paymentArr = [
    {"name": "Thanh toán qua VietQR / PayOS", "code": "PAYOS"},
  ];

  int selectMethod = 0;
  bool isSubmitting = false;

  String _fmt(int v) => v
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final pickupDateTime = cart.combinedPickupDateTime;
    final timeStr = "${pickupDateTime.hour.toString().padLeft(2, '0')}:${pickupDateTime.minute.toString().padLeft(2, '0')} - ${pickupDateTime.day}/${pickupDateTime.month}/${pickupDateTime.year}";
    final restaurantIds = cart.restaurantIds;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 46),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryTextOf(context), size: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Xác nhận đơn Pre-Order",
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Danh sách quán trong đơn & món ăn ──
              ...restaurantIds.map((resId) {
                final resName = cart.restaurantName(resId);
                final resAddress = cart.restaurantAddress(resId);
                final resItems = cart.itemsForRestaurant(resId);
                final subTotal = cart.subTotalForRestaurant(resId).toInt();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TColor.cardOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TColor.borderOf(context)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header quán
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: TColor.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.storefront_rounded, color: TColor.primary, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: TColor.primaryTextOf(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (resAddress.isNotEmpty) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      resAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: TColor.secondaryTextOf(context),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${_fmt(subTotal)}đ",
                              style: TextStyle(
                                color: TColor.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: TColor.borderOf(context), height: 1),
                        const SizedBox(height: 8),

                        // Danh sách món ăn của quán này với hình ảnh trực quan
                        ...resItems.map((item) {
                          final itemTotal = (item.price * item.quantity).toInt();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SmartNetworkImage(
                                    imageUrl: item.image,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.foodName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: TColor.primaryTextOf(context),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "x${item.quantity}  •  ${_fmt(item.price.toInt())}đ",
                                        style: TextStyle(
                                          color: TColor.secondaryTextOf(context),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "${_fmt(itemTotal)}đ",
                                  style: TextStyle(
                                    color: TColor.primaryTextOf(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),

              // Selected Pickup Time Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.alarm_on_rounded, color: TColor.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Giờ hẹn nhận món",
                          style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TColor.primary.withOpacity(0.4)),
                      ),
                      child: Text(
                        timeStr,
                        style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Container(decoration: BoxDecoration(color: TColor.borderOf(context).withOpacity(0.3)), height: 8),

              // Payment Method Selection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Phương thức thanh toán",
                      style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(paymentArr.length, (index) {
                      final pObj = paymentArr[index];
                      final isSelected = selectMethod == index;
                      return GestureDetector(
                        onTap: () => setState(() => selectMethod = index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: TColor.cardOf(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? TColor.primary : TColor.borderOf(context),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                index == 0 ? Icons.qr_code_2_rounded : Icons.payments_rounded,
                                color: isSelected ? TColor.primary : TColor.secondaryTextOf(context),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(pObj["name"]!,
                                  style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w600))),
                              Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: TColor.primary, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              Container(decoration: BoxDecoration(color: TColor.borderOf(context).withOpacity(0.3)), height: 8),

              // Order Total Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tiền món ăn", style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13)),
                        Text("${_fmt(cart.subTotal.toInt())}đ",
                            style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (cart.discountAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(children: [
                            const Icon(Icons.confirmation_number_rounded, color: Color(0xFF10B981), size: 14),
                            const SizedBox(width: 4),
                            Text("Giảm giá (${cart.appliedVoucherCode})",
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w700)),
                          ]),
                          Text("-${_fmt(cart.discountAmount.toInt())}đ",
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Phí giao hàng", style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13)),
                        const Text("0đ (Tự đến lấy)", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: TColor.borderOf(context), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tổng thanh toán", style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 15, fontWeight: FontWeight.w800)),
                        Text("${_fmt(cart.total.toInt())}đ",
                            style: TextStyle(color: TColor.primary, fontSize: 20, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
                child: isSubmitting
                    ? Center(child: CircularProgressIndicator(color: TColor.primary))
                    : RoundButton(
                        title: "Hoàn tất đặt món",
                        onPressed: _handlePlaceOrders,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tách đơn theo quán → gọi API song song → hiển thị kết quả lần lượt.
  Future<void> _handlePlaceOrders() async {
    final cart = context.read<CartProvider>();
    final mapProvider = context.read<MapProvider>();
    final methodCode = paymentArr[selectMethod]["code"]!;
    final restaurantIds = cart.restaurantIds;
    if (restaurantIds.isEmpty) return;

    setState(() => isSubmitting = true);

    // Gọi API song song — mỗi quán tạo 1 đơn riêng
    final futures = restaurantIds.asMap().entries.map((entry) {
      final resId = entry.value;
      final resItems = cart.itemsForRestaurant(resId);
      final resSubTotal = cart.subTotalForRestaurant(resId);
      // Voucher chỉ áp dụng cho quán đầu tiên
      final isFirst = entry.key == 0;
      final discount = isFirst ? cart.discountAmount : 0.0;
      final finalTotal = (resSubTotal - discount).clamp(0.0, double.infinity);

      return OrderService.createPreOrder(
        restaurantId: resId,
        pickupTime: cart.combinedPickupDateTime,
        items: resItems,
        totalAmount: finalTotal,
        paymentMethod: methodCode,
        voucherCode: isFirst ? cart.appliedVoucherCode : null,
        voucherId: isFirst ? cart.appliedVoucherId : null,
      );
    }).toList();

    final results = await Future.wait(futures);

    if (!mounted) return;
    setState(() => isSubmitting = false);

    final successOrders = <Map<String, dynamic>>[];
    final failMessages = <String>[];

    for (int i = 0; i < results.length; i++) {
      if (results[i]['success'] == true) {
        successOrders.add(results[i]['data'] as Map<String, dynamic>);
      } else {
        final resName = cart.restaurantName(restaurantIds[i]);
        failMessages.add("$resName: ${results[i]['message'] ?? 'Thất bại'}");
      }
    }

    if (successOrders.isNotEmpty) {
      try {
        mapProvider.setActiveStopoverOrder(successOrders.first);
      } catch (_) {}
      cart.clearCart();
      if (failMessages.isNotEmpty && mounted) {
        CustomToast.showError(context,
            "Đặt thành công một số quán. Thất bại:\n${failMessages.join('\n')}");
      }
      _showOrderResults(successOrders);
    } else {
      final msg = failMessages.isNotEmpty
          ? failMessages.first
          : 'Đặt món thất bại. Vui lòng thử lại!';
      CustomToast.showError(context, msg);
    }
  }

  void _showOrderResults(List<Map<String, dynamic>> orders) {
    if (!mounted || orders.isEmpty) return;
    final orderData = orders.first;
    final remaining = orders.skip(1).toList();
    final payment = orderData['payment'];
    final hasQr = payment != null &&
        payment['qrUrl'] != null &&
        payment['qrUrl'].toString().isNotEmpty;

    void showNext() => _showOrderResults(remaining);

    void showSuccessModal([Map<String, dynamic>? updatedData]) async {
      final finalOrderData = {
        ...orderData,
        if (updatedData != null) ...updatedData,
      };

      final action = await PaymentSuccessModal.show(
        context: context,
        orderData: finalOrderData,
      );

      if (!mounted) return;

      if (remaining.isNotEmpty) {
        showNext();
        return;
      }

      if (action == PaymentSuccessAction.viewOrder) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OrderHistoryView()),
          (route) => route.isFirst,
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }

    void showFallbackSuccessSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => CheckoutMessageView(orderData: orderData),
      ).then((_) => showNext());
    }

    if (hasQr) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => VietQRPaymentModal(
          orderData: orderData,
          onPaymentSuccess: (verified) => showSuccessModal(verified),
        ),
      );
    } else {
      showFallbackSuccessSheet();
    }
  }
}
