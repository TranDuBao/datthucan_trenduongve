import { Router } from 'express';
import { AdminController } from '../controllers/admin_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { requireRole } from '../middlewares/role_middleware';

import { AuditLogController } from '../controllers/audit_log_controller';

const router = Router();
const controller = new AdminController();
const auditLogController = new AuditLogController();

// All Admin routes require Auth & ADMIN Role
router.use(authMiddleware as any);
router.use(requireRole(['ADMIN']) as any);

router.get('/stats', controller.getDashboardStats as any);
router.get('/users', controller.getUsers as any);
router.post('/users', controller.createUser as any);

// Specific user subpath routes MUST be defined before generic /users/:id
router.put('/users/:id/lock', controller.lockUser as any);
router.put('/users/:id/password', controller.changeUserPassword as any);

// Generic user CRUD routes
router.get('/users/:id', controller.getUserDetail as any);
router.put('/users/:id', controller.updateUser as any);
router.delete('/users/:id', controller.deleteUser as any);
router.post('/scan-cccd', controller.scanCCCD as any);

router.get('/restaurants', controller.getRestaurants as any);
router.get('/restaurants/:id/detail', controller.getRestaurantDetail as any);
router.post('/restaurants', controller.createRestaurant as any);
router.put('/restaurants/:id', controller.updateRestaurant as any);
router.delete('/restaurants/:id', controller.deleteRestaurant as any);
router.patch('/restaurants/:id/restore', controller.restoreRestaurant as any);
router.post('/restaurants/:id/restore', controller.restoreRestaurant as any);


router.get('/categories', controller.getCategories as any);
router.post('/categories', controller.createCategory as any);
router.put('/categories/:id', controller.updateCategory as any);
router.get('/categories/:id/foods', controller.getCategoryFoods as any);

router.get('/foods', controller.getFoods as any);
router.put('/foods/:id', controller.updateFood as any);
router.get('/orders', controller.getOrders as any);
router.get('/payments', controller.getPayments as any);
router.get('/activity-logs/export-csv', auditLogController.exportCsv as any);
router.get('/activity-logs', auditLogController.getLogs as any);

export default router;
