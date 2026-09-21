# 🚴‍♂️ Ứng Dụng Tối Ưu Lộ Trình Đặt Đồ Ăn & Mua Sắm Không Tiền Mặt (Smart City Take-Away & Route Food App)

Hệ thống hỗ trợ thực khách di chuyển từ điểm A đến điểm B tìm kiếm, đặt mua đồ ăn mang đi (Take-away) hoặc đặt bàn trước tại các quán ăn nằm ngay trên lộ trình di chuyển thích ứng ngữ cảnh đô thị thông minh.

---

## 🛠️ Cấu Trúc Thư Mục Backend (Layered Architecture)

```
backend/
├── src/
│   ├── config/             # Cấu hình CSDL (Bảo vệ dữ liệu synchronize=false)
│   │   └── database.ts
│   ├── models/             # MODEL: Các bảng CSDL (TaiKhoanModel, KhachHangModel)
│   │   ├── tai_khoan_model.ts
│   │   └── khach_hang_model.ts
│   ├── services/           # SERVICE: Xử lý logic nghiệp vụ, bcrypt hash, JWT, Google OAuth
│   │   ├── auth_service.ts
│   │   └── user_service.ts
│   ├── controllers/        # CONTROLLER: Xử lý Request/Response, Validate input
│   │   └── auth_controller.ts
│   ├── middlewares/        # MIDDLEWARE: Xác thực JWT token bảo mật
│   │   └── auth_middleware.ts
│   ├── routes/             # ROUTE: Định tuyến API
│   │   └── auth_routes.ts
│   ├── app.ts              # Cấu hình Express App
│   └── server.ts           # Khởi tạo Server HTTP
├── database/
│   └── schema_full.sql     # File SQL 15 Bảng Tiếng Việt
├── Dockerfile
└── package.json
```

---

## 📱 Cấu Trúc Mobile App (Flutter MVC)

```
mobile_flutter/
├── lib/
│   ├── models/             # MODEL: Data objects (user_model.dart, auth_response_model.dart)
│   ├── controllers/        # CONTROLLER: Business logic & State Management (auth_controller.dart)
│   ├── views/              # VIEW: Giao diện người dùng
│   │   ├── auth/           # login_view.dart, register_view.dart
│   │   ├── home/           # home_view.dart
│   │   └── components/     # custom_button.dart, custom_input.dart, google_button.dart
│   ├── services/           # Api service & Local storage (api_service.dart, auth_service.dart)
│   └── main.dart
```

---

## 🛡️ Quy Tắc Hệ Thống & CSDL (.agents/AGENTS.md)

1. **Bảo vệ CSDL PostgreSQL hiện có (`synchronize: false`):**
   - Backend tuyệt đối **KHÔNG BAO GIỜ** tự động xóa/reset dữ liệu 15 bảng CSDL có sẵn.
2. **Giới hạn độ dài file code (< 1000 dòng):**
   - Đảm bảo tất cả các file mã nguồn được chia nhỏ gọn gàng.

---

## 🚀 Hướng Dẫn Khởi Chạy

### 1. Khởi chạy bằng Docker Compose
```bash
docker-compose up -d --build
```

### 2. Khởi chạy Backend (Thủ công)
```bash
cd backend
npm install
npm run dev
```

### 3. Khởi chạy Flutter Mobile App
```bash
cd mobile_flutter
flutter pub get
flutter run
```

---

## 📡 Danh Sách API (Phase 1 Auth)

- `POST /api/v1/auth/register` - Đăng ký tài khoản (Tự động lưu vào `TaiKhoan` & `KhachHang`)
- `POST /api/v1/auth/login` - Đăng nhập Email/Tên đăng nhập & Mật khẩu
- `POST /api/v1/auth/google` - Đăng nhập bằng Google ID Token
- `GET /api/v1/auth/me` - Lấy thông tin cá nhân (Header: `Authorization: Bearer <TOKEN>`)
