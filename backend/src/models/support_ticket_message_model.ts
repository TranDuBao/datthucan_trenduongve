import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { TaiKhoanModel } from './tai_khoan_model';
import { SupportTicketModel } from './support_ticket_model';

export type MessageSenderRole = 'USER' | 'ADMIN' | 'STORE';

@Entity({ name: 'ho_tro_tin_nhan' })
export class SupportTicketMessageModel {
  @PrimaryGeneratedColumn({ name: 'ma_tin_nhan' })
  maTinNhan!: number;

  @Column({ name: 'ma_phieu' })
  maPhieu!: number;

  @ManyToOne(() => SupportTicketModel, (ticket) => ticket.tinNhan, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'ma_phieu' })
  phieu?: SupportTicketModel;

  @Column({ name: 'ma_tai_khoan_gui' })
  maTaiKhoanGui!: number;

  @ManyToOne(() => TaiKhoanModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'ma_tai_khoan_gui' })
  taiKhoanGui?: TaiKhoanModel;

  @Column({ name: 'vai_tro_gui', type: 'varchar', length: 20, default: 'USER' })
  vaiTroGui!: MessageSenderRole;

  @Column({ name: 'noi_dung', type: 'text' })
  noiDung!: string;

  @Column({ name: 'danh_sach_anh', type: 'jsonb', nullable: true, default: () => "'[]'" })
  danhSachAnh?: string[];

  @Column({ name: 'da_xem', type: 'boolean', default: false })
  daXem!: boolean;

  @Column({ name: 'thoi_gian_xem', type: 'timestamp', nullable: true })
  thoiGianXem?: Date;

  @CreateDateColumn({ name: 'ngay_tao' })
  ngayTao!: Date;
}
