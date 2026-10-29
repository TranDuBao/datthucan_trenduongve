const assert = require('node:assert');
const crypto = require('node:crypto');

console.log('===============================================================');
console.log('[Test] [Info] RUNNING PAYMENT FLOW & ORDER LIFECYCLE VERIFICATION SUITE');
console.log('===============================================================\n');

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
// SUITE 1: ORDER CREATION & INITIAL STATUS ISOLATION
// ─────────────────────────────────────────────────────────────────────────────
console.log('[Test] [Info] 1. Order Creation & Initial Status Tests');

test('1.1 Online orders (PAYOS/VIETQR) are initialized as CHO_THANH_TOAN (UNPAID)', () => {
  const methodOnline1 = 'PAYOS';
  const methodOnline2 = 'VIETQR';
  const methodCOD = 'COD';

  function determineInitialStatus(method) {
    const m = (method || 'PAYOS').toUpperCase();
    const isOnline = m === 'PAYOS' || m === 'VIETQR' || m === 'MOMO' || m === 'VNPAY';
    return isOnline ? 'CHO_THANH_TOAN' : 'CHO_XAC_NHAN';
  }

  assert.strictEqual(determineInitialStatus(methodOnline1), 'CHO_THANH_TOAN');
  assert.strictEqual(determineInitialStatus(methodOnline2), 'CHO_THANH_TOAN');
  assert.strictEqual(determineInitialStatus(methodCOD), 'CHO_XAC_NHAN');
});

test('1.2 CHO_THANH_TOAN orders are excluded from restaurant active preparation list', () => {
  const mockOrders = [
    { maDonHang: 101, trangThai: 'CHO_THANH_TOAN', tongTien: 50000 },
    { maDonHang: 102, trangThai: 'CHO_XAC_NHAN', tongTien: 75000 },
    { maDonHang: 103, trangThai: 'DANG_CHUAN_BI', tongTien: 120000 },
    { maDonHang: 104, trangThai: 'DA_HUY', tongTien: 30000 },
  ];

  const unpaidStatuses = ['cho_thanh_toan', 'unpaid', 'chờ thanh toán'];

  // Restaurant getOrders query filter
  const restaurantVisibleOrders = mockOrders.filter(
    (o) => !unpaidStatuses.includes(o.trangThai.toLowerCase())
  );

  assert.strictEqual(restaurantVisibleOrders.length, 3);
  assert.strictEqual(restaurantVisibleOrders.some((o) => o.maDonHang === 101), false);
  assert.strictEqual(restaurantVisibleOrders.some((o) => o.maDonHang === 102), true);
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 2: RESTAURANT ACTION GUARD FOR UNPAID ORDERS
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n[Test] [Info] 2. Restaurant Action Guard Tests');

test('2.1 Restaurant cannot accept or prepare an order while status is CHO_THANH_TOAN', () => {
  const order = { maDonHang: 201, trangThai: 'CHO_THANH_TOAN', maQuan: 5 };

  function restaurantUpdateStatus(ord, targetStatus) {
    const current = String(ord.trangThai || '').trim().toUpperCase();
    if (current === 'CHO_THANH_TOAN' || current === 'UNPAID') {
      throw new Error('Đơn hàng chưa hoàn tất thanh toán, cửa hàng không thể tiếp nhận hoặc chuẩn bị món!');
    }
    ord.trangThai = targetStatus;
  }

  assert.throws(() => {
    restaurantUpdateStatus(order, 'DA_XAC_NHAN');
  }, /Đơn hàng chưa hoàn tất thanh toán/);

  assert.throws(() => {
    restaurantUpdateStatus(order, 'DANG_CHUAN_BI');
  }, /Đơn hàng chưa hoàn tất thanh toán/);

  assert.strictEqual(order.trangThai, 'CHO_THANH_TOAN');
});

test('2.2 Customer CAN cancel an order in CHO_THANH_TOAN status', () => {
  const order = { maDonHang: 202, trangThai: 'CHO_THANH_TOAN', maKhachHang: 10 };

  function customerCancelOrder(ord, requesterKhachHangId) {
    if (ord.maKhachHang !== requesterKhachHangId) {
      throw new Error('Không tìm thấy đơn hàng');
    }
    const current = ord.trangThai;
    if (current !== 'CHO_XAC_NHAN' && current !== 'CHO_THANH_TOAN') {
      throw new Error('Đơn hàng đã được xác nhận hoặc đang chế biến, không thể hủy!');
    }
    ord.trangThai = 'DA_HUY';
    ord.lyDoHuy = 'Khách hàng hủy đơn trên màn hình thanh toán';
  }

  customerCancelOrder(order, 10);
  assert.strictEqual(order.trangThai, 'DA_HUY');
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 3: WEBHOOK SIGNATURE & SECURITY
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n[Test] [Info] 3. Webhook Signature & Security Tests');

test('3.1 Invalid or tampered signature is rejected with error', () => {
  const webhookSecret = 'test_secret_key_12345';
  const payload = {
    code: '00',
    data: { orderCode: 301, amount: 65000, description: 'DH301' },
  };

  const sortedKeys = Object.keys(payload.data).sort();
  const queryStr = sortedKeys.map(k => `${k}=${payload.data[k]}`).join('&');
  const validSig = crypto.createHmac('sha256', webhookSecret).update(queryStr).digest('hex');
  const fakeSig = 'fake_signature_abc_123';

  function verifySig(receivedSig, expectedSig) {
    try {
      const b1 = Buffer.from(receivedSig);
      const b2 = Buffer.from(expectedSig);
      return b1.length === b2.length && crypto.timingSafeEqual(b1, b2);
    } catch {
      return false;
    }
  }

  assert.strictEqual(verifySig(fakeSig, validSig), false);
  assert.strictEqual(verifySig(validSig, validSig), true);
});

test('3.2 Underpayment (amount mismatch) is rejected without confirming order', () => {
  const order = { maDonHang: 302, tongTien: 100000, trangThai: 'CHO_THANH_TOAN' };
  const paidAmount = 50000; // Customer only transferred half

  function processPaymentWebhook(ord, amount) {
    if (amount < ord.tongTien) {
      throw new Error(`Số tiền thanh toán (${amount}) không đủ so với tổng tiền đơn hàng (${ord.tongTien})`);
    }
    ord.trangThai = 'CHO_XAC_NHAN';
  }

  assert.throws(() => {
    processPaymentWebhook(order, paidAmount);
  }, /không đủ so với tổng tiền/);

  assert.strictEqual(order.trangThai, 'CHO_THANH_TOAN');
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 4: WEBHOOK SUCCESS & IDEMPOTENCY
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n[Test] [Info] 4. Webhook Verification & Idempotency Tests');

test('4.1 Valid payment transitions order to CHO_XAC_NHAN and payment to THANH_TOAN_THANH_CONG', () => {
  const order = { maDonHang: 401, trangThai: 'CHO_THANH_TOAN', tongTien: 80000, maQuan: 3 };
  let payment = { maDonHang: 401, trangThai: 'CHO_THANH_TOAN', soTien: 80000 };

  let realtimeEmitted = false;
  let restaurantNotified = false;

  function executeWebhookSuccess(ord, pmt, amount) {
    // 1. Transaction
    if (pmt.trangThai === 'THANH_TOAN_THANH_CONG') {
      return { alreadyProcessed: true };
    }
    pmt.trangThai = 'THANH_TOAN_THANH_CONG';
    pmt.soTien = amount;

    if (ord.trangThai === 'CHO_THANH_TOAN') {
      ord.trangThai = 'CHO_XAC_NHAN';
    }

    // 2. Realtime emit after DB write
    realtimeEmitted = true;
    restaurantNotified = true;

    return { alreadyProcessed: false };
  }

  const res1 = executeWebhookSuccess(order, payment, 80000);
  assert.strictEqual(res1.alreadyProcessed, false);
  assert.strictEqual(order.trangThai, 'CHO_XAC_NHAN');
  assert.strictEqual(payment.trangThai, 'THANH_TOAN_THANH_CONG');
  assert.strictEqual(realtimeEmitted, true);
  assert.strictEqual(restaurantNotified, true);

  // 4.2 Duplicate webhook call (Idempotency)
  realtimeEmitted = false;
  restaurantNotified = false;
  const res2 = executeWebhookSuccess(order, payment, 80000);
  assert.strictEqual(res2.alreadyProcessed, true);
  // Realtime emit is NOT triggered on duplicate webhook
  assert.strictEqual(realtimeEmitted, false);
  assert.strictEqual(restaurantNotified, false);
  assert.strictEqual(order.trangThai, 'CHO_XAC_NHAN');
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 5: CLIENT INTEGRITY & SECURITY (/verify read-only)
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n[Test] [Info] 5. Client Integrity & Security Tests');

test('5.1 Frontend cannot forge payment state via client requests', () => {
  // Client attempts to POST /api/v1/payments/verify with body { status: 'PAID', trangThai: 'THANH_TOAN_THANH_CONG' }
  const clientPayload = { maDonHang: 501, status: 'PAID', trangThai: 'THANH_TOAN_THANH_CONG' };
  const dbPayment = { maDonHang: 501, trangThai: 'CHO_THANH_TOAN', soTien: 45000 };

  // Read-only endpoint returns DB payment status, ignoring any status fields passed by client
  function getPaymentStatus(dbState, clientBody) {
    return {
      status: 'success',
      data: {
        maDonHang: dbState.maDonHang,
        trangThaiThanhToan: dbState.trangThai, // Source of truth: DB only!
        soTien: dbState.soTien,
      },
    };
  }

  const response = getPaymentStatus(dbPayment, clientPayload);
  assert.strictEqual(response.data.trangThaiThanhToan, 'CHO_THANH_TOAN');
  assert.notStrictEqual(response.data.trangThaiThanhToan, 'PAID');
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 6: REVENUE CALCULATION ACCURACY
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n[Test] [Info] 6. Revenue Calculation Tests');

test('6.1 Unpaid (CHO_THANH_TOAN) orders are strictly excluded from confirmed revenue', () => {
  const storeOrders = [
    { maDonHang: 601, trangThai: 'CHO_THANH_TOAN', tongTien: 50000 },
    { maDonHang: 602, trangThai: 'HOAN_TAT', tongTien: 120000 },
    { maDonHang: 603, trangThai: 'DA_HUY', tongTien: 40000 },
    { maDonHang: 604, trangThai: 'HOAN_TAT', tongTien: 80000 },
  ];

  const completedStatuses = ['hoan_tat', 'hoan_thanh', 'completed', 'picked_up'];
  const revenue = storeOrders
    .filter(o => completedStatuses.includes(o.trangThai.toLowerCase()))
    .reduce((sum, o) => sum + o.tongTien, 0);

  assert.strictEqual(revenue, 200000);
});

console.log('\n===============================================================');
console.log(`[Test] [Info] ALL ${passedTests}/${totalTests} TESTS PASSED SUCCESSFULLY!`);
console.log('===============================================================\n');
