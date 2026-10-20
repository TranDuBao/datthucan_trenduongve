import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import 'restaurant_format_utils.dart';

class VoucherCardWidget extends StatelessWidget {
  final Map<String, dynamic> voucher;
  final Function(bool val) onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VoucherCardWidget({
    super.key,
    required this.voucher,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = (voucher['maCode'] ?? '').toString();
    final name = (voucher['tenVoucher'] ?? '').toString();
    final discountType = (voucher['loaiGiam'] ?? 'PERCENT').toString();
    final discountVal = voucher['giamGia'] ?? 0;
    final maxDiscount = voucher['giaTriGiamToiDa'];
    final minOrder = voucher['dieuKienDonToiThieu'] ?? 0;
    final usedCount = voucher['soLuongDaSuDung'] ?? 0;
    final totalCount = voucher['soLuongToiDa'] ?? 0;
    final endDate = voucher['ngayHetHan'];
    final computedStatus = (voucher['computedStatus'] ?? voucher['trangThai'] ?? 'HOAT_DONG').toString();
    final isActive = computedStatus == 'HOAT_DONG';

    // Discount label
    String discountLabel = '';
    if (discountType == 'PERCENT') {
      discountLabel = 'Giảm $discountVal%';
      final maxNum = num.tryParse(maxDiscount.toString()) ?? 0;
      if (maxDiscount != null && maxNum > 0) {
        discountLabel += ' (tối đa ${RestaurantFormatUtils.formatVND(maxDiscount)})';
      }
    } else {
      discountLabel = 'Giảm ${RestaurantFormatUtils.formatVND(discountVal)}';
    }

    // Usage progress
    double progress = 0.0;
    String usageText = 'Đã dùng: $usedCount';
    if (totalCount > 0) {
      progress = (usedCount / totalCount).clamp(0.0, 1.0);
      usageText += '/$totalCount lượt (Còn ${totalCount - usedCount})';
    } else {
      usageText += ' lượt (Không giới hạn)';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? TColor.borderOf(context) : Colors.grey.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code Badge, Status Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6011).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFC6011).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFFFC6011)),
                      const SizedBox(width: 6),
                      Text(
                        code,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFC6011),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      isActive ? 'Đang bật' : 'Tạm dừng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: isActive,
                      activeColor: const Color(0xFFFC6011),
                      onChanged: onToggle,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Voucher Name & Discount description
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: TColor.primaryTextOf(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              discountLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0284C7),
              ),
            ),
            if (minOrder > 0) ...[
              const SizedBox(height: 2),
              Text(
                'Đơn tối thiểu: ${RestaurantFormatUtils.formatVND(minOrder)}',
                style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
              ),
            ],
            const SizedBox(height: 12),

            // Progress Bar
            if (totalCount > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? const Color(0xFF1E2430) : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? const Color(0xFFEF4444) : const Color(0xFFFC6011),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              usageText,
              style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context)),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Bottom Info: Dates + Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'HSD: ${RestaurantFormatUtils.formatRelativeTime(endDate)}',
                    style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context)),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                      onPressed: onEdit,
                      tooltip: 'Chỉnh sửa voucher',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                      onPressed: onDelete,
                      tooltip: 'Xóa voucher',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
