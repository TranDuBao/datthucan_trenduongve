import { Request, Response } from 'express';
import { RefundService } from '../services/refund_service';
import { AppDataSource } from '../config/database';
import { CuaHangModel } from '../models/cua_hang_model';
import { HoanTienModel, RefundStatus } from '../models/hoan_tien_model';
import { DonHangModel } from '../models/don_hang_model';
import { KhachHangModel } from '../models/khach_hang_model';

export class RefundController {
  private refundService = RefundService.getInstance();
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private hoanTienRepo = AppDataSource.getRepository(HoanTienModel);
  private donHangRepo = AppDataSource.getRepository(DonHangModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);

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
   * Chi tiết yêu cầu hoàn tiền (Có kiểm tra quyền sở hữu BOLA/IDOR)
   */
  getRefundById = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const maHoanTien = Number(req.params.id);
      if (isNaN(maHoanTien) || maHoanTien <= 0) {
        return res.status(400).json({ status: 'error', message: 'Mã yêu cầu hoàn tiền không hợp lệ' });
      }

      const refund = await this.hoanTienRepo.findOne({ where: { maHoanTien } });
      if (!refund) {
        return res.status(404).json({ status: 'error', message: 'Không tìm thấy yêu cầu hoàn tiền' });
      }

      const userSub = Number(user.sub);
      const userRole = String(user.role || '').toUpperCase();

      if (userRole !== 'ADMIN') {
        const order = await this.donHangRepo.findOne({ where: { maDonHang: refund.maDonHang } });
        if (!order) {
          return res.status(404).json({ status: 'error', message: 'Không tìm thấy yêu cầu hoàn tiền' });
        }

        if (userRole === 'CUAN_HANG' || userRole === 'CUA_HANG' || userRole === 'RESTAURANT' || userRole === 'STORE') {
          const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userSub } });
          if (!store || store.maQuan !== order.maQuan) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy yêu cầu hoàn tiền' });
          }
        } else {
          // Customer Role
          const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
          if (!khachHang || order.maKhachHang !== khachHang.maKhachHang) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy yêu cầu hoàn tiền' });
          }
        }
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
   * Khách hàng bổ sung/cập nhật thông tin tài khoản ngân hàng nhận tiền hoàn (Có kiểm tra quyền sở hữu chặt chẽ)
   */
  updateBankInfo = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user) {
        return res.status(401).json({ status: 'error', message: 'Bạn chưa đăng nhập' });
      }

      const maHoanTien = Number(req.params.id);
      if (isNaN(maHoanTien) || maHoanTien <= 0) {
        return res.status(400).json({ status: 'error', message: 'Mã hoàn tiền không hợp lệ' });
      }

      const { nganHang, soTaiKhoan, tenChuTaiKhoan } = req.body;

      if (!nganHang || typeof nganHang !== 'string' || !nganHang.trim()) {
        return res.status(400).json({ status: 'error', message: 'Vui lòng cung cấp ngân hàng hợp lệ' });
      }
      if (!soTaiKhoan || typeof soTaiKhoan !== 'string' || !soTaiKhoan.trim()) {
        return res.status(400).json({ status: 'error', message: 'Vui lòng cung cấp số tài khoản hợp lệ' });
      }

      const refund = await this.hoanTienRepo.findOne({ where: { maHoanTien } });
      if (!refund) {
        return res.status(404).json({ status: 'error', message: 'Không tìm thấy yêu cầu hoàn tiền' });
      }

      const userSub = Number(user.sub);
      const userRole = String(user.role || '').toUpperCase();

      // Chỉ khách hàng sở hữu đơn hàng hoặc Admin mới có quyền cập nhật tài khoản nhận hoàn tiền
      if (userRole !== 'ADMIN') {
        const order = await this.donHangRepo.findOne({ where: { maDonHang: refund.maDonHang } });
        if (!order) {
          return res.status(404).json({ status: 'error', message: 'Không tìm thấy yêu cầu hoàn tiền' });
        }

        const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
        if (!khachHang || order.maKhachHang !== khachHang.maKhachHang) {
          return res.status(404).json({
            status: 'error',
            message: 'Không tìm thấy yêu cầu hoàn tiền',
          });
        }
      }

      // Không cho phép chỉnh sửa nếu yêu cầu đã hoàn tất thành công
      if (refund.trangThaiHoanTien === 'HOAN_TIEN_THANH_CONG' || refund.trangThaiHoanTien === 'DANG_XU_LY') {
        return res.status(400).json({
          status: 'error',
          message: 'Yêu cầu hoàn tiền đang được xử lý hoặc đã hoàn tất, không thể thay đổi thông tin ngân hàng',
        });
      }

      refund.nganHangNhan = nganHang.trim();
      refund.soTaiKhoanNhan = soTaiKhoan.trim();
      if (tenChuTaiKhoan && typeof tenChuTaiKhoan === 'string') {
        refund.tenChuTaiKhoanNhan = tenChuTaiKhoan.trim();
      }

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
