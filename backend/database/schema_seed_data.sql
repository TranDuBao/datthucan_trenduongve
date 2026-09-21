-- SQL Seed Data for Smart City Food Route App
-- Nạp dữ liệu mẫu Tiếng Việt cho Cửa Hàng, Danh Mục, Món Ăn và Đánh Giá

-- 1. Nạp Tài Khoản Cửa Hàng Mẫu
INSERT INTO TaiKhoan (tenDangNhap, matKhau, loaiTaiKhoan, trangThai) VALUES
('cuahang_phobo', '$2b$10$e8gV9pQ10928371092837u.102938102938102938102938102938', 'CUAN_HANG', 'HOAT_DONG'),
('cuahang_comtam', '$2b$10$e8gV9pQ10928371092837u.102938102938102938102938102938', 'CUAN_HANG', 'HOAT_DONG'),
('cuahang_bunbo', '$2b$10$e8gV9pQ10928371092837u.102938102938102938102938102938', 'CUAN_HANG', 'HOAT_DONG')
ON CONFLICT (tenDangNhap) DO NOTHING;

-- 2. Nạp Danh Sách Cửa Hàng Lộ Trình (Smart City Route Shops)
INSERT INTO CuaHang (maTaiKhoan, tenQuan, diaChi, trangThai, lat, lng, SDT, img) VALUES
(1, 'Phở Bò Gia Truyền Hà Nội - Nguyễn Trãi', '235 Nguyễn Trãi, Quận 1, TP.HCM', 'mở cửa', 10.762622, 106.682029, '0901234567', 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500'),
(2, 'Cơm Tấm Sài Gòn 99 - Điện Biên Phủ', '180 Điện Biên Phủ, Bình Thạnh, TP.HCM', 'mở cửa', 10.793110, 106.702980, '0907654321', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500'),
(3, 'Bún Bò Huế O Phượng - Võ Văn Kiệt', '520 Võ Văn Kiệt, Quận 5, TP.HCM', 'mở cửa', 10.751230, 106.671450, '0903334455', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500')
ON CONFLICT DO NOTHING;

-- 3. Nạp Danh Mục Món Ăn
INSERT INTO DanhMuc (maQuan, tenDanhMuc) VALUES
(1, 'Phở Truyền Thống'),
(1, 'Nước Uống & Tráng Miệng'),
(2, 'Cơm Tấm Đặc Biệt'),
(3, 'Bún Bò Huế')
ON CONFLICT DO NOTHING;

-- 4. Nạp Danh Sách Món Ăn
INSERT INTO MonAn (maDanhMuc, maQuan, tenMonAn, giaMonAn, soLuongMon, img, diemDanhGiaTB, soLuotDanhGia) VALUES
(1, 1, 'Phở Bò Tái Nạm Đặc Biệt', 65000.00, 100, 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500', 4.9, 128),
(1, 1, 'Phở Bò Tái Sườn Sụn', 75000.00, 80, 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500', 4.8, 95),
(2, 1, 'Trà Đá Đường Thốt Nốt', 15000.00, 200, 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500', 4.7, 45),
(3, 2, 'Cơm Tấm Sườn Bì Chả Trứng', 55000.00, 150, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500', 4.9, 210),
(4, 3, 'Bún Bò Huế Giò Heo Chả Cua', 60000.00, 120, 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=500', 5.0, 310)
ON CONFLICT DO NOTHING;

-- 5. Nạp Voucher Giảm Giá Lộ Trình
INSERT INTO Voucher (maCode, tenVoucher, giamGia, loaiGiam, giaTriGiamToiDa, dieuKienDonToiThieu, soLuongToiDa, maQuan) VALUES
('ROUTE10K', 'Giảm 10K Cho Đơn Lộ Trình', 10000.00, 'VND', 10000.00, 50000.00, 500, 1),
('TAKEAWAY20', 'Giảm 20% Đặt Bàn / Takeaway', 20.00, 'PERCENT', 30000.00, 100000.00, 300, 2)
ON CONFLICT DO NOTHING;
