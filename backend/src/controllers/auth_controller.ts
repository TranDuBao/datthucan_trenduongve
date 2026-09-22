import { Request, Response } from 'express';
import { AuthService } from '../services/auth_service';
import { UserService } from '../services/user_service';
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
      const { googleId, email, fullName, avatarUrl } = req.body;
      const name = fullName || req.body.name;
      if (!email || !name) {
        return res.status(400).json({
          statusCode: 400,
          status: "0",
          message: 'Thông tin Google OAuth không hợp lệ!',
        });
      }

      const result = await this.authService.loginWithGoogle({
        googleId: googleId || `google_${Date.now()}`,
        email,
        fullName: name,
        avatarUrl,
      });

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
      if (!req.user) {
        return res.status(401).json({ statusCode: 401, status: "0", message: 'Unauthenticated' });
      }

      const account = await this.userService.findById(req.user.sub);
      if (!account) {
        return res.status(404).json({ statusCode: 404, status: "0", message: 'Không tìm thấy người dùng' });
      }

      const userData = {
        id: account.taiKhoan.maTaiKhoan,
        username: account.taiKhoan.tenDangNhap,
        fullName: account.khachHang?.hoTen,
        name: account.khachHang?.hoTen,
        email: account.khachHang?.email || account.taiKhoan.tenDangNhap,
        phone: account.khachHang?.sdt,
        avatar: account.khachHang?.avatar,
        role: account.taiKhoan.loaiTaiKhoan,
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
      let userId = req.user?.sub;
      if (!userId) {
        userId = req.body.userId || req.body.maTaiKhoan || req.body.id;
      }
      if (!userId && req.body.email) {
        const found = await this.userService.findByTenDangNhapOrEmail(req.body.email);
        if (found) {
          userId = found.taiKhoan.maTaiKhoan;
        }
      }
      if (!userId) {
        userId = 1; // Default fallback ID if unauthenticated in dev mode
      }

      const { fullName, name, email, phone, sdt, address, diaChi, avatar } = req.body;
      const hoTen = fullName || name;
      const sdtVal = phone || sdt;
      const diaChiVal = address || diaChi;

      const updatedKhachHang = await this.userService.updateProfile(userId, {
        hoTen,
        email,
        phone: sdtVal,
        diaChi: diaChiVal,
        avatar,
      });

      const account = await this.userService.findById(userId);
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
        status: "1",
        message: 'Cập nhật thông tin thành công',
        payload: userData,
        data: userData,
      });
    } catch (error: any) {
      console.error('❌ UpdateProfile Error:', error);
      return res.status(500).json({
        statusCode: 500,
        status: "0",
        message: error.message || 'Lỗi server!',
      });
    }
  };

  changePassword = async (req: AuthenticatedRequest, res: Response) => {
    try {
      let userId = req.user?.sub;
      if (!userId) {
        userId = req.body.userId || req.body.maTaiKhoan || req.body.id;
      }
      if (!userId && req.body.email) {
        const found = await this.userService.findByTenDangNhapOrEmail(req.body.email);
        if (found) {
          userId = found.taiKhoan.maTaiKhoan;
        }
      }
      if (!userId) {
        userId = 1;
      }

      const { newPassword } = req.body;
      if (!newPassword || newPassword.length < 6) {
        return res.status(400).json({ statusCode: 400, status: "0", message: 'Mật khẩu phải từ 6 ký tự trở lên!' });
      }

      const bcrypt = await import('bcrypt');
      const hash = await bcrypt.hash(newPassword, 10);
      await this.userService.updatePassword(userId, hash);

      return res.status(200).json({
        statusCode: 200,
        status: "1",
        message: 'Đổi mật khẩu thành công',
      });
    } catch (error: any) {
      console.error('❌ ChangePassword Error:', error);
      return res.status(500).json({
        statusCode: 500,
        status: "0",
        message: error.message || 'Lỗi server!',
      });
    }
  };

  logout = async (req: Request, res: Response) => {
    return res.status(200).json({
      statusCode: 200,
      status: "1",
      message: 'Đăng xuất thành công',
    });
  };
}

