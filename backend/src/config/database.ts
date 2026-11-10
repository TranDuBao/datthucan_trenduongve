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
import { BannerModel } from '../models/banner_model';
import { HoanTienModel } from '../models/hoan_tien_model';
import { LoaiHinhQuanModel } from '../models/loai_hinh_quan_model';
import { ThongTinHeThongModel } from '../models/thong_tin_he_thong_model';
import { DonDangKyCuaHangModel } from '../models/don_dang_ky_cua_hang_model';
import { DieuKhoanChinhSachModel } from '../models/dieu_khoan_chinh_sach_model';
import { SupportConfigModel } from '../models/support_config_model';
import { SupportFaqGroupModel } from '../models/support_faq_group_model';
import { SupportFaqModel } from '../models/support_faq_model';
import { SupportFeedbackModel } from '../models/support_feedback_model';
import { SupportTicketModel } from '../models/support_ticket_model';
import { SupportTicketMessageModel } from '../models/support_ticket_message_model';
import { DeviceTokenModel } from '../models/device_token_model';
import { UserNotificationModel } from '../models/user_notification_model';
import { AppVersionModel } from '../models/app_version_model';

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
    BannerModel,
    HoanTienModel,
    LoaiHinhQuanModel,
    ThongTinHeThongModel,
    DonDangKyCuaHangModel,
    DieuKhoanChinhSachModel,
    SupportConfigModel,
    SupportFaqGroupModel,
    SupportFaqModel,
    SupportFeedbackModel,
    SupportTicketModel,
    SupportTicketMessageModel,
    DeviceTokenModel,
    UserNotificationModel,
    AppVersionModel,
  ],
  migrations: [__dirname + '/../migrations/*.ts'],
  // CRITICAL DB SAFETY RULE: Never drop or synchronize schema automatically!
  synchronize: false,
  logging: process.env.NODE_ENV === 'development',
  extra: {
    max: Number(process.env.DB_POOL_MAX) || 25,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
  },
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

export const connectDatabase = async () => {
  try {
    if (!AppDataSource.isInitialized) {
      await AppDataSource.initialize();
    }
    console.log('[Database] [Info] Kết nối PostgreSQL thành công (Bảo vệ dữ liệu synchronize=false)');

    // Sử dụng Advisory Lock để tránh xung đột Exclusive Table Lock khi nhiều container/worker khởi động cùng lúc
    const lockRes = await AppDataSource.query(`SELECT pg_try_advisory_lock(987654) as locked;`).catch(() => [{ locked: true }]);
    const hasLock = Boolean(lockRes && lockRes[0] && lockRes[0].locked);

    if (hasLock) {
      try {
        const safeQuery = async (sql: string, params: any[] = []) => {
          try {
            await AppDataSource.query(sql, params);
          } catch (err: any) {
            // Ignore if already exists or duplicate
            if (!err.message?.includes('already exists') && !err.message?.includes('duplicate key') && !err.message?.includes('column') && !err.message?.includes('relation')) {
              console.warn(`[Database] [Schema Check Notice] ${err.message}`);
            }
          }
        };

        await safeQuery(`ALTER TABLE monan ALTER COLUMN img TYPE TEXT;`);
        await safeQuery(`ALTER TABLE cuahang ALTER COLUMN img TYPE TEXT;`);
        await safeQuery(`ALTER TABLE taikhoan ADD COLUMN IF NOT EXISTS khoadenngay TIMESTAMP NULL;`);
        await safeQuery(`ALTER TABLE taikhoan ADD COLUMN IF NOT EXISTS lydokhoa TEXT NULL;`);

        // Ensure auto-increment sequence default for taikhoan & khachhang primary keys
        await safeQuery(`CREATE SEQUENCE IF NOT EXISTS taikhoan_mataikhoan_seq;`);
        await safeQuery(`SELECT setval('taikhoan_mataikhoan_seq', COALESCE((SELECT MAX(mataikhoan) FROM taikhoan), 0) + 1, false);`);
        await safeQuery(`ALTER TABLE taikhoan ALTER COLUMN mataikhoan SET DEFAULT nextval('taikhoan_mataikhoan_seq');`);

        await safeQuery(`CREATE SEQUENCE IF NOT EXISTS khachhang_makhachhang_seq;`);
        await safeQuery(`SELECT setval('khachhang_makhachhang_seq', COALESCE((SELECT MAX(makhachhang) FROM khachhang), 0) + 1, false);`);
        await safeQuery(`ALTER TABLE khachhang ALTER COLUMN makhachhang SET DEFAULT nextval('khachhang_makhachhang_seq');`);

        await AppDataSource.query(`ALTER TABLE danhmuc ADD COLUMN IF NOT EXISTS hinhanh TEXT NULL;`).catch(() => {});
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS banner (
        mabanner SERIAL PRIMARY KEY,
        tieude VARCHAR(255) NOT NULL,
        phude VARCHAR(255) NULL,
        hinhanh TEXT NOT NULL,
        lienket VARCHAR(255) NULL,
        mausac VARCHAR(50) DEFAULT '#FC6011',
        thutu INT DEFAULT 0,
        trangthai VARCHAR(30) DEFAULT 'HOAT_DONG',
        loaibanner VARCHAR(50) DEFAULT 'TRAN_VIEN',
        ngaytao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});
    await AppDataSource.query(`ALTER TABLE banner ADD COLUMN IF NOT EXISTS loaibanner VARCHAR(50) DEFAULT 'TRAN_VIEN';`).catch(() => {});

    // Store Categories Table (loai_hinh_quan)
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS loai_hinh_quan (
        maloai SERIAL PRIMARY KEY,
        tenloai VARCHAR(100) UNIQUE NOT NULL,
        mota TEXT NULL,
        hinhanh TEXT NULL,
        icon VARCHAR(50) DEFAULT 'Store',
        thutu INT DEFAULT 0,
        trangthai VARCHAR(30) DEFAULT 'ACTIVE',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_loaihinhquan_trangthai ON loai_hinh_quan(trangthai);
    `).catch((err) => console.warn('[Database] loai_hinh_quan table creation error:', err));

    // Seed default standard store categories if empty
    await AppDataSource.query(`
      INSERT INTO loai_hinh_quan (tenloai, mota, icon, thutu, trangthai)
      VALUES 
        ('Phở', 'Phở bò, phở gà truyền thống', 'Beef', 1, 'ACTIVE'),
        ('Cơm tấm', 'Cơm tấm sườn bì chả, cơm văn phòng', 'UtensilsCrossed', 2, 'ACTIVE'),
        ('Bún bò', 'Bún bò Huế, bún riêu, bún các loại', 'Beef', 3, 'ACTIVE'),
        ('Cà phê & Trà', 'Cà phê, trà trái cây, thức uống', 'Coffee', 4, 'ACTIVE'),
        ('Trà sữa', 'Trà sữa trân châu, macchiato', 'CupSoda', 5, 'ACTIVE'),
        ('Bánh ngọt & Tráng miệng', 'Bánh kem, croissant, chè, kem', 'Cake', 6, 'ACTIVE'),
        ('Đồ ăn nhanh', 'Burger, gà rán, khoai tây chiên', 'Sandwich', 7, 'ACTIVE'),
        ('Lẩu & Nướng', 'Lẩu gia đình, đồ nướng BBQ', 'Flame', 8, 'ACTIVE'),
        ('Hải sản', 'Món ốc, tôm, mực tươi sống', 'Fish', 9, 'ACTIVE'),
        ('Healthy & Đồ chay', 'Salad, đồ chay, eat clean', 'Salad', 10, 'ACTIVE')
      ON CONFLICT (tenloai) DO NOTHING;
    `).catch(() => {});

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

    
    
    // Store Registration Table
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS dondangkycuahang (
        madon SERIAL PRIMARY KEY,
        mataikhoan INT NOT NULL REFERENCES taikhoan(mataikhoan) ON DELETE CASCADE,
        tenquan VARCHAR(150) NOT NULL,
        danhmuc VARCHAR(100) NULL,
        diachi TEXT NOT NULL,
        lat DOUBLE PRECISION NULL,
        lng DOUBLE PRECISION NULL,
        sdt VARCHAR(20) NOT NULL,
        hotenchuquan VARCHAR(150) NULL,
        ngaysinhchuquan DATE NULL,
        socccd VARCHAR(20) NOT NULL,
        diachithuongtru TEXT NULL,
        tennganhang VARCHAR(100) NOT NULL,
        sotaikhoannganhang VARCHAR(50) NOT NULL,
        tenchutaikhoan VARCHAR(100) NOT NULL,
        trangthai VARCHAR(30) DEFAULT 'CHO_DUYET',
        lydotuchoi TEXT NULL,
        ngaytao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ngayduyet TIMESTAMP NULL,
        nguoiduyet INT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_dondangky_mataikhoan ON dondangkycuahang(mataikhoan);
      CREATE INDEX IF NOT EXISTS idx_dondangky_trangthai ON dondangkycuahang(trangthai);
    `).catch(() => {});

    // Table for Legal Documents & Policies (Terms of Service, Privacy Policy)
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS dieu_khoan_chinh_sach (
        maphienban SERIAL PRIMARY KEY,
        loaitailieu VARCHAR(50) NOT NULL,
        sophienban VARCHAR(20) NOT NULL,
        tieude VARCHAR(255) NOT NULL,
        noidung TEXT NOT NULL,
        trangthai VARCHAR(30) DEFAULT 'NHAP',
        ngayhieuluc TIMESTAMP NULL,
        mataikhoantao INT NULL REFERENCES taikhoan(mataikhoan) ON DELETE SET NULL,
        ngaytao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        mataikhoancapnhat INT NULL,
        ngaycapnhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_tailieu ON dieu_khoan_chinh_sach(loaitailieu) WHERE trangthai = 'DANG_HIEU_LUC';
      CREATE INDEX IF NOT EXISTS idx_tailieu_loai_trangthai ON dieu_khoan_chinh_sach(loaitailieu, trangthai);
    `).catch(() => {});

    // Add legal & proof of consent columns to dondangkycuahang
    await AppDataSource.query(`ALTER TABLE dondangkycuahang ADD COLUMN IF NOT EXISTS loaihinhphaply VARCHAR(50) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE dondangkycuahang ADD COLUMN IF NOT EXISTS masothue VARCHAR(50) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE dondangkycuahang ADD COLUMN IF NOT EXISTS sogiayphepkinhdoanh VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE dondangkycuahang ADD COLUMN IF NOT EXISTS sogiayattp VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE dondangkycuahang ADD COLUMN IF NOT EXISTS maphienbandieukhoan INT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE dondangkycuahang ADD COLUMN IF NOT EXISTS maphienbanchinhsach INT NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE dondangkycuahang ADD COLUMN IF NOT EXISTS thoigiandongy TIMESTAMP NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE dondangkycuahang ADD COLUMN IF NOT EXISTS dongydieukhoan BOOLEAN DEFAULT FALSE;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE dondangkycuahang ADD COLUMN IF NOT EXISTS dongychinhsachdulieu BOOLEAN DEFAULT FALSE;`).catch(() => {});

    // Add legal fields to cuahang
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS loaihinhphaply VARCHAR(50) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS masothue VARCHAR(50) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS sogiayphepkinhdoanh VARCHAR(100) NULL;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS sogiayattp VARCHAR(100) NULL;`).catch(() => {});

    // Table for System Information ("About Us" - Về Chúng Tôi)
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS thongtin_hethong (
        id INT PRIMARY KEY DEFAULT 1,
        badge VARCHAR(150) DEFAULT 'ẨM THỰC TRÊN LỘ TRÌNH',
        tieude VARCHAR(255) DEFAULT 'Đặt Món Tiện Đường - Ghé Lấy Nóng Hổi',
        mota TEXT NOT NULL,
        sub_badge VARCHAR(150) DEFAULT 'Hơn 500+ quán ngon trên mọi cung đường',
        hinhanh TEXT NULL,
        sumenh_tieude VARCHAR(255) DEFAULT 'SỨ MỆNH & TÂM NHÌN',
        sumenh_phude VARCHAR(255) DEFAULT 'Kiến tạo phong cách ẩm thực di chuyển thông minh',
        sumenh_noidung TEXT NOT NULL,
        stat1_val VARCHAR(50) DEFAULT '500K+',
        stat1_label VARCHAR(100) DEFAULT 'Lộ trình phục vụ',
        stat2_val VARCHAR(50) DEFAULT '4.9★',
        stat2_label VARCHAR(100) DEFAULT 'Đánh giá cao',
        stat3_val VARCHAR(50) DEFAULT '99%',
        stat3_label VARCHAR(100) DEFAULT 'Khách hài lòng',
        giatricotloi JSONB NULL,
        hotline VARCHAR(50) DEFAULT '1900 6868',
        email VARCHAR(100) DEFAULT 'support@foodroute.vn',
        website VARCHAR(150) DEFAULT 'https://foodroute.vn',
        facebook TEXT NULL DEFAULT '',
        instagram TEXT NULL DEFAULT '',
        telegram TEXT NULL DEFAULT '',
        gmail TEXT NULL DEFAULT '',
        diachi TEXT NOT NULL,
        phienban VARCHAR(50) DEFAULT 'Phiên bản 1.0.0 • FoodRoute Official',
        banquyen VARCHAR(255) DEFAULT '© 2026 FoodRoute Inc. Giữ toàn bộ bản quyền hệ thống.',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch((err) => console.warn('[Database] thongtin_hethong creation error:', err));

    await AppDataSource.query(`
      INSERT INTO thongtin_hethong (
        id, badge, tieude, mota, sub_badge, 
        sumenh_tieude, sumenh_phude, sumenh_noidung,
        stat1_val, stat1_label, stat2_val, stat2_label, stat3_val, stat3_label,
        giatricotloi, hotline, email, website, diachi, phienban, banquyen
      )
      VALUES (
        1,
        'ẨM THỰC TRÊN LỘ TRÌNH',
        'Đặt Món Tiện Đường - Ghé Lấy Nóng Hổi',
        'Nền tảng tìm kiếm và đặt món thông minh dọc theo lộ trình di chuyển của bạn. Ghé lấy thức ăn tươi nóng mà không cần chờ đợi, trải nghiệm ẩm thực tiện lợi tối ưu thời gian.',
        'Hơn 500+ quán ngon trên mọi cung đường',
        'SỨ MỆNH & TÂM NHÌN',
        'Kiến tạo phong cách ẩm thực di chuyển thông minh',
        'Định vị thành giải pháp kết nối ẩm thực lộ trình hàng đầu, giúp tối ưu hóa thời gian di chuyển hàng ngày của người dùng bằng công nghệ gợi ý món ngon thông minh, đặt trước tiện lợi và thanh toán không tiền mặt an toàn.',
        '500K+', 'Lộ trình phục vụ',
        '4.9★', 'Đánh giá cao',
        '99%', 'Khách hài lòng',
        '[
          {"icon": "navigation", "title": "Tiện đường ghé lấy", "desc": "Đặt món trước, ghé lấy ngay trên lộ trình di chuyển mà không mất thời gian chờ đợi."},
          {"icon": "flame", "title": "Nóng hổi chuẩn giờ", "desc": "Quán canh thời gian chuẩn bị để món ăn vừa hoàn thành đúng lúc bạn có mặt."},
          {"icon": "shield", "title": "Thanh toán an toàn", "desc": "Tích hợp thanh toán tiện lợi qua VietQR, PayOS và MoMo với độ bảo mật tuyệt đối."},
          {"icon": "store", "title": "Quán ngon chọn lọc", "desc": "Hệ thống nhà hàng, quán ăn dọc tuyến đường được tuyển chọn kỹ lưỡng về vệ sinh an toàn."}
        ]'::jsonb,
        '1900 6868',
        'support@foodroute.vn',
        'https://foodroute.vn',
        'Khu Công Nghệ Cao, TP. Thủ Đức, TP. Hồ Chí Minh',
        'Phiên bản 1.0.0 • FoodRoute Official',
        '© 2026 FoodRoute Inc. Giữ toàn bộ bản quyền hệ thống.'
      )
      ON CONFLICT (id) DO NOTHING;
    `).catch(() => {});

    // Notification System Tables (Safe creation)
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        recipient_id INT NOT NULL DEFAULT 0,
        recipient_role VARCHAR(20) NOT NULL DEFAULT 'user',
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        data JSONB NULL,
        is_read BOOLEAN DEFAULT FALSE,
        read_at TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_notifications_recipient_read_created 
      ON notifications(recipient_id, is_read, created_at DESC);
    `).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS device_tokens (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL,
        token VARCHAR(500) NOT NULL UNIQUE,
        platform VARCHAR(20) NOT NULL DEFAULT 'android',
        language VARCHAR(10) NOT NULL DEFAULT 'vi',
        app_version VARCHAR(30) NULL,
        last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
    `).catch(() => {});

    await AppDataSource.query(`
      ALTER TABLE notifications 
        ADD COLUMN IF NOT EXISTS title_en VARCHAR(255) NULL,
        ADD COLUMN IF NOT EXISTS body_en TEXT NULL,
        ADD COLUMN IF NOT EXISTS target VARCHAR(50) DEFAULT 'USER',
        ADD COLUMN IF NOT EXISTS target_value VARCHAR(100) NULL,
        ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'sent',
        ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMP NULL,
        ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP NULL,
        ADD COLUMN IF NOT EXISTS created_by INT NULL,
        ADD COLUMN IF NOT EXISTS sent_count INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS read_count INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS failed_count INT DEFAULT 0;
    `).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS user_notifications (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL,
        notification_id INT NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
        is_read BOOLEAN DEFAULT FALSE,
        read_at TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_user_notification UNIQUE (user_id, notification_id)
      );
      CREATE INDEX IF NOT EXISTS idx_user_notifications_user_read 
      ON user_notifications(user_id, is_read, created_at DESC);
    `).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS app_versions (
        id SERIAL PRIMARY KEY,
        platform VARCHAR(20) NOT NULL UNIQUE,
        latest_version VARCHAR(30) NOT NULL,
        min_required_version VARCHAR(30) NOT NULL,
        store_url TEXT NOT NULL,
        changelog_vi TEXT NULL,
        changelog_en TEXT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await AppDataSource.query(`
      INSERT INTO app_versions (platform, latest_version, min_required_version, store_url, changelog_vi, changelog_en)
      VALUES 
        ('android', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.foodroute.food_route', 'Phiên bản ban đầu', 'Initial release'),
        ('ios', '1.0.0', '1.0.0', 'https://apps.apple.com/app/food-route/id000000000', 'Phiên bản ban đầu', 'Initial release')
      ON CONFLICT (platform) DO NOTHING;
    `).catch(() => {});

    await AppDataSource.query(`
      ALTER TABLE taikhoan 
        ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'vi',
        ADD COLUMN IF NOT EXISTS settings_system_notif BOOLEAN DEFAULT TRUE,
        ADD COLUMN IF NOT EXISTS settings_update_notif BOOLEAN DEFAULT TRUE;
    `).catch(() => {});

    // Đảm bảo sequence và DEFAULT auto-increment cho các bảng đơn hàng & chi tiết đơn & thanh toán
    try {
      await AppDataSource.query(`
        DO $$
        BEGIN
          -- 1. donhang (madonhang)
          CREATE SEQUENCE IF NOT EXISTS donhang_madonhang_seq;
          PERFORM setval('donhang_madonhang_seq', COALESCE((SELECT MAX(madonhang) FROM donhang), 0) + 1, false);
          ALTER TABLE donhang ALTER COLUMN madonhang SET DEFAULT nextval('donhang_madonhang_seq');
          ALTER SEQUENCE donhang_madonhang_seq OWNED BY donhang.madonhang;

          -- 2. chitietdonhang (machitietdon)
          CREATE SEQUENCE IF NOT EXISTS chitietdonhang_machitietdon_seq;
          PERFORM setval('chitietdonhang_machitietdon_seq', COALESCE((SELECT MAX(machitietdon) FROM chitietdonhang), 0) + 1, false);
          ALTER TABLE chitietdonhang ALTER COLUMN machitietdon SET DEFAULT nextval('chitietdonhang_machitietdon_seq');
          ALTER SEQUENCE chitietdonhang_machitietdon_seq OWNED BY chitietdonhang.machitietdon;

          -- 3. thanhtoan (mathanhtoan)
          CREATE SEQUENCE IF NOT EXISTS thanhtoan_mathanhtoan_seq;
          PERFORM setval('thanhtoan_mathanhtoan_seq', COALESCE((SELECT MAX(mathanhtoan) FROM thanhtoan), 0) + 1, false);
          ALTER TABLE thanhtoan ALTER COLUMN mathanhtoan SET DEFAULT nextval('thanhtoan_mathanhtoan_seq');
          ALTER SEQUENCE thanhtoan_mathanhtoan_seq OWNED BY thanhtoan.mathanhtoan;
        EXCEPTION WHEN OTHERS THEN
          RAISE NOTICE 'Order sequence setup: %', SQLERRM;
        END $$;
      `);
    } catch (seqErr) {
      console.warn('[Database] [Warn] Sequence setup warning:', seqErr);
    }

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

    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS danhgiatrungbinh NUMERIC(3,2) DEFAULT 0.00;`).catch(() => {});
    await AppDataSource.query(`ALTER TABLE cuahang ADD COLUMN IF NOT EXISTS soluongdanhgia INT DEFAULT 0;`).catch(() => {});

    // Ensure all ratings in monan and cuahang strictly reflect real user reviews in danhgia & danhgia_mon
    await AppDataSource.query(`
      UPDATE monan
      SET diemdanhgiatb = 0.0, soluotdanhgia = 0
      WHERE mamonan NOT IN (
        SELECT DISTINCT mamon FROM danhgia_mon
        UNION
        SELECT DISTINCT ct.mamonan FROM chitietdonhang ct JOIN danhgia dg ON dg.madonhang = ct.madonhang
      );

      WITH real_dish_stats AS (
        SELECT 
          mamonan,
          COUNT(DISTINCT madanhgia) as cnt,
          ROUND(AVG(stars)::numeric, 1) as avg_stars
        FROM (
          SELECT dgm.mamon as mamonan, dg.madanhgia, COALESCE(dgm.soluongsao, dg.soluongsao) as stars
          FROM danhgia_mon dgm
          JOIN danhgia dg ON dg.madanhgia = dgm.madanhgia
          WHERE (dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)
          UNION
          SELECT ct.mamonan, dg.madanhgia, dg.soluongsao as stars
          FROM chitietdonhang ct
          JOIN danhgia dg ON dg.madonhang = ct.madonhang
          WHERE (dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)
        ) sub
        GROUP BY mamonan
      )
      UPDATE monan m
      SET 
        diemdanhgiatb = r.avg_stars,
        soluotdanhgia = r.cnt
      FROM real_dish_stats r
      WHERE m.mamonan = r.mamonan;

      UPDATE cuahang
      SET danhgiatrungbinh = 0.0, soluongdanhgia = 0
      WHERE maquan NOT IN (
        SELECT DISTINCT maquan FROM danhgia WHERE maquan IS NOT NULL AND (is_hidden IS NOT TRUE OR is_hidden IS NULL)
      );

      WITH real_store_stats AS (
        SELECT 
          maquan,
          COUNT(madanhgia) as cnt,
          ROUND(AVG(soluongsao)::numeric, 2) as avg_stars
        FROM danhgia
        WHERE (is_hidden IS NOT TRUE OR is_hidden IS NULL) AND maquan IS NOT NULL
        GROUP BY maquan
      )
      UPDATE cuahang c
      SET 
        danhgiatrungbinh = r.avg_stars,
        soluongdanhgia = r.cnt
      FROM real_store_stats r
      WHERE c.maquan = r.maquan;
    `).catch((err) => {
      console.warn('[Database] Rating reconciliation notice:', err?.message || err);
    });

    // Dọn dẹp triệt để các URL ảnh mẫu Unsplash cũ còn sót trong DB để chỉ giữ ảnh thật người dùng upload
    await AppDataSource.query(`
      UPDATE monan 
      SET hinhanh = NULL 
      WHERE hinhanh LIKE '%photo-1582878826629-29b7ad1cdc43%' 
         OR hinhanh LIKE '%images.unsplash.com%';
    `).catch(() => {});

    await AppDataSource.query(`ALTER TABLE donhang ADD COLUMN IF NOT EXISTS lydohuy TEXT NULL;`).catch(() => {});

    // Support System Safe Migrations (Giai đoạn A)
    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS ho_tro_cau_hinh (
        id INT PRIMARY KEY DEFAULT 1,
        hotline VARCHAR(50) DEFAULT '1900 6868',
        gio_lam_viec VARCHAR(150) DEFAULT '08:00 - 22:00 hàng ngày (T2 - CN)',
        email_ho_tro VARCHAR(100) DEFAULT 'support@foodroute.vn',
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});
    await AppDataSource.query(`
      INSERT INTO ho_tro_cau_hinh (id, hotline, gio_lam_viec, email_ho_tro)
      VALUES (1, '1900 6868', '08:00 - 22:00 hàng ngày (T2 - CN)', 'support@foodroute.vn')
      ON CONFLICT (id) DO NOTHING;
    `).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS ho_tro_faq_nhom (
        ma_nhom SERIAL PRIMARY KEY,
        ten_nhom VARCHAR(150) NOT NULL,
        thu_tu INT DEFAULT 1,
        kich_hoat BOOLEAN DEFAULT TRUE,
        ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS ho_tro_faq_cau_hoi (
        ma_faq SERIAL PRIMARY KEY,
        ma_nhom INT NOT NULL REFERENCES ho_tro_faq_nhom(ma_nhom) ON DELETE CASCADE,
        cau_hoi TEXT NOT NULL,
        cau_tra_loi TEXT NOT NULL,
        thu_tu INT DEFAULT 1,
        kich_hoat BOOLEAN DEFAULT TRUE,
        ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS ho_tro_gop_y (
        ma_gop_y SERIAL PRIMARY KEY,
        ma_tai_khoan INT NULL REFERENCES taikhoan(mataikhoan) ON DELETE SET NULL,
        ho_ten VARCHAR(150) NULL,
        sdt VARCHAR(20) NULL,
        loai_gop_y VARCHAR(50) DEFAULT 'TINH_NANG',
        noi_dung TEXT NOT NULL,
        danh_gia_sao SMALLINT NULL,
        danh_sach_anh JSONB NULL,
        trang_thai VARCHAR(30) DEFAULT 'CHUA_XEM',
        ghi_chu_admin TEXT NULL,
        ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS ho_tro_phieu (
        ma_phieu SERIAL PRIMARY KEY,
        ma_tai_khoan INT NOT NULL REFERENCES taikhoan(mataikhoan) ON DELETE CASCADE,
        tieu_de VARCHAR(255) NULL,
        loai_su_co VARCHAR(50) NOT NULL,
        mo_ta TEXT NOT NULL,
        ma_don_hang INT NULL REFERENCES donhang(madonhang) ON DELETE SET NULL,
        danh_sach_anh JSONB DEFAULT '[]',
        trang_thai VARCHAR(30) DEFAULT 'MOI',
        so_tin_chua_doc_admin INT DEFAULT 0,
        so_tin_chua_doc_user INT DEFAULT 0,
        tin_nhan_cuoi TEXT NULL,
        thoi_gian_tin_cuoi TIMESTAMP NULL,
        ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    await AppDataSource.query(`
      CREATE TABLE IF NOT EXISTS ho_tro_tin_nhan (
        ma_tin_nhan SERIAL PRIMARY KEY,
        ma_phieu INT NOT NULL REFERENCES ho_tro_phieu(ma_phieu) ON DELETE CASCADE,
        ma_tai_khoan_gui INT NOT NULL REFERENCES taikhoan(mataikhoan) ON DELETE CASCADE,
        vai_tro_gui VARCHAR(20) DEFAULT 'USER',
        noi_dung TEXT NOT NULL,
        danh_sach_anh JSONB DEFAULT '[]',
        da_xem BOOLEAN DEFAULT FALSE,
        thoi_gian_xem TIMESTAMP NULL,
        ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `).catch(() => {});

    // Seed default FAQ groups & questions if empty
    try {
      const existingGroups = await AppDataSource.query(`SELECT COUNT(*) as count FROM ho_tro_faq_nhom`);
      if (existingGroups[0] && Number(existingGroups[0].count) === 0) {
        const g1 = await AppDataSource.query(
          `INSERT INTO ho_tro_faq_nhom (ten_nhom, thu_tu, kich_hoat) VALUES ($1, $2, $3) RETURNING ma_nhom`,
          ['Đơn hàng & Tiện đường ghé lấy', 1, true]
        );
        const g2 = await AppDataSource.query(
          `INSERT INTO ho_tro_faq_nhom (ten_nhom, thu_tu, kich_hoat) VALUES ($1, $2, $3) RETURNING ma_nhom`,
          ['Thanh toán & Hoàn tiền', 2, true]
        );
        const g3 = await AppDataSource.query(
          `INSERT INTO ho_tro_faq_nhom (ten_nhom, thu_tu, kich_hoat) VALUES ($1, $2, $3) RETURNING ma_nhom`,
          ['Đăng ký Cửa hàng & Đối tác', 3, true]
        );

        if (g1[0]?.ma_nhom) {
          await AppDataSource.query(
            `INSERT INTO ho_tro_faq_cau_hoi (ma_nhom, cau_hoi, cau_tra_loi, thu_tu, kich_hoat)
             VALUES ($1, $2, $3, $4, $5), ($1, $6, $7, $8, $5)`,
            [
              g1[0].ma_nhom,
              'Làm sao để đặt món trên lộ trình di chuyển?',
              'Bạn chỉ cần mở bản đồ lộ trình, chọn điểm xuất phát và điểm đến. Food Route sẽ đề xuất các quán ăn ngon nằm ngay trên cung đường để bạn ghé lấy tiện lợi nhất mà không phải đi đường vòng.',
              1,
              true,
              'Tôi có thể hẹn giờ đến lấy món không?',
              'Có, trong bước xác nhận đơn hàng bạn có thể chọn thời gian dự kiến ghé lấy (ví dụ 15 phút, 30 phút nữa). Quán ăn sẽ chuẩn bị nóng hổi đúng giờ bạn đến.',
              2,
            ]
          );
        }

        if (g2[0]?.ma_nhom) {
          await AppDataSource.query(
            `INSERT INTO ho_tro_faq_cau_hoi (ma_nhom, cau_hoi, cau_tra_loi, thu_tu, kich_hoat)
             VALUES ($1, $2, $3, $4, $5)`,
            [
              g2[0].ma_nhom,
              'Chính sách hoàn tiền khi quán hủy đơn như thế nào?',
              'Nếu đơn hàng thanh toán online bị quán từ chối hoặc hủy, hệ thống sẽ tự động hoàn tiền về tài khoản ngân hàng hoặc phương thức thanh toán ban đầu của bạn trong vòng vài phút.',
              1,
              true,
            ]
          );
        }

        if (g3[0]?.ma_nhom) {
          await AppDataSource.query(
            `INSERT INTO ho_tro_faq_cau_hoi (ma_nhom, cau_hoi, cau_tra_loi, thu_tu, kich_hoat)
             VALUES ($1, $2, $3, $4, $5)`,
            [
              g3[0].ma_nhom,
              'Thời gian xét duyệt hồ sơ mở cửa hàng mất bao lâu?',
              'Đội ngũ Admin Food Route tiếp nhận và xử lý hồ sơ đăng ký trong vòng 24 giờ làm việc. Bạn sẽ nhận được thông báo ngay khi hồ sơ được duyệt.',
              1,
              true,
            ]
          );
        }
      }
    } catch (e) {
      console.warn('[Database] Seed FAQ warn:', e);
    }
  } finally {
    await AppDataSource.query(`SELECT pg_advisory_unlock(987654);`).catch(() => {});
  }
} else {
  console.log('[Database] [Info] Node khác đang kiểm tra cấu trúc CSDL. Bỏ qua kiểm tra để tránh xung đột khóa bảng.');
}

await ensureAdminUserExists();
    // Auto-sanitization disabled to protect production/user data integrity
  } catch (error) {
    console.error('[Database] [Error] Lỗi kết nối PostgreSQL:', error);
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
      console.log(`[Database] [Info] Tự động khởi tạo tài khoản Admin từ .env (${adminEmail})...`);
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
      console.log('[Database] [Info] Đã khởi tạo thành công tài khoản Admin từ biến môi trường');
    }
  } catch (e) {
    console.error('[Database] [Warn] Không thể tự động kiểm tra tài khoản Admin:', e);
  }
};
