import 'package:flutter/material.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import '../../common/color_extension.dart';
import '../../view/main_tabview/main_tabview.dart';
import '../../view/more/order_history_view.dart';

class CheckoutMessageView extends StatefulWidget {
  final Map<String, dynamic>? orderData;
  const CheckoutMessageView({super.key, this.orderData});

  @override
  State<CheckoutMessageView> createState() => _CheckoutMessageViewState();
}

class _CheckoutMessageViewState extends State<CheckoutMessageView> {
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);
    final orderId = widget.orderData?['orderId'] ?? widget.orderData?['maDonHang'] ?? 1;
    final pickupTimeRaw = widget.orderData?['pickupTime'] ?? widget.orderData?['thoiGianHenNhan'] ?? '';

    String formattedPickupTime = 'Đúng giờ hẹn';
    if (pickupTimeRaw.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(pickupTimeRaw.toString());
        formattedPickupTime = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ngày ${dt.day}/${dt.month}/${dt.year}";
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
      width: media.width,
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: TColor.primaryTextOf(context),
                  size: 25,
                ),
              )
            ],
          ),
          Image.asset(
            "assets/img/thank_you.png",
            width: media.width * 0.5,
          ),
          const SizedBox(height: 20),
          Text(
            "Đặt hàng thành công!",
            style: TextStyle(
              color: TColor.primaryTextOf(context),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Mã đơn hàng: #PRE-$orderId",
            style: TextStyle(
              color: TColor.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TColor.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TColor.primary.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alarm_on_rounded, color: TColor.primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      "Giờ hẹn tự đến lấy:",
                      style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formattedPickupTime,
                  style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Đơn hàng của bạn đã được gửi tới nhà hàng. Quán sẽ bắt đầu chế biến để sẵn sàng đúng giờ hẹn của bạn!",
            textAlign: TextAlign.center,
            style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 25),
          RoundButton(
            title: "Trở về Trang chủ",
            onPressed: () {
              final mainTab = context.findAncestorStateOfType<MainTabViewState>();
              if (mainTab != null) {
                Navigator.of(context).popUntil((r) => r.isFirst);
                mainTab.changeTab(2, popToRoot: true);
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainTabView()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          // Nút phụ: đi thẳng đến màn hình đơn hàng để xem tiến trình
          GestureDetector(
            onTap: () {
              final mainTab = context.findAncestorStateOfType<MainTabViewState>();
              if (mainTab != null) {
                Navigator.of(context).popUntil((r) => r.isFirst);
                mainTab.pushToTab(4, const OrderHistoryView());
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainTabView()),
                  (route) => false,
                ).then((_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderHistoryView()),
                  );
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: TColor.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Xem đơn hàng của tôi",
                    style: TextStyle(
                      color: TColor.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
