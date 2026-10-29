import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../providers/cart_provider.dart';
import '../services/order_service.dart';
import '../common_widget/smart_network_image.dart';
import '../view/menu/restaurant_detail_view.dart';
import '../view/menu/item_details_view.dart';
import '../view/more/checkout_view.dart';
import 'custom_toast.dart';

class FoodStopoverSheet extends StatefulWidget {
  final Map<String, dynamic> restaurant;
  final Map<String, dynamic>? selectedFood;

  const FoodStopoverSheet({
    super.key,
    required this.restaurant,
    this.selectedFood,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> restaurant,
    Map<String, dynamic>? selectedFood,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => FoodStopoverSheet(
        restaurant: restaurant,
        selectedFood: selectedFood,
      ),
    );
  }

  @override
  State<FoodStopoverSheet> createState() => _FoodStopoverSheetState();
}

class _FoodStopoverSheetState extends State<FoodStopoverSheet> {
  late List<Map<String, dynamic>> _foodsList;
  final Set<int> _selectedFoodIds = {};
  final Map<int, int> _quantities = {};

  @override
  void initState() {
    super.initState();
    final matched = (widget.restaurant['matchedFoods'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    if (matched.isNotEmpty) {
      _foodsList = matched;
    } else if (widget.selectedFood != null) {
      _foodsList = [Map<String, dynamic>.from(widget.selectedFood!)];
    } else if (widget.restaurant['primaryFood'] != null) {
      _foodsList = [
        Map<String, dynamic>.from(widget.restaurant['primaryFood'] as Map)
      ];
    } else {
      _foodsList = [];
    }

    // Mặc định tích chọn món đầu tiên còn hàng để người dùng có thể đặt ngay với 1 chạm
    for (final f in _foodsList) {
      final fId = (f['id'] as num? ?? f['maMonAn'] as num? ?? 0).toInt();
      final qty = int.tryParse((f['quantity'] ?? f['soLuongMon'] ?? 0).toString()) ?? 0;
      final status = (f['trangThaiMon'] ?? 'DANG_BAN').toString().toUpperCase();
      final bool isAvailable = qty > 0 && status != 'HET_HANG' && status != 'TAM_NGUNG';

      _quantities[fId] = 1;
      if (isAvailable && _selectedFoodIds.isEmpty) {
        _selectedFoodIds.add(fId);
      }
    }
  }

  void _openItemDetail(Map<String, dynamic> food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailsView(itemObj: food),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();
    final storeName = (widget.restaurant['tenQuan'] ?? widget.restaurant['name'] ?? 'Quán tiện đường').toString();
    final address = (widget.restaurant['diaChi'] ?? widget.restaurant['address'] ?? 'Địa chỉ trên lộ trình').toString();
    final int dist = (widget.restaurant['distanceFromRouteMeters'] as num?)?.toInt() ?? 0;
    final int prepTime = (widget.restaurant['thoiGianChuanBi'] as num?)?.toInt() ?? 20;

    // Tính tổng tiền các món được tích chọn
    double totalPrice = 0.0;
    int totalCount = 0;
    for (final f in _foodsList) {
      final fId = (f['id'] as num? ?? f['maMonAn'] as num? ?? 0).toInt();
      if (_selectedFoodIds.contains(fId)) {
        final price = (f['price'] as num?)?.toDouble() ?? (f['giaMonAn'] as num?)?.toDouble() ?? 0.0;
        final q = _quantities[fId] ?? 1;
        totalPrice += price * q;
        totalCount += q;
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── THÔNG TIN QUÁN ĂN ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6011).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFFFC6011), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dist > 0 ? 'Lệch tuyến ${dist}m' : 'Ngay trên tuyến',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Chuẩn bị ~$prepTime phút',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFCBD5E1),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── TIÊU ĐỀ DANH SÁCH MÓN ĂN & HƯỚNG DẪN ──
            Row(
              children: [
                Text(
                  'Món ăn tiện đường (${_foodsList.length})',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tích chọn món • Nhấn để xem chi tiết',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── DANH SÁCH MÓN ĂN VỚI DẤU TÍCH VÀ XEM CHI TIẾT ──
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _foodsList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final food = _foodsList[idx];
                  final fId = (food['id'] as num? ?? food['maMonAn'] as num? ?? idx).toInt();
                  final fName = (food['name'] ?? food['tenMonAn'] ?? 'Món ngon').toString();
                  final fPrice = (food['price'] as num?)?.toDouble() ?? (food['giaMonAn'] as num?)?.toDouble() ?? 0.0;
                  final fImg = (food['image'] ?? food['img'] ?? '').toString();
                  final stock = int.tryParse((food['quantity'] ?? food['soLuongMon'] ?? 0).toString()) ?? 0;
                  final status = (food['trangThaiMon'] ?? 'DANG_BAN').toString().toUpperCase();
                  final isSoldOut = stock <= 0 || status == 'HET_HANG' || status == 'TAM_NGUNG';

                  final isChecked = _selectedFoodIds.contains(fId);
                  final quantity = _quantities[fId] ?? 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? const Color(0xFFFC6011).withValues(alpha: 0.12)
                          : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isChecked ? const Color(0xFFFC6011) : Colors.white12,
                        width: isChecked ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // 1. Dấu tích chọn món (Checkbox)
                        GestureDetector(
                          onTap: isSoldOut
                              ? null
                              : () {
                                  setState(() {
                                    if (isChecked) {
                                      _selectedFoodIds.remove(fId);
                                    } else {
                                      _selectedFoodIds.add(fId);
                                      if (!_quantities.containsKey(fId)) {
                                        _quantities[fId] = 1;
                                      }
                                    }
                                  });
                                },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isChecked ? const Color(0xFFFC6011) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isChecked
                                    ? const Color(0xFFFC6011)
                                    : (isSoldOut ? Colors.white24 : Colors.white60),
                                width: 1.8,
                              ),
                            ),
                            child: isChecked
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 2. Hình ảnh món (Click để xem chi tiết)
                        GestureDetector(
                          onTap: () => _openItemDetail(food),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SmartNetworkImage(
                                  imageUrl: fImg,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  placeholderIcon: Icons.fastfood_rounded,
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 3. Tên & Giá món (Click để xem chi tiết)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openItemDetail(food),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        fName,
                                        style: GoogleFonts.outfit(
                                          color: isSoldOut ? const Color(0xFF94A3B8) : Colors.white,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          decoration: isSoldOut ? TextDecoration.lineThrough : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      "${fPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFFFC6011),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isSoldOut ? 'Hết hàng' : 'Còn $stock',
                                      style: GoogleFonts.outfit(
                                        color: isSoldOut ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 4. Bộ tăng giảm số lượng (nếu đã tích chọn)
                        if (isChecked && !isSoldOut) ...[
                          const SizedBox(width: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (quantity > 1) {
                                        _quantities[fId] = quantity - 1;
                                      } else {
                                        _selectedFoodIds.remove(fId);
                                      }
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Icon(Icons.remove_rounded, color: Colors.white, size: 14),
                                  ),
                                ),
                                Text(
                                  '$quantity',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    if (quantity < stock) {
                                      setState(() {
                                        _quantities[fId] = quantity + 1;
                                      });
                                    } else {
                                      CustomToast.showError(context, 'Đã đạt giới hạn số lượng còn lại');
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    child: Icon(Icons.add_rounded, color: Colors.white, size: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── TỔNG TIỀN VÀ 2 NÚT HÀNH ĐỘNG ──
            if (totalCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã chọn $totalCount món:',
                      style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "${totalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                      style: GoogleFonts.outfit(color: const Color(0xFFFC6011), fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailView(restaurantObj: widget.restaurant),
                        ),
                      );
                    },
                    child: Text(
                      'Xem Menu Quán',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6011),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: () {
                      if (_selectedFoodIds.isEmpty) {
                        CustomToast.showError(context, 'Vui lòng tích chọn ít nhất 1 món để đặt ghé lấy');
                        return;
                      }

                      final resId = (widget.restaurant['maQuan'] as num? ?? 1).toInt();
                      final cart = context.read<CartProvider>();

                      // Cập nhật quán cho giỏ hàng
                      cart.setRestaurant(
                        id: resId,
                        name: storeName,
                        address: address,
                      );

                      // Thêm tất cả món đã tích chọn vào giỏ hàng
                      Map<String, dynamic>? firstFood;
                      for (final f in _foodsList) {
                        final fId = (f['id'] as num? ?? f['maMonAn'] as num? ?? 0).toInt();
                        if (_selectedFoodIds.contains(fId)) {
                          firstFood ??= f;
                          final fName = (f['name'] ?? f['tenMonAn'] ?? 'Món ngon').toString();
                          final fPrice = (f['price'] as num?)?.toDouble() ?? (f['giaMonAn'] as num?)?.toDouble() ?? 0.0;
                          final fImg = (f['image'] ?? f['img'] ?? '').toString();
                          final q = _quantities[fId] ?? 1;

                          cart.addToCart(CartItemModel(
                            foodId: fId,
                            foodName: fName,
                            price: fPrice,
                            quantity: q,
                            image: fImg,
                            restaurantId: resId,
                          ));
                        }
                      }

                      // Lưu quán ghé lấy vào MapProvider
                      provider.selectStopoverRestaurant(widget.restaurant, firstFood);

                      // Đóng sheet và chuyển thẳng sang màn hình Thanh Toán & Hẹn Giờ Lấy
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckoutView(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Đặt Món Ghé Lấy',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
