import { Request, Response } from 'express';
import { AuthService } from '../services/auth_service';
import { UserService } from '../services/user_service';
import { AdminService } from '../services/admin_service';
import { AuthenticatedRequest } from '../middlewares/auth_middleware';

export class AuthController {
  private authService = new AuthService();
  private userService = new UserService();

  register = async (req: Request, res: Response) => {
    try {
      const email = req.body.email;
      const password = req.body.password;
      const fullName = req.body.fullName || req.body.name;
      const phone = req.body.phone || req.body.mobile || req.body.sdt;

      if (!email || !password || !fullName) {
        return res.status(400).json({
          statusCode: 400,
          status: "0",
          message: 'Vui lòng nhập đầy đủ email, mật khẩu và họ tên!',
        });
      }

      const result = await this.authService.register({ email, password, fullName, phone });
      return res.status(201).json({
        statusCode: 201,
        status: "1",
        message: 'Đăng ký tài khoản thành công',
        payload: result,
        data: result,
      });
    } catch (error: any) {
      console.error('❌ Register Error:', error);
      return res.status(400).json({
        statusCode: 400,
        status: "0",
        message: error.message || 'Đăng ký thất bại!',
      });
    }
  };

  login = async (req: Request, res: Response) => {
    try {
      const { email, password } = req.body;
      if (!email || !password) {
        return res.status(400).json({
          statusCode: 400,
          status: "0",
          message: 'Vui lòng nhập email và mật khẩu!',
        });
      }

      const result = await this.authService.login({ email, password });
      return res.status(200).json({
        statusCode: 200,
        status: "1",
        message: 'Đăng nhập thành công',
        payload: result,
        data: result,
      });
    } catch (error: any) {
      console.error('❌ Login Error:', error);
      return res.status(401).json({
        statusCode: 401,
        status: "0",
        message: error.message || 'Đăng nhập thất bại!',
      });
    }
  };

  googleAuth = async (req: Request, res: Response) => {
    try {
      const idToken = req.body.idToken || req.body.id_token || req.body.token;
      if (!idToken || typeof idToken !== 'string' || !idToken.trim()) {
        return res.status(400).json({
          statusCode: 400,
          status: "0",
          message: 'Vui lòng cung cấp Google ID Token hợp lệ!',
        });
      }

      const result = await this.authService.loginWithGoogle(idToken.trim());

      return res.status(200).json({
        statusCode: 200,
        status: "1",
        message: 'Đăng nhập bằng Google thành công',
        payload: result,
        data: result,
      });
    } catch (error: any) {
      console.error('❌ Google Auth Error:', error);
      return res.status(400).json({
        statusCode: 400,
        status: "0",
        message: error.message || 'Đăng nhập Google thất bại!',
      });
    }
  };

  getProfile = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const userId = req.user?.sub;
      if (!userId || isNaN(Number(userId))) {
        return res.status(401).json({
          statusCode: 401,
          status: "0",
          message: 'Bạn cần đăng nhập để thực hiện chức năng này',
        });
      }

      const account = await this.userService.findById(Number(userId));
      if (!account) {
        return res.status(404).json({ statusCode: 404, status: "0", message: 'Không tìm thấy người dùng' });
      }

      const userData = {
        id: account.taiKhoan.maTaiKhoan,
        username: account.taiKhoan.tenDangNhap,
        fullName: account.khachHang?.hoTen || '',
        name: account.khachHang?.hoTen || '',
        email: account.khachHang?.email || account.taiKhoan.tenDangNhap,
        phone: account.khachHang?.sdt || '',
        mobile: account.khachHang?.sdt || '',
        address: account.khachHang?.diaChi || '',
        diaChi: account.khachHang?.diaChi || '',
        avatar: account.khachHang?.avatar || '',
        role: account.taiKhoan.loaiTaiKhoan,
        khachHang: account.khachHang,
      };

      return res.status(200).json({
        statusCode: 200,
        status: "1",
        message: 'Lấy thông tin thành công',
        payload: userData,
        data: userData,
      });
    } catch (error: any) {
      console.error('❌ GetProfile Error:', error);
      return res.status(500).json({
        statusCode: 500,
        status: "0",
        message: error.message || 'Lỗi server!',
      });
    }
  };

  updateProfile = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const userId = req.user?.sub;
      if (!userId || isNaN(Number(userId))) {
        return res.status(401).json({
          statusCode: 401,
          status: '0',
          message: 'Bạn cần đăng nhập để thực hiện chức năng này',
        });
      }

      const targetUserId = Number(userId);
      const { fullName, name, email, phone, sdt, address, diaChi, avatar } = req.body;
      const hoTen = fullName || name;
      const sdtVal = phone || sdt;
      const diaChiVal = address || diaChi;

      const updatedKhachHang = await this.userService.updateProfile(targetUserId, {
        hoTen,
        email,
        phone: sdtVal,
        diaChi: diaChiVal,
        avatar,
      });

      const account = await this.userService.findById(targetUserId);
      const userData = {
        id: account?.taiKhoan.maTaiKhoan,
        username: account?.taiKhoan.tenDangNhap,
        fullName: updatedKhachHang?.hoTen || account?.khachHang?.hoTen,
        name: updatedKhachHang?.hoTen || account?.khachHang?.hoTen,
        email: updatedKhachHang?.email || account?.khachHang?.email || account?.taiKhoan.tenDangNhap,
        phone: updatedKhachHang?.sdt || account?.khachHang?.sdt,
        address: updatedKhachHang?.diaChi || account?.khachHang?.diaChi,
        avatar: updatedKhachHang?.avatar || account?.khachHang?.avatar,
        role: account?.taiKhoan.loaiTaiKhoan,
        khachHang: updatedKhachHang,
      };

      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Cập nhật thông tin thành công',
        payload: userData,
        data: userData,
      });
    } catch (error: any) {
      console.error('❌ UpdateProfile Error:', error);
      return res.status(500).json({
        statusCode: 500,
        status: '0',
        message: error.message || 'Lỗi server!',
      });
    }
  };

  changePassword = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const userId = req.user?.sub;
      if (!userId || isNaN(Number(userId))) {
        return res.status(401).json({
          statusCode: 401,
          status: '0',
          message: 'Bạn cần đăng nhập để thực hiện chức năng này',
        });
      }

      const { oldPassword, newPassword } = req.body;
      if (!oldPassword) {
        return res.status(400).json({ statusCode: 400, status: '0', message: 'Vui lòng nhập mật khẩu hiện tại!' });
      }
      if (!newPassword || newPassword.length < 6) {
        return res.status(400).json({ statusCode: 400, status: '0', message: 'Mật khẩu mới phải từ 6 ký tự trở lên!' });
      }

      const account = await this.userService.findById(Number(userId));
      if (!account || !account.taiKhoan) {
        return res.status(404).json({ statusCode: 404, status: '0', message: 'Không tìm thấy tài khoản!' });
      }

      const bcrypt = await import('bcrypt');
      const isMatch = await bcrypt.compare(oldPassword, account.taiKhoan.matKhau);
      if (!isMatch) {
        return res.status(400).json({ statusCode: 400, status: '0', message: 'Mật khẩu hiện tại không chính xác!' });
      }

      const hash = await bcrypt.hash(newPassword, 10);
      await this.userService.updatePassword(Number(userId), hash);
      const { TokenBlacklistService } = await import('../services/token_blacklist_service');
      TokenBlacklistService.getInstance().revokeAllUserTokens(Number(userId));

      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Đổi mật khẩu thành công',
      });
    } catch (error: any) {
      console.error('❌ ChangePassword Error:', error);
      return res.status(500).json({
        statusCode: 500,
        status: '0',
        message: error.message || 'Lỗi server!',
      });
    }
  };

  logout = async (req: Request, res: Response) => {
    try {
      const authHeader = req.headers.authorization;
      const accessToken =
        authHeader && authHeader.startsWith('Bearer ')
          ? authHeader.split(' ')[1]
          : undefined;
      const refreshToken = req.body?.refreshToken || req.body?.refresh_token;

      await this.authService.logout(accessToken, refreshToken);

      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Đăng xuất thành công, phiên đăng nhập đã được thu hồi',
      });
    } catch (error: any) {
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Đăng xuất thành công',
      });
    }
  };

  refreshToken = async (req: Request, res: Response) => {
    try {
      const refreshTokenStr =
        req.body?.refreshToken || req.body?.refresh_token;
      if (!refreshTokenStr) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Vui lòng cung cấp refresh token',
        });
      }

      const result = await this.authService.refreshTokens(refreshTokenStr);
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Làm mới token thành công',
        payload: result,
        data: result,
      });
    } catch (error: any) {
      return res.status(401).json({
        statusCode: 401,
        status: '0',
        message: error.message || 'Làm mới token thất bại',
      });
    }
  };

  scanCCCD = async (req: Request, res: Response) => {
    try {
      const { image, frontImage, backImage, side } = req.body;
      const adminService = new AdminService();
      const result = await adminService.scanCCCD({ image, frontImage, backImage, side }, side);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: error.message });
    }
  };
}

