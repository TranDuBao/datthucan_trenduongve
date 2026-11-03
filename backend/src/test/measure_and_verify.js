/**
 * END-TO-END MEASUREMENT & INDEPENDENT VERIFICATION SCRIPT (MỤC 2h & 2i)
 */

const http = require('http');

// 1. Independent Cross-Track Distance Formula (Spherical Trigonometry / Great-Circle navigation)
// Formula: d_xt = asin( sin(d13/R) * sin(theta13 - theta12) ) * R
// completely different from flat-earth equi-rectangular projection in code!
function independentSphericalCrossTrack(point, start, end) {
  const R = 6371000; // meters
  const toRad = (deg) => (deg * Math.PI) / 180;

  const lat1 = toRad(start.lat);
  const lon1 = toRad(start.lng);
  const lat2 = toRad(end.lat);
  const lon2 = toRad(end.lng);
  const lat3 = toRad(point.lat);
  const lon3 = toRad(point.lng);

  // Angular distance from start to point (d13 / R)
  const dLat13 = lat3 - lat1;
  const dLon13 = lon3 - lon1;
  const a13 =
    Math.sin(dLat13 / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat3) * Math.sin(dLon13 / 2) ** 2;
  const delta13 = 2 * Math.atan2(Math.sqrt(a13), Math.sqrt(1 - a13));

  // Initial bearing from start to end (theta12)
  const y12 = Math.sin(lon2 - lon1) * Math.cos(lat2);
  const x12 =
    Math.cos(lat1) * Math.sin(lat2) -
    Math.sin(lat1) * Math.cos(lat2) * Math.cos(lon2 - lon1);
  const theta12 = Math.atan2(y12, x12);

  // Initial bearing from start to point (theta13)
  const y13 = Math.sin(lon3 - lon1) * Math.cos(lat3);
  const x13 =
    Math.cos(lat1) * Math.sin(lat3) -
    Math.sin(lat1) * Math.cos(lat3) * Math.cos(lon3 - lon1);
  const theta13 = Math.atan2(y13, x13);

  // Cross-track distance
  const dXt = Math.asin(Math.sin(delta13) * Math.sin(theta13 - theta12)) * R;
  return Math.abs(dXt);
}

// Flat-Earth Projection in code (geo_corridor_utils.ts)
function codeFlatProjection(point, start, end) {
  const DEG_TO_RAD = Math.PI / 180;
  const EARTH_RADIUS_METERS = 6371000;
  const midLat = ((start.lat + end.lat + point.lat) / 3) * DEG_TO_RAD;
  const cosMidLat = Math.cos(midLat);

  const x1 = start.lng * DEG_TO_RAD * cosMidLat * EARTH_RADIUS_METERS;
  const y1 = start.lat * DEG_TO_RAD * EARTH_RADIUS_METERS;
  const x2 = end.lng * DEG_TO_RAD * cosMidLat * EARTH_RADIUS_METERS;
  const y2 = end.lat * DEG_TO_RAD * EARTH_RADIUS_METERS;
  const xp = point.lng * DEG_TO_RAD * cosMidLat * EARTH_RADIUS_METERS;
  const yp = point.lat * DEG_TO_RAD * EARTH_RADIUS_METERS;

  const dx = x2 - x1;
  const dy = y2 - y1;
  const lenSq = dx * dx + dy * dy;
  let t = ((xp - x1) * dx + (yp - y1) * dy) / lenSq;
  t = Math.max(0, Math.min(1, t));

  const projX = x1 + t * dx;
  const projY = y1 + t * dy;
  return Math.hypot(xp - projX, yp - projY);
}

// Run verification
async function verify() {
  console.log('--- MỤC 2i: ĐỐI CHIẾU KHOẢNG CÁCH HOÀN TOÀN ĐỘC LẬP TRÊN 3 QUÁN THẬT ---');
  // Tuyến đường tham chiếu: Ngã 4 Hàng Xanh -> Chợ Bến Thành
  const routeStart = { lat: 10.8016, lng: 106.7115 };
  const routeEnd = { lat: 10.7725, lng: 106.6980 };

  const stores = [
    { name: 'Phúc Long NTMK', lat: 10.7812, lng: 106.6985 },
    { name: 'Cơm Tấm Sài Gòn 99', lat: 10.7950, lng: 106.6850 },
    { name: 'Tiệm Kem Sweet Cake', lat: 10.7870, lng: 106.6920 },
  ];

  for (const s of stores) {
    const dSpherical = independentSphericalCrossTrack(s, routeStart, routeEnd);
    const dFlatCode = codeFlatProjection(s, routeStart, routeEnd);
    const diffMeters = Math.abs(dSpherical - dFlatCode);
    const errPct = (diffMeters / dSpherical) * 100;
    console.log(`• ${s.name}:`);
    console.log(`   Công thức Cầu Độc lập (Great-Circle Cross-Track): ${dSpherical.toFixed(2)} m`);
    console.log(`   Công thức Code Phẳng (Equirectangular Projection): ${dFlatCode.toFixed(2)} m`);
    console.log(`   Chênh lệch: ${diffMeters.toFixed(2)} m (${errPct.toFixed(3)}%)`);
  }

  console.log('\n--- MỤC 2h: ĐO HIỆU NĂNG ĐẦU-CUỐI & SỐ LẦN GỌI ROUTING ---');
  const t0 = Date.now();
  // Call live along-route API
  const token = require('jsonwebtoken').sign({ sub: 10, role: 'KHACH_HANG' }, 'super_secret_key_smart_city_food_route_2026');
  const payload = JSON.stringify({
    routePoints: [
      { lat: 10.8286, lng: 106.6341 },
      { lat: 10.8030, lng: 106.6660 },
      { lat: 10.7769, lng: 106.7009 },
    ],
    maxDistanceMeters: 800,
  });

  const req = http.request(
    {
      hostname: 'localhost',
      port: 3000,
      path: '/api/v1/restaurants/along-route',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer ' + token,
        'Content-Length': Buffer.byteLength(payload),
      },
    },
    (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => {
        const totalDurationMs = Date.now() - t0;
        const parsed = JSON.parse(data);
        console.log(`• HTTP Status: ${res.statusCode}`);
        console.log(`• Tổng thời gian toàn trình (End-to-end latency): ${totalDurationMs} ms`);
        console.log(`• Số lượng quán tìm thấy trong hành lang: ${parsed.data?.length || 0}`);
        if (parsed.data && parsed.data.length > 0) {
          const calculatedCount = parsed.data.filter((s) => s.isDetourCalculated).length;
          console.log(`• Số lượng quán được gọi OSRM tính đi vòng (giới hạn N): ${calculatedCount}`);
          console.log(`• Quán #1: ${parsed.data[0].tenQuan} (${parsed.data[0].detourDurationText}, ${parsed.data[0].detourDistanceText})`);
        }
      });
    }
  );
  req.write(payload);
  req.end();
}

verify();
