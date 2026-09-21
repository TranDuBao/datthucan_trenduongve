import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import '../config/api_config.dart';

class PlacesService {
  /// Tìm kiếm địa điểm với 3 tầng tự động: TomTom Search → Photon OSM → Nominatim OSM
  Future<List<PlaceModel>> getAutocompleteSuggestions(
    String input, {
    LatLng? biasLocation,
  }) async {
    final queryText = input.trim();
    if (queryText.isEmpty) return [];

    List<PlaceModel> results = [];

    // 1. Thử tìm bằng TomTom API
    final apiKey = ApiConfig.tomTomApiKey;
    if (apiKey.isNotEmpty && apiKey != 'YOUR_TOMTOM_API_KEY_HERE') {
      final queryParams = <String, String>{
        'key': apiKey,
        'limit': '10',
        'language': 'vi-VN',
        'countrySet': 'VN',
        'typeahead': 'true',
        'radius': '50000',
      };

      if (biasLocation != null &&
          biasLocation.latitude >= 8.0 &&
          biasLocation.latitude <= 24.0 &&
          biasLocation.longitude >= 102.0 &&
          biasLocation.longitude <= 110.0) {
        queryParams['lat'] = biasLocation.latitude.toString();
        queryParams['lon'] = biasLocation.longitude.toString();
      }

      // Encode queryText đúng chuẩn URL path
      final encodedPath = Uri.encodeComponent(queryText);
      final uri = Uri.parse(
        'https://api.tomtom.com/search/2/search/$encodedPath.json',
      ).replace(queryParameters: queryParams);

      try {
        debugPrint('🔍 TomTom Search URI: $uri');
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final Map<String, dynamic> data =
              json.decode(utf8.decode(response.bodyBytes));
          final List<dynamic> tomTomResults = data['results'] as List? ?? [];
          results = tomTomResults
              .map((item) =>
                  PlaceModel.fromTomTomJson(item as Map<String, dynamic>))
              .toList();
          debugPrint('   → TomTom trả về ${results.length} kết quả');
        } else {
          debugPrint('❌ TomTom Search status: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        debugPrint('❌ PlacesService TomTom search error: $e');
      }
    }

    // 2. Nếu TomTom trả về rỗng (hoặc gõ tiếng Việt không dấu như "dai hoc"), 
    //    tự động Fallback sang Photon OpenStreetMap Search API
    if (results.isEmpty) {
      results = await _searchPhoton(queryText, biasLocation: biasLocation);
    }

    // 3. Nếu vẫn rỗng, fallback sang Nominatim OpenStreetMap Search
    if (results.isEmpty) {
      results = await _searchNominatim(queryText);
    }

    return results;
  }

  /// Photon (OpenStreetMap) Search Fallback — kèm User-Agent header (tránh lỗi HTTP 403)
  Future<List<PlaceModel>> _searchPhoton(String input, {LatLng? biasLocation}) async {
    final lat = biasLocation?.latitude ?? 10.7769;
    final lon = biasLocation?.longitude ?? 106.7009;
    final uri = Uri.parse(
      'https://photon.komoot.io/api/?q=${Uri.encodeComponent(input.trim())}&lat=$lat&lon=$lon&limit=10',
    );

    try {
      debugPrint('🌐 Photon OSM Fallback Search: "$input"');
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Mobile; FlutterApp/1.0; FoodDelivery)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> features = data['features'] as List? ?? [];
        debugPrint('   → Photon OSM trả về ${features.length} kết quả');
        return features
            .map((item) =>
                PlaceModel.fromPhotonJson(item as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('❌ Photon Search status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Photon Search error: $e');
    }
    return [];
  }

  /// Nominatim (OpenStreetMap) Search Fallback cho tìm kiếm không dấu tại Việt Nam
  Future<List<PlaceModel>> _searchNominatim(String input) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(input.trim())}&format=json&addressdetails=1&countrycodes=vn&limit=10',
    );

    try {
      debugPrint('🗺️ Nominatim OSM Fallback Search: "$input"');
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'FoodDeliveryApp/1.0 (contact@fooddelivery.app)',
          'Accept-Language': 'vi-VN,vi;q=0.9',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('   → Nominatim OSM trả về ${list.length} kết quả');
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          final lat = double.tryParse(map['lat']?.toString() ?? '0') ?? 0;
          final lon = double.tryParse(map['lon']?.toString() ?? '0') ?? 0;
          final displayName = map['display_name']?.toString() ?? '';
          final name = map['name']?.toString() ?? displayName.split(',').first;
          return PlaceModel(
            id: map['place_id']?.toString() ?? '$lat,$lon',
            name: name.isNotEmpty ? name : 'Địa điểm không tên',
            address: displayName,
            latLng: LatLng(lat, lon),
            type: map['type']?.toString(),
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('❌ Nominatim Search error: $e');
    }
    return [];
  }

  /// Reverse geocoding: tọa độ → địa chỉ (TomTom Reverse Geocoding API)
  Future<PlaceModel?> reverseGeocode(LatLng latLng) async {
    final apiKey = ApiConfig.tomTomApiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_TOMTOM_API_KEY_HERE') {
      debugPrint('❌ TomTom API key chưa được cấu hình trong .env');
      return null;
    }

    final uri = Uri.https(
      'api.tomtom.com',
      '/search/2/reverseGeocode/${latLng.latitude},${latLng.longitude}.json',
      {
        'key': apiKey,
        'language': 'vi-VN',
      },
    );

    try {
      debugPrint('📍 TomTom Reverse: ${latLng.latitude}, ${latLng.longitude}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> addresses = data['addresses'] as List? ?? [];
        if (addresses.isNotEmpty) {
          return PlaceModel.fromTomTomReverseJson(
              addresses[0] as Map<String, dynamic>);
        }
      } else {
        debugPrint('❌ TomTom Reverse status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ PlacesService TomTom reverse error: $e');
    }
    return null;
  }
}
