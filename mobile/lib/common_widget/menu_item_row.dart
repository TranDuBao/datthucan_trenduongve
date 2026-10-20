import 'package:flutter/material.dart';
import '../common/color_extension.dart';
import 'smart_network_image.dart';

class MenuItemRow extends StatelessWidget {
  final Map mObj;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const MenuItemRow({
    super.key,
    required this.mObj,
    required this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = mObj["name"]?.toString() ??
        mObj["tenMonAn"]?.toString() ??
        mObj["title"]?.toString() ??
        "Món Ăn";

    final rateVal = (mObj["rate"] ?? mObj["diemDanhGiaTB"] ?? mObj["diemDanhGia"] ?? mObj["rating"] ?? 0.0).toString();
    final double ratingNum = double.tryParse(rateVal) ?? 0.0;

    final storeName = mObj["type"]?.toString() ?? mObj["tenQuan"]?.toString() ?? "Nhà hàng tuyển chọn";
    
    final priceVal = (mObj["price"] ?? mObj["giaMonAn"] as num?)?.toInt() ?? 65000;
    final formattedPrice = "${priceVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ";
    final oldPriceVal = (priceVal * 1.35).toInt();
    final formattedOldPrice = "${oldPriceVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ";

    final rawImg = mObj["image"]?.toString() ?? mObj["img"]?.toString() ?? mObj["hinhAnh"]?.toString();
    final imgUrl = (rawImg != null && rawImg.trim().isNotEmpty) ? rawImg.trim() : "assets/img/menu_1.png";

    final int stockQty = int.tryParse((mObj["soLuongMon"] ?? mObj["quantity"] ?? mObj["soLuong"] ?? 0).toString()) ?? 0;
    final String status = (mObj["trangThaiMon"] ?? mObj["status"] ?? "").toString().toUpperCase();
    final bool isSoldOut = stockQty <= 0 || status == 'HET_HANG' || status == 'HET_MON' || status == 'TAM_NGUNG';

    final int soldQty = int.tryParse((mObj["soLuongDaBan"] ?? mObj["soLuotBan"] ?? mObj["soldCount"] ?? 0).toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TColor.borderOf(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Food Thumbnail Image with Badge Overlay
                Stack(
                  children: [
                    Opacity(
                      opacity: isSoldOut ? 0.45 : 1.0,
                      child: SmartNetworkImage(
                        imageUrl: imgUrl,
                        width: 104,
                        height: 104,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    if (isSoldOut)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "HẾT MÓN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (ratingNum > 0)
                      // Rating Badge
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                ratingNum.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // 2. Food Info & Action
                Expanded(
                  child: SizedBox(
                    height: 104,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSoldOut ? TColor.secondaryTextOf(context) : TColor.primaryTextOf(context),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    storeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: TColor.secondaryTextOf(context),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (soldQty > 0) ...[
                                  Text(
                                    "Đã bán $soldQty",
                                    style: TextStyle(
                                      color: TColor.secondaryTextOf(context),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSoldOut ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isSoldOut ? "Hết món" : "Còn $stockQty phần",
                                    style: TextStyle(
                                      color: isSoldOut ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Price Row & Quick Add Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedPrice,
                                  style: TextStyle(
                                    color: isSoldOut ? TColor.secondaryTextOf(context) : TColor.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  formattedOldPrice,
                                  style: TextStyle(
                                    color: TColor.secondaryTextOf(context),
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSoldOut
                                    ? (isDark ? const Color(0xFF2A2E3B) : const Color(0xFFE5E7EB))
                                    : TColor.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSoldOut
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: TColor.primary.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isSoldOut) ...[
                                    const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                                    const SizedBox(width: 2),
                                  ],
                                  Text(
                                    isSoldOut ? "Hết món" : "Thêm",
                                    style: TextStyle(
                                      color: isSoldOut ? TColor.secondaryTextOf(context) : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
