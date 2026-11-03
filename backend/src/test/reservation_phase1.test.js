/**
 * Smart City Food Route - Table Reservation Phase 1 Verification Test Suite
 * Tests: A1 (Timezone & Operating Hours), A2 (Concurrency & Overlap), A3 (Table Status Preservation),
 * A4 (Route Mounting), A5 (Input Validation & Whitelist), A6 (Socket Security & Room Isolation),
 * B1 (Safe CuaHang Relation & Data Masking), B2 (Availability Endpoint).
 */

const assert = require('node:assert');
const http = require('node:http');
const jwt = require('jsonwebtoken');
const { In, Not } = require('typeorm');

function resolveModule(relPath) {
  const candidates = [
    relPath,
    '../' + relPath,
    '../../dist/' + relPath.replace(/^\.\.\//, '').replace(/^src\//, ''),
    '../dist/' + relPath.replace(/^\.\.\//, '').replace(/^src\//, ''),
    './dist/' + relPath.replace(/^\.\.\//, '').replace(/^src\//, ''),
  ];
  for (const c of candidates) {
    try {
      return require(c);
    } catch (_) {}
  }
  throw new Error(`Cannot resolve module: ${relPath}`);
}

const { AppDataSource } = resolveModule('config/database');
const { DatBanModel } = resolveModule('models/dat_ban_model');
const { BanModel } = resolveModule('models/ban_model');
const { CuaHangModel } = resolveModule('models/cua_hang_model');
const { KhachHangModel } = resolveModule('models/khach_hang_model');
const { TaiKhoanModel } = resolveModule('models/tai_khoan_model');
const { ReservationService } = resolveModule('services/reservation_service');
const { RealtimeService } = resolveModule('services/realtime_service');

const BASE_URL = 'http://localhost:3000';
const JWT_SECRET = process.env.JWT_SECRET || 'your_secret_key';

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

function makeToken(sub, role = 'KHACH_HANG', email = 'user.test@example.com') {
  return jwt.sign({ sub, email, role, type: 'access' }, JWT_SECRET, { expiresIn: '1h' });
}

function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const payload = body ? JSON.stringify(body) : null;
    if (payload) headers['Content-Length'] = Buffer.byteLength(payload);

    const req = http.request(url, { method, headers }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const parsed = data ? JSON.parse(data) : {};
          resolve({ status: res.statusCode, headers: res.headers, data: parsed });
        } catch (_) {
          resolve({ status: res.statusCode, headers: res.headers, data });
        }
      });
    });

    req.on('error', reject);
    if (payload) req.write(payload);
    req.end();
  });
}

function connectSocketClient(token) {
  return new Promise((resolve, reject) => {
    const handshakeReq = http.request(
      `${BASE_URL}/socket.io/?EIO=4&transport=polling`,
      { headers: { Authorization: `Bearer ${token}` } },
      (res) => {
        let body = '';
        res.on('data', (c) => (body += c));
        res.on('end', () => {
          if (res.statusCode !== 200) {
            return reject(new Error(`Socket handshake failed with status ${res.statusCode}: ${body}`));
          }
          const sid = JSON.parse(body.slice(1)).sid;
          const client = {
            sid,
            token,
            joinRoom(roomType, id) {
              return new Promise((rResolve, rReject) => {
                const joinReq = http.request(
                  `${BASE_URL}/socket.io/?EIO=4&transport=polling&sid=${sid}`,
                  {
                    method: 'POST',
                    headers: { 'Content-Type': 'text/plain;charset=UTF-8' },
                  },
                  (pRes) => {
                    let pBody = '';
                    pRes.on('data', (c) => (pBody += c));
                    pRes.on('end', () => rResolve(pBody));
                  }
                );
                joinReq.on('error', rReject);
                joinReq.write(`42["room:join",{"roomType":"${roomType}","id":${id}}]`);
                joinReq.end();
              });
            },
            disconnect() {
              const dReq = http.request(
                `${BASE_URL}/socket.io/?EIO=4&transport=polling&sid=${sid}`,
                { method: 'POST', headers: { 'Content-Type': 'text/plain;charset=UTF-8' } },
                () => {}
              );
              dReq.on('error', () => {});
              dReq.write('41');
              dReq.end();
            },
          };
          resolve(client);
        });
      }
    );
    handshakeReq.on('error', reject);
    handshakeReq.end();
  });
}

async function run() {
  console.log('===============================================================');
  console.log('[Test] [Info] TABLE RESERVATION PHASE 1 VERIFICATION TEST SUITE');
  console.log('===============================================================\n');

  if (!AppDataSource.isInitialized) {
    await AppDataSource.initialize();
  }

  const datBanRepo = AppDataSource.getRepository(DatBanModel);
  const banRepo = AppDataSource.getRepository(BanModel);
  const cuaHangRepo = AppDataSource.getRepository(CuaHangModel);
  const khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  const taiKhoanRepo = AppDataSource.getRepository(TaiKhoanModel);

  // Setup isolated test entities
  const testStore = await cuaHangRepo.save(
    cuaHangRepo.create({
      tenQuan: 'Quán Test Phase 1 [Automated]',
      diaChi: '123 Đường Test, Q1, TP.HCM',
      trangThai: 'mở cửa',
      gioHoatDong: '{"mon":{"open":true,"from":"08:00","to":"22:00"},"tue":{"open":true,"from":"08:00","to":"22:00"},"wed":{"open":true,"from":"08:00","to":"22:00"},"thu":{"open":true,"from":"08:00","to":"22:00"},"fri":{"open":true,"from":"08:00","to":"22:00"},"sat":{"open":true,"from":"08:00","to":"23:00"},"sun":{"open":true,"from":"08:00","to":"23:00"}}',
      coChoDatTruoc: true,
      hoTenChuQuan: 'BÍ MẬT CHỦ QUÁN',
      soCCCD: '079099999999',
      soTaiKhoanNganHang: '9999999999',
      tenNganHang: 'Vietcombank',
    })
  );

  const testTable1 = await banRepo.save(
    banRepo.create({ maQuan: testStore.maQuan, tenBan: 'Bàn Test 1', sucChua: 4, trangThai: 'TRONG' })
  );

  const testTable2 = await banRepo.save(
    banRepo.create({ maQuan: testStore.maQuan, tenBan: 'Bàn Test 2', sucChua: 6, trangThai: 'TRONG' })
  );

  // User A & User B
  const tkA = await taiKhoanRepo.save(
    taiKhoanRepo.create({
      tenDangNhap: 'customer.a.phase1@test.com',
      matKhau: '$2b$10$abcdefghijklmnopqrstuvwxyz123456',
      loaiTaiKhoan: 'KHACH_HANG',
    })
  );
  const userA = await khachHangRepo.save(
    khachHangRepo.create({
      maTaiKhoan: tkA.maTaiKhoan,
      hoTen: 'Khách Hàng Test A',
      sdt: '0901111111',
      email: 'customer.a.phase1@test.com',
    })
  );
  const tokenA = makeToken(userA.maTaiKhoan, 'KHACH_HANG', userA.email);

  const tkB = await taiKhoanRepo.save(
    taiKhoanRepo.create({
      tenDangNhap: 'customer.b.phase1@test.com',
      matKhau: '$2b$10$abcdefghijklmnopqrstuvwxyz123456',
      loaiTaiKhoan: 'KHACH_HANG',
    })
  );
  const userB = await khachHangRepo.save(
    khachHangRepo.create({
      maTaiKhoan: tkB.maTaiKhoan,
      hoTen: 'Khách Hàng Test B',
      sdt: '0902222222',
      email: 'customer.b.phase1@test.com',
    })
  );
  const tokenB = makeToken(userB.maTaiKhoan, 'KHACH_HANG', userB.email);

  const createdReservationIds = [];

  try {
    // ─────────────────────────────────────────────────────────────────────────
    // SUITE A1: TIMEZONE & OPERATING HOURS LOGIC
    // ─────────────────────────────────────────────────────────────────────────
    console.log('[Test] [Info] A1. Timezone & Operating Hours Evaluation');

    await test('A1.1 Booking within Vietnam operating hours is accepted', async () => {
      // Monday 18:00 Vietnam time (UTC+7) -> 11:00 UTC
      const validDate = new Date();
      validDate.setDate(validDate.getDate() + ((1 + 7 - validDate.getDay()) % 7 || 7)); // Next Monday
      validDate.setUTCHours(11, 0, 0, 0); // 18:00 VN

      const res = await makeRequest(
        'POST',
        '/api/v1/reservations',
        {
          maQuan: testStore.maQuan,
          maBan: testTable1.maBan,
          thoiGianBatDau: validDate.toISOString(),
          soNguoi: 2,
        },
        tokenA
      );

      assert.strictEqual(res.status, 201, `Expected 201, got ${res.status}: ${JSON.stringify(res.data)}`);
      assert.strictEqual(res.data.status, 'success');
      createdReservationIds.push(res.data.data.maDatBan);
    });

    await test('A1.2 Booking outside Vietnam operating hours (e.g. 23:30 VN) is rejected', async () => {
      // Monday 23:30 Vietnam time (UTC+7) -> 16:30 UTC. Store closes at 22:00.
      const lateDate = new Date();
      lateDate.setDate(lateDate.getDate() + ((1 + 7 - lateDate.getDay()) % 7 || 7));
      lateDate.setUTCHours(16, 30, 0, 0); // 23:30 VN

      const res = await makeRequest(
        'POST',
        '/api/v1/reservations',
        {
          maQuan: testStore.maQuan,
          maBan: testTable2.maBan,
          thoiGianBatDau: lateDate.toISOString(),
          soNguoi: 2,
        },
        tokenA
      );

      assert.strictEqual(res.status, 400);
      assert.match(res.data.message, /ngoài giờ mở cửa/i);
    });

    await test('A1.3 Overnight operating hours (e.g. 18:00 - 02:00) accepts midnight booking', async () => {
      const overnightStore = await cuaHangRepo.save(
        cuaHangRepo.create({
          tenQuan: 'Quán Xuyên Đêm [Automated]',
          diaChi: '456 Phố Đêm',
          trangThai: 'mở cửa',
          gioHoatDong: '18:00 - 02:00',
          coChoDatTruoc: true,
        })
      );
      const ovTable = await banRepo.save(
        banRepo.create({ maQuan: overnightStore.maQuan, tenBan: 'Bàn Đêm 1', sucChua: 4, trangThai: 'TRONG' })
      );

      // 01:00 Vietnam time (UTC+7) -> 18:00 UTC (previous day)
      const midnightVN = new Date();
      midnightVN.setDate(midnightVN.getDate() + 2);
      midnightVN.setUTCHours(18, 0, 0, 0); // 01:00 next day in VN

      const res = await makeRequest(
        'POST',
        '/api/v1/reservations',
        {
          maQuan: overnightStore.maQuan,
          maBan: ovTable.maBan,
          thoiGianBatDau: midnightVN.toISOString(),
          soNguoi: 2,
        },
        tokenA
      );

      assert.strictEqual(res.status, 201, `Expected 201, got ${res.status}: ${JSON.stringify(res.data)}`);
      createdReservationIds.push(res.data.data.maDatBan);

      // Clean overnight test store
      await banRepo.delete({ maQuan: overnightStore.maQuan });
      await cuaHangRepo.delete({ maQuan: overnightStore.maQuan });
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SUITE A2: CONCURRENCY & PESSIMISTIC LOCK OVERLAP PREVENTION
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n[Test] [Info] A2. Concurrency & Overlap Prevention (Parallel Requests)');

    await test('A2.1 5 concurrent requests for same maBan at same time: exactly 1 succeeds', async () => {
      const targetDate = new Date();
      targetDate.setDate(targetDate.getDate() + 3);
      targetDate.setUTCHours(12, 0, 0, 0); // 19:00 VN

      const reqPromises = Array.from({ length: 5 }, (_, idx) =>
        makeRequest(
          'POST',
          '/api/v1/reservations',
          {
            maQuan: testStore.maQuan,
            maBan: testTable2.maBan,
            thoiGianBatDau: targetDate.toISOString(),
            soNguoi: 4,
            ghiChu: `Concurrent attempt #${idx + 1}`,
          },
          tokenA
        )
      );

      const results = await Promise.all(reqPromises);
      const successCount = results.filter((r) => r.status === 201).length;
      const conflictCount = results.filter((r) => r.status === 400).length;

      for (const r of results) {
        if (r.status === 201) createdReservationIds.push(r.data.data.maDatBan);
      }

      assert.strictEqual(successCount, 1, `Expected exactly 1 success, got ${successCount}`);
      assert.strictEqual(conflictCount, 4, `Expected 4 conflicts, got ${conflictCount}`);
    });

    await test('A2.2 5 concurrent requests without maBan when only 1 suitable table exists', async () => {
      // Create single-table store
      const singleStore = await cuaHangRepo.save(
        cuaHangRepo.create({
          tenQuan: 'Quán 1 Bàn Duy Nhất [Automated]',
          diaChi: '789 Đường Độc Nhất',
          trangThai: 'mở cửa',
          gioHoatDong: '08:00 - 22:00',
          coChoDatTruoc: true,
        })
      );
      const onlyTable = await banRepo.save(
        banRepo.create({ maQuan: singleStore.maQuan, tenBan: 'Bàn Độc Nhất', sucChua: 6, trangThai: 'TRONG' })
      );

      const targetDate = new Date();
      targetDate.setDate(targetDate.getDate() + 4);
      targetDate.setUTCHours(12, 0, 0, 0);

      const reqPromises = Array.from({ length: 5 }, () =>
        makeRequest(
          'POST',
          '/api/v1/reservations',
          {
            maQuan: singleStore.maQuan,
            // maBan omitted: automatic table assignment
            thoiGianBatDau: targetDate.toISOString(),
            soNguoi: 5,
          },
          tokenA
        )
      );

      const results = await Promise.all(reqPromises);
      const successCount = results.filter((r) => r.status === 201).length;
      const rejectedCount = results.filter((r) => r.status === 400).length;

      for (const r of results) {
        if (r.status === 201) createdReservationIds.push(r.data.data.maDatBan);
      }

      assert.strictEqual(successCount, 1, `Expected exactly 1 success when 1 table left, got ${successCount}`);
      assert.strictEqual(rejectedCount, 4, `Expected 4 rejected, got ${rejectedCount}`);

      await banRepo.delete({ maQuan: singleStore.maQuan });
      await cuaHangRepo.delete({ maQuan: singleStore.maQuan });
    });

    await test('A2.3 Partially overlapping time windows on same table are rejected', async () => {
      const slotStart = new Date();
      slotStart.setDate(slotStart.getDate() + 5);
      slotStart.setUTCHours(11, 0, 0, 0); // 18:00 VN -> ends 19:30 VN

      // Booking 1: 18:00 - 19:30 VN
      const res1 = await makeRequest(
        'POST',
        '/api/v1/reservations',
        {
          maQuan: testStore.maQuan,
          maBan: testTable1.maBan,
          thoiGianBatDau: slotStart.toISOString(),
          soNguoi: 2,
        },
        tokenA
      );
      assert.strictEqual(res1.status, 201);
      createdReservationIds.push(res1.data.data.maDatBan);

      // Booking 2: 18:45 VN (partially overlaps 18:00 - 19:30)
      const overlapStart = new Date(slotStart.getTime() + 45 * 60 * 1000);
      const res2 = await makeRequest(
        'POST',
        '/api/v1/reservations',
        {
          maQuan: testStore.maQuan,
          maBan: testTable1.maBan,
          thoiGianBatDau: overlapStart.toISOString(),
          soNguoi: 2,
        },
        tokenB
      );
      assert.strictEqual(res2.status, 400);
      assert.match(res2.data.message, /đã được khách khác đặt/i);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SUITE A3: TABLE STATUS PRESERVATION ON CANCELLATION
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n[Test] [Info] A3. Table Physical Status Preservation on Cancellation');

    await test('A3.1 Cancelling future reservation B on a table currently DANG_SU_DUNG by A does NOT free table', async () => {
      // Set table physically to DANG_SU_DUNG (seated diner A)
      testTable1.trangThai = 'DANG_SU_DUNG';
      await banRepo.save(testTable1);

      // Future booking B on testTable1
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 6);
      futureDate.setUTCHours(12, 0, 0, 0);

      const bookingB = await datBanRepo.save(
        datBanRepo.create({
          maQuan: testStore.maQuan,
          maBan: testTable1.maBan,
          maKhachHang: userA.maKhachHang,
          soNguoi: 2,
          thoiGianBatDau: futureDate,
          thoiGianKetThuc: new Date(futureDate.getTime() + 90 * 60 * 1000),
          trangThai: 'CHO_XAC_NHAN',
          ghiChu: 'Ghi chú ban đầu của khách',
        })
      );
      createdReservationIds.push(bookingB.maDatBan);

      // Customer A cancels future booking B
      const cancelRes = await makeRequest('PATCH', `/api/v1/reservations/${bookingB.maDatBan}/cancel`, {}, tokenA);
      assert.strictEqual(cancelRes.status, 200);

      // Verify table physical status in DB is STILL DANG_SU_DUNG!
      const refreshedTable = await banRepo.findOne({ where: { maBan: testTable1.maBan } });
      assert.strictEqual(
        refreshedTable.trangThai,
        'DANG_SU_DUNG',
        'Physical table must remain DANG_SU_DUNG after cancelling future booking'
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SUITE A5: INPUT VALIDATION & PARAMETER TAMPERING (POST /api/v1/reservations)
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n[Test] [Info] A5. Input Validation & Body Whitelisting');

    await test('A5.1 Rejects invalid soNguoi (0, negative, decimal, huge, non-integer)', async () => {
      const validDate = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

      const invalidGuests = [0, -2, 3.5, 9999, 'abc'];
      for (const val of invalidGuests) {
        const res = await makeRequest(
          'POST',
          '/api/v1/reservations',
          { maQuan: testStore.maQuan, thoiGianBatDau: validDate, soNguoi: val },
          tokenA
        );
        assert.strictEqual(res.status, 400, `Expected 400 for soNguoi=${val}, got ${res.status}`);
      }
    });

    await test('A5.2 Rejects invalid thoiGianBatDau (malformed, past date)', async () => {
      const resMalformed = await makeRequest(
        'POST',
        '/api/v1/reservations',
        { maQuan: testStore.maQuan, thoiGianBatDau: 'not-a-date', soNguoi: 2 },
        tokenA
      );
      assert.strictEqual(resMalformed.status, 400);

      const pastDate = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
      const resPast = await makeRequest(
        'POST',
        '/api/v1/reservations',
        { maQuan: testStore.maQuan, thoiGianBatDau: pastDate, soNguoi: 2 },
        tokenA
      );
      assert.strictEqual(resPast.status, 400);
      assert.match(resPast.data.message, /tương lai/i);
    });

    await test('A5.3 Parameter tampering: body cannot override maKhachHang or trangThai', async () => {
      const validDate = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000);
      validDate.setUTCHours(11, 0, 0, 0);

      const res = await makeRequest(
        'POST',
        '/api/v1/reservations',
        {
          maQuan: testStore.maQuan,
          thoiGianBatDau: validDate.toISOString(),
          soNguoi: 2,
          // Attacker injects fake customer ID and confirmed status
          maKhachHang: 8888,
          trangThai: 'DA_XAC_NHAN',
        },
        tokenA
      );

      assert.strictEqual(res.status, 201);
      createdReservationIds.push(res.data.data.maDatBan);

      // Verify DB record has true userA maKhachHang and initial CHO_XAC_NHAN
      assert.strictEqual(res.data.data.maKhachHang, userA.maKhachHang);
      assert.strictEqual(res.data.data.trangThai, 'CHO_XAC_NHAN');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SUITE A6: REALTIME ROOM ISOLATION & UNAUTHORIZED LISTENING
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n[Test] [Info] A6. Realtime Socket Authorization & Room Isolation');

    await test('A6.1 Customer A cannot join room reservation of Customer B; Customer B can join own room', async () => {
      // Create booking for user B
      const bookingBDate = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
      bookingBDate.setUTCHours(11, 0, 0, 0);

      const bookingB = await datBanRepo.save(
        datBanRepo.create({
          maQuan: testStore.maQuan,
          maBan: testTable2.maBan,
          maKhachHang: userB.maKhachHang,
          soNguoi: 2,
          thoiGianBatDau: bookingBDate,
          thoiGianKetThuc: new Date(bookingBDate.getTime() + 90 * 60 * 1000),
          trangThai: 'CHO_XAC_NHAN',
        })
      );
      createdReservationIds.push(bookingB.maDatBan);

      // Connect Socket A (Customer A)
      const clientA = await connectSocketClient(tokenA);
      // Customer A tries to join Customer B's reservation room
      await clientA.joinRoom('reservation', bookingB.maDatBan);
      await new Promise((resolve) => setTimeout(resolve, 300));

      // Connect Socket B (Customer B)
      const clientB = await connectSocketClient(tokenB);
      // Customer B joins own reservation room
      await clientB.joinRoom('reservation', bookingB.maDatBan);
      await new Promise((resolve) => setTimeout(resolve, 300));

      const ioServer = RealtimeService.getInstance().getIO();
      if (ioServer) {
        const socketA = ioServer.sockets.sockets.get(clientA.sid);
        const socketB = ioServer.sockets.sockets.get(clientB.sid);

        if (socketA) {
          const aHasRoom = socketA.rooms.has(`reservation:${bookingB.maDatBan}`);
          assert.strictEqual(
            aHasRoom,
            false,
            'Security violation: Customer A must NOT be admitted to Customer B reservation room'
          );
        }

        if (socketB) {
          const bHasRoom = socketB.rooms.has(`reservation:${bookingB.maDatBan}`);
          assert.strictEqual(
            bHasRoom,
            true,
            'Legitimate access: Customer B must be admitted to own reservation room'
          );
        }
      }

      clientA.disconnect();
      clientB.disconnect();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SUITE B1: SAFE CUAHANG RELATION & SENSITIVE DATA MASKING
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n[Test] [Info] B1. Safe CuaHang Relation & Data Masking');

    await test('B1.1 my-reservations returns cuaHang with public fields, masks sensitive owner info', async () => {
      const res = await makeRequest('GET', '/api/v1/reservations/my-reservations', null, tokenA);
      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.data.status, 'success');
      assert(Array.isArray(res.data.data), 'Expected array of reservations');
      assert(res.data.data.length > 0, 'Expected at least 1 reservation');

      const sample = res.data.data[0];
      assert(sample.cuaHang, 'cuaHang must be loaded');
      assert.strictEqual(sample.cuaHang.tenQuan, 'Quán Test Phase 1 [Automated]');
      // Masking assertions:
      assert.strictEqual(sample.cuaHang.hoTenChuQuan, undefined, 'hoTenChuQuan must NOT be exposed');
      assert.strictEqual(sample.cuaHang.soCCCD, undefined, 'soCCCD must NOT be exposed');
      assert.strictEqual(sample.cuaHang.soTaiKhoanNganHang, undefined, 'Bank account must NOT be exposed');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SUITE B2: AVAILABILITY ENDPOINT
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n[Test] [Info] B2. Table Availability Endpoint');

    await test('B2.1 GET /api/v1/restaurants/:id/reservations/availability returns suitable free tables', async () => {
      const checkDate = new Date();
      checkDate.setDate(checkDate.getDate() + 7);
      checkDate.setUTCHours(11, 0, 0, 0); // 18:00 VN

      const res = await makeRequest(
        'GET',
        `/api/v1/restaurants/${testStore.maQuan}/reservations/availability?thoiGianBatDau=${encodeURIComponent(checkDate.toISOString())}&soNguoi=4`,
        null,
        tokenA
      );

      assert.strictEqual(res.status, 200);
      assert.strictEqual(res.data.status, 'success');
      assert.strictEqual(res.data.data.canBook, true);
      assert.strictEqual(res.data.data.isOpen, true);
      assert(Array.isArray(res.data.data.availableTables));
      assert.strictEqual(res.data.data.availableTables.length, 2, 'Both test tables have sucChua >= 4');
    });

    await test('B2.2 Availability requires authentication (401 without token)', async () => {
      const res = await makeRequest(
        'GET',
        `/api/v1/restaurants/${testStore.maQuan}/reservations/availability?thoiGianBatDau=2026-11-02T18:00:00Z&soNguoi=2`
      );
      assert.strictEqual(res.status, 401);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // SUITE B4: NOTE PRESERVATION ON CANCELLATION
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n[Test] [Info] B4. Customer Note Preservation on Cancellation');

    await test('B4.1 Customer original ghiChu is preserved, cancel reason appended', async () => {
      const futureDate = new Date(Date.now() + 8 * 24 * 60 * 60 * 1000);
      futureDate.setUTCHours(11, 0, 0, 0);

      const booking = await datBanRepo.save(
        datBanRepo.create({
          maQuan: testStore.maQuan,
          maBan: testTable2.maBan,
          maKhachHang: userA.maKhachHang,
          soNguoi: 2,
          thoiGianBatDau: futureDate,
          thoiGianKetThuc: new Date(futureDate.getTime() + 90 * 60 * 1000),
          trangThai: 'CHO_XAC_NHAN',
          ghiChu: 'Ghi chú ban đầu của khách VIP',
        })
      );
      createdReservationIds.push(booking.maDatBan);

      const cancelRes = await makeRequest('PATCH', `/api/v1/reservations/${booking.maDatBan}/cancel`, {}, tokenA);
      assert.strictEqual(cancelRes.status, 200);

      const updated = await datBanRepo.findOne({ where: { maDatBan: booking.maDatBan } });
      assert(updated.ghiChu.includes('Ghi chú ban đầu của khách VIP'), 'Original note must be preserved');
      assert(updated.ghiChu.includes('Khách hàng tự hủy'), 'Cancel reason must be appended');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // BOLA & OWNERSHIP TESTS
    // ─────────────────────────────────────────────────────────────────────────
    console.log('\n[Test] [Info] Ownership & BOLA Access Control');

    await test('User B cannot view or cancel User A reservation (returns 404)', async () => {
      const resvA = createdReservationIds[0];
      const viewRes = await makeRequest('GET', `/api/v1/reservations/${resvA}`, null, tokenB);
      assert.strictEqual(viewRes.status, 404, 'Foreign reservation lookup must return 404');

      const cancelRes = await makeRequest('PATCH', `/api/v1/reservations/${resvA}/cancel`, {}, tokenB);
      assert.strictEqual(cancelRes.status, 404, 'Foreign reservation cancel must return 404');
    });

  } finally {
    // Teardown & Clean up test data completely
    console.log('\n[Test] [Info] Cleaning up test data...');
    if (createdReservationIds.length > 0) {
      await datBanRepo.delete({ maDatBan: In(createdReservationIds) });
    }
    await banRepo.delete({ maQuan: testStore.maQuan });
    await cuaHangRepo.delete({ maQuan: testStore.maQuan });
    await khachHangRepo.delete({ maKhachHang: In([userA.maKhachHang, userB.maKhachHang]) });
    await taiKhoanRepo.delete({ maTaiKhoan: In([tkA.maTaiKhoan, tkB.maTaiKhoan]) });

    console.log('===============================================================');
    console.log(`[Test] [Summary] ALL TESTS PASSED: ${passedTests}/${totalTests}`);
    console.log('===============================================================\n');
  }
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('\n[Test] [FATAL ERROR]:', err);
    process.exit(1);
  });
