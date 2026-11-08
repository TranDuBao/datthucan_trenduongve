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
      console.error('[AdminController] [Error] Error Admin Dashboard Stats:', error);
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
      const { tenDanhMuc, hinhAnh, maDanhMuc } = req.body;
      if (!tenDanhMuc) return res.status(400).json({ statusCode: 400, message: 'Vui lòng nhập tên danh mục' });
      const result = await this.adminService.createCategory(tenDanhMuc, hinhAnh, maDanhMuc ? Number(maDanhMuc) : undefined);
      return res.status(201).json({ statusCode: 201, status: '1', data: result, message: maDanhMuc ? 'Cập nhật danh mục thành công' : 'Tạo danh mục thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateCategory = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const { tenDanhMuc, hinhAnh } = req.body;
      if (!tenDanhMuc) return res.status(400).json({ statusCode: 400, message: 'Vui lòng nhập tên danh mục' });
      const result = await this.adminService.updateCategory(id, tenDanhMuc, hinhAnh);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Cập nhật danh mục thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  deleteCategory = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.deleteCategory(id);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Xóa danh mục thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  assignFoodToCategory = async (req: Request, res: Response) => {
    try {
      const { maMonAn, maDanhMuc } = req.body;
      if (!maMonAn || !maDanhMuc) {
        return res.status(400).json({ statusCode: 400, message: 'Thiếu mã món ăn hoặc mã danh mục' });
      }
      const result = await this.adminService.assignFoodToCategory(Number(maMonAn), Number(maDanhMuc));
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Phân món vào thực đơn thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  removeFoodFromCategory = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.removeFoodFromCategory(id);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Đã gỡ món khỏi danh mục' });
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

  getBanners = async (req: Request, res: Response) => {
    try {
      const result = await this.adminService.getAllBanners();
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  createBanner = async (req: Request, res: Response) => {
    try {
      const result = await this.adminService.createBanner(req.body);
      return res.status(201).json({ statusCode: 201, status: '1', data: result, message: 'Tạo banner thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  updateBanner = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.updateBanner(id, req.body);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Cập nhật banner thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  deleteBanner = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const result = await this.adminService.deleteBanner(id);
      return res.status(200).json({ statusCode: 200, status: '1', data: result, message: 'Xóa banner thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getActiveBanners = async (req: Request, res: Response) => {
    try {
      const result = await this.adminService.getActiveBanners();
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  private static lastKnownStats: any = {
    totalDownloads: 9,
    version: 'v1.0.0',
    releaseName: 'FoodRoute App v1.0.0',
    publishedAt: '2026-11-08T14:41:36Z',
    apkName: 'FoodRoute_v1.0.apk',
    apkSize: 71512646,
    apkDownloadCount: 9,
    downloadUrl: 'https://github.com/TranDuBao/datthucan_trenduongve/releases/download/v1.0.0/FoodRoute_v1.0.apk',
    releaseUrl: 'https://github.com/TranDuBao/datthucan_trenduongve/releases/tag/v1.0.0',
  };

  private cachedAppStats: { data: any; expiry: number } | null = null;

  getAppStats = async (req: Request, res: Response) => {
    try {
      const now = Date.now();
      if (this.cachedAppStats && this.cachedAppStats.expiry > now) {
        return res.status(200).json({ statusCode: 200, status: '1', data: this.cachedAppStats.data });
      }

      // Fetch from GitHub Releases API
      const repo = 'TranDuBao/datthucan_trenduongve';
      const headers: Record<string, string> = { 'User-Agent': 'FoodRoute-Backend' };
      if (process.env.GITHUB_TOKEN) {
        headers['Authorization'] = `token ${process.env.GITHUB_TOKEN}`;
      }

      const ghRes = await fetch(`https://api.github.com/repos/${repo}/releases`, { headers });

      if (!ghRes.ok) {
        throw new Error(`GitHub API error: ${ghRes.status}`);
      }

      const releases = await ghRes.json();
      let totalDownloads = 0;
      let latestRelease: any = null;
      let apkAsset: any = null;

      if (Array.isArray(releases) && releases.length > 0) {
        latestRelease = releases[0];
        for (const rel of releases) {
          if (Array.isArray(rel.assets)) {
            for (const asset of rel.assets) {
              totalDownloads += Number(asset.download_count) || 0;
              if (asset.name.endsWith('.apk') && !apkAsset) {
                apkAsset = asset;
              }
            }
          }
        }
      }

      const payload = {
        totalDownloads: totalDownloads > 0 ? totalDownloads : AdminController.lastKnownStats.totalDownloads,
        version: latestRelease?.tag_name || 'v1.0.0',
        releaseName: latestRelease?.name || 'FoodRoute App v1.0.0',
        publishedAt: latestRelease?.published_at || new Date().toISOString(),
        apkName: apkAsset?.name || 'FoodRoute_v1.0.apk',
        apkSize: apkAsset?.size || 71512646,
        apkDownloadCount: (apkAsset?.download_count != null && apkAsset.download_count > 0) ? apkAsset.download_count : AdminController.lastKnownStats.apkDownloadCount,
        downloadUrl: apkAsset?.browser_download_url || 'https://github.com/TranDuBao/datthucan_trenduongve/releases/download/v1.0.0/FoodRoute_v1.0.apk',
        releaseUrl: latestRelease?.html_url || 'https://github.com/TranDuBao/datthucan_trenduongve/releases/tag/v1.0.0',
      };

      if (payload.totalDownloads > 0) {
        AdminController.lastKnownStats = payload;
      }

      // Cache for 3 minutes to preserve GitHub rate limits
      this.cachedAppStats = { data: payload, expiry: now + 180000 };

      return res.status(200).json({ statusCode: 200, status: '1', data: payload });
    } catch (error: any) {
      console.warn('[AdminController] [Warn] Lỗi lấy thống kê app từ GitHub:', error.message);
      return res.status(200).json({ statusCode: 200, status: '1', data: AdminController.lastKnownStats });
    }
  };
}
