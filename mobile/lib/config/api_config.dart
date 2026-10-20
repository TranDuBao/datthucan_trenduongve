import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // ── TomTom API ──────────────────────────────────────────────────────────
  static const String _compileTimeTomTomKey =
      String.fromEnvironment('TOMTOM_API_KEY');

  static String get tomTomApiKey {
    if (_compileTimeTomTomKey.isNotEmpty) {
      return _compileTimeTomTomKey;
    }
    try {
      if (dotenv.isInitialized) {
        return dotenv.env['TOMTOM_API_KEY'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  /// TomTom Routing API base URL
  static const String tomTomRoutingBase =
      'https://api.tomtom.com/routing/1/calculateRoute';

  /// TomTom Fuzzy Search (Autocomplete) base URL
  static const String tomTomSearchBase =
      'https://api.tomtom.com/search/2/search';

  /// TomTom Reverse Geocoding base URL
  static const String tomTomReverseBase =
      'https://api.tomtom.com/search/2/reverseGeocode';

  // ── Map Tiles (Google Maps Tiles — 100% sạch, không watermark, tải cực nhanh) ───
  static const String lightTileUrl =
      'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';

  static const String fallbackTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String darkTileUrl =
      'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';

  // ── Default location (Trần Quý Cáp, Bình Thạnh, TP. Hồ Chí Minh) ────────
  static const double defaultLat = 10.8038;
  static const double defaultLng = 106.6975;
}
