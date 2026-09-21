import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Traffic Status
// ─────────────────────────────────────────────────────────────────────────────

enum TrafficStatus { smooth, slow, moderate, heavy }

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

    final distM = (json['routeOffsetInMeters'] as num? ?? 0);
    final durS = (json['travelTimeInSeconds'] as num? ?? 0);

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
    final distM = json['distance'] as num? ?? 0;
    final durS = json['duration'] as num? ?? 0;

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
    if (m.contains('UTURN') || m.contains('U_TURN')) return '↩';
    if (m.contains('ROUNDABOUT')) return '🔄';
    if (m.contains('ARRIVE')) return '🏁';
    if (m.contains('DEPART')) return '🚀';
    if (m.contains('MOTORWAY') || m.contains('FREEWAY')) return '🛣️';
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
        return '↩';
      case 'roundabout':
        return '🔄';
      case 'arrive':
        return '🏁';
      case 'depart':
        return '🚀';
      default:
        return '⬆';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RouteModel
// ─────────────────────────────────────────────────────────────────────────────

class RouteModel {
  final String totalDistance;
  final String totalDuration;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
  final List<RouteStep> steps;
  final List<LatLng> polylinePoints;
  final String summary;

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
    this.trafficDelayInSeconds = 0,
    this.trafficLengthInMeters = 0,
  });

  // ── ETA (giờ đến dự kiến) ────────────────────────────────────────────────
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
    final int durS =
        (routeSummary['travelTimeInSeconds'] as num? ?? 0).toInt();
    final int trafficDelay =
        (routeSummary['trafficDelayInSeconds'] as num? ?? 0).toInt();
    final int trafficLen =
        (routeSummary['trafficLengthInMeters'] as num? ?? 0).toInt();

    // ── Parse polyline từ legs[0].points ──
    final List<LatLng> polylinePoints = [];
    final legs = route['legs'] as List?;
    if (legs != null && legs.isNotEmpty) {
      final leg = legs[0] as Map<String, dynamic>;
      final points = leg['points'] as List?;
      if (points != null) {
        for (final p in points) {
          final point = p as Map<String, dynamic>;
          final lat = (point['latitude'] as num?)?.toDouble();
          final lon = (point['longitude'] as num?)?.toDouble();
          if (lat != null && lon != null) {
            polylinePoints.add(LatLng(lat, lon));
          }
        }
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
    final durS = (route['duration'] as num? ?? 0).toInt();

    List<RouteStep> steps = [];
    final legs = route['legs'] as List?;
    if (legs != null && legs.isNotEmpty) {
      final leg = legs[0] as Map<String, dynamic>;
      final legSteps = leg['steps'] as List?;
      if (legSteps != null) {
        steps = legSteps
            .map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
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
      polylinePoints: decodedPolyline,
      summary: route['name']?.toString() ?? '',
    );
  }
}
