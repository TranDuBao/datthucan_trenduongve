import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'cuahang' })
export class CuaHangModel {
  @PrimaryGeneratedColumn({ name: 'maquan' })
  maQuan: number;

  @Column({ name: 'mataikhoan', nullable: true })
  maTaiKhoan?: number;

  @Column({ name: 'tenquan', length: 150 })
  tenQuan: string;

  @Column({ name: 'diachi', type: 'text' })
  diaChi: string;

  @Column({ name: 'trangthai', length: 50, default: 'mở cửa' })
  trangThai: string;

  @Column({ name: 'lat', type: 'double precision', nullable: true })
  lat?: number;

  @Column({ name: 'lng', type: 'double precision', nullable: true })
  lng?: number;

  @Column({ name: 'sdt', nullable: true, length: 15 })
  sdt?: string;

  @Column({ name: 'img', nullable: true, length: 255 })
  img?: string;
}
