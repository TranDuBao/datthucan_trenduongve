import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/order_item_customization_tags.dart';
import 'restaurant_format_utils.dart';

class OwnerOrderDetailSheet extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(String newStatus, {String? lyDo}) onUpdateStatus;

  const OwnerOrderDetailSheet({
    super.key,
    required this.order,
    required this.onUpdateStatus,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> order,
    required Function(String newStatus, {String? lyDo}) onUpdateStatus,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OwnerOrderDetailSheet(
        order: order,
        onUpdateStatus: onUpdateStatus,
      ),
    );
  }

  @override
  State<OwnerOrderDetailSheet> createState() => _OwnerOrderDetailSheetState();
}

class _OwnerOrderDetailSheetState extends State<OwnerOrderDetailSheet> {
  bool _isSubmitting = false;

  void _confirmCancelOrder() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Từ chối / Hủy đơn hàng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng nhập lý do từ chối để thông báo cho khách hàng:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'VD: Quán hết món, đóng cửa đột xuất...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSubmitting = true);
              await widget.onUpdateStatus('DA_HUY', lyDo: reasonController.text.trim());
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;
    final orderId = order['maDonHang'] ?? order['id'] ?? 0;
    final status = (order['trangThai'] ?? order['status'] ?? '').toString();
    final badge = RestaurantFormatUtils.getStatusBadge(status);
    final customerName = order['customerName'] ?? order['tenKhachHang'] ?? order['khachHang']?['hoTen'] ?? 'Khách vãng lai';
    final customerPhone = (order['customerPhone'] ?? order['sdtKhachHang'] ?? order['sdt'] ?? order['khachHang']?['sdt'] ?? '').toString().trim();
    final customerEmail = (order['customerEmail'] ?? order['emailKhachHang'] ?? order['email'] ?? order['khachHang']?['email'] ?? '').toString().trim();
    final orderDate = order['thoiGianDat'] ?? order['thoigiandat'] ?? order['createdAt'];
    final pickupDate = order['thoiGianHenNhan'] ?? order['thoigianhennhan'] ?? order['thoiGianGheLay'];
    final note = (order['ghiChu'] ?? order['ghichu'] ?? '').toString().trim();
    final items = (order['items'] ?? order['chiTietDonHang'] ?? []) as List;
    final total = order['tongTien'] ?? order['tongGia'] ?? 0;
    final pMethod = order['phuongThucThanhToan'] ?? 'TIEN_MAT';
    final isPaid = (order['trangThaiThanhToan'] ?? '') == 'DA_THANH_TOAN';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chi tiết đơn #$orderId',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TColor.primaryTextOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      RestaurantFormatUtils.formatDateTime(order['thoiGianDat'] ?? order['createdAt']),
                      style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badge['bg'],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badge['border']),
                  ),
                  child: Text(
                    badge['text'],
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: badge['fg']),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Content scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── 1. Khách hàng section ──────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TColor.borderOf(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Thông tin khách hàng mua',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 95,
                            child: Text(
                              'Họ và tên:',
                              style: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              customerName,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: TColor.primaryTextOf(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 95,
                            child: Text(
                              'Số điện thoại:',
                              style: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                            ),
                          ),
                          Expanded(
                            child: customerPhone.isNotEmpty
                                ? Row(
                                    children: [
                                      Text(
                                        customerPhone,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      InkWell(
                                        onTap: () async {
                                          final uri = Uri.parse('tel:$customerPhone');
                                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.phone_in_talk_rounded, size: 13, color: Color(0xFF10B981)),
                                              SizedBox(width: 3),
                                              Text(
                                                'Gọi',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: customerPhone));
                                          CustomToast.showSuccess(context, 'Đã chép SĐT: $customerPhone');
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(Icons.copy_rounded, size: 14, color: TColor.secondaryTextOf(context)),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Chưa cập nhật SĐT',
                                    style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: TColor.secondaryTextOf(context)),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 95,
                            child: Text(
                              'Email:',
                              style: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              customerEmail.isNotEmpty ? customerEmail : 'Chưa cập nhật email',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: customerEmail.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                fontStyle: customerEmail.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                color: customerEmail.isNotEmpty ? TColor.primaryTextOf(context) : TColor.secondaryTextOf(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 2. Thời gian & Lộ trình ────────────────────────
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TColor.borderOf(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFFFC6011)),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Thời gian đơn hàng & Ghé lấy',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Thời gian đặt hàng:',
                            style: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                          ),
                          Text(
                            RestaurantFormatUtils.formatDateTime(orderDate),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: TColor.primaryTextOf(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Thời gian hẹn ghé lấy:',
                            style: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              (pickupDate != null && pickupDate.toString().isNotEmpty)
                                  ? RestaurantFormatUtils.formatDateTime(pickupDate)
                                  : 'Ghé lấy khi sẵn sàng (~15-20p)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFC6011),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hình thức nhận món:',
                            style: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                          ),
                          Text(
                            'Đặt trước ghé lấy trên lộ trình',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 3. Ghi chú chung của khách hàng ────────────────
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: note.isNotEmpty
                        ? (isDark ? const Color(0xFF2C2415) : const Color(0xFFFFFBEB))
                        : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: note.isNotEmpty
                          ? (isDark ? const Color(0xFF785415) : const Color(0xFFFDE68A))
                          : TColor.borderOf(context),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: note.isNotEmpty ? const Color(0xFFD97706) : TColor.secondaryTextOf(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ghi chú từ khách hàng:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: note.isNotEmpty
                                    ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309))
                                    : TColor.secondaryTextOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              note.isNotEmpty ? note : 'Không có yêu cầu ghi chú đặc biệt cho đơn này.',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontStyle: note.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                                fontWeight: note.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                color: note.isNotEmpty
                                    ? (isDark ? Colors.white : const Color(0xFF78350F))
                                    : TColor.secondaryTextOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (status.toUpperCase() == 'DA_HUY') ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFEF4444)),
                            const SizedBox(width: 8),
                            const Text(
                              'Đơn hàng đã hủy',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                        if (order['lyDoHuy'] != null && order['lyDoHuy'].toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Lý do: ${order['lyDoHuy']}',
                            style: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                          ),
                        ],
                        if (order['refundInfo'] != null || order['refund'] != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Số tiền hoàn trả:', style: TextStyle(fontSize: 13)),
                              Text(
                                RestaurantFormatUtils.formatVND(
                                  (order['refundInfo'] ?? order['refund'])['soTienHoan'] ?? order['tongTien'] ?? 0,
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFDC2626)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trạng thái hoàn:', style: TextStyle(fontSize: 13)),
                              Text(
                                (order['refundInfo'] ?? order['refund'])['trangThaiHoanTien'] == 'HOAN_TIEN_THANH_CONG'
                                    ? '✓ Đã hoàn tiền'
                                    : ((order['refundInfo'] ?? order['refund'])['soTaiKhoanNhan'] != null
                                        ? '⏳ Chờ chuyển khoản'
                                        : '⏳ Chờ khách nhập STK'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: (order['refundInfo'] ?? order['refund'])['trangThaiHoanTien'] == 'HOAN_TIEN_THANH_CONG'
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFEA580C),
                                ),
                              ),
                            ],
                          ),
                          if ((order['refundInfo'] ?? order['refund'])['soTaiKhoanNhan'] != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'STK: ${(order['refundInfo'] ?? order['refund'])['nganHangNhan'] ?? 'Ngân hàng'} • ${(order['refundInfo'] ?? order['refund'])['soTaiKhoanNhan']} (${(order['refundInfo'] ?? order['refund'])['tenChuTaiKhoanNhan'] ?? ''})',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Danh sách món
                Text(
                  'Món ăn đã đặt (${items.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
                const SizedBox(height: 10),
                ...items.map((item) {
                  final itemMap = item is Map ? item : {};
                  final custom = OrderItemCustomizationParser.parse(itemMap);
                  final qty = itemMap['soLuong'] ?? 1;
                  final price = itemMap['donGia'] ?? itemMap['gia'] ?? 0;
                  final lineTotal = price * qty;
                  final itemImg = (itemMap['img'] ?? itemMap['image'] ?? itemMap['hinhAnh'] ?? '').toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TColor.borderOf(context)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Food Image Thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF28303D) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: itemImg.isNotEmpty
                                ? Image.network(
                                    SVKey.formatImageUrl(itemImg),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Icon(Icons.fastfood_rounded, size: 24, color: const Color(0xFFFC6011).withValues(alpha: 0.6)),
                                    ),
                                  )
                                : Center(
                                    child: Icon(Icons.fastfood_rounded, size: 24, color: const Color(0xFFFC6011).withValues(alpha: 0.6)),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Quantity Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${qty}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFFFC6011),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Name & Customization
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                custom.cleanName,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: TColor.primaryTextOf(context),
                                ),
                              ),
                              OrderItemCustomizationTags(
                                customization: custom,
                                showDefaultIfEmpty: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Price
                        Text(
                          RestaurantFormatUtils.formatVND(lineTotal),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: TColor.primaryTextOf(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),

                // Thông tin thanh toán (Giao diện thẻ bo tròn hiện đại, không dùng đường gạch ngang)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: TColor.borderOf(context)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Phương thức thanh toán:',
                            style: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                          ),
                          Text(
                            (pMethod == 'TIEN_MAT' || pMethod == 'COD' || pMethod == 'PAYOS' || pMethod == 'VIETQR') ? 'VietQR / PayOS' : pMethod,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: TColor.primaryTextOf(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Trạng thái thanh toán:',
                            style: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
                          ),
                          Text(
                            isPaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng cộng:',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TColor.primaryTextOf(context)),
                          ),
                          Text(
                            RestaurantFormatUtils.formatVND(total),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFC6011),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: TColor.cardOf(context),
              border: Border(top: BorderSide(color: TColor.borderOf(context))),
            ),
            child: SafeArea(
              top: false,
              child: _buildActionButtons(status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    if (_isSubmitting) {
      return const Center(child: CircularProgressIndicator());
    }

    final st = status.toUpperCase();

    if (st == 'CHO_XAC_NHAN') {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _confirmCancelOrder,
              child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC6011),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                setState(() => _isSubmitting = true);
                await widget.onUpdateStatus('DANG_CHUAN_BI');
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Nhận & Chế biến ➔', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else if (st == 'DA_XAC_NHAN' || st == 'DANG_CHUAN_BI') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            setState(() => _isSubmitting = true);
            await widget.onUpdateStatus('SAN_SANG');
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Báo món đã sẵn sàng ➔', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    } else if (st == 'SAN_SANG') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            setState(() => _isSubmitting = true);
            await widget.onUpdateStatus('HOAN_TAT');
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Xác nhận khách đã lấy ➔', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
    );
  }
}
