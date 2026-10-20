import { Router } from 'express';
import { UploadController } from '../controllers/upload_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { createRateLimiter } from '../middlewares/rate_limiter_middleware';

const router = Router();
const controller = new UploadController();

// Rate limiter for upload endpoints (max 60 uploads per 15 minutes per IP)
const uploadLimiter = createRateLimiter(15 * 60 * 1000, 60);

// Active Upload routes (Web calls '/', Mobile calls '/base64')
router.post('/', uploadLimiter as any, authMiddleware as any, controller.uploadBase64 as any);
router.post('/base64', uploadLimiter as any, authMiddleware as any, controller.uploadBase64 as any);

// Active Delete route (Web calls 'DELETE /file')
router.delete('/file', authMiddleware as any, controller.deleteFile as any);

export default router;
