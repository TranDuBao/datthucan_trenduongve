import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToOne,
} from 'typeorm';
import { KhachHang } from './khach-hang.entity';

export enum LoaiTaiKhoan {
  KHACH_HANG = 'KHACH_HANG',
  CUAN_HANG = 'CUAN_HANG',
  NHAN_VIEN = 'NHAN_VIEN',
  ADMIN = 'ADMIN',
}

@Entity({ name: 'taikhoan' })
export class TaiKhoan {
  @PrimaryGeneratedColumn({ name: 'mataikhoan' })
  maTaiKhoan: number;

  @Column({ name: 'tendangnhap', unique: true, length: 50 })
  tenDangNhap: string;

  @Column({ name: 'matkhau', length: 255, select: false })
  matKhau: string;

  @Column({ name: 'loaitaikhoan', length: 30, default: LoaiTaiKhoan.KHACH_HANG })
  loaiTaiKhoan: string;

  @Column({ name: 'trangthai', length: 30, default: 'HOAT_DONG' })
  trangThai: string;

  @CreateDateColumn({ name: 'ngaytao' })
  ngayTao: Date;

  @OneToOne(() => KhachHang, (khachHang) => khachHang.taiKhoan)
  khachHang?: KhachHang;
}
