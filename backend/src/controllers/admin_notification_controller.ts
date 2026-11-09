import { Request, Response } from 'express';
import { NotificationService } from '../services/notification_service';
import { NotificationTarget, NotificationType } from '../models/notification_model';

export class AdminNotificationController {
  private notificationService = NotificationService.getInstance();

  /**
   * GET /api/v1/admin/notifications
   * List history of system and update notifications with statistics
   */
  getNotifications = async (req: Request, res: Response) => {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const type = req.query.type as string | undefined;

      const result = await this.notificationService.getAdminNotificationHistory({
        page,
        limit,
        type,
      });

      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error: any) {
      console.error('[AdminNotificationController] getNotifications error:', error);
      return res.status(500).json({
        success: false,
        message: 'Lỗi khi lấy danh sách thông báo quản trị',
        error: error.message,
      });
    }
  };

  /**
   * POST /api/v1/admin/notifications
   * Compose and broadcast System or Update notification
   * Rule: Admin only composes 'system' or 'update' notifications. No promotions, no order notifications.
   */
  createNotification = async (req: Request, res: Response) => {
    try {
      const adminId = (req as any).user?.maTaiKhoan;
      const {
        type,
        titleVi,
        bodyVi,
        titleEn,
        bodyEn,
        target = 'ALL',
        targetValue,
        scheduledAt,
        sendNow = true,
        data = {},
      } = req.body;

      if (!type || !['system', 'update'].includes(type)) {
        return res.status(400).json({
          success: false,
          message: 'Admin chỉ được phép tạo thông báo loại "system" (Hệ thống) hoặc "update" (Cập nhật phiên bản)',
        });
      }

      if (!titleVi || !bodyVi) {
        return res.status(400).json({
          success: false,
          message: 'Tiêu đề và nội dung tiếng Việt là bắt buộc',
        });
      }

      const notif = await this.notificationService.createAdminNotification({
        type,
        titleVi,
        bodyVi,
        titleEn,
        bodyEn,
        target: target as any,
        targetValue,
        scheduledAt: scheduledAt ? new Date(scheduledAt) : undefined,
        createdBy: adminId,
        sendNow: Boolean(sendNow),
        data,
      });

      return res.status(201).json({
        success: true,
        message: sendNow ? 'Thông báo đã được phát thành công' : 'Đã lên lịch gửi thông báo thành công',
        data: notif,
      });
    } catch (error: any) {
      console.error('[AdminNotificationController] createNotification error:', error);
      return res.status(500).json({
        success: false,
        message: 'Lỗi khi tạo thông báo',
        error: error.message,
      });
    }
  };

  /**
   * POST /api/v1/admin/notifications/:id/cancel
   * Cancel scheduled notification
   */
  cancelScheduled = async (req: Request, res: Response) => {
    try {
      const id = parseInt(req.params.id);
      if (isNaN(id)) {
        return res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      }

      await this.notificationService.cancelScheduledNotification(id);

      return res.status(200).json({
        success: true,
        message: 'Đã hủy thông báo hẹn giờ thành công',
      });
    } catch (error: any) {
      console.error('[AdminNotificationController] cancelScheduled error:', error);
      return res.status(400).json({
        success: false,
        message: error.message || 'Lỗi khi hủy thông báo',
      });
    }
  };

  /**
   * POST /api/v1/admin/notifications/:id/test
   * Send test notification to a specific user (e.g. admin test account)
   */
  sendTest = async (req: Request, res: Response) => {
    try {
      const adminId = (req as any).user?.maTaiKhoan;
      const notificationId = parseInt(req.params.id);
      const targetUserId = parseInt(req.body.targetUserId) || adminId;

      if (isNaN(notificationId)) {
        return res.status(400).json({ success: false, message: 'ID thông báo không hợp lệ' });
      }

      const result = await this.notificationService.sendTestNotification(adminId, targetUserId, notificationId);

      return res.status(200).json({
        success: true,
        message: result.message,
      });
    } catch (error: any) {
      console.error('[AdminNotificationController] sendTest error:', error);
      return res.status(400).json({
        success: false,
        message: error.message || 'Lỗi khi gửi thông báo thử nghiệm',
      });
    }
  };

  /**
   * GET /api/v1/admin/app-versions
   * Get app version settings for both Android and iOS
   */
  getAppVersions = async (req: Request, res: Response) => {
    try {
      const android = await this.notificationService.getAppVersionConfig('android');
      const ios = await this.notificationService.getAppVersionConfig('ios');

      return res.status(200).json({
        success: true,
        data: {
          android,
          ios,
        },
      });
    } catch (error: any) {
      console.error('[AdminNotificationController] getAppVersions error:', error);
      return res.status(500).json({
        success: false,
        message: 'Lỗi khi lấy thông tin phiên bản ứng dụng',
        error: error.message,
      });
    }
  };

  /**
   * PUT /api/v1/admin/app-versions/:platform
   * Update app version settings for android or ios
   * Optionally sends a version update notification to users
   */
  updateAppVersion = async (req: Request, res: Response) => {
    try {
      const platform = req.params.platform?.toLowerCase();
      if (!['android', 'ios'].includes(platform)) {
        return res.status(400).json({ success: false, message: 'Platform phải là android hoặc ios' });
      }

      const {
        latestVersion,
        minRequiredVersion,
        storeUrl,
        changelogVi,
        changelogEn,
        notifyUsers,
      } = req.body;

      const updated = await this.notificationService.updateAppVersionConfig(platform, {
        latestVersion,
        minRequiredVersion,
        storeUrl,
        changelogVi,
        changelogEn,
      });

      // If requested, broadcast update notification to users
      if (notifyUsers) {
        const adminId = (req as any).user?.maTaiKhoan;
        await this.notificationService.createAdminNotification({
          type: 'update',
          titleVi: `Cập nhật phiên bản mới ${latestVersion}`,
          bodyVi: changelogVi || `Đã có phiên bản mới ${latestVersion}. Hãy cập nhật để trải nghiệm tính năng mới nhất!`,
          titleEn: `New Version Update ${latestVersion}`,
          bodyEn: changelogEn || `A new version ${latestVersion} is available. Update now to enjoy the latest features!`,
          target: NotificationTarget.ALL,
          createdBy: adminId,
          sendNow: true,
          data: {
            platform,
            latestVersion,
            minRequiredVersion,
            storeUrl,
          },
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Cập nhật cấu hình phiên bản thành công',
        data: updated,
      });
    } catch (error: any) {
      console.error('[AdminNotificationController] updateAppVersion error:', error);
      return res.status(500).json({
        success: false,
        message: 'Lỗi khi cập nhật phiên bản ứng dụng',
        error: error.message,
      });
    }
  };
}

