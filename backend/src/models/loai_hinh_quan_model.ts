import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity({ name: 'loai_hinh_quan' })
export class LoaiHinhQuanModel {
  @PrimaryGeneratedColumn({ name: 'maloai' })
  maLoai: number;

  @Column({ name: 'tenloai', length: 100, unique: true })
  tenLoai: string;

  @Column({ name: 'mota', type: 'text', nullable: true })
  moTa?: string;

  @Column({ name: 'hinhanh', type: 'text', nullable: true })
  hinhAnh?: string;

  @Column({ name: 'icon', length: 50, nullable: true })
  icon?: string;

  @Column({ name: 'thutu', type: 'int', default: 0 })
  thuTu: number;

  @Column({ name: 'trangthai', length: 30, default: 'ACTIVE' })
  trangThai: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}

