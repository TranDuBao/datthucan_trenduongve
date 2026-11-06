import 'package:flutter/material.dart';
import 'package:food_route/common/color_extension.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/locator.dart';
import '../../common_widget/smart_network_image.dart';
import '../../common_widget/social_brand_icon.dart';
import '../../providers/language_provider.dart';
import '../../services/socket_service.dart';
import '../../services/system_info_service.dart';
import '../../widgets/skeleton/about_us_skeleton.dart';
import 'my_order_view.dart';

class AboutUsView extends StatefulWidget {
  const AboutUsView({super.key});

  @override
  State<AboutUsView> createState() => _AboutUsViewState();
}

class _AboutUsViewState extends State<AboutUsView> {
  Map<String, dynamic>? _systemInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSystemInfo();
    locator<SocketService>().subscribe('about_us:updated', _onAboutUsUpdated);
  }

  @override
  void dispose() {
    locator<SocketService>().unsubscribe('about_us:updated', _onAboutUsUpdated);
    super.dispose();
  }

  void _onAboutUsUpdated(dynamic _) {
    _fetchSystemInfo();
  }

  Future<void> _fetchSystemInfo() async {
    final data = await SystemInfoService.fetchAboutUs();
    if (mounted) {
      setState(() {
        _systemInfo = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchExternal(String urlStr) async {
    if (urlStr.isEmpty) return;
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AboutUsView] Launch error: $e');
    }
  }

  IconData _mapIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'navigation':
        return Icons.navigation_outlined;
      case 'flame':
        return Icons.local_fire_department_outlined;
      case 'shield':
        return Icons.shield_outlined;
      case 'store':
        return Icons.storefront_outlined;
      case 'leaf':
      case 'eco':
        return Icons.eco_outlined;
      case 'clock':
        return Icons.access_time_rounded;
      case 'heart':
        return Icons.favorite_border_rounded;
      case 'award':
        return Icons.military_tech_outlined;
      default:
        return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = context.watch<LanguageProvider>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: TColor.bgOf(context),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildHeader(context, lang, isDark),
              ),
              const Expanded(
                child: AboutUsSkeleton(),
              ),
            ],
          ),
        ),
      );
    }

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

              // Stats Row (500K+, 4.9, 98% / 25phút)
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
                          _systemInfo?['phienban']?.toString() ?? "Phiên bản 2.5.0 • FoodRoute Official",
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _systemInfo?['banquyen']?.toString() ?? "© 2026 FoodRoute Inc. Giữ toàn bộ bản quyền hệ thống.",
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context).withValues(alpha: 0.6),
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
              Icons.shopping_cart_outlined,
              size: 20,
              color: TColor.primaryTextOf(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(bool isDark) {
    final badge = _systemInfo?['badge']?.toString() ?? "ẨM THỰC TRÊN LỘ TRÌNH";
    final title = _systemInfo?['tieude']?.toString() ?? (isDark ? "Ẩm Thực Đỉnh Cao,\nTrọn Vẹn Từng Giây" : "Mang hương vị ấm áp đến từng bữa ăn của bạn");
    final desc = _systemInfo?['mota']?.toString() ?? "Nền tảng tìm kiếm và đặt món thông minh dọc theo lộ trình di chuyển của bạn. Ghé lấy thức ăn tươi nóng mà không cần chờ đợi.";
    final subBadge = _systemInfo?['sub_badge']?.toString() ?? "Hơn 500+ quán ngon trên mọi cung đường";
    final heroImg = _systemInfo?['hinhanh']?.toString() ?? "";

    Widget heroCardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (heroImg.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SmartNetworkImage(
              imageUrl: heroImg,
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? TColor.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? TColor.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.sparkles, size: 12, color: isDark ? TColor.primary : Colors.white),
              const SizedBox(width: 4),
              Text(
                badge,
                style: TextStyle(
                  color: isDark ? TColor.primary : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isDark ? 22 : 21,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          desc,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isDark ? 0.75 : 0.9),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        if (subBadge.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(LucideIcons.award, size: 14, color: isDark ? TColor.primary : Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subBadge,
                  style: TextStyle(
                    color: isDark ? TColor.primary : Colors.white.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (isDark) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF171B26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: TColor.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: heroCardBody,
      );
    } else {
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
              color: TColor.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: heroCardBody,
      );
    }
  }

  Widget _buildStatsRow(bool isDark) {
    final stat1Val = _systemInfo?['stat1_val']?.toString() ?? "500K+";
    final stat1Label = _systemInfo?['stat1_label']?.toString() ?? "Lộ trình phục vụ";
    final stat2Val = _systemInfo?['stat2_val']?.toString() ?? "4.9★";
    final stat2Label = _systemInfo?['stat2_label']?.toString() ?? "Đánh giá cao";
    final stat3Val = _systemInfo?['stat3_val']?.toString() ?? "99%";
    final stat3Label = _systemInfo?['stat3_label']?.toString() ?? "Khách hài lòng";

    final stats = [
      {"num": stat1Val, "label": stat1Label},
      {"num": stat2Val, "label": stat2Label},
      {"num": stat3Val, "label": stat3Label},
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
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                  color: TColor.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.explore_outlined, color: TColor.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _systemInfo?['sumenh_tieude']?.toString() ?? "SỨ MỆNH & TÂM NHÌN",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _systemInfo?['sumenh_phude']?.toString() ?? "Kiến tạo phong cách ẩm thực di chuyển thông minh",
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
              '"${_systemInfo?['sumenh_noidung']?.toString() ?? 'Định vị thành giải pháp kết nối ẩm thực lộ trình hàng đầu, giúp tối ưu hóa thời gian di chuyển hàng ngày của người dùng bằng công nghệ gợi ý món ngon thông minh, đặt trước tiện lợi và thanh toán an toàn.'}"',
              style: TextStyle(
                color: TColor.primaryTextOf(context).withValues(alpha: 0.9),
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
    final dynamic rawValues = _systemInfo?['giatricotloi'];
    List<Map<String, dynamic>> values = [];

    if (rawValues is List && rawValues.isNotEmpty) {
      final colorList = [
        {"bg": const Color(0xFFE8F5E9), "color": const Color(0xFF2E7D32)},
        {"bg": const Color(0xFFFFF3E0), "color": const Color(0xFFE65100)},
        {"bg": const Color(0xFFE3F2FD), "color": const Color(0xFF1565C0)},
        {"bg": const Color(0xFFFCE4EC), "color": const Color(0xFFC2185B)},
      ];

      for (int i = 0; i < rawValues.length; i++) {
        final valItem = rawValues[i];
        if (valItem is Map) {
          final c = colorList[i % colorList.length];
          values.add({
            "icon": _mapIconData(valItem['icon']?.toString()),
            "bg": c["bg"]!,
            "iconColor": c["color"]!,
            "title": valItem['title']?.toString() ?? "Giá trị",
            "desc": valItem['desc']?.toString() ?? "",
          });
        }
      }
    }

    if (values.isEmpty) {
      values = [
        {
          "icon": Icons.navigation_outlined,
          "bg": const Color(0xFFFFF3E0),
          "iconColor": const Color(0xFFE65100),
          "title": "Tiện đường ghé lấy",
          "desc": "Đặt món trước, ghé lấy ngay trên lộ trình di chuyển mà không mất thời gian.",
        },
        {
          "icon": Icons.local_fire_department_outlined,
          "bg": const Color(0xFFFBE9E7),
          "iconColor": const Color(0xFFD84315),
          "title": "Nóng hổi chuẩn giờ",
          "desc": "Quán canh thời gian chuẩn bị để món ăn vừa hoàn thành đúng lúc bạn đến.",
        },
        {
          "icon": Icons.shield_outlined,
          "bg": const Color(0xFFE3F2FD),
          "iconColor": const Color(0xFF1565C0),
          "title": "Thanh toán an toàn",
          "desc": "Tích hợp thanh toán tiện lợi qua VietQR, PayOS với độ bảo mật tuyệt đối.",
        },
        {
          "icon": Icons.storefront_outlined,
          "bg": const Color(0xFFE8F5E9),
          "iconColor": const Color(0xFF2E7D32),
          "title": "Quán ngon chọn lọc",
          "desc": "Hệ thống nhà hàng, quán ăn dọc tuyến đường được chọn lọc kỹ lưỡng.",
        },
      ];
    }

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
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                  color: isDark ? TColor.primary.withValues(alpha: 0.15) : (item["bg"] as Color),
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

  Widget _buildContactFooter(BuildContext context, bool isDark) {
    final hotline = _systemInfo?['hotline']?.toString() ?? "1900 6868";
    final email = _systemInfo?['email']?.toString() ?? "support@foodroute.vn";
    final address = _systemInfo?['diachi']?.toString() ?? "Khu Công Nghệ Cao, TP. Thủ Đức, TP. Hồ Chí Minh";
    final facebook = _systemInfo?['facebook']?.toString() ?? "";
    final instagram = _systemInfo?['instagram']?.toString() ?? "";
    final telegram = _systemInfo?['telegram']?.toString() ?? "";
    final gmail = _systemInfo?['gmail']?.toString() ?? "";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hotline row (clickable)
          InkWell(
            onTap: () => _launchExternal("tel:${hotline.replaceAll(RegExp(r'\s+'), '')}"),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.phone_rounded, color: TColor.primary, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    "Hotline: ",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    hotline,
                    style: TextStyle(
                      color: TColor.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Email row (clickable)
          InkWell(
            onTap: () => _launchExternal("mailto:$email"),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.mail_outline_rounded, color: TColor.primary, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      email,
                      style: TextStyle(
                        color: TColor.primaryTextOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Address row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, color: TColor.primary, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: TColor.borderOf(context), height: 1),
          const SizedBox(height: 12),

          // Social media & connect channels row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBrandCircleBtn(
                tooltip: "Facebook",
                bgColor: const Color(0xFF1877F2),
                icon: Icons.facebook,
                iconColor: Colors.white,
                onTap: () => _launchExternal(facebook.isNotEmpty ? facebook : "https://facebook.com/foodroute.official"),
              ),
              const SizedBox(width: 16),
              _buildInstagramCircleBtn(
                onTap: () => _launchExternal(instagram.isNotEmpty ? instagram : "https://instagram.com/foodroute.vn"),
              ),
              const SizedBox(width: 16),
              _buildTelegramCircleBtn(
                onTap: () => _launchExternal(telegram.isNotEmpty ? telegram : "https://t.me/foodroute_support"),
              ),
              const SizedBox(width: 16),
              _buildGmailCircleBtn(
                onTap: () => _launchExternal("mailto:${gmail.isNotEmpty ? gmail : 'support@foodroute.vn'}"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCircleBtn({
    required String tooltip,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramCircleBtn({required VoidCallback onTap}) {
    return Tooltip(
      message: "Instagram",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFF09433), Color(0xFFE6683C), Color(0xFFDC2743), Color(0xFFCC2366), Color(0xFFBC1888)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2743).withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: CustomPaint(
              size: Size(20, 20),
              painter: InstagramIconPainter(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelegramCircleBtn({required VoidCallback onTap}) {
    return Tooltip(
      message: "Telegram",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF26A5E4),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF26A5E4).withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Transform.translate(
              offset: const Offset(-1.0, 0.5),
              child: const CustomPaint(
                size: Size(20, 20),
                painter: TelegramIconPainter(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGmailCircleBtn({required VoidCallback onTap}) {
    return Tooltip(
      message: "Gmail",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: CustomPaint(
              size: Size(21, 16.5),
              painter: GmailIconPainter(),
            ),
          ),
        ),
      ),
    );
  }
}
