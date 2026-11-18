import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/color_extension.dart';
import '../../../widgets/custom_toast.dart';
import 'restaurant_format_utils.dart';

class VoucherFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic> input) onSave;

  const VoucherFormSheet({
    super.key,
    this.initialData,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    Map<String, dynamic>? initialData,
    required Function(Map<String, dynamic> input) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => VoucherFormSheet(
        initialData: initialData,
        onSave: onSave,
      ),
    );
  }

  @override
  State<VoucherFormSheet> createState() => _VoucherFormSheetState();
}

class _VoucherFormSheetState extends State<VoucherFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _discountValController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _minOrderController;
  late TextEditingController _totalCountController;

  String _discountType = 'PERCENT'; // 'PERCENT' or 'FIXED'
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _codeController = TextEditingController(text: d?['maCode'] ?? '');
    _nameController = TextEditingController(text: d?['tenVoucher'] ?? '');
    _discountType = (d?['loaiGiam'] ?? 'PERCENT').toString();

    // Parse discount values nicely
    final gVal = d?['giamGia'];
    _discountValController = TextEditingController(
      text: gVal != null ? (num.tryParse(gVal.toString())?.toInt().toString() ?? '') : '',
    );
    final maxG = d?['giaTriGiamToiDa'];
    _maxDiscountController = TextEditingController(
      text: maxG != null ? (num.tryParse(maxG.toString())?.toInt().toString() ?? '') : '',
    );
    final minO = d?['dieuKienDonToiThieu'];
    _minOrderController = TextEditingController(
      text: minO != null ? (num.tryParse(minO.toString())?.toInt().toString() ?? '') : '',
    );
    final totC = d?['soLuongToiDa'];
    _totalCountController = TextEditingController(
      text: totC != null ? (num.tryParse(totC.toString())?.toInt().toString() ?? '') : '',
    );

    _isActive = (d?['trangThai'] ?? 'HOAT_DONG') == 'HOAT_DONG';

    if (d?['ngayBatDau'] != null) {
      _startDate = DateTime.tryParse(d!['ngayBatDau'].toString());
    }
    if (d?['ngayHetHan'] != null) {
      _endDate = DateTime.tryParse(d!['ngayHetHan'].toString());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _discountValController.dispose();
    _maxDiscountController.dispose();
    _minOrderController.dispose();
    _totalCountController.dispose();
    super.dispose();
  }

  void _generateRandomCode() {
    final rnd = Random();
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final part1 = 'KM${rnd.nextInt(90) + 10}';
    final part2 = '${letters[rnd.nextInt(letters.length)]}${letters[rnd.nextInt(letters.length)]}';
    final part3 = '${rnd.nextInt(900) + 100}';
    setState(() {
      _codeController.text = '$part1$part2$part3';
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? now.add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
      helpText: isStart ? 'CHỌN NGÀY BẮT ĐẦU' : 'CHỌN NGÀY HẾT HẠN',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFC6011),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFC6011),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endDate != null && _startDate != null && _endDate!.isBefore(_startDate!)) {
      CustomToast.showError(context, 'Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }

    setState(() => _isSubmitting = true);

    final input = <String, dynamic>{
      'maCode': _codeController.text.trim().toUpperCase(),
      'tenVoucher': _nameController.text.trim(),
      'loaiGiam': _discountType,
      'giamGia': double.tryParse(_discountValController.text) ?? 0,
      'dieuKienDonToiThieu': double.tryParse(_minOrderController.text) ?? 0,
      'soLuongToiDa': int.tryParse(_totalCountController.text) ?? 0,
      'trangThai': _isActive ? 'HOAT_DONG' : 'TAM_TAT',
      if (_discountType == 'PERCENT' && _maxDiscountController.text.isNotEmpty)
        'giaTriGiamToiDa': double.tryParse(_maxDiscountController.text),
      if (_startDate != null) 'ngayBatDau': _startDate!.toIso8601String(),
      if (_endDate != null) 'ngayHetHan': _endDate!.toIso8601String(),
    };

    await widget.onSave(input);

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialData != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFC6011),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditing ? 'Chỉnh sửa voucher' : 'Tạo voucher khuyến mãi mới',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TColor.primaryTextOf(context),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),

          // Form body scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Status Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Trạng thái phát hành',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: TColor.primaryTextOf(context),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isActive
                                      ? 'Đang bật (Khách hàng có thể nhìn thấy và áp dụng)'
                                      : 'Tạm dừng (Khách hàng không thể nhìn thấy)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: TColor.secondaryTextOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            activeThumbColor: const Color(0xFFFC6011),
                            activeTrackColor: const Color(0xFFFFDBCA),
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) => setState(() => _isActive = val),
                          ),
                        ],
                      ),
                    ),

                    // Mã Voucher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('MÃ VOUCHER (VIẾT HOA, KHÔNG DẤU) *'),
                        if (!isEditing)
                          InkWell(
                            onTap: _generateRandomCode,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFFC6011)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tạo tự động',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFC6011),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isEditing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              size: 16,
                              color: Color(0xFFFC6011),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _codeController.text,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _codeController.text));
                                CustomToast.showSuccess(context, 'Đã sao chép mã voucher');
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      TextFormField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        decoration: _inputDecoration(
                          'VD: GIAM20K, CHAOBANMOI',
                          prefixIcon: const Icon(
                            Icons.confirmation_number_outlined,
                            size: 18,
                            color: Color(0xFFFC6011),
                          ),
                          suffixText: 'A-Z',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mã voucher';
                          if (val.trim().length < 3) return 'Mã từ 3 ký tự trở lên';
                          return null;
                        },
                      ),
                    const SizedBox(height: 14),

                    // Tên Voucher
                    _buildLabel('TÊN CHƯƠNG TRÌNH VOUCHER *'),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: TColor.primaryTextOf(context)),
                      decoration: _inputDecoration('VD: Giảm 20% cho đơn từ 100k'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên voucher' : null,
                    ),
                    const SizedBox(height: 14),

                    // Loại giảm giá (Segmented Pill Buttons)
                    _buildLabel('LOẠI GIẢM GIÁ *'),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _discountType = 'PERCENT'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _discountType == 'PERCENT'
                                      ? const Color(0xFFFC6011)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _discountType == 'PERCENT'
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFC6011).withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_discountType == 'PERCENT') ...[
                                        const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        'Theo phần trăm (%)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _discountType == 'PERCENT'
                                              ? Colors.white
                                              : TColor.secondaryTextOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _discountType = 'FIXED'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _discountType == 'FIXED'
                                      ? const Color(0xFFFC6011)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _discountType == 'FIXED'
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFFC6011).withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_discountType == 'FIXED') ...[
                                        const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        'Cố định (đ)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _discountType == 'FIXED'
                                              ? Colors.white
                                              : TColor.secondaryTextOf(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Mức giảm & Giảm tối đa
                    if (_discountType == 'PERCENT')
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('MỨC GIẢM (%) *'),
                                TextFormField(
                                  controller: _discountValController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: TColor.primaryTextOf(context)),
                                  decoration: _inputDecoration('VD: 20', suffixText: '%'),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Bắt buộc';
                                    final numVal = double.tryParse(val);
                                    if (numVal == null || numVal <= 0) return 'Số dương';
                                    if (numVal > 100) return '<= 100%';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('GIẢM TỐI ĐA (Đ)'),
                                TextFormField(
                                  controller: _maxDiscountController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: TColor.primaryTextOf(context)),
                                  decoration: _inputDecoration('VD: 50000', suffixText: 'đ'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('SỐ TIỀN GIẢM (Đ) *'),
                          TextFormField(
                            controller: _discountValController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: TColor.primaryTextOf(context)),
                            decoration: _inputDecoration('VD: 30000', suffixText: 'đ'),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Bắt buộc';
                              final numVal = double.tryParse(val);
                              if (numVal == null || numVal <= 0) return 'Số dương';
                              return null;
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 14),

                    // Đơn tối thiểu & Tổng số lượt
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('ĐƠN TỐI THIỂU (Đ)'),
                              TextFormField(
                                controller: _minOrderController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: TColor.primaryTextOf(context)),
                                decoration: _inputDecoration('VD: 100000', suffixText: 'đ'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('SỐ LƯỢT DÙNG (0: VÔ HẠN)'),
                              TextFormField(
                                controller: _totalCountController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: TColor.primaryTextOf(context)),
                                decoration: _inputDecoration('VD: 50', suffixText: 'lượt'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Ngày bắt đầu & kết thúc
                    _buildLabel('THỜI HẠN ÁP DỤNG'),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(isStart: true),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: TColor.textfieldOf(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TỪ NGÀY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: TColor.secondaryTextOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Color(0xFFFC6011),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _startDate == null
                                              ? 'Hôm nay'
                                              : RestaurantFormatUtils.formatDateOnly(_startDate),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: TColor.primaryTextOf(context),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(isStart: false),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: TColor.textfieldOf(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ĐẾN NGÀY',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: TColor.secondaryTextOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 14,
                                        color: Color(0xFFFC6011),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _endDate == null
                                              ? 'Hết hạn'
                                              : RestaurantFormatUtils.formatDateOnly(_endDate),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _endDate == null
                                                ? TColor.placeholder
                                                : TColor.primaryTextOf(context),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (!isEditing) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 20,
                              color: Color(0xFFFC6011),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kích hoạt ngay sau khi tạo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: TColor.primaryTextOf(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Khách hàng tại quán có thể dùng ngay lập tức',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: TColor.secondaryTextOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              activeThumbColor: const Color(0xFFFC6011),
                              activeTrackColor: const Color(0xFFFFDBCA),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) => setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC6011),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0xFFFC6011).withOpacity(0.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isEditing ? Icons.check_rounded : Icons.add_rounded,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isEditing ? 'LƯU THAY ĐỔI' : 'TẠO VOUCHER',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
          color: TColor.secondaryTextOf(context),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    Widget? prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: TColor.placeholder),
      prefixIcon: prefixIcon,
      suffixText: suffixText,
      suffixStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: TColor.secondaryTextOf(context),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: TColor.borderOf(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: TColor.borderOf(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFC6011), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: TColor.textfieldOf(context),
    );
  }
}
