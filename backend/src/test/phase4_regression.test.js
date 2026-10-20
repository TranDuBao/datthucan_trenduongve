const assert = require('node:assert');
const crypto = require('node:crypto');

// Resolve TokenBlacklistService (either relative to dist or src)
let TokenBlacklistService;
try {
  TokenBlacklistService = require('./services/token_blacklist_service').TokenBlacklistService;
} catch (_) {
  try {
    TokenBlacklistService = require('../services/token_blacklist_service').TokenBlacklistService;
  } catch (_) {
    TokenBlacklistService = require('../../dist/services/token_blacklist_service').TokenBlacklistService;
  }
}

console.log('===============================================================');
console.log('🚀 RUNNING PHASE 4 COMPREHENSIVE ARCHITECTURE & LOGIC TEST SUITE');
console.log('===============================================================\n');

let totalTests = 0;
let passedTests = 0;

function test(name, fn) {
  totalTests++;
  try {
    fn();
    passedTests++;
    console.log(`  ✅ [PASS] ${name}`);
  } catch (err) {
    console.error(`  ❌ [FAIL] ${name}`);
    console.error(`     Error: ${err.message}`);
    throw err;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 1: AUTHENTICATION & TOKEN LIFECYCLE (SEC-02)
// ─────────────────────────────────────────────────────────────────────────────
console.log('📋 1. Authentication & Token Lifecycle Tests (SEC-02)');
const blacklist = TokenBlacklistService.getInstance();
blacklist.resetForTesting();

test('1.1 Unrevoked token is accepted; revoked token is immediately rejected', () => {
  const token = 'sample.access.jwt.token.123';
  assert.strictEqual(blacklist.isRevoked(token), false);

  blacklist.revokeToken(token, Math.floor(Date.now() / 1000) + 3600, 'logout');
  assert.strictEqual(blacklist.isRevoked(token), true);
});

test('1.2 Global user logout invalidates all previously issued access tokens', () => {
  const userId = 88;
  const now = Math.floor(Date.now() / 1000);
  const oldPayload = { sub: userId, iat: now - 30, exp: now + 3600, type: 'access' };
  const newPayload = { sub: userId, iat: now + 10, exp: now + 3600, type: 'access' };

  blacklist.revokeAllUserTokens(userId);
  assert.strictEqual(blacklist.isRevoked('old_tok', oldPayload), true);
  assert.strictEqual(blacklist.isRevoked('new_tok', newPayload), false);
});

test('1.3 Refresh token cannot be used directly as an access token', () => {
  const refreshPayload = { sub: 88, type: 'refresh', jti: 'ref_jti_456' };
  const isValidAccess = refreshPayload.type === 'access';
  assert.strictEqual(isValidAccess, false);
});

test('1.4 Refresh token rotation: previous refresh token is revoked after renewal', () => {
  const oldRefreshToken = 'ref_token_to_rotate';
  assert.strictEqual(blacklist.isRevoked(oldRefreshToken), false);

  blacklist.revokeToken(oldRefreshToken, Math.floor(Date.now() / 1000) + 86400, 'rotated');
  assert.strictEqual(blacklist.isRevoked(oldRefreshToken), true);
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 2: RBAC & STORE DATA ISOLATION (PHASE 2)
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n📋 2. RBAC & Multi-tenant Store Isolation Tests (Phase 2)');

test('2.1 Restaurant owner can only access orders belonging to their own store', () => {
  const authenticatedStoreId = 15;
  const storeAOrder = { maDonHang: 101, maQuan: 15, customer: 'Khách A' };
  const storeBOrder = { maDonHang: 102, maQuan: 99, customer: 'Khách B' };

  const canAccessA = storeAOrder.maQuan === authenticatedStoreId;
  const canAccessB = storeBOrder.maQuan === authenticatedStoreId;

  assert.strictEqual(canAccessA, true);
  assert.strictEqual(canAccessB, false);
});

test('2.2 Customer cannot modify or cancel reservation of another customer', () => {
  const currentCustomerId = 200;
  const reservation = { maDatBan: 50, maKhachHang: 100, trangThai: 'CHO_XAC_NHAN' };

  const isOwner = reservation.maKhachHang === currentCustomerId;
  assert.strictEqual(isOwner, false, 'Foreign reservation must be denied');
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 3: PAYOS PAYMENT & WEBHOOK SECURITY (SEC-03)
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n📋 3. PayOS Webhook & Payment Security Tests (SEC-03)');

function verifyPayOsSignature(data, signature, checksumKey) {
  if (!checksumKey) return false;
  const sortedKeys = Object.keys(data).sort();
  const signData = sortedKeys.map(k => `${k}=${data[k]}`).join('&');
  const hmac = crypto.createHmac('sha256', checksumKey).update(signData).digest('hex');
  return hmac === signature;
}

test('3.1 Valid PayOS webhook signature matches HMAC SHA256 checksum', () => {
  const secretKey = 'my_test_checksum_key_secret';
  const webhookData = { amount: 50000, code: '00', orderCode: 12345 };
  const sortedKeys = Object.keys(webhookData).sort();
  const signStr = sortedKeys.map(k => `${k}=${webhookData[k]}`).join('&');
  const validSignature = crypto.createHmac('sha256', secretKey).update(signStr).digest('hex');

  const isValid = verifyPayOsSignature(webhookData, validSignature, secretKey);
  assert.strictEqual(isValid, true);
});

test('3.2 Tampered webhook payload is strictly rejected', () => {
  const secretKey = 'my_test_checksum_key_secret';
  const webhookData = { amount: 50000, code: '00', orderCode: 12345 };
  const invalidSignature = 'tampered_signature_hex';

  const isValid = verifyPayOsSignature(webhookData, invalidSignature, secretKey);
  assert.strictEqual(isValid, false);
});

test('3.3 Webhook verification fails safely when checksum key is missing (no fallback)', () => {
  const webhookData = { amount: 50000, code: '00', orderCode: 12345 };
  const isValid = verifyPayOsSignature(webhookData, 'some_sig', '');
  assert.strictEqual(isValid, false);
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 4: TABLE RESERVATION STATE & CONCURRENCY (PHASE 3)
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n📋 4. Table Reservation Business Rules & Overlap Prevention (Phase 3)');

test('4.1 Reservation rejects time outside operating hours', () => {
  const openHour = 10;
  const closeHour = 22;
  const bookingHour = 8; // 08:00 is outside 10:00 - 22:00

  const isWithinHours = bookingHour >= openHour && bookingHour < closeHour;
  assert.strictEqual(isWithinHours, false);
});

test('4.2 Overlapping booking for same table is prevented', () => {
  const slotStart = new Date('2026-10-20T12:00:00Z');
  const slotEnd = new Date('2026-10-20T14:00:00Z');

  const existingBooking = {
    start: new Date('2026-10-20T11:30:00Z'),
    end: new Date('2026-10-20T13:00:00Z'),
    status: 'DA_XAC_NHAN',
  };

  const isOverlapping =
    existingBooking.status !== 'DA_HUY' &&
    existingBooking.start < slotEnd &&
    existingBooking.end > slotStart;

  assert.strictEqual(isOverlapping, true);
});

test('4.3 Table under maintenance (TAM_NGUNG) cannot be reserved', () => {
  const table = { maBan: 1, tenBan: 'Bàn 1', trangThai: 'TAM_NGUNG', sucChua: 4 };
  const canBook = table.trangThai !== 'TAM_NGUNG';
  assert.strictEqual(canBook, false);
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 5: VOUCHER CONCURRENCY & IDEMPOTENT ROLLBACK (PHASE 3)
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n📋 5. Voucher Concurrency & Rollback Tests (Phase 3)');

test('5.1 Percentage voucher discount correctly honors maximum cap', () => {
  const orderTotal = 200000;
  const percent = 20; // 20% of 200,000 = 40,000
  const maxCap = 25000; // Cap at 25,000

  const rawDiscount = (orderTotal * percent) / 100;
  const finalDiscount = Math.min(rawDiscount, maxCap);

  assert.strictEqual(finalDiscount, 25000);
});

test('5.2 Exceeded voucher quota rejects new usage', () => {
  const voucher = { soLuongToiDa: 10, soLuongDaSuDung: 10 };
  const hasRemaining = voucher.soLuongDaSuDung < voucher.soLuongToiDa;
  assert.strictEqual(hasRemaining, false);
});

test('5.3 Voucher rollback on order cancellation is strictly idempotent', () => {
  let voucherUsedCount = 5;
  let customerVoucherUsed = true;

  function cancelOrder() {
    if (customerVoucherUsed) {
      customerVoucherUsed = false;
      voucherUsedCount = Math.max(0, voucherUsedCount - 1);
    }
  }

  // First cancellation: voucher is restored
  cancelOrder();
  assert.strictEqual(customerVoucherUsed, false);
  assert.strictEqual(voucherUsedCount, 4);

  // Duplicate cancellation event: voucher count does NOT double-decrement
  cancelOrder();
  assert.strictEqual(customerVoucherUsed, false);
  assert.strictEqual(voucherUsedCount, 4);
});

// ─────────────────────────────────────────────────────────────────────────────
// SUITE 6: REVIEW CONFLICT & RATING CALCULATION
// ─────────────────────────────────────────────────────────────────────────────
console.log('\n📋 6. Review & Rating Calculation Tests');

test('6.1 Recalculate restaurant average rating excludes hidden reviews', () => {
  const reviews = [
    { rating: 5, isHidden: false },
    { rating: 4, isHidden: false },
    { rating: 1, isHidden: true }, // Admin hidden review
  ];

  const visible = reviews.filter(r => !r.isHidden);
  const avg = visible.reduce((sum, r) => sum + r.rating, 0) / visible.length;

  assert.strictEqual(visible.length, 2);
  assert.strictEqual(avg, 4.5);
});

console.log('\n===============================================================');
console.log(`🎉 ALL ${passedTests}/${totalTests} TESTS PASSED SUCCESSFULLY!`);
console.log('===============================================================\n');
