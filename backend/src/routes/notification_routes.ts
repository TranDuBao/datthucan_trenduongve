import { Router } from 'express';
import { NotificationController } from '../controllers/notification_controller';
import { authMiddleware } from '../middlewares/auth_middleware';

const router = Router();
const controller = new NotificationController();

// 1. Public endpoint (Check app version for updates)
router.get('/app-version', controller.checkAppVersion as any);

// 2. Authenticated endpoints
router.use(authMiddleware as any);

// Inbox & Counter
router.get('/', controller.getUserInbox as any);
router.get('/inbox', controller.getUserInbox as any);
router.get('/unread-count', controller.getUnreadCount as any);
router.patch('/read-all', controller.markAllAsRead as any);
router.patch('/:id/read', controller.markAsRead as any);

// Device Token Registration (FCM)
router.post('/device-token', controller.registerDeviceToken as any);
router.delete('/device-token', controller.unregisterDeviceToken as any);

// Notification Settings
router.patch('/settings', controller.updateSettings as any);

export default router;
