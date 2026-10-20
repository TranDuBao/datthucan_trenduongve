import { Router } from 'express';
import { NotificationController } from '../controllers/notification_controller';
import { authMiddleware } from '../middlewares/auth_middleware';

const router = Router();
const controller = new NotificationController();

// All notification routes require authentication
router.use(authMiddleware as any);

router.get('/', controller.getNotifications as any);
router.get('/unread-count', controller.getUnreadCount as any);
router.patch('/read-all', controller.markAllAsRead as any);
router.patch('/:id/read', controller.markAsRead as any);

export default router;
