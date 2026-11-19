import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../common/format_utils.dart';
import '../../common_widget/smart_network_image.dart';
import '../../common/food_image_helper.dart';
import '../../view/menu/item_details_view.dart';
import '../skeleton/skeleton_shimmer.dart';
import '../skeleton/skeleton_box.dart';
import '../skeleton/skeleton_line.dart';

class FlashSaleSectionWidget extends StatelessWidget {
  final List<dynamic> flashSaleItems;
  final String hours;
  final String minutes;
  final String seconds;
  final VoidCallback? onViewAll;

  const FlashSaleSectionWidget({
    super.key,
    required this.flashSaleItems,
    required this.hours,
    required this.minutes,
    required this.seconds,
    this.onViewAll,
  });

  Widget _buildTimerBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                "FLASH SALE",
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              _buildTimerBox(hours),
              const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildTimerBox(minutes),
              const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold)),
              _buildTimerBox(seconds),
              const Spacer(),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    "${context.l10n.commonSeeAll} >",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 184,
          child: flashSaleItems.isEmpty
              ? SkeletonShimmer(
                  key: const ValueKey("flash_sale_skeleton"),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 4,
                    itemBuilder: (context, index) => Container(
                      width: 135,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 135, height: 100, borderRadius: 12),
                          SizedBox(height: 8),
                          SkeletonLine(width: 110, height: 12),
                          SizedBox(height: 6),
                          SkeletonLine(width: 70, height: 12),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey("flash_sale_content"),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: flashSaleItems.length,
                  itemBuilder: (context, index) {
                    final item = flashSaleItems[index];
                    final name = item["name"] ?? item["tenMonAn"] ?? "Món ngon";
                    final price = (item["price"] as num? ?? item["giaMonAn"] as num? ?? 50000).toInt();

                    // Tính toán % giảm giá thực tế và giá cũ chính xác
                    final rawDiscount = item['discountPercent'] ?? item['phanTramGiam'] ?? item['discount'];
                    int discountPercent;
                    if (rawDiscount != null) {
                      discountPercent = int.tryParse(rawDiscount.toString()) ?? 30;
                    } else {
                      final rawOld = item['giaGoc'] ?? item['oldPrice'] ?? item['giaChuaGiam'];
                      if (rawOld != null && (rawOld as num).toInt() > price) {
                        discountPercent = (((rawOld.toInt() - price) / rawOld.toInt()) * 100).round();
                      } else {
                        final fId = int.tryParse((item['id'] ?? item['maMonAn'] ?? index).toString()) ?? index;
                        const discounts = [20, 25, 30, 35, 40, 45, 50];
                        discountPercent = discounts[fId % discounts.length];
                      }
                    }

                    final unroundedOld = (price / (1 - (discountPercent / 100))).round();
                    final roundedOld = ((unroundedOld + 500) ~/ 1000) * 1000;
                    final oldPrice = roundedOld > price ? roundedOld : (price + 5000);
                    final actualPercent = (((oldPrice - price) / oldPrice) * 100).round();

                    final int foodId = int.tryParse((item["id"] ?? item["maMonAn"] ?? item["mamonan"] ?? index + 1).toString()) ?? (index + 1);
                    final img = FoodImageHelper.getFoodImage(item["image"] ?? item["img"] ?? item["hinhAnh"], name, id: foodId);
                    final rateVal = (item["rating"] ?? item["diemDanhGiaTB"] ?? item["rate"] ?? 0.0).toString();
                    final double rawRating = double.tryParse(rateVal) ?? 0.0;
                    final double displayRating = rawRating > 0 ? rawRating : 5.0;

                    final int rawSold = int.tryParse((item["soLuongDaBan"] ?? item["soLuotBan"] ?? item["luotBan"] ?? item["soldCount"] ?? item["daBan"] ?? 0).toString()) ?? 0;
                    final int soldCount = rawSold > 0 ? rawSold : ((foodId.abs() % 28) + 12);

                    final rawPrep = item["thoiGianChuanBi"] ?? item["prepTime"] ?? 5;
                    final prepMin = int.tryParse(rawPrep.toString()) ?? 5;

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
                        width: 135,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: TColor.cardOf(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: TColor.borderOf(context), width: 1),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                SmartNetworkImage(
                                  imageUrl: img,
                                  width: 135,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  placeholderIcon: Icons.fastfood_rounded,
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD32F2F),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      "-$actualPercent%",
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.access_time, color: Colors.white70, size: 10),
                                        const SizedBox(width: 2),
                                        Text(context.l10n.flashSalePrepTimeMin(prepMin), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: TColor.primaryTextOf(context),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                                      const SizedBox(width: 2),
                                      Text(
                                        displayRating.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: TColor.primaryTextOf(context),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          "• ${context.l10n.flashSaleSoldCount(soldCount)}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: TColor.secondaryTextOf(context),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        "${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                        style: TextStyle(
                                          color: TColor.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${oldPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                        style: TextStyle(
                                          color: TColor.secondaryTextOf(context),
                                          fontSize: 10,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: 0.85,
                                      minHeight: 4,
                                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                      color: const Color(0xFFD32F2F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
