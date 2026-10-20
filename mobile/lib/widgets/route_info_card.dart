import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../models/route_model.dart';
import '../view/menu/restaurant_detail_view.dart';
import '../view/main_tabview/main_tabview.dart';

class RouteInfoCard extends StatelessWidget {
  const RouteInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        final route = provider.currentRoute;
        if (route == null) return const SizedBox.shrink();

        return AnimatedSlide(
          offset:
              provider.showRouteDetails ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: provider.showRouteDetails ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: _RouteCard(provider: provider, route: route),
          ),
        );
      },
    );
  }
}

class _RouteCard extends StatelessWidget {
  final MapProvider provider;
  final RouteModel route;
  const _RouteCard({required this.provider, required this.route});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: provider.isFocusMode
          ? _buildCompactCard(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5EA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _buildRouteAndPriceRow(context),
                _buildRouteBanner(),
                _buildConfirmButton(context),
              ],
            ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: Color(0xFFFC6011),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            route.totalDuration,
            style: GoogleFonts.outfit(
              color: const Color(0xFF1C1C1E),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '(${route.totalDistance}) • ${provider.pickupReadyTimeText}',
              style: GoogleFonts.outfit(
                color: const Color(0xFF8E8E93),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: provider.exitFocusMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.unfold_more_rounded,
                      color: Color(0xFFFC6011), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Chi tiết',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFC6011),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteAndPriceRow(BuildContext context) {
    final trafficNote = route.trafficStatus == TrafficStatus.smooth
        ? 'Tuyến đường thông thoáng'
        : 'Giao thông: ${route.trafficLabel}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: Color(0xFFFC6011),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      route.totalDistance,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF1C1C1E),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF8E8E93),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      route.totalDuration,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF00C853),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  trafficNote,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'GHÉ LẤY',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8E8E93),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '~${provider.prepMinutes} phút',
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFC6011),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_rounded,
            color: Color(0xFFFC6011),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tiện đường đi làm về • Đặt trước ghé lấy không chờ đợi',
              style: GoogleFonts.outfit(
                color: const Color(0xFFE65100),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFFC6011).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'TIỆN ĐƯỜNG',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFC6011),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: GestureDetector(
        onTap: () => _showRouteRestaurantsSheet(context),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFC6011), Color(0xFFFF7A00)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFC6011).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Xác nhận lộ trình ghé lấy',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRouteRestaurantsSheet(BuildContext context) {
    final restaurants = provider.routeRestaurants;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
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
                    color: Colors.white24,
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
                        color: const Color(0xFFFC6011).withValues(alpha: 0.15),
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
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Tiện đường ghé lấy • Không cần đi vòng',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
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
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
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
                              child: Text('Khám phá toàn bộ thực đơn', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: restaurants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final r = restaurants[idx] as Map;
                          final storeName = (r['tenQuan'] ?? r['name'] ?? 'Nhà hàng').toString();
                          final address = (r['diaChi'] ?? r['address'] ?? 'Địa chỉ tự đến lấy').toString();
                          final int dist = (r['distanceFromRouteMeters'] as num?)?.toInt() ?? 0;
                          final int prepTime = (r['thoiGianChuanBi'] as num?)?.toInt() ?? 20;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFC6011).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.restaurant_rounded, color: Color(0xFFFC6011), size: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        storeName,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
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
                                          color: const Color(0xFF94A3B8),
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              dist > 0 ? 'Lệch tuyến ${dist}m' : 'Ngay trên tuyến',
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFF10B981),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '• Chuẩn bị ~$prepTime phút',
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFF94A3B8),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFC6011),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RestaurantDetailView(restaurantObj: r),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Xem Menu',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
      },
    );
  }

  void _showStepsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DirectionStepsList(route: route),
    );
  }
}

class DirectionStepsList extends StatelessWidget {
  final RouteModel route;
  const DirectionStepsList({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A35),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Icon(Icons.navigation_rounded,
                        color: Color(0xFF00E5FF), size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Hướng dẫn đường đi',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _chip(
                        Icons.format_list_numbered_rounded,
                        '${route.steps.length} bước',
                        const Color(0xFF00E5FF)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    _chip(Icons.schedule_rounded, route.totalDuration,
                        const Color(0xFF00E5FF)),
                    const SizedBox(width: 8),
                    _chip(Icons.straighten_rounded, route.totalDistance,
                        const Color(0xFFFFD54F)),
                    const SizedBox(width: 8),
                    _chip(Icons.location_on_rounded, 'Đến ${route.etaText}',
                        const Color(0xFF00E676)),
                  ],
                ),
              ),
              _buildTrafficSummary(),
              Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                  indent: 20,
                  endIndent: 20),
              Expanded(
                child: route.steps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'Không có dữ liệu hướng dẫn',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: route.steps.length,
                        itemBuilder: (_, i) =>
                            _buildStep(route.steps[i], i, route.steps.length),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrafficSummary() {
    final status = route.trafficStatus;
    final (color, icon) = switch (status) {
      TrafficStatus.smooth => (const Color(0xFF00E676), Icons.check_circle_outline_rounded),
      TrafficStatus.slow => (const Color(0xFFFFD54F), Icons.speed_rounded),
      TrafficStatus.moderate => (const Color(0xFFFF9800), Icons.traffic_rounded),
      TrafficStatus.heavy => (const Color(0xFFFF5252), Icons.warning_amber_rounded),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tình trạng giao thông: ${route.trafficLabel}',
                  style: GoogleFonts.outfit(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (route.trafficDelayText.isNotEmpty)
                  Text(
                    'Dự kiến trễ ${route.trafficDelayText} do giao thông',
                    style: GoogleFonts.outfit(
                      color: color.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  )
                else
                  Text(
                    'Tuyến đường thông thoáng, không có ùn tắc',
                    style: GoogleFonts.outfit(
                      color: color.withValues(alpha: 0.75),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(RouteStep step, int index, int total) {
    final isFirst = index == 0;
    final isLast = index == total - 1;
    final isArrive = step.maneuver.toUpperCase().contains('ARRIVE') ||
        step.maneuver == 'arrive';

    final stepColor = isArrive
        ? const Color(0xFF00E676)
        : isFirst
            ? const Color(0xFF00E5FF)
            : Colors.white.withValues(alpha: 0.8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  if (!isFirst)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 2,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isArrive
                          ? const Color(0xFF00E676).withValues(alpha: 0.15)
                          : isFirst
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                              : const Color(0xFF2D2D5E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: stepColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Text(step.maneuverIcon,
                          style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 2,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.instruction.isEmpty ? 'Đi thẳng' : step.instruction,
                      style: GoogleFonts.outfit(
                        color: stepColor,
                        fontSize: 13,
                        fontWeight: isFirst || isArrive
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (step.distance != '0 m') ...[
                          Icon(Icons.straighten_rounded,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.4)),
                          const SizedBox(width: 3),
                          Text(
                            step.distance,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                          Text(' • ',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 11)),
                        ],
                        Icon(Icons.schedule_rounded,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(width: 3),
                        Text(
                          step.duration,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
