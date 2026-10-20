import { Router } from 'express';
import { AuthController } from '../controllers/auth_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { createRateLimiter } from '../middlewares/rate_limiter_middleware';

const router = Router();
const authController = new AuthController();

// Strict Rate Limiter specifically for Login / Register / Google Auth actions
const authLimiter = createRateLimiter(15 * 60 * 1000, 50);

// Authentication Endpoints
router.post('/register', authLimiter as any, authController.register);
router.post('/login', authLimiter as any, authController.login);
router.post('/google', authLimiter as any, authController.googleAuth);
router.post('/logout', authController.logout);
router.post('/refresh', authLimiter as any, authController.refreshToken);
router.post('/refresh-token', authLimiter as any, authController.refreshToken);
router.get('/me', authMiddleware as any, authController.getProfile);
router.post('/me', authMiddleware as any, authController.getProfile);
router.post('/update_profile', authMiddleware as any, authController.updateProfile);
router.put('/update_profile', authMiddleware as any, authController.updateProfile);
router.post('/change_password', authMiddleware as any, authController.changePassword);
router.post('/scan-cccd', authController.scanCCCD);

export default router;
