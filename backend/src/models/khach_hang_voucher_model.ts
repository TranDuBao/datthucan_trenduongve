import { Entity, PrimaryColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'khachhang_voucher' })
export class KhachHangVoucherModel {
  @PrimaryColumn({ name: 'makhachhang' })
  maKhachHang: number;

  @PrimaryColumn({ name: 'mavoucher' })
  maVoucher: number;

  @CreateDateColumn({ name: 'ngayluu' })
  ngayLuu: Date;

  @Column({ name: 'dasudung', default: false })
  daSuDung: boolean;
}
