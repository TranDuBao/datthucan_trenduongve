import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToOne,
} from 'typeorm';
import { KhachHangModel } from './khach_hang_model';

export enum LoaiTaiKhoan {
  KHACH_HANG = 'KHACH_HANG',
  CUAN_HANG = 'CUAN_HANG',
  NHAN_VIEN = 'NHAN_VIEN',
  ADMIN = 'ADMIN',
}

@Entity({ name: 'taikhoan' })
export class TaiKhoanModel {
  @PrimaryGeneratedColumn({ name: 'mataikhoan' })
  maTaiKhoan: number;

  @Column({ name: 'tendangnhap', unique: true, length: 50 })
  tenDangNhap: string;

  @Column({ name: 'matkhau', length: 255 })
  matKhau: string;

  @Column({ name: 'loaitaikhoan', length: 30, default: LoaiTaiKhoan.KHACH_HANG })
  loaiTaiKhoan: string;

  @Column({ name: 'trangthai', length: 30, default: 'HOAT_DONG' })
  trangThai: string;

  @Column({ name: 'khoadenngay', type: 'timestamp', nullable: true })
  khoaDenNgay?: Date | null;

  @Column({ name: 'lydokhoa', type: 'text', nullable: true })
  lyDoKhoa?: string | null;

  @CreateDateColumn({ name: 'ngaytao' })
  ngayTao: Date;

  @OneToOne(() => KhachHangModel, (khachHang) => khachHang.taiKhoan)
  khachHang?: KhachHangModel;
}
