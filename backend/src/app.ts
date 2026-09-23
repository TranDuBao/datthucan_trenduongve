import express, { Application } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth_routes';
import restaurantRoutes from './routes/restaurant_routes';
import orderRoutes from './routes/order_routes';
import paymentRoutes from './routes/payment_routes';

import { RestaurantController } from './controllers/restaurant_controller';

dotenv.config();

const app: Application = express();
const restaurantController = new RestaurantController();

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes Layer
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/restaurants', restaurantRoutes);
app.get('/api/v1/categories', restaurantController.getCategories);
app.use('/api/v1/orders', orderRoutes);
app.use('/api/v1/payments', paymentRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', message: 'Smart City Food Route API running' });
});

export default app;
