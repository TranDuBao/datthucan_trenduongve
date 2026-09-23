import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../widgets/custom_toast.dart';
import 'checkout_view.dart';

class MyOrderView extends StatefulWidget {
  const MyOrderView({super.key});

  @override
  State<MyOrderView> createState() => _MyOrderViewState();
}

class _MyOrderViewState extends State<MyOrderView> {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

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
                        "Giỏ hàng & Đặt trước",
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

              // Restaurant Info Card
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TColor.cardOf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TColor.borderOf(context), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: TColor.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.storefront_rounded, color: TColor.primary, size: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cart.restaurantName,
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, color: TColor.primary, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    cart.restaurantAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: TColor.secondaryTextOf(context),
                                      fontSize: 12,
                                    ),
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

              // Pickup Time Selector Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TColor.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TColor.primary.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time_filled_rounded, color: TColor.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            "Chọn thời gian tự đến lấy (Pickup Time)",
                            style: TextStyle(
                              color: TColor.primaryTextOf(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Date Picker Button
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: cart.selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 7)),
                                );
                                if (pickedDate != null) {
                                  cart.setPickupDate(pickedDate);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: TColor.cardOf(context),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: TColor.borderOf(context)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${cart.selectedDate.day}/${cart.selectedDate.month}/${cart.selectedDate.year}",
                                      style: TextStyle(color: TColor.primaryTextOf(context), fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Icon(Icons.calendar_month_rounded, size: 16, color: TColor.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Time Picker Button
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: cart.selectedTime,
                                );
                                if (pickedTime != null) {
                                  cart.setPickupTime(pickedTime);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: TColor.cardOf(context),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: TColor.borderOf(context)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${cart.selectedTime.hour.toString().padLeft(2, '0')}:${cart.selectedTime.minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(color: TColor.primaryTextOf(context), fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Icon(Icons.schedule_rounded, size: 16, color: TColor.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "* Món ăn sẽ được nhà hàng chuẩn bị sẵn sàng vào thời điểm trên.",
                        style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Cart Items List
              cart.items.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          "Giỏ hàng chưa có món nào.\nHãy chọn món ăn từ menu quán!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 14),
                        ),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: TColor.cardOf(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TColor.borderOf(context), width: 1),
                      ),
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) => Divider(
                          color: TColor.borderOf(context),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          var item = cart.items[index];
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          final itemPrice = item.price.toInt();
                          final itemTotal = (item.price * item.quantity).toInt();

                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // 1. Food Image Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: item.image.toString().startsWith("http")
                                      ? Image.network(
                                          item.image.toString(),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 60,
                                            height: 60,
                                            color: TColor.primary.withOpacity(0.12),
                                            child: Icon(Icons.fastfood_rounded, color: TColor.primary, size: 28),
                                          ),
                                        )
                                      : Image.asset(
                                          item.image.toString(),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            width: 60,
                                            height: 60,
                                            color: TColor.primary.withOpacity(0.12),
                                            child: Icon(Icons.fastfood_rounded, color: TColor.primary, size: 28),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),

                                // 2. Food Info & Price
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
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${itemPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                        style: TextStyle(
                                          color: TColor.secondaryTextOf(context),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${itemTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                        style: TextStyle(
                                          color: TColor.primary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // 3. Modern Increment / Decrement Quantity Controls
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: TColor.borderOf(context), width: 1),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () {
                                          cart.updateQuantity(item.foodId, -1);
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
                                            ],
                                          ),
                                          child: Icon(
                                            item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                                            size: 16,
                                            color: item.quantity == 1 ? const Color(0xFFD32F2F) : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          "${item.quantity}",
                                          style: TextStyle(
                                            color: TColor.primaryTextOf(context),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () {
                                          cart.updateQuantity(item.foodId, 1);
                                        },
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFC6011),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

              const SizedBox(height: 20),

              // Summary Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Tiền món", style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13)),
                        Text(
                          "${cart.subTotal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                          style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                        Text(
                          "${cart.total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                          style: TextStyle(color: TColor.primary, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    RoundButton(
                      title: "Xác nhận đặt món & Thanh toán",
                      onPressed: () {
                        if (cart.items.isEmpty) {
                          CustomToast.showError(context, "Giỏ hàng của bạn đang trống!");
                          return;
                        }

                        if (!cart.isPickupTimeValid()) {
                          CustomToast.showError(context, "Thời gian hẹn lấy phải cách hiện tại ít nhất 5 phút!");
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutView(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
