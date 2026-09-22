import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import 'package:food_delivery/providers/language_provider.dart';
import '../../services/category_service.dart';
import '../more/my_order_view.dart';
import 'menu_items_view.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  TextEditingController txtSearch = TextEditingController();
  bool isLoading = true;
  List<CategoryModel> categoryList = [];

  @override
  void initState() {
    super.initState();
    _loadCategoriesFromDB();
  }

  Future<void> _loadCategoriesFromDB() async {
    setState(() => isLoading = true);
    final list = await CategoryService.fetchCategoriesFromDB();
    if (mounted) {
      setState(() {
        categoryList = list;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Left Side Vertical Orange Accent Pill
          Positioned(
            left: 0,
            top: media.height * 0.18,
            child: Container(
              width: media.width * 0.28,
              height: media.height * 0.65,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TColor.primary,
                    TColor.primary.withOpacity(0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(38),
                  bottomRight: Radius.circular(38),
                ),
                boxShadow: [
                  BoxShadow(
                    color: TColor.primary.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(4, 0),
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 46),

                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.tr('menu'),
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: TColor.cardOf(context),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: TColor.borderOf(context), width: 1),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const MyOrderView()),
                                  );
                                },
                                icon: Icon(
                                  Icons.shopping_cart_outlined,
                                  color: TColor.primaryTextOf(context),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: TColor.textfieldOf(context),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: TColor.borderOf(context), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: TColor.secondaryTextOf(context),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: txtSearch,
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: "${lang.tr('search')}...",
                                hintStyle: TextStyle(
                                  color: TColor.secondaryTextOf(context).withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Category Cards List from DB
                  isLoading
                      ? Center(child: CircularProgressIndicator(color: TColor.primary))
                      : categoryList.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  "Chưa có danh mục nào trong cơ sở dữ liệu",
                                  style: TextStyle(
                                    color: TColor.secondaryTextOf(context),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: categoryList.length,
                              itemBuilder: (context, index) {
                                var mObj = categoryList[index];
                                bool isHot = mObj.isHot;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MenuItemsView(mObj: {
                                          "name": mObj.name,
                                          "id": mObj.id,
                                        }),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 18),
                                    child: Stack(
                                      alignment: Alignment.centerRight,
                                      children: [
                                        // Background Dark Card Tile
                                        Container(
                                          margin: const EdgeInsets.only(left: 30),
                                          padding: const EdgeInsets.only(left: 60, right: 16, top: 16, bottom: 16),
                                          decoration: BoxDecoration(
                                            color: TColor.cardOf(context),
                                            borderRadius: BorderRadius.circular(22),
                                            border: Border.all(color: TColor.borderOf(context), width: 1),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.18),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          mObj.name,
                                                          style: TextStyle(
                                                            color: TColor.primaryTextOf(context),
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                        if (isHot) ...[
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFD32F2F),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: const Text(
                                                              "HOT",
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w800,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      "${mObj.itemsCount} ${lang.tr('items')}",
                                                      style: TextStyle(
                                                        color: TColor.secondaryTextOf(context),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF242936) : const Color(0xFFF2F2F4),
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.chevron_right_rounded,
                                                  color: TColor.primaryTextOf(context),
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Food Image Thumbnail Circle
                                        Positioned(
                                          left: 0,
                                          child: Container(
                                            width: 76,
                                            height: 76,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: TColor.primary.withOpacity(0.3),
                                                  blurRadius: 14,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(38),
                                              child: Image.asset(
                                                mObj.image,
                                                width: 76,
                                                height: 76,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  color: TColor.primary.withOpacity(0.2),
                                                  child: Icon(Icons.restaurant_rounded, color: TColor.primary),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
