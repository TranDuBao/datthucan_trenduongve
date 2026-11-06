import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
} from 'typeorm';
import { TaiKhoanModel } from './tai_khoan_model';
import { DonHangModel } from './don_hang_model';
import { SupportTicketMessageModel } from './support_ticket_message_model';

export type TicketStatus = 'MOI' | 'DANG_XU_LY' | 'DA_GIAI_QUYET' | 'DA_DONG';

@Entity({ name: 'ho_tro_phieu' })
export class SupportTicketModel {
  @PrimaryGeneratedColumn({ name: 'ma_phieu' })
  maPhieu!: number;

  @Column({ name: 'ma_tai_khoan' })
  maTaiKhoan!: number;

  @ManyToOne(() => TaiKhoanModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'ma_tai_khoan' })
  taiKhoan?: TaiKhoanModel;

  @Column({ name: 'tieu_de', type: 'varchar', length: 255, nullable: true })
  tieuDe?: string;

  @Column({ name: 'loai_su_co', type: 'varchar', length: 50 })
  loaiSuCo!: string;

  @Column({ name: 'mo_ta', type: 'text' })
  moTa!: string;

  @Column({ name: 'ma_don_hang', nullable: true })
  maDonHang?: number;

  @ManyToOne(() => DonHangModel, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'ma_don_hang' })
  donHang?: DonHangModel;

  @Column({ name: 'danh_sach_anh', type: 'jsonb', nullable: true, default: () => "'[]'" })
  danhSachAnh?: string[];

  @Column({ name: 'trang_thai', type: 'varchar', length: 30, default: 'MOI' })
  trangThai!: TicketStatus;

  @Column({ name: 'so_tin_chua_doc_admin', type: 'int', default: 0 })
  soTinChuaDocAdmin!: number;

  @Column({ name: 'so_tin_chua_doc_user', type: 'int', default: 0 })
  soTinChuaDocUser!: number;

  @Column({ name: 'tin_nhan_cuoi', type: 'text', nullable: true })
  tinNhanCuoi?: string;

  @Column({ name: 'thoi_gian_tin_cuoi', type: 'timestamp', nullable: true })
  thoiGianTinCuoi?: Date;

  @OneToMany(() => SupportTicketMessageModel, (msg) => msg.phieu)
  tinNhan?: SupportTicketMessageModel[];

  @CreateDateColumn({ name: 'ngay_tao' })
  ngayTao!: Date;

  @UpdateDateColumn({ name: 'ngay_cap_nhat' })
  ngayCapNhat!: Date;
}
