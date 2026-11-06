import { Request, Response } from 'express';
import { SupportTicketService } from '../services/support_ticket_service';

const ticketService = new SupportTicketService();

export class SupportTicketController {
  /**
   * [USER] Tạo phiếu hỗ trợ mới
   */
  static async createTicket(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.maTaiKhoan || (req as any).user?.id || (req as any).user?.sub;
      if (!userId) {
        return res.status(401).json({ success: false, message: 'Yêu cầu đăng nhập để gửi phiếu hỗ trợ.' });
      }

      const { loaiSuCo, moTa, tieuDe, maDonHang, danhSachAnh } = req.body;
      const ticket = await ticketService.createTicket(Number(userId), {
        loaiSuCo,
        moTa,
        tieuDe,
        maDonHang: maDonHang ? Number(maDonHang) : undefined,
        danhSachAnh,
      });

      return res.status(201).json({
        success: true,
        message: 'Gửi yêu cầu hỗ trợ thành công!',
        data: ticket,
      });
    } catch (e: any) {
      return res.status(400).json({ success: false, message: e.message || 'Lỗi tạo phiếu hỗ trợ' });
    }
  }

  /**
   * [USER] Lấy danh sách phiếu của người dùng
   */
  static async getMyTickets(req: Request, res: Response) {
    try {
      const userId = (req as any).user?.maTaiKhoan || (req as any).user?.id || (req as any).user?.sub;
      if (!userId) {
        return res.status(401).json({ success: false, message: 'Yêu cầu đăng nhập.' });
      }

      const page = Math.max(1, Number(req.query.page) || 1);
      const limit = Math.max(1, Math.min(50, Number(req.query.limit) || 20));
      const status = req.query.status as string;

      const result = await ticketService.getMyTickets(Number(userId), page, limit, status);
      return res.status(200).json({ success: true, ...result });
    } catch (e: any) {
      return res.status(500).json({ success: false, message: e.message || 'Lỗi tải danh sách phiếu' });
    }
  }

  /**
   * [USER/ADMIN] Xem chi tiết một phiếu
   */
  static async getTicketDetail(req: Request, res: Response) {
    try {
      const userId = Number((req as any).user?.maTaiKhoan || (req as any).user?.id || (req as any).user?.sub);
      const userRole = String((req as any).user?.role || '').toUpperCase();
      const isAdmin = userRole === 'ADMIN';

      const ticketId = Number(req.params.id);
      const ticket = await ticketService.getTicketDetail(ticketId, userId, isAdmin);

      return res.status(200).json({ success: true, data: ticket });
    } catch (e: any) {
      return res.status(400).json({ success: false, message: e.message });
    }
  }

  /**
   * [USER/ADMIN] Xem tin nhắn trong phiếu
   */
  static async getTicketMessages(req: Request, res: Response) {
    try {
      const userId = Number((req as any).user?.maTaiKhoan || (req as any).user?.id || (req as any).user?.sub);
      const userRole = String((req as any).user?.role || '').toUpperCase();
      const isAdmin = userRole === 'ADMIN';

      const ticketId = Number(req.params.id);
      const page = Math.max(1, Number(req.query.page) || 1);
      const limit = Math.max(1, Math.min(100, Number(req.query.limit) || 40));
      const beforeId = req.query.beforeId ? Number(req.query.beforeId) : undefined;

      const messages = await ticketService.getTicketMessages(ticketId, userId, isAdmin, page, limit, beforeId);
      return res.status(200).json({ success: true, data: messages });
    } catch (e: any) {
      return res.status(400).json({ success: false, message: e.message });
    }
  }

  /**
   * [USER/ADMIN] Gửi tin nhắn mới trong phiếu
   */
  static async sendMessage(req: Request, res: Response) {
    try {
      const userId = Number((req as any).user?.maTaiKhoan || (req as any).user?.id || (req as any).user?.sub);
      const userRole = String((req as any).user?.role || '').toUpperCase();
      const isAdmin = userRole === 'ADMIN';

      const ticketId = Number(req.params.id);
      const { noiDung, danhSachAnh } = req.body;

      const message = await ticketService.sendMessage(ticketId, userId, isAdmin ? 'ADMIN' : 'USER', {
        noiDung,
        danhSachAnh,
      });

      return res.status(201).json({ success: true, data: message });
    } catch (e: any) {
      return res.status(400).json({ success: false, message: e.message });
    }
  }

  /**
   * [USER/ADMIN] Đánh dấu tin nhắn đã đọc
   */
  static async markAsRead(req: Request, res: Response) {
    try {
      const userId = Number((req as any).user?.maTaiKhoan || (req as any).user?.id || (req as any).user?.sub);
      const userRole = String((req as any).user?.role || '').toUpperCase();
      const isAdmin = userRole === 'ADMIN';

      const ticketId = Number(req.params.id);
      await ticketService.markMessagesAsRead(ticketId, userId, isAdmin ? 'ADMIN' : 'USER');

      return res.status(200).json({ success: true, message: 'Đã đánh dấu đã đọc' });
    } catch (e: any) {
      return res.status(500).json({ success: false, message: e.message });
    }
  }

  /**
   * [ADMIN] Lấy danh sách phiếu tổng hợp
   */
  static async adminGetTickets(req: Request, res: Response) {
    try {
      const page = Math.max(1, Number(req.query.page) || 1);
      const limit = Math.max(1, Math.min(100, Number(req.query.limit) || 20));
      const status = req.query.status as string;
      const loaiSuCo = req.query.loaiSuCo as string;
      const search = req.query.search as string;

      const result = await ticketService.adminGetTickets(page, limit, status, loaiSuCo, search);
      return res.status(200).json({ success: true, ...result });
    } catch (e: any) {
      return res.status(500).json({ success: false, message: e.message });
    }
  }

  /**
   * [ADMIN] Cập nhật trạng thái phiếu
   */
  static async adminUpdateStatus(req: Request, res: Response) {
    try {
      const ticketId = Number(req.params.id);
      const { trangThai } = req.body;

      if (!['MOI', 'DANG_XU_LY', 'DA_GIAI_QUYET', 'DA_DONG'].includes(trangThai)) {
        return res.status(400).json({ success: false, message: 'Trạng thái không hợp lệ.' });
      }

      const updated = await ticketService.adminUpdateTicketStatus(ticketId, trangThai);
      return res.status(200).json({
        success: true,
        message: 'Cập nhật trạng thái phiếu thành công!',
        data: updated,
      });
    } catch (e: any) {
      return res.status(400).json({ success: false, message: e.message });
    }
  }
}

