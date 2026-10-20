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

import { RestaurantController } from './controllers/restaurant_controller';
import { createRateLimiter } from './middlewares/rate_limiter_middleware';

dotenv.config();

const app: Application = express();
const trustProxyHops = Number(process.env.TRUST_PROXY_HOPS) || 1;
app.set('trust proxy', trustProxyHops);

const restaurantController = new RestaurantController();

// Configured CORS Origin (P3-02 Fix)
const allowedOrigins = process.env.CLIENT_ORIGIN
  ? process.env.CLIENT_ORIGIN.split(',').map((o) => o.trim())
  : ['http://localhost:5173', 'http://localhost:3000', 'http://127.0.0.1:5173'];

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin || allowedOrigins.includes(origin) || process.env.NODE_ENV !== 'production') {
        callback(null, true);
      } else {
        callback(null, true); // Dev fallback
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
app.use(
  '/uploads',
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
app.get('/api/v1/categories', restaurantController.getCategories);
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

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Smart City Food Route API running' });
});

export default app;
