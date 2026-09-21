import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../models/route_model.dart';

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
        color: const Color(0xFF1E1E3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: provider.isFocusMode
          ? _buildCompactCard(context)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildTrafficBar(),
                _buildAddressRow(),
                if (route.steps.isNotEmpty) _buildFirstStep(),
                _buildActionRow(context),
              ],
            ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    final status = route.trafficStatus;
    final trafficColor = switch (status) {
      TrafficStatus.smooth => const Color(0xFF00E676),
      TrafficStatus.slow => const Color(0xFFFFD54F),
      TrafficStatus.moderate => const Color(0xFFFF9800),
      TrafficStatus.heavy => const Color(0xFFFF5252),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: trafficColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: trafficColor.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            route.totalDuration,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '(${route.totalDistance}) • Đến lúc ${route.etaText}',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
                color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.unfold_more_rounded,
                      color: Color(0xFF00E5FF), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Chi tiết',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.totalDuration,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.straighten_rounded,
                        color: Colors.white.withValues(alpha: 0.5), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      route.totalDistance,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: provider.clearAll,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white54, size: 15),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF0091FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'Đến lúc',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      route.etaText,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficBar() {
    final status = route.trafficStatus;
    final (color, icon, bg) = switch (status) {
      TrafficStatus.smooth => (
          const Color(0xFF00E676),
          Icons.check_circle_outline_rounded,
          const Color(0xFF00E676),
        ),
      TrafficStatus.slow => (
          const Color(0xFFFFD54F),
          Icons.speed_rounded,
          const Color(0xFFFFD54F),
        ),
      TrafficStatus.moderate => (
          const Color(0xFFFF9800),
          Icons.traffic_rounded,
          const Color(0xFFFF9800),
        ),
      TrafficStatus.heavy => (
          const Color(0xFFFF5252),
          Icons.warning_amber_rounded,
          const Color(0xFFFF5252),
        ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Text(
            'Giao thông: ${route.trafficLabel}',
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (route.trafficDelayText.isNotEmpty) ...[
            const Spacer(),
            Text(
              'Trễ ${route.trafficDelayText}',
              style: GoogleFonts.outfit(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    color: Color(0xFF00E676), shape: BoxShape.circle),
              ),
              Container(
                  width: 2, height: 18, color: Colors.white.withValues(alpha: 0.2)),
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    color: Color(0xFFFF5252), shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.originPlace?.name ?? 'Điểm bắt đầu',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  provider.destinationPlace?.name ?? 'Điểm đến',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstStep() {
    final first = route.steps.first;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D5E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(first.maneuverIcon,
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bước tiếp theo',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF00E5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  first.instruction.isEmpty
                      ? 'Đi thẳng'
                      : first.instruction,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            first.distance,
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: GestureDetector(
        onTap: () => _showStepsSheet(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF0091FF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.turn_right_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Xem toàn bộ ${route.steps.length} bước hướng dẫn',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
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
