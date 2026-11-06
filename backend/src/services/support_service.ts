import { AppDataSource } from '../config/database';
import { SupportConfigModel } from '../models/support_config_model';
import { SupportFaqGroupModel } from '../models/support_faq_group_model';
import { SupportFaqModel } from '../models/support_faq_model';
import { SupportFeedbackModel } from '../models/support_feedback_model';
import { RealtimeService } from './realtime_service';

export class SupportService {
  private configRepo = AppDataSource.getRepository(SupportConfigModel);
  private faqGroupRepo = AppDataSource.getRepository(SupportFaqGroupModel);
  private faqRepo = AppDataSource.getRepository(SupportFaqModel);
  private feedbackRepo = AppDataSource.getRepository(SupportFeedbackModel);

  // ==================== 1. CẤU HÌNH LIÊN HỆ ====================
  async getConfig(): Promise<SupportConfigModel> {
    let config = await this.configRepo.findOne({ where: { id: 1 } });
    if (!config) {
      config = this.configRepo.create({
        id: 1,
        hotline: '1900 6868',
        gioLamViec: '08:00 - 22:00 hàng ngày (T2 - CN)',
        emailHoTro: 'support@foodroute.vn',
      });
      await this.configRepo.save(config);
    }
    return config;
  }

  async updateConfig(data: {
    hotline?: string;
    gioLamViec?: string;
    emailHoTro?: string;
  }): Promise<SupportConfigModel> {
    const config = await this.getConfig();
    if (data.hotline !== undefined) config.hotline = data.hotline.trim();
    if (data.gioLamViec !== undefined) config.gioLamViec = data.gioLamViec.trim();
    if (data.emailHoTro !== undefined) config.emailHoTro = data.emailHoTro.trim();

    const saved = await this.configRepo.save(config);

    // Broadcast realtime to all clients
    try {
      const io = RealtimeService.getInstance().getIO();
      if (io) {
        io.emit('support:config_updated', {
          hotline: saved.hotline,
          gioLamViec: saved.gioLamViec,
          emailHoTro: saved.emailHoTro,
          updatedAt: saved.updatedAt,
        });
      }
    } catch (e) {
      console.warn('[SupportService] Realtime emit error (support:config_updated):', e);
    }

    return saved;
  }

  // ==================== 2. CÂU HỎI THƯỜNG GẶP (FAQ) ====================
  async getPublicFaq(search?: string) {
    const groups = await this.faqGroupRepo.find({
      where: { kichHoat: true },
      order: { thuTu: 'ASC', maNhom: 'ASC' },
      relations: ['cauHoi'],
    });

    const keyword = search ? search.trim().toLowerCase() : '';

    return groups
      .map((g) => {
        let items = (g.cauHoi || [])
          .filter((q) => q.kichHoat)
          .sort((a, b) => a.thuTu - b.thuTu);

        if (keyword) {
          items = items.filter(
            (q) =>
              q.cauHoi.toLowerCase().includes(keyword) ||
              q.cauTraLoi.toLowerCase().includes(keyword)
          );
        }

        return {
          maNhom: g.maNhom,
          tenNhom: g.tenNhom,
          thuTu: g.thuTu,
          cauHoi: items,
        };
      })
      .filter((g) => g.cauHoi.length > 0 || !keyword);
  }

  async getAdminFaqGroups() {
    return this.faqGroupRepo.find({
      order: { thuTu: 'ASC', maNhom: 'ASC' },
      relations: ['cauHoi'],
    });
  }

  async createFaqGroup(data: { tenNhom: string; thuTu?: number; kichHoat?: boolean }) {
    const group = this.faqGroupRepo.create({
      tenNhom: data.tenNhom.trim(),
      thuTu: data.thuTu || 1,
      kichHoat: data.kichHoat !== undefined ? data.kichHoat : true,
    });
    const saved = await this.faqGroupRepo.save(group);

    this.emitFaqUpdated('CREATE_GROUP', { group: saved });
    return saved;
  }

  async updateFaqGroup(maNhom: number, data: { tenNhom?: string; thuTu?: number; kichHoat?: boolean }) {
    const group = await this.faqGroupRepo.findOne({ where: { maNhom } });
    if (!group) throw new Error('Nhóm câu hỏi FAQ không tồn tại');

    if (data.tenNhom !== undefined) group.tenNhom = data.tenNhom.trim();
    if (data.thuTu !== undefined) group.thuTu = Number(data.thuTu);
    if (data.kichHoat !== undefined) group.kichHoat = Boolean(data.kichHoat);

    const saved = await this.faqGroupRepo.save(group);
    this.emitFaqUpdated('UPDATE_GROUP', { group: saved });
    return saved;
  }

  async deleteFaqGroup(maNhom: number) {
    const group = await this.faqGroupRepo.findOne({ where: { maNhom } });
    if (!group) throw new Error('Nhóm câu hỏi FAQ không tồn tại');

    await this.faqGroupRepo.remove(group);
    this.emitFaqUpdated('DELETE_GROUP', { maNhom });
    return true;
  }

  async createFaqQuestion(data: {
    maNhom: number;
    cauHoi: string;
    cauTraLoi: string;
    thuTu?: number;
    kichHoat?: boolean;
  }) {
    const group = await this.faqGroupRepo.findOne({ where: { maNhom: data.maNhom } });
    if (!group) throw new Error('Nhóm câu hỏi không tồn tại');

    const question = this.faqRepo.create({
      maNhom: data.maNhom,
      cauHoi: data.cauHoi.trim(),
      cauTraLoi: data.cauTraLoi.trim(),
      thuTu: data.thuTu || 1,
      kichHoat: data.kichHoat !== undefined ? data.kichHoat : true,
    });
    const saved = await this.faqRepo.save(question);

    this.emitFaqUpdated('CREATE_QUESTION', { question: saved });
    return saved;
  }

  async updateFaqQuestion(
    maFaq: number,
    data: {
      maNhom?: number;
      cauHoi?: string;
      cauTraLoi?: string;
      thuTu?: number;
      kichHoat?: boolean;
    }
  ) {
    const question = await this.faqRepo.findOne({ where: { maFaq } });
    if (!question) throw new Error('Câu hỏi FAQ không tồn tại');

    if (data.maNhom !== undefined) question.maNhom = Number(data.maNhom);
    if (data.cauHoi !== undefined) question.cauHoi = data.cauHoi.trim();
    if (data.cauTraLoi !== undefined) question.cauTraLoi = data.cauTraLoi.trim();
    if (data.thuTu !== undefined) question.thuTu = Number(data.thuTu);
    if (data.kichHoat !== undefined) question.kichHoat = Boolean(data.kichHoat);

    const saved = await this.faqRepo.save(question);
    this.emitFaqUpdated('UPDATE_QUESTION', { question: saved });
    return saved;
  }

  async deleteFaqQuestion(maFaq: number) {
    const question = await this.faqRepo.findOne({ where: { maFaq } });
    if (!question) throw new Error('Câu hỏi FAQ không tồn tại');

    const maNhom = question.maNhom;
    await this.faqRepo.remove(question);
    this.emitFaqUpdated('DELETE_QUESTION', { maFaq, maNhom });
    return true;
  }

  private emitFaqUpdated(action: string, payload: any) {
    try {
      const io = RealtimeService.getInstance().getIO();
      if (io) {
        io.emit('support:faq_updated', {
          action,
          ...payload,
          timestamp: new Date().toISOString(),
        });
      }
    } catch (e) {
      console.warn('[SupportService] Realtime emit error (support:faq_updated):', e);
    }
  }

  // ==================== 3. GÓP Ý & PHẢN HỒI ====================
  async createFeedback(data: {
    maTaiKhoan?: number;
    hoTen?: string;
    sdt?: string;
    loaiGopY?: string;
    noiDung: string;
    danhGiaSao?: number;
    danhSachAnh?: string[];
  }) {
    if (!data.noiDung || !data.noiDung.trim()) {
      throw new Error('Nội dung góp ý không được để trống');
    }

    const feedback = this.feedbackRepo.create({
      maTaiKhoan: data.maTaiKhoan || null,
      hoTen: data.hoTen ? data.hoTen.trim() : null,
      sdt: data.sdt ? data.sdt.trim() : null,
      loaiGopY: data.loaiGopY || 'TINH_NANG',
      noiDung: data.noiDung.trim(),
      danhGiaSao: data.danhGiaSao ? Math.max(1, Math.min(5, Number(data.danhGiaSao))) : null,
      danhSachAnh: Array.isArray(data.danhSachAnh) ? data.danhSachAnh : null,
      trangThai: 'CHUA_XEM',
    });

    const saved = await this.feedbackRepo.save(feedback);

    // Realtime notification to admin
    try {
      const io = RealtimeService.getInstance().getIO();
      if (io) {
        io.to('admin').emit('support:feedback_new', {
          maGopY: saved.maGopY,
          hoTen: saved.hoTen || 'Khách hàng ẩn danh',
          loaiGopY: saved.loaiGopY,
          danhGiaSao: saved.danhGiaSao,
          noiDung: saved.noiDung.substring(0, 100),
          ngayTao: saved.ngayTao,
        });
      }
    } catch (e) {
      console.warn('[SupportService] Realtime emit error (support:feedback_new):', e);
    }

    return saved;
  }

  async getAdminFeedbacks(options: {
    page?: number;
    limit?: number;
    loaiGopY?: string;
    trangThai?: string;
  }) {
    const page = Math.max(1, Number(options.page) || 1);
    const limit = Math.max(1, Math.min(50, Number(options.limit) || 10));
    const skip = (page - 1) * limit;

    const query = this.feedbackRepo
      .createQueryBuilder('fb')
      .leftJoinAndSelect('fb.taiKhoan', 'tk')
      .orderBy('fb.ngayTao', 'DESC')
      .skip(skip)
      .take(limit);

    if (options.loaiGopY && options.loaiGopY !== 'ALL') {
      query.andWhere('fb.loaiGopY = :loaiGopY', { loaiGopY: options.loaiGopY });
    }
    if (options.trangThai && options.trangThai !== 'ALL') {
      query.andWhere('fb.trangThai = :trangThai', { trangThai: options.trangThai });
    }

    const [items, total] = await query.getManyAndCount();
    return { items, total, page, limit };
  }

  async updateFeedbackStatus(
    maGopY: number,
    data: { trangThai?: 'CHUA_XEM' | 'DA_XEM' | 'DA_XU_LY'; ghiChuAdmin?: string }
  ) {
    const feedback = await this.feedbackRepo.findOne({ where: { maGopY } });
    if (!feedback) throw new Error('Không tìm thấy bản ghi góp ý');

    if (data.trangThai) feedback.trangThai = data.trangThai;
    if (data.ghiChuAdmin !== undefined) feedback.ghiChuAdmin = data.ghiChuAdmin ? data.ghiChuAdmin.trim() : null;

    return this.feedbackRepo.save(feedback);
  }
}

