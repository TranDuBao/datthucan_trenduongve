import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/color_extension.dart';
import '../../../services/bank_service.dart';
import '../../../widgets/custom_toast.dart';
import 'bank_picker_sheet.dart';

class StoreVietQRCard extends StatefulWidget {
  final String bankName;
  final String bankAcc;
  final String bankHolder;
  final String ownerName;
  final Function(String newBankName)? onUpdateBank;

  const StoreVietQRCard({
    super.key,
    required this.bankName,
    required this.bankAcc,
    required this.bankHolder,
    required this.ownerName,
    this.onUpdateBank,
  });

  @override
  State<StoreVietQRCard> createState() => _StoreVietQRCardState();
}

class _StoreVietQRCardState extends State<StoreVietQRCard> {
  String _bankLogo = '';

  @override
  void initState() {
    super.initState();
    _resolveLogo();
  }

  @override
  void didUpdateWidget(covariant StoreVietQRCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bankName != widget.bankName) {
      _resolveLogo();
    }
  }

  void _resolveLogo() async {
    final lower = widget.bankName.toLowerCase().trim();
    if (lower.isEmpty) return;
    final banks = await BankService.getVietQRBanks();
    final match = banks.firstWhere(
      (b) =>
          lower.contains(b.code.toLowerCase()) ||
          lower.contains(b.shortName.toLowerCase()),
      orElse: () => banks.first,
    );
    if (mounted && match.logo.isNotEmpty) {
      setState(() {
        _bankLogo = match.logo;
      });
    }
  }

  void _openBankPicker() {
    BankPickerSheet.show(
      context,
      currentBankName: widget.bankName,
      onSelect: (bank) {
        setState(() {
          _bankLogo = bank.logo;
        });
        if (widget.onUpdateBank != null) {
          widget.onUpdateBank!(bank.displayName);
        }
      },
    );
  }

  void _showVietQRDialog(BuildContext context) {
    if (widget.bankAcc.isEmpty) {
      CustomToast.showError(context, 'Vui lòng bổ sung số tài khoản ngân hàng trong hồ sơ để tạo mã VietQR');
      return;
    }

    // Clean bank code / extract code inside parentheses like (ICB)
    String cleanBank = 'icb';
    final regMatch = RegExp(r'\((.*?)\)').firstMatch(widget.bankName);
    if (regMatch != null && regMatch.group(1) != null) {
      cleanBank = regMatch.group(1)!.trim().toLowerCase();
    } else {
      cleanBank = widget.bankName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    }
    if (cleanBank.isEmpty) cleanBank = 'icb';
    final qrUrl =
        'https://img.vietqr.io/image/$cleanBank-${widget.bankAcc}-compact2.png?amount=0&addInfo=Thanh%20toan%20FoodRoute&accountName=${Uri.encodeComponent(widget.bankHolder)}';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: Color(0xFFFC6011), size: 24),
            SizedBox(width: 8),
            Text('Mã VietQR Để Bàn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  qrUrl,
                  height: 240,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Không thể tải mã QR trực tuyến', textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_bankLogo.isNotEmpty)
                  Container(
                    width: 30,
                    height: 20,
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Image.network(
                      _bankLogo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance_rounded,
                        size: 14,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                Flexible(
                  child: Text(
                    widget.bankName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.bankAcc} • ${widget.bankHolder}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC6011),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.bankAcc));
              CustomToast.showSuccess(ctx, 'Đã sao chép số tài khoản');
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Sao chép STK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Linked Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance_rounded, color: Color(0xFFFC6011), size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Tài khoản nhận tiền & VietQR',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                    SizedBox(width: 3),
                    Text(
                      'Đã liên kết',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Dark Bank Card (VietQR Pro card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E2430), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NGÂN HÀNG ĐỐI TÁC',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (_bankLogo.isNotEmpty)
                              Container(
                                width: 34,
                                height: 22,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Image.network(
                                  _bankLogo,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.account_balance_rounded,
                                    size: 14,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Color(0xFF0284C7), shape: BoxShape.circle),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              widget.bankName,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            if (widget.onUpdateBank != null) ...[
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: _openBankPicker,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF94A3B8)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'VIETQR PRO',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.qr_code_2, size: 14, color: Colors.white),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Tự động đối soát',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Account Number
                const Text(
                  'Số tài khoản thụ hưởng',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.bankAcc.isNotEmpty ? widget.bankAcc : '•••• •••• ••••',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (widget.bankAcc.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: widget.bankAcc));
                          CustomToast.showSuccess(context, 'Đã sao chép số tài khoản');
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Sao chép',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card Bottom Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CHỦ TÀI KHOẢN', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)),
                        const SizedBox(height: 2),
                        Text(
                          widget.bankHolder.isNotEmpty ? widget.bankHolder.toUpperCase() : 'CHƯA CẬP NHẬT',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CHỦ QUÁN ĐẠI DIỆN', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5)),
                        const SizedBox(height: 2),
                        Text(
                          widget.ownerName.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Button: Xem & Tải mã VietQR
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF7ED),
                foregroundColor: const Color(0xFFEA580C),
                side: const BorderSide(color: Color(0xFFFFEDD5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showVietQRDialog(context),
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: const Text(
                'Xem & Tải mã VietQR để bàn thanh toán',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
