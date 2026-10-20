import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { BanModel } from './ban_model';
import { KhachHangModel } from './khach_hang_model';

@Entity({ name: 'datban' })
export class DatBanModel {
  @PrimaryGeneratedColumn({ name: 'madatban' })
  maDatBan: number;

  @Column({ name: 'maban' })
  maBan: number;

  @Column({ name: 'makhachhang', nullable: true })
  maKhachHang?: number;

  @Column({ name: 'maquan' })
  maQuan: number;

  @Column({ name: 'thoigianbatdau', type: 'timestamp' })
  thoiGianBatDau: Date;

  @Column({ name: 'thoigianketthuc', type: 'timestamp' })
  thoiGianKetThuc: Date;

  @Column({ name: 'songuoi', default: 2 })
  soNguoi: number;

  @Column({ name: 'trangthai', length: 30, default: 'CHO_XAC_NHAN' })
  trangThai: string; 
  // CHO_XAC_NHAN, DA_XAC_NHAN, DA_DEN, DANG_SU_DUNG, DA_HOAN_TAT, KHACH_KHONG_DEN, DA_HUY, TU_CHOI

  @Column({ name: 'ghichu', type: 'text', nullable: true })
  ghiChu?: string;

  @Column({ name: 'tenkhachhang', length: 100, nullable: true })
  tenKhachHang?: string;

  @Column({ name: 'sdtkhachhang', length: 20, nullable: true })
  sdtKhachHang?: string;

  @Column({ name: 'emailkhachhang', length: 100, nullable: true })
  emailKhachHang?: string;

  @CreateDateColumn({ name: 'createdat', type: 'timestamp' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updatedat', type: 'timestamp' })
  updatedAt: Date;

  @ManyToOne(() => BanModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'maban' })
  ban?: BanModel;

  @ManyToOne(() => KhachHangModel, { onDelete: 'SET NULL' })
  @JoinColumn({ name: 'makhachhang' })
  khachHang?: KhachHangModel;
}
