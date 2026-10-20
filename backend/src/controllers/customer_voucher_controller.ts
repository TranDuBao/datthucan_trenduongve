import { Request, Response } from 'express';
import { VoucherService } from '../services/voucher_service';
import { AuthenticatedRequest } from '../middlewares/auth_middleware';

export class CustomerVoucherController {
  private voucherService = new VoucherService();

  getActiveVouchers = async (req: Request, res: Response) => {
    try {
      const maQuan = req.query.maQuan ? Number(req.query.maQuan) : undefined;
      const includeSystem = req.query.includeSystem === 'true';
      const vouchers = await this.voucherService.getActiveCustomerVouchers(maQuan, includeSystem);
      return res.status(200).json({ statusCode: 200, status: '1', data: vouchers });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  validateVoucher = async (req: Request, res: Response) => {
    try {
      const { maCode, maQuan, orderTotal } = req.body;
      if (!maCode) {
        return res.status(400).json({ statusCode: 400, message: 'Vui lòng cung cấp mã voucher' });
      }
      if (!maQuan) {
        return res.status(400).json({ statusCode: 400, message: 'Vui lòng cung cấp mã nhà hàng' });
      }

      const total = Number(orderTotal || 0);
      const result = await this.voucherService.validateCustomerVoucher(maCode, Number(maQuan), total);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  collectVoucher = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const maKhachHang = req.user?.sub;
      if (!maKhachHang) {
        return res.status(401).json({ statusCode: 401, message: 'Bạn chưa đăng nhập' });
      }

      const { maVoucher } = req.body;
      if (!maVoucher) {
        return res.status(400).json({ statusCode: 400, message: 'Vui lòng cung cấp mã ID voucher' });
      }

      const result = await this.voucherService.collectVoucher(maKhachHang, Number(maVoucher));
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: result.message });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getMyVouchers = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const maKhachHang = req.user?.sub;
      if (!maKhachHang) {
        return res.status(401).json({ statusCode: 401, message: 'Bạn chưa đăng nhập' });
      }

      const vouchers = await this.voucherService.getMyCollectedVouchers(maKhachHang);
      return res.status(200).json({ statusCode: 200, status: '1', data: vouchers });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };
}
