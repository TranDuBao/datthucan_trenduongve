import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../common/format_utils.dart';
import '../providers/map_provider.dart';
import 'order_enjoy_meal_modal.dart';
import 'route_info_card.dart';

class ActiveStopoverOrderCard extends StatelessWidget {
  const ActiveStopoverOrderCard({super.key});

  void _showOrderDetailsSheet(
    BuildContext context, {
    required Map<String, dynamic> order,
    required MapProvider provider,
    required bool has2Legs,
    required dynamic stopover,
  }) {
    final orderCode = order['maDonHang'] ?? order['id'] ?? '---';
    final storeName = order['tenQuan'] ?? order['restaurantName'] ?? 'Quán ghé lấy';
    final address = order['diaChi'] ?? order['restaurantAddress'] ?? 'Địa chỉ tự đến lấy';
    final status = order['trangThai'] ?? order['status'] ?? 'Đã xác nhận';
    final pickupTime = order['thoiGianHenNhan'] ?? order['pickupTime'] ?? 'Ghé lấy ngay';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFC6011),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.l10n.stopoverDetailsTitle,
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      context.l10n.stopoverOrderCode(orderCode.toString()),
                      style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  storeName,
                  style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (has2Legs) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.stopoverLeg1ToStore, style: GoogleFonts.outfit(color: const Color(0xFFFC6011), fontSize: 10.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('${stopover.legs[0].distance} • ${stopover.legs[0].duration}', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 12.5, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.stopoverLeg2ToDestination, style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('${stopover.legs[1].distance} • ${stopover.legs[1].duration}', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 12.5, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.stopoverPickupScheduled(pickupTime.toString()),
                      style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: GoogleFonts.outfit(color: const Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          provider.clearActiveStopoverOrder();
                          provider.clearStopover();
                        },
                        child: Text(context.l10n.stopoverReturnOriginalRoute, style: GoogleFonts.outfit(color: const Color(0xFF475467), fontSize: 12.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          provider.markOrderPickedUp(true);
                          OrderEnjoyMealModal.show(
                            context: context,
                            storeName: storeName,
                            orderCode: orderCode.toString(),
                            onComplete: () => provider.finishStopoverOrder(),
                          );
                        },
                        child: Text(
                          provider.isOrderPickedUp ? context.l10n.stopoverCompleteTrip : context.l10n.stopoverPickedUpContinue,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MapProvider>();
    final order = provider.activeStopoverOrder;
    if (order == null) return const SizedBox.shrink();

    final orderCode = order['maDonHang'] ?? order['id'] ?? '---';
    final storeName = order['tenQuan'] ?? order['restaurantName'] ?? 'Quán ghé lấy';
    final double? storeLat = (order['lat'] as num?)?.toDouble();
    final double? storeLng = (order['lng'] as num?)?.toDouble();

    final stopover = provider.stopoverRoute;
    final bool has2Legs = stopover != null && stopover.legs.length >= 2;
    final activeRoute = stopover ?? provider.currentRoute;

    final isPickedUp = provider.isOrderPickedUp;
    final leg1Info = has2Legs
        ? '${stopover.legs[0].distance} • ${stopover.legs[0].duration}'
        : (activeRoute?.totalDistance ?? '');

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPickedUp ? const Color(0xFF10B981) : const Color(0xFFFC6011),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPickedUp ? const Color(0xFF10B981) : const Color(0xFFFC6011)).withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── HÀNG 1: THÔNG TIN GỌN GÀNG CỦA CHẶNG 1 ĐẾN QUÁN ──
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isPickedUp
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : const Color(0xFFFC6011).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPickedUp ? Icons.check_circle_rounded : Icons.navigation_rounded,
                  color: isPickedUp ? const Color(0xFF10B981) : const Color(0xFFFC6011),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 13.5, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      isPickedUp
                          ? context.l10n.stopoverPickedUpEnjoy
                          : context.l10n.stopoverToStoreDistance(leg1Info),
                      style: GoogleFonts.outfit(
                        color: isPickedUp ? const Color(0xFF10B981) : const Color(0xFFFC6011),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Nút xem chi tiết đơn hàng dạng pop-up
              GestureDetector(
                onTap: () => _showOrderDetailsSheet(
                  context,
                  order: order,
                  provider: provider,
                  has2Legs: has2Legs,
                  stopover: stopover,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$orderCode',
                        style: GoogleFonts.outfit(color: const Color(0xFF475467), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── HÀNG 2: 2 NÚT HÀNH ĐỘNG ──
          if (!isPickedUp)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6011),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (storeLat != null && storeLng != null) {
                        provider.mapController.move(LatLng(storeLat, storeLng), 16);
                      }
                      if (activeRoute != null) {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => DirectionStepsList(route: activeRoute),
                        );
                      }
                    },
                    icon: const Icon(Icons.turn_right_rounded, color: Colors.white, size: 16),
                    label: Text(
                      context.l10n.stopoverViewDirections,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      provider.markOrderPickedUp(true);
                      OrderEnjoyMealModal.show(
                        context: context,
                        storeName: storeName,
                        orderCode: orderCode.toString(),
                        onComplete: () => provider.finishStopoverOrder(),
                      );
                    },
                    icon: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                    label: Text(
                      context.l10n.stopoverMarkPickedUp,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6011),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      provider.markOrderPickedUp(false);
                      if (storeLat != null && storeLng != null) {
                        provider.mapController.move(LatLng(storeLat, storeLng), 16);
                      }
                    },
                    icon: const Icon(Icons.replay_rounded, color: Colors.white, size: 16),
                    label: Text(
                      context.l10n.stopoverNavigateAgain,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      OrderEnjoyMealModal.show(
                        context: context,
                        storeName: storeName,
                        orderCode: orderCode.toString(),
                        buttonText: context.l10n.stopoverComplete,
                        onComplete: () {
                          provider.clearAll();
                        },
                      );
                    },
                    icon: const Icon(Icons.flag_rounded, color: Colors.white, size: 15),
                    label: Text(
                      context.l10n.stopoverComplete,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
