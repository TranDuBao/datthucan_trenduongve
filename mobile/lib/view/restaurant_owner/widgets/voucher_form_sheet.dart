import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../widgets/custom_toast.dart';

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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _codeController = TextEditingController(text: d?['maCode'] ?? '');
    _nameController = TextEditingController(text: d?['tenVoucher'] ?? '');
    _discountType = (d?['loaiGiam'] ?? 'PERCENT').toString();
    _discountValController = TextEditingController(text: d?['giamGia']?.toString() ?? '');
    _maxDiscountController = TextEditingController(text: d?['giaTriGiamToiDa']?.toString() ?? '');
    _minOrderController = TextEditingController(text: d?['dieuKienDonToiThieu']?.toString() ?? '');
    _totalCountController = TextEditingController(text: d?['soLuongToiDa']?.toString() ?? '');

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

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? now.add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
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
    final isEditing = widget.initialData != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
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
                Text(
                  isEditing ? 'Chỉnh sửa voucher' : 'Tạo voucher khuyến mãi mới',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Form body scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mã Voucher
                    _buildLabel('Mã voucher (Viết hoa, không dấu) *'),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      enabled: !isEditing, // Không cho sửa mã code khi đang edit
                      style: TextStyle(color: TColor.primaryTextOf(context)),
                      decoration: _inputDecoration('VD: GIAM20K, CHAOBANMOI'),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mã voucher';
                        if (val.trim().length < 3) return 'Mã từ 3 ký tự trở lên';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Tên Voucher
                    _buildLabel('Tên chương trình voucher *'),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: TColor.primaryTextOf(context)),
                      decoration: _inputDecoration('VD: Giảm 20% cho đơn từ 100k'),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tên voucher' : null,
                    ),
                    const SizedBox(height: 14),

                    // Loại giảm giá (Segmented switch)
                    _buildLabel('Loại giảm giá *'),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Theo phần trăm (%)')),
                            selected: _discountType == 'PERCENT',
                            selectedColor: const Color(0xFFFC6011),
                            labelStyle: TextStyle(
                              color: _discountType == 'PERCENT' ? Colors.white : TColor.primaryTextOf(context),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setState(() => _discountType = 'PERCENT'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Cố định (₫)')),
                            selected: _discountType == 'FIXED',
                            selectedColor: const Color(0xFFFC6011),
                            labelStyle: TextStyle(
                              color: _discountType == 'FIXED' ? Colors.white : TColor.primaryTextOf(context),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (_) => setState(() => _discountType = 'FIXED'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Mức giảm & Giảm tối đa
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(_discountType == 'PERCENT' ? 'Mức giảm (%) *' : 'Số tiền giảm (₫) *'),
                              TextFormField(
                                controller: _discountValController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: TColor.primaryTextOf(context)),
                                decoration: _inputDecoration(_discountType == 'PERCENT' ? 'VD: 20' : 'VD: 30000'),
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  final numVal = double.tryParse(val);
                                  if (numVal == null || numVal <= 0) return 'Số dương';
                                  if (_discountType == 'PERCENT' && numVal > 100) return '<= 100%';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        if (_discountType == 'PERCENT') ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Giảm tối đa (₫)'),
                                TextFormField(
                                  controller: _maxDiscountController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: TColor.primaryTextOf(context)),
                                  decoration: _inputDecoration('VD: 50000'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Đơn tối thiểu & Tổng số lượt
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Đơn tối thiểu (₫)'),
                              TextFormField(
                                controller: _minOrderController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: TColor.primaryTextOf(context)),
                                decoration: _inputDecoration('VD: 100000'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Số lượt dùng (0: vô hạn)'),
                              TextFormField(
                                controller: _totalCountController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: TColor.primaryTextOf(context)),
                                decoration: _inputDecoration('VD: 50'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Ngày bắt đầu & kết thúc
                    _buildLabel('Thời hạn áp dụng'),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 14),
                            label: Text(
                              _startDate == null ? 'Bắt đầu' : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _pickDate(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_busy, size: 14),
                            label: Text(
                              _endDate == null ? 'Hết hạn' : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onPressed: () => _pickDate(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFC6011),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isEditing ? 'LƯU THAY ĐỔI' : 'TẠO VOUCHER',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: TColor.secondaryTextOf(context),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: TColor.placeholder),
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
