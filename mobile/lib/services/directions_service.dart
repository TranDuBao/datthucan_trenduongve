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

  /// Tính đường đi theo đường thực tế sử dụng TomTom Routing API (với fallback tự động sang OSRM).
  /// Hỗ trợ điểm dừng ghé quán qua tham số [stopover] (A -> Q -> B).
  bool _isInVietnam(LatLng p) =>
      p.latitude >= 8.0 && p.latitude <= 24.0 && p.longitude >= 102.0 && p.longitude <= 112.0;

  Future<RouteModel?> getDirections({
    required LatLng origin,
    required LatLng destination,
    LatLng? stopover,
    TravelMode mode = TravelMode.car,
  }) async {
    const defaultPos = LatLng(ApiConfig.defaultLat, ApiConfig.defaultLng);
    final safeOrigin = _isInVietnam(origin) ? origin : defaultPos;
    final safeDestination = _isInVietnam(destination) ? destination : defaultPos;
    final safeStopover = (stopover != null && _isInVietnam(stopover)) ? stopover : null;
    final apiKey = ApiConfig.tomTomApiKey;

    // 1. Thử qua TomTom Routing API nếu đã cấu hình API key
    if (apiKey.isNotEmpty && apiKey != 'YOUR_TOMTOM_API_KEY_HERE') {
      final String waypoints;
      if (safeStopover != null) {
        waypoints =
            '${safeOrigin.latitude},${safeOrigin.longitude}:${safeStopover.latitude},${safeStopover.longitude}:${safeDestination.latitude},${safeDestination.longitude}';
      } else {
        waypoints =
            '${safeOrigin.latitude},${safeOrigin.longitude}:${safeDestination.latitude},${safeDestination.longitude}';
      }

      final travelMode = _travelModeString(mode);

      final uri = Uri.parse(
        '${ApiConfig.tomTomRoutingBase}/$waypoints/json'
        '?key=$apiKey'
        '&travelMode=$travelMode'
        '&routeType=fastest'
        '&traffic=true'
        '&instructionsType=text'
        '&language=vi-VN'
        '&sectionType=traffic'
        '&report=effectiveSettings',
      );

      try {
        debugPrint('[DirectionsService] [Info] TomTom Routing: $waypoints ($travelMode)');
        final response = await http.get(uri).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          final Map<String, dynamic> data =
              json.decode(utf8.decode(response.bodyBytes));
          return RouteModel.fromTomTomJson(data);
        } else {
          debugPrint('[DirectionsService] [Warn] TomTom Routing status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('[DirectionsService] [Warn] DirectionsService TomTom error (sẽ fallback OSRM): $e');
      }
    }

    // 2. Fallback sang OSRM (Open Source Routing Machine) nếu TomTom lỗi hoặc hết hạn mức
    return _getDirectionsOSRM(
      origin: safeOrigin,
      destination: safeDestination,
      stopover: safeStopover,
    );
  }

  /// OSRM Routing Fallback
  Future<RouteModel?> _getDirectionsOSRM({
    required LatLng origin,
    required LatLng destination,
    LatLng? stopover,
  }) async {
    try {
      final String coordStr;
      if (stopover != null) {
        coordStr =
            '${origin.longitude},${origin.latitude};${stopover.longitude},${stopover.latitude};${destination.longitude},${destination.latitude}';
      } else {
        coordStr =
            '${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}';
      }

      final uri = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/$coordStr?overview=full&geometries=geojson&steps=true',
      );

      debugPrint('[DirectionsService] [Info] OSRM Routing Fallback: $coordStr');
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'SmartFoodRouteApp/1.0 (contact@smartfoodroute.app)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final firstRoute = routes[0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List?;

          final List<LatLng> polylinePoints = [];
          if (coordinates != null) {
            for (final c in coordinates) {
              if (c is List && c.length >= 2) {
                final lon = (c[0] as num).toDouble();
                final lat = (c[1] as num).toDouble();
                polylinePoints.add(LatLng(lat, lon));
              }
            }
          }

          return RouteModel.fromOSRMJson(data, polylinePoints);
        }
      } else {
        debugPrint('[DirectionsService] [Error] OSRM Routing error status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DirectionsService] [Error] DirectionsService OSRM error: $e');
    }
    return null;
  }
}
