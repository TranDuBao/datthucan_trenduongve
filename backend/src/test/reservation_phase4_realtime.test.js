const http = require('http');
const jwt = require('jsonwebtoken');
const { AppDataSource } = require('/app/dist/config/database');
const { TaiKhoanModel } = require('/app/dist/models/tai_khoan_model');
const { KhachHangModel } = require('/app/dist/models/khach_hang_model');
const { CuaHangModel } = require('/app/dist/models/cua_hang_model');
const { BanModel } = require('/app/dist/models/ban_model');
const { DatBanModel } = require('/app/dist/models/dat_ban_model');
const { RealtimeService } = require('/app/dist/services/realtime_service');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const PORT = 3000;

function generateToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' });
}

function httpRequest(options, body) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          const parsed = data ? JSON.parse(data) : {};
          resolve({ statusCode: res.statusCode, data: parsed, raw: data });
        } catch (e) {
          resolve({ statusCode: res.statusCode, raw: data });
        }
      });
    });
    req.on('error', reject);
    if (body) {
      req.write(typeof body === 'string' ? body : JSON.stringify(body));
    }
    req.end();
  });
}

// Minimal Socket.io client over HTTP polling
class SimpleSocketClient {
  constructor(token) {
    this.token = token;
    this.sid = null;
    this.events = [];
    this.polling = false;
  }

  async connect() {
    const handshakeUrl = `/socket.io/?EIO=4&transport=polling&t=${Date.now()}`;
    const authPayload = JSON.stringify({ token: this.token });
    const packet = `40${authPayload}`;

    const res = await httpRequest({
      hostname: 'localhost',
      port: PORT,
      path: handshakeUrl,
      method: 'GET',
    });

    const openPacket = res.raw.substring(res.raw.indexOf('{'));
    const parsed = JSON.parse(openPacket);
    this.sid = parsed.sid;

    // Send auth packet
    await httpRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: `/socket.io/?EIO=4&transport=polling&sid=${this.sid}`,
        method: 'POST',
        headers: { 'Content-Type': 'text/plain;charset=UTF-8' },
      },
      packet
    );

    this.startPolling();
  }

  startPolling() {
    this.polling = true;
    const poll = async () => {
      if (!this.polling) return;
      try {
        const res = await httpRequest({
          hostname: 'localhost',
          port: PORT,
          path: `/socket.io/?EIO=4&transport=polling&sid=${this.sid}&t=${Date.now()}`,
          method: 'GET',
        });
        if (res.raw) {
          this.parsePackets(res.raw);
        }
      } catch (e) {}
      if (this.polling) {
        setTimeout(poll, 100);
      }
    };
    poll();
  }

  parsePackets(raw) {
    const parts = raw.split('\x1e');
    for (const part of parts) {
      if (part === '2') {
        // EIO ping -> reply pong '3'
        httpRequest(
          {
            hostname: 'localhost',
            port: PORT,
            path: `/socket.io/?EIO=4&transport=polling&sid=${this.sid}`,
            method: 'POST',
            headers: { 'Content-Type': 'text/plain;charset=UTF-8' },
          },
          '3'
        ).catch(() => {});
      } else if (part.startsWith('42')) {
        try {
          const parsed = JSON.parse(part.substring(2));
          this.events.push({ event: parsed[0], data: parsed[1] });
        } catch (e) {
          console.log('[Test] [Debug] Failed to parse packet:', part, e.message);
        }
      }
    }
  }

  async emit(event, data) {
    const packet = `42${JSON.stringify([event, data])}`;
    await httpRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: `/socket.io/?EIO=4&transport=polling&sid=${this.sid}`,
        method: 'POST',
        headers: { 'Content-Type': 'text/plain;charset=UTF-8' },
      },
      packet
    );
  }

  clearEvents() {
    this.events = [];
  }

  waitForEvent(eventName, predicate = null, timeoutMs = 4000) {
    return new Promise((resolve, reject) => {
      const startTime = Date.now();
      const check = () => {
        const idx = this.events.findIndex((e) => {
          if (e.event !== eventName) return false;
          if (typeof predicate === 'function' && !predicate(e.data)) return false;
          return true;
        });
        if (idx !== -1) {
          const found = this.events.splice(idx, 1)[0];
          return resolve(found.data);
        }
        if (Date.now() - startTime > timeoutMs) {
          return reject(new Error(`Timeout waiting for event [${eventName}]`));
        }
        setTimeout(check, 50);
      };
      check();
    });
  }

  disconnect() {
    this.polling = false;
  }
}

async function runRealtimeSyncTests() {
  console.log('===============================================================');
  console.log('[Test] [Info] PHASE 4: 2-WAY REALTIME SOCKET.IO SYNC TEST SUITE');
  console.log('===============================================================');

  if (!AppDataSource.isInitialized) {
    await AppDataSource.initialize();
  }

  const tkRepo = AppDataSource.getRepository(TaiKhoanModel);
  const khRepo = AppDataSource.getRepository(KhachHangModel);
  const storeRepo = AppDataSource.getRepository(CuaHangModel);
  const banRepo = AppDataSource.getRepository(BanModel);
  const resvRepo = AppDataSource.getRepository(DatBanModel);

  // Setup Accounts: Store Owner (Web) and Customer (Mobile)
  const timestamp = Date.now();
  const ownerAccount = await tkRepo.save(
    tkRepo.create({
      tenDangNhap: `owner_rt_${timestamp}`,
      matKhau: 'hash123',
      loaiTaiKhoan: 'STORE',
      trangThai: 'HOAT_DONG',
    })
  );

  const customerAccount = await tkRepo.save(
    tkRepo.create({
      tenDangNhap: `cust_rt_${timestamp}`,
      matKhau: 'hash123',
      loaiTaiKhoan: 'CUSTOMER',
      trangThai: 'HOAT_DONG',
    })
  );

  const foreignAccount = await tkRepo.save(
    tkRepo.create({
      tenDangNhap: `foreign_rt_${timestamp}`,
      matKhau: 'hash123',
      loaiTaiKhoan: 'CUSTOMER',
      trangThai: 'HOAT_DONG',
    })
  );

  const customer = await khRepo.save(
    khRepo.create({
      maTaiKhoan: customerAccount.maTaiKhoan,
      hoTen: 'Khách Hàng Realtime',
      sdt: '0901234888',
      email: `cust_${timestamp}@test.com`,
    })
  );

  const foreignCustomer = await khRepo.save(
    khRepo.create({
      maTaiKhoan: foreignAccount.maTaiKhoan,
      hoTen: 'Khách Hàng Xa Lạ',
      sdt: '0909999888',
      email: `foreign_${timestamp}@test.com`,
    })
  );

  const store = await storeRepo.save(
    storeRepo.create({
      maTaiKhoan: ownerAccount.maTaiKhoan,
      tenQuan: 'Quán Ăn Đồng Bộ Realtime',
      diaChi: '99 Lộ Trình FoodRoute',
      gioHoatDong: '00:00 - 23:59',
      coChoDatTruoc: true,
      trangThai: 'HOAT_DONG',
    })
  );

  const table = await banRepo.save(
    banRepo.create({
      maQuan: store.maQuan,
      tenBan: 'Bàn Realtime 1',
      sucChua: 4,
      trangThai: 'TRONG',
    })
  );

  const ownerToken = generateToken({ sub: ownerAccount.maTaiKhoan, role: 'STORE' });
  const customerToken = generateToken({ sub: customerAccount.maTaiKhoan, role: 'CUSTOMER' });
  const foreignToken = generateToken({ sub: foreignAccount.maTaiKhoan, role: 'CUSTOMER' });

  // Connect socket clients
  const restaurantWebClient = new SimpleSocketClient(ownerToken);
  await restaurantWebClient.connect();

  const customerMobileClient = new SimpleSocketClient(customerToken);
  await customerMobileClient.connect();

  const foreignClient = new SimpleSocketClient(foreignToken);
  await foreignClient.connect();

  // Wait 300ms for connection & room assignment
  await new Promise((r) => setTimeout(r, 300));

  let createdReservationId = null;

  try {
    // -------------------------------------------------------------
    // SCENARIO 1: Customer creates reservation on Mobile -> Restaurant receives reservation:created on Web
    // -------------------------------------------------------------
    console.log('\n[Test] [Info] Scenario 1: Customer creates reservation -> Web receives reservation:created');
    const tomorrow = new Date(Date.now() + 86400000);
    tomorrow.setUTCHours(12, 0, 0, 0);

    const postPromise = httpRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/v1/reservations',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${customerToken}`,
        },
      },
      {
        maQuan: store.maQuan,
        thoiGianBatDau: tomorrow.toISOString(),
        soNguoi: 4,
        maBan: table.maBan,
        ghiChu: 'Gần ban công',
        tenKhachHang: 'Khách Hàng Realtime',
        sdtKhachHang: '0901234888',
      }
    );

    const webEventPromise = restaurantWebClient.waitForEvent('reservation:created', 4000);
    const [createRes, webEvent] = await Promise.all([postPromise, webEventPromise]);

    if (createRes.statusCode !== 201) {
      throw new Error(`Failed to create reservation: ${createRes.raw}`);
    }
    createdReservationId = createRes.data.data.maDatBan;

    if (webEvent.id !== createdReservationId || webEvent.status !== 'CHO_XAC_NHAN') {
      throw new Error(`Invalid webEvent payload: ${JSON.stringify(webEvent)}`);
    }
    console.log(`  [Test] [Pass] Scenario 1: Restaurant received reservation:created for #${createdReservationId}`);

    // Join reservation room on mobile client
    await customerMobileClient.emit('room:join', { roomType: 'reservation', id: createdReservationId });
    await new Promise((r) => setTimeout(r, 200));

    // -------------------------------------------------------------
    // SCENARIO 2: Restaurant confirms reservation on Web -> Mobile receives reservation:status_changed (DA_XAC_NHAN)
    // -------------------------------------------------------------
    console.log('\n[Test] [Info] Scenario 2: Restaurant confirms on Web -> Mobile receives DA_XAC_NHAN');
    const confirmPromise = httpRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/v1/restaurant/reservations/${createdReservationId}/confirm`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ownerToken}`,
      },
    });

    const mobileConfirmEventPromise = customerMobileClient.waitForEvent('reservation:status_changed', 4000);
    const [confirmRes, confirmEvent] = await Promise.all([confirmPromise, mobileConfirmEventPromise]);

    if (confirmRes.statusCode !== 200) {
      throw new Error(`Failed to confirm reservation: ${confirmRes.raw}`);
    }
    if (confirmEvent.id !== createdReservationId || confirmEvent.status !== 'DA_XAC_NHAN') {
      throw new Error(`Invalid confirmEvent payload: ${JSON.stringify(confirmEvent)}`);
    }
    console.log(`  [Test] [Pass] Scenario 2: Mobile received reservation:status_changed = DA_XAC_NHAN`);

    // -------------------------------------------------------------
    // SCENARIO 3: Restaurant checks in customer -> Mobile receives DA_DEN
    // -------------------------------------------------------------
    console.log('\n[Test] [Info] Scenario 3: Restaurant check-in -> Mobile receives DA_DEN');
    const checkinPromise = httpRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/v1/restaurant/reservations/${createdReservationId}/check-in`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ownerToken}`,
      },
    });

    const mobileCheckinEventPromise = customerMobileClient.waitForEvent('reservation:status_changed', 4000);
    const [checkinRes, checkinEvent] = await Promise.all([checkinPromise, mobileCheckinEventPromise]);

    if (checkinRes.statusCode !== 200) {
      throw new Error(`Failed to checkin reservation: ${checkinRes.raw}`);
    }
    if (checkinEvent.id !== createdReservationId || checkinEvent.status !== 'DA_DEN') {
      throw new Error(`Invalid checkinEvent payload: ${JSON.stringify(checkinEvent)}`);
    }
    console.log(`  [Test] [Pass] Scenario 3: Mobile received reservation:status_changed = DA_DEN`);

    // Complete reservation
    await httpRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/v1/restaurant/reservations/${createdReservationId}/complete`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${ownerToken}`,
      },
    });

    // -------------------------------------------------------------
    // SCENARIO 4: Customer cancels reservation on Mobile -> Restaurant receives DA_HUY on Web
    // -------------------------------------------------------------
    console.log('\n[Test] [Info] Scenario 4: Customer cancels -> Restaurant receives DA_HUY on Web');
    // Create another reservation to test cancellation
    const resv2Res = await httpRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: '/api/v1/reservations',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${customerToken}`,
        },
      },
      {
        maQuan: store.maQuan,
        thoiGianBatDau: new Date(Date.now() + 172800000).toISOString(),
        soNguoi: 2,
        maBan: table.maBan,
        ghiChu: 'Gần cửa sổ',
      }
    );
    const resv2Id = resv2Res.data.data.maDatBan;

    // Customer cancels
    const cancelPromise = httpRequest(
      {
        hostname: 'localhost',
        port: PORT,
        path: `/api/v1/reservations/${resv2Id}/cancel`,
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${customerToken}`,
        },
      },
      { lyDoHuy: 'Bận việc đột xuất' }
    );

    const webCancelEventPromise = restaurantWebClient.waitForEvent(
      'reservation:status_changed',
      (data) => data.id === resv2Id && data.status === 'DA_HUY'
    );
    const [cancelRes, webCancelEvent] = await Promise.all([cancelPromise, webCancelEventPromise]);

    if (cancelRes.statusCode !== 200) {
      throw new Error(`Failed to cancel reservation: ${cancelRes.raw}`);
    }
    if (webCancelEvent.id !== resv2Id || webCancelEvent.status !== 'DA_HUY') {
      throw new Error(`Invalid webCancelEvent payload: ${JSON.stringify(webCancelEvent)}`);
    }
    console.log(`  [Test] [Pass] Scenario 4: Restaurant received DA_HUY for #${resv2Id}`);

    // -------------------------------------------------------------
    // SCENARIO 5: Security & Room Isolation: Foreign Customer cannot receive events or view foreign reservations
    // -------------------------------------------------------------
    console.log('\n[Test] [Info] Scenario 5: Room isolation & BOLA security');
    // Attempt foreign room join
    await foreignClient.emit('room:join', { roomType: 'reservation', id: resv2Id });
    await new Promise((r) => setTimeout(r, 200));

    // Verify foreign client cannot view customer A's reservation (returns 404)
    const foreignGetRes = await httpRequest({
      hostname: 'localhost',
      port: PORT,
      path: `/api/v1/reservations/${resv2Id}`,
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${foreignToken}`,
      },
    });
    if (foreignGetRes.statusCode !== 404) {
      throw new Error(`Security Breach: Foreign customer got ${foreignGetRes.statusCode} instead of 404 for reservation #${resv2Id}`);
    }
    console.log(`  [Test] [Pass] Scenario 5: Foreign customer denied access (404) to foreign reservation #${resv2Id}`);

    // Verify foreign client received 0 private reservation events
    const foreignEvents = foreignClient.events.filter(
      (e) => e.event === 'reservation:created' || e.event === 'reservation:status_changed'
    );
    if (foreignEvents.length > 0) {
      throw new Error(`Security Breach: Foreign client received private events: ${JSON.stringify(foreignEvents)}`);
    }
    console.log(`  [Test] [Pass] Scenario 5: Foreign customer received 0 unauthorized reservation events`);
  } finally {
    restaurantWebClient.disconnect();
    customerMobileClient.disconnect();
    foreignClient.disconnect();

    // Clean up test data
    console.log('\n[Test] [Info] Cleaning up realtime test data...');
    if (createdReservationId) {
      await resvRepo.delete({ maQuan: store.maQuan });
    }
    await banRepo.delete({ maQuan: store.maQuan });
    await storeRepo.delete({ maQuan: store.maQuan });
    await khRepo.delete({ maTaiKhoan: customerAccount.maTaiKhoan });
    await khRepo.delete({ maTaiKhoan: foreignAccount.maTaiKhoan });
    await tkRepo.delete({ maTaiKhoan: ownerAccount.maTaiKhoan });
    await tkRepo.delete({ maTaiKhoan: customerAccount.maTaiKhoan });
    await tkRepo.delete({ maTaiKhoan: foreignAccount.maTaiKhoan });
  }

  console.log('===============================================================');
  console.log('[Test] [Summary] ALL 5 REALTIME 2-WAY SYNC SCENARIOS PASSED!');
  console.log('===============================================================');
}

runRealtimeSyncTests()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('\n[Test] [Fail] Realtime test failed with error:', err);
    process.exit(1);
  });
