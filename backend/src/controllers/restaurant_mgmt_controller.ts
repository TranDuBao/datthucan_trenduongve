import { Response } from 'express';
import { RestaurantMgmtService } from '../services/restaurant_mgmt_service';
import { AdminService } from '../services/admin_service';
import { StoreAuthenticatedRequest } from '../middlewares/role_middleware';

export class RestaurantMgmtController {
  private service = new RestaurantMgmtService();
  private adminService = new AdminService();

  private getStoreId(req: StoreAuthenticatedRequest): number {
    const maQuan = req.maQuan;
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

  getRevenueAnalytics = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const period = String(req.query.period || '7days');
      const from = req.query.from ? String(req.query.from) : undefined;
      const to = req.query.to ? String(req.query.to) : undefined;

      const analytics = await this.service.getRevenueAnalytics(maQuan, period, from, to);
      return res.status(200).json({ statusCode: 200, status: '1', data: analytics });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getOrders = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const status = req.query.status ? String(req.query.status) : '';
      const period = req.query.period ? String(req.query.period) : undefined;
      const from = req.query.from ? String(req.query.from) : undefined;
      const to = req.query.to ? String(req.query.to) : undefined;
      const search = req.query.search ? String(req.query.search) : undefined;
      const page = Math.max(Number(req.query.page) || 1, 1);
      const limit = Math.max(Number(req.query.limit) || 20, 1);

      const result = await this.service.getOrders(maQuan, {
        status,
        period,
        from,
        to,
        search,
        page,
        limit,
      });
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateOrderStatus = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const maDonHang = Number(req.params.id);
      const { trangThai, status, lyDo, reason } = req.body;
      const targetStatus = trangThai || status;
      const cancellationReason = lyDo || reason;

      if (!targetStatus) {
        return res.status(400).json({ statusCode: 400, message: 'Vui lòng cung cấp trạng thái mới' });
      }

      const updated = await this.service.updateOrderStatus(maQuan, maDonHang, targetStatus, cancellationReason);
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

  createCategory = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const { tenDanhMuc } = req.body;
      const category = await this.service.createCategory(maQuan, tenDanhMuc);
      return res.status(201).json({ statusCode: 201, status: '1', data: category });
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

  scanCCCD = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const { image, frontImage, backImage, side } = req.body;
      const result = await this.adminService.scanCCCD({ image, frontImage, backImage, side }, side);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getFoodReviews = async (req: StoreAuthenticatedRequest, res: Response) => {
    try {
      const maQuan = this.getStoreId(req);
      const maMonAn = Number(req.params.id);
      if (!maMonAn || isNaN(maMonAn)) {
        return res.status(400).json({ statusCode: 400, message: 'Mã món ăn không hợp lệ' });
      }
      const page = Math.max(Number(req.query.page) || 1, 1);
      const limit = Math.min(Math.max(Number(req.query.limit) || 10, 1), 50);
      const result = await this.service.getFoodReviews(maQuan, maMonAn, page, limit);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };
}

