import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import '../../common/format_utils.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_service.dart';
import '../more/my_order_view.dart';
import '../../common_widget/smart_network_image.dart';
import '../menu/restaurant_detail_view.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/skeleton/restaurant_card_skeleton.dart';

class OfferView extends StatefulWidget {
  const OfferView({super.key});

  @override
  State<OfferView> createState() => _OfferViewState();
}

class _OfferViewState extends State<OfferView> {
  int selectFilterIndex = 0;

  List filterCategories = [
    {"name": "Tất cả", "icon": LucideIcons.store, "key": "all"},
    {"name": "Phở", "icon": LucideIcons.soup, "key": "phở"},
    {"name": "Bún", "icon": LucideIcons.utensilsCrossed, "key": "bún"},
    {"name": "Cơm", "icon": LucideIcons.utensils, "key": "cơm"},
    {"name": "Cà phê", "icon": LucideIcons.coffee, "key": "cà phê"},
    {"name": "Trà sữa", "icon": LucideIcons.cupSoda, "key": "trà sữa"},
    {"name": "Bánh ngọt", "icon": LucideIcons.cakeSlice, "key": "bánh ngọt"},
    {"name": "Bánh mì", "icon": LucideIcons.sandwich, "key": "bánh mì"},
    {"name": "Bánh sinh nhật", "icon": LucideIcons.cake, "key": "bánh sinh nhật"},
    {"name": "Kem", "icon": LucideIcons.iceCream, "key": "kem"},
  ];

  List offerArr = [];
  bool isLoading = true;

  String _getLocalizedCategoryName(BuildContext context, String key, String defaultName) {
    switch (key.toLowerCase()) {
      case "all":
        return context.l10n.storeFilterAll;
      case "phở":
        return context.l10n.storeFilterPho;
      case "bún":
        return context.l10n.storeFilterNoodles;
      case "cơm":
        return context.l10n.storeFilterRice;
      case "cà phê":
        return context.l10n.storeFilterCoffee;
      case "trà sữa":
        return context.l10n.storeFilterMilkTea;
      case "bánh ngọt":
        return context.l10n.storeFilterPastry;
      case "bánh mì":
        return context.l10n.storeFilterBanhMi;
      case "bánh sinh nhật":
        return context.l10n.storeFilterBirthdayCake;
      case "kem":
        return context.l10n.storeFilterIceCream;
      default:
        return defaultName;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRealRestaurantsFromDB();
  }

  Future<void> _loadRealRestaurantsFromDB() async {
    setState(() => isLoading = true);
    try {
      final list = await CategoryService.fetchRestaurantsFromDB();
      if (!mounted) return;
      if (list.isNotEmpty) {
        final formattedList = await Future.wait(list.map((res) async {
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

          final rawRate = res["danhGiaTrungBinh"] ??
              res["danhgiatrungbinh"] ??
              res["diemDanhGiaTB"] ??
              res["rate"] ??
              res["ratingAvg"];
          final rawCount = res["soLuongDanhGia"] ??
              res["soluongdanhgia"] ??
              res["soLuotDanhGia"] ??
              res["ratingCount"] ??
              res["rating"] ??
              0;
          final int ratingCount = int.tryParse(rawCount.toString()) ?? 0;
          final double rateVal = double.tryParse((rawRate ?? 0).toString()) ?? 0.0;
          final String formattedRate = (ratingCount > 0 && rateVal > 0) ? rateVal.toStringAsFixed(1) : "0.0";

          return {
            "id": maQuan,
            "maQuan": maQuan,
            "name": res["tenQuan"] ?? "Quán ăn lộ trình",
            "tenQuan": res["tenQuan"] ?? "Quán ăn lộ trình",
            "address": res["diaChi"] ?? "",
            "rate": formattedRate,
            "rating": ratingCount.toString(),
            "ratingCount": ratingCount,
            "danhGiaTrungBinh": rateVal,
            "soLuongDanhGia": ratingCount,
            "diemDanhGiaTB": rateVal,
            "soLuotDanhGia": ratingCount,
            "trangThai": res["trangThai"] ?? res["trangthai"] ?? "Đang mở",
            "type": "Món Việt",
            "food_type": "Đặc sản lộ trình",
            "discount": "ƯU ĐÃI LỘ TRÌNH 10K",
            "time": "15-20 phút",
            "gift": "Đặt trước ghé lấy tiện đường",
            "image": res["img"] ?? "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500",
            "featured_items": featuredItems.take(3).toList(),
          };
        }));

        if (mounted) {
          setState(() {
            offerArr = formattedList;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            offerArr = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayList = filteredOfferArr;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: RefreshIndicator(
        onRefresh: _loadRealRestaurantsFromDB,
        color: TColor.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                          context.l10n.storeRouteHeader,
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
                              context.l10n.storeNearbyTitle,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NotificationBell(
                          backgroundColor: TColor.cardOf(context),
                          iconColor: TColor.primaryTextOf(context),
                          border: Border.all(color: TColor.borderOf(context), width: 1),
                        ),
                        const SizedBox(width: 8),
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
                    mainAxisExtent: 135,
                  ),
                  itemCount: filterCategories.length,
                  itemBuilder: (context, index) {
                    final item = filterCategories[index] as Map;
                    final isSelected = selectFilterIndex == index;
                    final iconData = item["icon"] is IconData ? item["icon"] as IconData : null;

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
                            if (iconData != null) ...[
                              Icon(
                                iconData,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? const Color(0xFFFC6011) : const Color(0xFFFC6011)),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                _getLocalizedCategoryName(context, item["key"].toString(), item["name"].toString()),
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
                  ? const RestaurantSkeletonList(itemCount: 3)
                  : displayList.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.storefront_outlined,
                                  size: 40,
                                  color: TColor.secondaryTextOf(context).withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  context.l10n.storeNoFound,
                                  style: TextStyle(
                                    color: TColor.secondaryTextOf(context),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _loadRealRestaurantsFromDB,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: Text(context.l10n.storeReloadButton),
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

                            final rawDiscount = pObj["discount"].toString();
                            final discountText = rawDiscount == "ƯU ĐÃI LỘ TRÌNH 10K"
                                ? context.l10n.storeBadgeRouteDiscount10k
                                : rawDiscount;

                            final rawTime = pObj["time"].toString();
                            final timeText = rawTime == "15-20 phút"
                                ? context.l10n.storePrepTime15to20
                                : (Localizations.localeOf(context).languageCode == 'en'
                                    ? rawTime.replaceAll('phút', 'mins')
                                    : rawTime);

                            final String rawStatus = (pObj["trangThai"] ?? "mở cửa").toString().toLowerCase().trim();
                            final bool isStoreClosed = rawStatus == 'đóng cửa' || rawStatus == 'ngưng kinh doanh' || rawStatus == 'closed';

                            final ratingCount = int.tryParse((pObj["rating"] ?? 0).toString()) ?? 0;
                            final ratingsText = context.l10n.storeRatingsCount(ratingCount);
                            final cuisineText = pObj["type"] == "Món Việt" ? context.l10n.storeCuisineVietnamese : pObj["type"].toString();
                            final foodTypeText = pObj["food_type"] == "Đặc sản lộ trình" ? context.l10n.storeRouteSpecialty : pObj["food_type"].toString();

                            final rawGift = pObj["gift"].toString();
                            final giftText = rawGift == "Đặt trước ghé lấy tiện đường"
                                ? context.l10n.storeGiftRoutePickup
                                : rawGift;

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
                                        SmartNetworkImage(
                                          imageUrl: pObj["image"].toString(),
                                          width: double.infinity,
                                          height: 160,
                                          fit: BoxFit.cover,
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
                                              discountText,
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
                                                  timeText,
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
                                                  color: (isStoreClosed ? const Color(0xFFFF5252) : const Color(0xFF00C853)).withValues(alpha: 0.18),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isStoreClosed ? context.l10n.storeStatusClosed : context.l10n.storeStatusOpen,
                                                  style: TextStyle(
                                                    color: isStoreClosed ? const Color(0xFFFF5252) : const Color(0xFF00E676),
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
                                                  "$ratingsText • $cuisineText • $foodTypeText",
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
                                                  context.l10n.storeFeaturedDishes,
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
                                                  final formattedPrice = FormatUtils.formatCurrency(item["price"], locale: Localizations.localeOf(context));

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
                                                          child: SmartNetworkImage(
                                                            imageUrl: imgUrl,
                                                            width: 42,
                                                            height: 42,
                                                            fit: BoxFit.cover,
                                                            placeholderIcon: Icons.fastfood,
                                                          ),
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
                                                const Icon(LucideIcons.gift, size: 13, color: Color(0xFFFC6011)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    giftText,
                                                    style: TextStyle(
                                                      color: TColor.secondaryTextOf(context),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  context.l10n.storeViewMenu,
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
    ),
  );
  }
}
