import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../models/review_model.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_service.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/skeleton/skeleton_box.dart';
import '../../widgets/dish_reviews_section.dart';
import '../../common_widget/smart_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    itemData = Map<String, dynamic>.from(widget.itemObj);
    basePrice = double.tryParse((itemData["price"] ?? itemData["giaMonAn"] ?? 65000).toString()) ?? 65000.0;

    _avgRating = double.tryParse((itemData["danhGiaTrungBinh"] ?? itemData["rating"] ?? 0.0).toString()) ?? 0.0;
    _totalReviewsCount = int.tryParse((itemData["soLuongDanhGia"] ?? 0).toString()) ?? 0;

    _initCustomizationOptions();
    _loadDishReviewsAndStats();
    _loadDishLiveDetails();
  }

  void _initCustomizationOptions() {
    // 1. Initialize Size Options if provided by real database/API
    if (itemData["sizes"] is List && (itemData["sizes"] as List).isNotEmpty) {
      sizeOptions = (itemData["sizes"] as List).map((s) => Map<String, dynamic>.from(s)).toList();
    } else if (itemData["sizeOptions"] is List && (itemData["sizeOptions"] as List).isNotEmpty) {
      sizeOptions = (itemData["sizeOptions"] as List).map((s) => Map<String, dynamic>.from(s)).toList();
    } else {
      sizeOptions = [];
    }

    // 2. Initialize Topping Options if provided by real database/API
    if (itemData["toppings"] is List && (itemData["toppings"] as List).isNotEmpty) {
      toppingOptions = (itemData["toppings"] as List)
          .map((t) => Map<String, dynamic>.from(t)..putIfAbsent("selected", () => false))
          .toList();
    } else if (itemData["toppingOptions"] is List && (itemData["toppingOptions"] as List).isNotEmpty) {
      toppingOptions = (itemData["toppingOptions"] as List)
          .map((t) => Map<String, dynamic>.from(t)..putIfAbsent("selected", () => false))
          .toList();
    } else {
      toppingOptions = [];
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

  List<Map<String, dynamic>> _getCategoryBadges(String foodName) {
    if (_isDrink(foodName.toLowerCase())) {
      return [
        {"icon": Icons.access_time_rounded, "text": "~10 phút"},
        {"icon": Icons.local_fire_department_rounded, "text": "180 kcal"},
        {"icon": Icons.ac_unit_rounded, "text": "🧊 Đá riêng / Nóng"},
      ];
    } else if (_isCakeOrSweet(foodName.toLowerCase())) {
      return [
        {"icon": Icons.access_time_rounded, "text": "~15 phút"},
        {"icon": Icons.local_fire_department_rounded, "text": "320 kcal"},
        {"icon": Icons.cake_rounded, "text": "🍰 Bánh tươi mỗi ngày"},
      ];
    } else {
      return [
        {"icon": Icons.access_time_rounded, "text": "~15 phút"},
        {"icon": Icons.local_fire_department_rounded, "text": "580 kcal"},
        {"icon": Icons.eco_rounded, "text": "🌱 Nguyên liệu tươi sạch"},
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

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
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

  String _getInitials(String name) {
    if (name.trim().isEmpty) return "KH";
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1)).toUpperCase();
  }

  String _formatTimeAgo(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays >= 30) {
        final months = (diff.inDays / 30).floor();
        return '$months tháng trước';
      } else if (diff.inDays >= 7) {
        final weeks = (diff.inDays / 7).floor();
        return '$weeks tuần trước';
      } else if (diff.inDays >= 1) {
        return '${diff.inDays} ngày trước';
      } else if (diff.inHours >= 1) {
        return '${diff.inHours} giờ trước';
      } else if (diff.inMinutes >= 1) {
        return '${diff.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (_) {
      return dateStr.length > 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }

  List<ReviewModel> get _filteredReviews {
    if (_selectedReviewFilter == "image") {
      return _reviewsList.where((r) => r.image != null && r.image!.isNotEmpty).toList();
    } else if (_selectedReviewFilter == "5star") {
      return _reviewsList.where((r) => r.rating == 5).toList();
    } else if (_selectedReviewFilter == "latest") {
      final list = List<ReviewModel>.from(_reviewsList);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }
    return _reviewsList;
  }
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final foodName = itemData["name"] ?? itemData["tenMonAn"] ?? "Món ăn lộ trình";
    final imgUrl = itemData["image"] ?? itemData["img"] ?? itemData["hinhAnh"] ?? "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500";
    final foodDesc = itemData["description"] ?? itemData["moTa"] ?? "Món ăn được chế biến tươi nóng từ nguồn nguyên liệu sạch chuẩn vệ sinh an toàn thực phẩm. Đặt trước để ghé lấy nóng hổi không chờ đợi.";
    final badges = _getCategoryBadges(foodName);

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
                                  Text("⚠️ ", style: TextStyle(fontSize: 12)),
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
                                  Text("🔥 ", style: TextStyle(fontSize: 12)),
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

                        // Section 1: Lựa chọn khẩu phần (Rendered conditionally if sizeOptions is not empty)
                        if (sizeOptions.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                "Lựa chọn khẩu phần",
                                style: TextStyle(
                                  color: TColor.primaryTextOf(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF2EC),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Bắt buộc",
                                  style: TextStyle(
                                    color: Color(0xFFFF4D00),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Chọn 1",
                                style: TextStyle(
                                  color: TColor.secondaryTextOf(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: List.generate(sizeOptions.length, (index) {
                              final opt = sizeOptions[index];
                              final isSelected = selectedOptionIndex == index;
                              return GestureDetector(
                                onTap: isSoldOut
                                    ? null
                                    : () {
                                        setState(() => selectedOptionIndex = index);
                                      },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: TColor.cardOf(context),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected && !isSoldOut ? const Color(0xFFFF4D00) : TColor.borderOf(context),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                            color: isSelected && !isSoldOut
                                                ? const Color(0xFFFF4D00)
                                                : TColor.secondaryTextOf(context),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            opt["name"],
                                            style: TextStyle(
                                              color: TColor.primaryTextOf(context),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        opt["extra"] == 0 ? "Miễn phí" : "+${_formatCurrency(opt['extra'])}",
                                        style: TextStyle(
                                          color: isSelected && !isSoldOut
                                              ? const Color(0xFFFF4D00)
                                              : TColor.secondaryTextOf(context),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Section 2: Topping thêm (Rendered conditionally if toppingOptions is not empty)
                        if (toppingOptions.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                "Topping thêm",
                                style: TextStyle(
                                  color: TColor.primaryTextOf(context),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF2A2E3B) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Tùy chọn",
                                  style: TextStyle(
                                    color: TColor.secondaryTextOf(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Chọn nhiều",
                                style: TextStyle(
                                  color: TColor.secondaryTextOf(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            children: List.generate(toppingOptions.length, (index) {
                              final top = toppingOptions[index];
                              final isSelected = top["selected"] == true;
                              return GestureDetector(
                                onTap: isSoldOut
                                    ? null
                                    : () {
                                        setState(() {
                                          top["selected"] = !isSelected;
                                        });
                                      },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: TColor.cardOf(context),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected && !isSoldOut ? const Color(0xFFFF4D00) : TColor.borderOf(context),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                            color: isSelected && !isSoldOut
                                                ? const Color(0xFFFF4D00)
                                                : TColor.secondaryTextOf(context),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            top["name"],
                                            style: TextStyle(
                                              color: TColor.primaryTextOf(context),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "+${_formatCurrency(top['extra'])}",
                                        style: TextStyle(
                                          color: isSelected && !isSoldOut
                                              ? const Color(0xFFFF4D00)
                                              : TColor.secondaryTextOf(context),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Section 3: Ghi chú cho quán
                        Text(
                          "Ghi chú cho quán",
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: noteController,
                          enabled: !isSoldOut,
                          style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: "Ghi chú cho quán (vd: ít mỡ hành, nước mắm ngọt, để riêng ớt...)",
                            hintStyle: TextStyle(
                              color: TColor.secondaryTextOf(context).withOpacity(0.6),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: TColor.cardOf(context),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: TColor.borderOf(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: TColor.borderOf(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFFF4D00)),
                            ),
                          ),
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
                                  final foodId = itemData["id"] ?? itemData["maMonAn"] ?? 1;
                                  final resId = itemData["maQuan"] ?? itemData["restaurantId"] ?? 1;

                                  context.read<CartProvider>().addToCart(
                                        CartItemModel(
                                          foodId: foodId,
                                          foodName: foodName,
                                          price: calculatedUnitPrice,
                                          quantity: qty,
                                          image: imgUrl,
                                          restaurantId: resId,
                                        ),
                                      );

                                  CustomToast.showSuccess(context, "Đã thêm $foodName (x$qty) vào giỏ hàng!");
                                  Navigator.pop(context);
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
