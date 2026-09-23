import { Request, Response } from 'express';
import fs from 'fs';
import path from 'path';

export class UploadController {
  uploadBase64 = async (req: Request, res: Response) => {
    try {
      const { image } = req.body;
      if (!image) {
        return res.status(400).json({ statusCode: 400, message: 'Vui lòng cung cấp dữ liệu hình ảnh' });
      }

      // Match base64 header
      const matches = image.match(/^data:image\/([a-zA-Z0-9]+);base64,(.+)$/);
      if (!matches || matches.length !== 3) {
        return res.status(400).json({ statusCode: 400, message: 'Định dạng hình ảnh base64 không hợp lệ' });
      }

      const ext = matches[1] === 'jpeg' ? 'jpg' : matches[1];
      const buffer = Buffer.from(matches[2], 'base64');

      const uploadsDir = path.join(__dirname, '../../uploads');
      if (!fs.existsSync(uploadsDir)) {
        fs.mkdirSync(uploadsDir, { recursive: true });
      }

      const fileName = `img_${Date.now()}_${Math.random().toString(36).substring(2, 8)}.${ext}`;
      const filePath = path.join(uploadsDir, fileName);

      fs.writeFileSync(filePath, buffer);

      const host = req.get('host') || 'localhost:3000';
      const protocol = req.protocol || 'http';
      const imageUrl = `${protocol}://${host}/uploads/${fileName}`;

      return res.status(200).json({
        statusCode: 200,
        status: '1',
        url: imageUrl,
        message: 'Tải lên & cắt hình ảnh thành công',
      });
    } catch (error: any) {
      console.error('❌ Lỗi upload hình ảnh:', error);
      return res.status(500).json({ statusCode: 500, message: error.message || 'Lỗi lưu tệp hình ảnh' });
    }
  };
}
