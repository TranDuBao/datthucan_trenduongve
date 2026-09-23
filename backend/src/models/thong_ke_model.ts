import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'thongke' })
export class ThongKeModel {
  @PrimaryGeneratedColumn({ name: 'mathongke' })
  maThongKe: number;

  @Column({ name: 'maquan' })
  maQuan: number;

  @Column({ name: 'ngaythongke', type: 'date', default: () => 'CURRENT_DATE' })
  ngayThongKe: Date;

  @Column({ name: 'tongdoanhthu', type: 'decimal', precision: 15, scale: 2, default: 0 })
  tongDoanhThu: number;

  @Column({ name: 'soluongdathang', default: 0 })
  soLuongDatHang: number;

  @Column({ name: 'soluongdanhgia', default: 0 })
  soLuongDanhGia: number;

  @Column({ name: 'diemdanhgiatb', type: 'numeric', precision: 3, scale: 2, default: 0.0 })
  diemDanhGiaTB: number;
}
