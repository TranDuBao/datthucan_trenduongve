/**
 * Test Suite: Restaurant Consistency & Review Accuracy Verification
 * Tests:
 * 1. GET /api/v1/restaurants returns ratings & review counts matching the real danhgia table.
 * 2. Stores with 0 reviews return 0 rating and 0 count (no fake 4.8 or 5.0).
 * 3. Multiple restaurants returned simultaneously are distinct without cross-contamination.
 * 4. Active vouchers return khuyenMai only when a valid active voucher exists; null otherwise.
 * 5. GET /api/v1/restaurants/:id matches GET /api/v1/restaurants for the same store.
 */

const http = require('http');
const { Client } = require('pg');

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

async function runTests() {
  console.log('=== TEST SUITE: RESTAURANT CONSISTENCY & REVIEW ACCURACY ===\n');
  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`  [PASS] ${message}`);
      passed++;
    } else {
      console.error(`  [FAIL] ${message}`);
      failed++;
    }
  }

  const pgClient = new Client({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: process.env.DB_USERNAME || 'postgres',
    password: process.env.DB_PASSWORD || '123456',
    database: process.env.DB_DATABASE || 'postgres',
  });

  try {
    await pgClient.connect();

    // 1. Fetch real review stats directly from danhgia table
    const realReviewRows = (await pgClient.query(`
      SELECT 
        maquan,
        COALESCE(ROUND(AVG(soluongsao)::numeric, 1), 0.0) as real_avg,
        COUNT(madanhgia)::int as real_count
      FROM danhgia
      WHERE is_hidden IS NOT TRUE OR is_hidden IS NULL
      GROUP BY maquan
    `)).rows;

    const realReviewMap = new Map();
    realReviewRows.forEach(r => {
      realReviewMap.set(Number(r.maquan), {
        avg: parseFloat(r.real_avg || 0),
        count: parseInt(r.real_count || 0, 10),
      });
    });

    // 2. Call GET /api/v1/restaurants
    const response = await fetchJson('http://localhost:3000/api/v1/restaurants');
    const apiStores = response.data || [];

    console.log(`[TEST 1] Response contains stores: ${apiStores.length}`);
    assert(apiStores.length > 0, 'API returns non-empty list of stores');

    // Test 2: Check each store against real review data
    console.log('\n[TEST 2] Verifying ratings and review counts against danhgia table:');
    let allRatingsMatch = true;
    for (const store of apiStores) {
      const real = realReviewMap.get(store.maQuan) || { avg: 0.0, count: 0 };
      const apiAvg = parseFloat(store.danhGiaTrungBinh || 0);
      const apiCount = parseInt(store.soLuongDanhGia || 0, 10);

      const matches = (apiAvg === real.avg && apiCount === real.count);
      if (!matches) {
        allRatingsMatch = false;
        console.error(`    Mismatch at maQuan ${store.maQuan} (${store.tenQuan}): API=${apiAvg}/${apiCount}, Real=${real.avg}/${real.count}`);
      }
    }
    assert(allRatingsMatch, 'All stores have rating & review count matching real danhgia calculations');

    // Test 3: Stores without reviews must return 0, not 4.8 or 5.0
    console.log('\n[TEST 3] Verifying zero-review stores return 0.0 rating and 0 count:');
    const zeroReviewStores = apiStores.filter(s => (realReviewMap.get(s.maQuan)?.count || 0) === 0);
    assert(zeroReviewStores.length > 0, `Found ${zeroReviewStores.length} stores with 0 reviews in danhgia`);
    const allZeroCorrect = zeroReviewStores.every(s => parseFloat(s.danhGiaTrungBinh || 0) === 0.0 && parseInt(s.soLuongDanhGia || 0, 10) === 0);
    assert(allZeroCorrect, 'Every store with 0 reviews returns exactly 0.0 rating and 0 count (no fake 4.8 or 5.0)');

    // Test 4: Check voucher accuracy
    console.log('\n[TEST 4] Verifying voucher accuracy:');
    const store12 = apiStores.find(s => s.maQuan === 12);
    assert(store12 && store12.khuyenMai !== null, 'Store 12 (Sweet Cake) has active voucher badge');
    
    const store57 = apiStores.find(s => s.maQuan === 57);
    assert(store57 && store57.khuyenMai === null, 'Store 57 (Phở Hòa) has NO active voucher (khuyenMai is null)');

    // Test 5: Check GET /api/v1/restaurants/:id matches list
    console.log('\n[TEST 5] Verifying single restaurant endpoint matches list data:');
    const singleStore = (await fetchJson('http://localhost:3000/api/v1/restaurants/12')).data;
    assert(singleStore.maQuan === 12, 'Single store returns maQuan 12');
    assert(parseFloat(singleStore.danhGiaTrungBinh) === parseFloat(store12.danhGiaTrungBinh), 'Single store rating matches list rating');
    assert(parseInt(singleStore.soLuongDanhGia, 10) === parseInt(store12.soLuongDanhGia, 10), 'Single store review count matches list review count');

    console.log('\n================================================================');
    console.log(`[Summary] ${passed} passed, ${failed} failed`);
    if (failed > 0) {
      process.exit(1);
    } else {
      console.log('[Summary] ALL BACKEND CONSISTENCY TESTS PASSED CLEANLY (EXIT CODE 0)!');
      process.exit(0);
    }
  } catch (err) {
    console.error('Test execution error:', err);
    process.exit(1);
  } finally {
    await pgClient.end();
  }
}

runTests();
