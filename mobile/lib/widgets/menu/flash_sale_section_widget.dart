import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../view/menu/item_details_view.dart';
import '../skeleton/skeleton_shimmer.dart';
import '../skeleton/skeleton_box.dart';
import '../skeleton/skeleton_line.dart';

class FlashSaleSectionWidget extends StatelessWidget {
  final List<dynamic> flashSaleItems;
  final String hours;
  final String minutes;
  final String seconds;

  const FlashSaleSectionWidget({
    super.key,
    required this.flashSaleItems,
    required this.hours,
    required this.minutes,
    required this.seconds,
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
                "⚡ FLASH SALE",
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
              Text(
                "Xem tất cả >",
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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
                    final name = item["name"] ?? "Món ngon";
                    final price = (item["price"] as num? ?? 50000).toInt();
                    final oldPrice = (price * 1.4).toInt();
                    final img = item["image"] ?? "";

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
                                img.toString().startsWith("http")
                                    ? Image.network(
                                        img.toString(),
                                        width: 135,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey),
                                      )
                                    : Image.asset(
                                        img.toString(),
                                        width: 135,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey),
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
                                    child: const Text(
                                      "-35%",
                                      style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.access_time, color: Colors.white70, size: 10),
                                        SizedBox(width: 2),
                                        Text("7p", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
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
                                  const SizedBox(height: 2),
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
