import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  // ── TomTom API ──────────────────────────────────────────────────────────
  static String get tomTomApiKey =>
      dotenv.env['TOMTOM_API_KEY'] ?? '';

  /// TomTom Routing API base URL
  static const String tomTomRoutingBase =
      'https://api.tomtom.com/routing/1/calculateRoute';

  /// TomTom Fuzzy Search (Autocomplete) base URL
  static const String tomTomSearchBase =
      'https://api.tomtom.com/search/2/search';

  /// TomTom Reverse Geocoding base URL
  static const String tomTomReverseBase =
      'https://api.tomtom.com/search/2/reverseGeocode';

  // ── Map Tiles (OpenStreetMap — giữ miễn phí, không tốn TomTom quota) ───
  static const String lightTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String darkTileUrl =
      'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';

  // ── Default location (Trần Quý Cáp, Bình Thạnh, TP. Hồ Chí Minh) ────────
  static const double defaultLat = 10.8038;
  static const double defaultLng = 106.6975;
}
