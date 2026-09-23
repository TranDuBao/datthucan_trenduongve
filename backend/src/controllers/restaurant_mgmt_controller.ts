import { Response } from 'express';
import { RestaurantMgmtService } from '../services/restaurant_mgmt_service';
import { StoreAuthenticatedRequest } from '../middlewares/role_middleware';

export class RestaurantMgmtController {
  private service = new RestaurantMgmtService();

  private getStoreId(req: StoreAuthenticatedRequest): number {
    const maQuan = req.maQuan || Number(req.query.maQuan || req.body.maQuan);
    if (!maQuan) {
      throw new Error('Tài khoản chưa được gán nhà hàng quản lý');
    }
    return maQuan;
  }

  getDashboardStats = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const stats = await this.service.getDashboardStats(maQuan);
      return res.status(200).json({ statusCode: 200, status: '1', data: stats });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getOrders = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const status = String(req.query.status || '');
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;

      const result = await this.service.getOrders(maQuan, status, page, limit);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateOrderStatus = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const maDonHang = Number(req.params.id);
      const { trangThai } = req.body;

      if (!trangThai) {
        return res.status(400).json({ statusCode: 400, message: 'Vui lòng cung cấp trạng thái mới' });
      }

      const updated = await this.service.updateOrderStatus(maQuan, maDonHang, trangThai);
      return res.status(200).json({ statusCode: 200, status: '1', data: updated, message: 'Cập nhật trạng thái đơn thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getCategories = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const categories = await this.service.getCategories(maQuan);
      return res.status(200).json({ statusCode: 200, status: '1', data: categories });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getMenu = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const menu = await this.service.getMenu(maQuan);
      return res.status(200).json({ statusCode: 200, status: '1', data: menu });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  createFoodItem = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const food = await this.service.createFoodItem(maQuan, req.body);
      return res.status(201).json({ statusCode: 201, status: '1', data: food, message: 'Thêm món mới thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateFoodItem = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const maMonAn = Number(req.params.id);
      const updated = await this.service.updateFoodItem(maQuan, maMonAn, req.body);
      return res.status(200).json({ statusCode: 200, status: '1', data: updated, message: 'Cập nhật món thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  deleteFoodItem = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const maMonAn = Number(req.params.id);
      await this.service.deleteFoodItem(maQuan, maMonAn);
      return res.status(200).json({ statusCode: 200, status: '1', message: 'Xóa món thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getStoreProfile = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const profile = await this.service.getStoreProfile(maQuan);
      return res.status(200).json({ statusCode: 200, status: '1', data: profile });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateStoreProfile = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const updated = await this.service.updateStoreProfile(maQuan, req.body);
      return res.status(200).json({ statusCode: 200, status: '1', data: updated, message: 'Cập nhật thông tin nhà hàng thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };
}
