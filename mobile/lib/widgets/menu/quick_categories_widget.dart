import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import '../../common/format_utils.dart';

class QuickCategoriesWidget extends StatelessWidget {
  final List<Map<String, String>>? quickCategories;
  final String? selectedCategory;
  final ValueChanged<String>? onCategorySelected;

  const QuickCategoriesWidget({
    super.key,
    this.quickCategories,
    this.selectedCategory,
    this.onCategorySelected,
  });

  static String getLocalizedCategoryName(BuildContext context, String catName) {
    switch (catName) {
      case "Món Giảm 50%":
        return context.l10n.quickCatDiscount50;
      case "Trà Sữa / Cà Phê":
        return context.l10n.quickCatBobaCoffee;
      case "Phở & Bún Nóng":
        return context.l10n.quickCatHotNoodles;
      case "Cơm Trưa Nóng":
        return context.l10n.quickCatHotLunch;
      case "Bánh Mì & Nhanh":
        return context.l10n.quickCatBanhMiFast;
      case "Ăn Kèm & Vặt":
        return context.l10n.quickCatSnacks;
      case "Eat Clean Healthy":
        return context.l10n.quickCatEatClean;
      case "Ghé Lấy 0Đ":
        return context.l10n.quickCatPickup0d;
      default:
        return catName;
    }
  }

  static const List<Map<String, String>> defaultCategories = [
    {"name": "Món Giảm 50%", "icon": "badgePercent", "bg": "0xFFFFF3E0", "color": "0xFFE65100"},
    {"name": "Trà Sữa / Cà Phê", "icon": "coffee", "bg": "0xFFFFF8E1", "color": "0xFFF57F17"},
    {"name": "Phở & Bún Nóng", "icon": "soup", "bg": "0xFFFFEBEE", "color": "0xFFC62828"},
    {"name": "Cơm Trưa Nóng", "icon": "utensils", "bg": "0xFFE8F5E9", "color": "0xFF2E7D32"},
    {"name": "Bánh Mì & Nhanh", "icon": "sandwich", "bg": "0xFFE3F2FD", "color": "0xFF1565C0"},
    {"name": "Ăn Kèm & Vặt", "icon": "cookie", "bg": "0xFFFCE4EC", "color": "0xFFAD1457"},
    {"name": "Eat Clean Healthy", "icon": "salad", "bg": "0xFFE0F2F1", "color": "0xFF00695C"},
    {"name": "Ghé Lấy 0Đ", "icon": "ticket", "bg": "0xFFFFFDE7", "color": "0xFFFBC02D"},
  ];

  static IconData _getQuickCategoryIcon(String iconKey) {
    switch (iconKey) {
      case 'badgePercent':
        return LucideIcons.badgePercent;
      case 'coffee':
        return LucideIcons.coffee;
      case 'soup':
        return LucideIcons.soup;
      case 'utensils':
        return LucideIcons.utensils;
      case 'sandwich':
        return LucideIcons.sandwich;
      case 'cookie':
        return LucideIcons.cookie;
      case 'salad':
        return LucideIcons.salad;
      case 'ticket':
        return LucideIcons.ticket;
      default:
        return LucideIcons.utensils;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = quickCategories ?? defaultCategories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final cat = list[index];
          final catName = cat["name"]!;
          final isSelected = selectedCategory == catName;
          final bgColor = Color(int.parse(cat["bg"]!));

          return GestureDetector(
            onTap: () {
              if (onCategorySelected != null) {
                onCategorySelected!(catName);
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF3D1E10) : const Color(0xFFFFECE0))
                        : (isDark ? const Color(0xFF1F2430) : bgColor),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFFC6011)
                          : (isDark ? const Color(0xFF2E3545) : Colors.transparent),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFC6011).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(_getQuickCategoryIcon(cat["icon"]!), size: 22, color: Color(int.parse(cat["color"]!))),
                ),
                const SizedBox(height: 6),
                Text(
                  getLocalizedCategoryName(context, catName),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFFFC6011)
                        : (isDark ? Colors.white70 : const Color(0xFF333333)),
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
