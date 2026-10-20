import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
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
    final customerName = order['customerName'] ?? order['tenKhachHang'] ?? 'Khách vãng lai';
    final customerPhone = order['customerPhone'] ?? order['sdt'] ?? '';
    final note = order['ghiChu'] ?? '';
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
          const Divider(height: 1),

          // Content scrollable
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Khách hàng section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TColor.borderOf(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 18, color: Color(0xFF0284C7)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customerName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: TColor.primaryTextOf(context),
                              ),
                            ),
                          ),
                          if (customerPhone.isNotEmpty)
                            Text(
                              customerPhone,
                              style: TextStyle(
                                fontSize: 13,
                                color: TColor.secondaryTextOf(context),
                              ),
                            ),
                        ],
                      ),
                      if (note.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ghi chú: $note',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFF59E0B)),
                        ),
                      ],
                    ],
                  ),
                ),
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
                const SizedBox(height: 8),
                ...items.map((item) {
                  final name = item['tenMonAn'] ?? 'Món ăn';
                  final qty = item['soLuong'] ?? 1;
                  final price = item['donGia'] ?? item['gia'] ?? 0;
                  final lineTotal = price * qty;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC6011).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${qty}x',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFFC6011),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              color: TColor.primaryTextOf(context),
                            ),
                          ),
                        ),
                        Text(
                          RestaurantFormatUtils.formatVND(lineTotal),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TColor.primaryTextOf(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Thông tin thanh toán
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phương thức thanh toán:',
                      style: TextStyle(fontSize: 13, color: TColor.secondaryTextOf(context)),
                    ),
                    Text(
                      pMethod == 'TIEN_MAT' ? 'Tiền mặt khi nhận' : pMethod,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TColor.primaryTextOf(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trạng thái thanh toán:',
                      style: TextStyle(fontSize: 13, color: TColor.secondaryTextOf(context)),
                    ),
                    Text(
                      isPaid ? 'Đã thanh toán ✅' : 'Chưa thanh toán ⚠️',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng cộng:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: TColor.primaryTextOf(context)),
                    ),
                    Text(
                      RestaurantFormatUtils.formatVND(total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFC6011),
                      ),
                    ),
                  ],
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
