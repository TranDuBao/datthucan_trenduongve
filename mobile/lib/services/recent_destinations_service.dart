import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';

class RecentDestinationsService {
  static const String _storageKey = 'foodroute_recent_destinations_v1';
  static const int maxRecent = 4;
  static List<PlaceModel>? _cached;

  static Future<List<PlaceModel>> getRecentDestinations() async {
    if (_cached != null) return _cached!;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        _cached = [];
        return _cached!;
      }
      final List<dynamic> list = json.decode(jsonStr);
      _cached = list.map((item) {
        final map = item as Map<String, dynamic>;
        return PlaceModel(
          id: map['id']?.toString() ?? '',
          name: map['name']?.toString() ?? '',
          address: map['address']?.toString() ?? '',
          latLng: LatLng(
            (map['lat'] as num?)?.toDouble() ?? 0.0,
            (map['lng'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      }).where((p) => p.name.isNotEmpty && (p.latLng.latitude != 0 || p.latLng.longitude != 0)).toList();
      return _cached!;
    } catch (_) {
      _cached = [];
      return _cached!;
    }
  }

  static Future<List<PlaceModel>> addRecentDestination(PlaceModel place) async {
    if (place.name.isEmpty) return _cached ?? [];
    try {
      final list = List<PlaceModel>.from(await getRecentDestinations());
      list.removeWhere((p) =>
          p.name.trim().toLowerCase() == place.name.trim().toLowerCase() ||
          ((p.latLng.latitude - place.latLng.latitude).abs() < 0.0001 &&
           (p.latLng.longitude - place.latLng.longitude).abs() < 0.0001));

      list.insert(0, place);
      final trimmed = list.take(maxRecent).toList();
      _cached = trimmed;

      final prefs = await SharedPreferences.getInstance();
      final dataToSave = trimmed.map((p) => {
        'id': p.id,
        'name': p.name,
        'address': p.address,
        'lat': p.latLng.latitude,
        'lng': p.latLng.longitude,
      }).toList();

      await prefs.setString(_storageKey, json.encode(dataToSave));
      return trimmed;
    } catch (_) {
      return _cached ?? [];
    }
  }

  static Future<void> clearRecentDestinations() async {
    _cached = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}

