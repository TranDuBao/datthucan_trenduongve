import { Request, Response } from 'express';
import { OrderService } from '../services/order_service';

export class OrderController {
  private orderService = new OrderService();

  createOrder = async (req: Request, res: Response) => {
    try {
      const order = await this.orderService.createPreOrder(req.body);
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
      const maKhachHang = Number(req.query.maKhachHang) || 1;
      const orders = await this.orderService.getMyOrders(maKhachHang);
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
      const maDonHang = Number(req.params.id);
      const order = await this.orderService.getOrderById(maDonHang);
      if (!order) {
        return res.status(404).json({
          status: 'error',
          message: 'Không tìm thấy đơn hàng',
        });
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
      const maDonHang = Number(req.params.id);
      const { status } = req.body;
      if (!status) {
        return res.status(400).json({
          status: 'error',
          message: 'Trạng thái mới không được để trống',
        });
      }

      const updated = await this.orderService.updateOrderStatus(maDonHang, status);
      return res.status(200).json({
        status: 'success',
        message: 'Cập nhật trạng thái đơn hàng thành công',
        data: updated,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi cập nhật trạng thái đơn',
      });
    }
  };
}
