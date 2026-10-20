import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/color_extension.dart';
import '../../../services/bank_service.dart';
import 'bank_picker_sheet.dart';

class StoreProfileEditSheet extends StatefulWidget {
  final Map<String, dynamic> storeProfile;
  final Function(Map<String, dynamic> data) onSave;

  const StoreProfileEditSheet({
    super.key,
    required this.storeProfile,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> storeProfile,
    required Function(Map<String, dynamic> data) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StoreProfileEditSheet(
        storeProfile: storeProfile,
        onSave: onSave,
      ),
    );
  }

  @override
  State<StoreProfileEditSheet> createState() => _StoreProfileEditSheetState();
}

class _StoreProfileEditSheetState extends State<StoreProfileEditSheet> {
  late TextEditingController _txtTenQuan;
  late TextEditingController _txtSdt;
  late TextEditingController _txtDiaChi;
  late TextEditingController _txtMoTa;
  late TextEditingController _txtDanhMuc;
  late TextEditingController _txtPrepTime;
  late TextEditingController _txtHoTen;
  late TextEditingController _txtNganHang;
  late TextEditingController _txtSoTK;
  late TextEditingController _txtChuTK;

  String _selectedBankLogo = '';
  bool _isSaving = false;

  final List<String> _popularCategories = [
    'Bánh kem',
    'Ăn vặt',
    'Trà sữa',
    'Cà phê',
    'Cơm',
    'Bún / Phở',
    'Bánh ngọt',
    'Đồ ăn nhanh',
  ];

  final List<int> _popularTimes = [10, 15, 20, 25, 30, 45];

  @override
  void initState() {
    super.initState();
    final p = widget.storeProfile;
    _txtTenQuan = TextEditingController(text: p['tenQuan'] ?? '');
    _txtSdt = TextEditingController(text: p['sdt'] ?? '');
    _txtDiaChi = TextEditingController(text: p['diaChi'] ?? '');
    _txtMoTa = TextEditingController(text: p['moTa'] ?? '');
    _txtDanhMuc = TextEditingController(text: p['danhMuc'] ?? 'Bánh kem');
    _txtPrepTime = TextEditingController(text: (p['thoiGianChuanBi'] ?? 20).toString());
    _txtHoTen = TextEditingController(text: p['hoTenChuQuan'] ?? '');
    final initialBank = p['tenNganHang'] ?? 'VietinBank (ICB)';
    _txtNganHang = TextEditingController(text: initialBank);
    _txtSoTK = TextEditingController(text: p['soTaiKhoanNganHang'] ?? '');
    _txtChuTK = TextEditingController(text: p['tenChuTaiKhoan'] ?? '');

    _resolveInitialBankLogo(initialBank);
  }

  void _resolveInitialBankLogo(String bankName) async {
    final lower = bankName.toLowerCase().trim();
    if (lower.isEmpty) return;
    try {
      final banks = await BankService.getVietQRBanks();
      final match = banks.firstWhere(
        (b) =>
            lower.contains(b.code.toLowerCase()) ||
            lower.contains(b.shortName.toLowerCase()),
        orElse: () => banks.first,
      );
      if (mounted && match.logo.isNotEmpty) {
        setState(() {
          _selectedBankLogo = match.logo;
        });
      }
    } catch (_) {}
  }

  void _openBankPicker() {
    BankPickerSheet.show(
      context,
      currentBankName: _txtNganHang.text,
      onSelect: (bank) {
        setState(() {
          _txtNganHang.text = bank.displayName;
          _selectedBankLogo = bank.logo;
        });
      },
    );
  }

  @override
  void dispose() {
    _txtTenQuan.dispose();
    _txtSdt.dispose();
    _txtDiaChi.dispose();
    _txtMoTa.dispose();
    _txtDanhMuc.dispose();
    _txtPrepTime.dispose();
    _txtHoTen.dispose();
    _txtNganHang.dispose();
    _txtSoTK.dispose();
    _txtChuTK.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);

    final data = {
      'tenQuan': _txtTenQuan.text.trim(),
      'sdt': _txtSdt.text.trim(),
      'diaChi': _txtDiaChi.text.trim(),
      'moTa': _txtMoTa.text.trim(),
      'danhMuc': _txtDanhMuc.text.trim(),
      'thoiGianChuanBi': int.tryParse(_txtPrepTime.text.trim()) ?? 20,
      'hoTenChuQuan': _txtHoTen.text.trim(),
      'tenNganHang': _txtNganHang.text.trim(),
      'soTaiKhoanNganHang': _txtSoTK.text.trim(),
      'tenChuTaiKhoan': _txtChuTK.text.trim(),
    };

    await widget.onSave(data);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0F131C) : const Color(0xFFF8FAFC);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF332014) : const Color(0xFFFFF4ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFD8BF).withValues(alpha: isDark ? 0.2 : 0.6),
                      width: 1.0,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.storefront_outlined, color: Color(0xFFFC6011), size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chỉnh sửa hồ sơ quán',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: TColor.primaryTextOf(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cập nhật thông tin hiển thị & thanh toán',
                        style: TextStyle(
                          fontSize: 12,
                          color: TColor.secondaryTextOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        Icons.close_rounded,
                        size: 19,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: TColor.borderOf(context).withValues(alpha: 0.6)),

          // Scrollable Form Content (Optimized Padding - No Empty Space)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              children: [
                // SECTION 1: THÔNG TIN CƠ BẢN & LIÊN HỆ
                _buildSectionCard(
                  context,
                  badgeIcon: Icons.apartment_rounded,
                  badgeBgColor: const Color(0xFFFFF4ED),
                  badgeIconColor: const Color(0xFFEA580C),
                  title: 'THÔNG TIN CƠ BẢN & LIÊN HỆ',
                  subtitle: 'Tên hiển thị, số điện thoại và địa chỉ đón trả',
                  children: [
                    // Tên quán
                    _buildCleanInputField(
                      context,
                      label: 'Tên quán / Nhà hàng',
                      isRequired: true,
                      controller: _txtTenQuan,
                      icon: Icons.storefront_outlined,
                      iconColor: const Color(0xFFEA580C),
                      hint: 'VD: Tiệm Kem & Bánh Sinh Nhật Sweet Cake',
                    ),
                    const SizedBox(height: 10),

                    // Số điện thoại hotline + Badge 'Đã xác thực'
                    _buildCleanInputField(
                      context,
                      label: 'Số điện thoại hotline',
                      isRequired: true,
                      controller: _txtSdt,
                      icon: Icons.phone_outlined,
                      iconColor: const Color(0xFF059669),
                      hint: 'VD: 0908887766',
                      keyboardType: TextInputType.phone,
                      labelTrailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 12, color: Color(0xFF059669)),
                            SizedBox(width: 3),
                            Text(
                              'Đã xác thực',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Địa chỉ quán + Button 'Đổi vị trí'
                    _buildCleanInputField(
                      context,
                      label: 'Địa chỉ quán',
                      isRequired: true,
                      controller: _txtDiaChi,
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFFEF4444),
                      hint: 'VD: 98 Lê Lợi, Hà Nội, Việt Nam',
                      inputTrailing: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {},
                        child: const Text(
                          'Đổi vị trí',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFC6011),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Mô tả quán + Character count
                    _buildCleanInputField(
                      context,
                      label: 'Mô tả giới thiệu quán',
                      isRequired: false,
                      controller: _txtMoTa,
                      icon: Icons.description_outlined,
                      iconColor: const Color(0xFF6366F1),
                      hint: 'Chuyên cung cấp bánh kem và làm bánh theo yêu cầu',
                      maxLines: 2,
                      labelTrailing: Text(
                        '${_txtMoTa.text.length} / 200',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: TColor.secondaryTextOf(context),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // SECTION 2: VẬN HÀNH & PHỤC VỤ
                _buildSectionCard(
                  context,
                  badgeIcon: Icons.access_time_rounded,
                  badgeBgColor: const Color(0xFFE0F2FE),
                  badgeIconColor: const Color(0xFF0284C7),
                  title: 'VẬN HÀNH & PHỤC VỤ',
                  subtitle: 'Phân loại món chính và thời gian chuẩn bị',
                  children: [
                    // Danh mục món chính
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Text(
                            'Danh mục / Thể loại món chính',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: TColor.secondaryTextOf(context),
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2430) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFED7AA)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎂', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  _txtDanhMuc.text.isNotEmpty ? _txtDanhMuc.text : 'Bánh kem',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Quick category pills
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _popularCategories.map((cat) {
                        final isSelected = _txtDanhMuc.text == cat;
                        return InkWell(
                          onTap: () => setState(() => _txtDanhMuc.text = cat),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFC6011).withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFC6011) : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? const Color(0xFFFC6011) : TColor.secondaryTextOf(context),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 18),

                    // Thời gian chuẩn bị món
                    _buildCleanInputField(
                      context,
                      label: 'Thời gian chuẩn bị món trung bình (phút)',
                      isRequired: true,
                      controller: _txtPrepTime,
                      icon: Icons.hourglass_top_rounded,
                      iconColor: const Color(0xFF0284C7),
                      hint: '20',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: _popularTimes.map((min) {
                        final isSelected = _txtPrepTime.text == min.toString();
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: InkWell(
                              onTap: () => setState(() => _txtPrepTime.text = min.toString()),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF0284C7)
                                      : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${min}p',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? Colors.white : TColor.secondaryTextOf(context),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // SECTION 3: TÀI KHOẢN NHẬN TIỀN & VIETQR
                _buildSectionCard(
                  context,
                  badgeIcon: Icons.account_balance_rounded,
                  badgeBgColor: const Color(0xFFEEF2FF),
                  badgeIconColor: const Color(0xFF4F46E5),
                  title: 'TÀI KHOẢN NHẬN TIỀN (VIETQR)',
                  subtitle: 'Tài khoản ngân hàng thụ hưởng nhận thanh toán từ khách',
                  children: [
                    _buildCleanInputField(
                      context,
                      label: 'Họ tên chủ quán / Đại diện',
                      isRequired: true,
                      controller: _txtHoTen,
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF2563EB),
                      hint: 'VD: TRẦN DŨ BẢO',
                    ),
                    const SizedBox(height: 10),

                    // Tên ngân hàng thụ hưởng
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Text(
                            'Tên ngân hàng thụ hưởng',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: TColor.secondaryTextOf(context),
                            ),
                          ),
                          const Text(
                            ' *',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _openBankPicker,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2430) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            if (_selectedBankLogo.isNotEmpty)
                              Container(
                                width: 34,
                                height: 22,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Image.network(_selectedBankLogo, fit: BoxFit.contain),
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(Icons.account_balance_outlined, size: 19, color: Color(0xFF4F46E5)),
                              ),
                            Expanded(
                              child: Text(
                                _txtNganHang.text.isNotEmpty ? _txtNganHang.text : 'Chọn ngân hàng từ danh sách...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TColor.primaryTextOf(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFED7AA)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Chọn',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEA580C),
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFFEA580C)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Số tài khoản ngân hàng
                    _buildCleanInputField(
                      context,
                      label: 'Số tài khoản ngân hàng',
                      isRequired: true,
                      controller: _txtSoTK,
                      icon: Icons.credit_card_outlined,
                      iconColor: const Color(0xFF7C3AED),
                      hint: 'VD: 1098898989',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),

                    // Tên chủ tài khoản
                    _buildCleanInputField(
                      context,
                      label: 'Tên chủ tài khoản (In hoa không dấu)',
                      isRequired: true,
                      controller: _txtChuTK,
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xFF059669),
                      hint: 'VD: TRAN DU BAO',
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Pinned Bottom Action Button (Optimized Compact Padding)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            decoration: BoxDecoration(
              color: TColor.cardOf(context),
              border: Border(top: BorderSide(color: TColor.borderOf(context).withValues(alpha: 0.6))),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFC6011), Color(0xFFFF5200)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFC6011).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 20),
                    label: Text(
                      _isSaving ? 'ĐANG LƯU THAY ĐỔI...' : 'LƯU HỒ SƠ QUÁN',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData badgeIcon,
    required Color badgeBgColor,
    required Color badgeIconColor,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TColor.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? badgeIconColor.withValues(alpha: 0.16) : badgeBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(badgeIcon, color: badgeIconColor, size: 19),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: TColor.primaryTextOf(context),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: TColor.secondaryTextOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: TColor.borderOf(context)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCleanInputField(
    BuildContext context, {
    required String label,
    required bool isRequired,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? labelTrailing,
    Widget? inputTrailing,
    Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: TColor.secondaryTextOf(context),
                    ),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              if (labelTrailing != null) labelTrailing,
            ],
          ),
        ),

        // Input Container matching the reference image exactly
        Container(
          constraints: BoxConstraints(minHeight: maxLines > 1 ? 64 : 46),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  right: 10,
                  top: maxLines > 1 ? 12 : 0,
                ),
                child: Icon(icon, size: 19, color: iconColor),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  textCapitalization: textCapitalization,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TColor.primaryTextOf(context),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: TColor.placeholder,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: maxLines > 1 ? 11 : 13),
                  ),
                ),
              ),
              if (inputTrailing != null) inputTrailing,
            ],
          ),
        ),
      ],
    );
  }
}
