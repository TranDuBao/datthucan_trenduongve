import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity({ name: 'ban' })
export class BanModel {
  @PrimaryGeneratedColumn({ name: 'maban' })
  maBan: number;

  @Column({ name: 'maquan' })
  maQuan: number;

  @Column({ name: 'tenban', length: 50 })
  tenBan: string;

  @Column({ name: 'succhua', default: 4 })
  sucChua: number;

  @Column({ name: 'trangthai', length: 30, default: 'TRONG' })
  trangThai: string; // TRONG, DANG_SU_DUNG, TAM_NGUNG
}
