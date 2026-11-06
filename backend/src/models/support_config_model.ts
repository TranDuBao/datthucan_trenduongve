import { Entity, PrimaryColumn, Column, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'ho_tro_cau_hinh' })
export class SupportConfigModel {
  @PrimaryColumn({ name: 'id', default: 1 })
  id: number;

  @Column({ name: 'hotline', length: 50, default: '1900 6868' })
  hotline: string;

  @Column({ name: 'gio_lam_viec', length: 150, default: '08:00 - 22:00 hàng ngày (T2 - CN)' })
  gioLamViec: string;

  @Column({ name: 'email_ho_tro', length: 100, default: 'support@foodroute.vn' })
  emailHoTro: string;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}

