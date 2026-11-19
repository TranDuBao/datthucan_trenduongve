import { Entity, PrimaryColumn, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { MonAnModel } from './mon_an_model';
import { DanhMucModel } from './danh_muc_model';

@Entity({ name: 'monan_danhmuc' })
export class MonAnDanhMucModel {
  @PrimaryColumn({ name: 'mamonan' })
  maMonAn: number;

  @PrimaryColumn({ name: 'madanhmuc' })
  maDanhMuc: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @ManyToOne(() => MonAnModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'mamonan' })
  monAn?: MonAnModel;

  @ManyToOne(() => DanhMucModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'madanhmuc' })
  danhMuc?: DanhMucModel;
}

