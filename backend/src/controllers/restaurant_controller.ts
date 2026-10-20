import { Request, Response } from 'express';
import { RestaurantService } from '../services/restaurant_service';

export class RestaurantController {
  private restaurantService = new RestaurantService();

  getAll = async (req: Request, res: Response) => {
    try {
      const restaurants = await this.restaurantService.getAllRestaurants();
      return res.status(200).json({
        status: 'success',
        data: restaurants,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi hệ thống khi lấy danh sách nhà hàng',
      });
    }
  };

  getMenu = async (req: Request, res: Response) => {
    try {
      const maQuan = Number(req.params.id);
      if (!maQuan) {
        return res.status(400).json({
          status: 'error',
          message: 'Mã nhà hàng không hợp lệ',
        });
      }
      const menu = await this.restaurantService.getRestaurantMenu(maQuan);
      return res.status(200).json({
        status: 'success',
        data: menu,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi hệ thống khi lấy menu nhà hàng',
      });
    }
  };

  getCategories = async (req: Request, res: Response) => {
    try {
      const categories = await this.restaurantService.getAllCategories();
      return res.status(200).json(categories);
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi hệ thống khi lấy danh mục',
      });
    }
  };

  getAlongRoute = async (req: Request, res: Response) => {
    try {
      const { routePoints, points, maxDistance } = req.body;
      const pts = routePoints || points;
      if (!Array.isArray(pts) || pts.length === 0) {
        return res.status(400).json({
          status: 'error',
          message: 'Vui lòng cung cấp danh sách tọa độ tuyến đường (routePoints)',
        });
      }

      const maxDistanceMeters = Number(maxDistance) || 1000;
      const restaurants = await this.restaurantService.getRestaurantsAlongRoute(pts, maxDistanceMeters);

      return res.status(200).json({
        status: 'success',
        total: restaurants.length,
        data: restaurants,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi tìm kiếm nhà hàng trên lộ trình',
      });
    }
  };

  getFoodsOverview = async (req: Request, res: Response) => {
    try {
      const foods = await this.restaurantService.getAllFoodsOverview();
      return res.status(200).json({
        status: 'success',
        total: foods.length,
        data: foods,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi lấy danh sách món ăn tổng hợp',
      });
    }
  };
}
