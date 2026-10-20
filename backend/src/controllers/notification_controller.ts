import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth_middleware';
import { NotificationService } from '../services/notification_service';
import { AppDataSource } from '../config/database';
import { CuaHangModel } from '../models/cua_hang_model';
import { KhachHangModel } from '../models/khach_hang_model';

export class NotificationController {
  private notificationService = NotificationService.getInstance();
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);

  private async resolveRecipient(user: any): Promise<{ recipientId: number; recipientRole: 'user' | 'restaurant' | 'admin' }> {
    const userSub = Number(user.sub);
    const role = String(user.role || '').toUpperCase();

    if (role === 'ADMIN') {
      return { recipientId: userSub, recipientRole: 'admin' };
    }

    if (role === 'CUAN_HANG' || role === 'CUA_HANG') {
      const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userSub } });
      if (store) {
        return { recipientId: store.maQuan, recipientRole: 'restaurant' };
      }
      return { recipientId: userSub, recipientRole: 'user' };
    }

    // Default Customer / User
    const kh = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
    const customerId = kh ? kh.maKhachHang : userSub;
    return { recipientId: customerId, recipientRole: 'user' };
  }

  getNotifications = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const user = req.user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const { recipientId, recipientRole } = await this.resolveRecipient(user);
      const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 20;
      const unreadOnly = req.query.unreadOnly === 'true';

      const result = await this.notificationService.getNotifications(recipientId, recipientRole, {
        page,
        limit,
        unreadOnly,
      });

      return res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi lấy danh sách thông báo',
      });
    }
  };

  getUnreadCount = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const user = req.user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const { recipientId, recipientRole } = await this.resolveRecipient(user);
      const count = await this.notificationService.getUnreadCount(recipientId, recipientRole);

      return res.status(200).json({
        status: 'success',
        data: { unreadCount: count },
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi đếm thông báo chưa đọc',
      });
    }
  };

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

      const { recipientId, recipientRole } = await this.resolveRecipient(user);
      const updated = await this.notificationService.markAsRead(id, recipientId, recipientRole);

      return res.status(200).json({
        status: 'success',
        message: 'Đã đánh dấu thông báo là đã đọc',
        data: updated,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Lỗi khi cập nhật trạng thái thông báo',
      });
    }
  };

  markAllAsRead = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const user = req.user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const { recipientId, recipientRole } = await this.resolveRecipient(user);
      const updatedCount = await this.notificationService.markAllAsRead(recipientId, recipientRole);

      return res.status(200).json({
        status: 'success',
        message: 'Đã đánh dấu tất cả thông báo là đã đọc',
        data: { updatedCount },
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi đánh dấu đã đọc tất cả thông báo',
      });
    }
  };
}
