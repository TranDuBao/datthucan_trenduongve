import { Response } from 'express';
import { AuthenticatedRequest } from '../middlewares/auth_middleware';
import { StoreRegistrationService } from '../services/store_registration_service';

export class StoreRegistrationController {
  private service = StoreRegistrationService.getInstance();

  public submitRegistration = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const maTaiKhoan = Number(req.user?.sub);
      if (!maTaiKhoan) {
        return res.status(401).json({ success: false, message: 'Yêu cầu đăng nhập hợp lệ' });
      }

      const result = await this.service.submitRegistration(maTaiKhoan, req.body);
      return res.status(200).json({
        success: true,
        message: 'Gửi đơn đăng ký cửa hàng thành công! Vui lòng chờ quản trị viên duyệt.',
        data: result,
      });
    } catch (err: any) {
      const statusCode = err.statusCode || 400;
      return res.status(statusCode).json({
        success: false,
        code: err.code,
        message: err.message || 'Lỗi gửi đơn đăng ký cửa hàng',
      });
    }
  };

  public getMyStatus = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const maTaiKhoan = Number(req.user?.sub);
      if (!maTaiKhoan) {
        return res.status(401).json({ success: false, message: 'Yêu cầu đăng nhập hợp lệ' });
      }

      const result = await this.service.getMyStatus(maTaiKhoan);
      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err: any) {
      return res.status(500).json({
        success: false,
        message: err.message || 'Lỗi lấy trạng thái đơn đăng ký',
      });
    }
  };

  public getAdminRegistrations = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const page = parseInt(req.query.page as string, 10) || 1;
      const limit = parseInt(req.query.limit as string, 10) || 10;
      const status = req.query.status as string;

      const result = await this.service.getAdminRegistrations(page, limit, status);
      return res.status(200).json({
        success: true,
        ...result,
      });
    } catch (err: any) {
      return res.status(500).json({
        success: false,
        message: err.message || 'Lỗi lấy danh sách đơn đăng ký',
      });
    }
  };

  public getAdminRegistrationDetail = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const maDon = parseInt(req.params.id, 10);
      if (isNaN(maDon)) {
        return res.status(400).json({ success: false, message: 'Mã đơn không hợp lệ' });
      }

      const result = await this.service.getAdminRegistrationDetail(maDon);
      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (err: any) {
      return res.status(404).json({
        success: false,
        message: err.message || 'Không tìm thấy đơn đăng ký',
      });
    }
  };

  public approveRegistration = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const maDon = parseInt(req.params.id, 10);
      const adminId = Number(req.user?.sub);
      if (isNaN(maDon)) {
        return res.status(400).json({ success: false, message: 'Mã đơn không hợp lệ' });
      }

      const result = await this.service.approveRegistration(maDon, adminId);
      return res.status(200).json({
        success: true,
        message: result.message,
        data: result,
      });
    } catch (err: any) {
      return res.status(400).json({
        success: false,
        message: err.message || 'Lỗi duyệt đơn đăng ký',
      });
    }
  };

  public rejectRegistration = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const maDon = parseInt(req.params.id, 10);
      const adminId = Number(req.user?.sub);
      const { lyDoTuChoi } = req.body;

      if (isNaN(maDon)) {
        return res.status(400).json({ success: false, message: 'Mã đơn không hợp lệ' });
      }

      const result = await this.service.rejectRegistration(maDon, adminId, lyDoTuChoi);
      return res.status(200).json({
        success: true,
        message: result.message,
        data: result,
      });
    } catch (err: any) {
      return res.status(400).json({
        success: false,
        message: err.message || 'Lỗi từ chối đơn đăng ký',
      });
    }
  };
}

