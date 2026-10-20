import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../services/category_service.dart';
import '../../view/menu/menu_items_view.dart';
import '../skeleton/food_item_skeleton.dart';

class MenuCategoriesSectionWidget extends StatelessWidget {
  final List<CategoryModel> categoryList;
  final bool isLoading;
  final VoidCallback? onRetry;

  const MenuCategoriesSectionWidget({
    super.key,
    required this.categoryList,
    required this.isLoading,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Thực Đơn Quán Tuyển Chọn",
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${categoryList.length} Nhóm món",
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Đóng gói sẵn sàng, dừng xe lấy trong 1 phút",
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Categories List
        if (isLoading)
          const FoodItemSkeletonList(itemCount: 4)
        else if (categoryList.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_menu_outlined,
                    size: 40,
                    color: TColor.secondaryTextOf(context).withOpacity(0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Chưa có danh mục nào trong cơ sở dữ liệu",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 14,
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text("Tải lại thực đơn"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: categoryList.length,
            itemBuilder: (context, index) {
              final mObj = categoryList[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuItemsView(mObj: {
                        "name": mObj.name,
                        "id": mObj.id,
                        "maQuan": mObj.maQuan,
                        "items": mObj.items,
                      }),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TColor.cardOf(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: TColor.borderOf(context), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Thumbnail
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: mObj.image.startsWith("http")
                                ? Image.network(
                                    mObj.image,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 72,
                                      height: 72,
                                      color: TColor.primary.withOpacity(0.2),
                                      child: Icon(Icons.restaurant_rounded, color: TColor.primary),
                                    ),
                                  )
                                : Image.asset(
                                    mObj.image,
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 72,
                                      height: 72,
                                      color: TColor.primary.withOpacity(0.2),
                                      child: Icon(Icons.restaurant_rounded, color: TColor.primary),
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD32F2F),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Hot",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 12),

                      // Category Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mObj.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Chế biến tươi nóng • Gia vị gia truyền 24h",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: TColor.secondaryTextOf(context),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF262A36) : const Color(0xFFFFF0E6),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${mObj.itemsCount} món đang phục vụ",
                                    style: TextStyle(
                                      color: TColor.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF242936) : const Color(0xFFF2F2F4),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: TColor.primaryTextOf(context),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
