import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../common/format_utils.dart';
import '../../common_widget/smart_network_image.dart';
import '../../providers/cart_provider.dart';
import '../../view/menu/item_details_view.dart';
import '../more/my_order_view.dart';

class FlashSaleAllView extends StatefulWidget {
  final List<dynamic> flashSaleItems;

  const FlashSaleAllView({
    super.key,
    required this.flashSaleItems,
  });

  @override
  State<FlashSaleAllView> createState() => _FlashSaleAllViewState();
}

class _FlashSaleAllViewState extends State<FlashSaleAllView> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  void _updateTime() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const fiveHoursMs = 5 * 3600 * 1000;
    final remainingMs = fiveHoursMs - (nowMs % fiveHoursMs);
    _remainingSeconds = remainingMs ~/ 1000;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _hours => (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
  String get _minutes => ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  String get _seconds => (_remainingSeconds % 60).toString().padLeft(2, '0');

  Widget _buildTimerBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1E232E),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  int _calculateDiscountPercent(Map<String, dynamic> item, int currentPrice) {
    final rawDiscount = item['discountPercent'] ?? item['phanTramGiam'] ?? item['discount'];
    if (rawDiscount != null) {
      final d = int.tryParse(rawDiscount.toString());
      if (d != null && d > 0 && d < 100) return d;
    }

    final rawOldPrice = item['giaGoc'] ?? item['oldPrice'] ?? item['giaChuaGiam'];
    if (rawOldPrice != null) {
      final op = (rawOldPrice as num).toInt();
      if (op > currentPrice) {
        return (((op - currentPrice) / op) * 100).round();
      }
    }

    final fId = int.tryParse((item['id'] ?? item['maMonAn'] ?? 1).toString()) ?? 1;
    const discounts = [20, 25, 30, 35, 40, 45, 50];
    return discounts[fId % discounts.length];
  }

  String _formatVND(int amount) {
    return "${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Giới hạn đúng 20 món ăn Flash Sale
    final displayList = widget.flashSaleItems.take(20).toList();

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E232E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryTextOf(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.flashSaleTitle,
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart_outlined, color: TColor.primaryTextOf(context)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyOrderView()),
                  );
                },
              ),
              Builder(
                builder: (context) {
                  final cartCount = context.watch<CartProvider>().totalItemCount;
                  if (cartCount == 0) return const SizedBox.shrink();
                  return Positioned(
                    right: 6,
                    top: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFC6011),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "$cartCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banner đếm ngược 5 tiếng
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFFC6011)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, color: Colors.yellow, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.flashSaleEndsIn,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.flashSaleBannerSubtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildTimerBox(_hours),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: Text(":", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      _buildTimerBox(_minutes),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3),
                        child: Text(":", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      _buildTimerBox(_seconds),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Lưới 20 món ăn Flash Sale
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = displayList[index] as Map<String, dynamic>;
                  final name = (item["name"] ?? item["tenMonAn"] ?? "Món ngon").toString();
                  final price = (item["price"] as num? ?? item["giaMonAn"] as num? ?? 50000).toInt();
                  final discountPercent = _calculateDiscountPercent(item, price);
                  final unroundedOld = (price / (1 - (discountPercent / 100))).round();
                  final roundedOld = ((unroundedOld + 500) ~/ 1000) * 1000;
                  final oldPrice = roundedOld > price ? roundedOld : (price + 5000);
                  final actualPercent = (((oldPrice - price) / oldPrice) * 100).round();

                  final img = (item["image"] ?? item["img"] ?? item["hinhAnh"] ?? "").toString();
                  final rateVal = (item["rating"] ?? item["diemDanhGiaTB"] ?? item["rate"] ?? 0.0).toString();
                  final double rawRating = double.tryParse(rateVal) ?? 0.0;
                  final double displayRating = rawRating > 0 ? rawRating : 5.0;

                  final int rawSold = int.tryParse((item["soLuongDaBan"] ?? item["soLuotBan"] ?? item["luotBan"] ?? item["soldCount"] ?? item["daBan"] ?? 0).toString()) ?? 0;
                  final int foodId = int.tryParse((item["id"] ?? item["maMonAn"] ?? item["mamonan"] ?? index + 1).toString()) ?? (index + 1);
                  final int soldCount = rawSold > 0 ? rawSold : ((foodId.abs() % 28) + 12);

                  final rawPrep = item["thoiGianChuanBi"] ?? item["prepTime"] ?? 5;
                  final prepTime = int.tryParse(rawPrep.toString()) ?? 5;

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
                      decoration: BoxDecoration(
                        color: TColor.cardOf(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TColor.borderOf(context), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ảnh món kèm huy hiệu % giảm giá và thời gian chuẩn bị
                          Stack(
                            children: [
                              SmartNetworkImage(
                                imageUrl: img,
                                width: double.infinity,
                                height: 115,
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time, color: Colors.white70, size: 10),
                                      const SizedBox(width: 2),
                                      Text(
                                        "${prepTime}p",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Thông tin chi tiết món ăn
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: TColor.primaryTextOf(context),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 13),
                                    const SizedBox(width: 2),
                                    Text(
                                      displayRating.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: TColor.primaryTextOf(context),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "•",
                                      style: TextStyle(
                                        color: TColor.secondaryTextOf(context),
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "Đã bán $soldCount",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: TColor.secondaryTextOf(context),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.storefront_outlined, size: 11, color: TColor.secondaryTextOf(context)),
                                    const SizedBox(width: 3),
                                    Expanded(
                                      child: Text(
                                        (item["tenQuan"] ?? "Cửa hàng").toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: TColor.secondaryTextOf(context),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      _formatVND(price),
                                      style: TextStyle(
                                        color: TColor.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _formatVND(oldPrice),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: TColor.secondaryTextOf(context),
                                          fontSize: 10,
                                          decoration: TextDecoration.lineThrough,
                                        ),
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
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.l10n.flashSaleSellingFast,
                                      style: TextStyle(
                                        color: Color(0xFFD32F2F),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "Còn lại ${(soldCount > 4 ? (soldCount ~/ 4) : 4)}",
                                      style: TextStyle(
                                        color: TColor.secondaryTextOf(context),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
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
                },
                childCount: displayList.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }
}
