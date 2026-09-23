import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'nhanvien' })
export class NhanVienModel {
  @PrimaryGeneratedColumn({ name: 'manhanvien' })
  maNhanVien: number;

  @Column({ name: 'mataikhoan', nullable: true })
  maTaiKhoan?: number;

  @Column({ name: 'maquan', nullable: true })
  maQuan?: number;

  @Column({ name: 'hoten', length: 100 })
  hoTen: string;

  @Column({ name: 'sdt', nullable: true, length: 15 })
  sdt?: string;
}
