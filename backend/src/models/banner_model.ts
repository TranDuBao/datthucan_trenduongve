import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'banner' })
export class BannerModel {
  @PrimaryGeneratedColumn({ name: 'mabanner' })
  maBanner: number;

  @Column({ name: 'tieude', length: 255 })
  tieuDe: string;

  @Column({ name: 'phude', length: 255, nullable: true })
  phuDe?: string;

  @Column({ name: 'hinhanh', type: 'text' })
  hinhAnh: string;

  @Column({ name: 'lienket', length: 255, nullable: true })
  lienKet?: string;

  @Column({ name: 'mausac', length: 50, default: '#FC6011' })
  mauSac: string;

  @Column({ name: 'thutu', default: 0 })
  thuTu: number;

  @Column({ name: 'trangthai', length: 30, default: 'HOAT_DONG' })
  trangThai: string;

  @Column({ name: 'loaibanner', length: 50, default: 'TRAN_VIEN' })
  loaiBanner: string;

  @CreateDateColumn({ name: 'ngaytao' })
  ngayTao: Date;
}
