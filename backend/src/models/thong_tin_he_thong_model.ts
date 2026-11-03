import { Entity, PrimaryColumn, Column, UpdateDateColumn } from 'typeorm';

@Entity({ name: 'thongtin_hethong' })
export class ThongTinHeThongModel {
  @PrimaryColumn({ name: 'id', default: 1 })
  id: number;

  @Column({ name: 'badge', length: 150, default: 'ẨM THỰC TRÊN LỘ TRÌNH' })
  badge: string;

  @Column({ name: 'tieude', length: 255, default: 'Đặt Món Tiện Đường - Ghé Lấy Nóng Hổi' })
  tieude: string;

  @Column({ name: 'mota', type: 'text' })
  mota: string;

  @Column({ name: 'sub_badge', length: 150, default: 'Hơn 500+ quán ngon trên mọi cung đường' })
  sub_badge: string;

  @Column({ name: 'hinhanh', type: 'text', nullable: true })
  hinhanh?: string;

  @Column({ name: 'sumenh_tieude', length: 255, default: 'SỨ MỆNH & TÂM NHÌN' })
  sumenh_tieude: string;

  @Column({ name: 'sumenh_phude', length: 255, default: 'Kiến tạo phong cách ẩm thực di chuyển thông minh' })
  sumenh_phude: string;

  @Column({ name: 'sumenh_noidung', type: 'text' })
  sumenh_noidung: string;

  @Column({ name: 'stat1_val', length: 50, default: '500K+' })
  stat1_val: string;

  @Column({ name: 'stat1_label', length: 100, default: 'Lộ trình phục vụ' })
  stat1_label: string;

  @Column({ name: 'stat2_val', length: 50, default: '4.9★' })
  stat2_val: string;

  @Column({ name: 'stat2_label', length: 100, default: 'Đánh giá cao' })
  stat2_label: string;

  @Column({ name: 'stat3_val', length: 50, default: '99%' })
  stat3_val: string;

  @Column({ name: 'stat3_label', length: 100, default: 'Khách hài lòng' })
  stat3_label: string;

  @Column({ name: 'giatricotloi', type: 'jsonb', nullable: true })
  giatricotloi: any;

  @Column({ name: 'hotline', length: 50, default: '1900 6868' })
  hotline: string;

  @Column({ name: 'email', length: 100, default: 'support@foodroute.vn' })
  email: string;

  @Column({ name: 'website', length: 150, default: 'https://foodroute.vn' })
  website: string;

  @Column({ name: 'facebook', type: 'text', nullable: true, default: '' })
  facebook?: string;

  @Column({ name: 'instagram', type: 'text', nullable: true, default: '' })
  instagram?: string;

  @Column({ name: 'telegram', type: 'text', nullable: true, default: '' })
  telegram?: string;

  @Column({ name: 'gmail', type: 'text', nullable: true, default: '' })
  gmail?: string;

  @Column({ name: 'diachi', type: 'text' })
  diachi: string;

  @Column({ name: 'phienban', length: 50, default: 'Phiên bản 2.5.0 • FoodRoute Official' })
  phienban: string;

  @Column({ name: 'banquyen', length: 255, default: '© 2026 FoodRoute Inc. Giữ toàn bộ bản quyền hệ thống.' })
  banquyen: string;

  @UpdateDateColumn({ name: 'updated_at' })
  updated_at: Date;
}
