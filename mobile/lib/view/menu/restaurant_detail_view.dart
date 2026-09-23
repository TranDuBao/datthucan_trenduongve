import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../providers/cart_provider.dart';
import '../../services/category_service.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_toast.dart';
import '../more/my_order_view.dart';
import '../../common_widget/smart_network_image.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMenuData();
  }

  Future<void> _loadMenuData() async {
    setState(() => isLoading = true);
    final resId = widget.restaurantObj['maQuan'] ?? widget.restaurantObj['id'] ?? 1;
    final resName = widget.restaurantObj['tenQuan'] ?? widget.restaurantObj['name'] ?? 'Phở Bò Gia Truyền Hà Nội - Nguyễn Trãi';
    final resAddress = widget.restaurantObj['diaChi'] ?? widget.restaurantObj['address'] ?? '235 Nguyễn Trãi, Quận 1, TP.HCM';

    // Set active restaurant in CartProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().setRestaurant(id: resId, name: resName, address: resAddress);
    });

    final data = await CategoryService.fetchRestaurantMenuFromDB(resId);

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
                          Text(
                            " • $resAddress",
                            style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Promo Voucher Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColor.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TColor.primary.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Text("🎁", style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Ưu đãi đặc biệt cho khách Pre-Order",
                                    style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    "Giảm 10K cho đơn lộ trình từ 50K khi đặt trước",
                                    style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("Lấy mã", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
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
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
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
                                        final price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
                                        final img = item['image'] ?? '';

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
                                                // Food Image Thumbnail
                                                SmartNetworkImage(
                                                  imageUrl: img,
                                                  width: 85,
                                                  height: 85,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                const SizedBox(width: 12),
                                                // Info Column
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item['name'] ?? '',
                                                        style: TextStyle(
                                                          color: TColor.primaryTextOf(context),
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "Chế biến tươi nóng, thơm ngon chuẩn vị",
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: TColor.secondaryTextOf(context),
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            "${price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                                            style: TextStyle(
                                                              color: TColor.primaryTextOf(context),
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w800,
                                                            ),
                                                          ),
                                                          // Add Button (+)
                                                          InkWell(
                                                            onTap: () {
                                                              final foodId = item['id'] ?? 1;
                                                              final foodName = item['name'] ?? 'Món';
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
                      icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
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
