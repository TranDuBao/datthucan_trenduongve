import { Request, Response } from 'express';
import { StoreCategoryService } from '../services/store_category_service';

export class StoreCategoryController {
  private service = new StoreCategoryService();

  getAll = async (req: Request, res: Response) => {
    try {
      const search = req.query.search as string;
      const data = await this.service.getAll(search);
      return res.status(200).json({ statusCode: 200, status: '1', data });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  getActive = async (req: Request, res: Response) => {
    try {
      const data = await this.service.getActive();
      return res.status(200).json({ statusCode: 200, status: '1', data });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message });
    }
  };

  getById = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const data = await this.service.getById(id);
      return res.status(200).json({ statusCode: 200, status: '1', data });
    } catch (error: any) {
      return res.status(404).json({ statusCode: 404, message: error.message });
    }
  };

  create = async (req: Request, res: Response) => {
    try {
      const { tenLoai, moTa, hinhAnh, icon, thuTu, trangThai } = req.body;
      const data = await this.service.create({ tenLoai, moTa, hinhAnh, icon, thuTu, trangThai });
      return res.status(201).json({ statusCode: 201, status: '1', data, message: 'Tạo loại hình quán thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  update = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const { tenLoai, moTa, hinhAnh, icon, thuTu, trangThai } = req.body;
      const data = await this.service.update(id, { tenLoai, moTa, hinhAnh, icon, thuTu, trangThai });
      return res.status(200).json({ statusCode: 200, status: '1', data, message: 'Cập nhật loại hình quán thành công' });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  delete = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const data = await this.service.delete(id);
      return res.status(200).json({ statusCode: 200, status: '1', data, message: data.message });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };

  getRestaurantsByCategory = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);
      const data = await this.service.getRestaurantsByCategory(id);
      return res.status(200).json({ statusCode: 200, status: '1', data });
    } catch (error: any) {
      return res.status(404).json({ statusCode: 404, message: error.message });
    }
  };
}

