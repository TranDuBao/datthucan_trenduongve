import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

@Entity({ name: 'notifications' })
@Index('idx_notifications_recipient_read_created', ['recipientId', 'isRead', 'createdAt'])
export class NotificationModel {
  @PrimaryGeneratedColumn({ name: 'id' })
  id: number;

  @Column({ name: 'recipient_id', type: 'int' })
  recipientId: number;

  @Column({ name: 'recipient_role', length: 20 })
  recipientRole: string; // 'user' | 'restaurant' | 'admin'

  @Column({ name: 'type', length: 50 })
  type: string;

  @Column({ name: 'title', length: 255 })
  title: string;

  @Column({ name: 'body', type: 'text' })
  body: string;

  @Column({ name: 'data', type: 'jsonb', nullable: true })
  data?: Record<string, any> | null;

  @Column({ name: 'is_read', default: false })
  isRead: boolean;

  @Column({ name: 'read_at', type: 'timestamp', nullable: true })
  readAt?: Date | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;
}
