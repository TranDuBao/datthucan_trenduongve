import express, { Application } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import authRoutes from './routes/auth_routes';
import restaurantRoutes from './routes/restaurant_routes';
import orderRoutes from './routes/order_routes';
import paymentRoutes from './routes/payment_routes';
import adminRoutes from './routes/admin_routes';
import restaurantMgmtRoutes from './routes/restaurant_mgmt_routes';
import customerVoucherRoutes from './routes/customer_voucher_routes';
import customerReservationRoutes from './routes/customer_reservation_routes';
import uploadRoutes from './routes/upload_routes';
import reviewRoutes from './routes/review_routes';
import notificationRoutes from './routes/notification_routes';
import refundRoutes from './routes/refund_routes';
import storeRegistrationRoutes from './routes/store_registration_routes';
import legalDocumentRoutes from './routes/legal_document_routes';
import supportRoutes from './routes/support_routes';

import { RestaurantController } from './controllers/restaurant_controller';
import { SystemInfoController } from './controllers/system_info_controller';
import { AdminBannerService } from './services/admin/admin_banner_service';
import { createRateLimiter } from './middlewares/rate_limiter_middleware';

dotenv.config();

const app: Application = express();
const trustProxyHops = Number(process.env.TRUST_PROXY_HOPS) || 1;
app.set('trust proxy', trustProxyHops);

const restaurantController = new RestaurantController();
const adminBannerService = new AdminBannerService();
const systemInfoController = new SystemInfoController();

// Configured CORS Origin (supports CLIENT_ORIGIN or CORS_ORIGIN)
const corsEnv = process.env.CLIENT_ORIGIN || process.env.CORS_ORIGIN;
const allowedOrigins = corsEnv
  ? corsEnv.split(',').map((o) => o.trim())
  : ['http://localhost:5173', 'http://localhost:3000', 'http://127.0.0.1:5173'];

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else if (process.env.NODE_ENV !== 'production') {
        callback(null, true); // Dev fallback
      } else {
        callback(new Error('Chặn bởi chính sách bảo mật CORS (Origin không được phép)'));
      }
    },
    credentials: true,
  })
);

app.use(
  express.json({
    limit: '20mb',
    verify: (req: any, _res, buf) => {
      req.rawBody = buf;
    },
  })
);
app.use(express.urlencoded({ extended: true, limit: '20mb' }));

// Serve static uploads (ensuring directory exists)
const uploadsDir = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

// Security: Chặn truy cập công khai trực tiếp tới các tệp KYC/CCCD nhạy cảm
const blockKycStatic = (req: express.Request, res: express.Response, next: express.NextFunction) => {
  const normalized = (req.path || '').toLowerCase();
  if (normalized.includes('kyc_') || normalized.includes('cccd_')) {
    return res.status(403).json({
      statusCode: 403,
      message: 'Tài liệu nhạy cảm yêu cầu xác thực qua /api/v1/upload/kyc',
    });
  }
  next();
};

app.use(
  '/uploads',
  blockKycStatic,
  express.static(uploadsDir, {
    setHeaders: (res) => {
      res.setHeader('X-Content-Type-Options', 'nosniff');
    },
  })
);
const fallbackUploadsDir = path.join(__dirname, '../uploads');
if (fs.existsSync(fallbackUploadsDir)) {
  app.use(
    '/uploads',
    blockKycStatic,
    express.static(fallbackUploadsDir, {
      setHeaders: (res) => {
        res.setHeader('X-Content-Type-Options', 'nosniff');
      },
    })
  );
}

// Routes Layer
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/restaurants', restaurantRoutes);
app.get('/api/v1/system/about-us', systemInfoController.getAboutUs as any);
app.get('/api/v1/categories', restaurantController.getCategories);
app.get('/api/v1/banners', async (_req, res) => {
  try {
    const banners = await adminBannerService.getActiveBanners();
    return res.status(200).json({ statusCode: 200, status: '1', data: banners });
  } catch (error: any) {
    return res.status(500).json({ statusCode: 500, message: error.message });
  }
});
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/reservations', customerReservationRoutes);
app.use('/api/v1/admin', adminRoutes);
// Restaurant Store Owner Management Routes (/api/v1/restaurant/dashboard, /revenue, /orders, /menu, /profile, /vouchers)
app.use('/api/v1/restaurant', restaurantMgmtRoutes);
app.use('/api/v1/vouchers', customerVoucherRoutes);
app.use('/api/v1/upload', uploadRoutes);
app.use('/api/v1', reviewRoutes);
app.use('/api/v1/notifications', notificationRoutes);
app.use('/api/v1/refunds', refundRoutes);
app.use('/api/v1', storeRegistrationRoutes);
app.use('/api', storeRegistrationRoutes);
app.use('/api/v1', legalDocumentRoutes);
app.use('/api', legalDocumentRoutes);
app.use('/api/v1', supportRoutes);
app.use('/api', supportRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Smart City Food Route API running' });
});

// 404 Handler cho các API không tồn tại
app.use((req, res, next) => {
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({ statusCode: 404, status: 'error', message: 'API route không tồn tại' });
  }
  next();
});

// Middleware xử lý lỗi toàn cục (Global Exception Handler)
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error('[App] [Lỗi chưa bắt]:', err);
  const status = Number(err.statusCode || err.status || 500);
  const message = err.message || 'Lỗi hệ thống nội bộ';
  return res.status(status).json({
    statusCode: status,
    status: 'error',
    message: process.env.NODE_ENV === 'production' && status === 500 ? 'Đã có lỗi hệ thống xảy ra' : message,
  });
});

export default app;
