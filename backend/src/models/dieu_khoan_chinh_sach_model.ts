import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { TaiKhoanModel } from './tai_khoan_model';

export enum LoaiTaiLieuPhapLy {
  DIEU_KHOAN_DOI_TAC = 'DIEU_KHOAN_DOI_TAC',
  CHINH_SACH_DU_LIEU = 'CHINH_SACH_DU_LIEU',
}

export enum TrangThaiPhienBan {
  NHAP = 'NHAP',
  DANG_HIEU_LUC = 'DANG_HIEU_LUC',
  DA_LUU_TRU = 'DA_LUU_TRU',
}

@Entity({ name: 'dieu_khoan_chinh_sach' })
export class DieuKhoanChinhSachModel {
  @PrimaryGeneratedColumn({ name: 'maphienban' })
  maPhienBan: number;

  @Column({ name: 'loaitailieu', length: 50 })
  loaiTaiLieu: string; // LoaiTaiLieuPhapLy

  @Column({ name: 'sophienban', length: 20 })
  soPhienBan: string; // e.g. '1.0', '1.1'

  @Column({ name: 'tieude', length: 255 })
  tieuDe: string;

  @Column({ name: 'noidung', type: 'text' })
  noiDung: string;

  @Column({ name: 'trangthai', length: 30, default: TrangThaiPhienBan.NHAP })
  trangThai: string; // TrangThaiPhienBan

  @Column({ name: 'ngayhieuluc', type: 'timestamp', nullable: true })
  ngayHieuLuc?: Date | null;

  @Column({ name: 'mataikhoantao', nullable: true })
  maTaiKhoanTao?: number | null;

  @ManyToOne(() => TaiKhoanModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'mataikhoantao' })
  nguoiTao?: TaiKhoanModel;

  @CreateDateColumn({ name: 'ngaytao', type: 'timestamp' })
  ngayTao: Date;

  @Column({ name: 'mataikhoancapnhat', nullable: true })
  maTaiKhoanCapNhat?: number | null;

  @UpdateDateColumn({ name: 'ngaycapnhat', type: 'timestamp' })
  ngayCapNhat: Date;
}

