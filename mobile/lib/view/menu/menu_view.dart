import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import 'package:food_route/providers/language_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/map_provider.dart';
import '../../services/category_service.dart';
import '../../common/string_utils.dart';
import '../more/my_order_view.dart';
import '../../widgets/route_pickup_food_card.dart';
import '../../widgets/notification_bell.dart';
import '../main_tabview/main_tabview.dart';
import '../../widgets/menu/quick_categories_widget.dart';
import '../../widgets/menu/flash_sale_section_widget.dart';
import '../../widgets/menu/menu_filtered_foods_widget.dart';
import '../../widgets/menu/menu_categories_section_widget.dart';
import '../../models/banner_item_model.dart';
import '../../services/banner_service.dart';
import '../../widgets/menu/menu_banner_carousel.dart';
import 'flash_sale_all_view.dart';

class MenuView extends StatefulWidget {
  const MenuView({super.key});

  @override
  State<MenuView> createState() => _MenuViewState();
}

class _MenuViewState extends State<MenuView> {
  final TextEditingController txtSearch = TextEditingController();
  bool isLoading = true;
  List<CategoryModel> categoryList = [];
  List<dynamic> flashSaleItems = [];
  List<dynamic> allFlashSaleFoods = [];
  List<dynamic> routePickupFoods = [];
  List<dynamic> allFoodsList = [];
  List<BannerItemModel> _bannersList = [];

  String _searchQuery = '';
  String? _selectedCategory;

  Timer? _flashSaleTimer;
  int _flashSaleSeconds = 0;
  int? _lastCycleIndex;

  void _updateRemainingTime() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const fiveHoursMs = 5 * 3600 * 1000;
    final cycleIndex = nowMs ~/ fiveHoursMs;
    final remainingMs = fiveHoursMs - (nowMs % fiveHoursMs);
    _flashSaleSeconds = remainingMs ~/ 1000;

    if (_lastCycleIndex != null && _lastCycleIndex != cycleIndex) {
      _lastCycleIndex = cycleIndex;
      _reloadFlashSaleItems(cycleIndex);
    } else {
      _lastCycleIndex ??= cycleIndex;
    }
  }

  void _reloadFlashSaleItems(int cycleIndex) {
    if (allFoodsList.isEmpty) return;
    final available = allFoodsList.where((f) {
      final isSoldOut = _isSoldOutItem(f is Map ? f : {});
      return !isSoldOut;
    }).toList();

    final listToPick = available.isNotEmpty ? available : allFoodsList;
    final rnd = math.Random(cycleIndex);
    final shuffled = List<dynamic>.from(listToPick)..shuffle(rnd);
    final picked20 = shuffled.take(20).toList();

    if (mounted) {
      setState(() {
        allFlashSaleFoods = picked20;
        flashSaleItems = picked20.take(6).toList();
      });
    }
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

  @override
  void initState() {
    super.initState();
    txtSearch.addListener(() {
      if (mounted) {
        final currentText = txtSearch.text.trim();
        if (_searchQuery != currentText) {
          setState(() {
            _searchQuery = currentText;
            if (_searchQuery.isNotEmpty && _selectedCategory != null) {
              _selectedCategory = null;
            }
          });
        }
      }
    });
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

  bool _isSoldOutItem(dynamic item) {
    if (item is! Map) return true;
    final int qty = int.tryParse((item['soLuongMon'] ?? item['quantity'] ?? item['soLuong'] ?? 0).toString()) ?? 0;
    final String status = (item['trangThaiMon'] ?? item['status'] ?? '').toString().toUpperCase();
    return qty <= 0 || status == 'HET_HANG' || status == 'HET_MON' || status == 'TAM_NGUNG';
  }

  bool _isDrink(String text) {
    return text.contains("tra sua") ||
        text.contains("ca phe") ||
        text.contains("coffee") ||
        text.contains("matcha") ||
        text.contains("nuoc sam") ||
        text.contains("tra tac") ||
        text.contains("tra da") ||
        text.contains("tra cung dinh") ||
        text.contains("giai khat") ||
        text.contains("sinh to") ||
        text.contains("nuoc ep") ||
        text.contains("nuoc giai khat") ||
        (text.contains("tra ") && !text.contains("trang mieng") && !text.contains("trang tri"));
  }

  bool _isRice(String text) {
    return text.contains("com") ||
        text.contains("com tam") ||
        text.contains("com suon") ||
        text.contains("com ga") ||
        text.contains("com chien") ||
        text.contains("canh kho qua");
  }

  bool _isNoodle(String text) {
    return text.contains("pho") ||
        text.contains("bun bo") ||
        text.contains("bun") ||
        text.contains("hu tieu") ||
        text.contains("mien") ||
        text.contains("noodle");
  }

  bool _isSnackDessert(String text) {
    return text.contains("banh sinh nhat") ||
        text.contains("kem") ||
        text.contains("che") ||
        text.contains("quay") ||
        text.contains("trung chen") ||
        text.contains("cha cua") ||
        text.contains("banh loc") ||
        text.contains("an kem");
  }

  bool _isBakeryFast(String text) {
    return text.contains("croissant") ||
        text.contains("banh mi") ||
        text.contains("burger") ||
        text.contains("sandwich") ||
        text.contains("xoi") ||
        text.contains("pizza");
  }

  bool _matchesCategory(Map item, String category) {
    final name = (item["name"] ?? item["tenMonAn"] ?? "").toString();
    final catName = (item["categoryName"] ?? item["tenDanhMuc"] ?? "").toString();
    final combined = "$name $catName";
    final norm = StringUtils.removeDiacritics(combined);

    switch (category) {
      case "Món Giảm 50%":
        final price = (item["price"] ?? item["gia"] ?? item["giaMonAn"] ?? 0) as num;
        final originalPrice = (item["originalPrice"] ?? item["giaGoc"] ?? 0) as num;
        if (originalPrice > price) return true;
        return price <= 35000;

      case "Trà Sữa / Cà Phê":
        return _isDrink(norm) && !_isRice(norm) && !_isNoodle(norm);

      case "Phở & Bún Nóng":
        return _isNoodle(norm) && !_isRice(norm) && !_isDrink(norm);

      case "Cơm Trưa Nóng":
        return _isRice(norm) && !_isSnackDessert(norm) && !_isDrink(norm) && !_isNoodle(norm);

      case "Bánh Mì & Nhanh":
        return _isBakeryFast(norm) && !_isRice(norm) && !_isNoodle(norm);

      case "Ăn Kèm & Vặt":
        return _isSnackDessert(norm) && !_isRice(norm) && !_isNoodle(norm);

      case "Eat Clean Healthy":
        return norm.contains("clean") ||
            norm.contains("healthy") ||
            norm.contains("salad") ||
            norm.contains("chay") ||
            norm.contains("nuoc sam") ||
            norm.contains("hat chia") ||
            norm.contains("rau");

      case "Ghé Lấy 0Đ":
      default:
        return true;
    }
  }

  bool _matchesSearch(Map item, String query) {
    if (query.trim().isEmpty) return true;
    final name = (item["name"] ?? item["tenMonAn"] ?? "").toString();
    final catName = (item["categoryName"] ?? item["tenDanhMuc"] ?? "").toString();

    // Prioritize food name and category matching
    if (StringUtils.fuzzyMatch(name, query)) return true;
    if (StringUtils.fuzzyMatch(catName, query)) return true;

    // Only match restaurant name if query is long enough
    final storeName = (item["tenQuan"] ?? item["storeName"] ?? "").toString();
    if (query.trim().length >= 4 && StringUtils.fuzzyMatch(storeName, query)) {
      return true;
    }

    return false;
  }

  List<dynamic> get filteredFoods {
    return allFoodsList.where((item) {
      if (item is! Map) return false;

      // Exclude sold out / 0 quantity items
      if (_isSoldOutItem(item)) {
        return false;
      }

      if (_selectedCategory != null && !_matchesCategory(item, _selectedCategory!)) {
        return false;
      }
      if (_searchQuery.isNotEmpty && !_matchesSearch(item, _searchQuery)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get _currentSuggestions {
    if (_searchQuery.isEmpty) {
      return ["Cơm", "Phở", "Trà sữa", "Cà phê", "Bánh mì", "Bún bò"];
    }

    final queryNorm = StringUtils.removeDiacritics(_searchQuery);
    final suggestions = <String>{};

    if (queryNorm.contains("com") || "com".contains(queryNorm)) {
      suggestions.add("Cơm tấm");
      suggestions.add("Cơm sườn");
      suggestions.add("Cơm tấm bì chả");
    } else if (queryNorm.contains("pho") || "pho".contains(queryNorm)) {
      suggestions.add("Phở bò tái");
      suggestions.add("Phở bò nạm");
      suggestions.add("Phở đặc biệt");
    } else if (queryNorm.contains("bun") || "bun".contains(queryNorm)) {
      suggestions.add("Bún bò Huế");
      suggestions.add("Bún bò giò heo");
      suggestions.add("Bún bò tái");
    } else if (queryNorm.contains("tra") || "tra".contains(queryNorm)) {
      suggestions.add("Trà sữa Phúc Long");
      suggestions.add("Trà tắc xí muội");
      suggestions.add("Trà đá thốt nốt");
    } else if (queryNorm.contains("ca phe") || "ca phe".contains(queryNorm)) {
      suggestions.add("Cà phê sữa đá");
      suggestions.add("Cà phê phin sữa");
    }

    for (var item in allFoodsList) {
      if (item is Map) {
        final name = (item["name"] ?? item["tenMonAn"] ?? "").toString();
        if (StringUtils.fuzzyMatch(name, _searchQuery) && name.isNotEmpty) {
          suggestions.add(name);
          if (suggestions.length >= 6) break;
        }
      }
    }

    return suggestions.toList();
  }

  void _sortMenuItems(List<dynamic> items) {
    items.sort((a, b) {
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
  }

  Future<void> _loadCategoriesFromDB() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        CategoryService.fetchCategoriesFromDB(),
        CategoryService.fetchFoodsOverviewFromDB(),
        BannerService.fetchBanners(),
      ]);
      final cats = results[0] as List<CategoryModel>;
      final foods = results[1] as List<dynamic>;
      final banners = results[2] as List<BannerItemModel>;

      _sortMenuItems(foods);

      // Tự động gán hình ảnh và số lượng món ăn thực tế từ DB cho từng nhóm món
      final enrichedCats = cats.map((cat) {
        final catFoods = foods.where((f) {
          if (f is! Map) return false;
          final fCatId = f['maDanhMuc'] ?? f['idDanhMuc'];
          if (fCatId != null && int.tryParse(fCatId.toString()) == cat.id) {
            return true;
          }
          final fCatName = (f['tenDanhMuc'] ?? f['categoryName'] ?? '').toString().trim().toLowerCase();
          return fCatName.isNotEmpty && fCatName == cat.name.trim().toLowerCase();
        }).toList();

        final actualCount = catFoods.length;

        String foodImg = cat.image;
        if (foodImg.isEmpty || foodImg.startsWith('assets/')) {
          final matchFood = catFoods.firstWhere(
            (f) => (f['image'] ?? f['img'] ?? f['hinhAnh'] ?? '').toString().isNotEmpty,
            orElse: () => null,
          );
          if (matchFood != null) {
            foodImg = (matchFood['image'] ?? matchFood['img'] ?? matchFood['hinhAnh'] ?? '').toString();
          }
        }

        return CategoryModel(
          id: cat.id,
          maQuan: cat.maQuan,
          key: cat.key,
          name: cat.name,
          image: foodImg,
          itemsCount: actualCount,
          isHot: actualCount > 0,
          items: catFoods,
        );
      }).toList();

      if (mounted) {
        setState(() {
          allFoodsList = foods.toList();
          categoryList = enrichedCats;
          routePickupFoods = foods.toList();
          _bannersList = banners;
          isLoading = false;
        });
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        const fiveHoursMs = 5 * 3600 * 1000;
        final cycleIndex = nowMs ~/ fiveHoursMs;
        _lastCycleIndex = cycleIndex;
        _reloadFlashSaleItems(cycleIndex);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
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

  String _formatPickupSubtitle(double uLat, double uLng) {
    if (routePickupFoods.isEmpty) {
      return "Tiện đường ghé lấy món nóng hổi ngay trên lộ trình";
    }

    double minDistance = double.infinity;
    int minPrep = 5;

    for (final item in routePickupFoods) {
      if (item is Map) {
        final sLat = (item["lat"] as num?)?.toDouble();
        final sLng = (item["lng"] as num?)?.toDouble();
        if (sLat != null && sLng != null && sLat != 0 && sLng != 0) {
          const p = 0.017453292519943295;
          final a = 0.5 - math.cos((sLat - uLat) * p) / 2 +
              math.cos(uLat * p) * math.cos(sLat * p) *
                  (1 - math.cos((sLng - uLng) * p)) / 2;
          final meters = 12742 * math.asin(math.sqrt(a)) * 1000;
          if (meters < minDistance) {
            minDistance = meters;
            final rawPrep = item["thoiGianChuanBi"] ?? item["prepTime"];
            if (rawPrep != null) {
              final parsed = int.tryParse(rawPrep.toString());
              if (parsed != null && parsed > 0) minPrep = parsed;
            }
          }
        }
      }
    }

    String distText;
    if (minDistance.isInfinite || minDistance < 100) {
      distText = "Cách bạn từ 150m";
    } else if (minDistance < 1000) {
      distText = "Cách bạn từ ${minDistance.round()}m";
    } else {
      distText = "Cách bạn từ ${(minDistance / 1000).toStringAsFixed(1)}km";
    }

    return "$distText • Chuẩn bị nhanh từ ${minPrep}p";
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final mapProv = context.watch<MapProvider>();
    final userLat = mapProv.currentPosition.latitude;
    final userLng = mapProv.currentPosition.longitude;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isFiltering = _searchQuery.isNotEmpty || _selectedCategory != null;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCategoriesFromDB,
          color: TColor.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    const SizedBox(width: 8),
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
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                              if (_searchQuery.isNotEmpty && _selectedCategory != null) {
                                _selectedCategory = null;
                              }
                            });
                          },
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm phở bò, cơm tấm, trà sữa...",
                            hintStyle: TextStyle(
                              color: TColor.secondaryTextOf(context).withOpacity(0.7),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    color: TColor.secondaryTextOf(context),
                                    onPressed: () {
                                      txtSearch.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 3. Hero Promo Banner Carousel (Dynamic Admin Banners)
              MenuBannerCarousel(banners: _bannersList),

              const SizedBox(height: 20),

              // 4. Quick Categories 8 Icons Grid
              QuickCategoriesWidget(
                selectedCategory: _selectedCategory,
                onCategorySelected: (catName) {
                  setState(() {
                    if (_selectedCategory == catName) {
                      _selectedCategory = null;
                    } else {
                      _selectedCategory = catName;
                      txtSearch.clear();
                      _searchQuery = '';
                    }
                  });
                },
              ),

              // 5. Conditional Rendering: Filtered List or Standard Sections
              if (isFiltering)
                MenuFilteredFoodsWidget(
                  filteredFoods: filteredFoods,
                  searchQuery: _searchQuery,
                  selectedCategory: _selectedCategory,
                  onClearFilter: () {
                    setState(() {
                      _selectedCategory = null;
                      txtSearch.clear();
                      _searchQuery = '';
                    });
                  },
                )
              else ...[
                const SizedBox(height: 24),

                // Flash Sale Section
                FlashSaleSectionWidget(
                  flashSaleItems: flashSaleItems,
                  hours: _flashSaleHours,
                  minutes: _flashSaleMinutes,
                  seconds: _flashSaleSecs,
                  onViewAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FlashSaleAllView(
                          flashSaleItems: allFlashSaleFoods,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Category Groups Section
                MenuCategoriesSectionWidget(
                  categoryList: categoryList,
                  isLoading: isLoading,
                  onRetry: _loadCategoriesFromDB,
                ),

                const SizedBox(height: 24),

                // Tiện Đường Ghé Lấy (Route Pickup Foods Section)
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
                              _formatPickupSubtitle(userLat, userLng),
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
                        width: 165,
                        userLat: userLat,
                        userLng: userLng,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }
}
