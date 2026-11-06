import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { TaiKhoanModel } from './tai_khoan_model';

@Entity({ name: 'ho_tro_gop_y' })
export class SupportFeedbackModel {
  @PrimaryGeneratedColumn({ name: 'ma_gop_y' })
  maGopY: number;

  @Column({ name: 'ma_tai_khoan', type: 'int', nullable: true })
  maTaiKhoan?: number | null;

  @ManyToOne(() => TaiKhoanModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'ma_tai_khoan' })
  taiKhoan?: TaiKhoanModel | null;

  @Column({ name: 'ho_ten', length: 150, nullable: true })
  hoTen?: string;

  @Column({ name: 'sdt', length: 20, nullable: true })
  sdt?: string;

  @Column({ name: 'loai_gop_y', length: 50, default: 'TINH_NANG' })
  loaiGopY: string; // TINH_NANG, CHAT_LUONG_MON, DICH_VU, LOI_APP, KHAC

  @Column({ name: 'noi_dung', type: 'text' })
  noiDung: string;

  @Column({ name: 'danh_gia_sao', type: 'smallint', nullable: true })
  danhGiaSao?: number | null;

  @Column({ name: 'danh_sach_anh', type: 'jsonb', nullable: true })
  danhSachAnh?: string[] | null;

  @Column({ name: 'trang_thai', length: 30, default: 'CHUA_XEM' })
  trangThai: 'CHUA_XEM' | 'DA_XEM' | 'DA_XU_LY';

  @Column({ name: 'ghi_chu_admin', type: 'text', nullable: true })
  ghiChuAdmin?: string | null;

  @CreateDateColumn({ name: 'ngay_tao' })
  ngayTao: Date;
}

