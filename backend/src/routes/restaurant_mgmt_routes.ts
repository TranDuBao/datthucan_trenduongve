import { Router } from 'express';
import { RestaurantMgmtController } from '../controllers/restaurant_mgmt_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { requireRole, requireStoreOwner } from '../middlewares/role_middleware';

const router = Router();
const controller = new RestaurantMgmtController();

// All Restaurant Management routes require Auth & (CUAN_HANG or ADMIN Role) & Store Ownership validation
router.use(authMiddleware as any);
router.use(requireRole(['CUAN_HANG', 'ADMIN']) as any);
router.use(requireStoreOwner as any);

router.get('/dashboard', controller.getDashboardStats as any);
router.get('/orders', controller.getOrders as any);
router.put('/orders/:id/status', controller.updateOrderStatus as any);

router.get('/categories', controller.getCategories as any);
router.get('/menu', controller.getMenu as any);
router.post('/menu', controller.createFoodItem as any);
router.put('/menu/:id', controller.updateFoodItem as any);
router.delete('/menu/:id', controller.deleteFoodItem as any);

router.get('/profile', controller.getStoreProfile as any);
router.put('/profile', controller.updateStoreProfile as any);

export default router;
