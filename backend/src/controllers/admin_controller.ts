import { Request, Response } from 'express';
import { AdminService } from '../services/admin_service';

export class AdminController {
  private adminService = new AdminService();

  getDashboardStats = async (req: Request, res: Response) => {
    try {
      const stats = await this.adminService.getDashboardStats();
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
      const limit = Number(req.query.limit) || 10;
      const search = String(req.query.search || '');
      const role = String(req.query.role || '');

      const result = await this.adminService.getUsers(page, limit, search, role);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  updateUserRole = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const { loaiTaiKhoan, trangThai } = req.body;
      const result = await this.adminService.updateUserRole(id, loaiTaiKhoan, trangThai);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Cập nhật phân quyền thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getRestaurants = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;
      const search = String(req.query.search || '');

      const result = await this.adminService.getRestaurants(page, limit, search);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
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
      const { tenDanhMuc } = req.body;
      if (!tenDanhMuc) return res.status(400).json({ statusCode: 400, message: 'Vui lòng nhập tên danh mục' });
      const result = await this.adminService.createCategory(tenDanhMuc);
      return res.status(201).json({ statusCode: 201, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getFoods = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;
      const search = String(req.query.search || '');
      const maQuan = req.query.maQuan ? Number(req.query.maQuan) : undefined;

      const result = await this.adminService.getFoods(page, limit, search, maQuan);
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
      const limit = Number(req.query.limit) || 10;
      const status = String(req.query.status || '');
      const search = String(req.query.search || '');

      const result = await this.adminService.getOrders(page, limit, status, search);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  getPayments = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;

      const result = await this.adminService.getPayments(page, limit);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };
}
