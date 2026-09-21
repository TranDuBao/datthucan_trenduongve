-- Full PostgreSQL Database Schema (15 Tables) for Smart City Food Route App

-- 1. Bảng Tài Khoản
CREATE TABLE IF NOT EXISTS TaiKhoan (
    maTaiKhoan SERIAL PRIMARY KEY,
    tenDangNhap VARCHAR(50) UNIQUE NOT NULL,
    matKhau VARCHAR(255) NOT NULL,
    loaiTaiKhoan VARCHAR(30) NOT NULL, -- 'KHACH_HANG', 'CUAN_HANG', 'NHAN_VIEN', 'ADMIN'
    trangThai VARCHAR(30) DEFAULT 'HOAT_DONG',
    ngayTao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng Khách Hàng
CREATE TABLE IF NOT EXISTS KhachHang (
    maKhachHang SERIAL PRIMARY KEY,
    maTaiKhoan INT UNIQUE REFERENCES TaiKhoan(maTaiKhoan) ON DELETE CASCADE,
    hoTen VARCHAR(100) NOT NULL,
    SDT VARCHAR(15),
    email VARCHAR(100),
    diaChi TEXT,
    avatar VARCHAR(255)
);

-- 3. Bảng Cửa Hàng
CREATE TABLE IF NOT EXISTS CuaHang (
    maQuan SERIAL PRIMARY KEY,
    maTaiKhoan INT UNIQUE REFERENCES TaiKhoan(maTaiKhoan) ON DELETE CASCADE,
    tenQuan VARCHAR(150) NOT NULL,
    diaChi TEXT NOT NULL,
    trangThai VARCHAR(50) DEFAULT 'mở cửa', -- 'ngưng kinh doanh', 'mở cửa', 'đóng cửa'
    lat DOUBLE PRECISION,
    lng DOUBLE PRECISION,
    SDT VARCHAR(15),
    img VARCHAR(255)
);

-- 4. Bảng Nhân Viên
CREATE TABLE IF NOT EXISTS NhanVien (
    maNhanVien SERIAL PRIMARY KEY,
    maTaiKhoan INT UNIQUE REFERENCES TaiKhoan(maTaiKhoan) ON DELETE CASCADE,
    maQuan INT REFERENCES CuaHang(maQuan) ON DELETE SET NULL,
    hoTen VARCHAR(100) NOT NULL,
    SDT VARCHAR(15)
);

-- 5. Bảng Danh Mục
CREATE TABLE IF NOT EXISTS DanhMuc (
    maDanhMuc SERIAL PRIMARY KEY,
    maQuan INT REFERENCES CuaHang(maQuan) ON DELETE CASCADE,
    tenDanhMuc VARCHAR(100) NOT NULL
);

-- 6. Bảng Món Ăn
CREATE TABLE IF NOT EXISTS MonAn (
    maMonAn SERIAL PRIMARY KEY,
    maDanhMuc INT REFERENCES DanhMuc(maDanhMuc) ON DELETE SET NULL,
    maQuan INT REFERENCES CuaHang(maQuan) ON DELETE CASCADE,
    tenMonAn VARCHAR(150) NOT NULL,
    giaMonAn DECIMAL(12, 2) NOT NULL,
    soLuongMon INT DEFAULT 0,
    img VARCHAR(255),
    diemDanhGiaTB NUMERIC(3, 2) DEFAULT 0.0,
    soLuotDanhGia INT DEFAULT 0
);

-- 7. Bảng Giỏ Hàng
CREATE TABLE IF NOT EXISTS GioHang (
    maGio SERIAL PRIMARY KEY,
    maKhachHang INT UNIQUE REFERENCES KhachHang(maKhachHang) ON DELETE CASCADE
);

-- 8. Bảng Chi Tiết Giỏ Hàng
CREATE TABLE IF NOT EXISTS ChiTietGioHang (
    maChiTietGio SERIAL PRIMARY KEY,
    maGio INT REFERENCES GioHang(maGio) ON DELETE CASCADE,
    maMonAn INT REFERENCES MonAn(maMonAn) ON DELETE CASCADE,
    soLuong INT NOT NULL DEFAULT 1
);

-- 9. Bảng Voucher
CREATE TABLE IF NOT EXISTS Voucher (
    maVoucher SERIAL PRIMARY KEY,
    maCode VARCHAR(50) UNIQUE NOT NULL,
    tenVoucher VARCHAR(100) NOT NULL,
    giamGia DECIMAL(12, 2) NOT NULL,
    loaiGiam VARCHAR(20) DEFAULT 'VND', -- 'VND', 'PERCENT'
    giaTriGiamToiDa DECIMAL(12, 2),
    dieuKienDonToiThieu DECIMAL(12, 2) DEFAULT 0,
    ngayTao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngayHetHan TIMESTAMP,
    soLuongToiDa INT DEFAULT 0,
    soLuongDaLuu INT DEFAULT 0,
    trangThai VARCHAR(30) DEFAULT 'HOAT_DONG',
    maQuan INT REFERENCES CuaHang(maQuan) ON DELETE CASCADE
);

-- 10. Bảng Khách Hàng - Voucher
CREATE TABLE IF NOT EXISTS KhachHang_Voucher (
    maKhachHang INT REFERENCES KhachHang(maKhachHang) ON DELETE CASCADE,
    maVoucher INT REFERENCES Voucher(maVoucher) ON DELETE CASCADE,
    ngayLuu TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daSuDung BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (maKhachHang, maVoucher)
);

-- 11. Bảng Đơn Hàng
CREATE TABLE IF NOT EXISTS DonHang (
    maDonHang SERIAL PRIMARY KEY,
    maKhachHang INT REFERENCES KhachHang(maKhachHang) ON DELETE SET NULL,
    maQuan INT REFERENCES CuaHang(maQuan) ON DELETE SET NULL,
    maVoucher INT REFERENCES Voucher(maVoucher) ON DELETE SET NULL,
    trangThai VARCHAR(50) DEFAULT 'chờ xử lý', -- 'chờ xử lý', 'đã hoàn thành', 'đã nhận', 'đã hủy', 'chưa đánh giá', 'đã đánh giá'
    tongTien DECIMAL(12, 2) NOT NULL,
    thoiGianDat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    phuongThucThanhToan VARCHAR(50) DEFAULT 'COD'
);

-- 12. Bảng Chi Tiết Đơn Hàng
CREATE TABLE IF NOT EXISTS ChiTietDonHang (
    maChiTietDon SERIAL PRIMARY KEY,
    maDonHang INT REFERENCES DonHang(maDonHang) ON DELETE CASCADE,
    maMonAn INT REFERENCES MonAn(maMonAn) ON DELETE SET NULL,
    tenMonAn VARCHAR(150) NOT NULL,
    gia DECIMAL(12, 2) NOT NULL,
    soLuong INT NOT NULL,
    trangThaiMon VARCHAR(50) DEFAULT 'chưa làm' -- 'chưa làm', 'đã hoàn thành'
);

-- 13. Bảng Thanh Toán
CREATE TABLE IF NOT EXISTS ThanhToan (
    maThanhToan SERIAL PRIMARY KEY,
    maDonHang INT REFERENCES DonHang(maDonHang) ON DELETE CASCADE,
    taiKhoanThanhToan VARCHAR(100),
    soTien DECIMAL(12, 2) NOT NULL,
    taiKhoanNhan VARCHAR(100),
    ngayThanhToan TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    trangThai VARCHAR(50) DEFAULT 'THANH_TOAN_THANH_CONG',
    noiDung TEXT,
    loaiThanhToan VARCHAR(50)
);

-- 14. Bảng Đánh Giá
CREATE TABLE IF NOT EXISTS DanhGia (
    maDanhGia SERIAL PRIMARY KEY,
    maChiTietDon INT REFERENCES ChiTietDonHang(maChiTietDon) ON DELETE CASCADE,
    maKhachHang INT REFERENCES KhachHang(maKhachHang) ON DELETE CASCADE,
    soLuongSao INT CHECK (soLuongSao BETWEEN 1 AND 5),
    nhanXet TEXT,
    ngayNhanXet TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    hinhAnh VARCHAR(255),
    phanHoi TEXT
);

-- 15. Bảng Thống Kê
CREATE TABLE IF NOT EXISTS ThongKe (
    maThongKe SERIAL PRIMARY KEY,
    maQuan INT REFERENCES CuaHang(maQuan) ON DELETE CASCADE,
    ngayThongKe DATE DEFAULT CURRENT_DATE,
    tongDoanhThu DECIMAL(15, 2) DEFAULT 0,
    soLuongDatHang INT DEFAULT 0,
    soLuongDanhGia INT DEFAULT 0,
    diemDanhGiaTB NUMERIC(3, 2) DEFAULT 0.0
);
