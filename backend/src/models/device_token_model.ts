import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

@Entity({ name: 'device_tokens' })
@Index('idx_device_tokens_user_id', ['userId'])
export class DeviceTokenModel {
  @PrimaryGeneratedColumn({ name: 'id' })
  id: number;

  @Column({ name: 'user_id', type: 'int' })
  userId: number;

  @Column({ name: 'token', length: 500, unique: true })
  token: string;

  @Column({ name: 'platform', length: 20, default: 'android' })
  platform: string; // 'android' | 'ios' | 'web'

  @Column({ name: 'language', length: 10, default: 'vi' })
  language: string; // 'vi' | 'en'

  @Column({ name: 'app_version', length: 30, nullable: true })
  appVersion?: string;

  @UpdateDateColumn({ name: 'last_seen_at', type: 'timestamp' })
  lastSeenAt: Date;

  @CreateDateColumn({ name: 'created_at', type: 'timestamp' })
  createdAt: Date;
}

