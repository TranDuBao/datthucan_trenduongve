import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'voucher' })
export class VoucherModel {
  @PrimaryGeneratedColumn({ name: 'mavoucher' })
  maVoucher: number;

  @Column({ name: 'macode', unique: true, length: 50 })
  maCode: string;

  @Column({ name: 'tenvoucher', length: 100 })
  tenVoucher: string;

  @Column({ name: 'giamgia', type: 'decimal', precision: 12, scale: 2 })
  giamGia: number;

  @Column({ name: 'loaigiam', length: 20, default: 'VND' })
  loaiGiam: string;

  @Column({ name: 'giatrigiamtoida', type: 'decimal', precision: 12, scale: 2, nullable: true })
  giaTriGiamToiDa?: number;

  @Column({ name: 'dieukiendontoithieu', type: 'decimal', precision: 12, scale: 2, default: 0 })
  dieuKienDonToiThieu: number;

  @CreateDateColumn({ name: 'ngaytao' })
  ngayTao: Date;

  @Column({ name: 'ngayhethan', type: 'timestamp', nullable: true })
  ngayHetHan?: Date;

  @Column({ name: 'soluongtoida', default: 0 })
  soLuongToiDa: number;

  @Column({ name: 'soluongdaluu', default: 0 })
  soLuongDaLuu: number;

  @Column({ name: 'trangthai', length: 30, default: 'HOAT_DONG' })
  trangThai: string;

  @Column({ name: 'maquan', nullable: true })
  maQuan?: number;
}
