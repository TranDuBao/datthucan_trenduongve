import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../providers/cart_provider.dart';
import '../../common_widget/menu_item_row.dart';
import '../../services/category_service.dart';
import '../../widgets/skeleton/food_item_skeleton.dart';
import '../more/my_order_view.dart';
import '../more/restaurant_reviews_sheet.dart';
import 'item_details_view.dart';

class MenuItemsView extends StatefulWidget {
  final Map mObj;
  const MenuItemsView({super.key, required this.mObj});

  @override
  State<MenuItemsView> createState() => _MenuItemsViewState();
}

class _MenuItemsViewState extends State<MenuItemsView> {
  final TextEditingController txtSearch = TextEditingController();

  List menuItemsArr = [];
  bool isLoading = false;
  String searchQuery = "";
  int selectedFilterIndex = 0;

  final List<String> filterTags = ["Tất cả", "🔥 Bán chạy", "⭐ 4.5+", "⚡ Chuẩn bị nhanh"];

  @override
  void initState() {
    super.initState();
    txtSearch.addListener(() {
      if (mounted) {
        setState(() {
          searchQuery = txtSearch.text.trim().toLowerCase();
        });
      }
    });

    if (widget.mObj["items"] != null && (widget.mObj["items"] as List).isNotEmpty) {
      menuItemsArr = widget.mObj["items"];
    } else {
      _loadRealMenuFromDB();
    }
  }

  @override
  void dispose() {
    txtSearch.dispose();
    super.dispose();
  }

  Future<void> _loadRealMenuFromDB() async {
    setState(() => isLoading = true);
    var resId = widget.mObj["maQuan"] ?? 0;
    if (resId == 0) {
      final restaurants = await CategoryService.fetchRestaurantsFromDB();
      if (restaurants.isNotEmpty) {
        resId = restaurants.first["maQuan"] ?? restaurants.first["id"] ?? 2;
      }
    }
    if (resId == 0) resId = 2;

    final categories = await CategoryService.fetchRestaurantMenuFromDB(resId);
    if (mounted) {
      if (categories.isNotEmpty) {
        final cat = categories.firstWhere(
          (c) => c["name"] == widget.mObj["name"] || c["id"] == widget.mObj["id"],
          orElse: () => categories.first,
        );
        setState(() {
          menuItemsArr = cat["items"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          menuItemsArr = [];
          isLoading = false;
        });
      }
    }
  }

  bool _isSoldOutItem(dynamic item) {
    if (item is! Map) return false;
    final int qty = int.tryParse((item['soLuongMon'] ?? item['quantity'] ?? item['soLuong'] ?? 0).toString()) ?? 0;
    final String status = (item['trangThaiMon'] ?? item['status'] ?? '').toString().toUpperCase();
    return qty <= 0 || status == 'HET_HANG' || status == 'HET_MON' || status == 'TAM_NGUNG';
  }

  List get filteredItems {
    final list = menuItemsArr.where((item) {
      if (item is! Map) return false;
      final name = (item["name"] ?? item["tenMonAn"] ?? "").toString().toLowerCase();
      final matchesSearch = searchQuery.isEmpty || name.contains(searchQuery);

      if (!matchesSearch) return false;

      if (selectedFilterIndex == 2) {
        final rating = double.tryParse((item["rating"] ?? item["diemDanhGiaTB"] ?? 0.0).toString()) ?? 0.0;
        return rating >= 4.5;
      }

      return true;
    }).toList();

    list.sort((a, b) {
      final aMap = a is Map ? a : {};
      final bMap = b is Map ? b : {};
      final aSoldOut = _isSoldOutItem(aMap);
      final bSoldOut = _isSoldOutItem(bMap);

      if (aSoldOut != bSoldOut) {
        return aSoldOut ? 1 : -1;
      }
      final aSales = int.tryParse((aMap['soLuongDaBan'] ?? aMap['soLuotBan'] ?? aMap['luotBan'] ?? aMap['soldCount'] ?? 0).toString()) ?? 0;
      final bSales = int.tryParse((bMap['soLuongDaBan'] ?? bMap['soLuotBan'] ?? bMap['luotBan'] ?? bMap['soldCount'] ?? 0).toString()) ?? 0;
      if (bSales != aSales) {
        return bSales.compareTo(aSales);
      }
      final aRating = double.tryParse((aMap['diemDanhGiaTB'] ?? aMap['rating'] ?? 0.0).toString()) ?? 0.0;
      final bRating = double.tryParse((bMap['diemDanhGiaTB'] ?? bMap['rating'] ?? 0.0).toString()) ?? 0.0;
      return bRating.compareTo(aRating);
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final cartProv = context.watch<CartProvider>();
    final cartCount = cartProv.totalItemCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayItems = filteredItems;

    final storeId = widget.mObj["maQuan"] ?? widget.mObj["id"] ?? 0;
    final storeName = widget.mObj["name"]?.toString() ?? widget.mObj["tenQuan"]?.toString() ?? "Cửa hàng";
    final avgRating = double.tryParse((widget.mObj["danhGiaTrungBinh"] ?? widget.mObj["rating"] ?? 0.0).toString()) ?? 0.0;
    final totalReviews = int.tryParse((widget.mObj["soLuongDanhGia"] ?? 0).toString()) ?? 0;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Back Button Container
                  Material(
                    color: TColor.cardOf(context),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: TColor.borderOf(context), width: 1),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: TColor.primaryTextOf(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title & Subtitle Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.mObj["name"]?.toString() ?? "Thực Đơn Quán",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: TColor.primaryTextOf(context),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => RestaurantReviewsSheet(
                                    restaurantId: storeId,
                                    restaurantName: storeName,
                                    averageRating: avgRating,
                                    totalReviews: totalReviews,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9E6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFFE5A3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (avgRating > 0) ...[
                                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        avgRating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Color(0xFFD97706),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ] else ...[
                                      const Text(
                                        "Mới",
                                        style: TextStyle(
                                          color: Color(0xFFD97706),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${menuItemsArr.length} món sẵn sàng phục vụ",
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cart Icon Button with Badge
                  Stack(
                    children: [
                      Material(
                        color: TColor.cardOf(context),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const MyOrderView()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: TColor.borderOf(context), width: 1),
                            ),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: 20,
                              color: TColor.primaryTextOf(context),
                            ),
                          ),
                        ),
                      ),
                      if (cartCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              cartCount > 99 ? '99+' : cartCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: TColor.cardOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TColor.borderOf(context), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: txtSearch,
                  style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 14),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: "Tìm kiếm món ngon...",
                    hintStyle: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: TColor.secondaryTextOf(context), size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.cancel_rounded, color: TColor.secondaryTextOf(context), size: 18),
                            onPressed: () => txtSearch.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 3. Horizontal Filter Tag Chips
            SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filterTags.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedFilterIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedFilterIndex = index;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TColor.primary
                            : (isDark ? const Color(0xFF232734) : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? TColor.primary : TColor.borderOf(context),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filterTags[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : TColor.primaryTextOf(context),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 4. Food List / Loading / Empty State
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isLoading
                    ? const FoodItemSkeletonList(key: ValueKey("menu_items_skeleton"), itemCount: 6)
                    : displayItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 56,
                                color: TColor.secondaryTextOf(context).withOpacity(0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Không tìm thấy món ăn phù hợp",
                                style: TextStyle(
                                  color: TColor.primaryTextOf(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Vui lòng thử tìm với từ khóa khác",
                                style: TextStyle(
                                  color: TColor.secondaryTextOf(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: displayItems.length,
                          itemBuilder: (context, index) {
                            var item = displayItems[index];
                            Map mObj = item is Map ? item : {};
                            return MenuItemRow(
                              mObj: mObj,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailsView(itemObj: mObj),
                                  ),
                                );
                              },
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
