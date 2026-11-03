import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/smart_network_image.dart';
import '../../providers/map_provider.dart';
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
    final media = MediaQuery.sizeOf(context);
    final orderId = widget.orderData?['orderId'] ?? widget.orderData?['maDonHang'] ?? 1;
    final storeName = widget.orderData?['restaurantName'] ?? widget.orderData?['tenQuan'] ?? 'Nhà hàng';
    final storeAddress = widget.orderData?['restaurantAddress'] ?? widget.orderData?['diaChi'] ?? 'Địa chỉ tự đến lấy';
    final double? storeLat = (widget.orderData?['lat'] as num?)?.toDouble();
    final double? storeLng = (widget.orderData?['lng'] as num?)?.toDouble();

    final pickupTimeRaw = widget.orderData?['pickupTime'] ?? widget.orderData?['thoiGianHenNhan'] ?? '';
    final totalAmount = (widget.orderData?['tongTien'] ?? widget.orderData?['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final statusRaw = (widget.orderData?['status'] ?? widget.orderData?['trangThai'] ?? 'PENDING').toString();

    final items = (widget.orderData?['items'] as List?) ?? [];

    String formattedPickupTime = 'Đúng giờ hẹn';
    if (pickupTimeRaw.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(pickupTimeRaw.toString());
        formattedPickupTime = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ngày ${dt.day}/${dt.month}/${dt.year}";
      } catch (_) {}
    }

    String statusText = 'Chờ quán xác nhận';
    if (statusRaw.toUpperCase() == 'PENDING') {
      statusText = 'Chờ quán xác nhận';
    } else if (statusRaw.toUpperCase() == 'CONFIRMED' || statusRaw.toUpperCase() == 'ACCEPTED') {
      statusText = 'Quán đã xác nhận';
    } else if (statusRaw.toUpperCase() == 'PREPARING') {
      statusText = 'Đang chuẩn bị món';
    } else if (statusRaw.toUpperCase() == 'READY_FOR_PICKUP') {
      statusText = 'Chờ ghé lấy';
    }

    final isPaid = widget.orderData?['payment']?['trangThai'] == 'DA_THANH_TOAN' ||
        widget.orderData?['trangThai'] == 'CHO_XAC_NHAN' ||
        widget.orderData?['trangThai'] == 'DA_XAC_NHAN';
    final paymentStatusText = isPaid
        ? 'Đã thanh toán Online (VietQR)'
        : 'Chờ thanh toán';

    return Container(
      constraints: BoxConstraints(maxHeight: media.height * 0.9),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
      width: media.width,
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đơn đặt trước #$orderId',
                  style: GoogleFonts.outfit(
                    color: TColor.primaryTextOf(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: TColor.primaryTextOf(context), size: 24),
                ),
              ],
            ),
            Image.asset("assets/img/thank_you.png", width: media.width * 0.35),
            const SizedBox(height: 10),
            Text(
              "Đặt trước thành công!",
              style: TextStyle(
                color: TColor.primaryTextOf(context),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Quán sẽ chuẩn bị để sẵn sàng đúng giờ hẹn của bạn",
              textAlign: TextAlign.center,
              style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 12),
            ),
            const SizedBox(height: 14),

            // ── THÔNG TIN QUÁN & ĐỊA ĐIỂM GHÉ LẤY ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TColor.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TColor.primary.withValues(alpha: 0.25)),
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
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          storeName,
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    storeAddress,
                    style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 14),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: TColor.primary, size: 15),
                      const SizedBox(width: 5),
                      Text("Hẹn lấy: ", style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context))),
                      Expanded(
                        child: Text(
                          formattedPickupTime,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TColor.primaryTextOf(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 15),
                      const SizedBox(width: 5),
                      Text("Trạng thái: ", style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context))),
                      Text(
                        statusText,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                      const Spacer(),
                      Text(
                        paymentStatusText,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TColor.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── DANH SÁCH MÓN ĂN ĐÃ ĐẶT ──
            if (items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Món đã đặt (${items.length} món) • Tổng: ${NumberFormat('#,###').format(totalAmount)}đ',
                  style: GoogleFonts.outfit(
                    color: TColor.primaryTextOf(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: isDarkTheme(context) ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDarkTheme(context) ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: items.map<Widget>((it) {
                    final itemMap = it as Map<String, dynamic>;
                    final fName = itemMap['tenMonAn'] ?? itemMap['name'] ?? 'Món ăn';
                    final fQty = itemMap['soLuong'] ?? itemMap['quantity'] ?? 1;
                    final fPrice = (itemMap['gia'] ?? itemMap['price'] as num?)?.toDouble() ?? 0.0;
                    final fImg = itemMap['img'] ?? itemMap['image'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: SmartNetworkImage(
                                imageUrl: fImg.toString(),
                                width: 36,
                                height: 36,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$fQty × $fName',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TColor.primaryTextOf(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(fPrice * (fQty as num))}đ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: TColor.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // ── NÚT 1: DẪN ĐƯỜNG QUA QUÁN / NHẬP ĐIỂM ĐẾN (TH1/TH2) ──
            RoundButton(
              title: "Dẫn đường qua quán ghé lấy",
              onPressed: () async {
                final mapProvider = Provider.of<MapProvider>(context, listen: false);
                Navigator.pop(context);
                MainTabView.switchTab(context, 2);

                final sLat = storeLat ?? 10.7812;
                final sLng = storeLng ?? 106.6985;
                final oId = orderId is int ? orderId : int.tryParse(orderId.toString()) ?? 1;

                await mapProvider.navigateToOrderStore(
                  orderId: oId,
                  storeName: storeName,
                  storeAddress: storeAddress,
                  storeLatLng: LatLng(sLat, sLng),
                  pickupTime: formattedPickupTime,
                  status: statusText,
                );
              },
            ),
            const SizedBox(height: 10),

            // ── NÚT 2 & 3: XEM ĐƠN & TIẾP TỤC ĐẶT MÓN ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: TColor.primary),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Tiếp tục đặt món',
                      style: TextStyle(color: TColor.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: TColor.secondaryTextOf(context).withValues(alpha: 0.4)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      final mainTab = context.findAncestorStateOfType<MainTabViewState>();
                      if (mainTab != null) {
                        mainTab.pushToTab(4, const OrderHistoryView());
                      } else {
                        MainTabView.switchTab(context, 4);
                      }
                    },
                    child: Text(
                      'Xem chi tiết đơn',
                      style: TextStyle(color: TColor.primaryTextOf(context), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool isDarkTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}
