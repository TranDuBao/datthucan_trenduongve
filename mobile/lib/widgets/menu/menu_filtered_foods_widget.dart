import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../common_widget/smart_network_image.dart';
import '../../view/menu/item_details_view.dart';

class MenuFilteredFoodsWidget extends StatelessWidget {
  final List<dynamic> filteredFoods;
  final String searchQuery;
  final String? selectedCategory;
  final VoidCallback onClearFilter;

  const MenuFilteredFoodsWidget({
    super.key,
    required this.filteredFoods,
    required this.searchQuery,
    required this.selectedCategory,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        // Filter info header banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C1E14) : const Color(0xFFFFF4EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF4A2A1A) : const Color(0xFFFFE5D6),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt_rounded, color: Color(0xFFFC6011), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedCategory != null
                        ? "Đang lọc: $selectedCategory (${filteredFoods.length} món)"
                        : "Kết quả cho '$searchQuery' (${filteredFoods.length} món)",
                    style: const TextStyle(
                      color: Color(0xFFFC6011),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onClearFilter,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC6011),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Bỏ lọc ✕",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Food Items or Empty State
        if (filteredFoods.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TColor.cardOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TColor.borderOf(context)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: TColor.secondaryTextOf(context)),
                  const SizedBox(height: 10),
                  Text(
                    "Không tìm thấy món ăn phù hợp",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Vui lòng thử tìm với từ khóa hoặc danh mục khác",
                    style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredFoods.length,
              itemBuilder: (context, index) {
                final item = filteredFoods[index];
                final name = item["name"] ?? item["tenMonAn"] ?? "Món ngon";
                final storeName = item["tenQuan"] ?? item["storeName"] ?? "Cửa hàng";
                final price = (item["price"] ?? item["gia"] ?? 0) as num;
                final img = item["image"] ?? item["hinhAnh"] ?? "";

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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SmartNetworkImage(
                          imageUrl: img.toString(),
                          width: double.infinity,
                          height: 110,
                          fit: BoxFit.cover,
                          placeholderIcon: Icons.restaurant_rounded,
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: TColor.secondaryTextOf(context),
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                style: TextStyle(
                                  color: TColor.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
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
