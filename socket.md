# Kế Hoạch & Hướng Dẫn Triển Khai Realtime / Socket.io (`socket.md`)

> **Bối cảnh dự án**: Ứng dụng khám phá quán ăn & đặt đồ ăn mang đi (Pre-order) / Đặt bàn theo lộ trình (KHÔNG phải ứng dụng gọi xe/bài toán tài xế).
> **Vai trò của Socket.io**: Chỉ dùng để đẩy (push) sự kiện đồng bộ realtime giữa App Khách hàng (Mobile), Phía Nhà hàng (Web) và Backend. Cơ sở dữ liệu (PostgreSQL via TypeORM) là Source of Truth duy nhất.

---

## I. BÁO CÁO KHẢO SÁT HỆ THỐNG (GIAI ĐOẠN 1)

### 1. Hiện trạng Socket.io & Polling
* **Thành phần hiện tại**:
  * Backend (`backend/src/`): Chưa có Socket.io hay Gateway/Service Realtime.
  * Mobile (`mobile/lib/`): Chưa có Socket.io Service hay Provider Realtime.
  * Web (`web/src/`): Chưa có Socket.io Client.
* **Dependencies**:
  * `backend/package.json`: Project chạy **Express + TypeORM + TypeScript**. Chưa cài `socket.io`.
  * `mobile/pubspec.yaml`: Chưa cài `socket_io_client`.
  * `web/package.json`: Chưa cài `socket.io-client`.
* **Polling**: Hệ thống hiện tại không sử dụng vòng lặp Polling (`Timer.periodic` / `setInterval`) cho đơn hàng/thanh toán. Cập nhật state phụ thuộc vào pull-to-refresh hoặc điều hướng người dùng.

### 2. Bản đồ Code & Các chức năng cần Realtime

#### a. Đơn hàng mang đi (Takeaway / Pre-order) & Đặt bàn
* **Backend Controller**: [`order_controller.ts`](file:///d:/Nam_cuoi/KLTN/datthucan/backend/src/controllers/order_controller.ts) & [`restaurant_mgmt_controller.ts`](file:///d:/Nam_cuoi/KLTN/datthucan/backend/src/controllers/restaurant_mgmt_controller.ts)
* **Backend Service**: [`order_service.ts`](file:///d:/Nam_cuoi/KLTN/datthucan/backend/src/services/order_service.ts) & [`restaurant_mgmt_service.ts`](file:///d:/Nam_cuoi/KLTN/datthucan/backend/src/services/restaurant_mgmt_service.ts)
* **Backend Entity**: [`don_hang_model.ts`](file:///d:/Nam_cuoi/KLTN/datthucan/backend/src/models/don_hang_model.ts) (`DonHangModel`, bảng `donhang`)
* **Trạng thái chuẩn trong DB**:
  * `'chờ xử lý'` (PENDING)
  * `'đã xác nhận'` (CONFIRMED)
  * `'đang chuẩn bị'` (PREPARING)
  * `'sẵn sàng ghé lấy'` (READY_FOR_PICKUP)
  * `'đã hoàn thành'` / `'đã lấy món'` (COMPLETED / PICKED_UP)
  * `'đã hủy'` (CANCELLED)
* **Mobile Layer**: [`order_service.dart`](file:///d:/Nam_cuoi/KLTN/datthucan/mobile/lib/services/order_service.dart), [`order_history_view.dart`](file:///d:/Nam_cuoi/KLTN/datthucan/mobile/lib/view/orders/order_history_view.dart), [`checkout_view.dart`](file:///d:/Nam_cuoi/KLTN/datthucan/mobile/lib/view/more/checkout_view.dart).

#### b. Thanh toán (PayOS / MoMo / VietQR)
* **Backend**: [`payment_controller.ts`](file:///d:/Nam_cuoi/KLTN/datthucan/backend/src/controllers/payment_controller.ts) & [`thanh_toan_model.ts`](file:///d:/Nam_cuoi/KLTN/datthucan/backend/src/models/thanh_toan_model.ts) (`ThanhToanModel`, bảng `thanhtoan`)
* **Trạng thái DB**: `'THANH_TOAN_THANH_CONG'`, `'CHUA_THANH_TOAN'`, `'THANH_TOAN_THAT_BAI'`
* **Mobile Service**: [`payment_service.dart`](file:///d:/Nam_cuoi/KLTN/datthucan/mobile/lib/services/payment_service.dart)

#### c. Thông báo trong app
* **Mobile**: [`notification_service.dart`](file:///d:/Nam_cuoi/KLTN/datthucan/mobile/lib/services/notification_service.dart) (`NotificationModel`, `NotificationService.fetchNotificationsFromDB()`).
* **Cơ chế**: Khi phát sinh sự kiện đơn/thanh toán, gửi event realtime `notification:new` trực tiếp tới room `user:{userId}`.

### 3. Phía Nhà hàng (Restaurant Side)
* **Giao diện**: Nền tảng Web React + Vite tại [`web/src/pages/restaurant/`](file:///d:/Nam_cuoi/KLTN/datthucan/web/src/pages/restaurant) (`RestaurantOrders.tsx`, `RestaurantDashboard.tsx`).
* **Room socket**: `restaurant:{maQuan}`. Khi chủ quán đăng nhập web, client gia nhập room này để nhận thông báo đơn hàng mới và cập nhật trạng thái tự động mà không cần F5.

### 4. Cơ chế Xác thực JWT
* **File liên quan**: [`auth_service.ts`](file:///d:/Nam_cuoi/KLTN/datthucan/backend/src/services/auth_service.ts) & [`auth_middleware.ts`](file:///d:/Nam_cuoi/KLTN/datthucan/backend/src/middlewares/auth_middleware.ts)
* **JWT Payload**:
  * `sub`: ID tài khoản (`maTaiKhoan`, number)
  * `email`: Email / tên đăng nhập
  * `role`: Loại tài khoản (`loaiTaiKhoan` - ví dụ: `'KHACH_HANG'`, `'NHA_HANG'`, `'ADMIN'`)
* **Biến môi trường**: `JWT_SECRET` (Đọc qua `process.env.JWT_SECRET`)

### 5. Kiến trúc Flutter
* **Locator (`GetIt`)**: [`locator.dart`](file:///d:/Nam_cuoi/KLTN/datthucan/mobile/lib/common/locator.dart)
* **State Management**: Provider trong [`main.dart`](file:///d:/Nam_cuoi/KLTN/datthucan/mobile/lib/main.dart)

---

## II. DANH SÁCH EVENT & ROOM CHUẨN

### 1. Định danh Room (Server quyết định từ JWT Token)
* `user:{userId}`: Ví dụ `user:5` (Khách hàng nhận thông báo cá nhân & kết quả thanh toán).
* `order:{orderId}`: Ví dụ `order:102` (Phòng của đơn hàng cụ thể).
* `restaurant:{maQuan}`: Ví dụ `restaurant:3` (Tất cả nhân viên/chủ quán của nhà hàng đó).

### 2. Sự kiện (Event Names - Snake_case)
* `order:created`: Gửi tới `restaurant:{maQuan}` và `user:{maKhachHang}` khi tạo đơn thành công.
* `order:status_changed`: Gửi tới `order:{orderId}`, `user:{maKhachHang}` và `restaurant:{maQuan}` khi trạng thái thay đổi.
* `payment:confirmed`: Gửi tới `order:{orderId}` và `user:{maKhachHang}` khi xác nhận thanh toán thành công.
* `payment:failed`: Gửi tới `order:{orderId}` và `user:{maKhachHang}` khi thanh toán thất bại.
* `notification:new`: Gửi thông báo trong app tới `user:{userId}`.

---

## III. KẾ HOẠCH BƯỚC THỰC HIỆN CHI TIẾT (GIAI ĐOẠN 2)

### BƯỚC 1: CÀI ĐẶT DEPENDENCIES
1. **Backend**:
   ```bash
   cd backend
   npm install socket.io
   ```
2. **Mobile**:
   Cập nhật `mobile/pubspec.yaml`:
   ```yaml
   dependencies:
     socket_io_client: ^3.0.2
   ```
   Chạy `flutter pub get`.
3. **Web**:
   ```bash
   cd web
   npm install socket.io-client
   ```

---

### BƯỚC 2: XÂY DỰNG MODULE REALTIME BACKEND

#### 1. Tạo file `backend/src/modules/realtime/events/realtime_events.ts`
```typescript
export const REALTIME_ROOMS = {
  user: (userId: number | string) => `user:${userId}`,
  order: (orderId: number | string) => `order:${orderId}`,
  restaurant: (storeId: number | string) => `restaurant:${storeId}`,
};

export const REALTIME_EVENTS = {
  ORDER_CREATED: 'order:created',
  ORDER_STATUS_CHANGED: 'order:status_changed',
  PAYMENT_CONFIRMED: 'payment:confirmed',
  PAYMENT_FAILED: 'payment:failed',
  NOTIFICATION_NEW: 'notification:new',
  ROOM_JOIN: 'room:join',
  ROOM_LEAVE: 'room:leave',
};
```

#### 2. Tạo file `backend/src/modules/realtime/realtime_service.ts`
```typescript
import { Server } from 'socket.io';

export class RealtimeService {
  private static instance: RealtimeService;
  private io: Server | null = null;

  private constructor() {}

  public static getInstance(): RealtimeService {
    if (!RealtimeService.instance) {
      RealtimeService.instance = new RealtimeService();
    }
    return RealtimeService.instance;
  }

  public setServer(io: Server) {
    this.io = io;
  }

  public emitToRoom(room: string, event: string, payload: any) {
    if (!this.io) {
      console.warn('⚠️ RealtimeService: Socket.io server chưa được khởi tạo');
      return;
    }
    this.io.to(room).emit(event, payload);
  }

  public emitToUser(userId: number, event: string, payload: any) {
    this.emitToRoom(`user:${userId}`, event, payload);
  }
}
```

#### 3. Tạo file `backend/src/modules/realtime/realtime_gateway.ts`
* Xác thực JWT token từ `socket.handshake.auth.token`.
* Lưu `userId` và `role` vào `socket.data`.
* Tự động join room `user:{userId}`.
* Xử lý sự kiện client join/leave room (kiểm tra quyền truy cập).

#### 4. Khởi tạo Socket.io trong `backend/src/server.ts` & `backend/src/app.ts`
* Đổi `app.listen` thành tạo `http.createServer(app)` và đính kèm `Server` của `socket.io`.

---

### BƯỚC 3: TÍCH HỢP PHÁT EVENT TRONG CÁC SERVICE BACKEND

1. **`backend/src/services/order_service.ts`**:
   * Sau khi `donHangRepo.save(...)` thành công trong `createPreOrder`, gọi:
     ```typescript
     const realtime = RealtimeService.getInstance();
     realtime.emitToRoom(`restaurant:${savedOrder.maQuan}`, REALTIME_EVENTS.ORDER_CREATED, {
       id: savedOrder.maDonHang,
       maQuan: savedOrder.maQuan,
       maKhachHang: savedOrder.maKhachHang,
       trangThai: savedOrder.trangThai,
       tongTien: savedOrder.tongTien,
       thoiGianHenNhan: savedOrder.thoiGianHenNhan,
       updatedAt: new Date(),
     });
     ```

2. **`backend/src/services/restaurant_mgmt_service.ts`**:
   * Sau khi `orderRepo.save(order)` thành công trong `updateOrderStatus`, gọi phát event `order:status_changed` tới `order:{maDonHang}` và `user:{maKhachHang}`.

3. **`backend/src/controllers/payment_controller.ts`**:
   * Sau khi `thanhToanRepo.save(payment)` thành công, gọi phát event `payment:confirmed` tới `order:{maDonHang}` và `user:{maKhachHang}`.

---

### BƯỚC 4: TRIỂN KHAI PHÍA MOBILE FLUTTER

1. **Tạo `mobile/lib/services/socket_service.dart`**:
   * 1 Instance duy nhất per app session.
   * Lấy token từ `Globs.udValueString(KKey.authToken)`.
   * Truyền `auth: {'token': token}` khi `io(...)`.
   * Lắng nghe sự kiện reconnect -> thông báo cho Provider thực hiện REST resync.

2. **Tạo `mobile/lib/providers/order_provider.dart`**:
   * Quản lý danh sách đơn hàng & trạng thái đơn hàng hiện tại.
   * Lắng nghe các event từ `SocketService` (`order:status_changed`, `payment:confirmed`, `notification:new`).
   * Gọi `notifyListeners()` để tự động rebuild UI màn hình lịch sử / chi tiết đơn hàng mà không thay đổi bất kỳ layout hay style nào.
   * Xử lý gỡ bỏ listener trong `dispose()`.

3. **Đăng ký Locator & Main**:
   * Đăng ký `SocketService` trong `mobile/lib/common/locator.dart`.
   * Thêm `OrderProvider` vào `MultiProvider` trong `mobile/lib/main.dart`.

---

### BƯỚC 5: TRIỂN KHAI PHÍA WEB RESTAURANT (`web/`)

1. **Tạo `web/src/services/socketService.ts`**:
   * Kết nối tới Socket.io backend với JWT của tài khoản chủ quán.
   * Gia nhập room `restaurant:{maQuan}`.

2. **Cập nhật `web/src/pages/restaurant/RestaurantOrders.tsx`**:
   * Lắng nghe `order:created` và `order:status_changed`.
   * Tự động tải lại danh sách đơn hàng của quán để hiển thị đơn mới tức thì.

---

## IV. CÁC QUY TẮC BẮT BUỘC TUÂN THỦ (CRITICAL RULES)

1. **Database là Source of Truth**: Chỉ emit SAU KHI thao tác ghi DB thành công. Không bao giờ lưu state socket làm dữ liệu chính.
2. **Gateway mỏng**: Không đặt business logic hay câu truy vấn TypeORM vào Gateway.
3. **Giữ nguyên UI**: Tuyệt đối KHÔNG thay đổi layout, style, màu sắc, phông chữ, navigation hay animation của ứng dụng Mobile/Web hiện có.
4. **Không dùng Dữ liệu giả**: Không tạo mảng/đối tượng giả để giả lập dữ liệu realtime.
5. **Giữ nguyên API REST**: Không thay đổi route, method, payload hay format response REST hiện tại.
6. **Xác thực JWT**: Mọi kết nối socket phải được xác thực token ở handshake. Không đọc token từ query string.

---

## V. ĐIỀU KIỆN KIỂM THỬ XÁC NHẬN (VERIFICATION CHECKLIST)

- [ ] Kết nối thành công với Token hợp lệ; từ chối kết nối khi Token thiếu/không hợp lệ.
- [ ] User A không thể join hoặc nhận thông báo đơn hàng của User B.
- [ ] Khi Nhà hàng chuyển trạng thái đơn (từ web/API), màn hình Mobile của Khách hàng cập nhật realtime tức thì.
- [ ] Ngắt kết nối mạng trên Mobile rồi bật lại (Reconnect): State ứng dụng tự động gọi REST API để đồng bộ lại dữ liệu mới nhất.
- [ ] Các endpoint REST API cũ hoạt động hoàn toàn bình thường, không xảy ra lỗi sập server.
