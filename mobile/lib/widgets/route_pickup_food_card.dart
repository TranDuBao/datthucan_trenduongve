import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/color_extension.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../view/menu/item_details_view.dart';
import '../common_widget/smart_network_image.dart';
import 'custom_toast.dart';

class RoutePickupFoodCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final double? width;
  final double? userLat;
  final double? userLng;

  const RoutePickupFoodCard({
    Key? key,
    required this.item,
    this.width,
    this.userLat,
    this.userLng,
  }) : super(key: key);

  String _formatDistance() {
    final uLat = userLat ?? 10.762622;
    final uLng = userLng ?? 106.682029;
    final storeLat = (item["lat"] as num?)?.toDouble() ?? 10.762622;
    final storeLng = (item["lng"] as num?)?.toDouble() ?? 106.682029;

    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((storeLat - uLat) * p) / 2 +
        math.cos(uLat * p) * math.cos(storeLat * p) *
            (1 - math.cos((storeLng - uLng) * p)) / 2;
    final meters = 12742 * math.asin(math.sqrt(a)) * 1000;

    if (meters < 100) {
      return "Cách 150m";
    } else if (meters < 1000) {
      return "Cách ${meters.round()}m";
    } else {
      return "Cách ${(meters / 1000).toStringAsFixed(1)}km";
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = item["name"] ?? item["tenMonAn"] ?? "Món tiện đường";
    final price = (item["price"] as num? ?? item["giaMonAn"] as num? ?? 45000).toInt();
    final img = item["image"] ?? item["img"] ?? "";

    final int stockQty = int.tryParse((item["soLuongMon"] ?? item["quantity"] ?? item["soLuong"] ?? 0).toString()) ?? 0;
    final String status = (item["trangThaiMon"] ?? item["status"] ?? "").toString().toUpperCase();
    final bool isSoldOut = stockQty <= 0 || status == 'HET_HANG' || status == 'HET_MON' || status == 'TAM_NGUNG';
    final int soldQty = int.tryParse((item["soLuongDaBan"] ?? item["soLuotBan"] ?? item["soldCount"] ?? 0).toString()) ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailsView(itemObj: item),
          ),
        );
      },
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: TColor.cardOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TColor.borderOf(context), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Opacity(
                  opacity: isSoldOut ? 0.45 : 1.0,
                  child: SmartNetworkImage(
                    imageUrl: img.toString(),
                    width: double.infinity,
                    height: 115,
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.fastfood,
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSoldOut ? const Color(0xFFEF4444) : const Color(0xFFFC6011),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSoldOut ? "Hết món" : "Ghé lấy sau 8p",
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                if (!isSoldOut)
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: InkWell(
                      onTap: () {
                        final foodId = (item["id"] as num? ?? item["maMonAn"] as num? ?? 1).toInt();
                        final name = item["name"] ?? item["tenMonAn"] ?? "Món tiện đường";
                        final price = (item["price"] as num? ?? item["giaMonAn"] as num? ?? 45000).toDouble();
                        final image = item["image"]?.toString() ?? item["img"]?.toString() ?? "";
                        final restaurantId = (item["maQuan"] as num? ?? 1).toInt();

                        context.read<CartProvider>().addToCart(CartItemModel(
                          foodId: foodId,
                          foodName: name,
                          price: price,
                          quantity: 1,
                          image: image,
                          restaurantId: restaurantId,
                        ));

                        CustomToast.showSuccess(context, "Đã thêm '$name' vào giỏ hàng");
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Color(0xFFFC6011), size: 20),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSoldOut ? TColor.secondaryTextOf(context) : TColor.primaryTextOf(context),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.storefront, size: 12, color: TColor.secondaryTextOf(context)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item["tenQuan"] ?? "Cửa hàng",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (soldQty > 0) ...[
                        const SizedBox(width: 4),
                        Text(
                          "• Đã bán $soldQty",
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSoldOut ? TColor.secondaryTextOf(context) : TColor.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSoldOut ? const Color(0xFFFEE2E2) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSoldOut ? "Hết hàng" : "Còn $stockQty",
                          style: TextStyle(
                            color: isSoldOut ? const Color(0xFFDC2626) : const Color(0xFF2E7D32),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
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
    );
  }
}
