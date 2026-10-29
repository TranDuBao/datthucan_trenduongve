import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:provider/provider.dart';

import '../../common/globs.dart';
import '../../providers/language_provider.dart';
import '../../widgets/custom_toast.dart';
import 'my_order_view.dart';

class PaymentDetailsView extends StatefulWidget {
  const PaymentDetailsView({super.key});

  @override
  State<PaymentDetailsView> createState() => _PaymentDetailsViewState();
}

class _PaymentDetailsViewState extends State<PaymentDetailsView> {
  static const String _prefKey = "preferred_payment_wallet";
  String selectedWalletCode = "PAYOS";

  final List<Map<String, dynamic>> wallets = [
    {
      "name": "VietQR / PayOS",
      "code": "PAYOS",
      "subtitle": "Quét mã QR tự động qua hơn 40 ứng dụng ngân hàng và ví điện tử, không mất phí.",
      "tag": "KHUYÊN DÙNG",
      "tagColor": const Color(0xFF10B981),
      "badgeBg": const Color(0xFFE8F5E9),
      "iconBg": const Color(0xFFFFECE5),
      "iconColor": const Color(0xFFFC6011),
      "icon": Icons.qr_code_2_rounded,
    },
    {
      "name": "Ví MoMo",
      "code": "MOMO",
      "subtitle": "Thanh toán một chạm qua ví điện tử MoMo hoặc quét mã QR MoMo liên kết.",
      "tag": "PHỔ BIẾN",
      "tagColor": const Color(0xFFA50064),
      "badgeBg": const Color(0xFFFCE4EC),
      "iconBg": const Color(0xFFA50064),
      "iconColor": Colors.white,
      "textIcon": "M",
    },
    {
      "name": "ZaloPay",
      "code": "ZALOPAY",
      "subtitle": "Thanh toán an toàn, tức thì qua ứng dụng ví điện tử ZaloPay & Zalo.",
      "tag": "TIỆN LỢI",
      "tagColor": const Color(0xFF0068FF),
      "badgeBg": const Color(0xFFE3F2FD),
      "iconBg": const Color(0xFF0068FF),
      "iconColor": Colors.white,
      "textIcon": "Zalo",
    },
    {
      "name": "VNPay QR",
      "code": "VNPAY",
      "subtitle": "Cổng thanh toán quốc gia, quét mã thanh toán trực tiếp từ mọi ứng dụng ngân hàng.",
      "tag": "TOÀN QUỐC",
      "tagColor": const Color(0xFF005BAA),
      "badgeBg": const Color(0xFFE1F5FE),
      "iconBg": const Color(0xFF005BAA),
      "iconColor": Colors.white,
      "icon": Icons.account_balance_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    final saved = Globs.udValueString(_prefKey);
    if (saved.isNotEmpty && wallets.any((w) => w["code"] == saved)) {
      selectedWalletCode = saved;
    }
  }

  void _selectWallet(String code, String name) {
    setState(() => selectedWalletCode = code);
    Globs.udStringSet(code, _prefKey);
    CustomToast.showSuccess(context, "Đã chọn $name làm ví thanh toán mặc định");
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
                "Chọn ví điện tử hoặc cổng thanh toán trực tuyến bạn muốn sử dụng làm mặc định khi đặt món.",
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Banner thông báo thanh toán không tiền mặt
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2430) : const Color(0xFFFFF4EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C3240) : const Color(0xFFFFD8C2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TColor.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.flash_on_rounded, color: TColor.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Thanh toán trực tuyến (Cashless)",
                            style: TextStyle(
                              color: TColor.primaryTextOf(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Tất cả đơn hàng Pre-Order được thanh toán và xác nhận tự động qua ví điện tử.",
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
              const SizedBox(height: 22),

              // Section Header: Ví điện tử & Cổng thanh toán
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "VÍ ĐIỆN TỬ & CỔNG THANH TOÁN",
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
                    child: Text(
                      "${wallets.length} CỔNG KHẢ DỤNG",
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Danh sách các Ví điện tử
              ...wallets.map((wallet) {
                final code = wallet["code"] as String;
                final name = wallet["name"] as String;
                final subtitle = wallet["subtitle"] as String;
                final tag = wallet["tag"] as String?;
                final tagColor = wallet["tagColor"] as Color;
                final badgeBg = wallet["badgeBg"] as Color;
                final iconBg = wallet["iconBg"] as Color;
                final iconColor = wallet["iconColor"] as Color;
                final icon = wallet["icon"] as IconData?;
                final textIcon = wallet["textIcon"] as String?;
                final isSelected = selectedWalletCode == code;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => _selectWallet(code, name),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TColor.cardOf(context),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? TColor.primary : TColor.borderOf(context),
                          width: isSelected ? 1.8 : 1,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Logo / Icon ví
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: icon != null
                                  ? Icon(icon, color: iconColor, size: 24)
                                  : Text(
                                      textIcon ?? '',
                                      style: TextStyle(
                                        color: iconColor,
                                        fontSize: textIcon != null && textIcon.length > 2 ? 11 : 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Thông tin ví
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: TColor.primaryTextOf(context),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (tag != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            color: tagColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: TColor.secondaryTextOf(context),
                                    fontSize: 11,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Nút chọn (Radio indicator)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                              color: isSelected ? TColor.primary : TColor.secondaryTextOf(context),
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

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
                            "Bảo mật PCI-DSS cấp độ 1 & Mã hóa SSL 256-bit",
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
                      "Giao dịch được đối soát và xác thực tự động trực tiếp qua cổng thanh toán",
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
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 20,
              color: TColor.primaryTextOf(context),
            ),
          ),
        ),
      ],
    );
  }
}
