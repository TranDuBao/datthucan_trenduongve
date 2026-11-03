const { AppDataSource } = require('./dist/config/database');
const bcrypt = require('bcrypt');

const storeAccountLinks = [
  { maquan: 56, tendangnhap: 'cuahang_huynhhoa', tenquan: 'Bánh Mì Huỳnh Hoa - Lê Thị Riêng' },
  { maquan: 57, tendangnhap: 'cuahang_phohoa', tenquan: 'Phở Hòa Pasteur - Quận 1' },
  { maquan: 58, tendangnhap: 'cuahang_comtammoc', tenquan: 'Cơm Tấm Mộc - Mạc Thị Bưởi' },
  { maquan: 59, tendangnhap: 'cuahang_bundaucokhan', tenquan: 'Bún Đậu Mắm Tôm Cô Khàn - Cống Quỳnh' },
  { maquan: 60, tendangnhap: 'cuahang_hutieuthanhdat', tenquan: 'Hủ Tiếu Nam Vang Thành Đạt - Cô Bắc' },
  { maquan: 61, tendangnhap: 'cuahang_thealley', tenquan: 'The Alley Trà Sữa - Hồ Tùng Mậu' },
  { maquan: 62, tendangnhap: 'cuahang_buncha145', tenquan: 'Bún Chả 145 - Bùi Viện' },
  { maquan: 63, tendangnhap: 'cuahang_ganuongooo', tenquan: 'Gà Nướng Ò Ó O - Đinh Tiên Hoàng' },
  { maquan: 64, tendangnhap: 'cuahang_banhcanhcua', tenquan: 'Bánh Canh Cua Trần Khắc Chân' },
  { maquan: 65, tendangnhap: 'cuahang_morico', tenquan: 'Trà Trái Cây & Bánh Morico - Lê Thánh Tôn' }
];

async function run() {
  await AppDataSource.initialize();
  const queryRunner = AppDataSource.createQueryRunner();
  await queryRunner.connect();
  await queryRunner.startTransaction();

  try {
    const defaultPassword = '123456';
    const hashedPassword = await bcrypt.hash(defaultPassword, 10);
    let linkedCount = 0;

    for (const item of storeAccountLinks) {
      // 1. Kiểm tra xem tài khoản đã tồn tại chưa
      let accountRes = await queryRunner.query(
        'SELECT mataikhoan FROM taikhoan WHERE tendangnhap = $1',
        [item.tendangnhap]
      );

      let maTaiKhoan;
      if (accountRes.length > 0) {
        maTaiKhoan = accountRes[0].mataikhoan;
        // Cập nhật lại mật khẩu nếu đã tồn tại
        await queryRunner.query(
          'UPDATE taikhoan SET matkhau = $1, loaitaikhoan = $2, trangthai = $3 WHERE mataikhoan = $4',
          [hashedPassword, 'CUAN_HANG', 'HOAT_DONG', maTaiKhoan]
        );
      } else {
        // Tạo mới tài khoản
        const insertRes = await queryRunner.query(
          'INSERT INTO taikhoan (tendangnhap, matkhau, loaitaikhoan, trangthai) VALUES ($1, $2, $3, $4) RETURNING mataikhoan',
          [item.tendangnhap, hashedPassword, 'CUAN_HANG', 'HOAT_DONG']
        );
        maTaiKhoan = insertRes[0].mataikhoan;
      }

      // 2. Cập nhật mataikhoan vào bảng cuahang
      await queryRunner.query(
        'UPDATE cuahang SET mataikhoan = $1 WHERE maquan = $2',
        [maTaiKhoan, item.maquan]
      );

      linkedCount++;
      console.log(`Đã liên kết tài khoản "${item.tendangnhap}" (ID: ${maTaiKhoan}) -> Quán "${item.tenquan}" (Mã quán: ${item.maquan})`);
    }

    await queryRunner.commitTransaction();
    console.log(`\nSUCCESS: Đã tạo và liên kết thành công ${linkedCount} tài khoản cửa hàng!`);
    await queryRunner.release();
    process.exit(0);
  } catch (err) {
    await queryRunner.rollbackTransaction();
    await queryRunner.release();
    console.error('ERROR liên kết tài khoản:', err);
    process.exit(1);
  }
}

run();
