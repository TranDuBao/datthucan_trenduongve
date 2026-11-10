import { In, LessThan } from 'typeorm';
import { AppDataSource } from '../config/database';
import { NotificationModel, NotificationStatus, NotificationTarget, NotificationType } from '../models/notification_model';
import { UserNotificationModel } from '../models/user_notification_model';
import { DeviceTokenModel } from '../models/device_token_model';
import { TaiKhoanModel } from '../models/tai_khoan_model';
import { AppVersionModel } from '../models/app_version_model';
import { RealtimeService } from './realtime_service';
import { FcmService } from './fcm_service';

export interface SendNotificationOptions {
  recipientId: number; // 0 for broadcast, or specific user ID
  recipientRole?: 'user' | 'restaurant' | 'admin';
  type: string; // 'order_ready' | 'order_cancelled' | 'refund' | 'system' | 'update'
  title: string;
  body: string;
  titleEn?: string;
  bodyEn?: string;
  data?: Record<string, any>;
  target?: string; // 'ALL' | 'ROLE' | 'USER' | 'VERSION_LT'
  targetValue?: string;
  createdBy?: number;
  idempotencyKey?: string; // e.g. "order_ready:123" to prevent duplicate sends
}

export interface GetNotificationsOptions {
  page?: number;
  limit?: number;
  unreadOnly?: boolean;
}

export interface UserNotificationContext {
  userId: number;
  role: string;
  storeId?: number;
  customerId?: number;
}

export class NotificationService {
  private static instance: NotificationService;
  private notificationRepo = AppDataSource.getRepository(NotificationModel);
  private userNotificationRepo = AppDataSource.getRepository(UserNotificationModel);
  private deviceTokenRepo = AppDataSource.getRepository(DeviceTokenModel);
  private taiKhoanRepo = AppDataSource.getRepository(TaiKhoanModel);
  private appVersionRepo = AppDataSource.getRepository(AppVersionModel);

  public static getInstance(): NotificationService {
    if (!NotificationService.instance) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  /**
   * 1. Core Unified Dispatcher:
   * Writes to Database (Notifications & UserNotifications inbox),
   * Emits via Socket.io, and pushes via FCM to background devices.
   */
  async sendNotification(options: SendNotificationOptions): Promise<NotificationModel | null> {
    const {
      recipientId,
      recipientRole = 'user',
      type,
      title,
      body,
      titleEn,
      bodyEn,
      data = {},
      target = NotificationTarget.USER,
      targetValue,
      createdBy,
      idempotencyKey,
    } = options;

    // Check Idempotency for order/refund events to prevent duplicate push
    if (idempotencyKey && data.orderId) {
      const existing = await this.notificationRepo.findOne({
        where: {
          recipientId,
          type,
          data: { orderId: data.orderId },
        } as any,
      });
      if (existing) {
        return existing;
      }
    }

    // A. Persist Master Notification
    const master = this.notificationRepo.create({
      recipientId,
      recipientRole,
      type,
      title,
      body,
      titleEn: titleEn || null,
      bodyEn: bodyEn || null,
      data: data || null,
      target,
      targetValue: targetValue || null,
      status: NotificationStatus.SENT,
      sentAt: new Date(),
      createdBy: createdBy || null,
      isRead: false,
    });
    const savedMaster = await this.notificationRepo.save(master);

    // B. Handle In-App Inbox & Push based on Target
    if (target === NotificationTarget.USER && recipientId > 0) {
      await this.deliverToUser(recipientId, savedMaster);
    } else if (target === NotificationTarget.ALL || target === NotificationTarget.ROLE || target === NotificationTarget.VERSION_LT) {
      await this.deliverBroadcast(savedMaster);
    }

    return savedMaster;
  }

  /**
   * Deliver to a single specific user (Order Ready, Cancelled, Refund, Direct)
   */
  private async deliverToUser(userId: number, notification: NotificationModel) {
    // 1. Write to user's personal inbox (with conflict protection)
    try {
      await this.userNotificationRepo.query(
        `INSERT INTO user_notifications (user_id, notification_id, is_read, created_at)
         VALUES ($1, $2, false, CURRENT_TIMESTAMP)
         ON CONFLICT (user_id, notification_id) DO NOTHING;`,
        [userId, notification.id]
      );
    } catch (e: any) {
      console.warn('[NotificationService] Inbox insertion note:', e.message);
    }

    // 2. Realtime Socket.io emission
    try {
      RealtimeService.getInstance().emitNotification(
        notification.recipientRole,
        userId,
        notification
      );
    } catch (e) {
      console.warn('[NotificationService] Socket emission fallback:', e);
    }

    // 3. Fetch device tokens & Push via FCM
    try {
      const tokens = await this.deviceTokenRepo.find({ where: { userId } });
      if (tokens.length > 0) {
        await this.dispatchTokensFcm(tokens, notification);
      }
    } catch (err: any) {
      console.error('[NotificationService] FCM deliverToUser error:', err.message);
    }
  }

  /**
   * Deliver broadcast notification (System announcements, Version updates)
   */
  private async deliverBroadcast(notification: NotificationModel) {
    // 1. Deliver to In-App Inbox for targeted users
    try {
      if (notification.target === NotificationTarget.ROLE) {
        const role = notification.targetValue || 'KHACH_HANG';
        await this.userNotificationRepo.query(
          `INSERT INTO user_notifications (user_id, notification_id, is_read, created_at)
           SELECT mataikhoan, $1, false, CURRENT_TIMESTAMP
           FROM taikhoan
           WHERE loaitaikhoan = $2
           ON CONFLICT (user_id, notification_id) DO NOTHING;`,
          [notification.id, role]
        );
      } else {
        await this.userNotificationRepo.query(
          `INSERT INTO user_notifications (user_id, notification_id, is_read, created_at)
           SELECT mataikhoan, $1, false, CURRENT_TIMESTAMP
           FROM taikhoan
           ON CONFLICT (user_id, notification_id) DO NOTHING;`,
          [notification.id]
        );
      }
    } catch (e: any) {
      console.warn('[NotificationService] Broadcast inbox insert note:', e.message);
    }

    let targetTokens: DeviceTokenModel[] = [];

    if (notification.target === NotificationTarget.ROLE) {
      const role = notification.targetValue || 'KHACH_HANG';
      const users = await this.taiKhoanRepo.find({ where: { loaiTaiKhoan: role }, select: ['maTaiKhoan'] });
      const userIds = users.map((u) => u.maTaiKhoan);
      if (userIds.length > 0) {
        targetTokens = await this.deviceTokenRepo.find({ where: { userId: In(userIds) } });
      }
    } else if (notification.target === NotificationTarget.VERSION_LT && notification.targetValue) {
      // Find devices with app version lower than targetValue
      targetTokens = await this.deviceTokenRepo.find({
        where: { appVersion: LessThan(notification.targetValue) },
      });
    } else {
      // Target ALL devices
      targetTokens = await this.deviceTokenRepo.find();
    }

    // Broadcast Realtime via Socket.io
    try {
      RealtimeService.getInstance().getIO()?.emit('notification:broadcast', {
        id: notification.id,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        data: notification.data,
      });
    } catch (e) {
      console.warn('[NotificationService] Broadcast socket error:', e);
    }

    // Push to FCM tokens grouped by language
    if (targetTokens.length > 0) {
      await this.dispatchTokensFcm(targetTokens, notification);
    }
  }

  /**
   * Group tokens by language, deliver via FCM, and clean dead tokens.
   */
  private async dispatchTokensFcm(tokens: DeviceTokenModel[], notification: NotificationModel) {
    const fcm = FcmService.getInstance();
    const deadTokens: string[] = [];

    // Group by language
    const viTokens = tokens.filter((t) => t.language !== 'en').map((t) => t.token);
    const enTokens = tokens.filter((t) => t.language === 'en').map((t) => t.token);

    // Channel ID mapping: high importance for orders, default for system
    const channelId = notification.type.startsWith('order') ? 'food_route_orders' : 'food_route_system';

    // Send Vietnamese payload
    if (viTokens.length > 0) {
      const resVi = await fcm.sendMulticastPush({
        tokens: viTokens,
        title: notification.title,
        body: notification.body,
        channelId,
        data: {
          notificationId: String(notification.id),
          type: notification.type,
          ...(notification.data || {}),
        },
      });
      notification.sentCount += resVi.successCount;
      notification.failedCount += resVi.failureCount;
      deadTokens.push(...resVi.deadTokens);
    }

    // Send English payload
    if (enTokens.length > 0) {
      const titleEn = notification.titleEn || notification.title;
      const bodyEn = notification.bodyEn || notification.body;
      const resEn = await fcm.sendMulticastPush({
        tokens: enTokens,
        title: titleEn,
        body: bodyEn,
        channelId,
        data: {
          notificationId: String(notification.id),
          type: notification.type,
          ...(notification.data || {}),
        },
      });
      notification.sentCount += resEn.successCount;
      notification.failedCount += resEn.failureCount;
      deadTokens.push(...resEn.deadTokens);
    }

    // Update master counters
    await this.notificationRepo.update(notification.id, {
      sentCount: notification.sentCount,
      failedCount: notification.failedCount,
    });

    // Clean up dead tokens from database
    if (deadTokens.length > 0) {
      await this.deviceTokenRepo.delete({ token: In(deadTokens) });
    }
  }

  // -------------------------------------------------------------
  // 2. Device Token & User Preferences API
  // -------------------------------------------------------------

  async registerDeviceToken(params: {
    userId: number;
    token: string;
    platform: string;
    language?: string;
    appVersion?: string;
  }) {
    const { userId, token, platform, language = 'vi', appVersion } = params;

    let deviceToken = await this.deviceTokenRepo.findOne({ where: { token } });
    if (deviceToken) {
      deviceToken.userId = userId;
      deviceToken.platform = platform;
      deviceToken.language = language;
      if (appVersion) deviceToken.appVersion = appVersion;
      deviceToken.lastSeenAt = new Date();
    } else {
      deviceToken = this.deviceTokenRepo.create({
        userId,
        token,
        platform,
        language,
        appVersion: appVersion || null,
        lastSeenAt: new Date(),
      });
    }

    await this.deviceTokenRepo.save(deviceToken);

    // Sync preferred language to taikhoan
    await this.taiKhoanRepo.update(userId, { preferredLanguage: language }).catch(() => {});

    return deviceToken;
  }

  async unregisterDeviceToken(token: string) {
    if (!token) return;
    await this.deviceTokenRepo.delete({ token });
  }

  async updateNotificationSettings(
    userId: number,
    settings: { systemNotif?: boolean; updateNotif?: boolean; language?: string }
  ) {
    const updatePayload: Partial<TaiKhoanModel> = {};
    if (settings.systemNotif !== undefined) updatePayload.settingsSystemNotif = settings.systemNotif;
    if (settings.updateNotif !== undefined) updatePayload.settingsUpdateNotif = settings.updateNotif;
    if (settings.language !== undefined) {
      updatePayload.preferredLanguage = settings.language;
      await this.deviceTokenRepo.update({ userId }, { language: settings.language });
    }

    await this.taiKhoanRepo.update(userId, updatePayload);
    return await this.taiKhoanRepo.findOne({
      where: { maTaiKhoan: userId },
      select: ['maTaiKhoan', 'preferredLanguage', 'settingsSystemNotif', 'settingsUpdateNotif'],
    });
  }

  // -------------------------------------------------------------
  // 3. Inbox Management API (Paginated, Mark Read)
  // -------------------------------------------------------------

  async getUserInbox(context: UserNotificationContext, options: GetNotificationsOptions = {}) {
    const { userId, role, storeId, customerId } = context;
    const page = Math.max(1, Number(options.page) || 1);
    const limit = Math.max(1, Math.min(50, Number(options.limit) || 20));
    const skip = (page - 1) * limit;

    const roleUpper = (role || '').toUpperCase();

    let whereClause = '';
    const params: any[] = [userId];

    if (roleUpper === 'ADMIN') {
      whereClause = `(
        (n.recipient_role = 'admin' AND (n.recipient_id = $1 OR n.recipient_id = 0))
        OR n.target = 'ALL'
        OR (n.target = 'ROLE' AND n.target_value = 'ADMIN')
        OR un.user_id = $1
      )`;
    } else if (roleUpper === 'CUAN_HANG' || roleUpper === 'CUA_HANG' || roleUpper === 'RESTAURANT' || roleUpper === 'STORE') {
      params.push(storeId || 0);
      whereClause = `(
        (n.recipient_role = 'restaurant' AND (n.recipient_id = $2 OR n.recipient_id = $1))
        OR (n.recipient_role = 'user' AND n.recipient_id = $1)
        OR n.target = 'ALL'
        OR (n.target = 'ROLE' AND (n.target_value = 'CUAN_HANG' OR n.target_value = 'RESTAURANT' OR n.target_value = 'STORE'))
        OR un.user_id = $1
      )`;
    } else {
      params.push(customerId || 0);
      whereClause = `(
        (n.recipient_role = 'user' AND (n.recipient_id = $1 OR n.recipient_id = $2))
        OR n.target = 'ALL'
        OR (n.target = 'ROLE' AND (n.target_value = 'USER' OR n.target_value = 'KHACH_HANG'))
        OR un.user_id = $1
      )`;
    }

    if (options.unreadOnly) {
      whereClause += ` AND COALESCE(un.is_read, n.is_read, false) = false`;
    }

    const countSql = `
      SELECT COUNT(*)::int AS total,
             COUNT(CASE WHEN COALESCE(un.is_read, n.is_read, false) = false THEN 1 END)::int AS unread_count
      FROM notifications n
      LEFT JOIN user_notifications un ON un.notification_id = n.id AND un.user_id = $1
      WHERE ${whereClause}
    `;

    const countResult = await this.notificationRepo.query(countSql, params);
    const total = Number(countResult[0]?.total || 0);
    const unreadCount = Number(countResult[0]?.unread_count || 0);

    const itemsSql = `
      SELECT 
        n.id,
        n.recipient_id AS "recipientId",
        n.recipient_role AS "recipientRole",
        n.type,
        n.title,
        n.body,
        n.title_en AS "titleEn",
        n.body_en AS "bodyEn",
        n.data,
        COALESCE(un.is_read, n.is_read, false) AS "isRead",
        COALESCE(un.read_at, n.read_at) AS "readAt",
        COALESCE(un.created_at, n.created_at) AS "createdAt"
      FROM notifications n
      LEFT JOIN user_notifications un ON un.notification_id = n.id AND un.user_id = $1
      WHERE ${whereClause}
      ORDER BY COALESCE(un.created_at, n.created_at) DESC
      LIMIT ${limit} OFFSET ${skip}
    `;

    const rawItems = await this.notificationRepo.query(itemsSql, params);

    const items = rawItems.map((r: any) => ({
      id: Number(r.id),
      recipientId: Number(r.recipientId || 0),
      recipientRole: r.recipientRole || 'user',
      type: r.type || 'system',
      title: r.title || 'Thông báo',
      body: r.body || '',
      titleEn: r.titleEn || null,
      bodyEn: r.bodyEn || null,
      data: r.data || null,
      isRead: Boolean(r.isRead),
      readAt: r.readAt || null,
      createdAt: r.createdAt ? new Date(r.createdAt).toISOString() : new Date().toISOString(),
    }));

    return {
      items,
      notifications: items,
      total,
      unreadCount,
      totalPages: Math.ceil(total / limit) || 1,
      page,
      limit,
    };
  }

  async markAsRead(context: UserNotificationContext, notificationId: number) {
    const { userId } = context;
    try {
      await this.userNotificationRepo.query(
        `INSERT INTO user_notifications (user_id, notification_id, is_read, read_at)
         VALUES ($1, $2, true, CURRENT_TIMESTAMP)
         ON CONFLICT (user_id, notification_id)
         DO UPDATE SET is_read = true, read_at = CURRENT_TIMESTAMP;`,
        [userId, notificationId]
      );
    } catch (_) {}

    await this.notificationRepo.update({ id: notificationId }, { isRead: true, readAt: new Date() }).catch(() => {});
    await this.notificationRepo.increment({ id: notificationId }, 'readCount', 1).catch(() => {});
    return { success: true };
  }

  async markAllAsRead(context: UserNotificationContext) {
    const { userId, role, storeId, customerId } = context;
    const roleUpper = (role || '').toUpperCase();

    let whereClause = '';
    const params: any[] = [userId];

    if (roleUpper === 'ADMIN') {
      whereClause = `(
        (n.recipient_role = 'admin' AND (n.recipient_id = $1 OR n.recipient_id = 0))
        OR n.target = 'ALL'
        OR (n.target = 'ROLE' AND n.target_value = 'ADMIN')
        OR un.user_id = $1
      )`;
    } else if (roleUpper === 'CUAN_HANG' || roleUpper === 'CUA_HANG' || roleUpper === 'RESTAURANT' || roleUpper === 'STORE') {
      params.push(storeId || 0);
      whereClause = `(
        (n.recipient_role = 'restaurant' AND (n.recipient_id = $2 OR n.recipient_id = $1))
        OR (n.recipient_role = 'user' AND n.recipient_id = $1)
        OR n.target = 'ALL'
        OR (n.target = 'ROLE' AND (n.target_value = 'CUAN_HANG' OR n.target_value = 'RESTAURANT' OR n.target_value = 'STORE'))
        OR un.user_id = $1
      )`;
    } else {
      params.push(customerId || 0);
      whereClause = `(
        (n.recipient_role = 'user' AND (n.recipient_id = $1 OR n.recipient_id = $2))
        OR n.target = 'ALL'
        OR (n.target = 'ROLE' AND (n.target_value = 'USER' OR n.target_value = 'KHACH_HANG'))
        OR un.user_id = $1
      )`;
    }

    try {
      await this.userNotificationRepo.query(
        `INSERT INTO user_notifications (user_id, notification_id, is_read, read_at)
         SELECT $1, n.id, true, CURRENT_TIMESTAMP
         FROM notifications n
         LEFT JOIN user_notifications un ON un.notification_id = n.id AND un.user_id = $1
         WHERE ${whereClause} AND COALESCE(un.is_read, n.is_read, false) = false
         ON CONFLICT (user_id, notification_id)
         DO UPDATE SET is_read = true, read_at = CURRENT_TIMESTAMP;`,
        params
      );

      if (roleUpper === 'ADMIN') {
        await this.notificationRepo.query(
          `UPDATE notifications SET is_read = true, read_at = CURRENT_TIMESTAMP 
           WHERE (recipient_role = 'admin' AND (recipient_id = $1 OR recipient_id = 0));`,
          [userId]
        );
      } else if (roleUpper === 'CUAN_HANG' || roleUpper === 'CUA_HANG' || roleUpper === 'RESTAURANT' || roleUpper === 'STORE') {
        if (storeId) {
          await this.notificationRepo.query(
            `UPDATE notifications SET is_read = true, read_at = CURRENT_TIMESTAMP 
             WHERE (recipient_role = 'restaurant' AND recipient_id = $1);`,
            [storeId]
          );
        }
      }
    } catch (_) {}

    return { success: true };
  }

  async getUnreadCount(context: UserNotificationContext): Promise<number> {
    const { userId, role, storeId, customerId } = context;
    const roleUpper = (role || '').toUpperCase();

    let whereClause = '';
    const params: any[] = [userId];

    if (roleUpper === 'ADMIN') {
      whereClause = `(
        (n.recipient_role = 'admin' AND (n.recipient_id = $1 OR n.recipient_id = 0))
        OR n.target = 'ALL'
        OR (n.target = 'ROLE' AND n.target_value = 'ADMIN')
        OR un.user_id = $1
      )`;
    } else if (roleUpper === 'CUAN_HANG' || roleUpper === 'CUA_HANG' || roleUpper === 'RESTAURANT' || roleUpper === 'STORE') {
      params.push(storeId || 0);
      whereClause = `(
        (n.recipient_role = 'restaurant' AND (n.recipient_id = $2 OR n.recipient_id = $1))
        OR (n.recipient_role = 'user' AND n.recipient_id = $1)
        OR n.target = 'ALL'
        OR (n.target = 'ROLE' AND (n.target_value = 'CUAN_HANG' OR n.target_value = 'RESTAURANT' OR n.target_value = 'STORE'))
        OR un.user_id = $1
      )`;
    } else {
      params.push(customerId || 0);
      whereClause = `(
        (n.recipient_role = 'user' AND (n.recipient_id = $1 OR n.recipient_id = $2))
        OR n.target = 'ALL'
        OR (n.target = 'ROLE' AND (n.target_value = 'USER' OR n.target_value = 'KHACH_HANG'))
        OR un.user_id = $1
      )`;
    }

    whereClause += ` AND COALESCE(un.is_read, n.is_read, false) = false`;

    const countSql = `
      SELECT COUNT(*)::int AS unread_count
      FROM notifications n
      LEFT JOIN user_notifications un ON un.notification_id = n.id AND un.user_id = $1
      WHERE ${whereClause}
    `;

    const res = await this.notificationRepo.query(countSql, params);
    return Number(res[0]?.unread_count || 0);
  }

  // -------------------------------------------------------------
  // 4. Admin Management (System & Update Announcements)
  // -------------------------------------------------------------

  async createAdminNotification(params: {
    type: 'system' | 'update' | 'alert' | 'promo' | string;
    titleVi: string;
    bodyVi: string;
    titleEn?: string;
    bodyEn?: string;
    target: 'ALL' | 'ROLE' | 'VERSION_LT';
    targetValue?: string;
    scheduledAt?: Date;
    createdBy?: number;
    sendNow?: boolean;
    data?: Record<string, any>;
  }) {
    const {
      type,
      titleVi,
      bodyVi,
      titleEn,
      bodyEn,
      target,
      targetValue,
      scheduledAt,
      createdBy,
      sendNow,
      data = {},
    } = params;

    const isScheduled = !sendNow && scheduledAt && new Date(scheduledAt) > new Date();

    const notif = this.notificationRepo.create({
      recipientId: 0,
      recipientRole: 'user',
      type: type || NotificationType.SYSTEM,
      title: titleVi,
      body: bodyVi,
      titleEn: titleEn || null,
      bodyEn: bodyEn || null,
      data,
      target,
      targetValue: targetValue || null,
      status: isScheduled ? NotificationStatus.SCHEDULED : NotificationStatus.SENT,
      scheduledAt: isScheduled ? new Date(scheduledAt!) : null,
      sentAt: isScheduled ? null : new Date(),
      createdBy: createdBy || null,
    });

    let saved: NotificationModel;
    try {
      saved = await this.notificationRepo.save(notif);
    } catch (saveErr: any) {
      console.warn('[NotificationService] Fallback save master notification:', saveErr?.message || saveErr);
      const maxRes = await this.notificationRepo.query(`SELECT COALESCE(MAX(id), 0) + 1 as next_id FROM notifications`);
      notif.id = Number(maxRes[0]?.next_id || 1);
      await this.notificationRepo.query(
        `INSERT INTO notifications (id, recipient_id, recipient_role, type, title, body, data, is_read, created_at)
         VALUES ($1, 0, 'user', $2, $3, $4, $5, false, CURRENT_TIMESTAMP)`,
        [notif.id, notif.type, notif.title, notif.body, JSON.stringify(data || {})]
      );
      saved = notif;
    }

    if (sendNow || !isScheduled) {
      try {
        await this.deliverBroadcast(saved);
      } catch (broadcastErr: any) {
        console.warn('[NotificationService] Broadcast deliver notice:', broadcastErr?.message || broadcastErr);
      }
    }

    return saved;
  }

  async sendTestNotification(adminUserId: number, targetUserId: number, notificationId: number) {
    const master = await this.notificationRepo.findOne({ where: { id: notificationId } });
    if (!master) throw new Error('Không tìm thấy thông báo');
    await this.deliverToUser(targetUserId, master);
    return { success: true, message: `Đã gửi thử thông báo tới user #${targetUserId}` };
  }

  async getAdminNotificationHistory(options: { page?: number; limit?: number; type?: string }) {
    const page = Math.max(1, Number(options.page) || 1);
    const limit = Math.max(1, Math.min(50, Number(options.limit) || 20));
    const skip = (page - 1) * limit;

    const query = this.notificationRepo
      .createQueryBuilder('n')
      .where('n.type IN (:...types)', { types: ['system', 'update'] })
      .orderBy('n.created_at', 'DESC')
      .skip(skip)
      .take(limit);

    if (options.type) {
      query.andWhere('n.type = :type', { type: options.type });
    }

    const [items, total] = await query.getManyAndCount();
    return { items, total, page, limit };
  }

  async cancelScheduledNotification(id: number) {
    const notif = await this.notificationRepo.findOne({ where: { id } });
    if (!notif) throw new Error('Không tìm thấy thông báo');
    if (notif.status !== NotificationStatus.SCHEDULED) {
      throw new Error('Chỉ có thể hủy thông báo đang trong trạng thái hẹn giờ');
    }

    notif.status = NotificationStatus.FAILED;
    await this.notificationRepo.save(notif);
    return { success: true };
  }

  // -------------------------------------------------------------
  // 5. App Version Management API
  // -------------------------------------------------------------

  async getAppVersionConfig(platform: string = 'android') {
    const config = await this.appVersionRepo.findOne({ where: { platform } });
    if (!config) {
      return {
        platform,
        latestVersion: '1.0.0',
        minRequiredVersion: '1.0.0',
        storeUrl: '',
        changelogVi: '',
        changelogEn: '',
      };
    }
    return config;
  }

  async updateAppVersionConfig(platform: string, data: Partial<AppVersionModel>) {
    let config = await this.appVersionRepo.findOne({ where: { platform } });
    if (!config) {
      config = this.appVersionRepo.create({ platform, ...data });
    } else {
      Object.assign(config, data);
    }
    return await this.appVersionRepo.save(config);
  }
}
