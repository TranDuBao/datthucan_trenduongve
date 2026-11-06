import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';

class CategoryItemData {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const CategoryItemData({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

class StoreCategoryPickerSheet extends StatefulWidget {
  final String currentCategory;
  final Function(String) onSelected;

  const StoreCategoryPickerSheet({
    super.key,
    required this.currentCategory,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String currentCategory,
    required Function(String) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StoreCategoryPickerSheet(
        currentCategory: currentCategory,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<StoreCategoryPickerSheet> createState() => _StoreCategoryPickerSheetState();
}

class _StoreCategoryPickerSheetState extends State<StoreCategoryPickerSheet> {
  late String _tempSelected;

  static const List<CategoryItemData> categories = [
    CategoryItemData(
      name: 'Cà phê & Trà',
      subtitle: 'Coffee, matcha, trà thảo mộc & đá xay',
      icon: Icons.local_cafe_rounded,
      iconBg: Color(0xFFFFF3EB),
      iconColor: Color(0xFFFC6011),
    ),
    CategoryItemData(
      name: 'Cơm & Món mặn',
      subtitle: 'Cơm tấm, cơm văn phòng, món gia đình',
      icon: Icons.rice_bowl_rounded,
      iconBg: Color(0xFFFEE2E2),
      iconColor: Color(0xFFDC2626),
    ),
    CategoryItemData(
      name: 'Bánh mì & Xôi',
      subtitle: 'Bánh mì pate, xôi xéo, điểm tâm sáng',
      icon: Icons.breakfast_dining_rounded,
      iconBg: Color(0xFFFEF3C7),
      iconColor: Color(0xFFD97706),
    ),
    CategoryItemData(
      name: 'Bún, Phở & Mì',
      subtitle: 'Phở bò, bún bò Huế, hủ tiếu, ramen',
      icon: Icons.ramen_dining_rounded,
      iconBg: Color(0xFFFCE7F3),
      iconColor: Color(0xFFDB2777),
    ),
    CategoryItemData(
      name: 'Trà sữa & Ăn vặt',
      subtitle: 'Boba tea, bánh tráng, xiên que, chè',
      icon: Icons.emoji_food_beverage_rounded,
      iconBg: Color(0xFFEDE9FE),
      iconColor: Color(0xFF7C3AED),
    ),
    CategoryItemData(
      name: 'Đồ ăn nhanh & Burger',
      subtitle: 'Gà rán, burger, khoai tây chiên, pizza',
      icon: Icons.lunch_dining_rounded,
      iconBg: Color(0xFFFFEDD5),
      iconColor: Color(0xFFEA580C),
    ),
    CategoryItemData(
      name: 'Lẩu & Nướng',
      subtitle: 'Lẩu hải sản, BBQ nướng than, bò nướng',
      icon: Icons.outdoor_grill_rounded,
      iconBg: Color(0xFFFFE4E6),
      iconColor: Color(0xFFE11D48),
    ),
    CategoryItemData(
      name: 'Món Chay',
      subtitle: 'Cơm chay, lẩu nấm, thực dưỡng thanh đạm',
      icon: Icons.eco_rounded,
      iconBg: Color(0xFFDCFCE7),
      iconColor: Color(0xFF16A34A),
    ),
    CategoryItemData(
      name: 'Khác',
      subtitle: 'Các món ăn & đồ uống đa dạng khác',
      icon: Icons.restaurant_rounded,
      iconBg: Color(0xFFF1F5F9),
      iconColor: Color(0xFF475569),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.currentCategory;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161920) : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top drag handle
            const SizedBox(height: 12),
            Container(
              width: 46,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF333846) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Chọn Loại Hình Kinh Doanh",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Phân loại chính xác giúp gợi ý đúng khách hàng",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF232836) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

            // Category Items List
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shrinkWrap: true,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = categories[index];
                  final isSelected = _tempSelected == item.name;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _tempSelected = item.name;
                      });
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? TColor.primary.withOpacity(0.12)
                                : const Color(0xFFFFFBF9))
                            : (isDark ? const Color(0xFF1E232E) : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected
                              ? TColor.primary
                              : (isDark ? const Color(0xFF2B3342) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon container with project's Material Icons
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? item.iconColor.withOpacity(0.18) : item.iconBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              item.icon,
                              size: 24,
                              color: item.iconColor,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Title and Subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? TColor.primary
                                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected
                                        ? (isDark
                                            ? const Color(0xFFFFB399)
                                            : TColor.primary.withOpacity(0.85))
                                        : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B)),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Radio / Checkmark Icon matching the design image
                          if (isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: TColor.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            )
                          else
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFCBD5E1),
                                  width: 1.6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Confirm Button matching the design image
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              decoration: BoxDecoration(
                color: bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSelected(_tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primary,
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Xác Nhận Lựa Chọn",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

