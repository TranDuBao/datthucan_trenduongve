import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_toast.dart';
import '../../common_widget/smart_network_image.dart';
import '../more/my_order_view.dart';

class ItemDetailsView extends StatefulWidget {
  final Map itemObj;
  const ItemDetailsView({super.key, required this.itemObj});

  @override
  State<ItemDetailsView> createState() => _ItemDetailsViewState();
}

class _ItemDetailsViewState extends State<ItemDetailsView> {
  late double basePrice;
  int qty = 1;
  bool isFav = false;

  // Customization selection state
  int selectedOptionIndex = 0;
  final List<Map<String, dynamic>> sizeOptions = [
    {"name": "Cỡ vừa (Tiêu chuẩn)", "extra": 0},
    {"name": "Cỡ lớn (Thêm thịt & bánh)", "extra": 15000},
  ];

  final List<Map<String, dynamic>> toppingOptions = [
    {"name": "Thịt tái thêm", "extra": 15000, "selected": false},
    {"name": "Sườn sụn giòn", "extra": 15000, "selected": false},
    {"name": "Trứng chần nước béo", "extra": 8000, "selected": false},
  ];

  final TextEditingController noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    basePrice = double.tryParse((widget.itemObj["price"] ?? widget.itemObj["giaMonAn"] ?? 65000).toString()) ?? 65000.0;
  }

  double get calculatedUnitPrice {
    double price = basePrice + sizeOptions[selectedOptionIndex]["extra"];
    for (var top in toppingOptions) {
      if (top["selected"] == true) {
        price += top["extra"];
      }
    }
    return price;
  }

  double get calculatedTotalPrice => calculatedUnitPrice * qty;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final foodName = widget.itemObj["name"] ?? widget.itemObj["tenMonAn"] ?? "Mon an lo trinh";
    final imgUrl = widget.itemObj["image"] ?? widget.itemObj["img"] ?? "https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500";
    final ratingVal = double.tryParse((widget.itemObj["rating"] ?? 4.9).toString()) ?? 4.9;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Image Banner with Action Icons
                Stack(
                  children: [
                    SmartNetworkImage(
                      imageUrl: imgUrl,
                      width: media.width,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      width: media.width,
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent, Colors.black.withOpacity(0.7)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    // Action Buttons Row
                    Positioned(
                      top: 40,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                                child: IconButton(
                                  icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? Colors.red : Colors.white, size: 20),
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
                    // Badges overlay
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                            child: const Text("🔥 Top 1 Bán Chạy", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text("$ratingVal (128)", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Main Details Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodName,
                        style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "${basePrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                            style: TextStyle(color: TColor.primary, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "${(basePrice * 1.25).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                            style: TextStyle(
                              color: TColor.secondaryTextOf(context),
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Món ăn được chế biến tươi nóng từ nguồn nguyên liệu sạch chuẩn vệ sinh an toàn thực phẩm. Đặt trước để ghé lấy nóng hổi không chờ đợi.",
                        style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 16),

                      // Info badges row (prep time, calories)
                      Row(
                        children: [
                          _infoBadge(context, Icons.access_time_filled_rounded, "~15 phút"),
                          const SizedBox(width: 10),
                          _infoBadge(context, Icons.local_fire_department_rounded, "420 kcal"),
                          const SizedBox(width: 10),
                          _infoBadge(context, Icons.verified_rounded, "Hữu cơ 100%"),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Divider(color: TColor.borderOf(context)),
                      const SizedBox(height: 16),

                      // Single Select Option: Size/Portion
                      Text(
                        "Lựa chọn khẩu phần (Bắt buộc)",
                        style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: List.generate(sizeOptions.length, (index) {
                          final opt = sizeOptions[index];
                          final isSelected = selectedOptionIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() => selectedOptionIndex = index);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: TColor.cardOf(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? TColor.primary : TColor.borderOf(context), width: isSelected ? 1.5 : 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, color: TColor.primary, size: 18),
                                      const SizedBox(width: 10),
                                      Text(opt["name"], style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Text(
                                    opt["extra"] == 0 ? "Miễn phí" : "+${opt['extra']}đ",
                                    style: TextStyle(color: isSelected ? TColor.primary : TColor.secondaryTextOf(context), fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Multi Select Option: Toppings
                      Text(
                        "Topping thêm (Tùy chọn)",
                        style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: List.generate(toppingOptions.length, (index) {
                          final top = toppingOptions[index];
                          final isSelected = top["selected"] == true;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                top["selected"] = !isSelected;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: TColor.cardOf(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? TColor.primary : TColor.borderOf(context), width: isSelected ? 1.5 : 1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: TColor.primary, size: 20),
                                      const SizedBox(width: 10),
                                      Text(top["name"], style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Text("+${top['extra']}đ", style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Note for Chef
                      Text(
                        "Ghi chú cho nhà hàng",
                        style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13),
                        decoration: InputDecoration(
                          hintText: "Ghi chú cho đầu bếp (ví dụ: ít hành, không cay...)",
                          hintStyle: TextStyle(color: TColor.secondaryTextOf(context).withOpacity(0.6), fontSize: 12),
                          filled: true,
                          fillColor: TColor.cardOf(context),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                        ),
                      ),

                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sticky Bottom Action Bar (Image 3 Bottom Bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E232E) : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  // Quantity Counter (- 1 +)
                  Container(
                    decoration: BoxDecoration(
                      color: TColor.bgOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: TColor.borderOf(context)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_rounded, color: TColor.primaryTextOf(context), size: 18),
                          onPressed: () {
                            if (qty > 1) {
                              setState(() => qty--);
                            }
                          },
                        ),
                        Text(
                          "$qty",
                          style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_rounded, color: TColor.primary, size: 18),
                          onPressed: () {
                            setState(() => qty++);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Big Orange Add to Cart Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TColor.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          final foodId = widget.itemObj["id"] ?? widget.itemObj["maMonAn"] ?? 1;
                          final resId = widget.itemObj["maQuan"] ?? 1;

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
                          "Thêm vào giỏ ${calculatedTotalPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ",
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: TColor.primary),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
