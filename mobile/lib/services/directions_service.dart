import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../config/api_config.dart';

enum TravelMode { car, bike, foot }

class DirectionsService {
  /// Chuyển TravelMode → TomTom travelMode string
  String _travelModeString(TravelMode mode) {
    switch (mode) {
      case TravelMode.car:
        return 'car';
      case TravelMode.bike:
        return 'bicycle';
      case TravelMode.foot:
        return 'pedestrian';
    }
  }

  /// Tính đường đi ngắn nhất theo đường thực tế sử dụng TomTom Routing API.
  Future<RouteModel?> getDirections({
    required LatLng origin,
    required LatLng destination,
    TravelMode mode = TravelMode.car,
  }) async {
    final apiKey = ApiConfig.tomTomApiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_TOMTOM_API_KEY_HERE') {
      debugPrint('❌ TomTom API key chưa được cấu hình trong .env');
      return null;
    }

    final waypoints =
        '${origin.latitude},${origin.longitude}:${destination.latitude},${destination.longitude}';

    final travelMode = _travelModeString(mode);

    final uri = Uri.parse(
      '${ApiConfig.tomTomRoutingBase}/$waypoints/json'
      '?key=$apiKey'
      '&travelMode=$travelMode'
      '&routeType=shortest'
      '&traffic=true'
      '&instructionsType=text'
      '&language=vi-VN'
      '&sectionType=traffic'
      '&report=effectiveSettings',
    );

    try {
      debugPrint('🗺️ TomTom Routing: $waypoints ($travelMode)');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        return RouteModel.fromTomTomJson(data);
      } else {
        debugPrint('❌ TomTom Routing status: ${response.statusCode}');
        debugPrint('❌ Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ DirectionsService TomTom error: $e');
    }
    return null;
  }
}
