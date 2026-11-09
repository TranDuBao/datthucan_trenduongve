import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  UpdateDateColumn,
} from 'typeorm';

@Entity({ name: 'app_versions' })
export class AppVersionModel {
  @PrimaryGeneratedColumn({ name: 'id' })
  id: number;

  @Column({ name: 'platform', length: 20, unique: true })
  platform: string; // 'android' | 'ios'

  @Column({ name: 'latest_version', length: 30 })
  latestVersion: string;

  @Column({ name: 'min_required_version', length: 30 })
  minRequiredVersion: string;

  @Column({ name: 'store_url', type: 'text' })
  storeUrl: string;

  @Column({ name: 'changelog_vi', type: 'text', nullable: true })
  changelogVi?: string;

  @Column({ name: 'changelog_en', type: 'text', nullable: true })
  changelogEn?: string;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamp' })
  updatedAt: Date;
}

