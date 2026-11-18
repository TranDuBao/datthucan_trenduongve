import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import '../common/globs.dart';
import '../common/service_call.dart';
import '../models/place_model.dart';

class RecentDestinationsService {
  static const int maxRecent = 4;
  static List<PlaceModel>? _cached;
  static String? _cachedUserId;

  static String _getCurrentUserId() {
    final payload = ServiceCall.userPayload.isNotEmpty
        ? ServiceCall.userPayload
        : Globs.udValue(Globs.userPayload);
    if (payload is Map) {
      final userId = (payload['user_id'] ??
              payload['id'] ??
              payload['maTaiKhoan'] ??
              payload['user']?['id'] ??
              payload['user']?['maTaiKhoan'])
          ?.toString();
      if (userId != null && userId.isNotEmpty && userId != '0') {
        return userId;
      }
    }
    return 'guest';
  }

  static String _getStorageKey() {
    final uid = _getCurrentUserId();
    return 'foodroute_recent_destinations_u_$uid';
  }

  static void invalidateCache() {
    _cached = null;
    _cachedUserId = null;
  }

  static Future<List<PlaceModel>> getRecentDestinations() async {
    final currentUid = _getCurrentUserId();
    if (_cached != null && _cachedUserId == currentUid) {
      return _cached!;
    }

    _cachedUserId = currentUid;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey();
      final jsonStr = prefs.getString(key);
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
      _cachedUserId = _getCurrentUserId();

      final prefs = await SharedPreferences.getInstance();
      final dataToSave = trimmed.map((p) => {
        'id': p.id,
        'name': p.name,
        'address': p.address,
        'lat': p.latLng.latitude,
        'lng': p.latLng.longitude,
      }).toList();

      await prefs.setString(_getStorageKey(), json.encode(dataToSave));
      return trimmed;
    } catch (_) {
      return _cached ?? [];
    }
  }

  static Future<void> clearRecentDestinations() async {
    _cached = [];
    _cachedUserId = _getCurrentUserId();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getStorageKey());
    } catch (_) {}
  }
}

