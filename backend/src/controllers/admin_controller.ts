import { Request, Response } from 'express';
import { AdminService } from '../services/admin_service';

export class AdminController {
  private adminService = new AdminService();

  getDashboardStats = async (req: Request, res: Response) => {
    try {
      // Validate page (default 1, integer >= 1)
      let page = parseInt(String(req.query.page), 10);
      if (isNaN(page) || page < 1) {
        page = 1;
      }

      // Validate limit (default 10, max 50, integer 1..50)
      let limit = parseInt(String(req.query.limit), 10);
      if (isNaN(limit) || limit < 1 || limit > 50) {
        limit = 10;
      }

      const ordersOnly = req.query.ordersOnly === 'true' || req.query.ordersOnly === '1';

      const stats = await this.adminService.getDashboardStats(page, limit, ordersOnly);
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        data: stats,
      });
    } catch (error: any) {
      console.error('❌ Error Admin Dashboard Stats:', error);
      return res.status(500).json({ statusCode: 500, message: error.message || 'Lỗi server' });
    }
  };

  getUsers = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 1000;
      const search = String(req.query.search || '');
      const role = String(req.query.role || '');
      const status = String(req.query.status || '');

      const result = await this.adminService.getUsers(page, limit, search, role, status);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  getUserDetail = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.getUserDetail(id);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(404).json({ statusCode: 404, message: error.message });
    }
  };

  createUser = async (req: Request, res: Response) => {
    try {
      const result = await this.adminService.createUser(req.body);
      return res.status(201).json({ statusCode: 201, status: '1', data: result, message: 'Tạo tài khoản mới thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateUser = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.updateUser(id, req.body);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Cập nhật thông tin thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  lockUser = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.lockUser(id, req.body);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Cập nhật trạng thái khóa tài khoản thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  changeUserPassword = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const { matKhauMoi } = req.body;
      const result = await this.adminService.changeUserPassword(id, matKhauMoi);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  deleteUser = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.deleteUser(id);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  scanCCCD = async (req: Request, res: Response) => {
    try {
      const { image, side } = req.body;
      const result = await this.adminService.scanCCCD(image, side);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getRestaurants = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 1000;
      const search = String(req.query.search || '');

      const result = await this.adminService.getRestaurants(page, limit, search);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  getRestaurantDetail = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.getRestaurantDetail(id);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(404).json({ statusCode: 404, message: error.message });
    }
  };

  createRestaurant = async (req: Request, res: Response) => {
    try {
      const result = await this.adminService.createRestaurant(req.body);
      return res.status(201).json({ statusCode: 201, status: '1', data: result, message: 'Tạo nhà hàng mới thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateRestaurant = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.updateRestaurant(id, req.body);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Cập nhật nhà hàng thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  deleteRestaurant = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.deleteRestaurant(id);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Đã xóa mềm nhà hàng thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể xóa nhà hàng' });
    }
  };

  restoreRestaurant = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.restoreRestaurant(id);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Đã khôi phục nhà hàng thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message || 'Không thể khôi phục nhà hàng' });
    }
  };

  getCategories = async (req: Request, res: Response) => {
    try {
      const categories = await this.adminService.getCategories();
      return res.status(200).json({ statusCode: 200, status: '1', data: categories });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  createCategory = async (req: Request, res: Response) => {
    try {
      const { tenDanhMuc, maDanhMuc } = req.body;
      if (!tenDanhMuc) return res.status(400).json({ statusCode: 400, message: 'Vui lòng nhập tên danh mục' });
      const result = await this.adminService.createCategory(tenDanhMuc, maDanhMuc ? Number(maDanhMuc) : undefined);
      return res.status(201).json({ statusCode: 201, status: '1', data: result, message: maDanhMuc ? 'Cập nhật danh mục thành công' : 'Tạo danh mục thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateCategory = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const { tenDanhMuc } = req.body;
      if (!tenDanhMuc) return res.status(400).json({ statusCode: 400, message: 'Vui lòng nhập tên danh mục' });
      const result = await this.adminService.updateCategory(id, tenDanhMuc);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Cập nhật danh mục thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getCategoryFoods = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.getCategoryFoods(id);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(404).json({ statusCode: 404, message: error.message });
    }
  };

  getFoods = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 1000;
      const search = String(req.query.search || '');
      const maQuan = req.query.maQuan ? Number(req.query.maQuan) : undefined;
      const maDanhMuc = req.query.maDanhMuc ? Number(req.query.maDanhMuc) : undefined;

      const result = await this.adminService.getFoods(page, limit, search, maQuan, maDanhMuc);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  updateFood = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.updateFood(id, req.body);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Cập nhật món ăn thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getOrders = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 1000;
      const status = String(req.query.status || '');
      const search = String(req.query.search || '');
      const storeId = req.query.storeId ? Number(req.query.storeId) : undefined;

      const result = await this.adminService.getOrders(page, limit, status, search, storeId);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  getPayments = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 1000;

      const result = await this.adminService.getPayments(page, limit);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  getActivityLogs = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 100;
      const search = String(req.query.search || '');
      const actionType = String(req.query.actionType || '');

      const result = await this.adminService.getActivityLogs(page, limit, search, actionType);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };
}
