import { DataSource } from 'typeorm';
import dotenv from 'dotenv';
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
import { ThongKeModel } from '../models/thong_ke_model';

import { TaiKhoan } from '../modules/user/entities/tai-khoan.entity';
import { KhachHang } from '../modules/user/entities/khach-hang.entity';
import { User } from '../modules/user/user.entity';

dotenv.config();

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  username: process.env.DB_USERNAME || 'postgres',
  password: process.env.DB_PASSWORD || '123456',
  database: process.env.DB_DATABASE || 'postgres',
  entities: [
    // Full 15 Database Table Models
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
    ThongKeModel,
    // Legacy / Module Entities
    TaiKhoan,
    KhachHang,
    User,
  ],
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
    await ensureAdminUserExists();
  } catch (error) {
    console.error('❌ Lỗi kết nối PostgreSQL:', error);
  }
};

const ensureAdminUserExists = async () => {
  try {
    const userRepo = AppDataSource.getRepository(TaiKhoanModel);
    const existingAdmin = await userRepo.findOne({ where: { loaiTaiKhoan: 'ADMIN' } });
    if (!existingAdmin) {
      console.log('⚡ Tự động khởi tạo tài khoản Admin (admin@gmail.com)...');
      await AppDataSource.query(`
        INSERT INTO taikhoan (tendangnhap, matkhau, loaitaikhoan, trangthai)
        VALUES ('admin@gmail.com', '$2b$10$e8gV9pQ10928371092837u.102938102938102938102938102938', 'ADMIN', 'HOAT_DONG')
        ON CONFLICT (tendangnhap) DO NOTHING;
      `);
      await AppDataSource.query(`
        INSERT INTO khachhang (mataikhoan, hoten, sdt, email, diachi)
        SELECT mataikhoan, 'Quản Trị Viên Hệ Thống', '0900000000', 'admin@gmail.com', 'Trụ sở Admin'
        FROM taikhoan WHERE tendangnhap = 'admin@gmail.com'
        ON CONFLICT (mataikhoan) DO NOTHING;
      `);
      console.log('✅ Đã khởi tạo thành công tài khoản Admin trong CSDL');
    }
  } catch (e) {
    console.error('⚠️ Không thể tự động kiểm tra tài khoản Admin:', e);
  }
};
