import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

export enum RefundStatus {
  PENDING = 'CHO_XU_LY',
  PROCESSING = 'DANG_XU_LY',
  REFUNDED = 'HOAN_TIEN_THANH_CONG',
  FAILED = 'THAT_BAI',
  REVIEW_REQUIRED = 'CAN_DUYET_THU_CONG',
}

@Entity({ name: 'hoantien' })
export class HoanTienModel {
  @PrimaryGeneratedColumn({ name: 'mahoantien' })
  maHoanTien: number;

  @Column({ name: 'madonhang' })
  maDonHang: number;

  @Column({ name: 'mathanhtoan', nullable: true })
  maThanhToan?: number;

  @Column({ name: 'sotienhoan', type: 'decimal', precision: 12, scale: 2 })
  soTienHoan: number;

  @Column({ name: 'lydohoan', type: 'text', nullable: true })
  lyDoHoan?: string;

  @Column({ name: 'nguoiyeucau', length: 50 })
  nguoiYeuCau: string; // 'KHACH_HANG' | 'CUA_HANG' | 'ADMIN'

  @Column({ name: 'trangthaihoantien', length: 50, default: RefundStatus.PENDING })
  trangThaiHoanTien: string;

  @Column({ name: 'phuongthuchoan', length: 50, default: 'PAYOS_PAYOUT' })
  phuongThucHoan: string;

  @Column({ name: 'nganhangnhan', length: 100, nullable: true })
  nganHangNhan?: string;

  @Column({ name: 'sotaikhoannhan', length: 50, nullable: true })
  soTaiKhoanNhan?: string;

  @Column({ name: 'tenchutaikhoannhan', length: 150, nullable: true })
  tenChuTaiKhoanNhan?: string;

  @Column({ name: 'magiaodichpayos', length: 100, nullable: true })
  maGiaoDichPayOS?: string;

  @CreateDateColumn({ name: 'thoigianyeucau' })
  thoiGianYeuCau: Date;

  @Column({ name: 'thoigianhoan', type: 'timestamp', nullable: true })
  thoiGianHoan?: Date;

  @Column({ name: 'ghichu', type: 'text', nullable: true })
  ghiChu?: string;
}
