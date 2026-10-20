import { Request, Response } from 'express';
import { OrderService, normalizeOrderStatus } from '../services/order_service';
import { AppDataSource } from '../config/database';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';

export class OrderController {
  private orderService = new OrderService();
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);

  createOrder = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      const userSub = user?.sub ? Number(user.sub) : undefined;
      const order = await this.orderService.createPreOrder(req.body, userSub);
      return res.status(201).json({
        status: 'success',
        message: 'Tạo đơn hàng pre-order thành công',
        data: order,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Không thể tạo đơn hàng pre-order',
      });
    }
  };

  getMyOrders = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({
          status: 'error',
          message: 'Bạn cần đăng nhập để xem danh sách đơn hàng',
        });
      }

      const userSub = Number(user.sub);
      const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
      if (!khachHang) {
        return res.status(200).json({
          status: 'success',
          data: [],
        });
      }

      const orders = await this.orderService.getMyOrders(khachHang.maKhachHang);
      return res.status(200).json({
        status: 'success',
        data: orders,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi hệ thống khi lấy danh sách đơn hàng',
      });
    }
  };

  getOrderById = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({
          status: 'error',
          message: 'Bạn cần đăng nhập để xem đơn hàng',
        });
      }

      const maDonHang = Number(req.params.id);
      if (!maDonHang || isNaN(maDonHang)) {
        return res.status(400).json({
          status: 'error',
          message: 'Mã đơn hàng không hợp lệ',
        });
      }

      const order = await this.orderService.getOrderById(maDonHang);
      if (!order) {
        return res.status(404).json({
          status: 'error',
          message: 'Không tìm thấy đơn hàng',
        });
      }

      const userSub = Number(user.sub);
      const role = String(user.role || '').toUpperCase();

      if (role !== 'ADMIN') {
        if (role === 'RESTAURANT' || role === 'STORE' || role === 'CUAN_HANG' || role === 'CUA_HANG') {
          const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userSub } });
          if (!store || store.maQuan !== order.maQuan) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng' });
          }
        } else {
          const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
          if (!khachHang || order.maKhachHang !== khachHang.maKhachHang) {
            return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng' });
          }
        }
      }

      return res.status(200).json({
        status: 'success',
        data: order,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi lấy thông tin đơn hàng',
      });
    }
  };

  updateStatus = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({
          status: 'error',
          message: 'Bạn cần đăng nhập để thực hiện thao tác này',
        });
      }

      const maDonHang = Number(req.params.id);
      if (!maDonHang || isNaN(maDonHang)) {
        return res.status(400).json({
          status: 'error',
          message: 'Mã đơn hàng không hợp lệ',
        });
      }

      const { status, lyDo, reason } = req.body;
      if (!status || typeof status !== 'string' || !status.trim()) {
        return res.status(400).json({
          status: 'error',
          message: 'Trạng thái mới không hợp lệ',
        });
      }

      const order = await this.orderService.getOrderById(maDonHang);
      if (!order) {
        return res.status(404).json({ status: 'error', message: 'Không tìm thấy đơn hàng' });
      }

      const userSub = Number(user.sub);
      const userRole = String(user.role || '').toUpperCase();
      const targetStatus = normalizeOrderStatus(status);

      // Ownership & Status Transition Validations (BOLA Prevention)
      if (userRole === 'ADMIN') {
        // Admin has full authorization
      } else if (userRole === 'CUAN_HANG' || userRole === 'CUA_HANG' || userRole === 'RESTAURANT' || userRole === 'STORE') {
        const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userSub } });
        if (!store || store.maQuan !== order.maQuan) {
          return res.status(404).json({
            status: 'error',
            message: 'Không tìm thấy đơn hàng',
          });
        }

        const allowedStoreTransitions = ['DA_XAC_NHAN', 'DANG_CHUAN_BI', 'SAN_SANG', 'HOAN_TAT', 'DA_HUY'];
        if (!allowedStoreTransitions.includes(targetStatus)) {
          return res.status(400).json({
            status: 'error',
            message: `Cửa hàng không thể chuyển đơn sang trạng thái "${targetStatus}"`,
          });
        }
      } else {
        // Customer Role
        const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
        if (!khachHang || order.maKhachHang !== khachHang.maKhachHang) {
          return res.status(404).json({
            status: 'error',
            message: 'Không tìm thấy đơn hàng',
          });
        }

        // Customers can ONLY cancel ('DA_HUY') their own pending order
        if (targetStatus !== 'DA_HUY') {
          return res.status(403).json({
            status: 'error',
            message: 'Khách hàng chỉ có quyền hủy đơn hàng',
          });
        }

        const currentOrderStatus = normalizeOrderStatus(order.trangThai);
        if (currentOrderStatus !== 'CHO_XAC_NHAN') {
          return res.status(400).json({
            status: 'error',
            message: 'Đơn hàng đã được xác nhận hoặc đang chế biến, không thể hủy!',
          });
        }
      }

      const updatedBy = (userRole === 'CUAN_HANG' || userRole === 'CUA_HANG' || userRole === 'ADMIN') ? 'restaurant' : 'user';
      const cancellationReason = lyDo || reason || (updatedBy === 'user' ? 'Khách hàng hủy đơn' : 'Quán hủy đơn');

      const updatedOrder = await this.orderService.updateOrderStatus(
        maDonHang,
        targetStatus,
        cancellationReason,
        updatedBy
      );
      return res.status(200).json({
        status: 'success',
        message: 'Cập nhật trạng thái đơn hàng thành công',
        data: updatedOrder,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Lỗi khi cập nhật trạng thái đơn hàng',
      });
    }
  };

  updateOrderStatus = this.updateStatus;
}
