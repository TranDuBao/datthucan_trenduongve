import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth_middleware';
import { AppDataSource } from '../config/database';
import { CuaHangModel } from '../models/cua_hang_model';

export interface StoreAuthenticatedRequest extends AuthenticatedRequest {
  maQuan?: number;
}

/**
 * Middleware kiểm tra vai trò người dùng (ADMIN, CUAN_HANG, KHACH_HANG)
 */
export const requireRole = (allowedRoles: string[]) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        statusCode: 401,
        message: 'Bạn cần đăng nhập để thực hiện chức năng này',
      });
    }

    const userRole = (req.user.role || '').toUpperCase();
    const normalizedUserRole = userRole === 'CUA_HANG' ? 'CUAN_HANG' : userRole;

    const isAllowed = allowedRoles.some((r) => {
      const normalizedR = r.toUpperCase() === 'CUA_HANG' ? 'CUAN_HANG' : r.toUpperCase();
      return normalizedR === normalizedUserRole;
    }) || userRole === 'ADMIN';

    if (!isAllowed) {
      return res.status(403).json({
        statusCode: 403,
        message: 'Bạn không có quyền truy cập tài nguyên này',
      });
    }

    next();
  };
};

/**
 * Middleware xác định nhà hàng thuộc quyền quản lý của tài khoản (CUAN_HANG)
 */
export const requireStoreOwner = async (
  req: StoreAuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  if (!req.user) {
    return res.status(401).json({
      statusCode: 401,
      message: 'Bạn chưa đăng nhập',
    });
  }

  // Nếu là ADMIN, cho phép truyền maQuan qua query/body nếu có, hoặc lấy quán đầu tiên
  if (req.user.role === 'ADMIN') {
    const requestedStoreId = req.query.maQuan || req.body.maQuan;
    if (requestedStoreId) {
      req.maQuan = Number(requestedStoreId);
    }
    return next();
  }

  try {
    const storeRepo = AppDataSource.getRepository(CuaHangModel);
    const store = await storeRepo.findOne({
      where: { maTaiKhoan: req.user.sub },
    });

    if (!store) {
      return res.status(403).json({
        statusCode: 403,
        message: 'Tài khoản của bạn chưa được liên kết với nhà hàng nào trong hệ thống',
      });
    }

    req.maQuan = store.maQuan;
    next();
  } catch (error: any) {
    console.error('❌ Lỗi xác thực quyền sở hữu nhà hàng:', error);
    return res.status(500).json({
      statusCode: 500,
      message: 'Lỗi kiểm tra quyền hạn nhà hàng',
    });
  }
};
