import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'monan' })
export class MonAnModel {
  @PrimaryGeneratedColumn({ name: 'mamonan' })
  maMonAn: number;

  @Column({ name: 'madanhmuc', nullable: true })
  maDanhMuc?: number;

  @Column({ name: 'maquan', nullable: true })
  maQuan?: number;

  @Column({ name: 'tenmonan', length: 150 })
  tenMonAn: string;

  @Column({ name: 'giamonan', type: 'decimal', precision: 12, scale: 2 })
  giaMonAn: number;

  @Column({ name: 'soluongmon', default: 0 })
  soLuongMon: number;

  @Column({ name: 'img', type: 'text', nullable: true })
  img?: string;

  @Column({ name: 'diemdanhgiatb', type: 'numeric', precision: 3, scale: 2, default: 0.0 })
  diemDanhGiaTB: number;

  @Column({ name: 'soluotdanhgia', default: 0 })
  soLuotDanhGia: number;

  @Column({ name: 'trangthaimon', length: 30, default: 'DANG_BAN', nullable: true })
  trangThaiMon?: string;
}
