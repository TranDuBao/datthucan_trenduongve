import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany } from 'typeorm';
import { SupportFaqModel } from './support_faq_model';

@Entity({ name: 'ho_tro_faq_nhom' })
export class SupportFaqGroupModel {
  @PrimaryGeneratedColumn({ name: 'ma_nhom' })
  maNhom: number;

  @Column({ name: 'ten_nhom', length: 150 })
  tenNhom: string;

  @Column({ name: 'thu_tu', type: 'int', default: 1 })
  thuTu: number;

  @Column({ name: 'kich_hoat', type: 'boolean', default: true })
  kichHoat: boolean;

  @CreateDateColumn({ name: 'ngay_tao' })
  ngayTao: Date;

  @OneToMany(() => SupportFaqModel, (faq) => faq.nhom)
  cauHoi?: SupportFaqModel[];
}

