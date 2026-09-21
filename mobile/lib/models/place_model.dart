import 'package:latlong2/latlong.dart';

class PlaceModel {
  final String id;
  final String name;
  final String address;
  final LatLng latLng;
  final String? type;

  PlaceModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latLng,
    this.type,
  });

  // ── TomTom Fuzzy Search / Autocomplete ─────────────────────────────────
  factory PlaceModel.fromTomTomJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>? ?? {};
    final double lat = (position['lat'] as num? ?? 0).toDouble();
    final double lon = (position['lon'] as num? ?? 0).toDouble();

    final poi = json['poi'] as Map<String, dynamic>?;
    final address = json['address'] as Map<String, dynamic>? ?? {};

    final String name = poi?['name']?.toString() ??
        address['streetName']?.toString() ??
        address['freeformAddress']?.toString() ??
        'Địa điểm không tên';

    final String fullAddress =
        address['freeformAddress']?.toString() ??
            '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';

    final String id = json['id']?.toString() ?? '$lat,$lon';
    final String type = json['type']?.toString() ?? poi?['categories']?.toString() ?? '';

    return PlaceModel(
      id: id,
      name: name,
      address: fullAddress,
      latLng: LatLng(lat, lon),
      type: type,
    );
  }

  // ── TomTom Reverse Geocoding ────────────────────────────────────────────
  factory PlaceModel.fromTomTomReverseJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final posStr = json['position']?.toString() ?? '';

    double lat = 0, lon = 0;
    final parts = posStr.split(',');
    if (parts.length == 2) {
      lat = double.tryParse(parts[0]) ?? 0;
      lon = double.tryParse(parts[1]) ?? 0;
    }

    final String freeform = address['freeformAddress']?.toString() ?? '';
    final String streetName = address['streetName']?.toString() ?? '';
    final String name = streetName.isNotEmpty ? streetName : freeform;

    return PlaceModel(
      id: 'reverse_$lat,$lon',
      name: name.isNotEmpty ? name : 'Vị trí đã chọn',
      address: freeform.isNotEmpty
          ? freeform
          : '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
      latLng: LatLng(lat, lon),
      type: 'address',
    );
  }

  // ── Photon (OpenStreetMap) Fuzzy Search ─────────────────────────────────
  factory PlaceModel.fromPhotonJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final coordinates = geometry['coordinates'] as List? ?? [0.0, 0.0];
    final properties = json['properties'] as Map<String, dynamic>? ?? {};

    final double lng = (coordinates[0] as num).toDouble();
    final double lat = (coordinates[1] as num).toDouble();

    final String name = properties['name']?.toString() ??
        properties['street']?.toString() ??
        'Địa điểm không tên';

    final List<String> addressParts = [];
    if (properties['street'] != null && properties['street'] != name) {
      addressParts.add(properties['street'].toString());
    }
    if (properties['district'] != null) {
      addressParts.add(properties['district'].toString());
    }
    if (properties['city'] != null) {
      addressParts.add(properties['city'].toString());
    }
    if (properties['state'] != null) {
      addressParts.add(properties['state'].toString());
    }
    if (properties['country'] != null) {
      addressParts.add(properties['country'].toString());
    }

    final String address = addressParts.isNotEmpty
        ? addressParts.join(', ')
        : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

    final String osmId = properties['osm_id']?.toString() ?? '';
    final String osmType = properties['osm_type']?.toString() ?? '';

    return PlaceModel(
      id: '$osmType$osmId',
      name: name,
      address: address,
      latLng: LatLng(lat, lng),
      type: properties['type']?.toString() ?? properties['osm_value']?.toString(),
    );
  }

  String get typeLabel {
    final t = type?.toLowerCase() ?? '';
    if (t.contains('restaurant') || t.contains('food')) return '🍽️ Nhà hàng';
    if (t.contains('hotel') || t.contains('lodging')) return '🏨 Khách sạn';
    if (t.contains('hospital')) return '🏥 Bệnh viện';
    if (t.contains('school') || t.contains('university')) return '🏫 Trường học';
    if (t.contains('cafe') || t.contains('coffee')) return '☕ Café';
    if (t.contains('bank')) return '🏦 Ngân hàng';
    if (t.contains('park')) return '🌳 Công viên';
    if (t.contains('airport')) return '✈️ Sân bay';
    return '📍 Địa điểm';
  }
}
