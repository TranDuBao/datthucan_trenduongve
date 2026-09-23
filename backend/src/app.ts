import express, { Application } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import authRoutes from './routes/auth_routes';
import restaurantRoutes from './routes/restaurant_routes';
import orderRoutes from './routes/order_routes';
import paymentRoutes from './routes/payment_routes';
import adminRoutes from './routes/admin_routes';
import restaurantMgmtRoutes from './routes/restaurant_mgmt_routes';
import uploadRoutes from './routes/upload_routes';

import { RestaurantController } from './controllers/restaurant_controller';

dotenv.config();

const app: Application = express();
const restaurantController = new RestaurantController();

// Middlewares
app.use(cors());
app.use(express.json({ limit: '20mb' }));
app.use(express.urlencoded({ extended: true, limit: '20mb' }));

// Serve static uploads
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Routes Layer
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/restaurants', restaurantRoutes);
app.get('/api/v1/categories', restaurantController.getCategories);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/restaurant', restaurantMgmtRoutes);
app.use('/api/v1/upload', uploadRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Smart City Food Route API running' });
});

export default app;
