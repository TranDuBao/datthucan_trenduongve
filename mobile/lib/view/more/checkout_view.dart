import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_toast.dart';
import 'checkout_message_view.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  List paymentArr = [
    {"name": "Thanh toán qua VietQR / PayOS", "icon": "assets/img/cash.png", "code": "PAYOS"},
    {"name": "Ví điện tử MoMo", "icon": "assets/img/visa_icon.png", "code": "MOMO"},
    {"name": "Thanh toán tại quán khi lấy", "icon": "assets/img/paypal.png", "code": "COD"},
  ];

  int selectMethod = 0;
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final pickupDateTime = cart.combinedPickupDateTime;
    final timeStr = "${pickupDateTime.hour.toString().padLeft(2, '0')}:${pickupDateTime.minute.toString().padLeft(2, '0')} - ${pickupDateTime.day}/${pickupDateTime.month}/${pickupDateTime.year}";

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

              // Pickup Restaurant Address Card
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded, color: TColor.primary, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Địa điểm nhà hàng (Tự đến lấy)",
                          style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TColor.cardOf(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TColor.borderOf(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cart.restaurantName,
                            style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cart.restaurantAddress,
                            style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

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
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: paymentArr.length,
                      itemBuilder: (context, index) {
                        var pObj = paymentArr[index] as Map? ?? {};
                        bool isSelected = selectMethod == index;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          decoration: BoxDecoration(
                            color: TColor.cardOf(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? TColor.primary : TColor.borderOf(context), width: isSelected ? 1.5 : 1),
                          ),
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                selectMethod = index;
                              });
                            },
                            title: Text(
                              pObj["name"].toString(),
                              style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            leading: Icon(
                              index == 0 ? Icons.qr_code_2_rounded : (index == 1 ? Icons.account_balance_wallet_rounded : Icons.payments_rounded),
                              color: isSelected ? TColor.primary : TColor.secondaryTextOf(context),
                            ),
                            trailing: Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: TColor.primary,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
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
                        Text(
                          "${cart.subTotal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                          style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Phí giao hàng", style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13)),
                        const Text("0đ (Khách tự đến lấy)", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: TColor.borderOf(context), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tổng thanh toán", style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 15, fontWeight: FontWeight.w800)),
                        Text(
                          "${cart.total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                          style: TextStyle(color: TColor.primary, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
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
                        onPressed: () async {
                          setState(() => isSubmitting = true);
                          final methodCode = paymentArr[selectMethod]["code"];

                          final res = await OrderService.createPreOrder(
                            restaurantId: cart.restaurantId,
                            pickupTime: cart.combinedPickupDateTime,
                            items: cart.items,
                            totalAmount: cart.total,
                            paymentMethod: methodCode,
                          );

                          if (mounted) {
                            setState(() => isSubmitting = false);
                            if (res['success'] == true) {
                              final orderData = res['data'];
                              cart.clearCart();

                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (context) {
                                  return CheckoutMessageView(orderData: orderData);
                                },
                              );
                            } else {
                              CustomToast.showError(
                                context,
                                res['message'] ?? 'Đặt món thất bại. Vui lòng thử lại!',
                              );
                            }
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
