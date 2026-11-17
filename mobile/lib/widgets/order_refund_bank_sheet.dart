import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/order_service.dart';
import 'custom_toast.dart';

/// Modal bottom sheet cho phép khách hàng nhập/chọn thông tin tài khoản ngân hàng để nhận tiền hoàn qua VietQR
class OrderRefundBankSheet extends StatefulWidget {
  final int orderId;
  final int? refundId;
  final String? initialBank;
  final String? initialAccountNumber;
  final String? initialAccountName;
  final double? refundAmount;

  const OrderRefundBankSheet({
    super.key,
    required this.orderId,
    this.refundId,
    this.initialBank,
    this.initialAccountNumber,
    this.initialAccountName,
    this.refundAmount,
  });

  static Future<Map<String, String>?> show(
    BuildContext context, {
    required int orderId,
    int? refundId,
    String? initialBank,
    String? initialAccountNumber,
    String? initialAccountName,
    double? refundAmount,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderRefundBankSheet(
        orderId: orderId,
        refundId: refundId,
        initialBank: initialBank,
        initialAccountNumber: initialAccountNumber,
        initialAccountName: initialAccountName,
        refundAmount: refundAmount,
      ),
    );
  }

  @override
  State<OrderRefundBankSheet> createState() => _OrderRefundBankSheetState();
}

class _OrderRefundBankSheetState extends State<OrderRefundBankSheet> {
  static const List<Map<String, String>> popularBanks = [
    {'code': 'MB', 'name': 'MB Bank (Quân Đội)'},
    {'code': 'VCB', 'name': 'Vietcombank'},
    {'code': 'TCB', 'name': 'Techcombank'},
    {'code': 'VPB', 'name': 'VPBank'},
    {'code': 'ACB', 'name': 'ACB'},
    {'code': 'BIDV', 'name': 'BIDV'},
    {'code': 'VBA', 'name': 'Agribank'},
    {'code': 'TPB', 'name': 'TPBank'},
    {'code': 'STB', 'name': 'Sacombank'},
    {'code': 'CTG', 'name': 'VietinBank'},
    {'code': 'VIB', 'name': 'VIB'},
    {'code': 'SHB', 'name': 'SHB'},
    {'code': 'MSB', 'name': 'MSB'},
    {'code': 'OCB', 'name': 'OCB'},
    {'code': 'HDB', 'name': 'HDBank'},
  ];

  late String _selectedBank;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountNameController;
  bool _rememberInfo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBank = widget.initialBank ?? 'MB';
    if (!popularBanks.any((b) => b['code'] == _selectedBank)) {
      _selectedBank = 'MB';
    }

    _accountNumberController = TextEditingController(text: widget.initialAccountNumber ?? '');
    _accountNameController = TextEditingController(text: widget.initialAccountName ?? '');

    _loadSavedBankInfo();
  }

  Future<void> _loadSavedBankInfo() async {
    if (_accountNumberController.text.isNotEmpty && _accountNameController.text.isNotEmpty) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBank = prefs.getString('saved_refund_bank');
      final savedNum = prefs.getString('saved_refund_account_num');
      final savedName = prefs.getString('saved_refund_account_name');

      if (mounted) {
        setState(() {
          if (savedBank != null && popularBanks.any((b) => b['code'] == savedBank)) {
            _selectedBank = savedBank;
          }
          if (_accountNumberController.text.isEmpty && savedNum != null) {
            _accountNumberController.text = savedNum;
          }
          if (_accountNameController.text.isEmpty && savedName != null) {
            _accountNameController.text = savedName;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final accNum = _accountNumberController.text.trim();
    final accName = _accountNameController.text.trim().toUpperCase();

    if (accNum.isEmpty) {
      CustomToast.show(context, message: 'Vui lòng nhập số tài khoản ngân hàng', isError: true);
      return;
    }
    if (accName.isEmpty) {
      CustomToast.show(context, message: 'Vui lòng nhập tên chủ tài khoản', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_rememberInfo) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_refund_bank', _selectedBank);
        await prefs.setString('saved_refund_account_num', accNum);
        await prefs.setString('saved_refund_account_name', accName);
      }

      int? targetRefundId = widget.refundId;
      if (targetRefundId == null || targetRefundId <= 0) {
        // Query refund by orderId if not passed directly
        final refundData = await OrderService.getOrderRefund(widget.orderId);
        if (refundData != null) {
          targetRefundId = refundData['maHoanTien'] ?? refundData['id'];
        }
      }

      if (targetRefundId != null && targetRefundId > 0) {
        final res = await OrderService.updateRefundBankInfo(
          refundId: targetRefundId,
          bankName: _selectedBank,
          accountNumber: accNum,
          accountName: accName,
        );

        if (res['success'] != true) {
          if (!mounted) return;
          CustomToast.show(context, message: res['message'] ?? 'Không thể cập nhật thông tin ngân hàng', isError: true);
          setState(() => _isLoading = false);
          return;
        }
      }

      if (!mounted) return;
      CustomToast.show(context, message: 'Đã lưu thông tin tài khoản nhận tiền hoàn', isError: false);
      Navigator.pop(context, {
        'bankName': _selectedBank,
        'accountNumber': accNum,
        'accountName': accName,
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, message: 'Lỗi: $e', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2430) : Colors.white;
    final inputBg = isDark ? const Color(0xFF262E3D) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF333C4D) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFFC6011), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tài khoản nhận tiền hoàn',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Nhà hàng sẽ quét mã VietQR và hoàn tiền về STK này',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dropdown chọn ngân hàng
            Text(
              'Ngân hàng thụ hưởng',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  dropdownColor: cardBg,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: textSecondary),
                  items: popularBanks.map((b) {
                    return DropdownMenuItem<String>(
                      value: b['code'],
                      child: Text(
                        '${b['code']} - ${b['name']}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBank = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Số tài khoản
            Text(
              'Số tài khoản ngân hàng',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                hintText: 'Nhập số tài khoản ngân hàng...',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC6011), width: 1.5)),
              ),
            ),
            const SizedBox(height: 14),

            // Tên chủ tài khoản
            Text(
              'Tên chủ tài khoản (Viết in hoa, không dấu)',
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _accountNameController,
              textCapitalization: TextCapitalization.characters,
              onChanged: (val) {
                final upper = val.toUpperCase();
                if (upper != val) {
                  _accountNameController.value = _accountNameController.value.copyWith(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                }
              },
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: inputBg,
                hintText: 'VD: NGUYEN VAN A',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFC6011), width: 1.5)),
              ),
            ),
            const SizedBox(height: 10),

            // Ghi nhớ thông tin
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberInfo,
                    activeColor: const Color(0xFFFC6011),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) => setState(() => _rememberInfo = val ?? true),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Lưu thông tin tài khoản cho lần hoàn tiền sau',
                  style: GoogleFonts.outfit(fontSize: 12.5, color: textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Nút Lưu thông tin
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC6011),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Xác Nhận & Lưu Thông Tin',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
