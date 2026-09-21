import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import '../providers/map_provider.dart';
import '../models/route_model.dart';
import '../models/place_model.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/route_info_card.dart';

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
      context.read<MapProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _fabAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Selector<MapProvider, bool>(
            selector: (_, p) => p.isFocusMode,
            builder: (context, focusMode, _) {
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                top: focusMode ? -150 : 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: focusMode ? 0 : 1,
                  duration: const Duration(milliseconds: 250),
                  child: SafeArea(
                    child: Consumer<MapProvider>(
                      builder: (context, provider, _) {
                        return GestureDetector(
                          onTap: provider.dismissSuggestions,
                          behavior: HitTestBehavior.translucent,
                          child: const Column(
                            children: [
                              SizedBox(height: 8),
                              SearchBarWidget(),
                            ],
                          ),
                        );
                      },
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
                                  _buildFab(
                                    icon: Icons.my_location_rounded,
                                    onTap: provider.goToMyLocation,
                                    tooltip: 'Vị trí của tôi',
                                  ),
                                  if (provider.currentRoute != null) ...[
                                    const SizedBox(height: 8),
                                    _buildFab(
                                      icon: Icons.close_rounded,
                                      onTap: provider.clearAll,
                                      tooltip: 'Xóa đường đi',
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
                  const RouteInfoCard(),
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
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 220,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F0F1E).withValues(alpha: 0.95),
                const Color(0xFF0F0F1E).withValues(alpha: 0.6),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: const Color(0xFF0F0F1E),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E3A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF00E5FF),
                  strokeWidth: 2.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang xác định vị trí...',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
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
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                ),
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
                      fontWeight: FontWeight.w500,
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
}

class _OptimizedMapWidget extends StatelessWidget {
  const _OptimizedMapWidget();

  List<Marker> _buildMarkers(
    LatLng currentPosition,
    PlaceModel? originPlace,
    PlaceModel? destinationPlace,
  ) {
    final markers = <Marker>[];

    markers.add(
      Marker(
        point: currentPosition,
        width: 40,
        height: 40,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00E5FF),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (originPlace != null) {
      markers.add(
        Marker(
          point: originPlace.latLng,
          width: 120,
          height: 65,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.3)),
                ),
                child: Text(
                  originPlace.name,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.location_on_rounded, color: Color(0xFF00E676), size: 30),
            ],
          ),
        ),
      );
    }

    if (destinationPlace != null) {
      markers.add(
        Marker(
          point: destinationPlace.latLng,
          width: 120,
          height: 65,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.3)),
                ),
                child: Text(
                  destinationPlace.name,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.location_on_rounded, color: Color(0xFFFF5252), size: 30),
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

    return Selector<MapProvider, ({
      RouteModel? route,
      LatLng position,
      PlaceModel? origin,
      PlaceModel? destination,
    })>(
      selector: (_, p) => (
        route: p.currentRoute,
        position: p.currentPosition,
        origin: p.originPlace,
        destination: p.destinationPlace,
      ),
      builder: (context, data, _) {
        return FlutterMap(
          mapController: provider.mapController,
          options: MapOptions(
            initialCenter: const LatLng(ApiConfig.defaultLat, ApiConfig.defaultLng),
            initialZoom: 13,
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
              userAgentPackageName: 'com.personal.google_maps_app',
            ),
            if (data.route != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: data.route!.polylinePoints,
                    strokeWidth: 5.0,
                    color: const Color(0xFF00E5FF),
                    borderColor: const Color(0xFF0091FF).withValues(alpha: 0.5),
                    borderStrokeWidth: 1.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers: _buildMarkers(data.position, data.origin, data.destination),
            ),
          ],
        );
      },
    );
  }
}
