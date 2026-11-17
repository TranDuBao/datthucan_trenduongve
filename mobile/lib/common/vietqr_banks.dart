import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VietQrBankItem {
  final String bin;
  final String code;
  final String shortName;
  final String name;

  const VietQrBankItem({
    required this.bin,
    required this.code,
    required this.shortName,
    required this.name,
  });

  String get displayName => '$shortName - $name';
  String get logoUrl => 'https://cdn.vietqr.io/img/$code.png';
}

class VietQrBanks {
  static const List<VietQrBankItem> all = [
    VietQrBankItem(bin: '970415', code: 'ICB', shortName: 'VietinBank', name: 'Ngân hàng TMCP Công thương Việt Nam'),
    VietQrBankItem(bin: '970436', code: 'VCB', shortName: 'Vietcombank', name: 'Ngân hàng TMCP Ngoại Thương Việt Nam'),
    VietQrBankItem(bin: '970418', code: 'BIDV', shortName: 'BIDV', name: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam'),
    VietQrBankItem(bin: '970405', code: 'VBA', shortName: 'Agribank', name: 'Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam'),
    VietQrBankItem(bin: '970448', code: 'OCB', shortName: 'OCB', name: 'Ngân hàng TMCP Phương Đông'),
    VietQrBankItem(bin: '970422', code: 'MB', shortName: 'MBBank', name: 'Ngân hàng TMCP Quân đội'),
    VietQrBankItem(bin: '970407', code: 'TCB', shortName: 'Techcombank', name: 'Ngân hàng TMCP Kỹ thương Việt Nam'),
    VietQrBankItem(bin: '970416', code: 'ACB', shortName: 'ACB', name: 'Ngân hàng TMCP Á Châu'),
    VietQrBankItem(bin: '970432', code: 'VPB', shortName: 'VPBank', name: 'Ngân hàng TMCP Việt Nam Thịnh Vượng'),
    VietQrBankItem(bin: '970423', code: 'TPB', shortName: 'TPBank', name: 'Ngân hàng TMCP Tiên Phong'),
    VietQrBankItem(bin: '970403', code: 'STB', shortName: 'Sacombank', name: 'Ngân hàng TMCP Sài Gòn Tài Lộc'),
    VietQrBankItem(bin: '970437', code: 'HDB', shortName: 'HDBank', name: 'Ngân hàng TMCP Phát triển Thành phố Hồ Chí Minh'),
    VietQrBankItem(bin: '970454', code: 'VCCB', shortName: 'VietCapitalBank', name: 'Ngân hàng TMCP Bản Việt'),
    VietQrBankItem(bin: '970429', code: 'SCB', shortName: 'SCB', name: 'Ngân hàng TMCP Sài Gòn'),
    VietQrBankItem(bin: '970441', code: 'VIB', shortName: 'VIB', name: 'Ngân hàng TMCP Quốc tế Việt Nam'),
    VietQrBankItem(bin: '970443', code: 'SHB', shortName: 'SHB', name: 'Ngân hàng TMCP Sài Gòn - Hà Nội'),
    VietQrBankItem(bin: '970431', code: 'EIB', shortName: 'Eximbank', name: 'Ngân hàng TMCP Xuất Nhập khẩu Việt Nam'),
    VietQrBankItem(bin: '970426', code: 'MSB', shortName: 'MSB', name: 'Ngân hàng TMCP Hàng Hải'),
    VietQrBankItem(bin: '546034', code: 'CAKE', shortName: 'CAKE', name: 'TMCP Việt Nam Thịnh Vượng - Ngân hàng số CAKE by VPBank'),
    VietQrBankItem(bin: '546035', code: 'Ubank', shortName: 'Ubank', name: 'TMCP Việt Nam Thịnh Vượng - Ngân hàng số Ubank by VPBank'),
    VietQrBankItem(bin: '963388', code: 'TIMO', shortName: 'Timo', name: 'Ngân hàng số Timo by Ban Viet Bank (Timo by Ban Viet Bank)'),
    VietQrBankItem(bin: '971005', code: 'VTLMONEY', shortName: 'ViettelMoney', name: 'Tổng Công ty Dịch vụ số Viettel - Chi nhánh tập đoàn công nghiệp viễn thông Quân Đội'),
    VietQrBankItem(bin: '971011', code: 'VNPTMONEY', shortName: 'VNPTMoney', name: 'Trung tâm dịch vụ tài chính số VNPT- Chi nhánh Tổng công ty truyền thông (VNPT Fintech)'),
    VietQrBankItem(bin: '970400', code: 'SGICB', shortName: 'SaigonBank', name: 'Ngân hàng TMCP Sài Gòn Công Thương'),
    VietQrBankItem(bin: '970409', code: 'BAB', shortName: 'BacABank', name: 'Ngân hàng TMCP Bắc Á'),
    VietQrBankItem(bin: '971133', code: 'PVDB', shortName: 'PVcomBank Pay', name: 'Ngân hàng số PVcomBank'),
    VietQrBankItem(bin: '971025', code: 'momo', shortName: 'MoMo', name: 'CTCP Dịch Vụ Di Động Trực Tuyến'),
    VietQrBankItem(bin: '970412', code: 'PVCB', shortName: 'PVcomBank', name: 'Ngân hàng TMCP Đại Chúng Việt Nam'),
    VietQrBankItem(bin: '970414', code: 'MBV', shortName: 'MBV', name: 'Ngân hàng TNHH MTV Việt Nam Hiện Đại'),
    VietQrBankItem(bin: '970419', code: 'NCB', shortName: 'NCB', name: 'Ngân hàng TMCP Quốc Dân'),
    VietQrBankItem(bin: '970424', code: 'SHBVN', shortName: 'ShinhanBank', name: 'Ngân hàng TNHH MTV Shinhan Việt Nam'),
    VietQrBankItem(bin: '970425', code: 'ABB', shortName: 'ABBANK', name: 'Ngân hàng TMCP An Bình'),
    VietQrBankItem(bin: '970427', code: 'VAB', shortName: 'VietABank', name: 'Ngân hàng TMCP Việt Á'),
    VietQrBankItem(bin: '970428', code: 'NAB', shortName: 'NamABank', name: 'Ngân hàng TMCP Nam Á'),
    VietQrBankItem(bin: '970430', code: 'PGB', shortName: 'PGBank', name: 'Ngân hàng TMCP Thịnh vượng và Phát triển'),
    VietQrBankItem(bin: '970433', code: 'VIETBANK', shortName: 'VietBank', name: 'Ngân hàng TMCP Việt Nam Thương Tín'),
    VietQrBankItem(bin: '970438', code: 'BVB', shortName: 'BaoVietBank', name: 'Ngân hàng TMCP Bảo Việt'),
    VietQrBankItem(bin: '970440', code: 'SEAB', shortName: 'SeABank', name: 'Ngân hàng TMCP Đông Nam Á'),
    VietQrBankItem(bin: '970446', code: 'COOPBANK', shortName: 'COOPBANK', name: 'Ngân hàng Hợp tác xã Việt Nam'),
    VietQrBankItem(bin: '970449', code: 'LPB', shortName: 'LPBank', name: 'Ngân hàng TMCP Lộc Phát Việt Nam'),
    VietQrBankItem(bin: '970452', code: 'KLB', shortName: 'KienLongBank', name: 'Ngân hàng TMCP Kiên Long'),
    VietQrBankItem(bin: '668888', code: 'KBank', shortName: 'KBank', name: 'Ngân hàng Đại chúng TNHH Kasikornbank'),
    VietQrBankItem(bin: '970466', code: 'KEBHANAHCM', shortName: 'KEBHanaHCM', name: 'Ngân hàng KEB Hana – Chi nhánh Thành phố Hồ Chí Minh'),
    VietQrBankItem(bin: '970467', code: 'KEBHANAHN', shortName: 'KEBHANAHN', name: 'Ngân hàng KEB Hana – Chi nhánh Hà Nội'),
    VietQrBankItem(bin: '977777', code: 'MAFC', shortName: 'MAFC', name: 'Công ty Tài chính TNHH MTV Mirae Asset (Việt Nam)'),
    VietQrBankItem(bin: '999888', code: 'VBSP', shortName: 'VBSP', name: 'Ngân hàng Chính sách Xã hội'),
    VietQrBankItem(bin: '963668', code: 'BNP HN', shortName: 'BNP HN', name: 'Ngân hàng BNP Paribas – Chi nhánh Hà Nội'),
    VietQrBankItem(bin: '555666', code: 'BIDC', shortName: 'BIDC', name: 'Ngân hàng Đầu Tư Và Phát Triển Campuchia - Chi nhánh Hà Nội'),
    VietQrBankItem(bin: '963666', code: 'BNP HCM', shortName: 'BNP HCM', name: 'Ngân hàng BNP Paribas – Chi nhánh Thành phố Hồ Chí Minh'),
    VietQrBankItem(bin: '971101', code: 'ZALOPAY', shortName: 'ZaloPay', name: 'Ví điện tử ZaloPay'),
    VietQrBankItem(bin: '963688', code: 'BOCHK', shortName: 'BOCHK', name: 'Ngân hàng Bank of China (Hong Kong) Limited – Chi nhánh Hồ Chí Minh'),
    VietQrBankItem(bin: '970465', code: 'BSP', shortName: 'BSP', name: 'Ngân hàng SinoPac - Chi nhánh Thành phố Hồ Chí Minh'),
    VietQrBankItem(bin: '168999', code: 'CUBHCM', shortName: 'CUBHCM', name: 'Ngân hàng Cathay United Bank – Chi nhánh Hồ Chí Minh'),
    VietQrBankItem(bin: '963686', code: 'ESUN', shortName: 'ESUN', name: 'Ngân hàng Thương mại TNHH E.SUN – Chi nhánh Đồng Nai (ESUNBANK)'),
    VietQrBankItem(bin: '963669', code: 'ICBC', shortName: 'ICBC', name: 'Ngân hàng Công thương Trung Quốc – Chi nhánh thành phố Hà Nội'),
    VietQrBankItem(bin: '971032', code: 'MVAS', shortName: 'MVAS', name: 'Trung tâm Dịch vụ số Mobifone – Chi nhánh Tổng Công ty viễn thông Mobifone'),
    VietQrBankItem(bin: '963326', code: 'TNEX', shortName: 'TNEX', name: 'TNEX by MSB'),
    VietQrBankItem(bin: '458761', code: 'HSBC', shortName: 'HSBC', name: 'Ngân hàng TNHH MTV HSBC (Việt Nam)'),
    VietQrBankItem(bin: '970442', code: 'HLBVN', shortName: 'HongLeong', name: 'Ngân hàng TNHH MTV Hong Leong Việt Nam'),
    VietQrBankItem(bin: '970455', code: 'IBK - HN', shortName: 'IBKHN', name: 'Ngân hàng Công nghiệp Hàn Quốc - Chi nhánh Hà Nội'),
    VietQrBankItem(bin: '970456', code: 'IBK - HCM', shortName: 'IBKHCM', name: 'Ngân hàng Công nghiệp Hàn Quốc - Chi nhánh TP. Hồ Chí Minh'),
    VietQrBankItem(bin: '970434', code: 'IVB', shortName: 'IndovinaBank', name: 'Ngân hàng TNHH Indovina'),
    VietQrBankItem(bin: '970406', code: 'Vikki', shortName: 'Vikki', name: 'Ngân hàng TNHH Một thành viên số Vikki'),
    VietQrBankItem(bin: '801011', code: 'NHB HN', shortName: 'Nonghyup', name: 'Ngân hàng Nonghyup - Chi nhánh Hà Nội'),
    VietQrBankItem(bin: '796500', code: 'DBS', shortName: 'DBSBank', name: 'DBS Bank Ltd - Chi nhánh Thành phố Hồ Chí Minh'),
    VietQrBankItem(bin: '970439', code: 'PBVN', shortName: 'PublicBank', name: 'Ngân hàng TNHH MTV Public Việt Nam'),
    VietQrBankItem(bin: '970410', code: 'SCVN', shortName: 'StandardChartered', name: 'Ngân hàng TNHH MTV Standard Chartered Bank Việt Nam'),
    VietQrBankItem(bin: '533948', code: 'CITIBANK', shortName: 'Citibank', name: 'Ngân hàng Citibank, N.A. - Chi nhánh Hà Nội'),
    VietQrBankItem(bin: '422589', code: 'CIMB', shortName: 'CIMB', name: 'Ngân hàng TNHH MTV CIMB Việt Nam'),
    VietQrBankItem(bin: '970458', code: 'UOB', shortName: 'UnitedOverseas', name: 'Ngân hàng United Overseas - Chi nhánh TP. Hồ Chí Minh'),
    VietQrBankItem(bin: '970444', code: 'CBB', shortName: 'CBBank', name: 'Ngân hàng Thương mại trách nhiệm hữu hạn một thành viên Ngoại thương Công nghệ số (Vietcombank Neo Limited)'),
    VietQrBankItem(bin: '970408', code: 'GPB', shortName: 'GPBank', name: 'Ngân hàng Thương mại TNHH MTV Dầu Khí Toàn Cầu'),
    VietQrBankItem(bin: '970421', code: 'VRB', shortName: 'VRB', name: 'Ngân hàng Liên doanh Việt - Nga'),
    VietQrBankItem(bin: '970457', code: 'WVN', shortName: 'Woori', name: 'Ngân hàng TNHH MTV Woori Việt Nam'),
    VietQrBankItem(bin: '970462', code: 'KBHN', shortName: 'KookminHN', name: 'Ngân hàng Kookmin - Chi nhánh Hà Nội'),
    VietQrBankItem(bin: '970463', code: 'KBHCM', shortName: 'KookminHCM', name: 'Ngân hàng Kookmin - Chi nhánh Thành phố Hồ Chí Minh'),
  ];

  static VietQrBankItem findByCodeOrBin(String? query) {
    if (query == null || query.trim().isEmpty) return all.first;
    final q = query.trim().toUpperCase();
    if (q == 'CTG') {
      return all.firstWhere((b) => b.code == 'ICB', orElse: () => all.first);
    }
    for (final b in all) {
      if (b.code.toUpperCase() == q || b.bin == q || b.shortName.toUpperCase() == q) {
        return b;
      }
    }
    // Partial search
    for (final b in all) {
      if (b.shortName.toUpperCase().contains(q) || b.name.toUpperCase().contains(q)) {
        return b;
      }
    }
    return all.first;
  }
}

/// Modal bottom sheet cho phép tìm kiếm và chọn ngân hàng thuận tiện
class VietQrBankPickerSheet extends StatefulWidget {
  final String? initialCode;

  const VietQrBankPickerSheet({super.key, this.initialCode});

  static Future<VietQrBankItem?> show(BuildContext context, {String? initialCode}) {
    return showModalBottomSheet<VietQrBankItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VietQrBankPickerSheet(initialCode: initialCode),
    );
  }

  @override
  State<VietQrBankPickerSheet> createState() => _VietQrBankPickerSheetState();
}

class _VietQrBankPickerSheetState extends State<VietQrBankPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<VietQrBankItem> _filtered = VietQrBanks.all;

  static const List<String> popularCodes = [
    'MB', 'VCB', 'TCB', 'VPB', 'ACB', 'BIDV', 'VBA', 'TPB', 'ICB', 'STB', 'HDB', 'LPB', 'MSB', 'SHB', 'OCB', 'CAKE', 'TIMO'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = VietQrBanks.all;
      } else {
        _filtered = VietQrBanks.all.where((b) {
          return b.code.toLowerCase().contains(query) ||
              b.shortName.toLowerCase().contains(query) ||
              b.name.toLowerCase().contains(query) ||
              b.bin.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2430) : Colors.white;
    final inputBg = isDark ? const Color(0xFF262E3D) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF333C4D) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn ngân hàng thụ hưởng',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: textSecondary,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: GoogleFonts.outfit(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFFFC6011)),
                hintText: 'Tìm theo tên ngân hàng, mã viết tắt (VCB, MB...)...',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: textSecondary),
                filled: true,
                fillColor: inputBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC6011), width: 1.5)),
              ),
            ),
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: popularCodes.map((code) {
                  final b = VietQrBanks.findByCodeOrBin(code);
                  final isSelected = widget.initialCode?.toUpperCase() == code;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => Navigator.pop(context, b),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFC6011)
                              : (isDark ? const Color(0xFF262E3D) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFC6011) : borderColor,
                          ),
                        ),
                        child: Text(
                          b.shortName,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: textSecondary),
                          const SizedBox(height: 8),
                          Text(
                            'Không tìm thấy ngân hàng phù hợp',
                            style: GoogleFonts.outfit(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? const Color(0xFF262E3D) : const Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, index) {
                      final item = _filtered[index];
                      final isSelected = widget.initialCode?.toUpperCase() == item.code.toUpperCase();
                      return ListTile(
                        onTap: () => Navigator.pop(context, item),
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: VietQrBankLogo(
                          bank: item,
                          width: 44,
                          height: 44,
                          isSelected: isSelected,
                          borderColor: isSelected ? const Color(0xFFFC6011) : borderColor,
                        ),
                        title: Text(
                          item.shortName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFFFC6011) : textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFC6011), size: 20)
                            : Icon(Icons.chevron_right_rounded, color: textSecondary, size: 18),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị Logo chính thức của ngân hàng từ CDN VietQR với cơ chế fallback thông minh
class VietQrBankLogo extends StatelessWidget {
  final VietQrBankItem bank;
  final double width;
  final double height;
  final double borderRadius;
  final bool isSelected;
  final Color? borderColor;

  const VietQrBankLogo({
    super.key,
    required this.bank,
    this.width = 44,
    this.height = 44,
    this.borderRadius = 10,
    this.isSelected = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? (isSelected ? const Color(0xFFFC6011) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius > 4 ? borderRadius - 2 : borderRadius),
        child: Image.network(
          bank.logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              bank.code.length > 5 ? bank.code.substring(0, 4) : bank.code,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFC6011),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
