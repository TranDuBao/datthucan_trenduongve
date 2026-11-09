import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateNotificationSystemTables1710000000004 implements MigrationInterface {
  name = 'CreateNotificationSystemTables1710000000004';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // 1. Device tokens table (supports FCM push notifications)
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS device_tokens (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL,
        token VARCHAR(500) NOT NULL UNIQUE,
        platform VARCHAR(20) NOT NULL DEFAULT 'android',
        language VARCHAR(10) NOT NULL DEFAULT 'vi',
        app_version VARCHAR(30) NULL,
        last_seen_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON device_tokens(user_id);
    `);

    // 2. Add bilingual and admin broadcast fields to notifications table if not exists
    await queryRunner.query(`
      ALTER TABLE notifications 
        ADD COLUMN IF NOT EXISTS title_en VARCHAR(255) NULL,
        ADD COLUMN IF NOT EXISTS body_en TEXT NULL,
        ADD COLUMN IF NOT EXISTS target VARCHAR(50) DEFAULT 'USER',
        ADD COLUMN IF NOT EXISTS target_value VARCHAR(100) NULL,
        ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'sent',
        ADD COLUMN IF NOT EXISTS scheduled_at TIMESTAMP NULL,
        ADD COLUMN IF NOT EXISTS sent_at TIMESTAMP NULL,
        ADD COLUMN IF NOT EXISTS created_by INT NULL,
        ADD COLUMN IF NOT EXISTS sent_count INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS read_count INT DEFAULT 0,
        ADD COLUMN IF NOT EXISTS failed_count INT DEFAULT 0;
    `);

    // 3. User notifications table (inbox per user)
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS user_notifications (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL,
        notification_id INT NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
        is_read BOOLEAN DEFAULT FALSE,
        read_at TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT uq_user_notification UNIQUE (user_id, notification_id)
      );
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_user_notifications_user_read 
      ON user_notifications(user_id, is_read, created_at DESC);
    `);

    // 4. App versions table (config for latest and minimum required version)
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS app_versions (
        id SERIAL PRIMARY KEY,
        platform VARCHAR(20) NOT NULL UNIQUE,
        latest_version VARCHAR(30) NOT NULL,
        min_required_version VARCHAR(30) NOT NULL,
        store_url TEXT NOT NULL,
        changelog_vi TEXT NULL,
        changelog_en TEXT NULL,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Insert baseline default versions if empty (only configuration, NOT fake business data)
    await queryRunner.query(`
      INSERT INTO app_versions (platform, latest_version, min_required_version, store_url, changelog_vi, changelog_en)
      VALUES 
        ('android', '1.0.0', '1.0.0', 'https://play.google.com/store/apps/details?id=com.foodroute.food_route', 'Phiên bản ban đầu', 'Initial release'),
        ('ios', '1.0.0', '1.0.0', 'https://apps.apple.com/app/food-route/id000000000', 'Phiên bản ban đầu', 'Initial release')
      ON CONFLICT (platform) DO NOTHING;
    `);

    // 5. Account preference columns
    await queryRunner.query(`
      ALTER TABLE taikhoan 
        ADD COLUMN IF NOT EXISTS preferred_language VARCHAR(10) DEFAULT 'vi',
        ADD COLUMN IF NOT EXISTS settings_system_notif BOOLEAN DEFAULT TRUE,
        ADD COLUMN IF NOT EXISTS settings_update_notif BOOLEAN DEFAULT TRUE;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS user_notifications;`);
    await queryRunner.query(`DROP TABLE IF EXISTS device_tokens;`);
    await queryRunner.query(`DROP TABLE IF EXISTS app_versions;`);
    await queryRunner.query(`
      ALTER TABLE notifications 
        DROP COLUMN IF EXISTS title_en,
        DROP COLUMN IF EXISTS body_en,
        DROP COLUMN IF EXISTS target,
        DROP COLUMN IF EXISTS target_value,
        DROP COLUMN IF EXISTS status,
        DROP COLUMN IF EXISTS scheduled_at,
        DROP COLUMN IF EXISTS sent_at,
        DROP COLUMN IF EXISTS created_by,
        DROP COLUMN IF EXISTS sent_count,
        DROP COLUMN IF EXISTS read_count,
        DROP COLUMN IF EXISTS failed_count;
    `);
    await queryRunner.query(`
      ALTER TABLE taikhoan 
        DROP COLUMN IF EXISTS preferred_language,
        DROP COLUMN IF EXISTS settings_system_notif,
        DROP COLUMN IF EXISTS settings_update_notif;
    `);
  }
}

