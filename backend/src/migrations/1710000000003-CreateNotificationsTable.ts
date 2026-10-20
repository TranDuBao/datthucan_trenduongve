import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateNotificationsTable1710000000003 implements MigrationInterface {
  name = 'CreateNotificationsTable1710000000003';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        recipient_id INT NOT NULL,
        recipient_role VARCHAR(20) NOT NULL,
        type VARCHAR(50) NOT NULL,
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        data JSONB NULL,
        is_read BOOLEAN DEFAULT FALSE,
        read_at TIMESTAMP NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_recipient_read_created 
      ON notifications(recipient_id, is_read, created_at DESC);
    `);

    await queryRunner.query(`
      ALTER TABLE donhang ADD COLUMN IF NOT EXISTS lydohuy TEXT NULL;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_notifications_recipient_read_created;
    `);
    await queryRunner.query(`
      DROP TABLE IF EXISTS notifications;
    `);
    await queryRunner.query(`
      ALTER TABLE donhang DROP COLUMN IF EXISTS lydohuy;
    `);
  }
}
