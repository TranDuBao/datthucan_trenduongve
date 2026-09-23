import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import 'package:food_delivery/providers/language_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/map_provider.dart';
import '../../services/category_service.dart';
import '../more/my_order_view.dart';
import 'menu_items_view.dart';
import 'item_details_view.dart';
import '../../widgets/route_pickup_food_card.dart';
import '../../screens/home_screen.dart';
import '../main_tabview/main_tabview.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  TextEditingController txtSearch = TextEditingController();
  bool isLoading = true;
  List<CategoryModel> categoryList = [];
  List<dynamic> flashSaleItems = [];
  List<dynamic> routePickupFoods = [];

  Timer? _flashSaleTimer;
  int _flashSaleSeconds = 0;

  void _updateRemainingTime() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final diff = endOfDay.difference(now).inSeconds;
    _flashSaleSeconds = diff > 0 ? diff : 0;
  }

  void _startFlashSaleTimer() {
    _updateRemainingTime();
    _flashSaleTimer?.cancel();
    _flashSaleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateRemainingTime();
        });
      }
    });
  }
  final List<Map<String, String>> quickCategories = [
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
  void initState() {
    super.initState();
    _startFlashSaleTimer();
    _loadCategoriesFromDB();
  }

  @override
  void dispose() {
    _flashSaleTimer?.cancel();
    txtSearch.dispose();
    super.dispose();
  }

  String get _flashSaleHours => (_flashSaleSeconds ~/ 3600).toString().padLeft(2, '0');
  String get _flashSaleMinutes => ((_flashSaleSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  String get _flashSaleSecs => (_flashSaleSeconds % 60).toString().padLeft(2, '0');

  Widget _buildTimerBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _loadCategoriesFromDB() async {
    setState(() => isLoading = true);
    final restaurants = await CategoryService.fetchRestaurantsFromDB();
    if (mounted && restaurants.isNotEmpty) {
      List<dynamic> allFoods = [];
      List<CategoryModel> categoryListResult = [];

      for (var res in restaurants) {
        final resId = res["maQuan"] ?? res["id"];
        final storeName = res["tenQuan"] ?? res["name"] ?? "Cửa hàng";
        final storeLat = (res["lat"] as num?)?.toDouble() ?? 10.762622;
        final storeLng = (res["lng"] as num?)?.toDouble() ?? 106.682029;

        if (resId != null) {
          final rawMenu = await CategoryService.fetchRestaurantMenuFromDB(resId);
          for (var cat in rawMenu) {
            final itemsList = cat["items"] as List? ?? [];
            for (var item in itemsList) {
              final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
              itemMap["tenQuan"] = itemMap["tenQuan"] ?? storeName;
              itemMap["lat"] = itemMap["lat"] ?? storeLat;
              itemMap["lng"] = itemMap["lng"] ?? storeLng;
              allFoods.add(itemMap);
            }

            if (categoryListResult.length < 8) {
              final catImage = itemsList.isNotEmpty && itemsList.first["image"] != null && itemsList.first["image"].toString().startsWith("http")
                  ? itemsList.first["image"].toString()
                  : (res["img"] ?? 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500');

              categoryListResult.add(CategoryModel(
                id: cat["id"] ?? 0,
                maQuan: resId,
                key: cat["name"]?.toString().toLowerCase() ?? 'cat',
                name: cat["name"] ?? 'Danh mục',
                image: catImage,
                itemsCount: cat["itemsCount"] ?? itemsList.length,
                items: itemsList,
              ));
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          categoryList = categoryListResult;
          flashSaleItems = allFoods.take(6).toList();
          routePickupFoods = allFoods.toList();
          isLoading = false;
        });
        return;
      }
    }

    final list = await CategoryService.fetchCategoriesFromDB();
    if (mounted) {
      setState(() {
        categoryList = list;
        isLoading = false;
      });
    }
  }

  void _openMapTab(BuildContext context) {
    context.read<MapProvider>().goToMyLocation();
    final mainTabState = context.findAncestorStateOfType<MainTabViewState>();
    if (mainTabState != null) {
      mainTabState.changeTab(2);
    } else {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainTabView(initialTab: 2)), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final mapProv = context.watch<MapProvider>();
    final userLat = mapProv.currentPosition.latitude;
    final userLng = mapProv.currentPosition.longitude;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Location & Pickup Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _openMapTab(context),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B1E28) : const Color(0xFFFFF4EE),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFFFE5D6),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFC6011),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "TIỆN ĐƯỜNG GHÉ LẤY",
                                          style: TextStyle(
                                            color: TColor.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFFC6011), size: 16),
                                      ],
                                    ),
                                    Text(
                                      mapProv.isLoadingLocation
                                          ? "Đang xác định vị trí..."
                                          : mapProv.currentLocationText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: TColor.primaryTextOf(context),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFC6011),
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

              const SizedBox(height: 14),

              // 2. Search Bar Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: TColor.textfieldOf(context),
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: TColor.borderOf(context), width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFFFC6011), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: txtSearch,
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm phở bò, trà sữa, quán gần...",
                            hintStyle: TextStyle(
                              color: TColor.secondaryTextOf(context).withOpacity(0.7),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262A36) : const Color(0xFFFFF0E6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          "Gần đây",
                          style: TextStyle(
                            color: TColor.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Hero Promo Banner Carousel (Gradient Orange to Green)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFC6011), Color(0xFF00C853)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFC6011).withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "⚡ ƯU ĐÃI GHÉ LẤY",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "QUÁN NGON SÀI GÒN\nGIẢM 40.000Đ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Đặt trước 15p - Ghé là lấy ngay",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              image: const DecorationImage(
                                image: NetworkImage("https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500"),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD32F2F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "-40K",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Quick Categories 8 Icons Grid
              Padding(
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
                  itemCount: quickCategories.length,
                  itemBuilder: (context, index) {
                    final cat = quickCategories[index];
                    final bgColor = Color(int.parse(cat["bg"]!));
                    final textColor = Color(int.parse(cat["color"]!));

                    return GestureDetector(
                      onTap: () {},
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F2430) : bgColor,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: isDark ? const Color(0xFF2E3545) : Colors.transparent),
                            ),
                            alignment: Alignment.center,
                            child: Text(cat["icon"]!, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat["name"]!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF333333), fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 5. Flash Sale Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text("⚡ FLASH SALE", style: TextStyle(color: Color(0xFFD32F2F), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    _buildTimerBox(_flashSaleHours),
                    const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildTimerBox(_flashSaleMinutes),
                    const Text(" : ", style: TextStyle(fontWeight: FontWeight.bold)),
                    _buildTimerBox(_flashSaleSecs),
                    const Spacer(),
                    Text("Xem tất cả >", style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Flash Sale Horizontal List
              SizedBox(
                height: 195,
                child: flashSaleItems.isEmpty
                    ? Center(child: CircularProgressIndicator(color: TColor.primary))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: flashSaleItems.length,
                        itemBuilder: (context, index) {
                          final item = flashSaleItems[index];
                          final name = item["name"] ?? "Món ngon";
                          final price = (item["price"] as num? ?? 50000).toInt();
                          final oldPrice = (price * 1.4).toInt();
                          final img = item["image"] ?? "";

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
                              width: 135,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: TColor.cardOf(context),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: TColor.borderOf(context), width: 1),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    children: [
                                      img.toString().startsWith("http")
                                          ? Image.network(
                                              img.toString(),
                                              width: 135,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey),
                                            )
                                          : Image.asset(
                                              img.toString(),
                                              width: 135,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey),
                                            ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD32F2F),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "-35%",
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(Icons.access_time, color: Colors.white70, size: 10),
                                              SizedBox(width: 2),
                                              Text("7p", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Text(
                                              "${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                              style: TextStyle(
                                                color: TColor.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${oldPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                              style: TextStyle(
                                                color: TColor.secondaryTextOf(context),
                                                fontSize: 10,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: 0.85,
                                            minHeight: 4,
                                            backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                                            color: const Color(0xFFD32F2F),
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

              const SizedBox(height: 24),

              // 6. Thực Đơn Quán Tuyển Chọn (Featured Menu Groups Section)
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

              // Real DB Category Cards List
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
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: categoryList.length,
                          itemBuilder: (context, index) {
                            var mObj = categoryList[index];

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
                                    // Food Category Thumbnail Banner with Badge
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

              const SizedBox(height: 24),

              // 7. Tiện Đường Ghé Lấy (Route Pickup Foods Section Grid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tiện Đường Ghé Lấy",
                            style: TextStyle(
                              color: TColor.primaryTextOf(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Cách bạn dưới 800m • Làm nóng trong 5 phút",
                            style: TextStyle(
                              color: TColor.secondaryTextOf(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => _openMapTab(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: TColor.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Text("Bản đồ", style: TextStyle(color: TColor.primary, fontSize: 11, fontWeight: FontWeight.w800)),
                            const SizedBox(width: 4),
                            const Icon(Icons.map_outlined, color: Color(0xFFFC6011), size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Route Pickup Foods Horizontal Scroll List
              if (routePickupFoods.isNotEmpty)
                SizedBox(
                  height: 225,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: routePickupFoods.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => RoutePickupFoodCard(
                      item: routePickupFoods[index],
                      width: 160,
                      userLat: userLat,
                      userLng: userLng,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
