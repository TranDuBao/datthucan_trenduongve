import { AppDataSource } from '../config/database';
import { NotificationModel } from '../models/notification_model';
import { RealtimeService } from './realtime_service';

export interface SendNotificationOptions {
  recipientId: number;
  recipientRole: 'user' | 'restaurant' | 'admin';
  type: string;
  title: string;
  body: string;
  data?: Record<string, any>;
}

export interface GetNotificationsOptions {
  page?: number;
  limit?: number;
  unreadOnly?: boolean;
}

export class NotificationService {
  private static instance: NotificationService;
  private notificationRepo = AppDataSource.getRepository(NotificationModel);

  public static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  /**
   * Persist notification in PostgreSQL first, then emit via Socket.io.
   */
  async sendNotification(options: SendNotificationOptions): Promise<NotificationModel> {
    const notification = this.notificationRepo.create({
      recipientId: options.recipientId,
      recipientRole: options.recipientRole,
      type: options.type,
      title: options.title,
      body: options.body,
      data: options.data || null,
      isRead: false,
    });

    const saved = await this.notificationRepo.save(notification);

    // Emit Realtime event only after database write succeeds
    try {
      RealtimeService.getInstance().emitNotification(
        saved.recipientRole,
        saved.recipientId,
        saved
      );
    } catch (e) {
      console.error('[NotificationService] Failed to emit realtime notification:', e);
    }

    return saved;
  }

  /**
   * Get paginated notifications for recipient.
   */
  async getNotifications(
    recipientId: number,
    recipientRole: string,
    options: GetNotificationsOptions = {}
  ) {
    const page = Math.max(1, Number(options.page) || 1);
    const limit = Math.max(1, Math.min(50, Number(options.limit) || 20));
    const skip = (page - 1) * limit;

    const query = this.notificationRepo.createQueryBuilder('n');

    if (recipientRole === 'admin') {
      query.where('(n.recipient_id = :recipientId OR n.recipient_id = 0)', { recipientId })
        .andWhere('n.recipient_role = :recipientRole', { recipientRole });
    } else {
      query.where('n.recipient_id = :recipientId', { recipientId })
        .andWhere('n.recipient_role = :recipientRole', { recipientRole });
    }

    if (options.unreadOnly) {
      query.andWhere('n.is_read = false');
    }

    query.orderBy('n.created_at', 'DESC')
      .skip(skip)
      .take(limit);

    const [notifications, total] = await query.getManyAndCount();

    const unreadCount = await this.getUnreadCount(recipientId, recipientRole);

    return {
      notifications,
      total,
      unreadCount,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
    };
  }

  /**
   * Count unread notifications for a specific recipient.
   */
  async getUnreadCount(recipientId: number, recipientRole: string): Promise<number> {
    if (recipientRole === 'admin') {
      return await this.notificationRepo.count({
        where: [
          { recipientId, recipientRole, isRead: false },
          { recipientId: 0, recipientRole, isRead: false },
        ],
      });
    }

    return await this.notificationRepo.count({
      where: {
        recipientId,
        recipientRole,
        isRead: false,
      },
    });
  }

  /**
   * Mark a single notification as read if it belongs to the caller.
   */
  async markAsRead(id: number, recipientId: number, recipientRole: string): Promise<NotificationModel> {
    let notification: NotificationModel | null = null;
    if (recipientRole === 'admin') {
      notification = await this.notificationRepo
        .createQueryBuilder('n')
        .where('n.id = :id', { id })
        .andWhere('(n.recipient_id = :recipientId OR n.recipient_id = 0)', { recipientId })
        .andWhere('n.recipient_role = :recipientRole', { recipientRole })
        .getOne();
    } else {
      notification = await this.notificationRepo.findOne({
        where: {
          id,
          recipientId,
          recipientRole,
        },
      });
    }

    if (!notification) {
      throw new Error('Không tìm thấy thông báo hoặc bạn không có quyền truy cập');
    }

    if (!notification.isRead) {
      notification.isRead = true;
      notification.readAt = new Date();
      return await this.notificationRepo.save(notification);
    }

    return notification;
  }

  /**
   * Mark all unread notifications of the caller as read.
   */
  async markAllAsRead(recipientId: number, recipientRole: string): Promise<number> {
    const qb = this.notificationRepo
      .createQueryBuilder()
      .update(NotificationModel)
      .set({ isRead: true, readAt: new Date() })
      .where('recipient_role = :recipientRole', { recipientRole })
      .andWhere('is_read = false');

    if (recipientRole === 'admin') {
      qb.andWhere('(recipient_id = :recipientId OR recipient_id = 0)', { recipientId });
    } else {
      qb.andWhere('recipient_id = :recipientId', { recipientId });
    }

    const result = await qb.execute();
    return result.affected || 0;
  }
}
