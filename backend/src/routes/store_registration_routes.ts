import { Router } from 'express';
import { StoreRegistrationController } from '../controllers/store_registration_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { requireRole } from '../middlewares/role_middleware';

const router = Router();
const controller = new StoreRegistrationController();

// Customer endpoints
router.post('/store-registrations', authMiddleware as any, controller.submitRegistration);
router.get('/store-registrations/my-status', authMiddleware as any, controller.getMyStatus);

// Admin endpoints (strictly guarded by ADMIN role)
router.get('/admin/store-registrations', authMiddleware as any, requireRole(['ADMIN']) as any, controller.getAdminRegistrations);
router.get('/admin/store-registrations/:id', authMiddleware as any, requireRole(['ADMIN']) as any, controller.getAdminRegistrationDetail);
router.post('/admin/store-registrations/:id/approve', authMiddleware as any, requireRole(['ADMIN']) as any, controller.approveRegistration);
router.post('/admin/store-registrations/:id/reject', authMiddleware as any, requireRole(['ADMIN']) as any, controller.rejectRegistration);

export default router;

