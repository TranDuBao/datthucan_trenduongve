import { Request, Response } from 'express';
import { ReservationService } from '../services/reservation_service';

export class CustomerReservationController {
  private reservationService = new ReservationService();

  createReservation = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({
          status: 'error',
          message: 'Bạn cần đăng nhập để thực hiện đặt bàn',
        });
      }

      const result = await this.reservationService.createCustomerReservation(Number(user.sub), req.body);
      return res.status(201).json({
        status: 'success',
        message: 'Đặt bàn thành công',
        data: result,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Không thể tạo lượt đặt bàn',
      });
    }
  };

  getMyReservations = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({
          status: 'error',
          message: 'Bạn cần đăng nhập để xem lịch sử đặt bàn',
        });
      }

      const result = await this.reservationService.getCustomerReservations(Number(user.sub));
      return res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi lấy danh sách đặt bàn',
      });
    }
  };

  getReservationById = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({
          status: 'error',
          message: 'Bạn cần đăng nhập để xem thông tin đặt bàn',
        });
      }

      const id = Number(req.params.id);
      if (isNaN(id) || id <= 0) {
        return res.status(400).json({
          status: 'error',
          message: 'Mã lượt đặt bàn không hợp lệ',
        });
      }

      const result = await this.reservationService.getCustomerReservationById(Number(user.sub), id);
      return res.status(200).json({
        status: 'success',
        data: result,
      });
    } catch (error: any) {
      return res.status(404).json({
        status: 'error',
        message: error.message || 'Không tìm thấy lượt đặt bàn',
      });
    }
  };

  cancelReservation = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({
          status: 'error',
          message: 'Bạn cần đăng nhập để thực hiện hủy đặt bàn',
        });
      }

      const id = Number(req.params.id);
      if (isNaN(id) || id <= 0) {
        return res.status(400).json({
          status: 'error',
          message: 'Mã lượt đặt bàn không hợp lệ',
        });
      }

      const result = await this.reservationService.cancelCustomerReservation(Number(user.sub), id);
      return res.status(200).json({
        status: 'success',
        message: 'Đã hủy lượt đặt bàn thành công',
        data: result,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Không thể hủy lượt đặt bàn',
      });
    }
  };
}
