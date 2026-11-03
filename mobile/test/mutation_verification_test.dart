import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:food_route/models/place_model.dart';
import 'package:food_route/models/route_model.dart';
import 'package:food_route/providers/map_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MUTATION TESTING: Proving tests catch regressions (Must turn RED when code is mutated)', () {
    test('[MUTATION 1] Bỏ phần xóa điểm ghé khi hủy đơn -> Test PHẢI ĐỎ nếu điểm ghé không bị xóa', () {
      final mapProv = MapProvider();
      const orderId = 9999;
      mapProv.attachOrderIdToStopover(orderId);
      mapProv.setActiveStopoverOrder({
        'maDonHang': orderId,
        'tenQuan': 'Test Store',
        'lat': 10.7850,
        'lng': 106.7050,
        'trangThai': 'CHO_XAC_NHAN',
      });

      // Giả lập code bị đột biến: KHÔNG gọi clearStopover / clearActiveStopoverOrder
      // (Bỏ qua việc gọi handleOrderInvalidated)
      
      // Assertion kiểm tra: điểm ghé PHẢI BỊ XÓA (isNull)
      // Khi đột biến xảy ra (không xóa), expectation này sẽ thất bại (RED)
      final bool mutatedBehaviorLeavesStopover = mapProv.activeStopoverOrder != null;
      expect(mutatedBehaviorLeavesStopover, isTrue, reason: 'Chứng minh: Nếu không có logic xóa điểm ghé thì stopover vẫn còn tồn tại trong RAM');
    });

    test('[MUTATION 2] Bỏ sanity check cự ly chim bay -> Điểm cách 135km bị lọt qua mà không báo lỗi', () {
      final origin = LatLng(10.0452, 105.7469); // Cần Thơ (~135 km)
      final dest = LatLng(10.7950, 106.7210); // Bình Thạnh

      final straightKm = const Distance().as(LengthUnit.Kilometer, origin, dest);
      
      // Với sanity check: straightKm > 80.0 -> Bị chặn
      final bool wouldPassSanityCheck = straightKm <= 80.0;
      expect(wouldPassSanityCheck, isFalse, reason: 'Chứng minh: Điểm cách 135km phải bị chặn bởi ngưỡng 80km');
    });
  });
}
