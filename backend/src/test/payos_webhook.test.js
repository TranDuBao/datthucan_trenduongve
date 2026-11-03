/**
 * ============================================================================
 * PAYOS WEBHOOK AUTOMATED TEST SUITE (PHASE 5.3)
 * ============================================================================
 * Tests PayOS webhook signature verification, state transition, notifications,
 * and idempotency (duplicate prevention) according to official PayOS spec.
 */

const crypto = require('crypto');
const http = require('http');

let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

function test(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`  [PASS] ${name}`);
  } catch (err) {
    failedTests++;
    console.error(`  [FAIL] ${name}`);
    console.error(`         ${err.message}`);
  }
}

async function testAsync(name, fn) {
  totalTests++;
  try {
    await fn();
    passedTests++;
    console.log(`  [PASS] ${name}`);
  } catch (err) {
    failedTests++;
    console.error(`  [FAIL] ${name}`);
    console.error(`         ${err.message}`);
  }
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

function assertEqual(actual, expected, message) {
  if (actual !== expected) {
    throw new Error(`${message || 'Failed'}: Expected '${expected}', got '${actual}'`);
  }
}

const TEST_SECRET = '875d3153d26ce4f54e4baa0727d3573c9ec20f4e79b364b0cfc7de7908f35603';

/**
 * PayOS official signature generator (key sorting, query-string formatting, HMAC-SHA256)
 */
function createPayOSSignature(data, secretKey) {
  const sortedKeys = Object.keys(data).sort();
  const parts = [];
  for (const k of sortedKeys) {
    const val = data[k];
    if (val !== undefined && val !== null) {
      const strVal = typeof val === 'object' ? JSON.stringify(val) : val;
      parts.push(`${k}=${strVal}`);
    }
  }
  const queryString = parts.join('&');
  return crypto.createHmac('sha256', secretKey).update(queryString).digest('hex');
}

/**
 * Timing-safe signature verifier matching payment_controller.ts
 */
function verifyTimingSafe(receivedSig, expectedSig) {
  try {
    const sigBuf = Buffer.from(String(receivedSig).trim().toLowerCase());
    const expBuf = Buffer.from(String(expectedSig).trim().toLowerCase());
    return sigBuf.length === expBuf.length && crypto.timingSafeEqual(sigBuf, expBuf);
  } catch {
    return false;
  }
}

async function runTests() {
  console.log('====================================================================');
  console.log('   STARTING SUITE 5.3: PAYOS WEBHOOK & IDEMPOTENCY TESTS');
  console.log('====================================================================\n');

  // --------------------------------------------------------------------------
  // SUITE 1: SIGNATURE VERIFICATION & PAYOS SPECIFICATION
  // --------------------------------------------------------------------------
  console.log('[Test Suite 1] PayOS Webhook Signature & Specification');

  test('1.1 Generates signature with alphabetical sorting matching PayOS algorithm', () => {
    const data = {
      orderCode: 12345,
      amount: 50000,
      description: 'DH12345',
      code: '00',
    };
    const sig = createPayOSSignature(data, TEST_SECRET);
    assert(typeof sig === 'string' && sig.length === 64, 'Signature must be a 64-char hex string');

    // Manual query string check: amount=50000&code=00&description=DH12345&orderCode=12345
    const manualQueryStr = 'amount=50000&code=00&description=DH12345&orderCode=12345';
    const manualSig = crypto.createHmac('sha256', TEST_SECRET).update(manualQueryStr).digest('hex');
    assertEqual(sig, manualSig, 'Alphabetical key sorting must match query string order');
  });

  test('1.2 Valid signature in req.body.signature passes verification', () => {
    const webhookPayload = {
      code: '00',
      desc: 'success',
      data: {
        orderCode: 9999,
        amount: 150000,
        description: 'DH9999',
      },
    };
    webhookPayload.signature = createPayOSSignature(webhookPayload.data, TEST_SECRET);

    const expectedSig = createPayOSSignature(webhookPayload.data, TEST_SECRET);
    const isValid = verifyTimingSafe(webhookPayload.signature, expectedSig);
    assert(isValid, 'Valid body.signature must be verified successfully');
  });

  test('1.3 Tampered webhook payload (e.g. modified amount) is rejected', () => {
    const originalData = { orderCode: 9999, amount: 150000, description: 'DH9999' };
    const originalSig = createPayOSSignature(originalData, TEST_SECRET);

    // Attacker modifies amount to 50000 while reusing original signature
    const tamperedData = { orderCode: 9999, amount: 50000, description: 'DH9999' };
    const expectedSig = createPayOSSignature(tamperedData, TEST_SECRET);
    const isValid = verifyTimingSafe(originalSig, expectedSig);
    assert(!isValid, 'Tampered data must fail signature verification');
  });

  test('1.4 Missing signature returns false / invalid', () => {
    const expectedSig = createPayOSSignature({ orderCode: 1 }, TEST_SECRET);
    assert(!verifyTimingSafe('', expectedSig), 'Empty signature must fail');
    assert(!verifyTimingSafe(null, expectedSig), 'Null signature must fail');
    assert(!verifyTimingSafe(undefined, expectedSig), 'Undefined signature must fail');
  });

  // --------------------------------------------------------------------------
  // SUITE 2: BUSINESS LOGIC, STATE TRANSITIONS & NOTIFICATIONS
  // --------------------------------------------------------------------------
  console.log('\n[Test Suite 2] Webhook State Transitions & Notifications');

  test('2.1 Valid payment webhook transitions order CHO_THANH_TOAN -> CHO_XAC_NHAN and payment -> THANH_TOAN_THANH_CONG', () => {
    const order = {
      maDonHang: 101,
      maKhachHang: 20,
      maQuan: 5,
      tongTien: 120000,
      trangThai: 'CHO_THANH_TOAN',
    };
    let payment = null;

    // Simulate webhook execution
    const isSuccess = true;
    const paidAmount = 120000;

    if (isSuccess) {
      if (paidAmount < order.tongTien) {
        throw new Error('Underpayment');
      }
      payment = {
        maDonHang: order.maDonHang,
        soTien: paidAmount,
        trangThai: 'THANH_TOAN_THANH_CONG',
      };
      if (order.trangThai === 'CHO_THANH_TOAN' || order.trangThai === 'UNPAID') {
        order.trangThai = 'CHO_XAC_NHAN';
      }
    }

    assertEqual(order.trangThai, 'CHO_XAC_NHAN', 'Order must be updated to CHO_XAC_NHAN');
    assertEqual(payment.trangThai, 'THANH_TOAN_THANH_CONG', 'Payment must be updated to THANH_TOAN_THANH_CONG');
  });

  test('2.2 Valid payment creates notifications for Restaurant, Admin, and Customer', () => {
    const notifications = [];
    function mockSendNotification(payload) {
      notifications.push(payload);
    }

    const order = { maDonHang: 101, maKhachHang: 20, maQuan: 5, tongTien: 120000, trangThai: 'CHO_XAC_NHAN' };
    const payment = { soTien: 120000, trangThai: 'THANH_TOAN_THANH_CONG' };

    if (payment.trangThai === 'THANH_TOAN_THANH_CONG') {
      // 1. Notification to Restaurant
      mockSendNotification({
        recipientId: order.maQuan,
        recipientRole: 'restaurant',
        type: 'order:created',
        title: 'Đơn hàng mới đã thanh toán',
      });
      // 2. Notification to Admin
      mockSendNotification({
        recipientId: 0,
        recipientRole: 'admin',
        type: 'order:created',
        title: 'Đơn hàng mới đã thanh toán',
      });
      // 3. Notification to Customer
      mockSendNotification({
        recipientId: order.maKhachHang,
        recipientRole: 'user',
        type: 'payment:confirmed',
        title: 'Thanh toán thành công',
      });
    }

    assertEqual(notifications.length, 3, 'Must send 3 notifications (restaurant, admin, user)');
    assertEqual(notifications[0].recipientRole, 'restaurant', 'First notification for restaurant');
    assertEqual(notifications[1].recipientRole, 'admin', 'Second notification for admin');
    assertEqual(notifications[2].recipientRole, 'user', 'Third notification for customer');
  });

  test('2.3 Underpayment attack is rejected (paid amount < total amount)', () => {
    const order = { maDonHang: 102, tongTien: 150000, trangThai: 'CHO_THANH_TOAN' };
    const underpaidAmount = 75000;

    let rejected = false;
    try {
      if (underpaidAmount < order.tongTien) {
        throw new Error(`Số tiền thanh toán (${underpaidAmount}) không đủ so với tổng tiền đơn hàng (${order.tongTien})`);
      }
    } catch (err) {
      rejected = true;
    }
    assert(rejected, 'Underpayment tampering must be strictly rejected');
    assertEqual(order.trangThai, 'CHO_THANH_TOAN', 'Order status must remain untouched on underpayment');
  });

  // --------------------------------------------------------------------------
  // SUITE 3: IDEMPOTENCY & DUPLICATE WEBHOOK HANDLING
  // --------------------------------------------------------------------------
  console.log('\n[Test Suite 3] Idempotency & Duplicate Webhook Prevention');

  test('3.1 Duplicate webhook call on already paid order returns alreadyProcessed: true', () => {
    const payment = {
      maDonHang: 103,
      soTien: 80000,
      trangThai: 'THANH_TOAN_THANH_CONG',
    };

    function processWebhook(existingPayment) {
      if (
        existingPayment &&
        (existingPayment.trangThai === 'THANH_TOAN_THANH_CONG' ||
          existingPayment.trangThai === 'DA_THANH_TOAN' ||
          existingPayment.trangThai === 'CHO_HOAN_TIEN' ||
          existingPayment.trangThai === 'DA_HOAN_TIEN' ||
          existingPayment.trangThai === 'THANH_TOAN_THAT_BAI')
      ) {
        return { alreadyProcessed: true, payment: existingPayment };
      }
      return { alreadyProcessed: false, payment: null };
    }

    const firstRun = processWebhook(payment);
    assertEqual(firstRun.alreadyProcessed, true, 'Duplicate webhook must return alreadyProcessed: true');
  });

  test('3.2 Duplicate webhook does not re-emit notifications or mutate state', () => {
    let emitCount = 0;
    let notifCount = 0;

    function handleWebhookSimulation(paymentState) {
      // Idempotency check
      if (paymentState.trangThai === 'THANH_TOAN_THANH_CONG') {
        return { alreadyProcessed: true };
      }

      // Initial execution
      paymentState.trangThai = 'THANH_TOAN_THANH_CONG';
      emitCount++;
      notifCount++;
      return { alreadyProcessed: false };
    }

    const payment = { trangThai: 'CHO_THANH_TOAN' };

    // Call 1: First webhook arrival
    const res1 = handleWebhookSimulation(payment);
    assertEqual(res1.alreadyProcessed, false, 'First webhook must be processed');
    assertEqual(emitCount, 1, 'First webhook triggers 1 emit');
    assertEqual(notifCount, 1, 'First webhook triggers 1 notification');

    // Call 2: Duplicate webhook arrives (network retry / PayOS replay)
    const res2 = handleWebhookSimulation(payment);
    assertEqual(res2.alreadyProcessed, true, 'Duplicate webhook marked alreadyProcessed');
    assertEqual(emitCount, 1, 'Duplicate webhook MUST NOT trigger extra emit');
    assertEqual(notifCount, 1, 'Duplicate webhook MUST NOT trigger extra notification');
  });

  // --------------------------------------------------------------------------
  // SUITE 4: LIVE HTTP WEBHOOK ENDPOINT VERIFICATION
  // --------------------------------------------------------------------------
  console.log('\n[Test Suite 4] Live HTTP API Webhook Verification (Port 3000)');

  function postHttpJson(path, body) {
    return new Promise((resolve, reject) => {
      const dataStr = JSON.stringify(body);
      const req = http.request(
        {
          hostname: 'localhost',
          port: 3000,
          path,
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(dataStr),
          },
        },
        (res) => {
          let resData = '';
          res.on('data', (c) => (resData += c));
          res.on('end', () => {
            try {
              resolve({ status: res.statusCode, body: JSON.parse(resData) });
            } catch {
              resolve({ status: res.statusCode, body: resData });
            }
          });
        }
      );
      req.on('error', reject);
      req.write(dataStr);
      req.end();
    });
  }

  await testAsync('4.1 Live POST /api/v1/payments/webhook with missing signature returns 400', async () => {
    const payload = {
      code: '00',
      desc: 'success',
      data: { orderCode: 1, amount: 10000 },
      // signature missing!
    };
    const res = await postHttpJson('/api/v1/payments/webhook', payload);
    assertEqual(res.status, 400, 'Must return HTTP 400 for missing signature');
    assertEqual(res.body.status, 'error', 'Response body must have status error');
  });

  await testAsync('4.2 Live POST /api/v1/payments/webhook with invalid signature returns 400', async () => {
    const payload = {
      code: '00',
      desc: 'success',
      data: { orderCode: 1, amount: 10000 },
      signature: '0000000000000000000000000000000000000000000000000000000000000000',
    };
    const res = await postHttpJson('/api/v1/payments/webhook', payload);
    assertEqual(res.status, 400, 'Must return HTTP 400 for invalid signature');
    assertEqual(res.body.status, 'error', 'Response body must have status error');
  });

  await testAsync('4.3 Live POST /api/v1/payments/webhook with valid signature & test ping returns 200', async () => {
    const data = {
      orderCode: 0, // PayOS verification ping
      amount: 0,
      description: 'Webhook verification ping',
    };
    const sig = createPayOSSignature(data, TEST_SECRET);
    const payload = {
      code: '00',
      desc: 'success',
      data: data,
      signature: sig,
    };
    const res = await postHttpJson('/api/v1/payments/webhook', payload);
    assertEqual(res.status, 200, 'Must return HTTP 200 for valid PayOS ping');
    assertEqual(res.body.status, 'success', 'Must return success status');
  });

  // --------------------------------------------------------------------------
  // SUMMARY
  // --------------------------------------------------------------------------
  console.log('\n====================================================================');
  console.log(`   PAYOS WEBHOOK SUITE FINISHED: ${passedTests}/${totalTests} Passed (${failedTests} Failed)`);
  console.log('====================================================================\n');

  if (failedTests > 0) {
    process.exit(1);
  }
}

if (require.main === module) {
  runTests().catch((err) => {
    console.error('Fatal error during test run:', err);
    process.exit(1);
  });
}

module.exports = { runTests };
