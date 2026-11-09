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

  // ── Map Tiles (OpenStreetMap Mirror & Display) ──────────────────────────
  static String get lightTileUrl {
    final key = tomTomApiKey;
    if (key.isNotEmpty) {
      return 'https://api.tomtom.com/map/1/tile/basic/main/{z}/{x}/{y}.png?key=$key';
    }
    return 'https://tile.openstreetmap.de/{z}/{x}/{y}.png';
  }

  static const String fallbackTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static String get darkTileUrl {
    final key = tomTomApiKey;
    if (key.isNotEmpty) {
      return 'https://api.tomtom.com/map/1/tile/basic/night/{z}/{x}/{y}.png?key=$key';
    }
    return 'https://tile.openstreetmap.de/{z}/{x}/{y}.png';
  }

  // ── Default location (Trần Quý Cáp, Bình Thạnh, TP. Hồ Chí Minh) ────────
  static const double defaultLat = 10.8038;
  static const double defaultLng = 106.6975;
}
