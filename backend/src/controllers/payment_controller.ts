import { Request, Response } from 'express';
import crypto from 'crypto';
import { AppDataSource } from '../config/database';
import { ThanhToanModel } from '../models/thanh_toan_model';
import { DonHangModel } from '../models/don_hang_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { RealtimeService } from '../services/realtime_service';
import { NotificationService } from '../services/notification_service';

export class PaymentController {
  private thanhToanRepo = AppDataSource.getRepository(ThanhToanModel);
  private donHangRepo = AppDataSource.getRepository(DonHangModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);

  /**
   * Safe status check endpoint for Frontend (Read-only, cannot mutate payment state)
   */
  getPaymentStatus = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({
          status: 'error',
          message: 'Bạn cần đăng nhập để thực hiện chức năng này',
        });
      }

      const maDonHang = Number(req.params.id || req.body.maDonHang || req.query.maDonHang);
      if (isNaN(maDonHang) || maDonHang <= 0) {
        return res.status(400).json({
          status: 'error',
          message: 'Mã đơn hàng không hợp lệ',
        });
      }

      const order = await this.donHangRepo.findOne({ where: { maDonHang } });
      if (!order) {
        return res.status(404).json({
          status: 'error',
          message: 'Không tìm thấy đơn hàng',
        });
      }

      // Authorization & Ownership Check
      const userSub = Number(user.sub);
      const role = String(user.role || '').toUpperCase();

      if (role !== 'ADMIN') {
        if (role === 'CUAN_HANG' || role === 'CUA_HANG') {
          const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userSub } });
          if (!store || store.maQuan !== order.maQuan) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng' });
          }
        } else {
          // Customer Role
          const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
          if (!khachHang || order.maKhachHang !== khachHang.maKhachHang) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng' });
          }
        }
      }

      const payment = await this.thanhToanRepo.findOne({ where: { maDonHang } });

      return res.status(200).json({
        status: 'success',
        data: {
          maDonHang,
          trangThaiThanhToan: payment ? payment.trangThai : 'CHO_THANH_TOAN',
          soTien: payment ? payment.soTien : order.tongTien,
          loaiThanhToan: payment ? payment.loaiThanhToan : order.phuongThucThanhToan,
          ngayThanhToan: payment ? payment.ngayThanhToan : null,
        },
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi kiểm tra trạng thái thanh toán',
      });
    }
  };

  /**
   * Payment Provider Webhook Callback (Server-to-Server with Signature & Idempotency)
   * Follows PayOS official checksum specification and raw HMAC verification.
   * NEVER falls back to JWT_SECRET.
   */
  handleWebhook = async (req: Request, res: Response) => {
    try {
      const webhookSecret = process.env.PAYMENT_WEBHOOK_SECRET;

      if (!webhookSecret) {
        console.error('❌ CẢNH BÁO BẢO MẬT: PAYMENT_WEBHOOK_SECRET chưa được cấu hình trong .env!');
        return res.status(500).json({
          status: 'error',
          message: 'Hệ thống chưa thiết lập khóa bảo mật Webhook thanh toán (PAYMENT_WEBHOOK_SECRET)',
        });
      }

      const signatureHeader = (req.headers['x-webhook-signature'] ||
        req.headers['x-payos-signature'] ||
        req.body?.signature) as string | undefined;

      if (!signatureHeader || typeof signatureHeader !== 'string' || !signatureHeader.trim()) {
        return res.status(401).json({
          status: 'error',
          message: 'Thiếu chữ ký xác thực Webhook (Signature required)',
        });
      }

      const verifyTimingSafe = (receivedSig: string, expectedSig: string): boolean => {
        try {
          const sigBuf = Buffer.from(receivedSig.trim());
          const expBuf = Buffer.from(expectedSig.trim());
          return sigBuf.length === expBuf.length && crypto.timingSafeEqual(sigBuf, expBuf);
        } catch {
          return false;
        }
      };

      let isSignatureValid = false;

      // 1. Verify against PayOS official data structure (req.body.data sorted query string)
      if (req.body?.data && typeof req.body.data === 'object') {
        const sortedKeys = Object.keys(req.body.data).sort();
        const parts: string[] = [];
        for (const k of sortedKeys) {
          const val = req.body.data[k];
          if (val !== undefined && val !== null) {
            let strVal = val;
            if (typeof val === 'object') {
              strVal = JSON.stringify(val);
            }
            parts.push(`${k}=${strVal}`);
          }
        }
        const payOSQueryStr = parts.join('&');
        const expectedPayOSSig = crypto.createHmac('sha256', webhookSecret).update(payOSQueryStr).digest('hex');
        if (verifyTimingSafe(signatureHeader, expectedPayOSSig)) {
          isSignatureValid = true;
        }
      }

      // 2. General webhook rawBody HMAC-SHA256 verification
      if (!isSignatureValid) {
        const rawBuffer =
          (req as any).rawBody ||
          Buffer.from(typeof req.body === 'string' ? req.body : JSON.stringify(req.body));
        const expectedRawSig = crypto.createHmac('sha256', webhookSecret).update(rawBuffer).digest('hex');
        if (verifyTimingSafe(signatureHeader, expectedRawSig)) {
          isSignatureValid = true;
        }
      }

      if (!isSignatureValid) {
        return res.status(400).json({
          status: 'error',
          message: 'Chữ ký Webhook không hợp lệ (Signature verification failed)',
        });
      }

      const webhookData =
        req.body?.data && typeof req.body.data === 'object' ? req.body.data : req.body;
      const targetOrderId = Number(webhookData.orderCode || webhookData.maDonHang);

      if (!targetOrderId || isNaN(targetOrderId) || targetOrderId <= 0) {
        return res.status(400).json({
          status: 'error',
          message: 'Mã đơn hàng không hợp lệ trong webhook payload',
        });
      }

      const amount = webhookData.amount;
      const isSuccess =
        req.body.code === '00' ||
        req.body.status === 'PAID' ||
        req.body.status === 'SUCCESS' ||
        webhookData.code === '00' ||
        webhookData.status === 'PAID' ||
        webhookData.status === 'SUCCESS' ||
        req.body.success === true;

      // Idempotent Transaction Execution
      const result = await AppDataSource.transaction(async (manager) => {
        const order = await manager.findOne(DonHangModel, { where: { maDonHang: targetOrderId } });
        if (!order) {
          throw new Error('Đơn hàng không tồn tại');
        }

        // Strict Amount Matching Check: Prevent underpayment tampering
        if (isSuccess && amount !== undefined && amount !== null) {
          const paidAmount = Number(amount);
          const expectedTotal = Number(order.tongTien);
          if (paidAmount < expectedTotal) {
            throw new Error(
              `Số tiền thanh toán (${paidAmount}) không đủ so với tổng tiền đơn hàng (${expectedTotal})`
            );
          }
        }

        let payment = await manager.findOne(ThanhToanModel, { where: { maDonHang: targetOrderId } });

        // Idempotency check: If already finalized (success or failure), do not process twice
        if (payment && (payment.trangThai === 'THANH_TOAN_THANH_CONG' || payment.trangThai === 'THANH_TOAN_THAT_BAI')) {
          return { alreadyProcessed: true, payment, order };
        }

        const newStatus = isSuccess ? 'THANH_TOAN_THANH_CONG' : 'THANH_TOAN_THAT_BAI';
        const finalAmount = Number(amount || order.tongTien);

        if (!payment) {
          payment = manager.create(ThanhToanModel, {
            maDonHang: targetOrderId,
            soTien: finalAmount,
            trangThai: newStatus,
            loaiThanhToan: order.phuongThucThanhToan || 'PAYOS',
            noiDung: `Webhook xác nhận thanh toán cho đơn #${targetOrderId}`,
          });
        } else {
          payment.trangThai = newStatus;
          payment.soTien = finalAmount;
        }

        await manager.save(payment);

        if (!isSuccess && order.trangThai === 'CHO_XAC_NHAN') {
          order.trangThai = 'DA_HUY';
          order.lyDoHuy = 'Thanh toán trực tuyến thất bại';
          await manager.save(order);
        }

        return { alreadyProcessed: false, payment, order };
      });

      if (!result.alreadyProcessed) {
        if (result.payment.trangThai === 'THANH_TOAN_THANH_CONG') {
          RealtimeService.getInstance().emitPaymentConfirmed(
            result.order.maQuan,
            targetOrderId,
            result.payment.soTien,
            result.order.maKhachHang
          );
        } else if (result.payment.trangThai === 'THANH_TOAN_THAT_BAI') {
          try {
            const { OrderService } = await import('../services/order_service');
            await new OrderService().rollbackInventoryAndVoucher(targetOrderId);
          } catch (e) {
            console.error('[PaymentController] Error rolling back failed payment order:', e);
          }
        }
      }

      return res.status(200).json({
        status: 'success',
        message: 'Xử lý webhook thanh toán thành công',
        data: { maDonHang: targetOrderId, trangThai: result.payment.trangThai },
      });
    } catch (error: any) {
      console.error('❌ Lỗi xử lý Webhook thanh toán:', error);
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi xử lý Webhook thanh toán',
      });
    }
  };

  /**
   * Store Owner / Admin manual payment confirmation for Cash On Delivery (COD)
   */
  confirmStorePayment = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn cần đăng nhập' });
      }

      const maDonHang = Number(req.body.maDonHang);
      if (!maDonHang || isNaN(maDonHang)) {
        return res.status(400).json({ status: 'error', message: 'Mã đơn hàng không hợp lệ' });
      }

      const order = await this.donHangRepo.findOne({ where: { maDonHang } });
      if (!order) {
        return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng' });
      }

      const userSub = Number(user.sub);
      const role = String(user.role || '').toUpperCase();

      if (role !== 'ADMIN') {
        const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userSub } });
        if (!store || store.maQuan !== order.maQuan) {
          return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng' });
        }
      }

      let payment = await this.thanhToanRepo.findOne({ where: { maDonHang } });
      if (!payment) {
        payment = this.thanhToanRepo.create({
          maDonHang,
          soTien: order.tongTien,
          trangThai: 'THANH_TOAN_THANH_CONG',
          loaiThanhToan: order.phuongThucThanhToan || 'COD',
          noiDung: `Nhà hàng xác nhận thanh toán trực tiếp cho đơn #${maDonHang}`,
        });
      } else {
        payment.trangThai = 'THANH_TOAN_THANH_CONG';
      }

      await this.thanhToanRepo.save(payment);

      RealtimeService.getInstance().emitPaymentConfirmed(
        order.maQuan,
        maDonHang,
        payment.soTien,
        order.maKhachHang
      );

      if (order.maKhachHang) {
        try {
          await NotificationService.getInstance().sendNotification({
            recipientId: order.maKhachHang,
            recipientRole: 'user',
            type: 'payment:confirmed',
            title: 'Thanh toán thành công',
            body: `Đơn hàng #DH-${maDonHang} đã được xác nhận thanh toán thành công (${Number(payment.soTien).toLocaleString('vi-VN')}đ).`,
            data: { orderId: maDonHang, maQuan: order.maQuan },
          });
        } catch (_) {}
      }

      return res.status(200).json({
        status: 'success',
        message: 'Xác nhận thanh toán đơn hàng thành công',
        data: payment,
      });
    } catch (error: any) {
      return res.status(500).json({ status: 'error', message: error.message || 'Lỗi khi xác nhận thanh toán' });
    }
  };
}
