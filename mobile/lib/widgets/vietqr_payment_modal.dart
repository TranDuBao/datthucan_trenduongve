import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../common/color_extension.dart';
import '../common/format_utils.dart';
import '../common/globs.dart';
import '../common/locator.dart';
import '../services/order_service.dart';
import '../services/socket_service.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import 'custom_toast.dart';
import 'order_cancelled_modal.dart';

class VietQRPaymentModal extends StatefulWidget {
  final Map<String, dynamic> orderData;
  final void Function(Map<String, dynamic> verifiedOrderData) onPaymentSuccess;

  const VietQRPaymentModal({
    super.key,
    required this.orderData,
    required this.onPaymentSuccess,
  });

  @override
  State<VietQRPaymentModal> createState() => _VietQRPaymentModalState();
}

class _VietQRPaymentModalState extends State<VietQRPaymentModal>
    with WidgetsBindingObserver {
  bool _isChecking = false;
  bool _isSuccess = false;
  bool _isCancelling = false;
  Timer? _pollingTimer;

  int get orderId =>
      widget.orderData['orderId'] ?? widget.orderData['maDonHang'] ?? 0;
  Map<String, dynamic> get payment => widget.orderData['payment'] is Map
      ? Map<String, dynamic>.from(widget.orderData['payment'])
      : {};

  String get qrUrl {
    final raw = payment['qrUrl']?.toString() ?? '';
    if (raw.isNotEmpty) {
      // Auto sanitize e.g. "MBBank (MB)" or "MBBank%20(MB)" to "MB"
      final match = RegExp(r'/image/([^-\?]+)').firstMatch(raw);
      if (match != null) {
        final bankSegment = match.group(1) ?? '';
        final decoded = Uri.decodeComponent(bankSegment);
        final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(decoded);
        if (parenMatch != null) {
          final cleanBank = parenMatch.group(1)!.trim();
          return raw.replaceFirst(bankSegment, cleanBank);
        }
      }
      return raw;
    }
    // Fallback dynamic VietQR URL generation
    if (accountNumber.isNotEmpty) {
      final parenMatch = RegExp(r'\(([^)]+)\)').firstMatch(bankName);
      final cleanBank =
          parenMatch != null ? parenMatch.group(1)!.trim() : bankName.trim();
      return 'https://img.vietqr.io/image/$cleanBank-$accountNumber-compact2.png?amount=${totalAmount.toInt()}&addInfo=${Uri.encodeComponent(transferContent)}&accountName=${Uri.encodeComponent(accountName)}';
    }
    return '';
  }

  String get bankName => payment['bankName']?.toString() ?? 'MBBank';
  String get accountNumber => payment['accountNumber']?.toString() ?? '';
  String get accountName => payment['accountName']?.toString() ?? '';
  String get transferContent =>
      payment['transferContent']?.toString() ?? 'DH$orderId';
  double get totalAmount =>
      double.tryParse((payment['soTien'] ?? widget.orderData['tongTien'] ?? 0)
          .toString()) ??
      0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Tham gia phòng socket của đơn hàng và lắng nghe sự kiện thanh toán thành công
    try {
      locator<SocketService>().joinOrderRoom(orderId);
      locator<SocketService>().subscribe(
          'payment:confirmed', _onSocketPaymentConfirmed);
      locator<SocketService>().subscribe(
          'order:status_changed', _onSocketOrderStatusChanged);
    } catch (_) {}

    // 2. Polling định kỳ kiểm tra trạng thái thanh toán từ Backend mỗi 2 giây
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
      _checkPaymentStatusSilently();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    try {
      locator<SocketService>().leaveOrderRoom(orderId);
      locator<SocketService>().unsubscribe(
          'payment:confirmed', _onSocketPaymentConfirmed);
      locator<SocketService>().unsubscribe(
          'order:status_changed', _onSocketOrderStatusChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Khi khách hàng chuyển từ ứng dụng ngân hàng quay lại app đặt món -> kiểm tra ngay lập tức
    if (state == AppLifecycleState.resumed && !_isSuccess && mounted) {
      _checkPaymentStatusSilently();
    }
  }

  void _onSocketPaymentConfirmed(dynamic data) {
    if (!mounted || _isSuccess) return;
    final int? pOrderId = data is Map
        ? (data['orderId'] ?? data['id'] ?? data['maDonHang'])
        : null;
    if (pOrderId == null || pOrderId == orderId) {
      _handlePaymentSuccess(data is Map ? Map<String, dynamic>.from(data) : null);
    }
  }

  void _onSocketOrderStatusChanged(dynamic data) {
    if (!mounted || _isSuccess || _isCancelling) return;
    final int? pOrderId = data is Map
        ? (data['orderId'] ?? data['id'] ?? data['maDonHang'])
        : null;
    final status = data is Map ? (data['status'] ?? data['trangThai']) : null;
    if (pOrderId != null && pOrderId != orderId) return;

    if (status == 'DA_HUY' || status == 'CANCELLED') {
      _handleOrderCancelled();
      return;
    }

    if (status == 'CHO_XAC_NHAN' ||
        status == 'DA_XAC_NHAN' ||
        status == 'DANG_CHUAN_BI') {
      _handlePaymentSuccess(data is Map ? Map<String, dynamic>.from(data) : null);
    }
  }

  void _handleOrderCancelled() {
    if (_isSuccess || !mounted) return;
    _pollingTimer?.cancel();
    try {
      locator<SocketService>().leaveOrderRoom(orderId);
      locator<SocketService>().unsubscribe(
          'payment:confirmed', _onSocketPaymentConfirmed);
      locator<SocketService>().unsubscribe(
          'order:status_changed', _onSocketOrderStatusChanged);
    } catch (_) {}

    try {
      context.read<MapProvider>().cancelStopoverOrder();
    } catch (_) {}

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    OrderCancelledModal.show(context: context, orderId: orderId);
  }

  Future<void> _checkPaymentStatusSilently() async {
    if (orderId <= 0 || _isSuccess || !mounted || _isCancelling) return;
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.mainUrl}/api/v1/payments/status/$orderId');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final data = body['data'];
        final status = data?['trangThaiThanhToan'];
        final orderStatus = data?['trangThaiDonHang'] ?? data?['orderStatus'];

        // Ưu tiên kiểm tra thanh toán thành công trước
        if (status == 'THANH_TOAN_THANH_CONG' ||
            status == 'PAID' ||
            status == 'DA_THANH_TOAN' ||
            orderStatus == 'CHO_XAC_NHAN' ||
            orderStatus == 'DA_XAC_NHAN' ||
            orderStatus == 'DANG_CHUAN_BI') {
          _handlePaymentSuccess(data is Map ? Map<String, dynamic>.from(data) : null);
          return;
        }

        if (orderStatus == 'DA_HUY' || orderStatus == 'CANCELLED') {
          _handleOrderCancelled();
          return;
        }
      }
    } catch (_) {}
  }

  void _handlePaymentSuccess([Map<String, dynamic>? paymentDetails]) {
    if (_isSuccess || _isCancelling || !mounted) return;
    _isSuccess = true;
    _pollingTimer?.cancel();

    try {
      locator<SocketService>().leaveOrderRoom(orderId);
      locator<SocketService>().unsubscribe(
          'payment:confirmed', _onSocketPaymentConfirmed);
      locator<SocketService>().unsubscribe(
          'order:status_changed', _onSocketOrderStatusChanged);
    } catch (_) {}

    final updatedData = Map<String, dynamic>.from(widget.orderData);
    if (paymentDetails != null) {
      final existingPayment = updatedData['payment'] is Map
          ? Map<String, dynamic>.from(updatedData['payment'])
          : <String, dynamic>{};
      existingPayment.addAll(paymentDetails);
      updatedData['payment'] = existingPayment;
    }
    updatedData['status'] = 'CHO_XAC_NHAN';
    updatedData['trangThai'] = 'CHO_XAC_NHAN';

    // 1. Tự động đóng modal QR ngay lập tức
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // 2. Kích hoạt hiển thị modal thông báo thành công có animation dấu tích
    widget.onPaymentSuccess(updatedData);
  }

  /// Hỏi xác nhận hủy đơn khi người dùng muốn đóng modal mà chưa thanh toán
  Future<void> _handleCancelOrder() async {
    if (_isSuccess || _isCancelling) return;

    // Kiểm tra nhanh với PayOS xem tiền đã vào chưa trước khi hỏi hủy
    await _checkPaymentStatusSilently();
    if (_isSuccess || !mounted) return;

    final formattedAmount = totalAmount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nut dong (x) goc phai
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx, false),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),

              // Icon canh bao hinh tron cam nhat kem badge cham than do
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF3E6),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 36,
                        color: Color(0xFFFF5722),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tieu de
              Text(
                context.l10n.vietqrCancelDialogTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E2022),
                ),
              ),
              const SizedBox(height: 8),

              // Mo ta chi tiet don hang
              Text(
                context.l10n.vietqrCancelDialogDesc(orderId.toString(), formattedAmount),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 22),

              // Nut Tiep tuc thanh toan (cam noi bat)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.credit_card_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tiếp tục thanh toán',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Nut Xac nhan huy (xam nhe)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF6B7280),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    context.l10n.vietqrConfirmCancelBtn,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5A6275),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    // Kiểm tra thêm 1 lần phòng trường hợp khách vừa chuyển tiền xong
    await _checkPaymentStatusSilently();
    if (_isSuccess || !mounted) return;

    setState(() => _isCancelling = true);
    _pollingTimer?.cancel();

    // Hủy đăng ký listener ngay để không bị nhận nhầm socket hủy thành thành công
    try {
      locator<SocketService>().leaveOrderRoom(orderId);
      locator<SocketService>().unsubscribe(
          'payment:confirmed', _onSocketPaymentConfirmed);
      locator<SocketService>().unsubscribe(
          'order:status_changed', _onSocketOrderStatusChanged);
    } catch (_) {}

    // Hiển thị dialog đang hủy đơn để ngăn thao tác trùng
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFFC6011), strokeWidth: 3),
                SizedBox(height: 14),
                Text('Đang xử lý hủy đơn...', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      var res = await OrderService.cancelOrder(orderId, reason: 'Khách hủy thanh toán VietQR');
      final msg = res['message']?.toString() ?? '';
      if (msg.contains('thanh toán thành công') || msg.contains('chuyển khoản thành công')) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context); // Đóng loading dialog
        }
        _isCancelling = false;
        _handlePaymentSuccess();
        return;
      }
      if (res['success'] != true) {
        // Thử lại 1 lần nếu gặp lỗi kết nối chập chờn
        res = await OrderService.cancelOrder(orderId, reason: 'Khách hủy thanh toán VietQR');
      }
    } catch (_) {}

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Đóng loading dialog
    }

    try {
      if (mounted) {
        context.read<MapProvider>().cancelStopoverOrder();
      }
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context); // Đóng VietQRPaymentModal
      OrderCancelledModal.show(context: context, orderId: orderId);
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (orderId <= 0 || _isSuccess) return;
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
        if (status == 'THANH_TOAN_THANH_CONG' || status == 'PAID') {
          _handlePaymentSuccess();
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
          CustomToast.showError(
              context, 'Chưa thể xác minh trạng thái thanh toán lúc này');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showInfo(context,
            'Chưa nhận được giao dịch. Bạn có thể thanh toán trực tiếp khi ghé lấy món.');
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isCancelling && !_isSuccess) {
          _handleCancelOrder();
        }
      },
      child: Container(
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
          child: _buildQrPaymentView(context, media, formattedAmount),
        ),
      ),
    );
  }

  /// Màn hình hiển thị mã VietQR thanh toán
  Widget _buildQrPaymentView(
      BuildContext context, Size media, String formattedAmount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.vietqrPaymentTitle,
              style: TextStyle(
                color: TColor.primaryTextOf(context),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              onPressed: _isCancelling ? null : _handleCancelOrder,
              icon: Icon(Icons.close_rounded,
                  color: TColor.primaryTextOf(context)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.vietqrOrderCodeAmount(orderId.toString(), formattedAmount),
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
                    child: Icon(Icons.qr_code_2_rounded,
                        size: 80, color: Colors.grey),
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
              _buildDetailRow(context, context.l10n.vietqrBank, bankName, null),
              const Divider(height: 12),
              _buildDetailRow(
                context,
                context.l10n.vietqrAccountNumber,
                accountNumber,
                () => _copyToClipboard(accountNumber, "số tài khoản"),
              ),
              const Divider(height: 12),
              _buildDetailRow(context, context.l10n.vietqrAccountName, accountName, null),
              const Divider(height: 12),
              _buildDetailRow(
                context,
                context.l10n.vietqrTransferContent,
                transferContent,
                () => _copyToClipboard(transferContent, "nội dung chuyển khoản"),
                isHighlight: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, size: 13, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                context.l10n.vietqrExactMemoNotice,
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tự động nhận diện thanh toán (không cần nút bấm)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: TColor.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TColor.primary.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(TColor.primary),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.vietqrAutoDetecting,
                style: TextStyle(
                  color: TColor.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Hủy đơn hàng nếu không muốn thanh toán
        TextButton(
          onPressed: _isCancelling ? null : _handleCancelOrder,
          child: _isCancelling
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  context.l10n.vietqrCancelOrderBtn,
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
        ),
      ],
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
                color: isHighlight
                    ? TColor.primary
                    : TColor.primaryTextOf(context),
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
                  child:
                      Icon(Icons.copy_rounded, size: 16, color: TColor.primary),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
