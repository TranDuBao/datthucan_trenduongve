import { DataSource } from 'typeorm';
import dotenv from 'dotenv';
import bcrypt from 'bcrypt';
import { TaiKhoanModel } from '../models/tai_khoan_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { NhanVienModel } from '../models/nhan_vien_model';
import { DanhMucModel } from '../models/danh_muc_model';
import { MonAnModel } from '../models/mon_an_model';
import { GioHangModel } from '../models/gio_hang_model';
import { ChiTietGioHangModel } from '../models/chi_tiet_gio_hang_model';
import { VoucherModel } from '../models/voucher_model';
import { KhachHangVoucherModel } from '../models/khach_hang_voucher_model';
import { DonHangModel } from '../models/don_hang_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';
import { ThanhToanModel } from '../models/thanh_toan_model';
import { DanhGiaModel } from '../models/danh_gia_model';
import { DanhGiaMonModel } from '../models/danh_gia_mon_model';
import { ThongKeModel } from '../models/thong_ke_model';
import { NhatKyHoatDongModel } from '../models/nhat_ky_hoat_dong_model';
import { BanModel } from '../models/ban_model';
import { DatBanModel } from '../models/dat_ban_model';
import { NotificationModel } from '../models/notification_model';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_DATABASE || 'postgres',
  entities: [
    // Full Database Table Models
    TaiKhoanModel,
    KhachHangModel,
    CuaHangModel,
    NhanVienModel,
    DanhMucModel,
    MonAnModel,
    GioHangModel,
    ChiTietGioHangModel,
    VoucherModel,
    KhachHangVoucherModel,
    DonHangModel,
    ChiTietDonHangModel,
    ThanhToanModel,
    DanhGiaModel,
    DanhGiaMonModel,
    ThongKeModel,
    NhatKyHoatDongModel,
    BanModel,
    DatBanModel,
    NotificationModel,
  ],
  migrations: [__dirname + '/../migrations/*.ts'],
  // CRITICAL DB SAFETY RULE: Never drop or synchronize schema automatically!
  synchronize: false,
  logging: process.env.NODE_ENV === 'development',
});

export const connectDatabase = async () => {
  try {
    if (!AppDataSource.isInitialized) {
      await AppDataSource.initialize();
    }
    console.log('✅ Kết nối PostgreSQL thành công (Bảo vệ dữ liệu synchronize=false)');
    await AppDataSource.query(`ALTER TABLE monan ALTER COLUMN img TYPE TEXT;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ALTER COLUMN img TYPE TEXT;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE taikhoan ADD COLUMN IF NOT EXISTS khoadenngay TIMESTAMP NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE taikhoan ADD COLUMN IF NOT EXISTS lydokhoa TEXT NULL;`).catch(() => {});

    // Activity / Audit Logs Table
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS nhatkyhoatdong (
        manhatky SERIAL PRIMARY KEY,
        mataikhoan INT NULL,
        tennguoithuchien VARCHAR(150) NOT NULL,
        loaihanhdong VARCHAR(50) NOT NULL,
        mota TEXT NOT NULL,
        doituong VARCHAR(100) NULL,
        madoituong VARCHAR(50) NULL,
        ipaddress VARCHAR(50) NULL,
        thoigiantuyen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    // Additive columns for Audit Log enhancement
    await AppDataSource.query(`ALTER TABLE nhatkyhoatdong ADD COLUMN IF NOT EXISTS actor_email VARCHAR(150) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE nhatkyhoatdong ADD COLUMN IF NOT EXISTS actor_role VARCHAR(50) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE nhatkyhoatdong ADD COLUMN IF NOT EXISTS changes JSONB NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE nhatkyhoatdong ADD COLUMN IF NOT EXISTS result VARCHAR(20) DEFAULT 'success';`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE nhatkyhoatdong ADD COLUMN IF NOT EXISTS error_code VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE nhatkyhoatdong ADD COLUMN IF NOT EXISTS reason TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE nhatkyhoatdong ADD COLUMN IF NOT EXISTS context JSONB NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE nhatkyhoatdong ADD COLUMN IF NOT EXISTS request_id VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE nhatkyhoatdong ADD COLUMN IF NOT EXISTS user_agent TEXT NULL;`).catch(() => {});

    // Indexes for high-performance audit query filtering
    await AppDataSource.query(`CREATE INDEX IF NOT EXISTS idx_nhatky_thoigiantuyen ON nhatkyhoatdong(thoigiantuyen DESC);`).catch(() => {});
    await AppDataSource.query(`CREATE INDEX IF NOT EXISTS idx_nhatky_mataikhoan ON nhatkyhoatdong(mataikhoan);`).catch(() => {});
    await AppDataSource.query(`CREATE INDEX IF NOT EXISTS idx_nhatky_loaihanhdong ON nhatkyhoatdong(loaihanhdong);`).catch(() => {});
    await AppDataSource.query(`CREATE INDEX IF NOT EXISTS idx_nhatky_target ON nhatkyhoatdong(doituong, madoituong);`).catch(() => {});

    
    // Auto add customer & store owner fields
    await AppDataSource.query(`ALTER TABLE khachhang ADD COLUMN IF NOT EXISTS ngaysinh DATE NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS hotenchuquan VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS diachithuongtru TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS ngaysinhchuquan DATE NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS socccd VARCHAR(20) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS tennganhang VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS sotaikhoannganhang VARCHAR(50) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS tenchutaikhoan VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS cccdmattruoc TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS cccdmatsau TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS mota TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS email VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS danhmuc VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS giohoatdong TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS thoigianchuanbi INT DEFAULT 20;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS cochodattruoc BOOLEAN DEFAULT TRUE;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS tienich TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE;`).catch(() => {});


    // Additive schema migrations (Food status & Table management)
    await AppDataSource.query(`ALTER TABLE monan ADD COLUMN IF NOT EXISTS trangthaimon VARCHAR(30) DEFAULT 'DANG_BAN';`).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS ban (
        maban SERIAL PRIMARY KEY,
        maquan INT REFERENCES cuahang(maquan) ON DELETE CASCADE,
        tenban VARCHAR(50) NOT NULL,
        succhua INT DEFAULT 4,
        trangthai VARCHAR(30) DEFAULT 'TRONG'
      );
    `).catch(() => {});
    await AppDataSource.query(`ALTER TABLE donhang ADD COLUMN IF NOT EXISTS maban INT REFERENCES ban(maban) ON DELETE SET NULL;`).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS datban (
        madatban SERIAL PRIMARY KEY,
        maban INT REFERENCES ban(maban) ON DELETE CASCADE,
        makhachhang INT REFERENCES khachhang(makhachhang) ON DELETE SET NULL,
        maquan INT REFERENCES cuahang(maquan) ON DELETE CASCADE,
        thoigianbatdau TIMESTAMP NOT NULL,
        thoigianketthuc TIMESTAMP NOT NULL,
        songuoi INT DEFAULT 2,
        trangthai VARCHAR(30) DEFAULT 'CHO_XAC_NHAN',
        ghichu TEXT NULL,
        tenkhachhang VARCHAR(100) NULL,
        sdtkhachhang VARCHAR(20) NULL,
        emailkhachhang VARCHAR(100) NULL,
        createdat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updatedat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    // Voucher & KhachHangVoucher safe migrations
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS voucher (
        mavoucher SERIAL PRIMARY KEY,
        macode VARCHAR(50) UNIQUE NOT NULL,
        tenvoucher VARCHAR(100) NOT NULL,
        mota TEXT NULL,
        giamgia NUMERIC(12,2) NOT NULL,
        loaigiam VARCHAR(20) DEFAULT 'VND',
        giatrigiamtoida NUMERIC(12,2) NULL,
        dieukiendontoithieu NUMERIC(12,2) DEFAULT 0,
        ngaytao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ngaybatdau TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ngayhethan TIMESTAMP NULL,
        soluongtoida INT DEFAULT 0,
        soluongdaluu INT DEFAULT 0,
        soluongdasudung INT DEFAULT 0,
        trangthai VARCHAR(30) DEFAULT 'HOAT_DONG',
        maquan INT REFERENCES cuahang(maquan) ON DELETE CASCADE
      );
    `).catch(() => {});
    await AppDataSource.query(`ALTER TABLE voucher ADD COLUMN IF NOT EXISTS mota TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE voucher ADD COLUMN IF NOT EXISTS ngaybatdau TIMESTAMP DEFAULT CURRENT_TIMESTAMP;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE voucher ADD COLUMN IF NOT EXISTS soluongdasudung INT DEFAULT 0;`).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS khachhang_voucher (
        makhachhang INT NOT NULL,
        mavoucher INT NOT NULL REFERENCES voucher(mavoucher) ON DELETE CASCADE,
        ngayluu TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        dasudung BOOLEAN DEFAULT FALSE,
        PRIMARY KEY (makhachhang, mavoucher)
      );
    `).catch(() => {});

    await AppDataSource.query(`
      CREATE INDEX IF NOT EXISTS idx_donhang_quan_status ON donhang(maquan, trangthai);
      CREATE INDEX IF NOT EXISTS idx_datban_quan_time ON datban(maquan, thoigianbatdau, thoigianketthuc);
      CREATE INDEX IF NOT EXISTS idx_monan_quan ON monan(maquan);
      CREATE UNIQUE INDEX IF NOT EXISTS idx_chitietgiohang_unique ON chitietgiohang(magio, mamonan);
    `).catch(() => {});

    // Review & Rating Additive Schema Migrations
    await AppDataSource.query(`ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS madonhang INT NULL REFERENCES donhang(madonhang) ON DELETE SET NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS maquan INT NULL REFERENCES cuahang(maquan) ON DELETE CASCADE;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT FALSE;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN DEFAULT FALSE;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS ly_do_an TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS ngayphanhoi TIMESTAMP NULL;`).catch(() => {});

    await AppDataSource.query(`CREATE UNIQUE INDEX IF NOT EXISTS uq_danhgia_madonhang ON danhgia(madonhang) WHERE madonhang IS NOT NULL;`).catch(() => {});
    await AppDataSource.query(`CREATE INDEX IF NOT EXISTS idx_danhgia_maquan ON danhgia(maquan);`).catch(() => {});
    await AppDataSource.query(`CREATE INDEX IF NOT EXISTS idx_danhgia_makhachhang ON danhgia(makhachhang);`).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS danhgia_mon (
        madanhgiamon SERIAL PRIMARY KEY,
        madanhgia INT NOT NULL REFERENCES danhgia(madanhgia) ON DELETE CASCADE,
        mamon INT NOT NULL REFERENCES monan(mamon) ON DELETE CASCADE,
        soluongsao INT DEFAULT 5,
        nhanxet TEXT NULL
      );
    `).catch(() => {});

    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS danhgiatrungbinh NUMERIC(3,2) DEFAULT 5.00;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS soluongdanhgia INT DEFAULT 0;`).catch(() => {});

    // Notifications Table & Indexes (Safe additive creation)
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        recipient_id INT NOT NULL,
        recipient_role VARCHAR(20) NOT NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        data JSONB NULL,
        is_read BOOLEAN DEFAULT FALSE,
        read_at TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});
    await AppDataSource.query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_recipient_read_created 
      ON notifications(recipient_id, is_read, created_at DESC);
    `).catch(() => {});
    await AppDataSource.query(`ALTER TABLE donhang ADD COLUMN IF NOT EXISTS lydohuy TEXT NULL;`).catch(() => {});

    await ensureAdminUserExists();
    // Auto-sanitization disabled to protect production/user data integrity
  } catch (error) {
    console.error('❌ Lỗi kết nối PostgreSQL:', error);
  }
};

/**
 * Safe DB validation stub.
 * Automated DML mutations and sample data seeding have been removed to preserve data integrity.
 */
export const runDBSanitization = async () => {
  // Intentionally no-op to adhere to DB safety & integrity rules (no automated DML/data tampering)
  return;
};

const ensureAdminUserExists = async () => {
  try {
    const adminEmail = process.env.ADMIN_EMAIL;
    const adminPassword = process.env.ADMIN_PASSWORD;

    // Only attempt admin creation if explicitly provided in environment variables
    if (!adminEmail || !adminPassword) {
      return;
    }

    const userRepo = AppDataSource.getRepository(TaiKhoanModel);
    const existingAdmin = await userRepo.findOne({ where: { loaiTaiKhoan: 'ADMIN' } });
    if (!existingAdmin) {
      console.log(`⚡ Tự động khởi tạo tài khoản Admin từ .env (${adminEmail})...`);
      const saltRounds = 10;
      const hashedPassword = await bcrypt.hash(adminPassword, saltRounds);

      await AppDataSource.query(
        `INSERT INTO taikhoan (tendangnhap, matkhau, loaitaikhoan, trangthai)
         VALUES ($1, $2, 'ADMIN', 'HOAT_DONG')
         ON CONFLICT (tendangnhap) DO NOTHING;`,
        [adminEmail, hashedPassword],
      );
      await AppDataSource.query(
        `INSERT INTO khachhang (mataikhoan, hoten, sdt, email, diachi)
         SELECT mataikhoan, 'Quản Trị Viên Hệ Thống', '0900000000', $1, 'Trụ sở Admin'
         FROM taikhoan WHERE tendangnhap = $1
         ON CONFLICT (mataikhoan) DO NOTHING;`,
        [adminEmail],
      );
      console.log('✅ Đã khởi tạo thành công tài khoản Admin từ biến môi trường');
    }
  } catch (e) {
    console.error('⚠️ Không thể tự động kiểm tra tài khoản Admin:', e);
  }
};
