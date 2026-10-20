import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { DanhGiaModel } from './danh_gia_model';
import { MonAnModel } from './mon_an_model';

@Entity({ name: 'danhgia_mon' })
export class DanhGiaMonModel {
  @PrimaryGeneratedColumn({ name: 'madanhgiamon' })
  maDanhGiaMon: number;

  @Column({ name: 'madanhgia' })
  maDanhGia: number;

  @Column({ name: 'mamon' })
  maMon: number;

  @Column({ name: 'soluongsao', type: 'int', default: 5 })
  soLuongSao: number;

  @Column({ name: 'nhanxet', type: 'text', nullable: true })
  nhanXet?: string;

  @ManyToOne(() => DanhGiaModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'madanhgia' })
  danhGia?: DanhGiaModel;

  @ManyToOne(() => MonAnModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'mamon' })
  monAn?: MonAnModel;
}
