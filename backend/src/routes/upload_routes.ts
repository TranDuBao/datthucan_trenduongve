import { Router } from 'express';
import { UploadController } from '../controllers/upload_controller';
import { authMiddleware } from '../middlewares/auth_middleware';

const router = Router();
const controller = new UploadController();

router.post('/', authMiddleware as any, controller.uploadBase64 as any);

export default router;
