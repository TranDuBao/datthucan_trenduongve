import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

export enum NotificationType {
  ORDER_READY = 'order_ready',
  ORDER_CANCELLED = 'order_cancelled',
  REFUND = 'refund',
  SYSTEM = 'system',
  UPDATE = 'update',
}

export enum NotificationStatus {
  DRAFT = 'draft',
  SCHEDULED = 'scheduled',
  SENT = 'sent',
  FAILED = 'failed',
}

export enum NotificationTarget {
  ALL = 'ALL',
  ROLE = 'ROLE',
  USER = 'USER',
  VERSION_LT = 'VERSION_LT',
}

@Entity({ name: 'notifications' })
@Index('idx_notifications_recipient_read_created', ['recipientId', 'isRead', 'createdAt'])
export class NotificationModel {
  @PrimaryGeneratedColumn({ name: 'id' })
  id: number;

  @Column({ name: 'recipient_id', type: 'int', default: 0 })
  recipientId: number; // 0 for broadcast, or specific user/store id

  @Column({ name: 'recipient_role', length: 20, default: 'user' })
  recipientRole: string; // 'user' | 'restaurant' | 'admin'

  @Column({ name: 'type', length: 50 })
  type: string; // 'order_ready' | 'order_cancelled' | 'refund' | 'system' | 'update'

  @Column({ name: 'title', length: 255 })
  title: string; // Vietnamese title (default)

  @Column({ name: 'body', type: 'text' })
  body: string; // Vietnamese body (default)

  @Column({ name: 'title_en', length: 255, nullable: true })
  titleEn?: string | null;

  @Column({ name: 'body_en', type: 'text', nullable: true })
  bodyEn?: string | null;

  @Column({ name: 'data', type: 'jsonb', nullable: true })
  data?: Record<string, any> | null;

  @Column({ name: 'target', length: 50, default: NotificationTarget.USER })
  target: string; // 'ALL' | 'ROLE' | 'USER' | 'VERSION_LT'

  @Column({ name: 'target_value', length: 100, nullable: true })
  targetValue?: string | null;

  @Column({ name: 'status', length: 20, default: NotificationStatus.SENT })
  status: string; // 'draft' | 'scheduled' | 'sent' | 'failed'

  @Column({ name: 'scheduled_at', type: 'timestamp', nullable: true })
  scheduledAt?: Date | null;

  @Column({ name: 'sent_at', type: 'timestamp', nullable: true })
  sentAt?: Date | null;

  @Column({ name: 'created_by', type: 'int', nullable: true })
  createdBy?: number | null; // Admin userId, null for automated

  @Column({ name: 'sent_count', type: 'int', default: 0 })
  sentCount: number;

  @Column({ name: 'read_count', type: 'int', default: 0 })
  readCount: number;

  @Column({ name: 'failed_count', type: 'int', default: 0 })
  failedCount: number;

  @Column({ name: 'is_read', default: false })
  isRead: boolean;

  @Column({ name: 'read_at', type: 'timestamp', nullable: true })
  readAt?: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;
}
