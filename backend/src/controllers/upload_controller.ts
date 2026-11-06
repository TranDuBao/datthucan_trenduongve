import { Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { v2 as cloudinary } from 'cloudinary';
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

      const isKyc = req.body.isKyc === true || req.body.isKyc === 'true';
      const userSub = (req as any).user?.sub ? String((req as any).user.sub) : '0';

      // 1. Cloudinary Integration: If configured, upload directly to cloud CDN
      if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET) {
        cloudinary.config({
          cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
          api_key: process.env.CLOUDINARY_API_KEY,
          api_secret: process.env.CLOUDINARY_API_SECRET,
        });

        const folder = isKyc ? 'foodroute/kyc' : 'foodroute/uploads';
        const prefix = isKyc ? `kyc_u${userSub}_` : `img_u${userSub}_`;
        const publicId = `${prefix}${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;

        const uploadResult = await cloudinary.uploader.upload(image, {
          folder,
          public_id: publicId,
          resource_type: 'image',
          overwrite: true,
        });

        return res.status(200).json({
          statusCode: 200,
          status: '1',
          url: uploadResult.secure_url,
          message: 'Tải lên & xử lý hình ảnh thành công qua Cloudinary',
        });
      }

      // 2. Local Filesystem Fallback
      const targetDir = isKyc
        ? path.join(process.cwd(), 'uploads_kyc')
        : path.join(process.cwd(), 'uploads');

      if (!fs.existsSync(targetDir)) {
        await fs.promises.mkdir(targetDir, { recursive: true });
      }

      const prefix = isKyc ? `kyc_u${userSub}_` : `img_u${userSub}_`;
      const fileName = `${prefix}${Date.now()}_${Math.random().toString(36).substring(2, 8)}.${ext}`;
      const filePath = path.join(targetDir, fileName);

      // Async non-blocking file write
      await fs.promises.writeFile(filePath, buffer);

      const imageUrl = isKyc ? `/api/v1/upload/kyc/${fileName}` : `/uploads/${fileName}`;

      return res.status(200).json({
        statusCode: 200,
        status: '1',
        url: imageUrl,
        message: 'Tải lên & cắt hình ảnh thành công',
      });
    } catch (error: any) {
      console.error('[UploadController] [Error] Lỗi upload hình ảnh:', error);
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

  /**
   * Endpoint phục vụ tệp KYC/CCCD nhạy cảm (Chỉ ADMIN hoặc chủ sở hữu tệp được xem)
   */
  getKycFile = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user) {
        return res.status(401).json({ statusCode: 401, message: 'Bạn chưa đăng nhập' });
      }

      const fileName = path.basename(req.params.filename || '');
      if (!fileName || fileName.includes('..') || fileName.includes('/') || fileName.includes('\\')) {
        return res.status(400).json({ statusCode: 400, message: 'Tên tệp không hợp lệ' });
      }

      const userRole = String(user.role || '').toUpperCase();
      const userSub = Number(user.sub);

      let isAllowed = false;
      if (userRole === 'ADMIN') {
        isAllowed = true;
      } else if (fileName.startsWith(`kyc_u${userSub}_`) || fileName.startsWith(`img_u${userSub}_`)) {
        isAllowed = true;
      }

      if (!isAllowed) {
        return res.status(403).json({
          statusCode: 403,
          message: 'Bạn không có quyền truy cập tài liệu KYC nhạy cảm này',
        });
      }

      const kycDir = path.join(process.cwd(), 'uploads_kyc');
      const filePath = path.join(kycDir, fileName);

      if (!fs.existsSync(filePath)) {
        // Fallback kiểm tra trong uploads nếu file cũ được lưu trước đây
        const fallbackPath = path.join(process.cwd(), 'uploads', fileName);
        if (fs.existsSync(fallbackPath)) {
          return res.sendFile(fallbackPath);
        }
        return res.status(404).json({ statusCode: 404, message: 'Không tìm thấy tệp tài liệu' });
      }

      return res.sendFile(filePath);
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, message: error.message || 'Lỗi đọc tệp KYC' });
    }
  };
}

export async function deleteUploadFile(fileUrl?: string) {
  if (!fileUrl || typeof fileUrl !== 'string') return;

  // Cloudinary deletion support
  if (fileUrl.includes('res.cloudinary.com')) {
    try {
      if (process.env.CLOUDINARY_CLOUD_NAME && process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_SECRET) {
        cloudinary.config({
          cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
          api_key: process.env.CLOUDINARY_API_KEY,
          api_secret: process.env.CLOUDINARY_API_SECRET,
        });

        // Extract public_id from Cloudinary URL: e.g. /upload/v12345/foodroute/uploads/xyz.jpg
        const match = fileUrl.match(/\/upload\/(?:v\d+\/)?(.+)\.[a-zA-Z0-9]+$/);
        if (match && match[1]) {
          await cloudinary.uploader.destroy(match[1]);
          console.log(`[UploadController] [Info] Đã xóa ảnh trên Cloudinary: ${match[1]}`);
          return;
        }
      }
    } catch (cErr) {
      console.warn('[UploadController] [Warn] Lỗi xóa ảnh Cloudinary:', cErr);
    }
    return;
  }

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
          console.log(`[UploadController] [Info] Đã dọn dẹp tệp ảnh cũ thành công: ${fileName}`);
          break;
        }
      }
    }
  } catch (err) {
    console.warn('[UploadController] [Warn] Lỗi xóa tệp ảnh trên đĩa:', err);
  }
}
