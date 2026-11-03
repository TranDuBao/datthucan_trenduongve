import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/map_provider.dart';
import '../view/menu/restaurant_detail_view.dart';
import '../view/main_tabview/main_tabview.dart';
import '../common_widget/smart_network_image.dart';

class RouteRestaurantsSheet extends StatelessWidget {
  final MapProvider provider;

  const RouteRestaurantsSheet({super.key, required this.provider});

  static void show(BuildContext context, MapProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RouteRestaurantsSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = provider.routeRestaurants;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Color(0xFFFC6011), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quán ăn trên lộ trình (${restaurants.length})',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Tiện đường ghé lấy • Không cần đi vòng',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          Flexible(
            child: restaurants.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Đang tải hoặc chưa có quán ăn trực tiếp trên trục đường này',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFC6011),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            final mainTab = context.findAncestorStateOfType<MainTabViewState>();
                            if (mainTab != null) mainTab.changeTab(1);
                          },
                          child: Text(
                            'Khám phá toàn bộ thực đơn',
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: restaurants.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, idx) {
                      final r = restaurants[idx] as Map;
                      final storeName = (r['tenQuan'] ?? r['name'] ?? 'Nhà hàng').toString();
                      final address = (r['diaChi'] ?? r['address'] ?? 'Địa chỉ tự đến lấy').toString();
                      final int dist = (r['distanceFromRouteMeters'] as num?)?.toInt() ?? 0;
                      final int prepTime = (r['thoiGianChuanBi'] as num?)?.toInt() ?? 15;
                      final double rating = (r['diemDanhGiaTB'] as num?)?.toDouble() ??
                          (r['danhGiaTrungBinh'] as num?)?.toDouble() ??
                          (r['rate'] as num?)?.toDouble() ??
                          0.0;
                      final int ratingCount = int.tryParse((r['soLuongDanhGia'] ?? r['soLuotDanhGia'] ?? r['ratingCount'] ?? 0).toString()) ?? 0;
                      final bool hasRealRating = rating > 0 && ratingCount > 0 && r['chuaCoDanhGia'] != true;
                      final double? storeLat = (r['lat'] as num?)?.toDouble() ?? (r['latitude'] as num?)?.toDouble();
                      final double? storeLng = (r['lng'] as num?)?.toDouble() ?? (r['longitude'] as num?)?.toDouble();
                      final userLat = provider.originPlace?.latLng.latitude;
                      final userLng = provider.originPlace?.latLng.longitude;

                      String distanceText = '';
                      if (userLat != null && userLng != null && storeLat != null && storeLng != null) {
                        final double dMeters = Geolocator.distanceBetween(userLat, userLng, storeLat, storeLng);
                        if (dMeters >= 1000) {
                          distanceText = '${(dMeters / 1000).toStringAsFixed(1)} km';
                        } else {
                          distanceText = '${dMeters.round()} m';
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail with Rating Badge
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SmartNetworkImage(
                                      imageUrl: (r['img'] ?? r['image'] ?? r['hinhAnh'] ?? '').toString(),
                                      width: 76,
                                      height: 76,
                                      borderRadius: BorderRadius.circular(12),
                                      placeholderIcon: Icons.restaurant_rounded,
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.15),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: hasRealRating
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 12),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    rating.toStringAsFixed(1),
                                                    style: GoogleFonts.outfit(
                                                      color: const Color(0xFF0F172A),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Text(
                                                'Mới',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFFFC6011),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                // Store Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        storeName,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF0F172A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        address,
                                        style: GoogleFonts.outfit(
                                          color: const Color(0xFF64748B),
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFA7F3D0)),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.north_east_rounded, size: 11, color: Color(0xFF059669)),
                                                const SizedBox(width: 3),
                                                Text(
                                                  dist > 0 ? 'Lệch tuyến ${dist}m' : 'Ngay trên tuyến',
                                                  style: GoogleFonts.outfit(
                                                    color: const Color(0xFF059669),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Chuẩn bị ~$prepTime phút',
                                                style: GoogleFonts.outfit(
                                                  color: const Color(0xFF64748B),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Bottom Row: Distance + Action Button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Cách bạn: ',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      distanceText.isNotEmpty ? distanceText : '1.2 km',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF0F172A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RestaurantDetailView(restaurantObj: r),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFC6011),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFC6011).withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Xem Menu',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 15),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
