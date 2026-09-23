import { Router } from 'express';
import { AdminController } from '../controllers/admin_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { requireRole } from '../middlewares/role_middleware';

const router = Router();
const controller = new AdminController();

// All Admin routes require Auth & ADMIN Role
router.use(authMiddleware as any);
router.use(requireRole(['ADMIN']) as any);

router.get('/stats', controller.getDashboardStats as any);
router.get('/users', controller.getUsers as any);
router.put('/users/:id/role', controller.updateUserRole as any);

router.get('/restaurants', controller.getRestaurants as any);
router.post('/restaurants', controller.createRestaurant as any);
router.put('/restaurants/:id', controller.updateRestaurant as any);

router.get('/categories', controller.getCategories as any);
router.post('/categories', controller.createCategory as any);

router.get('/foods', controller.getFoods as any);
router.put('/foods/:id', controller.updateFood as any);
router.get('/orders', controller.getOrders as any);
router.get('/payments', controller.getPayments as any);

export default router;
