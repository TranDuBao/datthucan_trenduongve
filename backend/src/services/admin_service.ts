import { AdminDashboardService } from './admin/admin_dashboard_service';
import { AdminUserService } from './admin/admin_user_service';
import { AdminRestaurantService } from './admin/admin_restaurant_service';
import { AdminCatalogService } from './admin/admin_catalog_service';
import { AdminBannerService } from './admin/admin_banner_service';
import { CuaHangModel } from '../models/cua_hang_model';
import { MonAnModel } from '../models/mon_an_model';
import { BannerModel } from '../models/banner_model';

export class AdminService {
  private dashboardService = new AdminDashboardService();
  private userService = new AdminUserService();
  private restaurantService = new AdminRestaurantService();
  private catalogService = new AdminCatalogService();
  private bannerService = new AdminBannerService();

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
  async getDashboardStats(
    page: number = 1,
    limit: number = 10,
    ordersOnly: boolean = false,
    filters?: { singleDate?: string; fromDate?: string; toDate?: string }
  ) {
    return this.dashboardService.getDashboardStats(page, limit, ordersOnly, filters);
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

  async getRestaurantDetail(maQuan: number, filters?: { singleDate?: string; fromDate?: string; toDate?: string }) {
    return this.restaurantService.getRestaurantDetail(maQuan, filters);
  }

  async getRestaurantComparison(
    restaurantIds: number[],
    timeframe: string = 'day',
    singleDate?: string,
    fromDate?: string,
    toDate?: string
  ) {
    return this.restaurantService.getRestaurantComparison(restaurantIds, timeframe, singleDate, fromDate, toDate);
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

  async createCategory(tenDanhMuc: string, hinhAnh?: string, maDanhMuc?: number) {
    return this.catalogService.createCategory(tenDanhMuc, hinhAnh, maDanhMuc);
  }

  async updateCategory(maDanhMuc: number, tenDanhMuc: string, hinhAnh?: string) {
    return this.catalogService.updateCategory(maDanhMuc, tenDanhMuc, hinhAnh);
  }

  async deleteCategory(maDanhMuc: number) {
    return this.catalogService.deleteCategory(maDanhMuc);
  }

  async assignFoodToCategory(maMonAn: number, maDanhMuc: number) {
    return this.catalogService.assignFoodToCategory(maMonAn, maDanhMuc);
  }

  async removeFoodFromCategory(maMonAn: number) {
    return this.catalogService.removeFoodFromCategory(maMonAn);
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

  // Banners
  async getAllBanners() {
    return this.bannerService.getAllBanners();
  }

  async getActiveBanners() {
    return this.bannerService.getActiveBanners();
  }

  async createBanner(data: Partial<BannerModel>) {
    return this.bannerService.createBanner(data);
  }

  async updateBanner(maBanner: number, data: Partial<BannerModel>) {
    return this.bannerService.updateBanner(maBanner, data);
  }

  async deleteBanner(maBanner: number) {
    return this.bannerService.deleteBanner(maBanner);
  }

  // Orders & Payments
  async getOrders(page?: number, limit?: number, status?: string, search?: string, storeId?: number) {
    return this.dashboardService.getOrders(page, limit, status, search, storeId);
  }

  async getPayments(page?: number, limit?: number) {
    return this.dashboardService.getPayments(page, limit);
  }
}
