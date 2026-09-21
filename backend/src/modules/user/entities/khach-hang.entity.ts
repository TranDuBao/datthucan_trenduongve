import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { TaiKhoan } from './tai-khoan.entity';

@Entity({ name: 'khachhang' })
export class KhachHang {
  @PrimaryGeneratedColumn({ name: 'makhachhang' })
  maKhachHang: number;

  @Column({ name: 'mataikhoan' })
  maTaiKhoan: number;

  @Column({ name: 'hoten', length: 100 })
  hoTen: string;

  @Column({ name: 'sdt', nullable: true, length: 15 })
  sdt?: string;

  @Column({ name: 'email', nullable: true, length: 100 })
  email?: string;

  @Column({ name: 'diachi', nullable: true, type: 'text' })
  diaChi?: string;

  @Column({ name: 'avatar', nullable: true, length: 255 })
  avatar?: string;

  @OneToOne(() => TaiKhoan, (taiKhoan) => taiKhoan.khachHang)
  @JoinColumn({ name: 'mataikhoan' })
  taiKhoan: TaiKhoan;
}
