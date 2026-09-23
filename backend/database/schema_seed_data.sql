-- SQL Seed Data for Smart City Food Route App
-- Nạp dữ liệu mẫu Tiếng Việt cho Cửa Hàng, Danh Mục, Món Ăn và Voucher (An toàn, chống trùng lặp dữ liệu)

-- 1. Nạp Tài Khoản Quản Trị Viên & Cửa Hàng Mẫu
INSERT INTO TaiKhoan (tenDangNhap, matKhau, loaiTaiKhoan, trangThai) VALUES
('admin@gmail.com', 'admin123', 'ADMIN', 'HOAT_DONG'),
('admin', 'admin123', 'ADMIN', 'HOAT_DONG'),
('cuahang_phobo', '123456', 'CUAN_HANG', 'HOAT_DONG'),
('cuahang_comtam', '123456', 'CUAN_HANG', 'HOAT_DONG'),
('cuahang_bunbo', '123456', 'CUAN_HANG', 'HOAT_DONG'),
('cuahang_caphe', '123456', 'CUAN_HANG', 'HOAT_DONG'),
('cuahang_tiemkem', '123456', 'CUAN_HANG', 'HOAT_DONG'),
('khachhang_demo', '123456', 'KHACH_HANG', 'HOAT_DONG')
ON CONFLICT (tenDangNhap) DO NOTHING;

INSERT INTO KhachHang (maTaiKhoan, hoTen, SDT, email, diaChi)
SELECT maTaiKhoan, 'Quản Trị Viên Hệ Thống', '0900000000', 'admin@gmail.com', 'Trụ sở Hệ Thống'
FROM TaiKhoan WHERE tenDangNhap IN ('admin@gmail.com', 'admin')
ON CONFLICT (maTaiKhoan) DO NOTHING;

INSERT INTO KhachHang (maTaiKhoan, hoTen, SDT, email, diaChi)
SELECT maTaiKhoan, 'Nguyễn Văn Khách', '0901112233', 'khachhang@gmail.com', '123 Nguyễn Trãi, Q1, TP.HCM'
FROM TaiKhoan WHERE tenDangNhap = 'khachhang_demo'
ON CONFLICT (maTaiKhoan) DO NOTHING;

-- 2. Nạp Danh Sách Cửa Hàng Lộ Trình (Tự động liên kết đúng maTaiKhoan, không trùng lặp)
INSERT INTO CuaHang (maTaiKhoan, tenQuan, diaChi, trangThai, lat, lng, SDT, img)
SELECT maTaiKhoan, 'Phở Bò Gia Truyền Hà Nội - Nguyễn Trãi', '235 Nguyễn Trãi, Quận 1, TP.HCM', 'mở cửa', 10.762622, 106.682029, '0901234567', 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500'
FROM TaiKhoan WHERE tenDangNhap = 'cuahang_phobo'
ON CONFLICT (maTaiKhoan) DO NOTHING;

INSERT INTO CuaHang (maTaiKhoan, tenQuan, diaChi, trangThai, lat, lng, SDT, img)
SELECT maTaiKhoan, 'Cơm Tấm Sài Gòn 99 - Điện Biên Phủ', '180 Điện Biên Phủ, Bình Thạnh, TP.HCM', 'mở cửa', 10.793110, 106.702980, '0907654321', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500'
FROM TaiKhoan WHERE tenDangNhap = 'cuahang_comtam'
ON CONFLICT (maTaiKhoan) DO NOTHING;

INSERT INTO CuaHang (maTaiKhoan, tenQuan, diaChi, trangThai, lat, lng, SDT, img)
SELECT maTaiKhoan, 'Bún Bò Huế O Phượng - Võ Văn Kiệt', '520 Võ Văn Kiệt, Quận 5, TP.HCM', 'mở cửa', 10.751230, 106.671450, '0903334455', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500'
FROM TaiKhoan WHERE tenDangNhap = 'cuahang_bunbo'
ON CONFLICT (maTaiKhoan) DO NOTHING;

INSERT INTO CuaHang (maTaiKhoan, tenQuan, diaChi, trangThai, lat, lng, SDT, img)
SELECT maTaiKhoan, 'Phúc Long Coffee & Tea - Nguyễn Thị Minh Khai', '42 Nguyễn Thị Minh Khai, Quận 1, TP.HCM', 'mở cửa', 10.781200, 106.698500, '0909998877', 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500'
FROM TaiKhoan WHERE tenDangNhap = 'cuahang_caphe'
ON CONFLICT (maTaiKhoan) DO NOTHING;

INSERT INTO CuaHang (maTaiKhoan, tenQuan, diaChi, trangThai, lat, lng, SDT, img)
SELECT maTaiKhoan, 'Tiệm Kem & Bánh Sinh Nhật Sweet Cake - Lê Lợi', '98 Lê Lợi, Quận 1, TP.HCM', 'mở cửa', 10.773500, 106.701100, '0908887766', 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500'
FROM TaiKhoan WHERE tenDangNhap = 'cuahang_tiemkem'
ON CONFLICT (maTaiKhoan) DO NOTHING;

-- 3. Nạp Danh Mục Món Ăn (Kiểm tra NOT EXISTS để không bị lặp lại danh mục khi chạy lại nhiều lần)
-- Quán Phở
INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Phở Truyền Thống' FROM CuaHang c WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Phở Truyền Thống');

INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Món Ăn Kèm' FROM CuaHang c WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Món Ăn Kèm');

INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Nước Uống & Tráng Miệng' FROM CuaHang c WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Nước Uống & Tráng Miệng');

-- Quán Cơm Tấm
INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Cơm Tấm Đặc Biệt' FROM CuaHang c WHERE c.tenQuan LIKE 'Cơm Tấm Sài Gòn%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Cơm Tấm Đặc Biệt');

INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Món Kèm & Giải Khát' FROM CuaHang c WHERE c.tenQuan LIKE 'Cơm Tấm Sài Gòn%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Món Kèm & Giải Khát');

-- Quán Bún Bò Huế
INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Bún Bò Huế' FROM CuaHang c WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Bún Bò Huế');

INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Món Ăn Kèm Huế' FROM CuaHang c WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Món Ăn Kèm Huế');

INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Giải Khát' FROM CuaHang c WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Giải Khát');

-- Quán Phúc Long Coffee & Tea
INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Cà Phê' FROM CuaHang c WHERE c.tenQuan LIKE 'Phúc Long Coffee%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Cà Phê');

INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Trà Sữa' FROM CuaHang c WHERE c.tenQuan LIKE 'Phúc Long Coffee%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Trà Sữa');

INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Bánh Ngọt' FROM CuaHang c WHERE c.tenQuan LIKE 'Phúc Long Coffee%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Bánh Ngọt');

-- Quán Kem & Bánh Sweet Cake
INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Kem' FROM CuaHang c WHERE c.tenQuan LIKE 'Tiệm Kem & Bánh%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Kem');

INSERT INTO DanhMuc (maQuan, tenDanhMuc)
SELECT c.maQuan, 'Bánh Sinh Nhật' FROM CuaHang c WHERE c.tenQuan LIKE 'Tiệm Kem & Bánh%'
AND NOT EXISTS (SELECT 1 FROM DanhMuc d WHERE d.maQuan = c.maQuan AND d.tenDanhMuc = 'Bánh Sinh Nhật');

-- 4. Nạp Danh Sách Món Ăn (Kiểm tra NOT EXISTS để không bị lặp lại món ăn khi chạy lại nhiều lần)
-- Phở Bò Gia Truyền
INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Phở Bò Tái Nạm Đặc Biệt', 65000.00, 100, 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500', 4.9, 128
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%' AND d.tenDanhMuc = 'Phở Truyền Thống'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Phở Bò Tái Nạm Đặc Biệt');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Phở Bò Tái Sườn Sụn', 75000.00, 80, 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500', 4.8, 95
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%' AND d.tenDanhMuc = 'Phở Truyền Thống'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Phở Bò Tái Sườn Sụn');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Phở Bò Gầu Bắp Trứng Chèn', 70000.00, 90, 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500', 4.9, 110
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%' AND d.tenDanhMuc = 'Phở Truyền Thống'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Phở Bò Gầu Bắp Trứng Chèn');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Quẩy Giòn Hà Nội (3 cái)', 10000.00, 300, 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=500', 4.7, 50
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%' AND d.tenDanhMuc = 'Món Ăn Kèm'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Quẩy Giòn Hà Nội (3 cái)');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Trứng Chèn Nước Béo', 12000.00, 200, 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500', 4.8, 62
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%' AND d.tenDanhMuc = 'Món Ăn Kèm'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Trứng Chèn Nước Béo');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Trà Đá Đường Thốt Nốt', 15000.00, 200, 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500', 4.7, 45
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%' AND d.tenDanhMuc = 'Nước Uống & Tráng Miệng'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Trà Đá Đường Thốt Nốt');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Trà Tắc Xí Muội Đường Phèn', 20000.00, 150, 'https://images.unsplash.com/photo-1556881286-fc6915169721?w=500', 4.9, 88
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%' AND d.tenDanhMuc = 'Nước Uống & Tráng Miệng'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Trà Tắc Xí Muội Đường Phèn');

-- Cơm Tấm Sài Gòn 99
INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Cơm Tấm Sườn Bì Chả Trứng', 55000.00, 150, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500', 4.9, 210
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Cơm Tấm Sài Gòn%' AND d.tenDanhMuc = 'Cơm Tấm Đặc Biệt'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Cơm Tấm Sườn Bì Chả Trứng');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Cơm Tấm Sườn Nướng Muối Ớt', 50000.00, 120, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500', 4.8, 140
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Cơm Tấm Sài Gòn%' AND d.tenDanhMuc = 'Cơm Tấm Đặc Biệt'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Cơm Tấm Sườn Nướng Muối Ớt');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Cơm Tấm Sườn Cốt Lết Trứng Ốp La', 48000.00, 130, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500', 4.7, 98
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Cơm Tấm Sài Gòn%' AND d.tenDanhMuc = 'Cơm Tấm Đặc Biệt'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Cơm Tấm Sườn Cốt Lết Trứng Ốp La');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Canh Khổ Qua Dồn Thịt', 18000.00, 100, 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=500', 4.8, 76
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Cơm Tấm Sài Gòn%' AND d.tenDanhMuc = 'Món Kèm & Giải Khát'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Canh Khổ Qua Dồn Thịt');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Nước Sâm Bông Cúc Hạt Chia', 15000.00, 180, 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500', 4.9, 105
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Cơm Tấm Sài Gòn%' AND d.tenDanhMuc = 'Món Kèm & Giải Khát'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Nước Sâm Bông Cúc Hạt Chia');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Cà Phê Sữa Đá Sài Gòn', 25000.00, 200, 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500', 4.9, 190
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Cơm Tấm Sài Gòn%' AND d.tenDanhMuc = 'Món Kèm & Giải Khát'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Cà Phê Sữa Đá Sài Gòn');

-- Bún Bò Huế O Phượng
INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Bún Bò Huế Giò Heo Chả Cua', 60000.00, 120, 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500', 5.0, 310
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%' AND d.tenDanhMuc = 'Bún Bò Huế'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Bún Bò Huế Giò Heo Chả Cua');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Bún Bò Tái Bắp Bò Nạm', 55000.00, 100, 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500', 4.8, 160
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%' AND d.tenDanhMuc = 'Bún Bò Huế'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Bún Bò Tái Bắp Bò Nạm');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Bún Bò Huế Đặc Biệt Đầy Đủ', 75000.00, 80, 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500', 4.9, 230
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%' AND d.tenDanhMuc = 'Bún Bò Huế'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Bún Bò Huế Đặc Biệt Đầy Đủ');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Bánh Lọc Lá Chuối (10 cái)', 40000.00, 90, 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=500', 4.8, 75
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%' AND d.tenDanhMuc = 'Món Ăn Kèm Huế'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Bánh Lọc Lá Chuối (10 cái)');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Chả Cua Thêm (2 cục)', 20000.00, 150, 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=500', 4.9, 110
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%' AND d.tenDanhMuc = 'Món Ăn Kèm Huế'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Chả Cua Thêm (2 cục)');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Trà Cung Đình Huế', 20000.00, 120, 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500', 4.7, 85
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%' AND d.tenDanhMuc = 'Giải Khát'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Trà Cung Đình Huế');

-- Phúc Long Coffee & Tea Items
INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Cà Phê Phin Sữa Đậm Đà', 35000.00, 250, 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500', 4.9, 340
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phúc Long Coffee%' AND d.tenDanhMuc = 'Cà Phê'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Cà Phê Phin Sữa Đậm Đà');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Trà Sữa Phúc Long Ô Long', 49000.00, 300, 'https://images.unsplash.com/photo-1556881286-fc6915169721?w=500', 4.9, 420
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phúc Long Coffee%' AND d.tenDanhMuc = 'Trà Sữa'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Trà Sữa Phúc Long Ô Long');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Bánh Croissant Bơ Tươi', 32000.00, 100, 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500', 4.8, 110
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Phúc Long Coffee%' AND d.tenDanhMuc = 'Bánh Ngọt'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Bánh Croissant Bơ Tươi');

-- Sweet Cake Items
INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Kem Bơ Sáp Dừa Tươi', 38000.00, 150, 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=500', 4.9, 180
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Tiệm Kem & Bánh%' AND d.tenDanhMuc = 'Kem'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Kem Bơ Sáp Dừa Tươi');

INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia)
SELECT d.maDanhMuc, c.maQuan, 'Bánh Sinh Nhật Dâu Tây Kem Bơ', 280000.00, 30, 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500', 5.0, 95
FROM DanhMuc d JOIN CuaHang c ON d.maQuan = c.maQuan
WHERE c.tenQuan LIKE 'Tiệm Kem & Bánh%' AND d.tenDanhMuc = 'Bánh Sinh Nhật'
AND NOT EXISTS (SELECT 1 FROM MonAn m WHERE m.maQuan = c.maQuan AND m.tenMonAn = 'Bánh Sinh Nhật Dâu Tây Kem Bơ');

-- 5. Nạp Voucher Giảm Giá Lộ Trình (Tự động liên kết đúng maQuan)
INSERT INTO Voucher (maCode, tenVoucher, giamGia, loaiGiam, giaTriGiamToiDa, dieuKienDonToiThieu, soLuongToiDa, maQuan)
SELECT 'ROUTE10K', 'Giảm 10K Cho Đơn Lộ Trình', 10000.00, 'VND', 10000.00, 50000.00, 500, c.maQuan
FROM CuaHang c WHERE c.tenQuan LIKE 'Phở Bò Gia Truyền%'
ON CONFLICT (maCode) DO NOTHING;

INSERT INTO Voucher (maCode, tenVoucher, giamGia, loaiGiam, giaTriGiamToiDa, dieuKienDonToiThieu, soLuongToiDa, maQuan)
SELECT 'TAKEAWAY20', 'Giảm 20% Đặt Bàn / Takeaway', 20.00, 'PERCENT', 30000.00, 100000.00, 300, c.maQuan
FROM CuaHang c WHERE c.tenQuan LIKE 'Cơm Tấm Sài Gòn%'
ON CONFLICT (maCode) DO NOTHING;

INSERT INTO Voucher (maCode, tenVoucher, giamGia, loaiGiam, giaTriGiamToiDa, dieuKienDonToiThieu, soLuongToiDa, maQuan)
SELECT 'BUNBO15', 'Giảm 15% Cho Đơn Đặt Trước', 15.00, 'PERCENT', 25000.00, 80000.00, 200, c.maQuan
FROM CuaHang c WHERE c.tenQuan LIKE 'Bún Bò Huế O Phượng%'
ON CONFLICT (maCode) DO NOTHING;
