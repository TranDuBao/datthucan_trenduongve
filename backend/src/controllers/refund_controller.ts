import { Request, Response } from 'express';
import { RefundService } from '../services/refund_service';
import { AppDataSource } from '../config/database';
import { CuaHangModel } from '../models/cua_hang_model';
import { HoanTienModel, RefundStatus } from '../models/hoan_tien_model';

export class RefundController {
  private refundService = RefundService.getInstance();
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private hoanTienRepo = AppDataSource.getRepository(HoanTienModel);

  /**
   * Danh sách yêu cầu hoàn tiền (Có phân quyền Admin và Quán)
   */
  getRefunds = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const role = String(user.role || '').toUpperCase();
      const userSub = Number(user.sub);
      let maQuan: number | undefined;

      if (role !== 'ADMIN') {
        if (role === 'CUAN_HANG' || role === 'CUA_HANG' || role === 'RESTAURANT' || role === 'STORE') {
          const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userSub } });
          if (!store) {
            return res.status(403).json({ status: 'error', message: 'Không tìm thấy thông tin cửa hàng' });
          }
          maQuan = store.maQuan;
        } else {
          return res.status(403).json({ status: 'error', message: 'Bạn không có quyền truy cập danh sách hoàn tiền' });
        }
      }

      const trangThai = req.query.trangThai as string | undefined;
      const refunds = await this.refundService.getRefundsList({ maQuan, trangThai });

      return res.status(200).json({
        status: 'success',
        data: refunds,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi lấy danh sách hoàn tiền',
      });
    }
  };

  /**
   * Chi tiết yêu cầu hoàn tiền
   */
  getRefundById = async (req: Request, res: Response) => {
    try {
      const maHoanTien = Number(req.params.id);
      const refund = await this.hoanTienRepo.findOne({ where: { maHoanTien } });
      if (!refund) {
        return res.status(404).json({ status: 'error', message: 'Không tìm thấy yêu cầu hoàn tiền' });
      }

      return res.status(200).json({
        status: 'success',
        data: refund,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi lấy chi tiết hoàn tiền',
      });
    }
  };

  /**
   * Cập nhật trạng thái hoàn tiền (Admin xác nhận chuyển khoản / đối soát)
   */
  updateRefundStatus = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      const role = String(user.role || '').toUpperCase();
      if (role !== 'ADMIN') {
        return res.status(403).json({
          status: 'error',
          message: 'Chỉ Quản trị viên mới có quyền cập nhật trạng thái hoàn tiền',
        });
      }

      const maHoanTien = Number(req.params.id);
      const { trangThai, maGiaoDich, ghiChu } = req.body;

      if (!trangThai) {
        return res.status(400).json({ status: 'error', message: 'Thiếu trạng thái hoàn tiền mới' });
      }

      const updated = await this.refundService.updateRefundStatus({
        maHoanTien,
        newStatus: trangThai,
        maGiaoDich,
        ghiChu,
        adminSub: Number(user.sub),
      });

      return res.status(200).json({
        status: 'success',
        message: 'Cập nhật trạng thái hoàn tiền thành công',
        data: updated,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Lỗi khi cập nhật trạng thái hoàn tiền',
      });
    }
  };

  /**
   * Khách hàng hoặc Quán bổ sung thông tin tài khoản ngân hàng nhận tiền hoàn
   */
  updateBankInfo = async (req: Request, res: Response) => {
    try {
      const maHoanTien = Number(req.params.id);
      const { nganHang, soTaiKhoan, tenChuTaiKhoan } = req.body;

      if (!nganHang || !soTaiKhoan) {
        return res.status(400).json({ status: 'error', message: 'Vui lòng cung cấp ngân hàng và số tài khoản' });
      }

      const refund = await this.hoanTienRepo.findOne({ where: { maHoanTien } });
      if (!refund) {
        return res.status(404).json({ status: 'error', message: 'Không tìm thấy yêu cầu hoàn tiền' });
      }

      refund.nganHangNhan = nganHang;
      refund.soTaiKhoanNhan = soTaiKhoan;
      if (tenChuTaiKhoan) refund.tenChuTaiKhoanNhan = tenChuTaiKhoan;

      await this.hoanTienRepo.save(refund);

      return res.status(200).json({
        status: 'success',
        message: 'Cập nhật thông tin ngân hàng nhận tiền hoàn thành công',
        data: refund,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi cập nhật thông tin tài khoản ngân hàng',
      });
    }
  };
}
