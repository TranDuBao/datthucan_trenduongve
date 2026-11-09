import 'package:flutter_test/flutter_test.dart';
import 'package:food_route/common/service_call.dart';
import 'package:food_route/providers/map_provider.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  ServiceCall.userPayload = {'id': '1', 'user_id': '1'};

  group('MapProvider Active Stopover Navigation Tests', () {
    test('activeStopoverLatLng extracts coordinates accurately with multiple fallback keys', () async {
      final mapProvider = MapProvider();

      // Test key dạng standard: lat, lng
      await mapProvider.setActiveStopoverOrder({
        'maDonHang': 74,
        'tenQuan': 'Phúc Long Coffee & Tea',
        'lat': 10.7812,
        'lng': 106.6985,
      });

      expect(mapProvider.activeStopoverOrder, isNotNull);
      expect(mapProvider.activeStopoverLatLng, equals(const LatLng(10.7812, 106.6985)));
      expect(mapProvider.isOrderPickedUp, isFalse);

      // Test key dạng Tiếng Việt: vido, kinhdo
      await mapProvider.setActiveStopoverOrder({
        'maDonHang': 75,
        'tenQuan': 'Gà Nướng Ò Ó O',
        'vido': 10.7915,
        'kinhdo': 106.6850,
      });

      expect(mapProvider.activeStopoverLatLng, equals(const LatLng(10.7915, 106.6850)));

      // Test key dạng nested: restaurant: { lat, lng }
      await mapProvider.setActiveStopoverOrder({
        'id': 76,
        'restaurantName': 'Bánh Canh Cua',
        'restaurant': {
          'lat': 10.7950,
          'lng': 106.6800,
        },
      });

      expect(mapProvider.activeStopoverLatLng, equals(const LatLng(10.7950, 106.6800)));
      expect(mapProvider.activeStopoverOrder?['restaurantName'], equals('Bánh Canh Cua'));
    });
  });
}

