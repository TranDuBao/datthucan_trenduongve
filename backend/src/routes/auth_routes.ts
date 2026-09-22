import { Router } from 'express';
import { AuthController } from '../controllers/auth_controller';
import { authMiddleware } from '../middlewares/auth_middleware';

const router = Router();
const authController = new AuthController();

// Authentication Endpoints
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/google', authController.googleAuth);
router.post('/logout', authController.logout);
router.get('/me', authMiddleware as any, authController.getProfile);
router.post('/update_profile', authController.updateProfile);
router.put('/update_profile', authController.updateProfile);
router.post('/change_password', authController.changePassword);

export default router;
