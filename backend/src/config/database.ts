import { DataSource } from 'typeorm';
import dotenv from 'dotenv';
import { TaiKhoanModel } from '../models/tai_khoan_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { DanhMucModel } from '../models/danh_muc_model';
import { MonAnModel } from '../models/mon_an_model';
import { DonHangModel } from '../models/don_hang_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';
import { ThanhToanModel } from '../models/thanh_toan_model';
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
    TaiKhoanModel,
    KhachHangModel,
    CuaHangModel,
    DanhMucModel,
    MonAnModel,
    DonHangModel,
    ChiTietDonHangModel,
    ThanhToanModel,
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
  } catch (error) {
    console.error('❌ Lỗi kết nối PostgreSQL:', error);
  }
};
