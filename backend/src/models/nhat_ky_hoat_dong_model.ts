import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'nhatkyhoatdong' })
export class NhatKyHoatDongModel {
  @PrimaryGeneratedColumn({ name: 'manhatky' })
  maNhatKy: number;

  @Column({ name: 'mataikhoan', nullable: true })
  maTaiKhoan?: number;

  @Column({ name: 'tennguoithuchien', length: 150 })
  tenNguoiThucHien: string;

  @Column({ name: 'actor_email', length: 150, nullable: true })
  actorEmail?: string;

  @Column({ name: 'actor_role', length: 50, nullable: true })
  actorRole?: string;

  @Column({ name: 'loaihanhdong', length: 100 })
  loaiHanhDong: string;

  @Column({ name: 'mota', type: 'text' })
  moTa: string;

  @Column({ name: 'doituong', length: 100, nullable: true })
  doiTuong?: string;

  @Column({ name: 'madoituong', length: 50, nullable: true })
  maDoiTuong?: string;

  @Column({ name: 'changes', type: 'jsonb', nullable: true })
  changes?: Record<string, any> | null;

  @Column({ name: 'result', length: 20, default: 'success' })
  result: string;

  @Column({ name: 'error_code', length: 100, nullable: true })
  errorCode?: string;

  @Column({ name: 'reason', type: 'text', nullable: true })
  reason?: string;

  @Column({ name: 'context', type: 'jsonb', nullable: true })
  context?: Record<string, any> | null;

  @Column({ name: 'request_id', length: 100, nullable: true })
  requestId?: string;

  @Column({ name: 'user_agent', type: 'text', nullable: true })
  userAgent?: string;

  @Column({ name: 'ipaddress', length: 50, nullable: true })
  ipAddress?: string;

  @CreateDateColumn({ name: 'thoigiantuyen' })
  thoiGianTuyen: Date;
}

