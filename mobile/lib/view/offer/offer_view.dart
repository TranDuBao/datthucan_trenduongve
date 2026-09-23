import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_service.dart';
import 'package:food_delivery/providers/language_provider.dart';
import '../more/my_order_view.dart';
import '../menu/restaurant_detail_view.dart';

class OfferView extends StatefulWidget {
  const OfferView({super.key});

  @override
  State<OfferView> createState() => _OfferViewState();
}

class _OfferViewState extends State<OfferView> {
  int selectFilterIndex = 0;

  List filterCategories = [
    {"name": "Tất cả", "icon": "🔥", "key": "all"},
    {"name": "Phở", "icon": "🍜", "key": "phở"},
    {"name": "Bún", "icon": "🍲", "key": "bún"},
    {"name": "Cơm", "icon": "🍚", "key": "cơm"},
    {"name": "Cà phê", "icon": "☕", "key": "cà phê"},
    {"name": "Trà sữa", "icon": "🧋", "key": "trà sữa"},
    {"name": "Bánh ngọt", "icon": "🍰", "key": "bánh ngọt"},
    {"name": "Bánh mì", "icon": "🥖", "key": "bánh mì"},
    {"name": "Bánh sinh nhật", "icon": "🎂", "key": "bánh sinh nhật"},
    {"name": "Kem", "icon": "🍦", "key": "kem"},
  ];

  List offerArr = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRealRestaurantsFromDB();
  }

  Future<void> _loadRealRestaurantsFromDB() async {
    setState(() => isLoading = true);
    final list = await CategoryService.fetchRestaurantsFromDB();
    if (mounted) {
      if (list.isNotEmpty) {
        List formattedList = [];
        for (var res in list) {
          final maQuan = res["maQuan"] ?? res["id"] ?? 0;
          final menu = await CategoryService.fetchRestaurantMenuFromDB(maQuan);
          List featuredItems = [];
          for (var cat in menu) {
            final items = cat["items"] as List? ?? [];
            for (var item in items) {
              featuredItems.add({
                "name": item["name"] ?? "",
                "price": item["price"] ?? 0,
                "image": item["image"] ?? "",
              });
            }
          }

          formattedList.add({
            "id": maQuan,
            "maQuan": maQuan,
            "name": res["tenQuan"] ?? "Quán ăn lộ trình",
            "tenQuan": res["tenQuan"] ?? "Quán ăn lộ trình",
            "address": res["diaChi"] ?? "",
            "diaChi": res["diaChi"] ?? "",
            "rate": "4.9",
            "rating": "128",
            "type": "Món Việt",
            "food_type": "Đặc sản lộ trình",
            "discount": "ƯU ĐÃI LỘ TRÌNH 10K",
            "time": "15-20 phút",
            "gift": "Đặt trước ghé lấy tiện đường",
            "image": res["img"] ?? "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500",
            "featured_items": featuredItems.take(3).toList(),
          });
        }

        setState(() {
          offerArr = formattedList;
          isLoading = false;
        });
      } else {
        setState(() {
          offerArr = [];
          isLoading = false;
        });
      }
    }
  }

  List get filteredOfferArr {
    if (selectFilterIndex == 0) return offerArr;
    final selectedKey = filterCategories[selectFilterIndex]["key"].toString().toLowerCase();
    return offerArr.where((res) {
      final resName = res["name"].toString().toLowerCase();
      final featured = res["featured_items"] as List? ?? [];
      final hasInName = resName.contains(selectedKey);
      final hasInItems = featured.any((item) => item["name"].toString().toLowerCase().contains(selectedKey));
      return hasInName || hasInItems;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayList = filteredOfferArr;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 46),

              // Header Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CỬA HÀNG LỘ TRÌNH",
                          style: TextStyle(
                            color: TColor.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              "Cửa hàng gần bạn",
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: TColor.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
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
                              Icons.shopping_bag_outlined,
                              color: TColor.primaryTextOf(context),
                              size: 20,
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final cartCount = context.watch<CartProvider>().totalItemCount;
                            if (cartCount == 0) return const SizedBox.shrink();
                            return Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: TColor.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "$cartCount",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Filter Chips 2-Row Horizontal Scrollable Grid
              SizedBox(
                height: 90,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 130,
                  ),
                  itemCount: filterCategories.length,
                  itemBuilder: (context, index) {
                    final item = filterCategories[index] as Map;
                    final isSelected = selectFilterIndex == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectFilterIndex = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? TColor.primary
                              : (isDark ? const Color(0xFF1B1E28) : const Color(0xFFEEEEEE)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? TColor.primary
                                : (isDark ? const Color(0xFF2C3240) : Colors.transparent),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item["icon"].toString(),
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item["name"].toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFC0C4D0) : const Color(0xFF555555)),
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

              const SizedBox(height: 20),

              // Restaurant Cards List from DB
              isLoading
                  ? Center(child: CircularProgressIndicator(color: TColor.primary))
                  : displayList.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              "Không tìm thấy cửa hàng nào thuộc danh mục này",
                              style: TextStyle(
                                color: TColor.secondaryTextOf(context),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            var pObj = displayList[index] as Map? ?? {};
                            final featuredItems = pObj["featured_items"] as List? ?? [];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RestaurantDetailView(restaurantObj: pObj),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: TColor.cardOf(context),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: TColor.borderOf(context), width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image Stack Banner
                                    Stack(
                                      children: [
                                        pObj["image"].toString().startsWith("http")
                                            ? Image.network(
                                                pObj["image"].toString(),
                                                width: double.infinity,
                                                height: 160,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  width: double.infinity,
                                                  height: 160,
                                                  color: Colors.grey.shade800,
                                                  child: const Icon(Icons.restaurant, color: Colors.white, size: 40),
                                                ),
                                              )
                                            : Image.asset(
                                                pObj["image"].toString(),
                                                width: double.infinity,
                                                height: 160,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  width: double.infinity,
                                                  height: 160,
                                                  color: Colors.grey.shade800,
                                                  child: const Icon(Icons.restaurant, color: Colors.white, size: 40),
                                                ),
                                              ),
                                        // Gradient Overlay for readability
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withOpacity(0.6),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Top Left Discount Badge
                                        Positioned(
                                          top: 12,
                                          left: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: TColor.primary,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              "🏷️ ${pObj["discount"].toString()}",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Top Right Heart Button
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.45),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.favorite_border_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        // Bottom Right Time Badge
                                        Positioned(
                                          bottom: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.75),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.access_time_rounded,
                                                  color: Colors.white70,
                                                  size: 12,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  pObj["time"].toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Card Content Info
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  pObj["name"].toString(),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: TColor.primaryTextOf(context),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00C853).withOpacity(0.18),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  "Đang mở",
                                                  style: TextStyle(
                                                    color: Color(0xFF00E676),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                pObj["rate"].toString(),
                                                style: TextStyle(
                                                  color: TColor.primary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  "(${pObj["rating"]} Ratings) • ${pObj["type"]} • ${pObj["food_type"]}",
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: TColor.secondaryTextOf(context),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Featured Signature Dishes Preview Row
                                          if (featuredItems.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Text(
                                                  "🔥 Món nổi bật:",
                                                  style: TextStyle(
                                                    color: TColor.primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              height: 56,
                                              child: ListView.builder(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: featuredItems.length,
                                                itemBuilder: (context, fIdx) {
                                                  final item = featuredItems[fIdx];
                                                  final imgUrl = item["image"].toString();
                                                  final formattedPrice = "${(item["price"] as num? ?? 0).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ";

                                                  return Container(
                                                    margin: const EdgeInsets.only(right: 8),
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF161922) : const Color(0xFFF4F4F6),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: TColor.borderOf(context), width: 1),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(8),
                                                          child: imgUrl.startsWith("http")
                                                              ? Image.network(imgUrl, width: 42, height: 42, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.fastfood, color: TColor.primary, size: 20))
                                                              : Image.asset(imgUrl, width: 42, height: 42, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.fastfood, color: TColor.primary, size: 20)),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            ConstrainedBox(
                                                              constraints: const BoxConstraints(maxWidth: 110),
                                                              child: Text(
                                                                item["name"].toString(),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(
                                                                  color: TColor.primaryTextOf(context),
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w700,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(height: 2),
                                                            Text(
                                                              formattedPrice,
                                                              style: TextStyle(
                                                                color: TColor.primary,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.w800,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],

                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF11141D) : const Color(0xFFF7F7F9),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                const Text("🎁", style: TextStyle(fontSize: 13)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    pObj["gift"].toString(),
                                                    style: TextStyle(
                                                      color: TColor.secondaryTextOf(context),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  "Xem menu",
                                                  style: TextStyle(
                                                    color: TColor.primary,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
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
            ],
          ),
        ),
      ),
    );
  }
}
