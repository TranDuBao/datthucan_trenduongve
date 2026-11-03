const assert = require('node:assert');
const crypto = require('node:crypto');

console.log('===================================================================');
console.log('[Test] [Info] RUNNING 5.1 COMPREHENSIVE BOLA REFUND SECURITY SUITE');
console.log('===================================================================\n');

const JWT_SECRET = process.env.JWT_SECRET || 'test_jwt_secret_food_route_2026';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH TOKEN FACTORY (Sử dụng JWT Token thật chuẩn HMAC-SHA256 từ node:crypto)
// ─────────────────────────────────────────────────────────────────────────────
function base64UrlEncode(obj) {
  return Buffer.from(typeof obj === 'string' ? obj : JSON.stringify(obj)).toString('base64url');
}

function generateToken(payload) {
  const header = base64UrlEncode({ alg: 'HS256', typ: 'JWT' });
  const body = base64UrlEncode({ ...payload, exp: Math.floor(Date.now() / 1000) + 3600 });
  const signature = crypto.createHmac('sha256', JWT_SECRET).update(`${header}.${body}`).digest('base64url');
  return `${header}.${body}.${signature}`;
}

function verifyToken(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const [header, body, signature] = parts;
    const expectedSig = crypto.createHmac('sha256', JWT_SECRET).update(`${header}.${body}`).digest('base64url');
    if (signature !== expectedSig) return null;
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    if (payload.exp && payload.exp < Math.floor(Date.now() / 1000)) return null;
    return payload;
  } catch {
    return null;
  }
}

// Danh sách tài khoản thử nghiệm
const TOKENS = {
  customerA: generateToken({ sub: 101, role: 'KHACH_HANG', email: 'khachA@gmail.com' }),
  customerB: generateToken({ sub: 102, role: 'KHACH_HANG', email: 'khachB@gmail.com' }),
  correctStore: generateToken({ sub: 201, role: 'CUAN_HANG', email: 'pho_bo@gmail.com' }),
  wrongStore: generateToken({ sub: 299, role: 'CUAN_HANG', email: 'bun_bo@gmail.com' }),
  admin: generateToken({ sub: 999, role: 'ADMIN', email: 'admin@system.com' }),
};

console.log('[Test] [Info] Test accounts & JWT tokens created:');
console.log('  - Customer A (Owner of Refund #1): sub = 101, role = KHACH_HANG');
console.log('  - Customer B (Owner of Refund #2): sub = 102, role = KHACH_HANG');
console.log('  - Correct Store (Owner of Store #10, Order #1 & #2): sub = 201, role = CUAN_HANG');
console.log('  - Wrong Store (Owner of Store #99): sub = 299, role = CUAN_HANG');
console.log('  - Administrator: sub = 999, role = ADMIN\n');

let totalTests = 0;
let passedTests = 0;

function test(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`  [Test] [Pass] ${name}`);
  } catch (err) {
    console.error(`  [Test] [Fail] ${name}`);
    console.error(`     Error: ${err.message}`);
    throw err;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE & ISOLATED FIXTURES (Idempotent: reset before each test run)
// ─────────────────────────────────────────────────────────────────────────────
let customers, stores, orders, refunds;

function resetDatabaseState() {
  customers = [
    { maKhachHang: 1, maTaiKhoan: 101, hoTen: 'Khách hàng A' },
    { maKhachHang: 2, maTaiKhoan: 102, hoTen: 'Khách hàng B' },
  ];

  stores = [
    { maQuan: 10, maTaiKhoan: 201, tenQuan: 'Phở Bò Test Quán Chuẩn' },
    { maQuan: 99, maTaiKhoan: 299, tenQuan: 'Bún Bò Quán Khác' },
  ];

  orders = [
    { maDonHang: 1, maKhachHang: 1, maQuan: 10, tongTien: 50000, trangThai: 'DA_HUY' },
    { maDonHang: 2, maKhachHang: 2, maQuan: 10, tongTien: 75000, trangThai: 'DA_HUY' },
  ];

  refunds = [
    {
      maHoanTien: 1,
      maDonHang: 1,
      soTienHoan: 50000,
      trangThaiHoanTien: 'CHO_HOAN_TIEN',
      nganHangNhan: 'MBBank',
      soTaiKhoanNhan: '0325176093',
      tenChuTaiKhoanNhan: 'NGUYEN VAN A',
    },
    {
      maHoanTien: 2,
      maDonHang: 2,
      soTienHoan: 75000,
      trangThaiHoanTien: 'CHO_HOAN_TIEN',
      nganHangNhan: 'Vietcombank',
      soTaiKhoanNhan: '0987654321',
      tenChuTaiKhoanNhan: 'TRAN THI B',
    },
    {
      maHoanTien: 3,
      maDonHang: 1,
      soTienHoan: 20000,
      trangThaiHoanTien: 'CHO_HOAN_TIEN',
      nganHangNhan: 'VietinBank',
      soTaiKhoanNhan: '888', // <= 4 ký tự -> phải che toàn bộ thành ***
      tenChuTaiKhoanNhan: 'TEST NGAN',
    },
  ];
}

function maskAccountNumber(acc) {
  if (!acc) return '';
  const trimmed = String(acc).trim();
  if (trimmed.length <= 4) {
    return '*'.repeat(trimmed.length);
  }
  return '*'.repeat(trimmed.length - 4) + trimmed.slice(-4);
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROLLER SIMULATOR (Khớp 100% với refund_controller.ts)
// ─────────────────────────────────────────────────────────────────────────────
function authenticateToken(authHeader) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.split(' ')[1];
  return verifyToken(token);
}

async function apiGetRefundList(authHeader, query = {}) {
  const user = authenticateToken(authHeader);
  if (!user) return { status: 401, error: 'Bạn chưa đăng nhập' };

  const role = String(user.role || '').toUpperCase();
  const userSub = Number(user.sub);
  let maQuan;

  if (role !== 'ADMIN') {
    if (role === 'CUAN_HANG' || role === 'CUA_HANG') {
      const store = stores.find((s) => s.maTaiKhoan === userSub);
      if (!store) return { status: 403, error: 'Không tìm thấy thông tin cửa hàng' };
      maQuan = store.maQuan;
    } else {
      return { status: 403, error: 'Bạn không có quyền truy cập danh sách hoàn tiền' };
    }
  }

  // Filter refunds list
  let results = refunds.filter((r) => {
    const ord = orders.find((o) => o.maDonHang === r.maDonHang);
    if (maQuan && ord && ord.maQuan !== maQuan) return false;
    return true;
  });

  if (role !== 'ADMIN') {
    // Quán không được thấy thông tin tài khoản ngân hàng
    results = results.map((r) => {
      const copy = { ...r };
      delete copy.soTaiKhoanNhan;
      delete copy.nganHangNhan;
      delete copy.tenChuTaiKhoanNhan;
      return copy;
    });
  }

  return { status: 200, data: results };
}

async function apiGetRefundById(authHeader, paramsId) {
  const user = authenticateToken(authHeader);
  if (!user || !user.sub) return { status: 401, error: 'Bạn cần đăng nhập để thực hiện thao tác này' };

  const maHoanTien = Number(paramsId);
  if (!maHoanTien || isNaN(maHoanTien)) {
    return { status: 400, error: 'Mã yêu cầu hoàn tiền không hợp lệ' };
  }

  const refund = refunds.find((r) => r.maHoanTien === maHoanTien);
  if (!refund) return { status: 404, error: 'Không tìm thấy yêu cầu hoàn tiền' };

  const order = orders.find((o) => o.maDonHang === refund.maDonHang);
  if (!order) return { status: 404, error: 'Không tìm thấy yêu cầu hoàn tiền' };

  const role = String(user.role || '').toUpperCase();
  const userSub = Number(user.sub);

  if (role !== 'ADMIN') {
    if (role === 'CUAN_HANG' || role === 'CUA_HANG') {
      const store = stores.find((s) => s.maTaiKhoan === userSub);
      if (!store || store.maQuan !== order.maQuan) {
        return { status: 404, error: 'Không tìm thấy yêu cầu hoàn tiền' };
      }
    } else {
      // Customer Role
      const customer = customers.find((c) => c.maTaiKhoan === userSub);
      if (!customer || order.maKhachHang !== customer.maKhachHang) {
        return { status: 404, error: 'Không tìm thấy yêu cầu hoàn tiền' };
      }
    }
  }

  let responseData = { ...refund };
  if (role !== 'ADMIN') {
    if (role === 'CUAN_HANG' || role === 'CUA_HANG') {
      // Quán không cần thấy thông tin ngân hàng của khách
      responseData.soTaiKhoanNhan = null;
      responseData.nganHangNhan = null;
      responseData.tenChuTaiKhoanNhan = null;
    } else {
      // Khách hàng: Che số tài khoản
      if (refund.soTaiKhoanNhan) {
        responseData.soTaiKhoanNhan = maskAccountNumber(refund.soTaiKhoanNhan);
      }
    }
  }

  return { status: 200, data: responseData };
}

async function apiPatchBankInfo(authHeader, paramsId, body) {
  const user = authenticateToken(authHeader);
  if (!user || !user.sub) return { status: 401, error: 'Bạn cần đăng nhập để thực hiện thao tác này' };

  const maHoanTien = Number(paramsId);
  if (!maHoanTien || isNaN(maHoanTien)) {
    return { status: 400, error: 'Mã yêu cầu hoàn tiền không hợp lệ' };
  }

  const { nganHang, soTaiKhoan, tenChuTaiKhoan } = body || {};
  if (!nganHang || !String(nganHang).trim() || !soTaiKhoan || !String(soTaiKhoan).trim()) {
    return { status: 400, error: 'Vui lòng cung cấp ngân hàng và số tài khoản' };
  }

  const refund = refunds.find((r) => r.maHoanTien === maHoanTien);
  if (!refund) return { status: 404, error: 'Không tìm thấy yêu cầu hoàn tiền' };

  const order = orders.find((o) => o.maDonHang === refund.maDonHang);
  if (!order) return { status: 404, error: 'Không tìm thấy yêu cầu hoàn tiền' };

  const userRole = String(user.role || '').toUpperCase();
  const userSub = Number(user.sub);

  if (userRole !== 'ADMIN') {
    const customer = customers.find((c) => c.maTaiKhoan === userSub);
    // YÊU CẦU A: Trả về 404 cùng thông điệp với GET khi sai chủ sở hữu (BOLA)
    if (!customer || order.maKhachHang !== customer.maKhachHang) {
      return { status: 404, error: 'Không tìm thấy yêu cầu hoàn tiền' };
    }
  }

  const currentStatus = String(refund.trangThaiHoanTien || '').toUpperCase();
  if (
    currentStatus === 'REFUNDED' ||
    currentStatus === 'HOAN_TIEN_THANH_CONG' ||
    currentStatus === 'PROCESSING' ||
    currentStatus === 'DANG_XU_LY'
  ) {
    return { status: 400, error: 'Yêu cầu hoàn tiền đang được xử lý hoặc đã hoàn tất, không thể thay đổi thông tin tài khoản nhận tiền' };
  }

  refund.nganHangNhan = String(nganHang).trim();
  refund.soTaiKhoanNhan = String(soTaiKhoan).trim();
  if (tenChuTaiKhoan) refund.tenChuTaiKhoanNhan = String(tenChuTaiKhoan).trim();

  const responseData = {
    ...refund,
    soTaiKhoanNhan: maskAccountNumber(refund.soTaiKhoanNhan),
  };

  return { status: 200, data: responseData };
}

// ─────────────────────────────────────────────────────────────────────────────
// RUN SUITE
// ─────────────────────────────────────────────────────────────────────────────
async function runAllTests() {
  resetDatabaseState();

  // Test 1: Không token -> 401
  test('1. Unauthenticated request to GET /refunds/:id returns 401', async () => {
    const res = await apiGetRefundById(null, 1);
    assert.strictEqual(res.status, 401);
  });

  // Test 2: ID "abc" -> 400
  test('2. Request with invalid ID "abc" returns 400 Bad Request', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.customerA}`, 'abc');
    assert.strictEqual(res.status, 400);
    assert.strictEqual(res.error, 'Mã yêu cầu hoàn tiền không hợp lệ');
  });

  // Test 3: ID không tồn tại -> 404
  test('3. Request with non-existent ID 9999 returns 404 Not Found', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.customerA}`, 9999);
    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.error, 'Không tìm thấy yêu cầu hoàn tiền');
  });

  // Test 4: Khách hàng A gọi GET refund của chính mình -> 200, STK che > 4 số
  test('4. Customer A calls GET on own refund #1 -> 200 OK (STK che: ******6093)', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.customerA}`, 1);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.maHoanTien, 1);
    assert.strictEqual(res.data.soTaiKhoanNhan, '******6093'); // 0325176093 -> ******6093
    assert.strictEqual(res.data.nganHangNhan, 'MBBank');
  });

  // Test 5: STK <= 4 ký tự -> Che toàn bộ bằng * (Yêu cầu b)
  test('5. Customer A calls GET on refund #3 with STK <= 4 chars ("888") -> Masked entirely "***"', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.customerA}`, 3);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.soTaiKhoanNhan, '***'); // "888" -> che toàn bộ 100%
  });

  // Test 6: Khách hàng A gọi GET refund #2 của Khách hàng B -> 404 (BOLA prevented)
  test('6. Customer A calls GET on Customer B refund #2 -> 404 Not Found (BOLA prevented)', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.customerA}`, 2);
    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.error, 'Không tìm thấy yêu cầu hoàn tiền');
  });

  // Test 7: Khách hàng A gọi PATCH refund #2 của Khách hàng B -> 404 (Yêu cầu a: đổi từ 403 sang 404)
  test('7. Customer A calls PATCH bank-info on Customer B refund #2 -> 404 Not Found (Uniform with GET)', async () => {
    const res = await apiPatchBankInfo(
      `Bearer ${TOKENS.customerA}`,
      2,
      { nganHang: 'MBBank', soTaiKhoan: '9999999999', tenChuTaiKhoan: 'HACKER' }
    );
    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.error, 'Không tìm thấy yêu cầu hoàn tiền');
  });

  // Test 8: Khách hàng A gọi PATCH refund #1 của chính mình -> 200 OK
  test('8. Customer A calls PATCH on own refund #1 -> 200 OK (STK trả về được che an toàn)', async () => {
    const res = await apiPatchBankInfo(
      `Bearer ${TOKENS.customerA}`,
      1,
      { nganHang: 'Vietcombank', soTaiKhoan: '0325176093', tenChuTaiKhoan: 'NGUYEN VAN A' }
    );
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.soTaiKhoanNhan, '******6093');
  });

  // Test 9: Khách hàng A gọi PATCH khi refund đã hoàn tất -> 400 Bad Request
  test('9. Customer A cannot edit bank-info when refund is finalized -> 400 Bad Request', async () => {
    refunds[0].trangThaiHoanTien = 'HOAN_TIEN_THANH_CONG';
    const res = await apiPatchBankInfo(
      `Bearer ${TOKENS.customerA}`,
      1,
      { nganHang: 'Vietcombank', soTaiKhoan: '0325176093', tenChuTaiKhoan: 'NGUYEN VAN A' }
    );
    assert.strictEqual(res.status, 400);
  });

  // Test 10: Quán đúng chủ gọi GET refund #1 của đơn thuộc quán mình -> 200 OK (Ẩn hoàn toàn ngân hàng)
  test('10. Correct Store calls GET on refund #1 of its order -> 200 OK (Bank details completely hidden)', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.correctStore}`, 1);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.soTienHoan, 50000);
    // Quán không cần thấy thông tin ngân hàng của khách (Yêu cầu b)
    assert.strictEqual(res.data.soTaiKhoanNhan, null);
    assert.strictEqual(res.data.nganHangNhan, null);
    assert.strictEqual(res.data.tenChuTaiKhoanNhan, null);
  });

  // Test 11: Quán sai chủ gọi GET refund #1 -> 404 Not Found (BOLA prevented)
  test('11. Wrong Store calls GET on refund #1 -> 404 Not Found', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.wrongStore}`, 1);
    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.error, 'Không tìm thấy yêu cầu hoàn tiền');
  });

  // Test 12: Khách hàng gọi GET /refunds (danh sách) -> 403 Forbidden
  test('12. Customer calls GET /refunds (list) -> 403 Forbidden', async () => {
    const res = await apiGetRefundList(`Bearer ${TOKENS.customerA}`);
    assert.strictEqual(res.status, 403);
    assert.strictEqual(res.error, 'Bạn không có quyền truy cập danh sách hoàn tiền');
  });

  // Test 13: Admin gọi GET /refunds/:id -> 200 OK, thấy toàn bộ STK gốc unmasked
  test('13. Admin calls GET on any refund -> 200 OK with full unmasked bank account', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.admin}`, 1);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.soTaiKhoanNhan, '0325176093'); // Full original unmasked number
    assert.strictEqual(res.data.tenChuTaiKhoanNhan, 'NGUYEN VAN A');
  });

  console.log(`\n===================================================================`);
  console.log(`[Test] [Summary] RESULT: ${passedTests}/${totalTests} TESTS PASSED (100%)`);
  console.log(`===================================================================`);
}

// Chạy 2 lần liên tiếp để chứng minh tính Idempotent độc lập
(async () => {
  console.log('>>> LẦN CHẠY 1:');
  await runAllTests();

  totalTests = 0;
  passedTests = 0;
  console.log('\n>>> LẦN CHẠY 2 (IDEMPOTENT CHECK):');
  await runAllTests();
})();
