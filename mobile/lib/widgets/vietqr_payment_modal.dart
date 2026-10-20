import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../common/color_extension.dart';
import '../common/globs.dart';
import 'custom_toast.dart';

class VietQRPaymentModal extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final VoidCallback onPaymentSuccess;

  const VietQRPaymentModal({
    super.key,
    required this.orderData,
    required this.onPaymentSuccess,
  });

  @override
  State<VietQRPaymentModal> createState() => _VietQRPaymentModalState();
}

class _VietQRPaymentModalState extends State<VietQRPaymentModal> {
  bool _isChecking = false;

  int get orderId => widget.orderData['orderId'] ?? widget.orderData['maDonHang'] ?? 0;
  Map<String, dynamic> get payment => widget.orderData['payment'] is Map
      ? Map<String, dynamic>.from(widget.orderData['payment'])
      : {};

  String get qrUrl => payment['qrUrl']?.toString() ?? '';
  String get bankName => payment['bankName']?.toString() ?? 'MBBank';
  String get accountNumber => payment['accountNumber']?.toString() ?? '';
  String get accountName => payment['accountName']?.toString() ?? '';
  String get transferContent => payment['transferContent']?.toString() ?? 'DH$orderId';
  double get totalAmount => double.tryParse((payment['soTien'] ?? widget.orderData['tongTien'] ?? 0).toString()) ?? 0.0;

  Future<void> _checkPaymentStatus() async {
    if (orderId <= 0) return;
    setState(() => _isChecking = true);

    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/payments/status/$orderId');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final status = body['data']?['trangThaiThanhToan'];
        if (status == 'THANH_TOAN_THANH_CONG') {
          if (mounted) {
            CustomToast.showSuccess(context, 'Xác nhận thanh toán thành công!');
            Navigator.pop(context);
            widget.onPaymentSuccess();
          }
          return;
        } else {
          if (mounted) {
            CustomToast.showInfo(
              context,
              'Hệ thống đang chờ giao dịch ngân hàng. Vui lòng thử lại sau vài giây hoặc kiểm tra với quán lúc nhận món.',
            );
          }
        }
      } else {
        if (mounted) {
          CustomToast.showError(context, 'Chưa thể xác minh trạng thái thanh toán lúc này');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showInfo(context, 'Chưa nhận được giao dịch. Bạn có thể thanh toán trực tiếp khi ghé lấy món.');
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    CustomToast.showSuccess(context, 'Đã sao chép $label');
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    final formattedAmount = totalAmount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    return Container(
      constraints: BoxConstraints(maxHeight: media.height * 0.88),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Thanh toán VietQR / PayOS",
                  style: TextStyle(
                    color: TColor.primaryTextOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onPaymentSuccess();
                  },
                  icon: Icon(Icons.close_rounded, color: TColor.primaryTextOf(context)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "Mã đơn hàng: #DH-$orderId • $formattedAmountđ",
              style: TextStyle(
                color: TColor.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),

            // QR Code Container
            if (qrUrl.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.network(
                  qrUrl,
                  width: media.width * 0.65,
                  height: media.width * 0.65,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: media.width * 0.65,
                      height: media.width * 0.65,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox(
                      width: media.width * 0.65,
                      height: media.width * 0.65,
                      child: const Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 14),

            // Bank details card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TColor.bgOf(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TColor.borderOf(context)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(context, "Ngân hàng", bankName, null),
                  const Divider(height: 12),
                  _buildDetailRow(
                    context,
                    "Số tài khoản",
                    accountNumber,
                    () => _copyToClipboard(accountNumber, "số tài khoản"),
                  ),
                  const Divider(height: 12),
                  _buildDetailRow(context, "Chủ tài khoản", accountName, null),
                  const Divider(height: 12),
                  _buildDetailRow(
                    context,
                    "Nội dung CK",
                    transferContent,
                    () => _copyToClipboard(transferContent, "nội dung chuyển khoản"),
                    isHighlight: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),
            Text(
              "⚠️ Vui lòng giữ chính xác nội dung chuyển khoản để hệ thống tự động xác nhận đơn.",
              style: TextStyle(
                color: TColor.secondaryTextOf(context),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Check button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkPaymentStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: _isChecking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Tôi đã chuyển khoản thành công",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Secondary option: Continue to order details
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onPaymentSuccess();
              },
              child: Text(
                "Xác nhận thanh toán sau tại quán",
                style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    VoidCallback? onCopy, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.secondaryTextOf(context),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: isHighlight ? TColor.primary : TColor.primaryTextOf(context),
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
            if (onCopy != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded, size: 16, color: TColor.primary),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
