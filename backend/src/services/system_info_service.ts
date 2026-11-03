import { AppDataSource } from '../config/database';
import { ThongTinHeThongModel } from '../models/thong_tin_he_thong_model';
import { RealtimeService } from './realtime_service';

export class SystemInfoService {
  private repo = AppDataSource.getRepository(ThongTinHeThongModel);

  async getAboutUs(): Promise<ThongTinHeThongModel> {
    let info = await this.repo.findOne({ where: { id: 1 } });
    if (!info) {
      info = this.repo.create({
        id: 1,
        badge: 'ẨM THỰC TRÊN LỘ TRÌNH',
        tieude: 'Đặt Món Tiện Đường - Ghé Lấy Nóng Hổi',
        mota: 'Nền tảng tìm kiếm và đặt món thông minh dọc theo lộ trình di chuyển của bạn. Ghé lấy thức ăn tươi nóng mà không cần chờ đợi, trải nghiệm ẩm thực tiện lợi tối ưu thời gian.',
        sub_badge: 'Hơn 500+ quán ngon trên mọi cung đường',
        sumenh_tieude: 'SỨ MỆNH & TÂM NHÌN',
        sumenh_phude: 'Kiến tạo phong cách ẩm thực di chuyển thông minh',
        sumenh_noidung: 'Định vị thành giải pháp kết nối ẩm thực lộ trình hàng đầu, giúp tối ưu hóa thời gian di chuyển hàng ngày của người dùng bằng công nghệ gợi ý món ngon thông minh, đặt trước tiện lợi và thanh toán không tiền mặt an toàn.',
        stat1_val: '500K+',
        stat1_label: 'Lộ trình phục vụ',
        stat2_val: '4.9★',
        stat2_label: 'Đánh giá cao',
        stat3_val: '99%',
        stat3_label: 'Khách hài lòng',
        giatricotloi: [
          { icon: 'navigation', title: 'Tiện đường ghé lấy', desc: 'Đặt món trước, ghé lấy ngay trên lộ trình di chuyển mà không mất thời gian chờ đợi.' },
          { icon: 'flame', title: 'Nóng hổi chuẩn giờ', desc: 'Quán canh thời gian chuẩn bị để món ăn vừa hoàn thành đúng lúc bạn có mặt.' },
          { icon: 'shield', title: 'Thanh toán an toàn', desc: 'Tích hợp thanh toán tiện lợi qua VietQR, PayOS và MoMo với độ bảo mật tuyệt đối.' },
          { icon: 'store', title: 'Quán ngon chọn lọc', desc: 'Hệ thống nhà hàng, quán ăn dọc tuyến đường được tuyển chọn kỹ lưỡng về vệ sinh an toàn.' }
        ],
        hotline: '1900 6868',
        email: 'support@foodroute.vn',
        website: 'https://foodroute.vn',
        diachi: 'Khu Công Nghệ Cao, TP. Thủ Đức, TP. Hồ Chí Minh',
        phienban: 'Phiên bản 2.5.0 • FoodRoute Official',
        banquyen: '© 2026 FoodRoute Inc. Giữ toàn bộ bản quyền hệ thống.',
      });
      await this.repo.save(info);
    }
    return info;
  }

  async updateAboutUs(data: Partial<ThongTinHeThongModel>): Promise<ThongTinHeThongModel> {
    let info = await this.repo.findOne({ where: { id: 1 } });
    if (!info) {
      info = await this.getAboutUs();
    }

    // Merge allowed fields
    const allowedKeys: (keyof ThongTinHeThongModel)[] = [
      'badge',
      'tieude',
      'mota',
      'sub_badge',
      'hinhanh',
      'sumenh_tieude',
      'sumenh_phude',
      'sumenh_noidung',
      'stat1_val',
      'stat1_label',
      'stat2_val',
      'stat2_label',
      'stat3_val',
      'stat3_label',
      'giatricotloi',
      'hotline',
      'email',
      'website',
      'facebook',
      'instagram',
      'telegram',
      'gmail',
      'diachi',
      'phienban',
      'banquyen',
    ];

    for (const key of allowedKeys) {
      if (data[key] !== undefined) {
        (info as any)[key] = data[key];
      }
    }

    const saved = await this.repo.save(info);
    // Realtime emit after DB write succeeds (Rule 15)
    RealtimeService.getInstance().emitAboutUsUpdated(saved);
    return saved;
  }
}
