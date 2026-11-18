import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
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
    final customerName = order['customerName'] ?? order['tenKhachHang'] ?? order['khachHang']?['hoTen'] ?? 'Khách hàng';
    final customerPhone = (order['customerPhone'] ?? order['sdtKhachHang'] ?? order['sdt'] ?? order['khachHang']?['sdt'] ?? '').toString().trim();
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

    // Primary food item image
    final firstItem = items.isNotEmpty ? (items[0] is Map ? items[0] : {}) : {};
    final String firstItemImg = (firstItem['img'] ?? firstItem['image'] ?? firstItem['hinhAnh'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? const Color(0xFFFC6011).withValues(alpha: 0.5)
              : TColor.borderOf(context),
          width: isPending ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                          '#$orderId',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
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
                const SizedBox(height: 12),

                // Order Content Row: Food Image + Customer & Items Summary
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Food thumbnail image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF28303D) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TColor.borderOf(context)),
                        ),
                        child: firstItemImg.isNotEmpty
                            ? Image.network(
                                SVKey.formatImageUrl(firstItemImg),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.fastfood_rounded,
                                  size: 26,
                                  color: const Color(0xFFFC6011).withValues(alpha: 0.6),
                                ),
                              )
                            : Icon(
                                Icons.fastfood_rounded,
                                size: 26,
                                color: const Color(0xFFFC6011).withValues(alpha: 0.6),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Customer & Items description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer info
                          Row(
                            children: [
                              Icon(Icons.person, size: 14, color: TColor.secondaryTextOf(context)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  customerPhone.isNotEmpty ? '$customerName ($customerPhone)' : customerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: TColor.primaryTextOf(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Items summary
                          if (itemSummary.isNotEmpty)
                            Text(
                              itemSummary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: TColor.primaryTextOf(context).withValues(alpha: 0.85),
                              ),
                            ),
                          if (items.length > 1) ...[
                            const SizedBox(height: 2),
                            Text(
                              '+${items.length - 1} món khác',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TColor.secondaryTextOf(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
