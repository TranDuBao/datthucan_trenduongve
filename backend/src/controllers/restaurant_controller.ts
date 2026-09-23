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
}
