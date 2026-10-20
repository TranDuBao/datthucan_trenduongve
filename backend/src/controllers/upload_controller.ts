import { Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { AppDataSource } from '../config/database';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { MonAnModel } from '../models/mon_an_model';

function isValidImageMagicBytes(buffer: Buffer): boolean {
  if (buffer.length < 12) return false;
  // JPEG: FF D8 FF
  if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return true;
  }
  // PNG: 89 50 4E 47
  if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) {
    return true;
  }
  // GIF: 47 49 46 (GIF87a / GIF89a)
  if (buffer[0] === 0x47 && buffer[1] === 0x49 && buffer[2] === 0x46) {
    return true;
  }
  // WebP: 52 49 46 46 (RIFF) ... 57 45 42 50 (WEBP)
  if (
    buffer[0] === 0x52 &&
    buffer[1] === 0x49 &&
    buffer[2] === 0x46 &&
    buffer[3] === 0x46 &&
    buffer[8] === 0x57 &&
    buffer[9] === 0x45 &&
    buffer[10] === 0x42 &&
    buffer[11] === 0x50
  ) {
    return true;
  }
  return false;
}

export class UploadController {
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private foodRepo = AppDataSource.getRepository(MonAnModel);

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

      const rawExt = matches[1].toLowerCase();
      const allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
      if (!allowedExts.includes(rawExt)) {
        return res.status(400).json({
          statusCode: 400,
          message: 'Chỉ chấp nhận các định dạng hình ảnh: JPG, JPEG, PNG, WEBP, GIF',
        });
      }

      const ext = rawExt === 'jpeg' ? 'jpg' : rawExt;
      const buffer = Buffer.from(matches[2], 'base64');

      // Security check: Validate maximum file size limit (5MB max)
      const MAX_FILE_SIZE = 5 * 1024 * 1024;
      if (buffer.length > MAX_FILE_SIZE) {
        return res.status(400).json({ statusCode: 400, message: 'Dung lượng tệp hình ảnh không được vượt quá 5MB' });
      }

      // Security check: Validate actual image magic bytes
      if (!isValidImageMagicBytes(buffer)) {
        return res.status(400).json({
          statusCode: 400,
          message: 'Tệp tải lên không phải hình ảnh hợp lệ (chữ ký tệp sai)',
        });
      }

      const uploadsDir = path.join(process.cwd(), 'uploads');
      if (!fs.existsSync(uploadsDir)) {
        await fs.promises.mkdir(uploadsDir, { recursive: true });
      }

      const userSub = (req as any).user?.sub ? String((req as any).user.sub) : '0';
      const fileName = `img_u${userSub}_${Date.now()}_${Math.random().toString(36).substring(2, 8)}.${ext}`;
      const filePath = path.join(uploadsDir, fileName);

      // Async non-blocking file write
      await fs.promises.writeFile(filePath, buffer);

      const imageUrl = `/uploads/${fileName}`;

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

  deleteFile = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user) {
        return res.status(401).json({ statusCode: 401, message: 'Bạn chưa đăng nhập' });
      }

      const { url } = req.body;
      if (!url || typeof url !== 'string' || !url.includes('/uploads/')) {
        return res.status(400).json({ statusCode: 400, message: 'Đường dẫn tệp không hợp lệ' });
      }

      const userRole = String(user.role || '').toUpperCase();
      const userSub = Number(user.sub);

      // Admin has authorization to delete any file
      if (userRole === 'ADMIN') {
        await deleteUploadFile(url);
        return res.status(200).json({ statusCode: 200, status: '1', message: 'Đã xóa tệp thành công' });
      }

      const fileName = url.split('/uploads/').pop();
      if (!fileName || fileName.includes('..') || fileName.includes('/') || fileName.includes('\\')) {
        return res.status(400).json({ statusCode: 400, message: 'Tên tệp không hợp lệ' });
      }

      let isOwner = false;

      // 0. Ownership check: If file was uploaded by this specific user
      if (fileName.startsWith(`img_u${userSub}_`)) {
        isOwner = true;
      }

      // 1. Check if it's the customer's avatar
      if (!isOwner) {
        const customer = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
        if (customer && customer.avatar && customer.avatar.includes(fileName)) {
          isOwner = true;
        }
      }

      // 2. If store owner, check store image or dishes
      if (!isOwner && (userRole === 'CUAN_HANG' || userRole === 'CUA_HANG')) {
        const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userSub } });
        if (store) {
          if (store.img && store.img.includes(fileName)) {
            isOwner = true;
          } else {
            const food = await this.foodRepo.findOne({ where: { maQuan: store.maQuan, img: url } });
            if (food) isOwner = true;
          }
        }
      }

      if (!isOwner) {
        return res.status(403).json({
          statusCode: 403,
          message: 'Bạn không có quyền xóa tệp tin này do không phải chủ sở hữu',
        });
      }

      await deleteUploadFile(url);
      return res.status(200).json({ statusCode: 200, status: '1', message: 'Đã dọn dẹp tệp ảnh cũ thành công' });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message || 'Lỗi xóa tệp' });
    }
  };
}

export async function deleteUploadFile(fileUrl?: string) {
  if (!fileUrl || typeof fileUrl !== 'string') return;
  if (!fileUrl.includes('/uploads/')) return;
  try {
    const fileName = fileUrl.split('/uploads/').pop();
    if (
      fileName &&
      !fileName.includes('..') &&
      !fileName.includes('/') &&
      !fileName.includes('\\') &&
      (fileName.startsWith('img_') || /\.(png|jpe?g|webp|gif)$/i.test(fileName))
    ) {
      const filePath1 = path.join(process.cwd(), 'uploads', fileName);
      const filePath2 = path.join(__dirname, '../uploads', fileName);
      const filePath3 = path.join(__dirname, '../../uploads', fileName);

      for (const p of [filePath1, filePath2, filePath3]) {
        if (fs.existsSync(p)) {
          await fs.promises.unlink(p);
          console.log(`🗑️ Đã dọn dẹp tệp ảnh cũ thành công: ${fileName}`);
          break;
        }
      }
    }
  } catch (err) {
    console.warn('⚠️ Lỗi xóa tệp ảnh trên đĩa:', err);
  }
}
