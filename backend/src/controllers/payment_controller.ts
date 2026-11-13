import { Request, Response } from 'express';
import crypto from 'crypto';
import { AppDataSource } from '../config/database';
import { ThanhToanModel } from '../models/thanh_toan_model';
import { DonHangModel } from '../models/don_hang_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';
import { RealtimeService } from '../services/realtime_service';
import { NotificationService } from '../services/notification_service';
import { PayOSService } from '../services/payos_service';

export class PaymentController {
  private thanhToanRepo = AppDataSource.getRepository(ThanhToanModel);
  private donHangRepo = AppDataSource.getRepository(DonHangModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);

  /**
   * Safe status check endpoint for Frontend (Syncs directly with PayOS gateway)
   * If webhook was delayed or missed, this actively verifies with PayOS and confirms the order immediately!
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

      let payment = await this.thanhToanRepo.findOne({ where: { maDonHang } });

      // Chủ động truy vấn trạng thái từ PayOS nếu đơn chưa được đánh dấu thanh toán thành công
      const isUnpaid = !payment || payment.trangThai === 'CHO_THANH_TOAN' || payment.trangThai === 'PENDING';
      const isPayOSMethod = ['PAYOS', 'VIETQR', 'CHUYEN_KHOAN'].includes(String(order.phuongThucThanhToan || '').toUpperCase()) ||
                            ['PAYOS', 'VIETQR', 'CHUYEN_KHOAN'].includes(String(payment?.loaiThanhToan || '').toUpperCase());

      if (isUnpaid && isPayOSMethod) {
        try {
          const payosCode = Number(payment?.taiKhoanThanhToan || maDonHang);
          const payosInfo = await PayOSService.getPaymentLinkInformation(payosCode);
          if (payosInfo && (payosInfo.status === 'PAID' || (payosInfo.amountPaid > 0 && payosInfo.amountPaid >= Number(order.tongTien)))) {
            console.log(`[PaymentController] [Info] Phát hiện thanh toán thành công từ PayOS cho đơn #${maDonHang}! Cập nhật hệ thống...`);

            await AppDataSource.transaction(async (manager) => {
              let p = await manager.findOne(ThanhToanModel, { where: { maDonHang } });
              const finalAmount = Number(payosInfo.amountPaid || order.tongTien);
              if (!p) {
                p = manager.create(ThanhToanModel, {
                  maDonHang,
                  soTien: finalAmount,
                  trangThai: 'THANH_TOAN_THANH_CONG',
                  loaiThanhToan: order.phuongThucThanhToan || 'PAYOS',
                  ngayThanhToan: new Date(),
                  noiDung: `PayOS xác nhận thanh toán thành công cho đơn #${maDonHang}`,
                });
              } else {
                p.trangThai = 'THANH_TOAN_THANH_CONG';
                p.soTien = finalAmount;
                p.ngayThanhToan = new Date();
                p.noiDung = `PayOS xác nhận thanh toán thành công cho đơn #${maDonHang}`;
              }
              await manager.save(p);
              payment = p;

              // Khôi phục hoặc chuyển trạng thái đơn hàng sang CHO_XAC_NHAN
              if (order.trangThai === 'CHO_THANH_TOAN' || order.trangThai === 'UNPAID' || order.trangThai === 'DA_HUY') {
                order.trangThai = 'CHO_XAC_NHAN';
                order.lyDoHuy = null as any;
                await manager.save(order);
              }
            });

            // 1. Phát sự kiện realtime xác nhận thanh toán
            RealtimeService.getInstance().emitPaymentConfirmed(
              order.maQuan,
              maDonHang,
              payment!.soTien,
              order.maKhachHang
            );

            // 2. Cập nhật trạng thái đơn hàng sang CHO_XAC_NHAN
            RealtimeService.getInstance().emitOrderStatusChanged(
              order.maQuan,
              maDonHang,
              'CHO_XAC_NHAN',
              order.maKhachHang
            );

            // 3. Báo đơn mới cho quán chuẩn bị món
            try {
              const chiTietRepo = AppDataSource.getRepository(ChiTietDonHangModel);
              const items = await chiTietRepo.find({ where: { maDonHang } });
              RealtimeService.getInstance().emitOrderCreated(order.maQuan, maDonHang, {
                maDonHang,
                maKhachHang: order.maKhachHang,
                tongTien: order.tongTien,
                thoiGianHenNhan: order.thoiGianHenNhan,
                itemsCount: items.length,
                status: 'CHO_XAC_NHAN',
              });

              if (order.maQuan) {
                await NotificationService.getInstance().sendNotification({
                  recipientId: order.maQuan,
                  recipientRole: 'restaurant',
                  type: 'order:created',
                  title: 'Đơn hàng mới đã thanh toán',
                  body: `Đơn hàng mới #DH-${maDonHang} (${items.length} món) đã được thanh toán thành công (${Number(payment!.soTien).toLocaleString('vi-VN')}đ). Mời quán chuẩn bị món!`,
                  data: { orderId: maDonHang, maQuan: order.maQuan, status: 'CHO_XAC_NHAN' },
                });
              }
            } catch (_) {}

            // 4. Thông báo cho khách hàng
            if (order.maKhachHang) {
              try {
                await NotificationService.getInstance().sendNotification({
                  recipientId: order.maKhachHang,
                  recipientRole: 'user',
                  type: 'payment:confirmed',
                  title: 'Thanh toán thành công',
                  body: `Đơn hàng #DH-${maDonHang} đã được xác nhận thanh toán thành công (${Number(payment!.soTien).toLocaleString('vi-VN')}đ). Quán đang tiếp nhận đơn.`,
                  data: { orderId: maDonHang, maQuan: order.maQuan },
                });
              } catch (_) {}
            }
          }
        } catch (syncErr: any) {
          console.error(`[PaymentController] [Warn] Lỗi kiểm tra PayOS chủ động cho đơn #${maDonHang}:`, syncErr.message);
        }
      }

      return res.status(200).json({
        status: 'success',
        data: {
          maDonHang,
          orderId: maDonHang,
          trangThaiThanhToan: payment ? payment.trangThai : 'CHO_THANH_TOAN',
          trangThaiDonHang: order.trangThai,
          soTien: payment ? payment.soTien : order.tongTien,
          loaiThanhToan: payment ? payment.loaiThanhToan : order.phuongThucThanhToan,
          ngayThanhToan: payment ? payment.ngayThanhToan : (order.trangThai !== 'CHO_THANH_TOAN' ? new Date().toISOString() : null),
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
      const webhookSecret = process.env.PAYMENT_WEBHOOK_SECRET || process.env.PAYOS_CHECKSUM_KEY;

      if (!webhookSecret) {
        console.error('[PaymentController] [Error] CẢNH BÁO BẢO MẬT: PAYMENT_WEBHOOK_SECRET hoặc PAYOS_CHECKSUM_KEY chưa được cấu hình trong .env!');
        return res.status(500).json({
          status: 'error',
          message: 'Hệ thống chưa thiết lập khóa bảo mật Webhook thanh toán (PAYMENT_WEBHOOK_SECRET / PAYOS_CHECKSUM_KEY)',
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

      console.log('[PaymentController] [Info] [Payment Webhook Received]:', JSON.stringify({
        code: req.body?.code,
        status: req.body?.status || webhookData?.status,
        orderCode: webhookData?.orderCode,
        amount: webhookData?.amount,
        desc: webhookData?.description,
      }));

      let targetOrderId = Number(webhookData.orderCode || webhookData.maDonHang);

      // Fallback: If orderCode is not provided or 0, extract from transfer description (e.g. "DH25")
      if (!targetOrderId || isNaN(targetOrderId) || targetOrderId <= 0) {
        const desc = String(webhookData.description || req.body?.description || '');
        const match = desc.match(/DH\s*(\d+)/i);
        if (match) {
          targetOrderId = Number(match[1]);
        }
      }

      // If signature is valid but targetOrderId is missing/0, it is a PayOS webhook verification ping
      if (!targetOrderId || isNaN(targetOrderId) || targetOrderId <= 0) {
        return res.status(200).json({
          status: 'success',
          message: 'Webhook URL verified successfully by PayOS',
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
        let order = await manager.findOne(DonHangModel, { where: { maDonHang: targetOrderId } });

        // If order not found by orderCode directly, check if targetOrderId matches payment.taiKhoanThanhToan (unique PayOS orderCode)
        if (!order) {
          const matchedPayment = await manager.findOne(ThanhToanModel, { where: { taiKhoanThanhToan: String(targetOrderId) } });
          if (matchedPayment && matchedPayment.maDonHang) {
            targetOrderId = matchedPayment.maDonHang;
            order = await manager.findOne(DonHangModel, { where: { maDonHang: targetOrderId } });
          }
        }

        // If still not found, check if description has DH<id>
        if (!order) {
          const desc = String(webhookData.description || req.body?.description || '');
          const match = desc.match(/DH\s*(\d+)/i);
          if (match) {
            const fallbackId = Number(match[1]);
            if (fallbackId && fallbackId !== targetOrderId) {
              const fallbackOrder = await manager.findOne(DonHangModel, { where: { maDonHang: fallbackId } });
              if (fallbackOrder) {
                targetOrderId = fallbackId;
                order = fallbackOrder;
              }
            }
          }
        }

        if (!order) {
          // Order not found (e.g. PayOS sample test orderCode), return success for test verification
          return { alreadyProcessed: true, payment: null, order: null, isTest: true };
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

        // Idempotency check: If already finalized (success, completed, refunded, or failure), do not process twice
        if (
          payment &&
          (payment.trangThai === 'THANH_TOAN_THANH_CONG' ||
            payment.trangThai === 'DA_THANH_TOAN' ||
            payment.trangThai === 'CHO_HOAN_TIEN' ||
            payment.trangThai === 'DA_HOAN_TIEN' ||
            payment.trangThai === 'THANH_TOAN_THAT_BAI')
        ) {
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

        if (isSuccess) {
          // Transition order from CHO_THANH_TOAN to CHO_XAC_NHAN (Ready for store to accept & prepare)
          if (order.trangThai === 'CHO_THANH_TOAN' || order.trangThai === 'UNPAID' || order.trangThai === 'DA_HUY') {
            order.trangThai = 'CHO_XAC_NHAN';
            order.lyDoHuy = null as any;
            await manager.save(order);
          }
        } else {
          // If payment failed, mark order as DA_HUY
          if (order.trangThai === 'CHO_THANH_TOAN' || order.trangThai === 'CHO_XAC_NHAN' || order.trangThai === 'UNPAID') {
            order.trangThai = 'DA_HUY';
            order.lyDoHuy = 'Thanh toán trực tuyến thất bại';
            await manager.save(order);
          }
        }

        return { alreadyProcessed: false, payment, order };
      });

      if (!result.alreadyProcessed && result.payment && result.order) {
        if (result.payment.trangThai === 'THANH_TOAN_THANH_CONG') {
          // 1. Emit payment confirmed event
          RealtimeService.getInstance().emitPaymentConfirmed(
            result.order.maQuan,
            targetOrderId,
            result.payment.soTien,
            result.order.maKhachHang
          );

          // 2. NOW emit order:created to restaurant because payment is verified!
          try {
            const chiTietRepo = AppDataSource.getRepository(ChiTietDonHangModel);
            const items = await chiTietRepo.find({ where: { maDonHang: targetOrderId } });

            RealtimeService.getInstance().emitOrderCreated(result.order.maQuan, targetOrderId, {
              maDonHang: targetOrderId,
              maKhachHang: result.order.maKhachHang,
              tongTien: result.order.tongTien,
              thoiGianHenNhan: result.order.thoiGianHenNhan,
              itemsCount: items.length,
              status: result.order.trangThai, // 'CHO_XAC_NHAN'
            });

            // 3. Send Notification to Restaurant
            if (result.order.maQuan) {
              await NotificationService.getInstance().sendNotification({
                recipientId: result.order.maQuan,
                recipientRole: 'restaurant',
                type: 'order:created',
                title: 'Đơn hàng mới đã thanh toán',
                body: `Đơn hàng mới #DH-${targetOrderId} (${items.length} món) đã được thanh toán thành công. Tổng tiền: ${Number(result.payment.soTien).toLocaleString('vi-VN')}đ. Mời quán chuẩn bị món!`,
                data: { orderId: targetOrderId, maQuan: result.order.maQuan, status: result.order.trangThai },
              });
            }

            // 4. Send Notification to Admin
            await NotificationService.getInstance().sendNotification({
              recipientId: 0,
              recipientRole: 'admin',
              type: 'order:created',
              title: 'Đơn hàng mới đã thanh toán',
              body: `Đơn hàng #DH-${targetOrderId} tại quán ID ${result.order.maQuan} đã thanh toán thành công (${Number(result.payment.soTien).toLocaleString('vi-VN')}đ).`,
              data: { orderId: targetOrderId, maQuan: result.order.maQuan },
            });

            // 5. Send Notification to Customer
            if (result.order.maKhachHang) {
              await NotificationService.getInstance().sendNotification({
                recipientId: result.order.maKhachHang,
                recipientRole: 'user',
                type: 'payment:confirmed',
                title: 'Thanh toán thành công',
                body: `Đơn hàng #DH-${targetOrderId} đã thanh toán thành công (${Number(result.payment.soTien).toLocaleString('vi-VN')}đ). Quán đang tiếp nhận đơn.`,
                data: { orderId: targetOrderId, maQuan: result.order.maQuan },
              });
            }
          } catch (notifErr) {
            console.error('[PaymentController] Error notifying store after payment:', notifErr);
          }
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
        data: { maDonHang: targetOrderId, trangThai: result.payment?.trangThai || 'TEST_VERIFIED' },
      });
    } catch (error: any) {
      console.error('[PaymentController] [Error] Lỗi xử lý Webhook thanh toán:', error);
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

      if (order.trangThai === 'CHO_THANH_TOAN' || order.trangThai === 'CHO_XAC_NHAN' || order.trangThai === 'UNPAID') {
        order.trangThai = 'DA_XAC_NHAN';
        await this.donHangRepo.save(order);
      }

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
