import 'package:flutter_test/flutter_test.dart';
import 'package:food_route/models/route_model.dart';
import 'package:food_route/providers/map_provider.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapProvider cancelStopoverOrder Tests', () {
    test('cancelStopoverOrder resets stopover route, store, food and restores original route', () {
      final mapProvider = MapProvider();

      final originalRoute = RouteModel(
        totalDistance: '2.5 km',
        totalDuration: '10 phút',
        totalDistanceMeters: 2500,
        totalDurationSeconds: 600,
        summary: 'Tuyến đường A -> B',
        steps: const [],
        polylinePoints: [
          const LatLng(10.7769, 106.7009),
          const LatLng(10.7800, 106.7050),
        ],
      );

      final stopoverRoute = RouteModel(
        totalDistance: '3.2 km',
        totalDuration: '15 phút',
        totalDistanceMeters: 3200,
        totalDurationSeconds: 900,
        summary: 'Tuyến đường rẽ qua Quán',
        steps: const [],
        polylinePoints: [
          const LatLng(10.7769, 106.7009),
          const LatLng(10.7780, 106.7020), // Quán ăn ghé vào
          const LatLng(10.7800, 106.7050),
        ],
      );

      // Thiết lập trạng thái giả lập khi đang chọn quán ghé lấy
      mapProvider.setStopoverRouteForTesting(
        original: originalRoute,
        stopover: stopoverRoute,
        store: {'id': 10, 'tenNhaHang': 'Quán Cơm Tấm'},
        food: {'id': 100, 'tenMonAn': 'Cơm sườn'},
        order: {'id': 999, 'tongTien': 50000},
      );

      expect(mapProvider.selectedStopoverStore, isNotNull);
      expect(mapProvider.stopoverRoute, isNotNull);
      expect(mapProvider.activeStopoverOrder, isNotNull);

      // Gọi hàm hủy đơn / hủy ghé quán
      mapProvider.cancelStopoverOrder();

      // Kiểm tra toàn bộ trạng thái ghé quán đã được giải phóng
      expect(mapProvider.selectedStopoverStore, isNull);
      expect(mapProvider.selectedStopoverFood, isNull);
      expect(mapProvider.stopoverRoute, isNull);
      expect(mapProvider.activeStopoverOrder, isNull);
      expect(mapProvider.currentRoute, equals(originalRoute));
    });
  });
}
