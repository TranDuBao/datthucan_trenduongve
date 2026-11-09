import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import '../common/format_utils.dart';
import '../providers/map_provider.dart';
import '../models/route_model.dart';
import '../models/place_model.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/route_info_card.dart';
import '../widgets/food_stopover_sheet.dart';
import '../widgets/active_stopover_order_card.dart';
import '../widgets/distant_stores_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabAnimCtrl;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fabScale = CurvedAnimation(parent: _fabAnimCtrl, curve: Curves.elasticOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapP = context.read<MapProvider>();
      mapP.navigationContext = context;
      mapP.initialize();
    });
  }

  @override
  void dispose() {
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.read<MapProvider>().navigationContext = context;
    final mapP = context.watch<MapProvider>();
    if (mapP.distantStores.isNotEmpty &&
        mapP.routeRestaurants.isEmpty &&
        !mapP.hasShownDistantModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final p = context.read<MapProvider>();
        if (p.distantStores.isNotEmpty &&
            p.routeRestaurants.isEmpty &&
            !p.hasShownDistantModal) {
          p.markDistantModalShown();
          _showDistantStoreDialog(context, p);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Stack(
        children: [
          const _OptimizedMapWidget(),
          _buildTopGradient(),
          Selector<MapProvider, bool>(
            selector: (_, p) => p.isLoadingLocation,
            builder: (context, isLoading, _) {
              if (!isLoading) return const SizedBox.shrink();
              return _buildLoadingOverlay();
            },
          ),
          Consumer<MapProvider>(
            builder: (context, provider, _) {
              final bool hasActiveOrder = provider.activeStopoverOrder != null;
              final bool isNavigating = provider.isNavigating;
              final bool hideSearch = provider.isFocusMode || hasActiveOrder || isNavigating;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                top: hideSearch ? -280 : 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: hideSearch ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: provider.dismissSuggestions,
                      behavior: HitTestBehavior.translucent,
                      child: const Column(
                        children: [
                          SizedBox(height: 8),
                          SearchBarWidget(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // ── Thanh chỉ dẫn gọn gàng ở đỉnh màn hình khi đang dẫn đường ghé quán hoặc tới điểm đến ──
          Consumer<MapProvider>(
            builder: (context, provider, _) {
              final order = provider.activeStopoverOrder;
              final bool isNavigating = provider.isNavigating;
              if (order == null && !isNavigating) return const SizedBox.shrink();

              final storeName = order?['tenQuan'] ?? order?['restaurantName'] ?? context.l10n.orderModeQuickStop;
              final orderCode = (order?['maDonHang'] ?? order?['id'] ?? '').toString();
              final bool isPickedUp = provider.isOrderPickedUp;
              final destName = provider.destinationPlace?.name ?? context.l10n.homeDestination;

              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPickedUp ? const Color(0xFF10B981) : const Color(0xFFFC6011),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isPickedUp ? const Color(0xFF10B981) : const Color(0xFFFC6011)).withValues(alpha: 0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: (isPickedUp ? const Color(0xFF10B981) : const Color(0xFFFC6011)).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPickedUp ? Icons.check_circle_rounded : Icons.navigation_rounded,
                            color: isPickedUp ? const Color(0xFF10B981) : const Color(0xFFFC6011),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isPickedUp
                                ? context.l10n.homePickedUpContinue(storeName.toString(), destName)
                                : orderCode.isNotEmpty
                                    ? context.l10n.homeNavigatingWithOrder(storeName.toString(), orderCode)
                                    : context.l10n.homeNavigatingToStore(storeName.toString()),
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ScaleTransition(
                          scale: _fabScale,
                          child: Consumer<MapProvider>(
                            builder: (context, provider, _) {
                              return Column(
                                children: [
                                  if (provider.distantStores.isNotEmpty && provider.routeRestaurants.isEmpty) ...[
                                    provider.distantStores.length > 1
                                        ? Badge(
                                            label: Text('${provider.distantStores.length}'),
                                            backgroundColor: const Color(0xFFFC6011),
                                            textColor: Colors.white,
                                            offset: const Offset(-2, 2),
                                            child: _buildFab(
                                              icon: Icons.alt_route_rounded,
                                              onTap: () => DistantStoresSheet.show(context, provider),
                                              tooltip: 'Xem ${provider.distantStores.length} quán gợi ý ở xa hơn',
                                              color: const Color(0xFFFC6011),
                                            ),
                                          )
                                        : _buildFab(
                                            icon: Icons.alt_route_rounded,
                                            onTap: () {
                                              final store = provider.distantStores.first;
                                              provider.previewDistantStoreRoute(store);
                                            },
                                            tooltip: 'Xem lộ trình rẽ đến: ${(provider.distantStoreSuggestion!['tenQuan'] ?? 'quán').toString()}',
                                            color: const Color(0xFFFC6011),
                                          ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (provider.selectedStopoverStore != null) ...[
                                    _buildFab(
                                      icon: Icons.undo_rounded,
                                      onTap: provider.clearStopover,
                                      tooltip: 'Quay lại tuyến thẳng ban đầu',
                                      color: const Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  _buildFab(
                                    icon: Icons.my_location_rounded,
                                    onTap: provider.goToMyLocation,
                                    tooltip: context.l10n.homeMyLocation,
                                  ),
                                  if (provider.currentRoute != null) ...[
                                    const SizedBox(height: 8),
                                    _buildFab(
                                      icon: Icons.close_rounded,
                                      onTap: provider.clearAll,
                                      tooltip: context.l10n.homeClearRoute,
                                      color: const Color(0xFFFF5252),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<MapProvider>(
                    builder: (context, provider, _) {
                      // Nếu có đơn đang ghé quán (kể cả đã đánh dấu lấy món): hiện thẻ ghé quán
                      if (provider.activeStopoverOrder != null) {
                        return const ActiveStopoverOrderCard();
                      }
                      // Nếu đang dẫn đường chặng 2 tới điểm đến (đơn đã hoàn tất xóa): ẩn
                      if (provider.isNavigating) {
                        return const SizedBox.shrink();
                      }
                      return const RouteInfoCard();
                    },
                  ),
                ],
              ),
            ),
          ),
          Selector<MapProvider, MapState>(
            selector: (_, p) => p.state,
            builder: (context, state, _) {
              if (state != MapState.loadingRoute) return const SizedBox.shrink();
              return _buildRouteLoadingOverlay();
            },
          ),
          Selector<MapProvider, String?>(
            selector: (_, p) => p.errorMessage,
            builder: (context, errorMessage, _) {
              if (errorMessage == null) return const SizedBox.shrink();
              return _buildErrorBanner(errorMessage);
            },
          ),
          Selector<MapProvider, (RouteModel?, PlaceModel?)>(
            selector: (_, p) => (p.currentRoute, p.originPlace),
            builder: (context, data, _) {
              final (route, origin) = data;
              if (route != null || origin != null) return const SizedBox.shrink();
              return _buildTapHint();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopGradient() {
    return const SizedBox.shrink();
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xFF0F0F1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF00E5FF),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang xác định vị trí...',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteLoadingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E3A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF00E5FF),
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Đang tìm đường...',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Positioned(
      bottom: 180,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5252).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFFF5252), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTapHint() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app_rounded,
                  color: Color(0xFF00E5FF), size: 16),
              const SizedBox(width: 8),
              Text(
                'Chạm bản đồ để đặt điểm A → B',
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color color = const Color(0xFF00E5FF),
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E3A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  void _showDistantStoreDialog(BuildContext context, MapProvider provider) {
    final stores = provider.distantStores;
    if (stores.isEmpty) return;
    final store = stores.first;
    final storeName = (store['tenQuan'] ?? store['name'] ?? 'Quán ăn').toString();
    final dist = (store['distanceFromRouteMeters'] as num?)?.toInt() ?? 0;
    final foodKw = provider.foodKeyword;
    final bool hasMultiple = stores.length > 1;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: Color(0xFFFC6011),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Không có quán trong 800m',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1E293B),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                  children: [
                    const TextSpan(text: 'Không tìm thấy quán có món '),
                    TextSpan(
                      text: '"$foodKw"',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const TextSpan(text: ' tiện đường (≤ 800m).\n\n'),
                    if (hasMultiple) ...[
                      const TextSpan(text: 'Tìm thấy '),
                      TextSpan(
                        text: '${stores.length} quán',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFC6011)),
                      ),
                      const TextSpan(text: ' ở xa hơn (gần nhất lệch tuyến '),
                      TextSpan(
                        text: '${dist}m',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFC6011)),
                      ),
                      const TextSpan(text: '). Bạn có muốn xem danh sách để cân nhắc lộ trình không?'),
                    ] else ...[
                      const TextSpan(text: 'Có quán '),
                      TextSpan(
                        text: storeName,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFC6011)),
                      ),
                      const TextSpan(text: ' ở xa hơn (lệch tuyến '),
                      TextSpan(
                        text: '${dist}m',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFFC6011)),
                      ),
                      const TextSpan(text: '). Bạn có muốn xem lộ trình rẽ vào quán không?'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        'Để sau',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (hasMultiple) {
                          DistantStoresSheet.show(context, provider);
                        } else {
                          provider.previewDistantStoreRoute(store);
                        }
                      },
                      icon: Icon(
                        hasMultiple ? Icons.list_alt_rounded : Icons.alt_route_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        hasMultiple ? 'Xem danh sách' : 'Xem lộ trình rẽ',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6011),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 2,
                        shadowColor: const Color(0xFFFC6011).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



}

class _OptimizedMapWidget extends StatelessWidget {
  const _OptimizedMapWidget();

  List<Marker> _buildMarkers(
    BuildContext context,
    LatLng currentPosition,
    PlaceModel? originPlace,
    PlaceModel? destinationPlace, [
    List<dynamic> routeRestaurants = const [],
    Map<String, dynamic>? selectedStopoverStore,
    Map<String, dynamic>? activeStopoverOrder,
    LatLng? activeStopoverLatLng,
  ]) {
    final markers = <Marker>[];

    // Current position marker
    markers.add(
      Marker(
        point: currentPosition,
        width: 36,
        height: 36,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFC6011).withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFFC6011),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFC6011),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Pickup marker (Green dot)
    if (originPlace != null) {
      markers.add(
        Marker(
          point: originPlace.latLng,
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF00C853),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Destination marker (Orange Callout Badge + Pin)
    if (destinationPlace != null) {
      markers.add(
        Marker(
          point: destinationPlace.latLng,
          width: 180,
          height: 75,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFC6011), Color(0xFFFF7A00)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFC6011).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flag_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        destinationPlace.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFC6011),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Along-route restaurant markers (Foodie badges with dish name)
    // Chỉ hiển thị khi người dùng tìm kiếm, ẩn hoàn toàn khi đang điều hướng đơn ghé quán
    if (activeStopoverOrder == null) {
      for (final res in routeRestaurants) {
        final double? lat = (res['lat'] as num?)?.toDouble();
        final double? lng = (res['lng'] as num?)?.toDouble();
        final String storeName = (res['tenQuan'] ?? res['name'] ?? 'Quán tiện đường').toString();
        final int dist = (res['distanceFromRouteMeters'] as num?)?.toInt() ?? 0;

        final matchedFoods = (res['matchedFoods'] as List?) ?? [];
        final primaryFood = res['primaryFood'] ?? (matchedFoods.isNotEmpty ? matchedFoods[0] : null);
        final String labelName = storeName;

        final bool isStopover = selectedStopoverStore != null && selectedStopoverStore['maQuan'] == res['maQuan'];

        if (lat != null && lng != null) {
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: isStopover ? 160 : 145,
              height: isStopover ? 60 : 54,
              child: GestureDetector(
                onTap: () {
                  FoodStopoverSheet.show(
                    context,
                    restaurant: res as Map<String, dynamic>,
                    selectedFood: primaryFood as Map<String, dynamic>?,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isStopover ? const Color(0xFFEA580C) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isStopover ? const Color(0xFFFFD54F) : const Color(0xFFFC6011),
                          width: isStopover ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isStopover ? const Color(0xFFFC6011).withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.35),
                            blurRadius: isStopover ? 10 : 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isStopover ? Icons.star_rounded : Icons.storefront_rounded,
                            color: isStopover ? const Color(0xFFFFD54F) : const Color(0xFFFC6011),
                            size: 13,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              labelName,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (dist > 0) ...[
                            const SizedBox(width: 3),
                            Text(
                              '• ${dist}m',
                              style: GoogleFonts.outfit(
                                color: isStopover ? Colors.white70 : const Color(0xFF94A3B8),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: isStopover ? 22 : 18,
                      height: isStopover ? 22 : 18,
                      decoration: BoxDecoration(
                        color: isStopover ? const Color(0xFFFFD54F) : const Color(0xFFFC6011),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        isStopover ? Icons.check_rounded : Icons.fastfood_rounded,
                        color: isStopover ? const Color(0xFF1E293B) : Colors.white,
                        size: isStopover ? 13 : 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    // Active Stopover Order marker (nếu có đơn hàng đang dẫn đường ghé quán)
    if (activeStopoverOrder != null && activeStopoverLatLng != null) {
      final sName = activeStopoverOrder['tenQuan'] ?? activeStopoverOrder['restaurantName'] ?? 'Quán ghé lấy';
      final sCode = activeStopoverOrder['maDonHang'] ?? activeStopoverOrder['id'] ?? '';
      markers.add(
        Marker(
          point: activeStopoverLatLng,
          width: 175,
          height: 62,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFC6011), Color(0xFFFF7A00)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        context.l10n.stopoverMarkerOrderBadge(sCode.toString(), sName.toString()),
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFFC6011),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 12),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MapProvider>(context, listen: false);

    return FlutterMap(
      mapController: provider.mapController,
      options: MapOptions(
        initialCenter: const LatLng(ApiConfig.defaultLat, ApiConfig.defaultLng),
        initialZoom: 15,
        minZoom: 10,
        maxZoom: 18.5,
        onMapReady: provider.onMapReady,
        onTap: (tapPosition, point) async {
          final hasRoute = provider.currentRoute != null;
          final showingSuggestions = provider.showSuggestions;
          if (hasRoute && !showingSuggestions) {
            provider.toggleFocusMode();
          } else {
            provider.exitFocusMode();
            await provider.onMapTapped(point);
          }
        },
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: ApiConfig.lightTileUrl,
          fallbackUrl: ApiConfig.fallbackTileUrl,
          subdomains: const ['0', '1', '2', '3'],
          userAgentPackageName: 'com.codeforany.food_delivery',
          maxZoom: 19,
          maxNativeZoom: 19,
          tileBuilder: (context, tileWidget, tile) {
            // Bộ lọc làm mờ mạng lưới đường viền xám chằng chịt,
            // nâng sáng nhẹ nền bản đồ để tuyến đường và quán ăn nổi bật tối đa,
            // đồng thời giữ trọn vẹn tên đường và ngõ hẻm ở mọi mức zoom.
            return ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.22, 0.35, 0.05, 0, 95,
                0.10, 0.47, 0.05, 0, 95,
                0.10, 0.35, 0.22, 0, 95,
                0,    0,    0,    1, 0,
              ]),
              child: tileWidget,
            );
          },
          errorTileCallback: (tile, error, stackTrace) {
            debugPrint('[HomeScreen] [Warn] TileLayer load error: $error');
          },
        ),
        Selector<MapProvider, ({
          RouteModel? originalRoute,
          RouteModel? stopoverRoute,
          bool isNavigating,
          ValueNotifier<List<LatLng>> remainingLeg1,
          ValueNotifier<List<LatLng>> remainingLeg2,
        })>(
          selector: (_, p) => (
            originalRoute: p.originalRoute,
            stopoverRoute: p.stopoverRoute,
            isNavigating: p.isNavigating,
            remainingLeg1: p.remainingLeg1,
            remainingLeg2: p.remainingLeg2,
          ),
          builder: (context, routes, _) {
            final original = routes.originalRoute;
            final stopover = routes.stopoverRoute;
            if (original == null && stopover == null) return const SizedBox.shrink();

            return ValueListenableBuilder<List<LatLng>>(
              valueListenable: routes.remainingLeg1,
              builder: (context, leg1Pts, _) {
                return ValueListenableBuilder<List<LatLng>>(
                  valueListenable: routes.remainingLeg2,
                  builder: (context, leg2Pts, _) {
                    final isNav = routes.isNavigating;
                    final ptsLeg1 = isNav
                        ? leg1Pts
                        : (stopover?.legs.isNotEmpty == true
                            ? stopover!.legs[0].polylinePoints
                            : (stopover?.simplifiedPolylinePoints ?? []));
                    final ptsLeg2 = isNav
                        ? leg2Pts
                        : (stopover != null && stopover.legs.length >= 2
                            ? stopover.legs[1].polylinePoints
                            : <LatLng>[]);

                    return PolylineLayer(
                      polylines: [
                        // Tuyến đường gốc A -> B (nếu có lộ trình ghé quán, vẽ mờ làm đường cơ sở tham chiếu)
                        if (original != null && stopover != null && original.simplifiedPolylinePoints.length >= 2)
                          Polyline(
                            points: original.simplifiedPolylinePoints,
                            strokeWidth: 4.0,
                            color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                            borderColor: Colors.white38,
                            borderStrokeWidth: 1.0,
                          )
                        else if (original != null && original.simplifiedPolylinePoints.length >= 2 && !isNav)
                          Polyline(
                            points: original.simplifiedPolylinePoints,
                            strokeWidth: 5.5,
                            color: const Color(0xFF2563EB),
                            borderColor: const Color(0xFF93C5FD),
                            borderStrokeWidth: 1.2,
                          ),

                        // Chặng 1: Hiện tại -> Quán ăn lấy món (Màu cam thương hiệu nổi bật, xóa dần khi xe đi qua)
                        if (ptsLeg1.length >= 2)
                          Polyline(
                            points: ptsLeg1,
                            strokeWidth: 6.0,
                            color: const Color(0xFFFC6011),
                            borderColor: const Color(0xFFFF9E80),
                            borderStrokeWidth: 1.5,
                          ),

                        // Chặng 2: Quán ăn -> Điểm đến đích (Màu xanh ngọc, xóa dần khi xe đi qua)
                        if (ptsLeg2.length >= 2)
                          Polyline(
                            points: ptsLeg2,
                            strokeWidth: 5.5,
                            color: const Color(0xFF059669),
                            borderColor: const Color(0xFF6EE7B7),
                            borderStrokeWidth: 1.5,
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        Selector<MapProvider, ({
          LatLng position,
          PlaceModel? origin,
          PlaceModel? destination,
          List<dynamic> routeRestaurants,
          Map<String, dynamic>? selectedStopoverStore,
          Map<String, dynamic>? activeStopoverOrder,
          LatLng? activeStopoverLatLng,
        })>(
          selector: (_, p) => (
            position: p.currentPosition,
            origin: p.originPlace,
            destination: p.destinationPlace,
            routeRestaurants: p.routeRestaurants,
            selectedStopoverStore: p.selectedStopoverStore,
            activeStopoverOrder: p.activeStopoverOrder,
            activeStopoverLatLng: p.activeStopoverLatLng,
          ),
          builder: (context, data, _) {
            final storesToRender = data.activeStopoverOrder != null
                ? []
                : [
                    ...data.routeRestaurants,
                    if (data.routeRestaurants.isEmpty && context.read<MapProvider>().distantStores.isNotEmpty)
                      ...context.read<MapProvider>().distantStores,
                  ];
            return MarkerLayer(
              markers: _buildMarkers(
                context,
                data.position,
                data.origin,
                data.destination,
                storesToRender,
                data.selectedStopoverStore,
                data.activeStopoverOrder,
                data.activeStopoverLatLng,
              ),
            );
          },
        ),
      ],
    );
  }
}
