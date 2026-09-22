import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/view/more/add_card_view.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import '../../services/payment_service.dart';
import 'my_order_view.dart';

class PaymentDetailsView extends StatefulWidget {
  const PaymentDetailsView({super.key});

  @override
  State<PaymentDetailsView> createState() => _PaymentDetailsViewState();
}

class _PaymentDetailsViewState extends State<PaymentDetailsView> {
  int selectMethod = 0; // 0: COD, 1+: Card/Wallet
  bool isLoading = true;
  List<PaymentMethodModel> savedCards = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => isLoading = true);
    final cards = await PaymentService.getSavedPaymentMethods();
    if (mounted) {
      setState(() {
        savedCards = cards;
        isLoading = false;
      });
    }
  }

  Future<void> _deleteCard(String id) async {
    await PaymentService.deleteCard(id);
    await _loadPaymentMethods();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, lang, isDark),
              const SizedBox(height: 18),

              // Title Section
              Text(
                "Tùy chọn thanh toán",
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Chọn phương thức bạn muốn sử dụng cho đơn đặt hàng lần này hoặc quản lý các thẻ đã lưu.",
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: COD / Cash on Delivery
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TIỀN MẶT & TRỰC TIẾP",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "PHỔ BIẾN",
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildCodCard(isDark),
              const SizedBox(height: 24),

              // Section 2: Saved Cards from Database
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "THẺ NGÂN HÀNG ĐÃ LIÊN KẾT",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "${savedCards.length} THẺ KHẢ DỤNG",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context).withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isLoading)
                Center(child: CircularProgressIndicator(color: TColor.primary))
              else if (savedCards.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TColor.cardOf(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TColor.borderOf(context)),
                  ),
                  child: Center(
                    child: Text(
                      "Chưa có thẻ ngân hàng nào được liên kết",
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: savedCards.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final card = savedCards[index];
                    return _buildCardItem(card, index + 1, isDark);
                  },
                ),
              const SizedBox(height: 24),

              // Section 3: E-Wallets
              Text(
                "VÍ ĐIỆN TỬ & CỔNG THANH TOÁN",
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildEWalletsRow(isDark),
              const SizedBox(height: 28),

              // Add Card Button
              InkWell(
                onTap: () async {
                  await showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (context) => const AddCardView(),
                  );
                  await _loadPaymentMethods();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: TColor.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: TColor.primary.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 6),
                      Text(
                        "Thêm thẻ tín dụng / ghi nợ mới",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Security Footnote
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF171B26) : const Color(0xFFE8F5E9).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFF232836) : const Color(0xFFC8E6C9),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, color: Color(0xFF2E7D32), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            "Bảo mật PCI-DSS cấp độ 1 & Mã hóa an toàn",
                            style: TextStyle(
                              color: isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF1B5E20),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Thông tin thẻ được mã hoá & không lưu trữ trực tiếp trên thiết bị",
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context).withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LanguageProvider lang, bool isDark) {
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
              Text(
                "Chi tiết thanh toán",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "Bảo mật chuẩn mã hóa SSL 256-bit",
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
                  Icons.shopping_bag_outlined,
                  size: 20,
                  color: TColor.primaryTextOf(context),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: TColor.primary,
                      shape: BoxShape.circle,
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

  Widget _buildCodCard(bool isDark) {
    final isSelected = selectMethod == 0;
    return InkWell(
      onTap: () => setState(() => selectMethod = 0),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TColor.cardOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? TColor.primary : TColor.borderOf(context),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.payments_outlined,
                color: Color(0xFFE65100),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Thanh toán khi nhận hàng",
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: TColor.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "COD",
                          style: TextStyle(
                            color: TColor.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Tiền mặt hoặc quẹt thẻ POS giao tận nơi",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? TColor.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? TColor.primary : TColor.secondaryTextOf(context).withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(PaymentMethodModel card, int idx, bool isDark) {
    final isSelected = selectMethod == idx;
    return InkWell(
      onTap: () => setState(() => selectMethod = idx),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TColor.cardOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? TColor.primary : TColor.borderOf(context),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      card.cardType.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.cardNumber,
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${card.bankName.isNotEmpty ? '${card.bankName} • ' : ''}Hết hạn ${card.expiryDate}",
                        style: TextStyle(
                          color: TColor.secondaryTextOf(context),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _deleteCard(card.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5252),
                    side: const BorderSide(color: Color(0xFFFF5252), width: 1),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Xóa", style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
            if (card.isDefault) ...[
              const SizedBox(height: 12),
              Divider(color: TColor.borderOf(context), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? TColor.primary : TColor.secondaryTextOf(context),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Chọn thẻ này thanh toán",
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 12),
                        SizedBox(width: 4),
                        Text(
                          "Mặc định",
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEWalletsRow(bool isDark) {
    final wallets = [
      {"name": "Ví MoMo", "code": "momo", "icon": "M", "color": const Color(0xFFA50064), "idx": 10},
      {"name": "Apple Pay", "code": "apple", "icon": "", "color": const Color(0xFF000000), "idx": 11},
      {"name": "ZaloPay", "code": "zalo", "icon": "Zalo", "color": const Color(0xFF0068FF), "idx": 12},
    ];

    return Row(
      children: wallets.map((item) {
        final idx = item["idx"] as int;
        final isSelected = selectMethod == idx;
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => selectMethod = idx),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: TColor.cardOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? TColor.primary : TColor.borderOf(context),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item["color"] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        item["icon"] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item["name"] as String,
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
