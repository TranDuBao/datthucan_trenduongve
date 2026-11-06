import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { SupportFaqGroupModel } from './support_faq_group_model';

@Entity({ name: 'ho_tro_faq_cau_hoi' })
export class SupportFaqModel {
  @PrimaryGeneratedColumn({ name: 'ma_faq' })
  maFaq: number;

  @Column({ name: 'ma_nhom', type: 'int' })
  maNhom: number;

  @ManyToOne(() => SupportFaqGroupModel, (group) => group.cauHoi, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'ma_nhom' })
  nhom?: SupportFaqGroupModel;

  @Column({ name: 'cau_hoi', type: 'text' })
  cauHoi: string;

  @Column({ name: 'cau_tra_loi', type: 'text' })
  cauTraLoi: string;

  @Column({ name: 'thu_tu', type: 'int', default: 1 })
  thuTu: number;

  @Column({ name: 'kich_hoat', type: 'boolean', default: true })
  kichHoat: boolean;

  @CreateDateColumn({ name: 'ngay_tao' })
  ngayTao: Date;

  @UpdateDateColumn({ name: 'ngay_cap_nhat' })
  ngayCapNhat: Date;
}

