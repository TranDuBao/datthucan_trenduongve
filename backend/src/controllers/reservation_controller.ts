import { Response } from 'express';
import { StoreAuthenticatedRequest } from '../middlewares/role_middleware';
import { ReservationService } from '../services/reservation_service';

export class ReservationController {
  private service = new ReservationService();

  getDashboardStats = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan;
      if (!maQuan) {
        return res.status(400).json({ statusCode: 400, message: 'Thiếu thông tin maQuan từ cửa hàng' });
      }

      const stats = await this.service.getDashboardStats(maQuan);
      return res.status(200).json({ statusCode: 200, data: stats });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message || 'Lỗi lấy thống kê đặt bàn' });
    }
  };

  getReservations = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan;
      if (!maQuan) {
        return res.status(400).json({ statusCode: 400, message: 'Thiếu thông tin maQuan từ cửa hàng' });
      }

      const { timeRange, startDate, endDate, trangThai, maBan, search, page, limit } = req.query;

      const result = await this.service.getReservations(maQuan, {
        timeRange: timeRange as any,
        startDate: startDate as string,
        endDate: endDate as string,
        trangThai: trangThai as string,
        maBan: maBan as string,
        search: search as string,
        page: page ? Number(page) : 1,
        limit: limit ? Number(limit) : 15,
      });

      return res.status(200).json({ statusCode: 200, ...result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message || 'Lỗi danh sách đặt bàn' });
    }
  };

  getReservationById = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan;
      const id = Number(req.params.id);
      if (!maQuan || !id) {
        return res.status(400).json({ statusCode: 400, message: 'Tham số không hợp lệ' });
      }

      const reservation = await this.service.getReservationById(maQuan, id);
      return res.status(200).json({ statusCode: 200, data: reservation });
    } catch (error: any) {
      return res.status(404).json({ statusCode: 404, message: error.message || 'Không tìm thấy lượt đặt bàn' });
    }
  };

  confirmReservation = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const updated = await this.service.updateReservationStatus(maQuan, id, 'DA_XAC_NHAN');
      return res.status(200).json({ statusCode: 200, message: 'Đã xác nhận đặt bàn thành công', data: updated });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể xác nhận đặt bàn' });
    }
  };

  rejectReservation = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const updated = await this.service.updateReservationStatus(maQuan, id, 'TU_CHOI');
      return res.status(200).json({ statusCode: 200, message: 'Đã từ chối đặt bàn', data: updated });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể từ chối đặt bàn' });
    }
  };

  checkInReservation = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const updated = await this.service.updateReservationStatus(maQuan, id, 'DA_DEN');
      return res.status(200).json({ statusCode: 200, message: 'Xác nhận khách đã đến', data: updated });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể xác nhận khách đã đến' });
    }
  };

  startReservation = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const updated = await this.service.updateReservationStatus(maQuan, id, 'DANG_SU_DUNG');
      return res.status(200).json({ statusCode: 200, message: 'Đánh dấu khách đang sử dụng bàn', data: updated });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể cập nhật sử dụng bàn' });
    }
  };

  completeReservation = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const updated = await this.service.updateReservationStatus(maQuan, id, 'DA_HOAN_TAT');
      return res.status(200).json({ statusCode: 200, message: 'Đã hoàn tất lượt sử dụng bàn', data: updated });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể hoàn tất lượt đặt bàn' });
    }
  };

  cancelReservation = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const updated = await this.service.updateReservationStatus(maQuan, id, 'DA_HUY');
      return res.status(200).json({ statusCode: 200, message: 'Đã hủy đặt bàn', data: updated });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể hủy đặt bàn' });
    }
  };

  noShowReservation = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const updated = await this.service.updateReservationStatus(maQuan, id, 'KHACH_KHONG_DEN');
      return res.status(200).json({ statusCode: 200, message: 'Đánh dấu khách không đến', data: updated });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể cập nhật khách không đến' });
    }
  };

  handleAction = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const action = (req.body.action || '').toString().toLowerCase();
      const note = req.body.note;

      let targetStatus = '';
      if (['confirm', 'da_xac_nhan'].includes(action)) targetStatus = 'DA_XAC_NHAN';
      else if (['reject', 'tu_choi'].includes(action)) targetStatus = 'TU_CHOI';
      else if (['check-in', 'check_in', 'da_den'].includes(action)) targetStatus = 'DA_DEN';
      else if (['start', 'dang_su_dung'].includes(action)) targetStatus = 'DANG_SU_DUNG';
      else if (['complete', 'da_hoan_tat', 'hoan_tat'].includes(action)) targetStatus = 'DA_HOAN_TAT';
      else if (['cancel', 'da_huy', 'khach_huy'].includes(action)) targetStatus = 'DA_HUY';
      else if (['no-show', 'no_show', 'khach_khong_den'].includes(action)) targetStatus = 'KHACH_KHONG_DEN';

      if (!targetStatus) {
        return res.status(400).json({ statusCode: 400, message: `Hành động không hợp lệ: ${action}` });
      }

      const updated = await this.service.updateReservationStatus(maQuan, id, targetStatus, note);
      return res.status(200).json({ statusCode: 200, message: 'Cập nhật trạng thái đặt bàn thành công', data: updated });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể cập nhật trạng thái đặt bàn' });
    }
  };


  createReservation = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const reservation = await this.service.createReservation(maQuan, req.body);
      return res.status(201).json({ statusCode: 201, message: 'Tạo lượt đặt bàn thành công', data: reservation });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể tạo lượt đặt bàn' });
    }
  };

  updateReservation = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const updated = await this.service.updateReservation(maQuan, id, req.body);
      return res.status(200).json({ statusCode: 200, message: 'Cập nhật thông tin đặt bàn thành công', data: updated });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể cập nhật thông tin đặt bàn' });
    }
  };


  // --- QUẢN LÝ BÀN ---

  getTables = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const tables = await this.service.getTables(maQuan);
      return res.status(200).json({ statusCode: 200, data: tables });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message || 'Lỗi danh sách bàn' });
    }
  };

  createTable = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const table = await this.service.createTable(maQuan, req.body);
      return res.status(201).json({ statusCode: 201, message: 'Tạo bàn thành công', data: table });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể tạo bàn mới' });
    }
  };

  updateTable = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const table = await this.service.updateTable(maQuan, id, req.body);
      return res.status(200).json({ statusCode: 200, message: 'Cập nhật bàn thành công', data: table });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể cập nhật thông tin bàn' });
    }
  };

  toggleTableStatus = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = req.maQuan!;
      const id = Number(req.params.id);
      const table = await this.service.toggleTableStatus(maQuan, id, req.body?.trangThai);
      return res.status(200).json({ statusCode: 200, message: 'Cập nhật trạng thái bàn thành công', data: table });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể cập nhật trạng thái bàn' });
    }
  };
}
