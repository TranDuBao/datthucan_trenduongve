import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../common/color_extension.dart';
import '../../common_widget/smart_network_image.dart';
import '../../models/reservation_model.dart';

class ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const ReservationCard({
    super.key,
    required this.reservation,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('HH:mm • dd/MM/yyyy').format(reservation.thoiGianBatDau.toLocal());
    final res = reservation.cuaHang;
    final storeName = res?.tenQuan ?? 'Quán ăn';
    final storeAddress = res?.diaChi ?? '';
    final storeImg = res?.img ?? '';
    final tableName = reservation.ban?.tenBan ?? 'Quán tự xếp bàn';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColor.borderOf(context)),
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: ID + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF232836) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#DB${reservation.maDatBan}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: TColor.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: reservation.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: reservation.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reservation.statusTitle,
                            style: TextStyle(
                              color: reservation.statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Middle row: Store info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 58,
                        height: 58,
                        child: storeImg.isNotEmpty
                            ? SmartNetworkImage(
                                imageUrl: storeImg,
                                width: 58,
                                height: 58,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: TColor.primary.withValues(alpha: 0.1),
                                child: Icon(Icons.restaurant_rounded, color: TColor.primary, size: 28),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: TColor.primaryTextOf(context),
                            ),
                          ),
                          if (storeAddress.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              storeAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: TColor.secondaryTextOf(context),
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_filled_rounded, size: 14, color: TColor.primary),
                              const SizedBox(width: 5),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TColor.primaryTextOf(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Bottom row: Table & guests info + Action
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E3547) : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.table_restaurant_rounded, size: 14, color: TColor.primary),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                tableName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TColor.primaryTextOf(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(width: 1, height: 12, color: TColor.borderOf(context)),
                            const SizedBox(width: 8),
                            Icon(Icons.people_outline_rounded, size: 14, color: TColor.primary),
                            const SizedBox(width: 5),
                            Text(
                              '${reservation.soNguoi} khách',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TColor.primaryTextOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (reservation.canCancel && onCancel != null)
                        GestureDetector(
                          onTap: onCancel,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hủy đặt',
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                      else
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: TColor.secondaryTextOf(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
