import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_service.dart';
import '../../services/order_service.dart';
import '../../services/voucher_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/skeleton/food_item_skeleton.dart';
import '../more/my_order_view.dart';
import '../../common_widget/smart_network_image.dart';
import '../../common/locator.dart';
import '../../services/socket_service.dart';
import 'item_details_view.dart';

class RestaurantDetailView extends StatefulWidget {
  final Map restaurantObj;
  const RestaurantDetailView({super.key, required this.restaurantObj});

  @override
  State<RestaurantDetailView> createState() => _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends State<RestaurantDetailView> {
  bool isLoading = true;
  List<dynamic> categoriesWithItems = [];
  int selectedCategoryIndex = 0;
  bool isFav = false;

  List<VoucherModel> storeVouchers = [];
  bool isLoadingVouchers = true;
  Set<int> collectedVoucherIds = {};

  @override
  void initState() {
    super.initState();
    _loadMenuData();
    locator<SocketService>().listenToVoucherUpdates((_) {
      if (mounted) {
        final resIdRaw = widget.restaurantObj['maQuan'] ?? widget.restaurantObj['id'] ?? 1;
        final int resId = resIdRaw is int ? resIdRaw : (int.tryParse(resIdRaw.toString()) ?? 1);
        VoucherService.fetchVouchers(maQuan: resId).then((vouchers) {
          if (mounted) setState(() => storeVouchers = vouchers);
        });
      }
    });
  }

  @override
  void dispose() {
    locator<SocketService>().offVoucherUpdates();
    super.dispose();
  }

  String _formatVND(dynamic amount) {
    final val = double.tryParse((amount ?? 0).toString()) ?? 0.0;
    return "${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫";
  }

  bool _isSoldOutItem(dynamic item) {
    if (item is! Map) return false;
    final int qty = int.tryParse((item['soLuongMon'] ?? item['quantity'] ?? item['soLuong'] ?? 0).toString()) ?? 0;
    final String status = (item['trangThaiMon'] ?? item['status'] ?? '').toString().toUpperCase();
    return qty <= 0 || status == 'HET_HANG' || status == 'HET_MON' || status == 'TAM_NGUNG';
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

  Future<void> _loadMenuData() async {
    setState(() {
      isLoading = true;
      isLoadingVouchers = true;
    });
    final resIdRaw = widget.restaurantObj['maQuan'] ?? widget.restaurantObj['id'] ?? 1;
    final int resId = resIdRaw is int ? resIdRaw : (int.tryParse(resIdRaw.toString()) ?? 1);
    final resName = widget.restaurantObj['tenQuan'] ?? widget.restaurantObj['name'] ?? 'Phở Bò Gia Truyền Hà Nội - Nguyễn Trãi';
    final resAddress = widget.restaurantObj['diaChi'] ?? widget.restaurantObj['address'] ?? '235 Nguyễn Trãi, Quận 1, TP.HCM';

    // Set active restaurant in CartProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().setRestaurant(id: resId, name: resName, address: resAddress);
    });

    // Fetch actual vouchers for this store from DB
    VoucherService.fetchVouchers(maQuan: resId).then((vouchers) {
      if (mounted) {
        setState(() {
          storeVouchers = vouchers;
          isLoadingVouchers = false;
        });
      }
    });

    final data = await CategoryService.fetchRestaurantMenuFromDB(resId);

    // Sort items in each category
    for (var cat in data) {
      final items = cat['items'] ?? [];
      if (items is List) {
        _sortMenuItems(items);
      }
    }

    // Combine all food items into a "Tất cả" category tab
    List<dynamic> allItems = [];
    for (var cat in data) {
      final items = cat['items'] ?? [];
      for (var item in items) {
        if (!allItems.any((e) => (e['id'] ?? e['maMonAn']) == (item['id'] ?? item['maMonAn']))) {
          allItems.add(item);
        }
      }
    }
    _sortMenuItems(allItems);

    List<dynamic> fullCategories = [];
    if (allItems.isNotEmpty || data.isNotEmpty) {
      fullCategories.add({
        'id': 0,
        'name': 'Tất cả',
        'itemsCount': allItems.length,
        'items': allItems,
      });
      fullCategories.addAll(data);
    }

    if (mounted) {
      setState(() {
        categoriesWithItems = fullCategories;
        selectedCategoryIndex = 0;
        isLoading = false;
      });
    }
  }

  void _showCollectVoucherModal(VoucherModel v) {
    final discountText = v.discountType == 'PERCENT'
        ? 'Giảm ${v.discount.toInt()}%${v.maxDiscount > 0 ? ' (Tối đa ${_formatVND(v.maxDiscount)})' : ''}'
        : 'Giảm ${_formatVND(v.discount)}';
    final minOrderText = v.minOrder > 0 ? ' • Đơn từ ${_formatVND(v.minOrder)}' : ' • Không giới hạn đơn';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Text("🎁", style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Thu thập Voucher",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TColor.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TColor.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: TColor.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            v.code,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            v.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "$discountText$minOrderText",
                      style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Mã ưu đãi này sẽ được lưu trực tiếp vào Ví Voucher của bạn và áp dụng khi thanh toán tại quán.",
                style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final res = await VoucherService.collectVoucher(v.id);
                if (mounted) {
                  if (res['success'] == true) {
                    setState(() {
                      collectedVoucherIds.add(v.id);
                    });
                    _showResultModal(
                      isSuccess: true,
                      title: "Lưu Voucher Thành Công! 🎉",
                      message: res['message'] ?? "Đã thêm mã ${v.code} vào ví voucher của bạn.",
                    );
                  } else {
                    _showResultModal(
                      isSuccess: false,
                      title: "Thông Báo",
                      message: res['message'] ?? "Không thể lưu voucher",
                    );
                  }
                }
              },
              child: const Text("Lấy mã ngay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showResultModal({required bool isSuccess, required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: TColor.secondaryTextOf(context)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? TColor.primary : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Đóng", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();

    final resName = widget.restaurantObj['tenQuan'] ?? widget.restaurantObj['name'] ?? 'Phở Bò Gia Truyền Hà Nội - Nguyễn Trãi';
    final resImg = widget.restaurantObj['img'] ?? widget.restaurantObj['image'] ?? 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500';
    final resAddress = widget.restaurantObj['diaChi'] ?? widget.restaurantObj['address'] ?? '235 Nguyễn Trãi, Quận 1, TP.HCM';

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: RefreshIndicator(
        onRefresh: _loadMenuData,
        color: TColor.primary,
        child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header Image & Action Bar
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: TColor.bgOf(context),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? Colors.red : Colors.white, size: 20),
                      onPressed: () {
                        setState(() => isFav = !isFav);
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      SmartNetworkImage(
                        imageUrl: resImg,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: TColor.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "⏱️ 15-20 phút • 1.2 km",
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Restaurant Info & Offer Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              resName,
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "• Đang mở",
                              style: TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "4.9 (124+)",
                            style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          Expanded(
                            child: Text(
                              " • $resAddress",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Dynamic Horizontal Store Promo Voucher Box
                      if (isLoadingVouchers)
                        const SizedBox.shrink()
                      else if (storeVouchers.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Khuyến mãi từ quán",
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 72,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: storeVouchers.length,
                                itemBuilder: (context, index) {
                                  final v = storeVouchers[index];
                                  final isCollected = collectedVoucherIds.contains(v.id);
                                  final discountText = v.discountType == 'PERCENT'
                                      ? 'Giảm ${v.discount.toInt()}%${v.maxDiscount > 0 ? ' (Tối đa ${_formatVND(v.maxDiscount)})' : ''}'
                                      : 'Giảm ${_formatVND(v.discount)}';
                                  final minOrderText = v.minOrder > 0 ? ' • Đơn từ ${_formatVND(v.minOrder)}' : '';

                                  return Container(
                                    width: 270,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: TColor.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: TColor.primary.withOpacity(0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text("🎁", style: TextStyle(fontSize: 18)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: TColor.primary,
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      v.code,
                                                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      v.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 12, fontWeight: FontWeight.w700),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "$discountText$minOrderText",
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 10.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        ElevatedButton(
                                          onPressed: isCollected
                                              ? null
                                              : () => _showCollectVoucherModal(v),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isCollected ? Colors.grey : TColor.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          child: Text(
                                            isCollected ? "Đã lấy" : "Lấy mã",
                                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Category Tabs Scrollable Horizontal Bar
                      if (categoriesWithItems.isNotEmpty)
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: categoriesWithItems.length,
                            itemBuilder: (context, index) {
                              final cat = categoriesWithItems[index];
                              final isSelected = selectedCategoryIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() => selectedCategoryIndex = index);
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? TColor.primary : TColor.cardOf(context),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: isSelected ? TColor.primary : TColor.borderOf(context)),
                                  ),
                                  child: Text(
                                    cat['name'] ?? 'Danh mục',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : TColor.primaryTextOf(context),
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Items Section List
              isLoading
                  ? const SliverToBoxAdapter(
                      child: FoodItemSkeletonList(itemCount: 5),
                    )
                  : categoriesWithItems.isEmpty
                      ? SliverFillRemaining(
                          child: Center(
                            child: Text(
                              "Chưa có món ăn nào trong nhà hàng này",
                              style: TextStyle(color: TColor.secondaryTextOf(context)),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, catIdx) {
                              if (selectedCategoryIndex != catIdx && selectedCategoryIndex < categoriesWithItems.length) {
                                // Filter to active selected category
                                return const SizedBox.shrink();
                              }

                              final cat = categoriesWithItems[catIdx];
                              final List items = cat['items'] ?? [];

                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${cat['name']} 🔥",
                                      style: TextStyle(
                                        color: TColor.primaryTextOf(context),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ListView.builder(
                                      physics: const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      itemCount: items.length,
                                      itemBuilder: (context, itemIdx) {
                                        final item = items[itemIdx];
                                        final price = double.tryParse((item['price'] ?? item['giaMonAn'] ?? 0).toString()) ?? 0.0;
                                        final img = item['image'] ?? item['img'] ?? '';
                                        final int stockQty = int.tryParse((item['soLuongMon'] ?? item['quantity'] ?? item['soLuong'] ?? 0).toString()) ?? 0;
                                        final String status = (item['trangThaiMon'] ?? item['status'] ?? '').toString().toUpperCase();
                                        final bool isSoldOut = stockQty <= 0 || status == 'HET_HANG' || status == 'HET_MON' || status == 'TAM_NGUNG';

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
                                            margin: const EdgeInsets.only(bottom: 14),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: TColor.cardOf(context),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(color: TColor.borderOf(context), width: 1),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                // Food Image Thumbnail with Sold Out Overlay
                                                Stack(
                                                  children: [
                                                    Opacity(
                                                      opacity: isSoldOut ? 0.45 : 1.0,
                                                      child: SmartNetworkImage(
                                                        imageUrl: img,
                                                        width: 85,
                                                        height: 85,
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                    if (isSoldOut)
                                                      Positioned.fill(
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: Colors.black.withOpacity(0.4),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          alignment: Alignment.center,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFFEF4444),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: const Text(
                                                              "HẾT MÓN",
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w800,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(width: 12),

                                                // Info Column
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item['name'] ?? item['tenMonAn'] ?? '',
                                                        style: TextStyle(
                                                          color: isSoldOut
                                                              ? TColor.secondaryTextOf(context)
                                                              : TColor.primaryTextOf(context),
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            isSoldOut ? "Tạm ngưng phục vụ" : "Chế biến tươi nóng",
                                                            style: TextStyle(
                                                              color: TColor.secondaryTextOf(context),
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: isSoldOut
                                                                  ? const Color(0xFFFEE2E2)
                                                                  : const Color(0xFFECFDF5),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              isSoldOut ? "Hết món" : "Còn $stockQty phần",
                                                              style: TextStyle(
                                                                color: isSoldOut
                                                                    ? const Color(0xFFDC2626)
                                                                    : const Color(0xFF059669),
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w700,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            "${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                                            style: TextStyle(
                                                              color: isSoldOut
                                                                  ? TColor.secondaryTextOf(context)
                                                                  : TColor.primaryTextOf(context),
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w800,
                                                            ),
                                                          ),
                                                          // Add Button (+) or Sold Out tag
                                                          if (isSoldOut)
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                              decoration: BoxDecoration(
                                                                color: isDark
                                                                    ? const Color(0xFF2A2E3B)
                                                                    : const Color(0xFFE5E7EB),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: Text(
                                                                "Hết món",
                                                                style: TextStyle(
                                                                  color: TColor.secondaryTextOf(context),
                                                                  fontSize: 11,
                                                                  fontWeight: FontWeight.w700,
                                                                ),
                                                              ),
                                                            )
                                                          else
                                                            InkWell(
                                                              onTap: () {
                                                                final foodId = item['id'] ?? item['maMonAn'] ?? 1;
                                                                final foodName = item['name'] ?? item['tenMonAn'] ?? 'Món';
                                                                final resId = widget.restaurantObj['maQuan'] ?? 1;

                                                                cart.addToCart(
                                                                  CartItemModel(
                                                                    foodId: foodId,
                                                                    foodName: foodName,
                                                                    price: price,
                                                                    quantity: 1,
                                                                    image: img,
                                                                    restaurantId: resId,
                                                                  ),
                                                                );

                                                                CustomToast.showSuccess(context, "Đã thêm $foodName vào giỏ hàng!");
                                                              },
                                                              child: Container(
                                                                width: 32,
                                                                height: 32,
                                                                decoration: BoxDecoration(
                                                                  color: TColor.primary,
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                                              ),
                                                            ),
                                                        ],
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
                              );
                            },
                            childCount: categoriesWithItems.length,
                          ),
                        ),

              // Bottom Spacing for floating cart bar
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ),

          // Sticky Bottom Floating Bar (Image 2 Bottom Bar)
          if (cart.items.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E232E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Tổng thanh toán (${cart.items.length} món)",
                          style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 11),
                        ),
                        Text(
                          "${cart.total.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MyOrderView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 18),
                      label: const Text(
                        "Đặt hàng ngay",
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}
