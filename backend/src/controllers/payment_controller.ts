import { Request, Response } from 'express';
import { AppDataSource } from '../config/database';
import { ThanhToanModel } from '../models/thanh_toan_model';
import { DonHangModel } from '../models/don_hang_model';

export class PaymentController {
  private thanhToanRepo = AppDataSource.getRepository(ThanhToanModel);
  private donHangRepo = AppDataSource.getRepository(DonHangModel);

  verifyPayment = async (req: Request, res: Response) => {
    try {
      const { maDonHang, soTien, phuongThuc } = req.body;
      if (!maDonHang) {
        return res.status(400).json({
          status: 'error',
          message: 'Mã đơn hàng không hợp lệ',
        });
      }

      const order = await this.donHangRepo.findOne({ where: { maDonHang } });
      if (!order) {
        return res.status(404).json({
          status: 'error',
          message: 'Không tìm thấy đơn hàng để xác minh thanh toán',
        });
      }

      // Record / update payment
      let payment = await this.thanhToanRepo.findOne({ where: { maDonHang } });
      if (!payment) {
        payment = this.thanhToanRepo.create({
          maDonHang,
          soTien: soTien || order.tongTien,
          trangThai: 'THANH_TOAN_THANH_CONG',
          loaiThanhToan: phuongThuc || order.phuongThucThanhToan,
          noiDung: `Xác minh thanh toán cho đơn pre-order #${maDonHang}`,
        });
      } else {
        payment.trangThai = 'THANH_TOAN_THANH_CONG';
      }

      await this.thanhToanRepo.save(payment);

      return res.status(200).json({
        status: 'success',
        message: 'Xác minh thanh toán thành công',
        data: {
          maDonHang,
          maThanhToan: payment.maThanhToan,
          trangThaiThanhToan: payment.trangThai,
        },
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi xác minh thanh toán',
      });
    }
  };
}
