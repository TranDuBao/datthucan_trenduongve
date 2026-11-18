import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/color_extension.dart';
import '../../../widgets/custom_toast.dart';
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
    final isPaused = computedStatus == 'TAM_TAT';
    final isExpiredOrDone = computedStatus == 'HET_HAN' || computedStatus == 'HET_LUOT';

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

    // Status label & color
    String statusText = 'Đang bật';
    Color statusColor = const Color(0xFF059669);
    if (isPaused) {
      statusText = 'Tạm dừng';
      statusColor = const Color(0xFF64748B);
    } else if (computedStatus == 'HET_HAN') {
      statusText = 'Hết hạn';
      statusColor = const Color(0xFFDC2626);
    } else if (computedStatus == 'HET_LUOT') {
      statusText = 'Hết lượt';
      statusColor = const Color(0xFFD97706);
    }

    // Usage progress calculation
    double progress = 0.0;
    String usageText = 'Đã dùng: $usedCount lượt';
    String badgeText = '';
    Color badgeBg = const Color(0xFFECFDF5);
    Color badgeFg = const Color(0xFF059669);
    Color progressColor = const Color(0xFFFC6011);

    if (totalCount > 0) {
      progress = (usedCount / totalCount).clamp(0.0, 1.0);
      usageText = 'Đã dùng: $usedCount/$totalCount lượt';
      final remaining = totalCount - usedCount;
      if (usedCount >= totalCount) {
        badgeText = 'Đã nhận đủ 100%';
        badgeBg = const Color(0xFFF1F5F9);
        badgeFg = const Color(0xFF64748B);
        progressColor = const Color(0xFF94A3B8);
      } else if (remaining <= 5) {
        badgeText = 'Sắp hết (Còn $remaining)';
        badgeBg = const Color(0xFFFFF7ED);
        badgeFg = const Color(0xFFD97706);
        progressColor = const Color(0xFFEA580C);
      } else {
        badgeText = 'Còn $remaining lượt';
        badgeBg = const Color(0xFFECFDF5);
        badgeFg = const Color(0xFF059669);
        progressColor = const Color(0xFF0284C7);
      }
    } else {
      badgeText = 'Vô hạn lượt';
      badgeBg = const Color(0xFFF0FDF4);
      badgeFg = const Color(0xFF16A34A);
      progress = 0.0;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
              : Colors.grey.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code Pill + Copy, Status Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Code Pill
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        if (code.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: code));
                          CustomToast.showSuccess(context, 'Đã sao chép mã $code');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A1C14) : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFED7AA),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.confirmation_number_outlined,
                              size: 14,
                              color: Color(0xFFFC6011),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              code,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2410C),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: Color(0xFF9A3412),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Status & Switch
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: isActive,
                          activeThumbColor: const Color(0xFFFC6011),
                          activeTrackColor: const Color(0xFFFFDBCA),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          onChanged: onToggle,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Voucher Name
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
                const SizedBox(height: 6),

                // Discount & Condition Row
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      discountLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    if (minOrder > 0)
                      Text(
                        'Đơn tối thiểu: ${RestaurantFormatUtils.formatVND(minOrder)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: TColor.secondaryTextOf(context),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Usage stats & Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      usageText,
                      style: TextStyle(
                        fontSize: 12,
                        color: TColor.secondaryTextOf(context),
                      ),
                    ),
                    if (badgeText.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: badgeFg,
                          ),
                        ),
                      ),
                  ],
                ),
                if (totalCount > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 6,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Divider line (soft & clean)
                Container(
                  height: 1,
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 8),

                // Bottom row: Expiry date + Action icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: TColor.secondaryTextOf(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'HSD: ${RestaurantFormatUtils.formatVoucherExpiry(endDate)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: TColor.secondaryTextOf(context),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isExpiredOrDone) ...[
                          InkWell(
                            onTap: onEdit,
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.replay_rounded, size: 14, color: Color(0xFFFC6011)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Tái phát hành',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFC6011),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                          onPressed: onEdit,
                          tooltip: 'Chỉnh sửa voucher',
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(6),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
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
        ),
      ),
    );
  }
}
