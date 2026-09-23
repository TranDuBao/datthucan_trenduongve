import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'donhang' })
export class DonHangModel {
  @PrimaryGeneratedColumn({ name: 'madonhang' })
  maDonHang: number;

  @Column({ name: 'makhachhang', nullable: true })
  maKhachHang?: number;

  @Column({ name: 'maquan', nullable: true })
  maQuan?: number;

  @Column({ name: 'mavoucher', nullable: true })
  maVoucher?: number;

  @Column({ name: 'trangthai', length: 50, default: 'chờ xử lý' })
  trangThai: string;

  @Column({ name: 'tongtien', type: 'decimal', precision: 12, scale: 2 })
  tongTien: number;

  @CreateDateColumn({ name: 'thoigiandat' })
  thoiGianDat: Date;

  @Column({ name: 'thoigianhennhan', type: 'timestamp', nullable: true })
  thoiGianHenNhan?: Date;

  @Column({ name: 'loaidonhang', length: 30, default: 'PRE_ORDER' })
  loaiDonHang: string;

  @Column({ name: 'phuongthucthanhtoan', length: 50, default: 'COD' })
  phuongThucThanhToan: string;
}
