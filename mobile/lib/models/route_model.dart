import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Traffic Status
// ─────────────────────────────────────────────────────────────────────────────

enum TrafficStatus { smooth, slow, moderate, heavy }

/// Điều chỉnh thời gian di chuyển phù hợp với vận tốc thực tế đô thị Việt Nam (TP.HCM / Hà Nội):
/// Vận tốc trung bình trong phố ~25 km/h do mật độ xe máy, giao lộ và đèn đỏ.
int adjustDurationForVietnamTraffic(int distanceMeters, int rawDurationSeconds) {
  if (distanceMeters <= 0) return rawDurationSeconds;
  final int realisticSec = (distanceMeters / (25.0 * 1000.0 / 3600.0)).round();
  final int scaledSec = (rawDurationSeconds * 1.85).round();
  return scaledSec > realisticSec ? scaledSec : realisticSec;
}

// ─────────────────────────────────────────────────────────────────────────────
// RouteStep
// ─────────────────────────────────────────────────────────────────────────────

class RouteStep {
  final String instruction;
  final String distance;
  final String duration;
  final String maneuver;

  RouteStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.maneuver,
  });

  // ── TomTom Guidance Instruction ─────────────────────────────────────────
  factory RouteStep.fromTomTomInstruction(Map<String, dynamic> json) {
    final maneuver = json['maneuver']?.toString() ?? '';
    final message = json['message']?.toString() ??
        json['combinedMessage']?.toString() ??
        '';
    final street = json['street']?.toString() ?? '';

    final String instruction = message.isNotEmpty
        ? message
        : _buildInstructionFromManeuver(maneuver, street);

    final distM = (json['routeOffsetInMeters'] as num? ?? 0).toInt();
    final rawDurS = (json['travelTimeInSeconds'] as num? ?? 0).toInt();
    final durS = adjustDurationForVietnamTraffic(distM, rawDurS);

    return RouteStep(
      instruction: instruction,
      distance: distM >= 1000
          ? '${(distM / 1000).toStringAsFixed(1)} km'
          : '${distM.toInt()} m',
      duration: durS >= 3600
          ? '${(durS / 3600).toInt()} giờ ${((durS % 3600) / 60).toInt()} phút'
          : '${(durS / 60).toInt()} phút',
      maneuver: maneuver,
    );
  }

  // ── OSRM Instruction (legacy) ────────────────────────────────────────────
  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final distM = (json['distance'] as num? ?? 0).toInt();
    final rawDurS = (json['duration'] as num? ?? 0).toInt();
    final durS = adjustDurationForVietnamTraffic(distM, rawDurS);

    final maneuverObj = json['maneuver'] as Map<String, dynamic>? ?? {};
    final type = maneuverObj['type']?.toString() ?? '';
    final modifier = maneuverObj['modifier']?.toString() ?? '';
    final streetName = json['name']?.toString() ?? '';

    String instructionText = '';
    if (type == 'depart') {
      instructionText =
          'Khởi hành ${streetName.isNotEmpty ? 'từ $streetName' : ''}';
    } else if (type == 'arrive') {
      instructionText = 'Đến điểm đích';
    } else if (type == 'turn' || type == 'ramp' || type == 'fork') {
      final direction = _translateModifier(modifier);
      instructionText =
          '$direction ${streetName.isNotEmpty ? 'vào $streetName' : ''}';
    } else if (type == 'uturn') {
      instructionText =
          'Quay đầu xe ${streetName.isNotEmpty ? 'vào $streetName' : ''}';
    } else if (type == 'roundabout') {
      instructionText =
          'Đi vào vòng xuyến ${streetName.isNotEmpty ? 'vào $streetName' : ''}';
    } else {
      instructionText =
          'Đi thẳng ${streetName.isNotEmpty ? 'vào $streetName' : ''}';
    }

    return RouteStep(
      instruction: instructionText,
      distance: distM >= 1000
          ? '${(distM / 1000).toStringAsFixed(1)} km'
          : '${distM.toInt()} m',
      duration: durS >= 3600
          ? '${(durS / 3600).toInt()} giờ ${((durS % 3600) / 60).toInt()} phút'
          : '${(durS / 60).toInt()} phút',
      maneuver: modifier.isNotEmpty ? modifier : type,
    );
  }

  static String _buildInstructionFromManeuver(String maneuver, String street) {
    final streetPart = street.isNotEmpty ? ' vào $street' : '';
    switch (maneuver) {
      case 'DEPART':
        return 'Khởi hành$streetPart';
      case 'ARRIVE':
      case 'ARRIVE_LEFT':
      case 'ARRIVE_RIGHT':
        return 'Đến điểm đích';
      case 'TURN_LEFT':
        return 'Rẽ trái$streetPart';
      case 'TURN_RIGHT':
        return 'Rẽ phải$streetPart';
      case 'KEEP_LEFT':
      case 'BEAR_LEFT':
        return 'Chếch sang trái$streetPart';
      case 'KEEP_RIGHT':
      case 'BEAR_RIGHT':
        return 'Chếch sang phải$streetPart';
      case 'MAKE_UTURN':
        return 'Quay đầu xe$streetPart';
      case 'ENTER_MOTORWAY':
      case 'ENTER_FREEWAY':
        return 'Vào đường cao tốc$streetPart';
      case 'TAKE_EXIT':
        return 'Ra khỏi đường cao tốc$streetPart';
      case 'ENTER_ROUNDABOUT':
        return 'Đi vào vòng xuyến$streetPart';
      case 'LEAVE_ROUNDABOUT':
        return 'Ra khỏi vòng xuyến$streetPart';
      case 'STRAIGHT':
      case 'FOLLOW':
      default:
        return 'Đi thẳng$streetPart';
    }
  }

  static String _translateModifier(String modifier) {
    switch (modifier) {
      case 'left':
        return 'Rẽ trái';
      case 'right':
        return 'Rẽ phải';
      case 'slight left':
        return 'Chếch sang trái';
      case 'slight right':
        return 'Chếch sang phải';
      case 'sharp left':
        return 'Rẽ ngoặt bên trái';
      case 'sharp right':
        return 'Rẽ ngoặt bên phải';
      case 'straight':
        return 'Đi thẳng';
      default:
        return 'Đi tiếp';
    }
  }

  String get maneuverIcon {
    final m = maneuver.toUpperCase();
    if (m.contains('LEFT')) return '↰';
    if (m.contains('RIGHT')) return '↱';
    if (m.contains('UTURN') || m.contains('U_TURN')) return '⮌';
    if (m.contains('ROUNDABOUT')) return '↺';
    if (m.contains('ARRIVE')) return '⇥';
    if (m.contains('DEPART')) return '↑';
    if (m.contains('MOTORWAY') || m.contains('FREEWAY')) return '⇈';
    switch (maneuver) {
      case 'left':
      case 'slight left':
      case 'sharp left':
        return '↰';
      case 'right':
      case 'slight right':
      case 'sharp right':
        return '↱';
      case 'uturn':
        return '⮌';
      case 'roundabout':
        return '↺';
      case 'arrive':
        return '⇥';
      case 'depart':
        return '↑';
      default:
        return '↑';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RouteModel
// ─────────────────────────────────────────────────────────────────────────────

class RouteLeg {
  final String distance;
  final String duration;
  final int distanceMeters;
  final int durationSeconds;
  final List<LatLng> polylinePoints;

  RouteLeg({
    required this.distance,
    required this.duration,
    required this.distanceMeters,
    required this.durationSeconds,
    this.polylinePoints = const [],
  });
}

class RouteModel {
  final String totalDistance;
  final String totalDuration;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
  final List<RouteStep> steps;
  final List<LatLng> polylinePoints;
  final String summary;
  final List<RouteLeg> legs;

  // ── Traffic info (từ TomTom) ─────────────────────────────────────────────
  final int trafficDelayInSeconds;
  final int trafficLengthInMeters;

  RouteModel({
    required this.totalDistance,
    required this.totalDuration,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.steps,
    required this.polylinePoints,
    required this.summary,
    this.legs = const [],
    this.trafficDelayInSeconds = 0,
    this.trafficLengthInMeters = 0,
  });

  List<LatLng>? _cachedSimplifiedPoints;

  /// Danh sách tọa độ đã được tối ưu hóa (decimated) giúp render GPU/Raster cực mượt, tránh giật lag bản đồ
  List<LatLng> get simplifiedPolylinePoints {
    if (_cachedSimplifiedPoints != null) return _cachedSimplifiedPoints!;
    if (polylinePoints.length <= 150) {
      _cachedSimplifiedPoints = polylinePoints;
      return _cachedSimplifiedPoints!;
    }
    final result = <LatLng>[polylinePoints.first];
    const double deg2m = 111000.0;
    for (int i = 1; i < polylinePoints.length - 1; i++) {
      final prev = result.last;
      final curr = polylinePoints[i];
      final dLat = (curr.latitude - prev.latitude) * deg2m;
      final dLon = (curr.longitude - prev.longitude) * deg2m;
      if (dLat * dLat + dLon * dLon >= 324.0) {
        result.add(curr);
      }
    }
    result.add(polylinePoints.last);
    _cachedSimplifiedPoints = result;
    return result;
  }
  /// Giờ đến dự kiến = giờ hiện tại + thời gian di chuyển
  String get etaText {
    final eta = DateTime.now().add(Duration(seconds: totalDurationSeconds));
    final h = eta.hour.toString().padLeft(2, '0');
    final m = eta.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Traffic status ────────────────────────────────────────────────────────
  TrafficStatus get trafficStatus {
    if (trafficDelayInSeconds < 60) return TrafficStatus.smooth;
    if (trafficDelayInSeconds < 300) return TrafficStatus.slow;
    if (trafficDelayInSeconds < 600) return TrafficStatus.moderate;
    return TrafficStatus.heavy;
  }

  String get trafficLabel {
    switch (trafficStatus) {
      case TrafficStatus.smooth:
        return 'Thông thoáng';
      case TrafficStatus.slow:
        return 'Chậm';
      case TrafficStatus.moderate:
        return 'Ùn tắc nhẹ';
      case TrafficStatus.heavy:
        return 'Ùn tắc nặng';
    }
  }

  String get trafficDelayText {
    if (trafficDelayInSeconds < 60) return '';
    if (trafficDelayInSeconds < 3600) {
      return '+${(trafficDelayInSeconds / 60).toInt()} phút';
    }
    return '+${(trafficDelayInSeconds / 3600).toStringAsFixed(1)} giờ';
  }

  // ── TomTom Routing API ───────────────────────────────────────────────────
  factory RouteModel.fromTomTomJson(Map<String, dynamic> json) {
    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('TomTom: Không tìm thấy tuyến đường');
    }

    final route = routes[0] as Map<String, dynamic>;
    final routeSummary = route['summary'] as Map<String, dynamic>? ?? {};

    final int distM =
        (routeSummary['lengthInMeters'] as num? ?? 0).toInt();
    final int rawDurS =
        (routeSummary['travelTimeInSeconds'] as num? ?? 0).toInt();
    final int durS = adjustDurationForVietnamTraffic(distM, rawDurS);
    final int trafficDelay =
        (routeSummary['trafficDelayInSeconds'] as num? ?? 0).toInt();
    final int trafficLen =
        (routeSummary['trafficLengthInMeters'] as num? ?? 0).toInt();

    // ── Parse polyline và các chặng (legs) ──
    final List<LatLng> polylinePoints = [];
    final List<RouteLeg> legsList = [];
    final legs = route['legs'] as List?;
    if (legs != null && legs.isNotEmpty) {
      for (final legObj in legs) {
        final leg = legObj as Map<String, dynamic>;
        final legSummary = leg['summary'] as Map<String, dynamic>? ?? {};
        final int lDistM = (legSummary['lengthInMeters'] as num? ?? 0).toInt();
        final int rawLDurS = (legSummary['travelTimeInSeconds'] as num? ?? 0).toInt();
        final int lDurS = adjustDurationForVietnamTraffic(lDistM, rawLDurS);
        final List<LatLng> legPoints = [];
        final points = leg['points'] as List?;
        if (points != null) {
          for (final p in points) {
            final point = p as Map<String, dynamic>;
            final lat = (point['latitude'] as num?)?.toDouble();
            final lon = (point['longitude'] as num?)?.toDouble();
            if (lat != null && lon != null) {
              final pt = LatLng(lat, lon);
              legPoints.add(pt);
              polylinePoints.add(pt);
            }
          }
        }
        final String lDistStr = lDistM >= 1000
            ? '${(lDistM / 1000).toStringAsFixed(1)} km'
            : '$lDistM m';
        final String lDurStr = lDurS >= 3600
            ? '${(lDurS / 3600).toInt()} giờ ${((lDurS % 3600) / 60).toInt()} phút'
            : '${(lDurS / 60).toInt()} phút';

        legsList.add(RouteLeg(
          distance: lDistStr,
          duration: lDurStr,
          distanceMeters: lDistM,
          durationSeconds: lDurS,
          polylinePoints: legPoints,
        ));
      }
    }

    // ── Parse guidance instructions ──
    List<RouteStep> steps = [];
    final guidance = route['guidance'] as Map<String, dynamic>?;
    if (guidance != null) {
      final instructions = guidance['instructions'] as List?;
      if (instructions != null) {
        steps = instructions
            .map((i) =>
                RouteStep.fromTomTomInstruction(i as Map<String, dynamic>))
            .toList();
      }
    }

    final String distStr = distM >= 1000
        ? '${(distM / 1000).toStringAsFixed(1)} km'
        : '$distM m';
    final String durStr = durS >= 3600
        ? '${(durS / 3600).toInt()} giờ ${((durS % 3600) / 60).toInt()} phút'
        : '${(durS / 60).toInt()} phút';

    return RouteModel(
      totalDistance: distStr,
      totalDuration: durStr,
      totalDistanceMeters: distM,
      totalDurationSeconds: durS,
      steps: steps,
      polylinePoints: polylinePoints,
      legs: legsList,
      summary: routeSummary['departureTime']?.toString() ?? '',
      trafficDelayInSeconds: trafficDelay,
      trafficLengthInMeters: trafficLen,
    );
  }

  // ── OSRM (legacy) ────────────────────────────────────────────────────────
  factory RouteModel.fromOSRMJson(
      Map<String, dynamic> json, List<LatLng> decodedPolyline) {
    final routes = json['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception('No routes found');
    }

    final route = routes[0] as Map<String, dynamic>;
    final distM = (route['distance'] as num? ?? 0).toInt();
    final rawDurS = (route['duration'] as num? ?? 0).toInt();
    final durS = adjustDurationForVietnamTraffic(distM, rawDurS);

    List<RouteStep> steps = [];
    final List<RouteLeg> legsList = [];
    final legs = route['legs'] as List?;
    if (legs != null && legs.isNotEmpty) {
      for (final legObj in legs) {
        final leg = legObj as Map<String, dynamic>;
        final int lDistM = (leg['distance'] as num? ?? 0).toInt();
        final int rawLDurS = (leg['duration'] as num? ?? 0).toInt();
        final int lDurS = adjustDurationForVietnamTraffic(lDistM, rawLDurS);
        final String lDistStr = lDistM >= 1000
            ? '${(lDistM / 1000).toStringAsFixed(1)} km'
            : '$lDistM m';
        final String lDurStr = lDurS >= 3600
            ? '${(lDurS / 3600).toInt()} giờ ${((lDurS % 3600) / 60).toInt()} phút'
            : '${(lDurS / 60).toInt()} phút';

        final List<LatLng> legPoints = [];
        final legSteps = leg['steps'] as List?;
        if (legSteps != null) {
          for (final st in legSteps) {
            final geom = (st as Map)['geometry'] as Map<String, dynamic>?;
            final coords = geom?['coordinates'] as List?;
            if (coords != null) {
              for (final c in coords) {
                if (c is List && c.length >= 2) {
                  final lon = (c[0] as num).toDouble();
                  final lat = (c[1] as num).toDouble();
                  legPoints.add(LatLng(lat, lon));
                }
              }
            }
          }
          if (steps.isEmpty) {
            steps = legSteps
                .map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
                .toList();
          }
        }

        legsList.add(RouteLeg(
          distance: lDistStr,
          duration: lDurStr,
          distanceMeters: lDistM,
          durationSeconds: lDurS,
          polylinePoints: legPoints,
        ));
      }
    }

    final String distStr = distM >= 1000
        ? '${(distM / 1000).toStringAsFixed(1)} km'
        : '$distM m';
    final String durStr = durS >= 3600
        ? '${(durS / 3600).toInt()} giờ ${((durS % 3600) / 60).toInt()} phút'
        : '${(durS / 60).toInt()} phút';

    return RouteModel(
      totalDistance: distStr,
      totalDuration: durStr,
      totalDistanceMeters: distM,
      totalDurationSeconds: durS,
      steps: steps,
      polylinePoints: decodedPolyline,
      legs: legsList,
      summary: route['name']?.toString() ?? '',
    );
  }
}
