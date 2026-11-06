import { Request, Response } from 'express';
import { SupportService } from '../services/support_service';

export class SupportController {
  private supportService = new SupportService();

  // ==================== CẤU HÌNH LIÊN HỆ ====================
  getConfig = async (req: Request, res: Response) => {
    try {
      const config = await this.supportService.getConfig();
      return res.status(200).json({
        statusCode: 200,
        success: true,
        data: config,
      });
    } catch (err: any) {
      return res.status(500).json({
        statusCode: 500,
        success: false,
        message: err.message || 'Lỗi lấy cấu hình liên hệ',
      });
    }
  };

  updateConfig = async (req: Request, res: Response) => {
    try {
      const { hotline, gioLamViec, emailHoTro } = req.body;
      const updated = await this.supportService.updateConfig({
        hotline,
        gioLamViec,
        emailHoTro,
      });
      return res.status(200).json({
        statusCode: 200,
        success: true,
        message: 'Cập nhật cấu hình liên hệ thành công',
        data: updated,
      });
    } catch (err: any) {
      return res.status(400).json({
        statusCode: 400,
        success: false,
        message: err.message || 'Lỗi cập nhật cấu hình liên hệ',
      });
    }
  };

  // ==================== FAQ ====================
  getPublicFaq = async (req: Request, res: Response) => {
    try {
      const { search } = req.query;
      const data = await this.supportService.getPublicFaq(search as string);
      return res.status(200).json({
        statusCode: 200,
        success: true,
        data,
      });
    } catch (err: any) {
      return res.status(500).json({
        statusCode: 500,
        success: false,
        message: err.message || 'Lỗi lấy danh sách câu hỏi FAQ',
      });
    }
  };

  getAdminFaq = async (req: Request, res: Response) => {
    try {
      const data = await this.supportService.getAdminFaqGroups();
      return res.status(200).json({
        statusCode: 200,
        success: true,
        data,
      });
    } catch (err: any) {
      return res.status(500).json({
        statusCode: 500,
        success: false,
        message: err.message || 'Lỗi lấy danh sách FAQ cho Admin',
      });
    }
  };

  createFaqGroup = async (req: Request, res: Response) => {
    try {
      const { tenNhom, thuTu, kichHoat } = req.body;
      if (!tenNhom || !tenNhom.trim()) {
        return res.status(400).json({ statusCode: 400, message: 'Tên nhóm FAQ không được để trống' });
      }
      const data = await this.supportService.createFaqGroup({ tenNhom, thuTu, kichHoat });
      return res.status(201).json({
        statusCode: 201,
        success: true,
        message: 'Tạo nhóm câu hỏi FAQ thành công',
        data,
      });
    } catch (err: any) {
      return res.status(400).json({ statusCode: 400, success: false, message: err.message });
    }
  };

  updateFaqGroup = async (req: Request, res: Response) => {
    try {
      const maNhom = Number(req.params.id);
      const data = await this.supportService.updateFaqGroup(maNhom, req.body);
      return res.status(200).json({
        statusCode: 200,
        success: true,
        message: 'Cập nhật nhóm câu hỏi FAQ thành công',
        data,
      });
    } catch (err: any) {
      return res.status(400).json({ statusCode: 400, success: false, message: err.message });
    }
  };

  deleteFaqGroup = async (req: Request, res: Response) => {
    try {
      const maNhom = Number(req.params.id);
      await this.supportService.deleteFaqGroup(maNhom);
      return res.status(200).json({
        statusCode: 200,
        success: true,
        message: 'Đã xóa nhóm câu hỏi FAQ thành công',
      });
    } catch (err: any) {
      return res.status(400).json({ statusCode: 400, success: false, message: err.message });
    }
  };

  createFaqQuestion = async (req: Request, res: Response) => {
    try {
      const { maNhom, cauHoi, cauTraLoi, thuTu, kichHoat } = req.body;
      if (!maNhom || !cauHoi || !cauTraLoi) {
        return res.status(400).json({ statusCode: 400, message: 'Vui lòng điền đủ nhóm, câu hỏi và câu trả lời' });
      }
      const data = await this.supportService.createFaqQuestion({
        maNhom: Number(maNhom),
        cauHoi,
        cauTraLoi,
        thuTu,
        kichHoat,
      });
      return res.status(201).json({
        statusCode: 201,
        success: true,
        message: 'Tạo câu hỏi FAQ thành công',
        data,
      });
    } catch (err: any) {
      return res.status(400).json({ statusCode: 400, success: false, message: err.message });
    }
  };

  updateFaqQuestion = async (req: Request, res: Response) => {
    try {
      const maFaq = Number(req.params.id);
      const data = await this.supportService.updateFaqQuestion(maFaq, req.body);
      return res.status(200).json({
        statusCode: 200,
        success: true,
        message: 'Cập nhật câu hỏi FAQ thành công',
        data,
      });
    } catch (err: any) {
      return res.status(400).json({ statusCode: 400, success: false, message: err.message });
    }
  };

  deleteFaqQuestion = async (req: Request, res: Response) => {
    try {
      const maFaq = Number(req.params.id);
      await this.supportService.deleteFaqQuestion(maFaq);
      return res.status(200).json({
        statusCode: 200,
        success: true,
        message: 'Đã xóa câu hỏi FAQ thành công',
      });
    } catch (err: any) {
      return res.status(400).json({ statusCode: 400, success: false, message: err.message });
    }
  };

  // ==================== GÓP Ý & PHẢN HỒI ====================
  submitFeedback = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      const { hoTen, sdt, loaiGopY, noiDung, danhGiaSao, danhSachAnh } = req.body;

      if (!noiDung || !noiDung.trim()) {
        return res.status(400).json({ statusCode: 400, message: 'Vui lòng nhập nội dung góp ý' });
      }

      const feedback = await this.supportService.createFeedback({
        maTaiKhoan: user?.sub ? Number(user.sub) : undefined,
        hoTen,
        sdt,
        loaiGopY,
        noiDung,
        danhGiaSao,
        danhSachAnh,
      });

      return res.status(201).json({
        statusCode: 201,
        success: true,
        message: 'Cảm ơn bạn đã gửi ý kiến đóng góp cho Food Route!',
        data: feedback,
      });
    } catch (err: any) {
      return res.status(400).json({ statusCode: 400, success: false, message: err.message });
    }
  };

  getAdminFeedbacks = async (req: Request, res: Response) => {
    try {
      const { page, limit, loaiGopY, trangThai } = req.query;
      const data = await this.supportService.getAdminFeedbacks({
        page: page ? Number(page) : 1,
        limit: limit ? Number(limit) : 10,
        loaiGopY: loaiGopY as string,
        trangThai: trangThai as string,
      });
      return res.status(200).json({
        statusCode: 200,
        success: true,
        data,
      });
    } catch (err: any) {
      return res.status(500).json({ statusCode: 500, success: false, message: err.message });
    }
  };

  updateFeedbackStatus = async (req: Request, res: Response) => {
    try {
      const maGopY = Number(req.params.id);
      const { trangThai, ghiChuAdmin } = req.body;
      const data = await this.supportService.updateFeedbackStatus(maGopY, { trangThai, ghiChuAdmin });
      return res.status(200).json({
        statusCode: 200,
        success: true,
        message: 'Cập nhật trạng thái góp ý thành công',
        data,
      });
    } catch (err: any) {
      return res.status(400).json({ statusCode: 400, success: false, message: err.message });
    }
  };
}

