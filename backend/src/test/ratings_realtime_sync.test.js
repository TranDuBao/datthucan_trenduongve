/**
 * INTEGRATION TEST: RATINGS & REALTIME SOCKET SYNCHRONIZATION
 * 
 * Rules:
 * - Runs 100% on DB TEST: datthucan_test (Port 5432)
 * - Verifies mathematical recalculation of store and dish ratings
 * - Verifies real-time event broadcasting to store, admin, and public mobile rooms
 * - Verifies elimination of fake 4.8 / 12 ratings on unrated items
 */

const http = require('http');
const express = require('express');
const jwt = require('jsonwebtoken');
const { AppDataSource } = require('/app/dist/config/database');
const { CuaHangModel } = require('/app/dist/models/cua_hang_model');
const { MonAnModel } = require('/app/dist/models/mon_an_model');
const { DonHangModel } = require('/app/dist/models/don_hang_model');
const { ChiTietDonHangModel } = require('/app/dist/models/chi_tiet_don_hang_model');
const { DanhGiaModel } = require('/app/dist/models/danh_gia_model');
const { DanhGiaMonModel } = require('/app/dist/models/danh_gia_mon_model');
const { KhachHangModel } = require('/app/dist/models/khach_hang_model');
const { TaiKhoanModel } = require('/app/dist/models/tai_khoan_model');
const { RealtimeService } = require('/app/dist/services/realtime_service');

const reviewRoutes = require('/app/dist/routes/review_routes').default || require('/app/dist/routes/review_routes');
const restaurantRoutes = require('/app/dist/routes/restaurant_routes').default || require('/app/dist/routes/restaurant_routes');

const TEST_PORT = 3999;
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_key_smart_city_food_route_2026';

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

class TestSocketClient {
  constructor(name, token) {
    this.name = name;
    this.token = token;
    this.sid = null;
    this.receivedEvents = [];
    this.isPolling = false;
  }

  async connect() {
    const handshakeUrl = `/socket.io/?EIO=4&transport=polling&t=${Date.now()}`;
    const authPayload = JSON.stringify({ token: this.token });
    const packet = `40${authPayload}`;

    const res = await httpRequest({
      hostname: 'localhost',
      port: TEST_PORT,
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
        port: TEST_PORT,
        path: `/socket.io/?EIO=4&transport=polling&sid=${this.sid}`,
        method: 'POST',
        headers: { 'Content-Type': 'text/plain;charset=UTF-8' },
      },
      packet
    );

    this.startPolling();
  }

  joinRoom(roomType, id) {
    const eventPacket = `42["room:join",{"roomType":"${roomType}","id":${id}}]`;
    return httpRequest(
      {
        hostname: 'localhost',
        port: TEST_PORT,
        path: `/socket.io/?EIO=4&transport=polling&sid=${this.sid}`,
        method: 'POST',
        headers: { 'Content-Type': 'text/plain;charset=UTF-8' },
      },
      eventPacket
    );
  }

  startPolling() {
    this.isPolling = true;
    const poll = async () => {
      if (!this.isPolling) return;
      try {
        const res = await httpRequest({
          hostname: 'localhost',
          port: TEST_PORT,
          path: `/socket.io/?EIO=4&transport=polling&sid=${this.sid}`,
          method: 'GET',
        });
        if (res.raw) {
          const raw = res.raw;
          let idx = 0;
          while (idx < raw.length) {
            const pIndex = raw.indexOf('42[', idx);
            if (pIndex === -1) break;
            let depth = 0;
            let endBracket = -1;
            for (let i = pIndex + 2; i < raw.length; i++) {
              if (raw[i] === '[') depth++;
              else if (raw[i] === ']') {
                depth--;
                if (depth === 0) {
                  endBracket = i;
                  break;
                }
              }
            }
            if (endBracket !== -1) {
              const fullPacket = raw.substring(pIndex + 2, endBracket + 1);
              try {
                const [eventName, eventData] = JSON.parse(fullPacket);
                this.receivedEvents.push({ event: eventName, data: eventData, time: new Date() });
              } catch (e) {
                console.error('[SocketParser] Error parsing packet:', e.message, fullPacket);
              }
              idx = endBracket + 1;
            } else {
              break;
            }
          }
        }
      } catch (e) {}
      if (this.isPolling) setTimeout(poll, 100);
    };
    poll();
  }

  stop() {
    this.isPolling = false;
  }
}

async function runTests() {
  const currentDb = process.env.DB_DATABASE || 'datthucan_test';
  console.log('======================================================================');
  console.log(`[TEST SUITE] BẮT ĐẦU KIỂM THỬ TÍCH HỢP ĐỒNG BỘ ĐÁNH GIÁ & SOCKET.IO`);
  console.log(`[DATABASE TARGET] ĐANG KẾT NỐI TỚI DATABASE: ${currentDb}`);
  console.log(`[TARGET HOST] host.docker.internal:5432`);
  console.log('======================================================================\n');

  if (currentDb === 'postgres') {
    throw new Error('NGUY HIỂM: DB_DATABASE đang trỏ vào postgres thật! Test chỉ được phép chạy trên DB TEST.');
  }

  // 1. Initialize DB Connection
  if (!AppDataSource.isInitialized) {
    await AppDataSource.initialize();
  }
  console.log(`[PASS] Đã kết nối thành công tới CSDL TEST: ${currentDb}`);

  // 2. Start HTTP & Socket Test Server
  const app = express();
  app.use(express.json());
  app.use('/api/v1', reviewRoutes);
  app.use('/api/v1/restaurants', restaurantRoutes);

  const server = http.createServer(app);
  RealtimeService.getInstance().initialize(server);
  await new Promise((resolve) => server.listen(TEST_PORT, resolve));
  console.log(`[PASS] Server test đã lắng nghe tại cổng ${TEST_PORT}\n`);

  let passedTests = 0;
  let totalTests = 0;

  try {
    // 3. Chuẩn bị tài khoản & dữ liệu kiểm thử
    console.log('--- [CHUẨN BỊ DỮ LIỆU TEST TRÊN DB TEST] ---');
    const storeRepo = AppDataSource.getRepository(CuaHangModel);
    const foodRepo = AppDataSource.getRepository(MonAnModel);
    const orderRepo = AppDataSource.getRepository(DonHangModel);
    const orderDetailRepo = AppDataSource.getRepository(ChiTietDonHangModel);
    const customerRepo = AppDataSource.getRepository(KhachHangModel);
    const userRepo = AppDataSource.getRepository(TaiKhoanModel);
    const reviewRepo = AppDataSource.getRepository(DanhGiaModel);

    // Lấy hoặc tạo khách hàng test
    let testCustomer = await customerRepo.findOne({ where: { sdt: '0909999888' } });
    let testUser = null;
    if (!testCustomer) {
      testUser = userRepo.create({
        tenDangNhap: 'reviewer_' + Date.now(),
        matKhau: '$2b$10$abcdefghijklmnopqrstuvwxyz123456',
        loaiTaiKhoan: 'KHACH_HANG',
        trangThai: 'HOAT_DONG',
      });
      testUser = await userRepo.save(testUser);
      testCustomer = customerRepo.create({
        maTaiKhoan: testUser.maTaiKhoan,
        hoTen: 'Nguyễn Văn Test Đánh Giá',
        sdt: '0909999888',
      });
      testCustomer = await customerRepo.save(testCustomer);
    } else {
      testUser = await userRepo.findOne({ where: { maTaiKhoan: testCustomer.maTaiKhoan } });
    }

    // Tạo đơn hàng test hoàn tất
    const testOrder = orderRepo.create({
      maKhachHang: testCustomer.maKhachHang,
      maQuan: 3,
      tongTien: 55000,
      trangThai: 'HOAN_TAT',
      phuongThucThanhToan: 'TIEN_MAT',
      thoigiandat: new Date(),
    });
    const savedOrder = await orderRepo.save(testOrder);

    const testDetail = orderDetailRepo.create({
      maDonHang: savedOrder.maDonHang,
      maMonAn: 12,
      tenMonAn: 'Trà Sữa Trân Châu Hoàng Kim',
      gia: 55000,
      soLuong: 1,
    });
    await orderDetailRepo.save(testDetail);

    console.log(`[PASS] Đã tạo đơn hàng test #${savedOrder.maDonHang} cho Quán #3, Món #12`);

    // 4. Khởi tạo 3 Socket Client
    const customerToken = generateToken({ sub: testUser.maTaiKhoan, email: testUser.email, role: 'KHACH_HANG' });
    const store3 = await storeRepo.findOne({ where: { maQuan: 3 } });
    const storeToken = generateToken({ sub: store3 ? store3.maTaiKhoan : 99991, email: 'store3@test.com', role: 'CUA_HANG' });
    const adminToken = generateToken({ sub: 99992, email: 'admin@test.com', role: 'ADMIN' });

    const storeClient = new TestSocketClient('StoreClient', storeToken);
    const publicClient = new TestSocketClient('PublicClient', customerToken);
    const adminClient = new TestSocketClient('AdminClient', adminToken);

    await storeClient.connect();
    await publicClient.connect();
    await adminClient.connect();

    // Store joins restaurant room; Public joins restaurant_public room
    await storeClient.joinRoom('restaurant', 3);
    await publicClient.joinRoom('restaurant_public', 3);
    await new Promise((r) => setTimeout(r, 200));

    console.log('[PASS] Cả 3 Socket.io client (Store, Public Viewer, Admin) đã kết nối thành công\n');

    // ──────────────────────────────────────────────────────────────────
    // TEST 1: TẠO ĐÁNH GIÁ MỚI VÀ ĐỒNG BỘ REALTIME
    // ──────────────────────────────────────────────────────────────────
    totalTests++;
    console.log('--- TEST 1: TẠO ĐÁNH GIÁ MỚI (POST /api/v1/orders/:id/review) ---');
    const storeBefore = await storeRepo.findOne({ where: { maQuan: 3 } });
    const dishBefore = await foodRepo.findOne({ where: { maMonAn: 12 } });

    storeClient.receivedEvents = [];
    publicClient.receivedEvents = [];
    adminClient.receivedEvents = [];

    const reviewPayload = {
      orderId: savedOrder.maDonHang,
      rating: 5,
      comment: 'Trà sữa KOI Thé rất ngon, trân châu hoàng kim dẻo mềm!',
      dishRatings: [{ dishId: 12, rating: 5, comment: 'Ngon tuyệt hảo' }],
    };

    // Đếm số review thực tế trong bảng danhgia TRƯỚC KHI tạo
    const beforeCountRaw = await AppDataSource.query(
      `SELECT COUNT(*) as cnt FROM danhgia WHERE maquan = 3 AND (is_hidden IS NOT TRUE OR is_hidden IS NULL)`
    );
    const realStoreCountBefore = Number(beforeCountRaw[0]?.cnt || 0);

    const createRes = await httpRequest(
      {
        hostname: 'localhost',
        port: TEST_PORT,
        path: `/api/v1/orders/${savedOrder.maDonHang}/review`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${customerToken}`,
        },
      },
      reviewPayload
    );

    if (createRes.statusCode !== 201 && createRes.statusCode !== 200) {
      throw new Error(`Tạo review thất bại: HTTP ${createRes.statusCode} - ${JSON.stringify(createRes.data)}`);
    }

    const createdReviewId = createRes.data.data?.maDanhGia || createRes.data.data?.id;
    console.log(`[PASS] Đã tạo đánh giá #${createdReviewId} thành công qua API`);

    // Chờ 400ms cho socket nhận gói tin
    await new Promise((r) => setTimeout(r, 400));

    // Xác minh CSDL TEST sau khi tạo
    const storeAfter = await storeRepo.findOne({ where: { maQuan: 3 } });
    const dishAfter = await foodRepo.findOne({ where: { maMonAn: 12 } });

    console.log(`  - Điểm Quán #3: trước = ${storeBefore.danhGiaTrungBinh} (${realStoreCountBefore} review thật) -> sau = ${storeAfter.danhGiaTrungBinh} (${storeAfter.soLuongDanhGia} lượt)`);
    console.log(`  - Điểm Món #12: trước = ${dishBefore.diemDanhGiaTB} (${dishBefore.soLuotDanhGia} lượt) -> sau = ${dishAfter.diemDanhGiaTB} (${dishAfter.soLuotDanhGia} lượt)`);

    if (Number(storeAfter.soLuongDanhGia) !== realStoreCountBefore + 1) {
      throw new Error(`Sai số lượt đánh giá quán: kỳ vọng ${realStoreCountBefore + 1}, thực tế ${storeAfter.soLuongDanhGia}`);
    }

    // Xác minh Socket Events
    const storeRatingEvt = storeClient.receivedEvents.find((e) => e.event === 'rating:updated');
    const storeReviewEvt = storeClient.receivedEvents.find((e) => e.event === 'review:created');
    const publicRatingEvt = publicClient.receivedEvents.find((e) => e.event === 'rating:updated');
    const adminRatingEvt = adminClient.receivedEvents.find((e) => e.event === 'rating:updated');

    console.log('  - StoreClient received events:', storeClient.receivedEvents.map(e => e.event));
    console.log('  - PublicClient received events:', publicClient.receivedEvents.map(e => e.event));
    console.log('  - AdminClient received events:', adminClient.receivedEvents.map(e => e.event));

    if (!storeRatingEvt) throw new Error('Store client không nhận được sự kiện rating:updated');
    if (!publicRatingEvt) throw new Error('Public Mobile client không nhận được sự kiện rating:updated');
    if (!adminRatingEvt) throw new Error('Admin client không nhận được sự kiện rating:updated');
    if (!storeReviewEvt) throw new Error('Store client không nhận được sự kiện review:created');

    console.log('  - Socket rating:updated payload:', JSON.stringify(storeRatingEvt.data));
    if (storeRatingEvt.data.storeId !== 3 || !Array.isArray(storeRatingEvt.data.dishRatings)) {
      throw new Error('Payload rating:updated không đúng định dạng');
    }

    console.log('[PASS] TEST 1 THÀNH CÔNG: Database cập nhật đúng và Socket.io broadcast tới cả 3 client!\n');
    passedTests++;

    // ──────────────────────────────────────────────────────────────────
    // TEST 2: KHÁCH HÀNG CHỈNH SỬA ĐÁNH GIÁ (PATCH /api/v1/reviews/:id)
    // ──────────────────────────────────────────────────────────────────
    totalTests++;
    console.log('--- TEST 2: SỬA ĐÁNH GIÁ TỪ 5 XUỐNG 1 SAO (PATCH /api/v1/reviews/:id) ---');
    storeClient.receivedEvents = [];
    publicClient.receivedEvents = [];
    adminClient.receivedEvents = [];

    const updateRes = await httpRequest(
      {
        hostname: 'localhost',
        port: TEST_PORT,
        path: `/api/v1/reviews/${createdReviewId}`,
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${customerToken}`,
        },
      },
      { rating: 1, comment: 'Đổi ý: Quá ngọt, không hài lòng' }
    );

    if (updateRes.statusCode !== 200) {
      throw new Error(`Sửa review thất bại: HTTP ${updateRes.statusCode} - ${JSON.stringify(updateRes.data)}`);
    }

    await new Promise((r) => setTimeout(r, 400));

    const storeAfterEdit = await storeRepo.findOne({ where: { maQuan: 3 } });
    const dishAfterEdit = await foodRepo.findOne({ where: { maMonAn: 12 } });

    console.log(`  - Điểm Quán sau khi sửa: ${storeAfterEdit.danhGiaTrungBinh} sao`);
    console.log(`  - Điểm Món #12 sau khi sửa: ${dishAfterEdit.diemDanhGiaTB} sao`);

    if (Number(storeAfterEdit.danhGiaTrungBinh) >= Number(storeAfter.danhGiaTrungBinh)) {
      throw new Error('Lỗi: Điểm quán không giảm sau khi khách sửa từ 5 sao xuống 1 sao');
    }
    if (Number(dishAfterEdit.diemDanhGiaTB) >= Number(dishAfter.diemDanhGiaTB)) {
      throw new Error('Lỗi: Điểm món ăn không giảm sau khi khách sửa từ 5 sao xuống 1 sao');
    }

    const editRatingEvt = storeClient.receivedEvents.find((e) => e.event === 'rating:updated');
    const editReviewEvt = storeClient.receivedEvents.find((e) => e.event === 'review:updated');
    if (!editRatingEvt) throw new Error('Không nhận được rating:updated sau khi sửa review');
    if (!editReviewEvt) throw new Error('Không nhận được review:updated sau khi sửa review');

    console.log('[PASS] TEST 2 THÀNH CÔNG: Sửa đánh giá đã tính lại cả quán và món, socket đồng bộ chính xác!\n');
    passedTests++;

    // ──────────────────────────────────────────────────────────────────
    // TEST 3: ADMIN ẨN ĐÁNH GIÁ (PATCH /api/v1/reviews/:id/visibility)
    // ──────────────────────────────────────────────────────────────────
    totalTests++;
    console.log('--- TEST 3: ADMIN ẨN ĐÁNH GIÁ (PATCH /api/v1/reviews/:id/visibility) ---');
    storeClient.receivedEvents = [];
    publicClient.receivedEvents = [];

    const hideRes = await httpRequest(
      {
        hostname: 'localhost',
        port: TEST_PORT,
        path: `/api/v1/reviews/${createdReviewId}/visibility`,
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${adminToken}`,
        },
      },
      { isHidden: true, reason: 'Nội dung không phù hợp' }
    );

    if (hideRes.statusCode !== 200) {
      throw new Error(`Ẩn review thất bại: HTTP ${hideRes.statusCode} - ${JSON.stringify(hideRes.data)}`);
    }

    await new Promise((r) => setTimeout(r, 400));

    const storeAfterHide = await storeRepo.findOne({ where: { maQuan: 3 } });
    const dishAfterHide = await foodRepo.findOne({ where: { maMonAn: 12 } });

    console.log(`  - Điểm Quán sau khi ẩn: ${storeAfterHide.danhGiaTrungBinh} (${storeAfterHide.soLuongDanhGia} lượt)`);
    console.log(`  - Điểm Món sau khi ẩn: ${dishAfterHide.diemDanhGiaTB} (${dishAfterHide.soLuotDanhGia} lượt)`);

    if (Number(storeAfterHide.soLuongDanhGia) !== realStoreCountBefore) {
      throw new Error(`Số lượt đánh giá quán sau khi ẩn không quay về ${realStoreCountBefore}: thực tế ${storeAfterHide.soLuongDanhGia}`);
    }

    const hideRatingEvt = storeClient.receivedEvents.find((e) => e.event === 'rating:updated');
    const hideReviewEvt = storeClient.receivedEvents.find((e) => e.event === 'review:visibility_changed');
    if (!hideRatingEvt) throw new Error('Không nhận được rating:updated sau khi ẩn review');
    if (!hideReviewEvt) throw new Error('Không nhận được review:visibility_changed sau khi ẩn review');

    console.log('[PASS] TEST 3 THÀNH CÔNG: Admin ẩn review đã loại trừ điểm và lượt, socket phát đồng bộ tức thì!\n');
    passedTests++;

    // ──────────────────────────────────────────────────────────────────
    // TEST 4: XÁC MINH CÁC ENDPOINT GET KHÔNG CÒN TRẢ VỀ ĐIỂM GIẢ 4.8 / 12
    // ──────────────────────────────────────────────────────────────────
    totalTests++;
    console.log('--- TEST 4: XÁC MINH CÁC ENDPOINT GET LOẠI BỎ ĐIỂM GIẢ 4.8 / 12 LƯỢT ---');

    // Test GET /api/v1/restaurants/61/menu (Quán 61 bị seed 4.8 / 12 lượt nhưng chưa có review thật)
    const menuRes = await httpRequest({
      hostname: 'localhost',
      port: TEST_PORT,
      path: '/api/v1/restaurants/61/menu',
      method: 'GET',
    });

    if (menuRes.statusCode !== 200) {
      throw new Error(`Gọi menu quán 61 thất bại: HTTP ${menuRes.statusCode}`);
    }

    const categories = menuRes.data.data || [];
    let fakeFoundCount = 0;
    let totalItemsChecked = 0;

    for (const cat of categories) {
      for (const item of cat.items || []) {
        totalItemsChecked++;
        if (item.soLuotDanhGia === 12 && item.diemDanhGiaTB === 4.8) {
          fakeFoundCount++;
        }
        if (item.soLuotDanhGia === 0 && item.chuaCoDanhGia !== true) {
          throw new Error(`Món #${item.id} [${item.name}] có 0 lượt nhưng thiếu cờ chuaCoDanhGia: true`);
        }
      }
    }

    console.log(`  - Đã kiểm tra ${totalItemsChecked} món ăn của Quán #61 qua GET /restaurants/61/menu`);
    console.log(`  - Số món còn dính điểm ảo 4.8 / 12 lượt: ${fakeFoundCount}`);

    if (fakeFoundCount > 0) {
      throw new Error(`Thất bại: Vẫn còn ${fakeFoundCount} món bị trả về điểm giả 4.8 / 12 lượt!`);
    }

    console.log('[PASS] TEST 4 THÀNH CÔNG: Không còn điểm giả 4.8 / 12 lượt trên endpoint menu!\n');
    passedTests++;

    // Dừng socket clients
    storeClient.stop();
    publicClient.stop();
    adminClient.stop();

    console.log('======================================================================');
    console.log(`[TỔNG KẾT BƯỚC 3] TẤT CẢ ${passedTests}/${totalTests} TESTS ĐÃ VƯỢT QUA 100%!`);
    console.log('======================================================================');
  } catch (err) {
    console.error('\n[TEST FAILED] Lỗi trong quá trình kiểm thử:', err);
    process.exit(1);
  } finally {
    server.close();
    if (AppDataSource.isInitialized) {
      await AppDataSource.destroy();
    }
    process.exit(0);
  }
}

runTests();
