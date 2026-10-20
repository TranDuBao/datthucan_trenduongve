import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddUniqueConstraintToDanhGiaMaDonHang1710000000000 implements MigrationInterface {
  name = 'AddUniqueConstraintToDanhGiaMaDonHang1710000000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE danhgia ADD CONSTRAINT uq_danhgia_madonhang UNIQUE (madonhang);
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE danhgia DROP CONSTRAINT IF EXISTS uq_danhgia_madonhang;
    `);
  }
}
