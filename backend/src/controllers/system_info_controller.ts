import { Request, Response } from 'express';
import { SystemInfoService } from '../services/system_info_service';

export class SystemInfoController {
  private service = new SystemInfoService();

  getAboutUs = async (_req: Request, res: Response) => {
    try {
      const data = await this.service.getAboutUs();
      return res.status(200).json({
        status: 'success',
        data,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi hệ thống khi lấy thông tin hệ thống',
      });
    }
  };

  updateAboutUs = async (req: Request, res: Response) => {
    try {
      const data = await this.service.updateAboutUs(req.body);
      return res.status(200).json({
        status: 'success',
        message: 'Cập nhật thông tin giới thiệu thành công',
        data,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Lỗi khi cập nhật thông tin giới thiệu',
      });
    }
  };
}
