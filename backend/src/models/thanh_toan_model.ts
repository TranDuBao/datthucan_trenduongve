import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'thanhtoan' })
export class ThanhToanModel {
  @PrimaryGeneratedColumn({ name: 'mathanhtoan' })
  maThanhToan: number;

  @Column({ name: 'madonhang' })
  maDonHang: number;

  @Column({ name: 'taikhoanthanhtoan', nullable: true, length: 100 })
  taiKhoanThanhToan?: string;

  @Column({ name: 'sotien', type: 'decimal', precision: 12, scale: 2 })
  soTien: number;

  @Column({ name: 'taikhoannhan', nullable: true, length: 100 })
  taiKhoanNhan?: string;

  @CreateDateColumn({ name: 'ngaythanhtoan' })
  ngayThanhToan: Date;

  @Column({ name: 'trangthai', length: 50, default: 'THANH_TOAN_THANH_CONG' })
  trangThai: string;

  @Column({ name: 'noidung', nullable: true, type: 'text' })
  noiDung?: string;

  @Column({ name: 'loaithanhtoan', nullable: true, length: 50 })
  loaiThanhToan?: string;
}
