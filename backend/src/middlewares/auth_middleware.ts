import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { TokenBlacklistService } from '../services/token_blacklist_service';

export interface AuthenticatedRequest extends Request {
  user?: {
    sub: number;
    email: string;
    role: string;
    type?: string;
    jti?: string;
  };
}

export const authMiddleware = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      statusCode: 401,
      message: 'Bạn cần đăng nhập để thực hiện chức năng này',
    });
  }

  const token = authHeader.split(' ')[1];
  try {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('CHÚ Ý BẢO MẬT: JWT_SECRET chưa được khai báo trong file .env!');
    }
    const decoded = jwt.verify(token, secret) as any;

    // Check token revocation blacklist (SEC-02 hardening)
    if (TokenBlacklistService.getInstance().isRevoked(token, decoded)) {
      return res.status(401).json({
        statusCode: 401,
        message: 'Phiên đăng nhập đã kết thúc hoặc token đã bị thu hồi. Vui lòng đăng nhập lại.',
      });
    }

    // Reject refresh token from accessing regular API endpoints (token type isolation)
    if (decoded.type === 'refresh') {
      return res.status(401).json({
        statusCode: 401,
        message: 'Refresh token không thể dùng để truy cập API trực tiếp',
      });
    }

    req.user = decoded;
    next();
  } catch (err: any) {
    return res.status(401).json({
      statusCode: 401,
      message: err.message?.includes('JWT_SECRET')
        ? err.message
        : 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn',
    });
  }
};

