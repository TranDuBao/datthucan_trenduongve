import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../common_widget/smart_network_image.dart';
import '../../models/reservation_model.dart';
import '../../providers/map_provider.dart';
import '../../services/order_route_storage.dart';
import '../../services/category_service.dart';
import '../../widgets/custom_toast.dart';
import '../main_tabview/main_tabview.dart';

class ReservationCard extends StatefulWidget {
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
  State<ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends State<ReservationCard> {
  OrderRouteInfo? _routeInfo;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    final info = await OrderRouteStorage.getReservationRoute(widget.reservation.maDatBan);
    if (mounted) {
      setState(() {
        _routeInfo = info;
      });
    }
  }

  Future<void> _startNavigation(BuildContext context) async {
    final res = widget.reservation.cuaHang;
    final storeName = res?.tenQuan ?? 'Quán ăn';
    final storeAddress = res?.diaChi ?? '';
    double? sLat = res?.lat;
    double? sLng = res?.lng;

    if (sLat == null || sLng == null) {
      try {
        final stores = await CategoryService.fetchRestaurantsFromDB();
        final matched = stores.firstWhere(
          (s) => s['maQuan'] == widget.reservation.maQuan || s['tenQuan'] == storeName,
          orElse: () => null,
        );
        if (matched != null) {
          sLat = (matched['lat'] as num?)?.toDouble();
          sLng = (matched['lng'] as num?)?.toDouble();
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    sLat ??= 10.7812;
    sLng ??= 106.6985;
    final storePos = LatLng(sLat, sLng);

    // Chuyển sang Tab 2 (Bản đồ lộ trình)
    MainTabView.switchTab(context, 2);

    final mapProvider = Provider.of<MapProvider>(context, listen: false);
    final route = _routeInfo ?? await OrderRouteStorage.getReservationRoute(widget.reservation.maDatBan);

    await mapProvider.navigateToOrderStore(
      orderId: widget.reservation.maDatBan,
      storeName: storeName,
      storeAddress: storeAddress,
      storeLatLng: storePos,
      destinationLatLng: route != null ? LatLng(route.destLat, route.destLng) : null,
      destinationName: route?.destName,
      destinationAddress: route?.destAddress,
      pickupTime: DateFormat('HH:mm • dd/MM').format(widget.reservation.thoiGianBatDau.toLocal()),
      status: 'Đặt bàn: ${widget.reservation.statusTitle}',
    );

    if (mounted) {
      CustomToast.showSuccess(context, "Đang dẫn đường đến $storeName");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = DateFormat('HH:mm • dd/MM/yyyy').format(widget.reservation.thoiGianBatDau.toLocal());
    final res = widget.reservation.cuaHang;
    final storeName = res?.tenQuan ?? 'Quán ăn';
    final storeAddress = res?.diaChi ?? '';
    final storeImg = res?.img ?? '';
    final tableName = widget.reservation.ban?.tenBan ?? 'Quán tự xếp bàn';

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
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: ID + Status Badge ──
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
                        '#DB${widget.reservation.maDatBan}',
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
                        color: widget.reservation.statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.reservation.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.reservation.statusTitle,
                            style: TextStyle(
                              color: widget.reservation.statusColor,
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

                // ── Middle row: Store info ──
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
                const SizedBox(height: 12),

                // ── CHỈ DẪN LỘ TRÌNH 2 CHẶNG (Cam #FC6011 & Xanh lá #10B981) ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E3547) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Chặng 1: Đến quán (Cam #FC6011)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFC6011).withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded, size: 13, color: Color(0xFFFC6011)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0E6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Chặng 1: Đến quán',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFFFC6011),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  storeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: TColor.primaryTextOf(context),
                                  ),
                                ),
                                if (storeAddress.isNotEmpty)
                                  Text(
                                    storeAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: TColor.secondaryTextOf(context),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Nét nối 2 chặng
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 2,
                            height: 12,
                            color: const Color(0xFFCBD5E1),
                          ),
                        ),
                      ),
                      // Chặng 2: Đến điểm đến (Xanh lá #10B981)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.flag_rounded, size: 13, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Chặng 2: Đến đích',
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF10B981),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _routeInfo?.destName ?? 'Điểm đến theo lộ trình',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: TColor.primaryTextOf(context),
                                  ),
                                ),
                                if ((_routeInfo?.destAddress ?? '').isNotEmpty)
                                  Text(
                                    _routeInfo!.destAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: TColor.secondaryTextOf(context),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Bottom row: Bàn & khách + Nút Dẫn đường / Hủy ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.table_restaurant_rounded, size: 14, color: TColor.primary),
                          const SizedBox(width: 4),
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
                          const SizedBox(width: 6),
                          Container(width: 1, height: 12, color: TColor.borderOf(context)),
                          const SizedBox(width: 6),
                          Icon(Icons.people_outline_rounded, size: 14, color: TColor.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.reservation.soNguoi} khách',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TColor.primaryTextOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nút Dẫn đường trực tiếp
                    InkWell(
                      onTap: () => _startNavigation(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFC6011).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFC6011).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_rounded, size: 13, color: Color(0xFFFC6011)),
                            SizedBox(width: 4),
                            Text(
                              'Dẫn đường',
                              style: TextStyle(
                                color: Color(0xFFFC6011),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (widget.reservation.canCancel && widget.onCancel != null) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: widget.onCancel,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Hủy đặt',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
