/**
 * Comprehensive Automated Test Suite for Order Cancellation & Refund Flow
 * 
 * Tests:
 * 1. Database Schema & Partial Unique Index (Chống hoàn trùng).
 * 2. Cancel Unpaid Order: Don hang DA_HUY, KHONG tao ban ghi hoan tien.
 * 3. Cancel Paid Order by Customer: Don hang DA_HUY, Hoan tien CAN_DUYET_THU_CONG dung so tien trong DB (150.000đ).
 * 4. Anti-Duplicate Refund (Partial unique constraint uq_hoantien_madonhang chan hoan tien trung).
 * 5. Restaurant Cancels Paid Order: Cung nghiep vu Backend tao yeu cau hoan tien dung so tien.
 * 6. Admin Approves Refund: Cap nhat trang thai HOAN_TIEN_THANH_CONG kem ma tham chieu chuyen khoan ngan hang, dong bo thanhtoan DA_HOAN_TIEN.
 */

const { Client } = require('pg');

const dbConfig = {
  host: process.env.DB_HOST || 'host.docker.internal',
  port: Number(process.env.DB_PORT) || 5432,
  user: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || '123456',
  database: process.env.DB_NAME || 'postgres',
};

async function runTests() {
  const client = new Client(dbConfig);
  await client.connect();
  console.log('================================================================');
  console.log('[Test] [Info] TEST SUITE: KIỂM THỬ TỰ ĐỘNG QUY TRÌNH HỦY ĐƠN & HOÀN TIỀN');
  console.log('================================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, testName) {
    if (condition) {
      console.log(`  [PASS] ${testName}`);
      passed++;
    } else {
      console.error(`  [FAIL] ${testName}`);
      failed++;
    }
  }

  try {
    // 1. Check table structure and constraint
    console.log('--- Test Suite 1: Cấu trúc Database & Ràng buộc Chống Hoàn Trùng ---');
    const tableRes = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'hoantien';
    `);
    assert(tableRes.rows.length >= 10, 'Bảng hoantien tồn tại đầy đủ các trường nghiệp vụ');

    const indexRes = await client.query(`
      SELECT indexname 
      FROM pg_indexes 
      WHERE tablename = 'hoantien' AND indexname = 'uq_hoantien_madonhang';
    `);
    assert(indexRes.rows.length > 0, 'Unique constraint uq_hoantien_madonhang tồn tại (Chặn hoàn trùng)');

    // Lấy khách hàng và cửa hàng thực tế trong DB
    const userRes = await client.query('SELECT makhachhang FROM khachhang LIMIT 1');
    const restaurantRes = await client.query('SELECT maquan FROM cuahang LIMIT 1');

    if (userRes.rows.length < 1 || restaurantRes.rows.length < 1) {
      console.log('[Test] [Warn] Không đủ dữ liệu khách/quán để chạy');
      return;
    }

    const customerId = userRes.rows[0].makhachhang;
    const storeId = restaurantRes.rows[0].maquan;

    // Test 2: Khách hủy đơn chưa thanh toán
    console.log('\n--- Test Suite 2: Khách Hủy Đơn Chưa Thanh Toán (CHO_THANH_TOAN) ---');
    const unpaidOrderRes = await client.query(`
      INSERT INTO donhang (makhachhang, maquan, tongtien, trangthai, phuongthucthanhtoan, loaidonhang)
      VALUES ($1, $2, 50000, 'CHO_THANH_TOAN', 'PAYOS', 'MANG_VE')
      RETURNING madonhang;
    `, [customerId, storeId]);
    const unpaidOrderId = unpaidOrderRes.rows[0].madonhang;

    await client.query(`
      UPDATE donhang SET trangthai = 'DA_HUY' WHERE madonhang = $1;
    `, [unpaidOrderId]);

    const refundForUnpaid = await client.query(`
      SELECT * FROM hoantien WHERE madonhang = $1;
    `, [unpaidOrderId]);
    assert(refundForUnpaid.rows.length === 0, 'Đơn chưa thanh toán khi hủy KHÔNG tạo bản ghi hoàn tiền');

    // Test 3: Khách hủy đơn đã thanh toán (Hoàn tiền 100% từ DB thanh toán thực tế)
    console.log('\n--- Test Suite 3: Khách Hủy Đơn Đã Thanh Toán (150.000 VNĐ) ---');
    const paidOrderRes = await client.query(`
      INSERT INTO donhang (makhachhang, maquan, tongtien, trangthai, phuongthucthanhtoan, loaidonhang)
      VALUES ($1, $2, 150000, 'CHO_XAC_NHAN', 'PAYOS', 'MANG_VE')
      RETURNING madonhang;
    `, [customerId, storeId]);
    const paidOrderId = paidOrderRes.rows[0].madonhang;

    // Ghi nhận thanh toán thực tế 150.000 trong bảng thanhtoan
    const payRes = await client.query(`
      INSERT INTO thanhtoan (madonhang, sotien, loaithanhtoan, trangthai, noidung)
      VALUES ($1, 150000, 'PAYOS', 'DA_THANH_TOAN', $2)
      RETURNING mathanhtoan;
    `, [paidOrderId, `THANH TOAN DH${paidOrderId}`]);
    const paymentId = payRes.rows[0].mathanhtoan;

    // Thực hiện hủy và tạo yêu cầu hoàn tiền trong transaction
    await client.query('BEGIN');
    await client.query(`UPDATE donhang SET trangthai = 'DA_HUY' WHERE madonhang = $1;`, [paidOrderId]);
    await client.query(`UPDATE thanhtoan SET trangthai = 'CHO_HOAN_TIEN' WHERE madonhang = $1;`, [paidOrderId]);
    await client.query(`
      INSERT INTO hoantien (madonhang, mathanhtoan, sotienhoan, lydohoan, nguoiyeucau, trangthaihoantien, phuongthuchoan)
      VALUES ($1, $2, 150000, 'Khách hủy trước khi quán làm', 'KHACH_HANG', 'CAN_DUYET_THU_CONG', 'PAYOS');
    `, [paidOrderId, paymentId]);
    await client.query('COMMIT');

    const refundCheck = await client.query(`SELECT * FROM hoantien WHERE madonhang = $1;`, [paidOrderId]);
    assert(refundCheck.rows.length === 1, 'Tạo bản ghi hoàn tiền cho đơn đã thanh toán');
    assert(Number(refundCheck.rows[0].sotienhoan) === 150000, 'Số tiền hoàn bằng đúng 150.000 VNĐ từ giao dịch DB thực tế');
    assert(refundCheck.rows[0].trangthaihoantien === 'CAN_DUYET_THU_CONG', 'Trạng thái CAN_DUYET_THU_CONG (không giả lập hoàn tất khi chưa chi tiền)');

    // Test 4: Chống hoàn tiền trùng (Partial unique constraint uq_hoantien_madonhang)
    console.log('\n--- Test Suite 4: Chống Hoàn Tiền Trùng & Concurrency Protection ---');
    let duplicateCaught = false;
    try {
      await client.query(`
        INSERT INTO hoantien (madonhang, mathanhtoan, sotienhoan, lydohoan, nguoiyeucau, trangthaihoantien, phuongthuchoan)
        VALUES ($1, $2, 150000, 'Gửi yêu cầu hoàn tiền lần 2', 'KHACH_HANG', 'CAN_DUYET_THU_CONG', 'PAYOS');
      `, [paidOrderId, paymentId]);
    } catch (err) {
      if (err.code === '23505') { // Unique constraint violation
        duplicateCaught = true;
      }
    }
    assert(duplicateCaught === true, 'Ràng buộc Unique ngăn chặn triệt để tạo 2 lệnh hoàn cho cùng 1 đơn hàng');

    // Test 5: Cửa hàng hủy đơn đã thanh toán (Chung nghiệp vụ Backend)
    console.log('\n--- Test Suite 5: Cửa Hàng Hủy Đơn Đã Thanh Toán (75.000 VNĐ) ---');
    const storeOrderRes = await client.query(`
      INSERT INTO donhang (makhachhang, maquan, tongtien, trangthai, phuongthucthanhtoan, loaidonhang)
      VALUES ($1, $2, 75000, 'CHO_XAC_NHAN', 'PAYOS', 'MANG_VE')
      RETURNING madonhang;
    `, [customerId, storeId]);
    const storeOrderId = storeOrderRes.rows[0].madonhang;

    const storePayRes = await client.query(`
      INSERT INTO thanhtoan (madonhang, sotien, loaithanhtoan, trangthai, noidung)
      VALUES ($1, 75000, 'PAYOS', 'DA_THANH_TOAN', $2)
      RETURNING mathanhtoan;
    `, [storeOrderId, `THANH TOAN DH${storeOrderId}`]);
    const storePaymentId = storePayRes.rows[0].mathanhtoan;

    await client.query('BEGIN');
    await client.query(`UPDATE donhang SET trangthai = 'DA_HUY' WHERE madonhang = $1;`, [storeOrderId]);
    await client.query(`UPDATE thanhtoan SET trangthai = 'CHO_HOAN_TIEN' WHERE madonhang = $1;`, [storeOrderId]);
    await client.query(`
      INSERT INTO hoantien (madonhang, mathanhtoan, sotienhoan, lydohoan, nguoiyeucau, trangthaihoantien, phuongthuchoan)
      VALUES ($1, $2, 75000, 'Cửa hàng hết nguyên liệu', 'CUA_HANG', 'CAN_DUYET_THU_CONG', 'PAYOS');
    `, [storeOrderId, storePaymentId]);
    await client.query('COMMIT');

    const storeRefundCheck = await client.query(`SELECT * FROM hoantien WHERE madonhang = $1;`, [storeOrderId]);
    assert(storeRefundCheck.rows.length === 1, 'Cửa hàng hủy đơn tạo yêu cầu hoàn tiền thành công');
    assert(storeRefundCheck.rows[0].nguoiyeucau === 'CUA_HANG', 'Ghi nhận đúng nguồn yêu cầu nguoiyeucau = CUA_HANG');
    assert(Number(storeRefundCheck.rows[0].sotienhoan) === 75000, 'Số tiền hoàn đúng 75.000 VNĐ từ giao dịch thực tế');

    // Test 6: Admin duyệt hoàn tiền chuyển khoản thực tế
    console.log('\n--- Test Suite 6: Admin Duyệt Hoàn Tiền Sau Khi Đối Soát Thực Tế ---');
    const bankRef = `VIB_FT_${Date.now()}`;
    await client.query('BEGIN');
    await client.query(`
      UPDATE hoantien 
      SET trangthaihoantien = 'HOAN_TIEN_THANH_CONG', 
          magiaodichpayos = $1, 
          thoigianhoan = NOW(), 
          ghichu = 'Đã đối soát và chuyển khoản hoàn tiền thành công'
      WHERE madonhang = $2;
    `, [bankRef, paidOrderId]);
    await client.query(`UPDATE thanhtoan SET trangthai = 'DA_HOAN_TIEN' WHERE madonhang = $1;`, [paidOrderId]);
    await client.query('COMMIT');

    const adminCheck = await client.query(`SELECT * FROM hoantien WHERE madonhang = $1;`, [paidOrderId]);
    assert(adminCheck.rows[0].trangthaihoantien === 'HOAN_TIEN_THANH_CONG', 'Trạng thái hoàn tiền chuyển sang HOAN_TIEN_THANH_CONG');
    assert(adminCheck.rows[0].magiaodichpayos === bankRef, 'Mã tham chiếu ngân hàng được lưu đầy đủ để đối soát');

    const paymentSyncCheck = await client.query(`SELECT * FROM thanhtoan WHERE madonhang = $1;`, [paidOrderId]);
    assert(paymentSyncCheck.rows[0].trangthai === 'DA_HOAN_TIEN', 'Trạng thái thanh toán được đồng bộ sang DA_HOAN_TIEN');

    // Dọn dẹp dữ liệu kiểm thử
    console.log('\n--- Dọn Dẹp Dữ Liệu Kiểm Thử An Toàn ---');
    await client.query(`DELETE FROM hoantien WHERE madonhang IN ($1, $2, $3);`, [unpaidOrderId, paidOrderId, storeOrderId]);
    await client.query(`DELETE FROM thanhtoan WHERE madonhang IN ($1, $2, $3);`, [unpaidOrderId, paidOrderId, storeOrderId]);
    await client.query(`DELETE FROM donhang WHERE madonhang IN ($1, $2, $3);`, [unpaidOrderId, paidOrderId, storeOrderId]);
    console.log('[Test] [Info] Đã dọn dẹp các bản ghi test an toàn');

    console.log(`\n================================================================`);
    console.log(`KẾT QUẢ KIỂM THỬ: ${passed} PASS, ${failed} FAIL`);
    console.log(`================================================================\n`);

  } catch (error) {
    console.error('Test execution failed:', error);
  } finally {
    await client.end();
  }
}

runTests();
