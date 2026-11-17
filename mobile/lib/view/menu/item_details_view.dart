import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../models/review_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_service.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/dish_reviews_section.dart';
import '../../widgets/dish_customization_section.dart';
import '../../common_widget/smart_network_image.dart';
import '../../common/food_image_helper.dart';
import '../../widgets/single_restaurant_warning_modal.dart';
import '../../common/locator.dart';
import '../../services/socket_service.dart';

class ItemDetailsView extends StatefulWidget {
  final Map itemObj;
  const ItemDetailsView({super.key, required this.itemObj});

  @override
  State<ItemDetailsView> createState() => _ItemDetailsViewState();
}

class _ItemDetailsViewState extends State<ItemDetailsView> {
  late Map<String, dynamic> itemData;
  late double basePrice;
  int qty = 1;
  bool isFav = false;

  bool _isLoadingReviews = true;
  List<ReviewModel> _reviewsList = [];
  double _avgRating = 0.0;
  int _totalReviewsCount = 0;
  String _selectedReviewFilter = "all";

  // Dynamic Customization state
  int selectedOptionIndex = 0;
  List<Map<String, dynamic>> sizeOptions = [];
  List<Map<String, dynamic>> toppingOptions = [];

  final TextEditingController noteController = TextEditingController();
  int? _attachedStoreId;

  @override
  void initState() {
    super.initState();
    itemData = Map<String, dynamic>.from(widget.itemObj);
    basePrice = double.tryParse((itemData["price"] ?? itemData["giaMonAn"] ?? 65000).toString()) ?? 65000.0;

    final rawRate = itemData["rating"] ?? itemData["diemDanhGiaTB"] ?? itemData["danhGiaTrungBinh"] ?? itemData["rate"] ?? 0.0;
    final rawCount = itemData["soLuotDanhGia"] ?? itemData["ratingCount"] ?? itemData["soLuongDanhGia"] ?? itemData["reviewsCount"] ?? 0;
    _avgRating = double.tryParse(rawRate.toString()) ?? 0.0;
    _totalReviewsCount = int.tryParse(rawCount.toString()) ?? 0;

    _initCustomizationOptions();
    _loadDishReviewsAndStats();
    _loadDishLiveDetails();

    _setupRealtimeSync();
  }

  void _setupRealtimeSync() {
    final rawResId = itemData["maQuan"] ?? itemData["restaurantId"];
    _attachedStoreId = int.tryParse(rawResId?.toString() ?? '');
    if (_attachedStoreId != null && _attachedStoreId! > 0) {
      locator<SocketService>().joinRestaurantRoom(_attachedStoreId!);
    }
    locator<SocketService>().listenToMenuUpdates(_onMenuUpdated);
  }

  void _onMenuUpdated(dynamic data) {
    if (!mounted || data == null) return;
    try {
      final food = data['food'];
      final currentDishId = int.tryParse((itemData["maMonAn"] ?? itemData["id"] ?? itemData["foodId"] ?? '').toString());
      final currentResId = int.tryParse((itemData["maQuan"] ?? itemData["restaurantId"] ?? '').toString());
      final updatedResId = int.tryParse(data['maQuan']?.toString() ?? '');

      if (food is Map) {
        final updatedDishId = int.tryParse((food['maMonAn'] ?? food['id'] ?? '').toString());
        if (currentDishId != null && updatedDishId != null && currentDishId == updatedDishId) {
          setState(() {
            itemData.addAll(Map<String, dynamic>.from(food));
            if (food['moTa'] != null) itemData['moTa'] = food['moTa'];
            if (food['mota'] != null) itemData['mota'] = food['mota'];
            if (food['dacTinh'] != null) itemData['dacTinh'] = food['dacTinh'];
            if (food['dactinh'] != null) itemData['dactinh'] = food['dactinh'];
            if (food['giaMonAn'] != null) {
              basePrice = double.tryParse(food['giaMonAn'].toString()) ?? basePrice;
            }
            _initCustomizationOptions();
          });
          return;
        }
      }

      if (currentResId != null && (updatedResId == null || updatedResId == currentResId)) {
        _loadDishLiveDetails();
      }
    } catch (e) {
      debugPrint('[ItemDetails] _onMenuUpdated error: $e');
    }
  }

  @override
  void dispose() {
    if (_attachedStoreId != null && _attachedStoreId! > 0) {
      locator<SocketService>().leaveRestaurantRoom(_attachedStoreId!);
    }
    locator<SocketService>().offMenuUpdates(_onMenuUpdated);
    noteController.dispose();
    super.dispose();
  }

  void _initCustomizationOptions() {
    dynamic rawSizes = itemData["sizes"] ?? itemData["sizeOptions"];
    dynamic rawToppings = itemData["toppings"] ?? itemData["toppingOptions"];

    if (rawSizes == null && rawToppings == null && itemData["options"] != null) {
      try {
        final opt = itemData["options"] is String
            ? jsonDecode(itemData["options"])
            : itemData["options"];
        if (opt is Map) {
          rawSizes = opt["sizes"];
          rawToppings = opt["toppings"];
        }
      } catch (_) {}
    }

    // 1. Initialize Size Options if provided by real database/API
    if (rawSizes is List) {
      sizeOptions = rawSizes
          .map((s) => {
                "name": (s["name"] ?? s["tenKhauPhan"] ?? "").toString(),
                "extra": (s["extra"] as num? ?? s["giaThem"] as num? ?? 0).toDouble(),
              })
          .where((s) => s["name"].toString().trim().isNotEmpty)
          .toList();
    } else {
      final name = (itemData["name"] ?? itemData["tenMonAn"] ?? "").toString().toLowerCase();
      if (_isDrink(name)) {
        sizeOptions = [
          {"name": "Size Vừa (M)", "extra": 0.0},
          {"name": "Size Lớn (L)", "extra": 6000.0},
          {"name": "Size Nhỏ (S)", "extra": 0.0},
        ];
      } else {
        sizeOptions = [
          {"name": "Phần Tiêu Chuẩn", "extra": 0.0},
          {"name": "Phần Lớn (Nhiều hơn)", "extra": 10000.0},
        ];
      }
    }

    if (sizeOptions.isNotEmpty) {
      if (selectedOptionIndex < 0 || selectedOptionIndex >= sizeOptions.length) {
        selectedOptionIndex = 0;
      }
    } else {
      selectedOptionIndex = -1;
    }

    // 2. Initialize Topping Options if provided by real database/API
    if (rawToppings is List) {
      toppingOptions = rawToppings
          .map((t) => {
                "name": (t["name"] ?? t["tenTopping"] ?? "").toString(),
                "extra": (t["extra"] as num? ?? t["giaThem"] as num? ?? 0).toDouble(),
                "selected": false,
              })
          .where((t) => t["name"].toString().trim().isNotEmpty)
          .toList();
    } else {
      final name = (itemData["name"] ?? itemData["tenMonAn"] ?? "").toString().toLowerCase();
      if (_isDrink(name)) {
        toppingOptions = [
          {"name": "Trân châu đen", "extra": 5000.0, "selected": false},
          {"name": "Trân châu trắng", "extra": 5000.0, "selected": false},
          {"name": "Thạch nha đam", "extra": 5000.0, "selected": false},
          {"name": "Pudding trứng", "extra": 7000.0, "selected": false},
        ];
      } else {
        toppingOptions = [];
      }
    }
  }

  bool _isDrink(String name) {
    return name.contains("nước") ||
        name.contains("trà") ||
        name.contains("cà phê") ||
        name.contains("coffee") ||
        name.contains("sữa") ||
        name.contains("sinh tố") ||
        name.contains("nước ép") ||
        name.contains("latte") ||
        name.contains("matcha") ||
        name.contains("chè");
  }

  bool _isCakeOrSweet(String name) {
    return name.contains("bánh") ||
        name.contains("cake") ||
        name.contains("kem") ||
        name.contains("tart") ||
        name.contains("donut") ||
        name.contains("mousse");
  }

  IconData _getIconForTag(String tag) {
    final lower = tag.toLowerCase();
    if (lower.contains('phút') || lower.contains('min') || lower.contains('chế biến') || lower.contains('nấu')) {
      return Icons.access_time_rounded;
    }
    if (lower.contains('kcal') || lower.contains('calo') || lower.contains('protein') || lower.contains('năng lượng')) {
      return Icons.local_fire_department_rounded;
    }
    if (lower.contains('đá') || lower.contains('lạnh') || lower.contains('nóng') || lower.contains('ice') || lower.contains('cold')) {
      return LucideIcons.snowflake;
    }
    if (lower.contains('bánh') || lower.contains('ngọt') || lower.contains('tráng miệng')) {
      return Icons.cake_rounded;
    }
    if (lower.contains('tươi') || lower.contains('sạch') || lower.contains('chay') || lower.contains('clean') || lower.contains('rau')) {
      return Icons.eco_rounded;
    }
    if (lower.contains('thịt') || lower.contains('bò') || lower.contains('gà') || lower.contains('hải sản') || lower.contains('xương')) {
      return Icons.restaurant_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  List<Map<String, dynamic>> _getBadges(Map<String, dynamic> item, String foodName) {
    final rawTraits = item['dacTinh'] ?? item['dactinh'] ?? item['traits'] ?? item['tags'];
    List<String> parsed = [];
    if (rawTraits is List) {
      parsed = rawTraits.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawTraits is String && rawTraits.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTraits);
        if (decoded is List) {
          parsed = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        } else {
          parsed = rawTraits.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        parsed = rawTraits.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    if (parsed.isNotEmpty) {
      return parsed.map((t) => {
        'icon': _getIconForTag(t),
        'text': t,
      }).toList();
    }

    return _getCategoryBadges(foodName);
  }

  List<Map<String, dynamic>> _getCategoryBadges(String foodName) {
    if (_isDrink(foodName.toLowerCase())) {
      return [
        {"icon": Icons.access_time_rounded, "text": "~10 phút"},
        {"icon": Icons.local_fire_department_rounded, "text": "180 kcal"},
        {"icon": LucideIcons.snowflake, "text": "Đá riêng / Nóng"},
      ];
    } else if (_isCakeOrSweet(foodName.toLowerCase())) {
      return [
        {"icon": Icons.access_time_rounded, "text": "~15 phút"},
        {"icon": Icons.local_fire_department_rounded, "text": "320 kcal"},
        {"icon": Icons.cake_rounded, "text": "Bánh tươi mỗi ngày"},
      ];
    } else {
      return [
        {"icon": Icons.access_time_rounded, "text": "~15 phút"},
        {"icon": Icons.local_fire_department_rounded, "text": "580 kcal"},
        {"icon": Icons.eco_rounded, "text": "Nguyên liệu tươi sạch"},
      ];
    }
  }

  Future<void> _loadDishReviewsAndStats() async {
    final rawDishId = itemData["maMonAn"] ??
        itemData["id"] ??
        itemData["dishId"] ??
        itemData["foodId"];

    final int? dishId = int.tryParse(rawDishId?.toString() ?? '');

    if (dishId == null) {
      if (mounted) {
        setState(() {
          _reviewsList = [];
          _totalReviewsCount = 0;
          _isLoadingReviews = false;
        });
      }
      return;
    }

    Map<String, dynamic> res = await ReviewService.fetchDishReviews(dishId, page: 1, limit: 10);

    if (res['success'] == true && mounted) {
      final rawList = res['reviews'];
      final List<ReviewModel> list = rawList is List ? List<ReviewModel>.from(rawList) : [];
      final int dbTotal = res['total'] ?? list.length;

      double avg = 0.0;
      if (list.isNotEmpty) {
        _totalReviewsCount = dbTotal;
        double sum = 0;
        for (var r in list) {
          sum += r.rating;
        }
        avg = (sum / list.length * 10).round() / 10;
      } else {
        _totalReviewsCount = 0;
        avg = 0.0;
      }

      setState(() {
        _reviewsList = list;
        _avgRating = avg;
        _isLoadingReviews = false;
      });
    } else if (mounted) {
      setState(() {
        _reviewsList = [];
        _totalReviewsCount = 0;
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _loadDishLiveDetails() async {
    final rawResId = itemData["maQuan"] ?? itemData["restaurantId"];
    final rawDishId = itemData["maMonAn"] ?? itemData["id"] ?? itemData["foodId"];
    final int? resId = int.tryParse(rawResId?.toString() ?? '');
    final int? dishId = int.tryParse(rawDishId?.toString() ?? '');
    final String dishName = (itemData["name"] ?? itemData["tenMonAn"] ?? '').toString().trim().toLowerCase();

    if (resId != null) {
      try {
        final menu = await CategoryService.fetchRestaurantMenuFromDB(resId);
        for (var cat in menu) {
          final items = cat['items'] as List? ?? [];
          for (var i in items) {
            final iId = int.tryParse((i['id'] ?? i['maMonAn'])?.toString() ?? '');
            final iName = (i['name'] ?? i['tenMonAn'] ?? '').toString().trim().toLowerCase();
            if ((dishId != null && iId == dishId) || (dishName.isNotEmpty && iName == dishName)) {
              if (mounted) {
                setState(() {
                  itemData.addAll(Map<String, dynamic>.from(i));
                  basePrice = double.tryParse((itemData["price"] ?? itemData["giaMonAn"] ?? basePrice).toString()) ?? basePrice;
                  _avgRating = double.tryParse((itemData["rating"] ?? itemData["diemDanhGiaTB"] ?? _avgRating).toString()) ?? _avgRating;
                  _totalReviewsCount = int.tryParse((itemData["soLuongDanhGia"] ?? itemData["ratingCount"] ?? _totalReviewsCount).toString()) ?? _totalReviewsCount;
                  _initCustomizationOptions();
                });
              }
              return;
            }
          }
        }
      } catch (_) {}
    }
  }

  double get calculatedUnitPrice {
    double price = basePrice;
    if (sizeOptions.isNotEmpty && selectedOptionIndex >= 0 && selectedOptionIndex < sizeOptions.length) {
      price += (sizeOptions[selectedOptionIndex]["extra"] ?? 0);
    }
    for (var top in toppingOptions) {
      if (top["selected"] == true) {
        price += (top["extra"] ?? 0);
      }
    }
    return price;
  }

  double get calculatedTotalPrice => calculatedUnitPrice * qty;

  String _formatCurrency(num amount) {
    return "${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ";
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final foodName = itemData["name"] ?? itemData["tenMonAn"] ?? "Món ăn lộ trình";
    final imgUrl = FoodImageHelper.getFoodImage(itemData["image"] ?? itemData["img"] ?? itemData["hinhAnh"], foodName, id: itemData["id"] ?? itemData["maMonAn"] ?? 0);
    final rawDesc = itemData["moTa"] ?? itemData["mota"] ?? itemData["description"];
    final foodDesc = (rawDesc != null && rawDesc.toString().trim().isNotEmpty)
        ? rawDesc.toString().trim()
        : "Món ăn được chế biến tươi nóng từ nguồn nguyên liệu sạch chuẩn vệ sinh an toàn thực phẩm. Đặt trước để ghé lấy nóng hổi không chờ đợi.";
    final badges = _getBadges(itemData, foodName);

    final bool hasExplicitStock = itemData.containsKey("soLuongMon") || itemData.containsKey("quantity");
    final int stockQty = hasExplicitStock
        ? (int.tryParse((itemData["soLuongMon"] ?? itemData["quantity"]).toString()) ?? 0)
        : 99;
    final String status = (itemData["trangThaiMon"] ?? itemData["status"] ?? "").toString().toUpperCase();
    final bool isSoldOut = (hasExplicitStock && stockQty <= 0) ||
        status == 'HET_HANG' ||
        status == 'HET_MON' ||
        status == 'TAM_NGUNG' ||
        status == 'SOLDOUT';
    final int soldQty = int.tryParse((itemData["soLuongDaBan"] ?? itemData["soLuotBan"] ?? itemData["soldCount"] ?? 0).toString()) ?? 0;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image Banner with Gradient & Action Buttons
                Stack(
                  children: [
                    Opacity(
                      opacity: isSoldOut ? 0.5 : 1.0,
                      child: SmartNetworkImage(
                        imageUrl: imgUrl,
                        width: media.width,
                        height: 320,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      width: media.width,
                      height: 320,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Header Nav Buttons
                    Positioned(
                      top: 44,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? Colors.red : Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() => isFav = !isFav);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Bottom Badges Overlay on Image Banner
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (isSoldOut)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.alertTriangle, size: 12, color: Colors.white), const SizedBox(width: 3),
                                  Text(
                                    "Hết Hàng",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (soldQty >= 50)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC107),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.flame, size: 12, color: Color(0xFF111827)), const SizedBox(width: 3),
                                  Text(
                                    "Bán Chạy",
                                    style: TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_totalReviewsCount > 0 && _avgRating > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${_avgRating.toStringAsFixed(1)} ($_totalReviewsCount)",
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          if (soldQty > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Đã bán $soldQty phần",
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Content Sheet
                Container(
                  transform: Matrix4.translationValues(0, -16, 0),
                  decoration: BoxDecoration(
                    color: TColor.bgOf(context),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Food Name Title
                        Text(
                          foodName,
                          style: TextStyle(
                            color: isSoldOut ? TColor.secondaryTextOf(context) : TColor.primaryTextOf(context),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Price & Stock Tag Row
                        Wrap(
                          spacing: 10,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _formatCurrency(basePrice),
                              style: TextStyle(
                                color: isSoldOut ? TColor.secondaryTextOf(context) : const Color(0xFFFF4D00),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _formatCurrency((basePrice * 1.25).toInt()),
                              style: TextStyle(
                                color: TColor.secondaryTextOf(context),
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSoldOut ? const Color(0xFFFEE2E2) : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isSoldOut ? "Hết hàng" : "Còn $stockQty phần",
                                style: TextStyle(
                                  color: isSoldOut ? const Color(0xFFDC2626) : const Color(0xFF059669),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (soldQty > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Đã bán $soldQty phần",
                                  style: TextStyle(
                                    color: TColor.secondaryTextOf(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Rating & Reviews Count Row below Sold Count
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              _totalReviewsCount > 0 && _avgRating > 0
                                  ? "${_avgRating.toStringAsFixed(1)} ($_totalReviewsCount đánh giá)"
                                  : "0.0 (0 đánh giá)",
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          foodDesc,
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Dynamic Category Info Badges Row
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: badges.map((b) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _infoBadge(context, b["icon"] as IconData, b["text"] as String),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Divider(color: TColor.borderOf(context), height: 1),
                        const SizedBox(height: 20),

                        // Customization: Khẩu phần, Topping & Ghi chú cho quán
                        DishCustomizationSection(
                          sizeOptions: sizeOptions,
                          selectedOptionIndex: selectedOptionIndex,
                          onSelectSize: (index) {
                            setState(() => selectedOptionIndex = index);
                          },
                          toppingOptions: toppingOptions,
                          onToggleTopping: (index, selected) {
                            setState(() {
                              toppingOptions[index]["selected"] = selected;
                            });
                          },
                          noteController: noteController,
                          isSoldOut: isSoldOut,
                          formatCurrency: _formatCurrency,
                        ),

                        const SizedBox(height: 24),
                        Divider(color: TColor.borderOf(context), height: 1),
                        const SizedBox(height: 20),

                        // Section 4: Đánh giá & Nhận xét
                        DishReviewsSection(
                          isLoading: _isLoadingReviews,
                          reviewsList: _reviewsList,
                          avgRating: _avgRating,
                          totalReviewsCount: _totalReviewsCount,
                          selectedFilter: _selectedReviewFilter,
                          onFilterChanged: (filter) {
                            setState(() {
                              _selectedReviewFilter = filter;
                            });
                          },
                        ),

                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E232E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Quantity Counter (- 1 +)
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2E3B) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_rounded, color: isSoldOut ? TColor.secondaryTextOf(context) : TColor.primaryTextOf(context), size: 18),
                            onPressed: isSoldOut
                                ? null
                                : () {
                                    if (qty > 1) {
                                      setState(() => qty--);
                                    }
                                  },
                          ),
                          Text(
                            "$qty",
                            style: TextStyle(
                              color: isSoldOut ? TColor.secondaryTextOf(context) : TColor.primaryTextOf(context),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_rounded, color: isSoldOut ? TColor.secondaryTextOf(context) : const Color(0xFFFF4D00), size: 18),
                            onPressed: isSoldOut
                                ? null
                                : () {
                                    if (qty < stockQty || stockQty == 0) {
                                      setState(() => qty++);
                                    } else {
                                      CustomToast.showError(context, "Số lượng trong kho chỉ còn $stockQty món");
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Big Orange Add to Cart Button (Disabled if Sold Out)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSoldOut ? (isDark ? const Color(0xFF2A2E3B) : const Color(0xFFD1D5DB)) : const Color(0xFFFF4D00),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: isSoldOut
                              ? null
                              : () {
                                  final rawFId = itemData["id"] ?? itemData["maMonAn"];
                                  final foodId = rawFId is int ? rawFId : (int.tryParse(rawFId?.toString() ?? '') ?? 1);
                                  final rawResId = itemData["maQuan"] ?? itemData["restaurantId"] ?? itemData["idQuan"];
                                  final resId = rawResId is int ? rawResId : (int.tryParse(rawResId?.toString() ?? '') ?? 1);
                                  final storeName = (itemData["tenQuan"] ?? itemData["restaurantName"] ?? "Quán mới").toString();
                                  final storeAddress = (itemData["diaChi"] ?? itemData["address"] ?? "").toString();

                                  final cart = context.read<CartProvider>();

                                  void doAdd() {
                                    if (storeName.isNotEmpty && !storeName.startsWith('Quán ')) {
                                      cart.registerRestaurant(id: resId, name: storeName, address: storeAddress);
                                    }

                                    final selectedSizeName = sizeOptions.isNotEmpty && selectedOptionIndex >= 0 && selectedOptionIndex < sizeOptions.length
                                        ? sizeOptions[selectedOptionIndex]["name"].toString()
                                        : "";
                                    final selectedToppingNames = toppingOptions.where((t) => t["selected"] == true).map((t) => t["name"].toString()).toList();
                                    final dishNote = noteController.text.trim();

                                    final itemNotes = [
                                      if (selectedToppingNames.isNotEmpty) "Topping: ${selectedToppingNames.join(', ')}",
                                      if (dishNote.isNotEmpty) dishNote,
                                    ].join(" • ");

                                    cart.addToCart(
                                      CartItemModel(
                                        foodId: foodId,
                                        foodName: foodName,
                                        price: calculatedUnitPrice,
                                        quantity: qty,
                                        image: imgUrl,
                                        restaurantId: resId,
                                        restaurantName: storeName,
                                        restaurantAddress: storeAddress,
                                        size: selectedSizeName,
                                        note: itemNotes,
                                      ),
                                    );
                                    CustomToast.showSuccess(context, "Đã thêm $foodName (x$qty) vào giỏ hàng!");
                                    Navigator.pop(context);
                                  }

                                  if (cart.hasConflictWith(resId)) {
                                    final existingResName = cart.activeRestaurantName;
                                    SingleRestaurantWarningModal.show(
                                      context: context,
                                      existingRestaurantName: existingResName.isNotEmpty ? existingResName : 'Quán khác',
                                      newRestaurantName: storeName,
                                      onClearAndOrder: () {
                                        cart.clearCart();
                                        doAdd();
                                      },
                                    );
                                    return;
                                  }

                                  doAdd();
                                },
                          child: Text(
                            isSoldOut
                                ? "Món ăn tạm hết hàng"
                                : "Thêm vào giỏ  •  ${_formatCurrency(calculatedTotalPrice)}",
                            style: TextStyle(
                              color: isSoldOut ? TColor.secondaryTextOf(context) : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2E3B) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TColor.secondaryTextOf(context)),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: TColor.primaryTextOf(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
