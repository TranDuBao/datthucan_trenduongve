import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'giohang' })
export class GioHangModel {
  @PrimaryGeneratedColumn({ name: 'magio' })
  maGio: number;

  @Column({ name: 'makhachhang', nullable: true })
  maKhachHang?: number;
}
