import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'chitietgiohang' })
export class ChiTietGioHangModel {
  @PrimaryGeneratedColumn({ name: 'machitietgio' })
  maChiTietGio: number;

  @Column({ name: 'magio' })
  maGio: number;

  @Column({ name: 'mamonan' })
  maMonAn: number;

  @Column({ name: 'soluong', default: 1 })
  soLuong: number;
}
