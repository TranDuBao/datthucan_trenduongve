import 'package:flutter/material.dart';

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

  static const List<Map<String, String>> defaultCategories = [
    {"name": "Món Giảm 50%", "icon": "🔥", "bg": "0xFFFFF3E0", "color": "0xFFE65100"},
    {"name": "Trà Sữa / Cà Phê", "icon": "☕", "bg": "0xFFFFF8E1", "color": "0xFFF57F17"},
    {"name": "Phở & Bún Nóng", "icon": "🍜", "bg": "0xFFFFEBEE", "color": "0xFFC62828"},
    {"name": "Cơm Trưa Nóng", "icon": "🍽️", "bg": "0xFFE8F5E9", "color": "0xFF2E7D32"},
    {"name": "Bánh Mì & Nhanh", "icon": "🥪", "bg": "0xFFE3F2FD", "color": "0xFF1565C0"},
    {"name": "Ăn Kèm & Vặt", "icon": "🍪", "bg": "0xFFFCE4EC", "color": "0xFFAD1457"},
    {"name": "Eat Clean Healthy", "icon": "🥗", "bg": "0xFFE0F2F1", "color": "0xFF00695C"},
    {"name": "Ghé Lấy 0Đ", "icon": "🎫", "bg": "0xFFFFFDE7", "color": "0xFFFBC02D"},
  ];

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
                  child: Text(cat["icon"]!, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(height: 6),
                Text(
                  catName,
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
