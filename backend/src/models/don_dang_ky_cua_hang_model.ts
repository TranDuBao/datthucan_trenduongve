import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { TaiKhoanModel } from './tai_khoan_model';
import { DieuKhoanChinhSachModel } from './dieu_khoan_chinh_sach_model';

export enum TrangThaiDonDangKy {
  CHO_DUYET = 'CHO_DUYET',
  DA_DUYET = 'DA_DUYET',
  TU_CHOI = 'TU_CHOI',
}

@Entity({ name: 'dondangkycuahang' })
export class DonDangKyCuaHangModel {
  @PrimaryGeneratedColumn({ name: 'madon' })
  maDon: number;

  @Column({ name: 'mataikhoan' })
  maTaiKhoan: number;

  @ManyToOne(() => TaiKhoanModel, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'mataikhoan' })
  taiKhoan?: TaiKhoanModel;

  @Column({ name: 'tenquan', length: 150 })
  tenQuan: string;

  @Column({ name: 'danhmuc', length: 100, nullable: true })
  danhMuc?: string;

  @Column({ name: 'diachi', type: 'text' })
  diaChi: string;

  @Column({ name: 'lat', type: 'double precision', nullable: true })
  lat?: number;

  @Column({ name: 'lng', type: 'double precision', nullable: true })
  lng?: number;

  @Column({ name: 'sdt', length: 20 })
  sdt: string;

  @Column({ name: 'hotenchuquan', length: 150, nullable: true })
  hoTenChuQuan?: string;

  @Column({ name: 'ngaysinhchuquan', type: 'date', nullable: true })
  ngaySinhChuQuan?: string | Date;

  @Column({ name: 'socccd', length: 20 })
  soCCCD: string;

  @Column({ name: 'diachithuongtru', type: 'text', nullable: true })
  diaChiThuongTru?: string;

  @Column({ name: 'tennganhang', length: 100 })
  tenNganHang: string;

  @Column({ name: 'sotaikhoannganhang', length: 50 })
  soTaiKhoanNganHang: string;

  @Column({ name: 'tenchutaikhoan', length: 100 })
  tenChuTaiKhoan: string;

  // Legal Information
  @Column({ name: 'loaihinhphaply', length: 50, nullable: true })
  loaiHinhPhapLy?: string | null;

  @Column({ name: 'masothue', length: 50, nullable: true })
  maSoThue?: string | null;

  @Column({ name: 'sogiayphepkinhdoanh', length: 100, nullable: true })
  soGiayPhepKinhDoanh?: string | null;

  @Column({ name: 'sogiayattp', length: 100, nullable: true })
  soGiayAttp?: string | null;

  // Proof of Consent (Legal agreement & data privacy policy)
  @Column({ name: 'maphienbandieukhoan', nullable: true })
  maPhienBanDieuKhoan?: number | null;

  @ManyToOne(() => DieuKhoanChinhSachModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'maphienbandieukhoan' })
  phienBanDieuKhoan?: DieuKhoanChinhSachModel | null;

  @Column({ name: 'maphienbanchinhsach', nullable: true })
  maPhienBanChinhSach?: number | null;

  @ManyToOne(() => DieuKhoanChinhSachModel, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'maphienbanchinhsach' })
  phienBanChinhSach?: DieuKhoanChinhSachModel | null;

  @Column({ name: 'thoigiandongy', type: 'timestamp', nullable: true })
  thoiGianDongY?: Date | null;

  @Column({ name: 'dongydieukhoan', type: 'boolean', default: false })
  dongYDieuKhoan: boolean;

  @Column({ name: 'dongychinhsachdulieu', type: 'boolean', default: false })
  dongYChinhSachDuLieu: boolean;

  @Column({ name: 'trangthai', length: 30, default: TrangThaiDonDangKy.CHO_DUYET })
  trangThai: string;

  @Column({ name: 'lydotuchoi', type: 'text', nullable: true })
  lyDoTuChoi?: string | null;

  @CreateDateColumn({ name: 'ngaytao', type: 'timestamp' })
  ngayTao: Date;

  @Column({ name: 'ngayduyet', type: 'timestamp', nullable: true })
  ngayDuyet?: Date | null;

  @Column({ name: 'nguoiduyet', nullable: true })
  nguoiDuyet?: number | null;
}

