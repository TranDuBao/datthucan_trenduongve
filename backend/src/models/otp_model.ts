import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'ma_xac_thuc_otp' })
export class OtpModel {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 150 })
  email: string;

  @Column({ name: 'otp_code', length: 10 })
  otpCode: string;

  @Column({ length: 50, default: 'FORGOT_PASSWORD' })
  loai: string;

  @Column({ name: 'da_su_dung', default: false })
  daSuDung: boolean;

  @Column({ name: 'het_han_luc', type: 'timestamp' })
  hetHanLuc: Date;

  @CreateDateColumn({ name: 'ngay_tao' })
  ngayTao: Date;
}

