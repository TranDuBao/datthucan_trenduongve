import { Request, Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth_middleware';
import { NotificationService, UserNotificationContext } from '../services/notification_service';
import { AppDataSource } from '../config/database';
import { CuaHangModel } from '../models/cua_hang_model';
import { KhachHangModel } from '../models/khach_hang_model';

export class NotificationController {
  private notificationService = NotificationService.getInstance();
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);

  private async resolveUserContext(user: any): Promise<UserNotificationContext> {
    const userId = Number(user.sub);
    const role = String(user.role || '').toUpperCase();

    let storeId: number | undefined;
    let customerId: number | undefined;

    if (role === 'CUAN_HANG' || role === 'CUA_HANG' || role === 'RESTAURANT' || role === 'STORE') {
      const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userId } });
      if (store) storeId = store.maQuan;
    } else if (role !== 'ADMIN') {
      const kh = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userId } });
      if (kh) customerId = kh.maKhachHang;
    }

    return { userId, role, storeId, customerId };
  }

  /**
   * Register or update FCM device token
   */
  registerDeviceToken = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const user = req.user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const { token, platform, language, appVersion } = req.body;
      if (!token) {
        return res.status(400).json({ status: 'error', message: 'FCM Token là bắt buộc' });
      }

      const deviceToken = await this.notificationService.registerDeviceToken({
        userId: Number(user.sub),
        token,
        platform: platform || 'android',
        language: language || 'vi',
        appVersion,
      });

      return res.status(200).json({
        status: 'success',
        message: 'Đăng ký device token thành công',
        data: deviceToken,
      });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  };

  /**
   * Delete device token on logout
   */
  unregisterDeviceToken = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const { token } = req.body;
      if (token) {
        await this.notificationService.unregisterDeviceToken(token);
      }
      return res.status(200).json({ status: 'success', message: 'Đã hủy device token' });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  };

  /**
   * Get paginated inbox for the current authenticated user (Admin, Store, Customer)
   */
  getUserInbox = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const user = req.user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;
      const unreadOnly = req.query.unreadOnly === 'true';

      const context = await this.resolveUserContext(user);
      const result = await this.notificationService.getUserInbox(context, {
        page,
        limit,
        unreadOnly,
      });

      return res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (error: any) {
      console.error('[NotificationController] getUserInbox error:', error);
      return res.status(500).json({ status: 'error', message: error.message });
    }
  };

  /**
   * Get unread notification count
   */
  getUnreadCount = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const user = req.user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const context = await this.resolveUserContext(user);
      const count = await this.notificationService.getUnreadCount(context);
      return res.status(200).json({
        status: 'success',
        data: { unreadCount: count },
      });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  };

  /**
   * Mark a single notification as read
   */
  markAsRead = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const user = req.user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const id = parseInt(req.params.id, 10);
      if (isNaN(id) || id <= 0) {
        return res.status(400).json({ status: 'error', message: 'ID thông báo không hợp lệ' });
      }

      const context = await this.resolveUserContext(user);
      await this.notificationService.markAsRead(context, id);
      return res.status(200).json({ status: 'success', message: 'Đã đánh dấu đã đọc' });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  };

  /**
   * Mark all notifications as read
   */
  markAllAsRead = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const user = req.user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const context = await this.resolveUserContext(user);
      await this.notificationService.markAllAsRead(context);
      return res.status(200).json({ status: 'success', message: 'Đã đánh dấu đã đọc tất cả' });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  };

  /**
   * Update notification & language preferences
   */
  updateSettings = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const user = req.user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const { systemNotif, updateNotif, language } = req.body;
      const updated = await this.notificationService.updateNotificationSettings(Number(user.sub), {
        systemNotif,
        updateNotif,
        language,
      });

      return res.status(200).json({
        status: 'success',
        message: 'Cập nhật cài đặt thông báo thành công',
        data: updated,
      });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  };

  /**
   * Public endpoint to check latest app version & force update requirement
   */
  checkAppVersion = async (req: Request, res: Response) => {
    try {
      const platform = (req.query.platform as string) || 'android';
      const config = await this.notificationService.getAppVersionConfig(platform);
      return res.status(200).json({
        status: 'success',
        data: config,
      });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message });
    }
  };
}
