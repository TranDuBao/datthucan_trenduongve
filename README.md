# 🚴‍♂️ Ứng Dụng Tối Ưu Lộ Trình Đặt Đồ Ăn & Mua Sắm Không Tiền Mặt (Smart City Take-Away & Route Food App)

Hệ thống ứng dụng thông minh hỗ trợ thực khách di chuyển từ điểm A đến điểm B tìm kiếm, khám phá nhà hàng/quán ăn nằm ngay trên hoặc gần lộ trình di chuyển, hỗ trợ đặt đồ ăn mang đi (Take-away), đặt bàn trước (Table Reservation) và thanh toán không dùng tiền mặt trong hệ sinh thái đô thị thông minh.

---

## 🏗️ Cấu Trúc Tổng Thể Dự Án

Dự án gồm 3 thành phần chính: **Backend (RESTful API & Realtime Socket.io)**, **Web Portal (Admin & Quản Lý Nhà Hàng)**, và **Mobile App (Ứng Dụng Khách Hàng)**.

```
datthucan/
├── backend/               # Server API Node.js / Express / TypeORM & Socket.io
├── mobile/                # Flutter Mobile App (Khách hàng)
├── web/                   # Web App React + Vite (Admin & Cửa hàng)
├── database/              # Schema CSDL PostgreSQL (18 bảng)
├── uploads/               # Thư mục chứa hình ảnh & tài nguyên tĩnh
└── docker-compose.yml     # Khởi chạy toàn bộ hệ thống bằng Docker
```

---

## 🛠️ Cấu Trúc Chi Tiết Các Thành Phần

### 1. Backend (`/backend` - Layered Architecture)

Sử dụng Node.js, TypeScript, Express, TypeORM kết nối CSDL PostgreSQL + PostGIS:

```
backend/src/
├── config/                # Cấu hình CSDL (Bảo vệ dữ liệu synchronize=false) & JWT
│   └── database.ts
├── models/                # TypeORM Entities (18 Bảng)
│   ├── tai_khoan_model.ts       # Tài khoản & Quyền hạn
│   ├── khach_hang_model.ts      # Thông tin Khách hàng
│   ├── cua_hang_model.ts        # Thông tin Nhà hàng / Quán ăn
│   ├── ban_model.ts             # Sơ đồ bàn phục vụ
│   ├── dat_ban_model.ts         # Đơn đặt bàn & Lịch hẹn
│   ├── mon_an_model.ts          # Thực đơn & Món ăn
│   ├── don_hang_model.ts        # Đơn hàng Take-away / Tại quán
│   ├── voucher_model.ts         # Mã khuyến mãi & Ưu đãi
│   └── thanh_toan_model.ts      # Giao dịch thanh toán (VietQR/PayOS/MoMo)
├── services/              # Xử lý Logic Nghiệp vụ & Realtime Emitter
│   ├── auth_service.ts          # Xác thực JWT, Google OAuth, Hash Mật khẩu
│   ├── reservation_service.ts   # Quản lý Đặt bàn & Khóa giao dịch
│   ├── restaurant_mgmt_service.ts # Nghiệp vụ quản lý Nhà hàng
│   └── order_service.ts         # Xử lý đơn hàng Take-away
├── controllers/           # HTTP Handlers (Request/Response validation)
│   ├── auth_controller.ts
│   ├── reservation_controller.ts
│   ├── restaurant_mgmt_controller.ts
│   ├── admin_controller.ts
│   └── payment_controller.ts
├── routes/                # Định tuyến RESTful APIs
│   ├── auth_routes.ts
│   ├── restaurant_mgmt_routes.ts
│   └── admin_routes.ts
└── middlewares/           # Middlewares (Auth JWT, Role Permission, Upload)
```

---

### 2. Web Portal (`/web` - React + Vite + Clean Vanilla CSS)

Trang quản trị đa phân quyền dành cho Quản trị viên (Admin System) và Chủ nhà hàng (Restaurant Portal):

```
web/src/
├── api/                   # API Client & Interceptors (Axios / Fetch)
├── components/            # UI Components tái sử dụng (MetricCard, AnimatedCounter, Modals)
├── context/               # AuthContext & Global State Management
├── pages/
│   ├── admin/             # Giao diện Hệ thống Quản trị (Admin)
│   │   ├── AdminDashboard.tsx       # Báo cáo tổng quan toàn hệ thống
│   │   ├── AdminRestaurants.tsx     # Duyệt & Quản lý nhà hàng
│   │   ├── AdminUsers.tsx           # Quản lý tài khoản & phân quyền
│   │   └── AdminActivityLogs.tsx    # Nhật ký hoạt động hệ thống
│   └── restaurant/        # Giao diện Cổng Quản Lý Nhà Hàng (Portal)
│       ├── RestaurantDashboard.tsx  # Chỉ số hoạt động realtime & cảnh báo
│       ├── RestaurantReservations.tsx # Quản lý đặt bàn & Sơ đồ bàn
│       ├── RestaurantOrders.tsx       # Quản lý & Điều phối đơn hàng
│       ├── RestaurantMenu.tsx         # Quản lý thực đơn & Món ăn
│       └── RestaurantVouchers.tsx     # Quản lý mã giảm giá
└── App.tsx                # Routing chính hệ thống
```

---

### 3. Mobile Customer App (`/mobile` - Flutter Provider/MVVM Architecture)

Ứng dụng di động dành cho khách hàng tìm kiếm lộ trình, đặt đồ ăn mang đi và đặt bàn trước:

```
mobile/lib/
├── models/                # Data Models (User, Restaurant, Order, Reservation)
├── views/ / screens/      # Giao diện UI (Route map, Food detail, Booking UI)
├── providers/             # State Management (ChangeNotifier / Provider)
├── services/              # API Client Services & Socket.io Realtime Client
├── common/                # Locator (GetIt) Dependency Injection & Constants
└── main.dart              # Entrypoint ứng dụng
```

---

## 🛡️ Quy Tắc Hệ Thống & Bảo Vệ CSDL (`.agents/AGENTS.md`)

1. **Bảo vệ CSDL PostgreSQL hiện có (`synchronize: false`):**
   - Backend tuyệt đối **KHÔNG BAO GIỜ** tự động xóa, reset hoặc `dropSchema` CSDL 18 bảng. Tất cả thay đổi schema đều phải backward-compatible.
2. **Kiến trúc Layered & Phân quyền bảo mật (Security & Ownership):**
   - Xác thực bắt buộc qua JWT token (Server-side check).
   - Phân quyền chặt chẽ theo vai trò (`KHACH_HANG`, `CHU_CUA_HANG`, `ADMIN`).
   - Nhà hàng A tuyệt đối không được đọc hoặc can thiệp dữ liệu của Nhà hàng B.
3. **Giới hạn độ dài file code (< 1000 dòng):**
   - Đảm bảo mã nguồn được thiết kế mô-đun hóa, dễ bảo trì và mở rộng.

---

## 🚀 Hướng Dẫn Khởi Chạy Hệ Thống

### 1. Khởi chạy bằng Docker Compose (Khuyên dùng)
```bash
docker-compose up -d --build
```

### 2. Khởi chạy Backend API Server
```bash
cd backend
npm install
npm run dev
# Server lắng nghe tại: http://localhost:3000
```

### 3. Khởi chạy Web Portal (Admin & Nhà Hàng)
```bash
cd web
npm install
npm run dev
# Web Portal hoạt động tại: http://localhost:5173
```

### 4. Khởi chạy Flutter Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

---

## 📡 Tổng Quan Danh Sách RESTful APIs

### 1. Xác thực & Tài khoản (`/api/v1/auth`)
- `POST /api/v1/auth/register` - Đăng ký tài khoản khách hàng / chủ nhà hàng
- `POST /api/v1/auth/login` - Đăng nhập bằng Email/Mật khẩu
- `POST /api/v1/auth/google` - Đăng nhập bằng Google OAuth ID Token
- `GET /api/v1/auth/me` - Lấy thông tin cá nhân hiện tại

### 2. Quản lý Nhà hàng (`/api/v1/restaurant-mgmt`)
- `GET /api/v1/restaurant-mgmt/profile` - Lấy thông tin chi tiết nhà hàng
- `PUT /api/v1/restaurant-mgmt/profile` - Cập nhật thông tin nhà hàng & giờ mở cửa
- `GET /api/v1/restaurant-mgmt/menu` - Lấy danh sách thực đơn & món ăn
- `POST /api/v1/restaurant-mgmt/menu` - Thêm món ăn mới vào thực đơn

### 3. Quản lý Đặt bàn (`/api/v1/restaurant/reservations`)
- `GET /api/v1/restaurant/reservations/stats` - Thống kê chỉ số đặt bàn hôm nay
- `GET /api/v1/restaurant/reservations` - Lấy danh sách đặt bàn (lọc theo trạng thái & ngày)
- `POST /api/v1/restaurant/reservations/:id/confirm` - Xác nhận đơn đặt bàn
- `POST /api/v1/restaurant/reservations/:id/check-in` - Xác nhận khách đã đến bàn

### 4. Quản lý Đơn hàng Take-away & Thanh toán
- `GET /api/v1/orders` - Danh sách đơn hàng
- `POST /api/v1/orders` - Tạo đơn hàng mới
- `POST /api/v1/payments/payos/create` - Tạo liên kết thanh toán VietQR / PayOS
- `POST /api/v1/payments/payos/webhook` - Webhook xác nhận thanh toán tự động

### 5. Hệ thống Quản trị Admin (`/api/v1/admin`)
- `GET /api/v1/admin/dashboard` - Thống kê toàn hệ thống
- `GET /api/v1/admin/restaurants` - Danh sách & duyệt nhà hàng đối tác
- `GET /api/v1/admin/users` - Quản lý danh sách người dùng & khóa tài khoản
- `GET /api/v1/admin/activity-logs` - Tra cứu nhật ký hoạt động hệ thống
