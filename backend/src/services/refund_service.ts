import { In, Not } from 'typeorm';
import { AppDataSource } from '../config/database';
import { DonHangModel } from '../models/don_hang_model';
import { ThanhToanModel } from '../models/thanh_toan_model';
import { HoanTienModel, RefundStatus } from '../models/hoan_tien_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { RealtimeService } from './realtime_service';
import { NotificationService } from './notification_service';
import { OrderService, normalizeOrderStatus } from './order_service';

export interface CancelAndRefundParams {
  maDonHang: number;
  requesterRole: 'user' | 'restaurant' | 'admin';
  requesterSub?: number;
  maQuan?: number;
  reason?: string;
  bankInfo?: {
    bankName?: string;
    accountNumber?: string;
    accountName?: string;
  };
}

export class RefundService {
  private static instance: RefundService;

  static getInstance(): RefundService {
    if (!RefundService.instance) {
      RefundService.instance = new RefundService();
    }
    return RefundService.instance;
  }

  /**
   * Hủy đơn và xử lý hoàn tiền thống nhất cho cả Khách hàng và Cửa hàng
   */
  async cancelAndProcessRefund(params: CancelAndRefundParams) {
    const { maDonHang, requesterRole, requesterSub, maQuan, reason, bankInfo } = params;

    const donHangRepo = AppDataSource.getRepository(DonHangModel);
    const khachHangRepo = AppDataSource.getRepository(KhachHangModel);
    const storeRepo = AppDataSource.getRepository(CuaHangModel);

    // 1. Kiểm tra đơn hàng tồn tại
    const order = await donHangRepo.findOne({ where: { maDonHang } });
    if (!order) {
      throw new Error('Không tìm thấy đơn hàng');
    }

    // 2. Xác thực quyền sở hữu (BOLA Prevention)
    if (requesterRole === 'admin') {
      // Admin has full access
    } else if (requesterRole === 'restaurant') {
      if (maQuan) {
        if (order.maQuan !== maQuan) {
          throw new Error('Bạn không có quyền thao tác trên đơn hàng của quán khác');
        }
      } else if (requesterSub) {
        const store = await storeRepo.findOne({ where: { maTaiKhoan: requesterSub } });
        if (!store || store.maQuan !== order.maQuan) {
          throw new Error('Bạn không có quyền thao tác trên đơn hàng của quán khác');
        }
      } else {
        throw new Error('Không xác định được danh tính nhà hàng');
      }
    } else {
      // Customer role
      if (!requesterSub) throw new Error('Không xác định được danh tính khách hàng');
      const khachHang = await khachHangRepo.findOne({ where: { maTaiKhoan: requesterSub } });
      if (!khachHang || order.maKhachHang !== khachHang.maKhachHang) {
        throw new Error('Bạn không có quyền hủy đơn hàng của người khác');
      }
    }

    const currentStatus = normalizeOrderStatus(order.trangThai);
    if (currentStatus === 'DA_HUY') {
      throw new Error('Đơn hàng này đã bị hủy trước đó');
    }

    // 3. Kiểm tra điều kiện hủy theo vai trò
    if (requesterRole === 'user') {
      // Khách hàng chỉ được hủy khi đơn chưa làm món: CHO_THANH_TOAN hoặc CHO_XAC_NHAN
      if (currentStatus !== 'CHO_THANH_TOAN' && currentStatus !== 'CHO_XAC_NHAN') {
        throw new Error('Đơn hàng đã được quán xác nhận hoặc đang chế biến, khách hàng không thể hủy');
      }
    } else if (requesterRole === 'restaurant') {
      // Quán không thể hủy đơn đã hoàn tất
      if (currentStatus === 'HOAN_TAT') {
        throw new Error('Đơn hàng đã hoàn tất, không thể hủy');
      }
    }

    const cancellationReason = reason?.trim() || (requesterRole === 'user' ? 'Khách hàng yêu cầu hủy đơn' : 'Cửa hàng hủy đơn');

    // 4. Thực thi Transaction đảm bảo tính toàn vẹn (ACID) và chống hoàn tiền trùng
    const result = await AppDataSource.transaction(async (manager) => {
      // Khóa bản ghi đơn hàng để tránh race condition
      const lockedOrder = await manager.findOne(DonHangModel, {
        where: { maDonHang },
        lock: { mode: 'pessimistic_write' },
      });

      if (!lockedOrder) throw new Error('Không tìm thấy đơn hàng khi khóa giao dịch');
      const latestStatus = normalizeOrderStatus(lockedOrder.trangThai);
      if (latestStatus === 'DA_HUY') {
        throw new Error('Đơn hàng đã bị hủy bởi một thao tác khác');
      }

      // Kiểm tra thanh toán thực tế trong CSDL
      const payment = await manager.findOne(ThanhToanModel, { where: { maDonHang } });
      const isPaid = payment && payment.trangThai === 'THANH_TOAN_THANH_CONG';

      let refundRecord: HoanTienModel | null = null;

      // 5. Nếu đơn ĐÃ THANH TOÁN -> Khởi tạo yêu cầu hoàn tiền
      if (isPaid) {
        // Kiểm tra chống hoàn trùng: Đã có yêu cầu hoàn tiền chưa?
        const existingRefund = await manager.findOne(HoanTienModel, {
          where: { maDonHang, trangThaiHoanTien: Not(RefundStatus.FAILED) },
        });

        if (existingRefund) {
          throw new Error(`Đơn hàng #${maDonHang} đã có yêu cầu hoàn tiền đang được xử lý (Mã: #${existingRefund.maHoanTien})`);
        }

        // Lấy số tiền hoàn CHÍNH XÁC từ Database, không lấy từ client!
        const refundAmount = Number(payment.soTien);
        if (isNaN(refundAmount) || refundAmount <= 0) {
          throw new Error('Số tiền thanh toán không hợp lệ để hoàn tiền');
        }

        // Tạo bản ghi Hoàn tiền với trạng thái CHỜ XỬ LÝ / CẦN ĐỐI SOÁT
        refundRecord = manager.create(HoanTienModel, {
          maDonHang,
          maThanhToan: payment.maThanhToan,
          soTienHoan: refundAmount,
          lyDoHoan: cancellationReason,
          nguoiYeuCau: requesterRole === 'user' ? 'KHACH_HANG' : (requesterRole === 'restaurant' ? 'CUA_HANG' : 'ADMIN'),
          trangThaiHoanTien: RefundStatus.REVIEW_REQUIRED, // Chờ đối soát và chi trả qua ngân hàng
          phuongThucHoan: 'PAYOS_PAYOUT',
          nganHangNhan: bankInfo?.bankName || payment.taiKhoanThanhToan || null,
          soTaiKhoanNhan: bankInfo?.accountNumber || payment.taiKhoanThanhToan || null,
          tenChuTaiKhoanNhan: bankInfo?.accountName || null,
          ghiChu: `Tạo yêu cầu hoàn tiền tự động khi đơn #${maDonHang} bị hủy`,
        });

        await manager.save(refundRecord);

        // Đổi trạng thái thanh toán thành CHO_HOAN_TIEN
        payment.trangThai = 'CHO_HOAN_TIEN';
        await manager.save(payment);
      }

      // 6. Cập nhật trạng thái đơn hàng thành DA_HUY
      lockedOrder.trangThai = 'DA_HUY';
      lockedOrder.lyDoHuy = cancellationReason;
      await manager.save(lockedOrder);

      return { order: lockedOrder, payment, refund: refundRecord, isPaid };
    });

    // 7. Rollback số lượng món và voucher (ngoài transaction chính để tránh lock kéo dài)
    try {
      await new OrderService().rollbackInventoryAndVoucher(maDonHang);
    } catch (e) {
      console.error('[RefundService] Error rolling back stock/voucher:', e);
    }

    // 8. Thông báo Realtime qua Socket và Push Notification
    try {
      const store = result.order.maQuan ? await storeRepo.findOne({ where: { maQuan: result.order.maQuan } }) : null;
      const tenQuan = store?.tenQuan || 'Cửa hàng';

      // Socket Order status changed: Chỉ báo cho quán nếu đơn này đã được thanh toán (quán đã tiếp nhận)
      if (result.isPaid && result.order.maQuan) {
        RealtimeService.getInstance().emitOrderStatusChanged(
          result.order.maQuan,
          maDonHang,
          'DA_HUY',
          result.order.maKhachHang
        );
      } else {
        // Đơn chưa thanh toán mà hủy: Chỉ gửi cho khách hàng và room đơn hàng, KHÔNG gửi cho web/app quán
        const io = RealtimeService.getInstance().getIO();
        const cancelPayload = {
          id: maDonHang,
          orderId: maDonHang,
          maDonHang: maDonHang,
          status: 'DA_HUY',
          trangThai: 'DA_HUY',
          updatedAt: new Date().toISOString(),
        };
        io?.to(`order:${maDonHang}`).emit('order:status_changed', cancelPayload);
        if (result.order.maKhachHang) {
          io?.to(`customer:${result.order.maKhachHang}`).emit('order:status_changed', cancelPayload);
        }
      }

      // Socket Refund event nếu có hoàn tiền
      if (result.refund) {
        RealtimeService.getInstance().getIO()?.emit('refund:created', {
          maHoanTien: result.refund.maHoanTien,
          maDonHang: result.refund.maDonHang,
          soTienHoan: result.refund.soTienHoan,
          trangThai: result.refund.trangThaiHoanTien,
          nguoiYeuCau: result.refund.nguoiYeuCau,
        });
      }

      // Gửi Notification
      const amountStr = result.refund ? `${Number(result.refund.soTienHoan).toLocaleString('vi-VN')}đ` : '';

      // Khách hủy đơn: Chỉ thông báo quán NẾU đơn đã thanh toán (quán đã có đơn cần làm)
      if (requesterRole === 'user' && result.order.maQuan && result.isPaid) {
        await NotificationService.getInstance().sendNotification({
          recipientId: result.order.maQuan,
          recipientRole: 'restaurant',
          type: 'order:cancelled',
          title: 'Khách hàng hủy đơn',
          body: `Khách hàng đã hủy đơn #${maDonHang}. Yêu cầu hoàn tiền ${amountStr} đã được tiếp nhận. Lý do: ${cancellationReason}`,
          data: { orderId: maDonHang, maQuan: result.order.maQuan, status: 'DA_HUY' },
        });
      } else if (result.order.maKhachHang) {
        // Quán hủy -> Thông báo khách
        await NotificationService.getInstance().sendNotification({
          recipientId: result.order.maKhachHang,
          recipientRole: 'user',
          type: 'order:cancelled',
          title: 'Đơn hàng đã bị hủy',
          body: `${tenQuan} đã hủy đơn #${maDonHang}.${result.isPaid ? ` Hệ thống đang xử lý hoàn trả ${amountStr} về tài khoản của bạn.` : ''} Lý do: ${cancellationReason}`,
          data: { orderId: maDonHang, maQuan: result.order.maQuan, status: 'DA_HUY' },
        });
      }

      // Thông báo Admin để đối soát hoàn tiền
      if (result.refund) {
        await NotificationService.getInstance().sendNotification({
          recipientId: 0,
          recipientRole: 'admin',
          type: 'refund:created',
          title: 'Yêu cầu hoàn tiền mới',
          body: `Đơn #${maDonHang} vừa bị hủy. Yêu cầu hoàn tiền ${amountStr} cần đối soát xử lý.`,
          data: { orderId: maDonHang, maHoanTien: result.refund.maHoanTien },
        });
      }
    } catch (notifErr) {
      console.error('[RefundService] Error sending notifications:', notifErr);
    }

    return {
      order: result.order,
      refund: result.refund,
      message: result.isPaid
        ? `Hủy đơn thành công. Đã tạo yêu cầu hoàn trả ${Number(result.refund?.soTienHoan).toLocaleString('vi-VN')}đ cho khách hàng.`
        : 'Hủy đơn hàng thành công (Đơn chưa thanh toán nên không phát sinh hoàn tiền).',
    };
  }

  /**
   * Admin hoặc Quán cập nhật trạng thái hoàn tiền (Xác nhận đã chuyển khoản thành công)
   */
  async updateRefundStatus(params: {
    maHoanTien: number;
    newStatus: string;
    maGiaoDich?: string;
    ghiChu?: string;
    adminSub?: number;
  }) {
    const { maHoanTien, newStatus, maGiaoDich, ghiChu } = params;
    const hoanTienRepo = AppDataSource.getRepository(HoanTienModel);
    const thanhToanRepo = AppDataSource.getRepository(ThanhToanModel);

    const refund = await hoanTienRepo.findOne({ where: { maHoanTien } });
    if (!refund) {
      throw new Error('Không tìm thấy yêu cầu hoàn tiền');
    }

    refund.trangThaiHoanTien = newStatus;
    if (maGiaoDich) refund.maGiaoDichPayOS = maGiaoDich;
    if (ghiChu) refund.ghiChu = ghiChu;

    if (newStatus === RefundStatus.REFUNDED) {
      refund.thoiGianHoan = new Date();
      // Đồng bộ sang bảng thanh toán
      if (refund.maDonHang) {
        const payment = await thanhToanRepo.findOne({ where: { maDonHang: refund.maDonHang } });
        if (payment) {
          payment.trangThai = 'DA_HOAN_TIEN';
          await thanhToanRepo.save(payment);
        }
      }
    }

    await hoanTienRepo.save(refund);

    // Bắn sự kiện realtime
    RealtimeService.getInstance().getIO()?.emit('refund:status_changed', {
      maHoanTien: refund.maHoanTien,
      maDonHang: refund.maDonHang,
      trangThai: refund.trangThaiHoanTien,
    });

    return refund;
  }

  /**
   * Lấy danh sách hoàn tiền (dành cho Admin và Cửa hàng)
   */
  async getRefundsList(filter?: { maQuan?: number; trangThai?: string }) {
    const hoanTienRepo = AppDataSource.getRepository(HoanTienModel);
    const query = hoanTienRepo.createQueryBuilder('h')
      .leftJoinAndSelect('donhang', 'd', 'h.madonhang = d.madonhang')
      .orderBy('h.thoigianyeucau', 'DESC');

    if (filter?.maQuan) {
      query.andWhere('d.maquan = :maQuan', { maQuan: filter.maQuan });
    }
    if (filter?.trangThai) {
      query.andWhere('h.trangthaihoanTien = :trangThai', { trangThai: filter.trangThai });
    }

    return await query.getRawMany();
  }

  /**
   * Lấy thông tin hoàn tiền theo mã đơn hàng
   */
  async getRefundByOrderId(maDonHang: number) {
    const hoanTienRepo = AppDataSource.getRepository(HoanTienModel);
    return await hoanTienRepo.findOne({ where: { maDonHang } });
  }
}
