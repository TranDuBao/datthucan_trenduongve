import { AdminDashboardService } from './admin/admin_dashboard_service';
import { AdminUserService } from './admin/admin_user_service';
import { AdminRestaurantService } from './admin/admin_restaurant_service';
import { AdminCatalogService } from './admin/admin_catalog_service';
import { CuaHangModel } from '../models/cua_hang_model';
import { MonAnModel } from '../models/mon_an_model';

export class AdminService {
  private dashboardService = new AdminDashboardService();
  private userService = new AdminUserService();
  private restaurantService = new AdminRestaurantService();
  private catalogService = new AdminCatalogService();

  // Activity Logs
  async logActivity(data: {
    maTaiKhoan?: number;
    tenNguoiThucHien?: string;
    loaiHanhDong: string;
    moTa: string;
    doiTuong?: string;
    maDoiTuong?: string | number;
    ipAddress?: string;
  }) {
    return this.dashboardService.logActivity(data);
  }

  async getActivityLogs(page?: number, limit?: number, search?: string, actionType?: string) {
    return this.dashboardService.getActivityLogs(page, limit, search, actionType);
  }

  // Dashboard Stats
  async getDashboardStats(page: number = 1, limit: number = 10, ordersOnly: boolean = false) {
    return this.dashboardService.getDashboardStats(page, limit, ordersOnly);
  }

  // Users
  async getUsers(page?: number, limit?: number, search?: string, roleFilter?: string, statusFilter?: string) {
    return this.userService.getUsers(page, limit, search, roleFilter, statusFilter);
  }

  async getUserDetail(maTaiKhoan: number) {
    return this.userService.getUserDetail(maTaiKhoan);
  }

  async createUser(data: any) {
    return this.userService.createUser(data);
  }

  async updateUser(maTaiKhoan: number, data: any) {
    return this.userService.updateUser(maTaiKhoan, data);
  }

  async scanCCCD(imageOrPayload: any, sideParam?: 'front' | 'back' | 'both') {
    return this.userService.scanCCCD(imageOrPayload, sideParam);
  }

  async lockUser(maTaiKhoan: number, data: any) {
    return this.userService.lockUser(maTaiKhoan, data);
  }

  async changeUserPassword(maTaiKhoan: number, matKhauMoi: string) {
    return this.userService.changeUserPassword(maTaiKhoan, matKhauMoi);
  }

  async deleteUser(maTaiKhoan: number) {
    return this.userService.deleteUser(maTaiKhoan);
  }

  // Restaurants
  async getRestaurants(page?: number, limit?: number, search?: string) {
    return this.restaurantService.getRestaurants(page, limit, search);
  }

  async createRestaurant(data: Partial<CuaHangModel>) {
    return this.restaurantService.createRestaurant(data);
  }

  async getRestaurantDetail(maQuan: number) {
    return this.restaurantService.getRestaurantDetail(maQuan);
  }

  async updateRestaurant(maQuan: number, data: Partial<CuaHangModel>) {
    return this.restaurantService.updateRestaurant(maQuan, data);
  }

  async deleteRestaurant(maQuan: number) {
    return this.restaurantService.deleteRestaurant(maQuan);
  }

  async restoreRestaurant(maQuan: number) {
    return this.restaurantService.restoreRestaurant(maQuan);
  }

  // Categories & Foods
  async getCategories() {
    return this.catalogService.getCategories();
  }

  async createCategory(tenDanhMuc: string, maDanhMuc?: number) {
    return this.catalogService.createCategory(tenDanhMuc, maDanhMuc);
  }

  async updateCategory(maDanhMuc: number, tenDanhMuc: string) {
    return this.catalogService.updateCategory(maDanhMuc, tenDanhMuc);
  }

  async getCategoryFoods(maDanhMuc: number) {
    return this.catalogService.getCategoryFoods(maDanhMuc);
  }

  async getFoods(page?: number, limit?: number, search?: string, maQuan?: number, maDanhMuc?: number) {
    return this.catalogService.getFoods(page, limit, search, maQuan, maDanhMuc);
  }

  async updateFood(maMonAn: number, data: Partial<MonAnModel>) {
    return this.catalogService.updateFood(maMonAn, data);
  }

  // Orders & Payments
  async getOrders(page?: number, limit?: number, status?: string, search?: string, storeId?: number) {
    return this.dashboardService.getOrders(page, limit, status, search, storeId);
  }

  async getPayments(page?: number, limit?: number) {
    return this.dashboardService.getPayments(page, limit);
  }
}
