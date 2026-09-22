import 'package:flutter/material.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:provider/provider.dart';

import '../../providers/language_provider.dart';
import 'my_order_view.dart';

class AboutUsView extends StatefulWidget {
  const AboutUsView({super.key});

  @override
  State<AboutUsView> createState() => _AboutUsViewState();
}

class _AboutUsViewState extends State<AboutUsView> {
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
              const SizedBox(height: 16),

              // Hero Card (Dark vs Light style from screenshots 1 & 2)
              _buildHeroCard(isDark),
              const SizedBox(height: 16),

              // Stats Row (500K+, 4.9★, 98% / 25phút)
              _buildStatsRow(isDark),
              const SizedBox(height: 20),

              // Mission & Vision Card
              _buildMissionCard(isDark),
              const SizedBox(height: 20),

              // Section: Core Values Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: TColor.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Giá trị cốt lõi",
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    isDark ? "Tiêu chuẩn 5 sao" : "Cam kết của quán",
                    style: TextStyle(
                      color: TColor.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Core Values 2x2 Grid
              _buildCoreValuesGrid(isDark),
              const SizedBox(height: 20),

              // Numbers / Impact Card (Dark Mode specific grid matching screenshot 1)
              if (isDark) ...[
                _buildImpressiveNumbersCard(isDark),
                const SizedBox(height: 20),
              ],

              // Contact & Social Connect Section
              _buildContactFooter(context, isDark),
              const SizedBox(height: 24),

              // Watermark Footer
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: TColor.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDark
                              ? "Phiên bản cao cấp 3.2.0 (Dark Prestige)"
                              : "Phiên bản 2.4.0 • Thiết kế vì sức khoẻ gia đình Việt",
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "© 2025 Gourmet Kitchen Inc. Giữ toàn bộ bản quyền sở hữu trí tuệ.",
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context).withOpacity(0.6),
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
          child: Text(
            lang.tr('about_us'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TColor.primaryTextOf(context),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
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
              Icons.shopping_bag_outlined,
              size: 20,
              color: TColor.primaryTextOf(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(bool isDark) {
    if (isDark) {
      // Dark Prestige Card (Screenshot 1)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF171B26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: TColor.primary.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TColor.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TColor.primary.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "✨",
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Câu chuyện thương hiệu",
                    style: TextStyle(
                      color: TColor.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
                children: [
                  const TextSpan(
                    text: "Ẩm Thực Đỉnh Cao,\n",
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: "Trọn Vẹn Từng Giây",
                    style: TextStyle(color: TColor.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Chúng tôi không chỉ đem đến bữa ăn, mà trao gửi cả trải nghiệm tinh hoa ẩm thực phục vụ tận cửa nhà bạn.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    } else {
      // Light Orange Card (Screenshot 2)
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: TColor.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🍴", style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Text(
                    "ẨM THỰC TỪ TRÁI TIM",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              "Mang hương vị ấm áp đến từng bữa ăn của bạn",
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Chúng tôi tin rằng mỗi món ăn trao đi là một niềm vui sum vầy trọn vẹn, gửi gắm trọn vẹn tình cảm và sự tươi ngon nhất.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 28,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Text("👨‍🍳", style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Text("🍲", style: TextStyle(fontSize: 11)),
                        ),
                      ),
                      Positioned(
                        left: 32,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.white,
                          child: Text("🥗", style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "Hơn 50+ đầu bếp chuyên nghiệp",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatsRow(bool isDark) {
    final stats = [
      {"num": "500K+", "label": isDark ? "Bữa ăn đã phục vụ" : "Bữa ăn đã trao"},
      {"num": "4.9 ★", "label": isDark ? "Đánh giá hài lòng" : "Đánh giá cao"},
      {"num": "98%", "label": isDark ? "Khách hài lòng" : "Khách hài lòng"},
    ];

    return Row(
      children: stats.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: TColor.cardOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TColor.borderOf(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  item["num"]!,
                  style: TextStyle(
                    color: TColor.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item["label"]!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TColor.secondaryTextOf(context),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMissionCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: TColor.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.explore_outlined, color: TColor.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SỨ MỆNH & TÂM NHÌN",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Kiến tạo phong cách ẩm thực tương lai",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF11141D) : const Color(0xFFFAFAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF2C3240) : const Color(0xFFEFEFEF),
              ),
            ),
            child: Text(
              '"Định vị thành biểu tượng dịch vụ ẩm thực hiện đại hàng đầu qua việc kết hợp tinh túy nguyên liệu tuyển chọn, bàn tay bếp trưởng tài hoa và công nghệ giao nhận siêu tốc chuẩn xác."',
              style: TextStyle(
                color: TColor.primaryTextOf(context).withOpacity(0.9),
                fontSize: 12,
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreValuesGrid(bool isDark) {
    final values = [
      {
        "icon": Icons.eco_outlined,
        "bg": const Color(0xFFE8F5E9),
        "iconColor": const Color(0xFF2E7D32),
        "title": isDark ? "Tươi Ngon Tuyệt Đối" : "Tươi sạch mỗi ngày",
        "desc": isDark
            ? "100% nguyên liệu canh tác hữu cơ được nhập mới trong ngày."
            : "Tuyển chọn nghiêm ngặt từ nông trại đạt chuẩn VietGAP.",
      },
      {
        "icon": Icons.bolt_outlined,
        "bg": const Color(0xFFFFF3E0),
        "iconColor": const Color(0xFFE65100),
        "title": isDark ? "Giao Nhận Thần Tốc" : "Giao trong 30 phút",
        "desc": isDark
            ? "Nhiệt độ món ăn được bảo toàn hoàn hảo tối đa trong 25 phút."
            : "Hộp giữ nhiệt chuyên dụng, món đến tay luôn nóng giòn.",
      },
      {
        "icon": Icons.shield_outlined,
        "bg": const Color(0xFFE3F2FD),
        "iconColor": const Color(0xFF1565C0),
        "title": isDark ? "An Toàn 5 Sao" : "Đầu bếp tâm huyết",
        "desc": isDark
            ? "Quy trình bếp khép kín tiêu chuẩn an toàn quốc tế nghiêm ngặt."
            : "Chăm chút tỉ mỉ từng đĩa ăn bằng cả niềm đam mê ẩm thực.",
      },
      {
        "icon": Icons.favorite_border_rounded,
        "bg": const Color(0xFFFCE4EC),
        "iconColor": const Color(0xFFC2185B),
        "title": isDark ? "Tận Tâm Trọn Vẹn" : "Hỗ trợ 24/7",
        "desc": isDark
            ? "Luôn lắng nghe và chăm sóc từng khẩu vị cá nhân chu đáo nhất."
            : "Luôn lắng nghe và hỗ trợ đổi trả tức thì nếu bạn chưa ưng ý.",
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: values.length,
      itemBuilder: (context, index) {
        final item = values[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: TColor.cardOf(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TColor.borderOf(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? TColor.primary.withOpacity(0.15) : (item["bg"] as Color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item["icon"] as IconData,
                  color: isDark ? TColor.primary : (item["iconColor"] as Color),
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item["title"] as String,
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item["desc"] as String,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImpressiveNumbersCard(bool isDark) {
    final numbers = [
      {"val": "500K+", "sub": "Bữa ăn đã phục vụ"},
      {"val": "4.9★", "sub": "Đánh giá hài lòng"},
      {"val": "25 phút", "sub": "Giao hàng bình quân"},
      {"val": "120+", "sub": "Đầu bếp thượng hạng"},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        children: [
          Text(
            "CON SỐ Ấn TƯỢNG ĐỒNG HÀNH CÙNG BẠN",
            style: TextStyle(
              color: TColor.primaryTextOf(context),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: numbers.length,
            itemBuilder: (context, index) {
              final item = numbers[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF11141D) : const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TColor.borderOf(context)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item["val"]!,
                      style: TextStyle(
                        color: TColor.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item["sub"]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactFooter(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Cần hỗ trợ trực tiếp?",
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.phone_in_talk_rounded, color: TColor.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "1900 8888",
                    style: TextStyle(
                      color: TColor.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: TColor.borderOf(context), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Mạng xã hội cộng đồng",
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  _buildSocialBtn("📘"),
                  const SizedBox(width: 8),
                  _buildSocialBtn("📸"),
                  const SizedBox(width: 8),
                  _buildSocialBtn("✉️"),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialBtn(String emoji) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: TColor.borderOf(context).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
