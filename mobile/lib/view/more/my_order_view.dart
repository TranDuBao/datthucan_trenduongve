import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/customer_voucher_modal.dart';
import '../../widgets/custom_date_picker_sheet.dart';
import '../../widgets/custom_time_picker_sheet.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 46),
              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: TColor.primaryTextOf(context),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Giỏ hàng & Đặt trước",
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (cart.items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: TColor.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${cart.totalItemCount} món",
                          style: TextStyle(
                            color: TColor.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Modernized Pickup Time Selector Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B1E28) : const Color(0xFFFFF4EE),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2C3240) : const Color(0xFFFFE5D6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TColor.primary.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: TColor.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.access_time_filled_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "Thời gian tự đến lấy (Pickup Time)",
                            style: TextStyle(
                              color: TColor.primaryTextOf(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Date Picker Selector Button
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                CustomDatePickerSheet.show(
                                  context: context,
                                  initialDate: cart.selectedDate,
                                  onDateSelected: (pickedDate) {
                                    cart.setPickupDate(pickedDate);
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 11, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: TColor.cardOf(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: TColor.borderOf(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${cart.selectedDate.day}/${cart.selectedDate.month}/${cart.selectedDate.year}",
                                      style: TextStyle(
                                        color: TColor.primaryTextOf(context),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_month_rounded,
                                      size: 18,
                                      color: TColor.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Time Picker Selector Button
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                CustomTimePickerSheet.show(
                                  context: context,
                                  initialTime: cart.selectedTime,
                                  selectedDate: cart.selectedDate,
                                  onTimeSelected: (pickedTime) {
                                    cart.setPickupTime(pickedTime);
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 11, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: TColor.cardOf(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: TColor.borderOf(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${cart.selectedTime.hour.toString().padLeft(2, '0')}:${cart.selectedTime.minute.toString().padLeft(2, '0')}",
                                      style: TextStyle(
                                        color: TColor.primaryTextOf(context),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 18,
                                      color: TColor.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: TColor.secondaryTextOf(context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Món ăn sẽ được nhà hàng chuẩn bị sẵn sàng vào thời điểm trên.",
                              style: TextStyle(
                                color: TColor.secondaryTextOf(context),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cart Items List / Empty State
              cart.items.isEmpty
                  ? _buildEmptyCartView(context, isDark)
                  : _buildCartItemsList(cart, isDark),

              const SizedBox(height: 16),

              // Voucher Selection Tile
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => const CustomerVoucherModal(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TColor.cardOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cart.appliedVoucherCode != null
                            ? const Color(0xFF10B981)
                            : TColor.borderOf(context),
                        width: cart.appliedVoucherCode != null ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cart.appliedVoucherCode != null
                                    ? const Color(0xFF10B981).withOpacity(0.12)
                                    : TColor.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.confirmation_number_rounded,
                                color: cart.appliedVoucherCode != null
                                    ? const Color(0xFF10B981)
                                    : TColor.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cart.appliedVoucherCode != null
                                      ? "Voucher: ${cart.appliedVoucherCode}"
                                      : "Chọn hoặc nhập mã Voucher",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: cart.appliedVoucherCode != null
                                        ? const Color(0xFF10B981)
                                        : TColor.primaryTextOf(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cart.appliedVoucherCode != null
                                      ? "Đã giảm -${cart.discountAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ"
                                      : "Giảm tiền trực tiếp cho đơn pre-order",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: TColor.secondaryTextOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: TColor.secondaryTextOf(context),
                        ),
                      ],
                    ),
                  ),
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
                        Text(
                          "Tiền món",
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "${cart.subTotal.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (cart.discountAmount > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.confirmation_number_rounded,
                                color: Color(0xFF10B981),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Giảm giá Voucher (${cart.appliedVoucherCode})",
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "-${cart.discountAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Phí giao hàng",
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          "0đ (Tự đến lấy)",
                          style: TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: TColor.borderOf(context), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tổng thanh toán",
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "${cart.total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                          style: TextStyle(
                            color: TColor.primary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    RoundButton(
                      title: "Xác nhận đặt món & Thanh toán",
                      onPressed: () {
                        if (cart.items.isEmpty) {
                          CustomToast.showError(
                              context, "Giỏ hàng của bạn đang trống!");
                          return;
                        }

                        if (!cart.isPickupTimeValid()) {
                          CustomToast.showError(context,
                              "Thời gian hẹn lấy phải cách hiện tại ít nhất 5 phút!");
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

  Widget _buildEmptyCartView(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context), width: 1),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: TColor.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                color: TColor.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Giỏ hàng chưa có món nào",
              style: TextStyle(
                color: TColor.primaryTextOf(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Hãy chọn các món ăn ưa thích từ thực đơn để thêm vào giỏ hàng pre-order!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TColor.secondaryTextOf(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsList(CartProvider cart, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          final itemPrice = item.price.toInt();
          final itemTotal = (item.price * item.quantity).toInt();

          return Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // 1. Food Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: item.image.toString().startsWith("http")
                      ? Image.network(
                          item.image.toString(),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: TColor.primary.withOpacity(0.12),
                            child: Icon(Icons.fastfood_rounded,
                                color: TColor.primary, size: 28),
                          ),
                        )
                      : Image.asset(
                          item.image.toString(),
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 64,
                            height: 64,
                            color: TColor.primary.withOpacity(0.12),
                            child: Icon(Icons.fastfood_rounded,
                                color: TColor.primary, size: 28),
                          ),
                        ),
                ),
                const SizedBox(width: 14),

                // 2. Info & Price
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
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Modern Quantity Selector
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C3240)
                        : const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: TColor.borderOf(context), width: 1),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            item.quantity == 1
                                ? Icons.delete_outline_rounded
                                : Icons.remove_rounded,
                            size: 16,
                            color: item.quantity == 1
                                ? const Color(0xFFD32F2F)
                                : Colors.black87,
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
                          child: const Icon(Icons.add_rounded,
                              size: 16, color: Colors.white),
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
    );
  }
}
