import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'danhgia' })
export class DanhGiaModel {
  @PrimaryGeneratedColumn({ name: 'madanhgia' })
  maDanhGia: number;

  @Column({ name: 'machitietdon', nullable: true })
  maChiTietDon?: number;

  @Column({ name: 'makhachhang', nullable: true })
  maKhachHang?: number;

  @Column({ name: 'soluongsao', type: 'int', default: 5 })
  soLuongSao: number;

  @Column({ name: 'nhanxet', type: 'text', nullable: true })
  nhanXet?: string;

  @CreateDateColumn({ name: 'ngaynhanxet' })
  ngayNhanXet: Date;

  @Column({ name: 'hinhanh', type: 'text', nullable: true })
  hinhAnh?: string;

  @Column({ name: 'phanhoi', type: 'text', nullable: true })
  phanHoi?: string;
}
