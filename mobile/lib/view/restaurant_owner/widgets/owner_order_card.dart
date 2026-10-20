import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import 'restaurant_format_utils.dart';
import 'owner_order_detail_sheet.dart';

class OwnerOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String newStatus, {String? lyDo}) onUpdateStatus;

  const OwnerOrderCard({
    super.key,
    required this.order,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderId = order['maDonHang'] ?? order['id'] ?? 0;
    final status = (order['trangThai'] ?? order['status'] ?? '').toString();
    final badge = RestaurantFormatUtils.getStatusBadge(status);
    final customerName = order['customerName'] ?? order['tenKhachHang'] ?? 'Khách hàng';
    final customerPhone = order['customerPhone'] ?? order['sdt'] ?? '';
    final items = (order['items'] ?? order['chiTietDonHang'] ?? []) as List;
    final total = order['tongTien'] ?? order['tongGia'] ?? 0;
    final isPaid = (order['trangThaiThanhToan'] ?? '') == 'DA_THANH_TOAN';
    final dateStr = order['thoiGianDat'] ?? order['createdAt'];
    final isPending = status.toUpperCase() == 'CHO_XAC_NHAN';

    // Summary of foods: e.g. "2x Cơm tấm sườn, 1x Trà đào"
    final itemSummary = items.map((i) {
      final qty = i['soLuong'] ?? 1;
      final name = i['tenMonAn'] ?? 'Món';
      return '${qty}x $name';
    }).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? const Color(0xFFFC6011).withOpacity(0.5)
              : TColor.borderOf(context),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            OwnerOrderDetailSheet.show(
              context,
              order: order,
              onUpdateStatus: onUpdateStatus,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Order ID & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#DH-$orderId',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: TColor.primaryTextOf(context),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${RestaurantFormatUtils.formatRelativeTime(dateStr)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: TColor.secondaryTextOf(context),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badge['bg'],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: badge['border']),
                      ),
                      child: Text(
                        badge['text'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badge['fg'],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Customer Info
                Row(
                  children: [
                    Icon(Icons.person, size: 14, color: TColor.secondaryTextOf(context)),
                    const SizedBox(width: 6),
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TColor.primaryTextOf(context),
                      ),
                    ),
                    if (customerPhone.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '($customerPhone)',
                        style: TextStyle(
                          fontSize: 12,
                          color: TColor.secondaryTextOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Items list summary
                if (itemSummary.isNotEmpty)
                  Text(
                    itemSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: TColor.primaryTextOf(context).withOpacity(0.9),
                    ),
                  ),
                const SizedBox(height: 10),

                // Price and payment status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          RestaurantFormatUtils.formatVND(total),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFC6011),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPaid ? 'Đã thanh toán' : 'Chưa TT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPaid ? const Color(0xFF10B981) : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Quick action button in thumb-zone
                    _buildInlineActionButton(context, status),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInlineActionButton(BuildContext context, String status) {
    final st = status.toUpperCase();

    if (st == 'CHO_XAC_NHAN') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFC6011),
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () => onUpdateStatus('DANG_CHUAN_BI'),
        child: const Text('Nhận đơn ➔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    } else if (st == 'DA_XAC_NHAN' || st == 'DANG_CHUAN_BI') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () => onUpdateStatus('SAN_SANG'),
        child: const Text('Đã xong món ➔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    } else if (st == 'SAN_SANG') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          minimumSize: const Size(120, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        onPressed: () => onUpdateStatus('HOAN_TAT'),
        child: const Text('Đã lấy món ➔', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    return const Icon(Icons.chevron_right, color: Colors.grey);
  }
}
