const assert = require('node:assert');
const crypto = require('node:crypto');
const path = require('node:path');

console.log('===================================================================');
console.log('[Test] [Info] RUNNING REAL CONTROLLER BOLA REFUND INTEGRATION SUITE');
console.log('===================================================================\n');

// Import real RefundController
const { RefundController } = require(path.resolve(__dirname, '../../dist/controllers/refund_controller'));
const controller = new RefundController();

const JWT_SECRET = process.env.JWT_SECRET || 'test_jwt_secret_food_route_2026';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH TOKEN FACTORY
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

// Test tokens
const TOKENS = {
  customerA: generateToken({ sub: 101, role: 'KHACH_HANG', email: 'khachA@gmail.com' }),
  customerB: generateToken({ sub: 102, role: 'KHACH_HANG', email: 'khachB@gmail.com' }),
  correctStore: generateToken({ sub: 201, role: 'CUAN_HANG', email: 'pho_bo@gmail.com' }),
  wrongStore: generateToken({ sub: 299, role: 'CUAN_HANG', email: 'bun_bo@gmail.com' }),
  admin: generateToken({ sub: 999, role: 'ADMIN', email: 'admin@system.com' }),
};

let totalTests = 0;
let passedTests = 0;

async function test(name, fn) {
  totalTests++;
  try {
    await fn();
    passedTests++;
    console.log(`  [Test] [Pass] ${name}`);
  } catch (err) {
    console.error(`  [Test] [Fail] ${name}`);
    console.error(`     Error: ${err.message}`);
    throw err;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE & ISOLATED FIXTURES
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
      soTaiKhoanNhan: '888',
      tenChuTaiKhoanNhan: 'TEST NGAN',
    },
  ];

  // Wire controller repos to memory store
  controller.hoanTienRepo = {
    findOne: async ({ where }) => {
      const match = refunds.find((r) => r.maHoanTien === where.maHoanTien);
      return match ? { ...match } : null;
    },
    save: async (entity) => {
      const idx = refunds.findIndex((r) => r.maHoanTien === entity.maHoanTien);
      if (idx !== -1) refunds[idx] = { ...entity };
      return entity;
    },
  };

  controller.donHangRepo = {
    findOne: async ({ where }) => {
      const match = orders.find((o) => o.maDonHang === where.maDonHang);
      return match ? { ...match } : null;
    },
  };

  controller.khachHangRepo = {
    findOne: async ({ where }) => {
      const match = customers.find((c) => c.maTaiKhoan === where.maTaiKhoan);
      return match ? { ...match } : null;
    },
  };

  controller.storeRepo = {
    findOne: async ({ where }) => {
      const match = stores.find((s) => s.maTaiKhoan === where.maTaiKhoan);
      return match ? { ...match } : null;
    },
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// REAL CONTROLLER EXECUTOR
// ─────────────────────────────────────────────────────────────────────────────
function authenticateToken(authHeader) {
  if (!authHeader || !authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.split(' ')[1];
  return verifyToken(token);
}

function mockReqRes(user, params = {}, body = {}, query = {}) {
  const req = { user, params, body, query };
  let resStatus = 200;
  let resData = null;
  const res = {
    status(code) {
      resStatus = code;
      return this;
    },
    json(payload) {
      resData = payload;
      return this;
    },
  };
  return { req, res, getStatus: () => resStatus, getData: () => resData };
}

async function apiGetRefundById(authHeader, paramsId) {
  const user = authenticateToken(authHeader);
  const { req, res, getStatus, getData } = mockReqRes(user, { id: paramsId });
  await controller.getRefundById(req, res);
  return { status: getStatus(), data: getData()?.data, error: getData()?.message };
}

async function apiPatchBankInfo(authHeader, paramsId, body) {
  const user = authenticateToken(authHeader);
  const { req, res, getStatus, getData } = mockReqRes(user, { id: paramsId }, body);
  await controller.updateBankInfo(req, res);
  return { status: getStatus(), data: getData()?.data, error: getData()?.message };
}

// ─────────────────────────────────────────────────────────────────────────────
// RUN SUITE
// ─────────────────────────────────────────────────────────────────────────────
async function runAllTests() {
  resetDatabaseState();

  // Test 1: Không token -> 401
  await test('1. Unauthenticated request to GET /refunds/:id returns 401', async () => {
    const res = await apiGetRefundById(null, 1);
    assert.strictEqual(res.status, 401);
  });

  // Test 2: ID "abc" -> 400
  await test('2. Request with invalid ID "abc" returns 400 Bad Request', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.customerA}`, 'abc');
    assert.strictEqual(res.status, 400);
    assert.strictEqual(res.error, 'Mã yêu cầu hoàn tiền không hợp lệ');
  });

  // Test 3: ID không tồn tại -> 404
  await test('3. Request with non-existent ID 9999 returns 404 Not Found', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.customerA}`, 9999);
    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.error, 'Không tìm thấy yêu cầu hoàn tiền');
  });

  // Test 4: Khách hàng A gọi GET refund của chính mình -> 200
  await test('4. Customer A calls GET on own refund #1 -> 200 OK', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.customerA}`, 1);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.maHoanTien, 1);
    assert.strictEqual(res.data.nganHangNhan, 'MBBank');
  });

  // Test 5: Khách hàng A gọi GET refund #2 của Khách hàng B -> 404 (BOLA prevented)
  await test('5. Customer A calls GET on Customer B refund #2 -> 404 Not Found (BOLA prevented)', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.customerA}`, 2);
    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.error, 'Không tìm thấy yêu cầu hoàn tiền');
  });

  // Test 6: Khách hàng A gọi PATCH refund #2 của Khách hàng B -> 404 (BOLA prevented)
  await test('6. Customer A calls PATCH bank-info on Customer B refund #2 -> 404 Not Found (Uniform with GET)', async () => {
    const res = await apiPatchBankInfo(
      `Bearer ${TOKENS.customerA}`,
      2,
      { nganHang: 'MBBank', soTaiKhoan: '9999999999', tenChuTaiKhoan: 'HACKER' }
    );
    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.error, 'Không tìm thấy yêu cầu hoàn tiền');
  });

  // Test 7: Khách hàng A gọi PATCH refund #1 của chính mình -> 200 OK
  await test('7. Customer A calls PATCH on own refund #1 -> 200 OK', async () => {
    const res = await apiPatchBankInfo(
      `Bearer ${TOKENS.customerA}`,
      1,
      { nganHang: 'Vietcombank', soTaiKhoan: '0325176093', tenChuTaiKhoan: 'NGUYEN VAN A' }
    );
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.nganHangNhan, 'Vietcombank');
  });

  // Test 8: Khách hàng A gọi PATCH khi refund đã hoàn tất -> 400 Bad Request
  await test('8. Customer A cannot edit bank-info when refund is finalized -> 400 Bad Request', async () => {
    refunds[0].trangThaiHoanTien = 'HOAN_TIEN_THANH_CONG';
    const res = await apiPatchBankInfo(
      `Bearer ${TOKENS.customerA}`,
      1,
      { nganHang: 'Vietcombank', soTaiKhoan: '0325176093', tenChuTaiKhoan: 'NGUYEN VAN A' }
    );
    assert.strictEqual(res.status, 400);
  });

  // Test 9: Quán đúng chủ gọi GET refund #1 của đơn thuộc quán mình -> 200 OK
  await test('9. Correct Store calls GET on refund #1 of its order -> 200 OK', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.correctStore}`, 1);
    assert.strictEqual(res.status, 200);
    assert.strictEqual(res.data.soTienHoan, 50000);
  });

  // Test 10: Quán sai chủ gọi GET refund #1 -> 404 Not Found (BOLA prevented)
  await test('10. Wrong Store calls GET on refund #1 -> 404 Not Found', async () => {
    const res = await apiGetRefundById(`Bearer ${TOKENS.wrongStore}`, 1);
    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.error, 'Không tìm thấy yêu cầu hoàn tiền');
  });

  console.log('\n===================================================================');
  console.log(`[Summary] ALL ${passedTests}/${totalTests} REAL CONTROLLER TESTS PASSED SUCCESSFULLY!`);
  console.log('===================================================================');
}

runAllTests().catch((err) => {
  console.error('[Fatal Test Failure]', err);
  process.exit(1);
});
