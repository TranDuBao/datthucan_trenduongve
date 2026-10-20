import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddReviewIndexes1710000000002 implements MigrationInterface {
  name = 'AddReviewIndexes1710000000002';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_danhgia_maquan_ngaynhanxet ON danhgia(maquan, ngaynhanxet DESC);
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_danhgia_makhachhang ON danhgia(makhachhang);
    `);
    await queryRunner.query(`
      CREATE INDEX IF NOT EXISTS idx_danhgia_mon_mamon ON danhgia_mon(mamon);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_danhgia_mon_mamon;
    `);
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_danhgia_makhachhang;
    `);
    await queryRunner.query(`
      DROP INDEX IF EXISTS idx_danhgia_maquan_ngaynhanxet;
    `);
  }
}
