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

  @Column({ name: 'img', type: 'text', nullable: true })
  img?: string;

  @Column({ name: 'hotenchuquan', nullable: true, length: 100 })
  hoTenChuQuan?: string | null;

  @Column({ name: 'diachithuongtru', nullable: true, type: 'text' })
  diaChiThuongTru?: string | null;

  @Column({ name: 'ngaysinhchuquan', nullable: true, type: 'date' })
  ngaySinhChuQuan?: Date | string | null;

  @Column({ name: 'socccd', nullable: true, length: 20 })
  soCCCD?: string | null;

  @Column({ name: 'tennganhang', nullable: true, length: 100 })
  tenNganHang?: string | null;

  @Column({ name: 'sotaikhoannganhang', nullable: true, length: 50 })
  soTaiKhoanNganHang?: string | null;

  @Column({ name: 'tenchutaikhoan', nullable: true, length: 100 })
  tenChuTaiKhoan?: string | null;

  @Column({ name: 'cccdmattruoc', nullable: true, type: 'text' })
  cccdMatTruoc?: string | null;

  @Column({ name: 'cccdmatsau', nullable: true, type: 'text' })
  cccdMatSau?: string | null;

  @Column({ name: 'mota', nullable: true, type: 'text' })
  moTa?: string | null;

  @Column({ name: 'email', nullable: true, length: 100 })
  email?: string | null;

  @Column({ name: 'danhmuc', nullable: true, length: 100 })
  danhMuc?: string | null;

  @Column({ name: 'giohoatdong', nullable: true, type: 'text' })
  gioHoatDong?: string | null;

  @Column({ name: 'thoigianchuanbi', nullable: true, default: 20 })
  thoiGianChuanBi?: number;

  @Column({ name: 'cochodattruoc', nullable: true, default: true })
  coChoDatTruoc?: boolean;

  @Column({ name: 'tienich', nullable: true, type: 'text' })
  tienIch?: string | null;

  @Column({ name: 'danhgiatrungbinh', type: 'decimal', precision: 3, scale: 2, default: 5.00 })
  danhGiaTrungBinh: number;

  @Column({ name: 'soluongdanhgia', type: 'int', default: 0 })
  soLuongDanhGia: number;

  @Column({ name: 'is_deleted', type: 'boolean', default: false })
  isDeleted: boolean;
}

