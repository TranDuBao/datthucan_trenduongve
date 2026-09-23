import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'danhmuc' })
export class DanhMucModel {
  @PrimaryGeneratedColumn({ name: 'madanhmuc' })
  maDanhMuc: number;

  @Column({ name: 'maquan', nullable: true })
  maQuan?: number;

  @Column({ name: 'tendanhmuc', length: 100 })
  tenDanhMuc: string;
}
