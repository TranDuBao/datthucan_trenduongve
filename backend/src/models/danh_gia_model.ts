import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'danhgia' })
export class DanhGiaModel {
  @PrimaryGeneratedColumn({ name: 'madanhgia' })
  maDanhGia: number;

  @Column({ name: 'madonhang', nullable: true })
  maDonHang?: number;

  @Column({ name: 'maquan', nullable: true })
  maQuan?: number;

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

  @Column({ name: 'ngayphanhoi', type: 'timestamp', nullable: true })
  ngayPhanHoi?: Date;

  @Column({ name: 'is_edited', type: 'boolean', default: false })
  isEdited: boolean;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;

  @Column({ name: 'is_hidden', type: 'boolean', default: false })
  isHidden: boolean;

  @Column({ name: 'ly_do_an', type: 'text', nullable: true })
  lyDoAn?: string;
}

