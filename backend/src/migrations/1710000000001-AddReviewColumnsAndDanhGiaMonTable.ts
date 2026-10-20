import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddReviewColumnsAndDanhGiaMonTable1710000000001 implements MigrationInterface {
  name = 'AddReviewColumnsAndDanhGiaMonTable1710000000001';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS maquan INT NULL;
    `);
    await queryRunner.query(`
      ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT FALSE;
    `);
    await queryRunner.query(`
      ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    `);
    await queryRunner.query(`
      ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS is_hidden BOOLEAN DEFAULT FALSE;
    `);
    await queryRunner.query(`
      ALTER TABLE danhgia ADD COLUMN IF NOT EXISTS ly_do_an TEXT NULL;
    `);

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS danhgia_mon (
        madanhgiamon SERIAL PRIMARY KEY,
        madanhgia INT REFERENCES danhgia(madanhgia) ON DELETE CASCADE,
        mamon INT REFERENCES monan(mamonan) ON DELETE CASCADE,
        soluongsao INT DEFAULT 5,
        nhanxet TEXT
      );
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP TABLE IF EXISTS danhgia_mon;
    `);
    await queryRunner.query(`
      ALTER TABLE danhgia DROP COLUMN IF EXISTS ly_do_an;
    `);
    await queryRunner.query(`
      ALTER TABLE danhgia DROP COLUMN IF EXISTS is_hidden;
    `);
    await queryRunner.query(`
      ALTER TABLE danhgia DROP COLUMN IF EXISTS updated_at;
    `);
    await queryRunner.query(`
      ALTER TABLE danhgia DROP COLUMN IF EXISTS is_edited;
    `);
    await queryRunner.query(`
      ALTER TABLE danhgia DROP COLUMN IF EXISTS maquan;
    `);
  }
}
