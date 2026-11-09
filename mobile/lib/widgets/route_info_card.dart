import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../common/format_utils.dart';
import 'route_restaurants_sheet.dart';
import 'distant_stores_sheet.dart';
import '../providers/map_provider.dart';
import '../models/route_model.dart';

String _formatRouteDuration(BuildContext context, int totalSec) {
  if (totalSec >= 3600) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    return context.l10n.durationHoursMinutes(h, m);
  }
  final m = (totalSec / 60).round();
  return context.l10n.durationMinutes(m);
}

String _formatTrafficLabel(BuildContext context, TrafficStatus status) {
  switch (status) {
    case TrafficStatus.smooth:
      return context.l10n.trafficStatusSmooth;
    case TrafficStatus.slow:
      return context.l10n.trafficStatusSlow;
    case TrafficStatus.moderate:
      return context.l10n.trafficStatusModerate;
    case TrafficStatus.heavy:
      return context.l10n.trafficStatusHeavy;
  }
}

String _formatTrafficDelay(BuildContext context, int seconds) {
  if (seconds < 60) return '';
  if (seconds < 3600) {
    return context.l10n.trafficDelayMinutes((seconds / 60).toInt());
  }
  return context.l10n.trafficDelayHours((seconds / 3600).toStringAsFixed(1));
}

String _formatStepDuration(BuildContext context, String rawDur) {
  final isVi = Localizations.localeOf(context).languageCode == 'vi';
  if (isVi) return rawDur;
  return rawDur.replaceAll('phút', 'mins').replaceAll('giờ', 'hr');
}

class RouteInfoCard extends StatelessWidget {
  const RouteInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        final route = provider.stopoverRoute ?? provider.currentRoute;
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
                _buildRouteBanner(context),
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
            _formatRouteDuration(context, route.totalDurationSeconds),
            style: GoogleFonts.outfit(
              color: const Color(0xFF1C1C1E),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '(${route.totalDistance}) • ${context.l10n.routePrepTimeApprox(provider.prepMinutes)}',
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
                    context.l10n.routeDetails,
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
        ? context.l10n.routeClearTraffic
        : context.l10n.routeTrafficStatusLabel(_formatTrafficLabel(context, route.trafficStatus));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _showStepsSheet(context),
            child: Tooltip(
              message: context.l10n.routeViewSegmentDetails,
              child: Container(
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
                      _formatRouteDuration(context, route.totalDurationSeconds),
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
                provider.foodRouteOption == FoodRouteOption.dineIn
                    ? context.l10n.routeDineInHeader
                    : (provider.foodRouteOption == FoodRouteOption.preOrder
                        ? context.l10n.routePreOrderHeader
                        : context.l10n.routeQuickStopHeader),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8E8E93),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.routeMinutesApprox(provider.prepMinutes),
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

  Widget _buildRouteBanner(BuildContext context) {
    final stopoverStore = provider.selectedStopoverStore;
    final String bannerText;
    final String badgeText;

    if (stopoverStore != null) {
      bannerText = context.l10n.routeStopoverBanner((stopoverStore['tenQuan'] ?? context.l10n.restaurantDefaultName).toString());
      badgeText = context.l10n.routeStopoverBadge;
    } else if (provider.foodKeyword.isNotEmpty) {
      if (provider.isSearchingFood) {
        bannerText = context.l10n.routeSearchingFoodAlong(provider.foodKeyword);
        badgeText = context.l10n.routeSearchingBadge;
      } else if (provider.routeRestaurants.isEmpty) {
        if (provider.distantStores.isNotEmpty) {
          final count = provider.distantStores.length;
          final dist = provider.distantStoreSuggestion!['distanceFromRouteMeters'];
          bannerText = count > 1
              ? 'Không có trong 800m • Có $count quán xa hơn (từ +${dist}m)'
              : 'Không có trong 800m • Có quán xa hơn (+${dist}m)';
          badgeText = 'GỢI Ý';
        } else {
          bannerText = context.l10n.routeNoStoresForKeyword(provider.foodKeyword);
          badgeText = context.l10n.routeZeroStoresBadge;
        }
      } else {
        bannerText = context.l10n.routeFoundStoresForKeyword(provider.routeRestaurants.length, provider.foodKeyword);
        badgeText = context.l10n.routeConvenientBadge;
      }
    } else {
      bannerText = context.l10n.routeDefaultCommuteBanner;
      badgeText = context.l10n.routeConvenientBadge;
    }

    return GestureDetector(
      onTap: () {
        if (provider.routeRestaurants.isEmpty && provider.distantStores.isNotEmpty) {
          if (provider.distantStores.length > 1) {
            DistantStoresSheet.show(context, provider);
          } else {
            final store = provider.distantStores.first;
            provider.previewDistantStoreRoute(store);
          }
        } else if (provider.routeRestaurants.isNotEmpty) {
          _showRouteRestaurantsSheet(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: stopoverStore != null ? const Color(0xFFFFF7ED) : const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stopoverStore != null ? const Color(0xFFFDBA74) : const Color(0xFFFFE0B2)),
        ),
        child: Row(
          children: [
            Icon(
              stopoverStore != null ? Icons.store_rounded : Icons.storefront_rounded,
              color: const Color(0xFFFC6011),
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bannerText,
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
                badgeText,
                style: GoogleFonts.outfit(
                  color: const Color(0xFFFC6011),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: GestureDetector(
        onTap: () {
          if (provider.routeRestaurants.isEmpty && provider.distantStores.isNotEmpty) {
            if (provider.distantStores.length > 1) {
              DistantStoresSheet.show(context, provider);
            } else {
              final store = provider.distantStores.first;
              provider.previewDistantStoreRoute(store);
            }
            return;
          }
          _showRouteRestaurantsSheet(context);
        },
        child: Container(
          width: double.infinity,
          height: 52,
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
                provider.foodRouteOption == FoodRouteOption.dineIn
                    ? context.l10n.routeConfirmDineIn
                    : (provider.foodRouteOption == FoodRouteOption.preOrder
                        ? context.l10n.routeConfirmPreOrder
                        : context.l10n.routeConfirmQuickStop),
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
    RouteRestaurantsSheet.show(context, provider);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2430) : Colors.white;
    final primaryText = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF2C3240) : const Color(0xFFF1F5F9);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF0F1F5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 48,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFC6011), Color(0xFFFF7A00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFC6011).withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.turn_right_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.routeDirectionsTitle,
                        style: GoogleFonts.outfit(
                          color: primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _chip(
                      icon: Icons.format_list_numbered_rounded,
                      label: context.l10n.routeStepsCount(route.steps.length),
                      bgColor: isDark ? const Color(0xFF2C221C) : const Color(0xFFFFF3ED),
                      textColor: const Color(0xFFFC6011),
                      borderColor: const Color(0xFFFFD8C2),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    _chip(
                      icon: Icons.schedule_rounded,
                      label: _formatRouteDuration(context, route.totalDurationSeconds),
                      bgColor: isDark ? const Color(0xFF2C221C) : const Color(0xFFFFF3ED),
                      textColor: const Color(0xFFFC6011),
                      borderColor: const Color(0xFFFFD8C2),
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      icon: Icons.straighten_rounded,
                      label: route.totalDistance,
                      bgColor: isDark ? const Color(0xFF262D3D) : const Color(0xFFF8FAFC),
                      textColor: isDark ? Colors.white : const Color(0xFF334155),
                      borderColor: isDark ? const Color(0xFF333D52) : const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 8),
                    _chip(
                      icon: Icons.location_on_rounded,
                      label: context.l10n.routeArriveAt(route.etaText),
                      bgColor: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5),
                      textColor: const Color(0xFF059669),
                      borderColor: const Color(0xFFA7F3D0),
                    ),
                  ],
                ),
              ),
              _buildTrafficSummary(context, isDark),
              Divider(
                color: borderColor,
                height: 1,
                thickness: 1,
                indent: 20,
                endIndent: 20,
              ),
              Expanded(
                child: route.steps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: secondaryText.withValues(alpha: 0.5),
                                size: 36),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.routeNoDirectionsData,
                              style: GoogleFonts.outfit(
                                color: secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                        itemCount: route.steps.length,
                        itemBuilder: (_, i) =>
                            _buildStep(context, route.steps[i], i, route.steps.length, isDark, primaryText, secondaryText),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrafficSummary(BuildContext context, bool isDark) {
    final status = route.trafficStatus;
    final (bgColor, borderColor, textColor, icon) = switch (status) {
      TrafficStatus.smooth => (
          isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFF0FDF4),
          const Color(0xFF86EFAC),
          const Color(0xFF059669),
          Icons.check_circle_rounded,
        ),
      TrafficStatus.slow => (
          isDark ? const Color(0xFF451A03).withValues(alpha: 0.25) : const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
          const Color(0xFFD97706),
          Icons.speed_rounded,
        ),
      TrafficStatus.moderate => (
          isDark ? const Color(0xFF431407).withValues(alpha: 0.25) : const Color(0xFFFFF7ED),
          const Color(0xFFFED7AA),
          const Color(0xFFEA580C),
          Icons.traffic_rounded,
        ),
      TrafficStatus.heavy => (
          isDark ? const Color(0xFF4C0519).withValues(alpha: 0.25) : const Color(0xFFFEF2F2),
          const Color(0xFFFECACA),
          const Color(0xFFDC2626),
          Icons.warning_amber_rounded,
        ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.routeTrafficStatusDetail(_formatTrafficLabel(context, route.trafficStatus)),
                  style: GoogleFonts.outfit(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  route.trafficDelayInSeconds >= 60
                      ? context.l10n.routeTrafficDelayed(_formatTrafficDelay(context, route.trafficDelayInSeconds))
                      : context.l10n.routeClearTrafficDetail,
                  style: GoogleFonts.outfit(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    RouteStep step,
    int index,
    int total,
    bool isDark,
    Color primaryText,
    Color secondaryText,
  ) {
    final isFirst = index == 0;
    final isLast = index == total - 1;
    final isArrive = step.maneuver.toUpperCase().contains('ARRIVE') ||
        step.maneuver == 'arrive';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isArrive
                          ? const Color(0xFF10B981)
                          : isFirst
                              ? const Color(0xFFFC6011)
                              : (isDark ? const Color(0xFF262D3D) : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isArrive
                            ? const Color(0xFF10B981)
                            : isFirst
                                ? const Color(0xFFFC6011)
                                : (isDark ? const Color(0xFF333D52) : const Color(0xFFE2E8F0)),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isArrive
                                  ? const Color(0xFF10B981)
                                  : isFirst
                                      ? const Color(0xFFFC6011)
                                      : Colors.black)
                              .withValues(alpha: isFirst || isArrive ? 0.35 : 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: isArrive
                          ? const Icon(Icons.location_on_rounded, color: Colors.white, size: 16)
                          : isFirst
                              ? const Icon(Icons.my_location_rounded, color: Colors.white, size: 16)
                              : Text(
                                  step.maneuverIcon,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFFC6011),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 2,
                          color: isDark ? const Color(0xFF2C3240) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.instruction.isEmpty ? context.l10n.routeGoStraight : step.instruction,
                      style: GoogleFonts.outfit(
                        color: primaryText,
                        fontSize: 13.5,
                        fontWeight: isFirst || isArrive ? FontWeight.w800 : FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (step.distance != '0 m') ...[
                          Icon(Icons.straighten_rounded,
                              size: 12, color: secondaryText),
                          const SizedBox(width: 3),
                          Text(
                            step.distance,
                            style: GoogleFonts.outfit(
                              color: secondaryText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text('  •  ',
                              style: TextStyle(
                                  color: secondaryText.withValues(alpha: 0.6),
                                  fontSize: 11)),
                        ],
                        Icon(Icons.schedule_rounded,
                            size: 12, color: secondaryText),
                        const SizedBox(width: 3),
                        Text(
                          _formatStepDuration(context, step.duration),
                          style: GoogleFonts.outfit(
                            color: secondaryText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
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

  Widget _chip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
