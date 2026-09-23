import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'chitietdonhang' })
export class ChiTietDonHangModel {
  @PrimaryGeneratedColumn({ name: 'machitietdon' })
  maChiTietDon: number;

  @Column({ name: 'madonhang' })
  maDonHang: number;

  @Column({ name: 'mamonan', nullable: true })
  maMonAn?: number;

  @Column({ name: 'tenmonan', length: 150 })
  tenMonAn: string;

  @Column({ name: 'gia', type: 'decimal', precision: 12, scale: 2 })
  gia: number;

  @Column({ name: 'soluong' })
  soLuong: number;

  @Column({ name: 'trangthaimon', length: 50, default: 'chưa làm' })
  trangThaiMon: string;
}
