import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/voucher_service.dart';
import 'my_order_view.dart';

class InboxView extends StatefulWidget {
  const InboxView({super.key});

  @override
  State<InboxView> createState() => _InboxViewState();
}

class _InboxViewState extends State<InboxView> {
  int selectTab = 0;
  bool isLoading = true;
  List<VoucherModel> voucherList = [];
  List<VoucherModel> savedVoucherList = [];

  @override
  void initState() {
    super.initState();
    _loadVouchersFromDatabase();
  }

  Future<void> _loadVouchersFromDatabase() async {
    setState(() => isLoading = true);
    final results = await Future.wait([
      VoucherService.fetchVouchers(),
      VoucherService.fetchMyCollectedVouchers(),
    ]);
    if (mounted) {
      setState(() {
        voucherList = results[0];
        savedVoucherList = results[1];
        isLoading = false;
      });
    }
  }

  List<VoucherModel> get _availableVouchers {
    return voucherList.where((v) {
      // Ẩn voucher đã hết hạn
      if (v.isExpired) return false;
      // Ẩn voucher đã thu thập hết hoặc khách hàng đã thu thập
      if (v.isExhausted || v.isCollected) return false;
      if (savedVoucherList.any((saved) => saved.id == v.id)) return false;
      return true;
    }).toList();
  }

  List<VoucherModel> get _filteredVouchers {
    if (selectTab == 2) {
      return savedVoucherList;
    }
    final validList = _availableVouchers;
    if (selectTab == 1) {
      return validList.where((v) => v.discountType == 'PERCENT' || v.tag == 'MEALMONKEY VIP' || v.tag.contains('GIẢM')).toList();
    }
    return validList;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();
    final availableCount = _availableVouchers.length;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildHeader(context, lang, isDark, availableCount),
            ),

            // Horizontal Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFilterChip("Tất cả", count: availableCount, idx: 0, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip("Mã giảm giá", idx: 1, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip("Voucher đã lưu", count: savedVoucherList.length, idx: 2, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable List of Vouchers
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: TColor.primary),
                    )
                  : _filteredVouchers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.confirmation_number_outlined, size: 54, color: TColor.secondaryTextOf(context).withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text(
                                selectTab == 2
                                    ? "Chưa có voucher nào trong ví"
                                    : "Chưa có voucher khả dụng nào",
                                style: TextStyle(
                                  color: TColor.primaryTextOf(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                selectTab == 2
                                    ? "Hãy bấm 'Thu thập' để lưu mã giảm giá vào ví"
                                    : "Tất cả voucher có thể đã được thu thập hoặc hết hạn",
                                style: TextStyle(
                                  color: TColor.secondaryTextOf(context),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadVouchersFromDatabase,
                          color: TColor.primary,
                          child: ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredVouchers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = _filteredVouchers[index];
                              return _buildOfferCard(item, isDark, isSavedTab: selectTab == 2);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LanguageProvider lang, bool isDark, int availableCount) {
    final cartCount = context.watch<CartProvider>().totalItemCount;

    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF2F3F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: TColor.primaryTextOf(context),
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Kho Voucher",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
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
              const SizedBox(height: 2),
              Text(
                "MealMonkey Rewards & Deals ($availableCount khả dụng)",
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyOrderView()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF2F3F5),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 20,
                  color: TColor.primaryTextOf(context),
                ),
                if (cartCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: TColor.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Center(
                        child: Text(
                          "$cartCount",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {int? count, required int idx, required bool isDark}) {
    final isSelected = selectTab == idx;
    return InkWell(
      onTap: () => setState(() => selectTab = idx),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? TColor.primary
              : (isDark ? const Color(0xFF171B26) : const Color(0xFFEFEFEF)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? TColor.primary
                : (isDark ? const Color(0xFF232836) : Colors.transparent),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : TColor.primaryText),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.3) : TColor.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$count",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(VoucherModel item, bool isDark, {bool isSavedTab = false}) {
    final remainingQty = item.soLuongToiDa > 0 ? (item.soLuongToiDa - item.soLuongDaLuu) : null;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Icon / Badge Box
                if (item.discountType == 'PERCENT' || item.isVip)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: TColor.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        item.discountType == 'PERCENT'
                            ? "${item.discount.toInt()}%\nOFF"
                            : "${(item.discount / 1000).toInt()}K\nOFF",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B4D3E),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF00E676),
                      size: 24,
                    ),
                  ),
                const SizedBox(width: 14),

                // Center Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Tag & Large Quantity Badge at Top Right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: TColor.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.tag,
                              style: TextStyle(
                                color: TColor.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          // Large prominent Quantity Badge on Top Right
                          if (remainingQty != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1B3E32) : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2E7D32) : const Color(0xFFA5D6A7),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 13,
                                    color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Còn lại: $remainingQty/${item.soLuongToiDa}",
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title & Description
                      Text(
                        item.name,
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: TColor.secondaryTextOf(context),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      if (item.expiryDate != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Hạn dùng: ${item.expiryDate}",
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Code Box & Action Button Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF11141D) : const Color(0xFFF2F3F5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE0E0E0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  "Mã : ",
                                  style: TextStyle(
                                    color: TColor.secondaryTextOf(context),
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  item.code,
                                  style: TextStyle(
                                    color: TColor.primaryTextOf(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Button: "Thu thập" or "Đã lưu ✓"
                          if (isSavedTab)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                                  SizedBox(width: 4),
                                  Text(
                                    "Đã lưu",
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () async {
                                final res = await VoucherService.collectVoucher(item.id);
                                if (context.mounted) {
                                  if (res['success'] == true) {
                                    // Tự động chuyển voucher sang danh sách Đã Lưu
                                    setState(() {
                                      voucherList.removeWhere((v) => v.id == item.id);
                                      savedVoucherList.add(item);
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ?? "Đã lưu mã ${item.code} vào ví của bạn!"),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: const Color(0xFF10B981),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(res['message'] ?? "Không thể lưu voucher"),
                                        duration: const Duration(seconds: 2),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: TColor.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Thu thập",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.bookmark_add_rounded, size: 16),
                                ],
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

          // Ribbon Banner on Top Right corner if item.isVip == true
          if (item.isVip)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5722),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                  ),
                ),
                child: const Text(
                  "HOT",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
