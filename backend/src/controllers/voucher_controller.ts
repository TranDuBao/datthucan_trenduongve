import { Response } from 'express';
import { VoucherService } from '../services/voucher_service';
import { StoreAuthenticatedRequest } from '../middlewares/role_middleware';

export class VoucherController {
  private voucherService = new VoucherService();

  private getStoreId(req: StoreAuthenticatedRequest): number {
    const maQuan = req.maQuan;
    if (!maQuan) {
      throw new Error('Tài khoản chưa được gán nhà hàng quản lý');
    }
    return maQuan;
  }

  getStoreVouchers = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const status = req.query.status ? String(req.query.status) : undefined;
      const search = req.query.search ? String(req.query.search) : undefined;

      const result = await this.voucherService.getStoreVouchers(maQuan, status, search);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getVoucherById = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const maVoucher = Number(req.params.id);
      const voucher = await this.voucherService.getVoucherById(maQuan, maVoucher);
      return res.status(200).json({ statusCode: 200, status: '1', data: voucher });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  createVoucher = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const created = await this.voucherService.createVoucher(maQuan, req.body);
      return res.status(201).json({
        statusCode: 201,
        status: '1',
        data: created,
        message: 'Tạo chương trình voucher thành công',
      });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateVoucher = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const maVoucher = Number(req.params.id);
      const updated = await this.voucherService.updateVoucher(maQuan, maVoucher, req.body);
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        data: updated,
        message: 'Cập nhật thông tin voucher thành công',
      });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  toggleVoucherStatus = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const maVoucher = Number(req.params.id);
      const targetStatus = req.body.trangThai ? String(req.body.trangThai) : undefined;
      const updated = await this.voucherService.toggleVoucherStatus(maQuan, maVoucher, targetStatus);
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        data: updated,
        message: `Đã ${updated.trangThai === 'HOAT_DONG' ? 'bật' : 'tắt'} voucher thành công`,
      });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  deleteVoucher = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const maVoucher = Number(req.params.id);
      const result = await this.voucherService.deleteVoucher(maQuan, maVoucher);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: result.message });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };
}
