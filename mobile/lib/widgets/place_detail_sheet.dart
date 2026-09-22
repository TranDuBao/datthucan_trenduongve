import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/place_model.dart';
import '../providers/map_provider.dart';
import '../config/api_config.dart';
import '../common_widget/custom_modal_alert.dart';

class PlaceDetailSheet extends StatefulWidget {
  final PlaceModel place;
  final MapProvider provider;

  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.provider,
  });

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  bool _imageLoaded = false;

  String get _poiPhotoUrl =>
      'https://api.tomtom.com/search/2/poiPhoto'
      '?id=${widget.place.id}'
      '&key=${ApiConfig.tomTomApiKey}'
      '&width=800&height=400';

  String get _staticMapUrl {
    final lat = widget.place.latLng.latitude;
    final lon = widget.place.latLng.longitude;
    return 'https://staticmap.openstreetmap.de/staticmap.php'
        '?center=$lat,$lon'
        '&zoom=16'
        '&size=600x300'
        '&markers=$lat,$lon,red-pushpin';
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A35),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildImageHeader(),
          _buildPlaceInfo(),
          _buildDivider(),
          _buildActions(context),
          SizedBox(height: bottomPad + 12),
        ],
      ),
    );
  }

  Widget _buildHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _buildImageHeader() {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          height: 170,
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF2D2D5E),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _poiPhotoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) {
                    if (!_imageLoaded) {
                      WidgetsBinding.instance.addPostFrameCallback(
                          (_) => setState(() => _imageLoaded = true));
                    }
                    return child;
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildStaticMapFallback(),
                      Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00E5FF),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ],
                  );
                },
                errorBuilder: (ctx, err, st) {
                  return _buildStaticMapFallback();
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 80,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF1A1A35).withValues(alpha: 0.95),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    widget.place.typeLabel,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 14,
                right: 14,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Text(
                    widget.place.name,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        const Shadow(
                          color: Colors.black,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaticMapFallback() {
    return Image.network(
      _staticMapUrl,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return _buildGradientPlaceholder();
      },
      errorBuilder: (ctx, err, st) {
        return _buildGradientPlaceholder();
      },
    );
  }

  Widget _buildGradientPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF0D1B3E)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.place.typeLabel.split(' ').first,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              widget.place.name,
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFF00E5FF),
            text: widget.place.address,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              final coord =
                  '${widget.place.latLng.latitude.toStringAsFixed(6)}, '
                  '${widget.place.latLng.longitude.toStringAsFixed(6)}';
              Clipboard.setData(ClipboardData(text: coord));
              CustomModalAlert.show(
                context: context,
                title: 'Đã sao chép!',
                message: 'Đã sao chép tọa độ địa điểm vào bộ nhớ tạm: $coord',
                infoTag: 'Tọa độ GPS',
                buttonTitle: 'Hoàn tất',
              );
            },
            child: _infoRow(
              icon: Icons.pin_drop_outlined,
              iconColor: Colors.white.withValues(alpha: 0.4),
              text:
                  '${widget.place.latLng.latitude.toStringAsFixed(5)},  '
                  '${widget.place.latLng.longitude.toStringAsFixed(5)}',
              textColor: Colors.white.withValues(alpha: 0.4),
              trailing: Icon(Icons.copy_rounded,
                  size: 13, color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    Color? textColor,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.outfit(
              color: textColor ?? Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildDivider() => Divider(
        color: Colors.white.withValues(alpha: 0.07),
        height: 28,
        indent: 20,
        endIndent: 20,
      );

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          _actionButton(
            label: 'Chỉ đường đến đây',
            icon: Icons.navigation_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF0091FF)],
            ),
            onTap: () {
              Navigator.pop(context);
              widget.provider
                  .selectPlace(widget.place, isOrigin: false);
            },
          ),
          const SizedBox(height: 10),
          _actionButton(
            label: 'Đặt làm điểm bắt đầu',
            icon: Icons.trip_origin_rounded,
            iconColor: const Color(0xFF00E676),
            bgColor: Colors.white.withValues(alpha: 0.07),
            borderColor: Colors.white.withValues(alpha: 0.12),
            onTap: () {
              Navigator.pop(context);
              widget.provider
                  .selectPlace(widget.place, isOrigin: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Gradient? gradient,
    Color? bgColor,
    Color? borderColor,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border:
              borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
