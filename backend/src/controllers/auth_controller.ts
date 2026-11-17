import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import { AuthService } from '../services/auth_service';
import { UserService } from '../services/user_service';
import { AdminService } from '../services/admin_service';
import { EmailService } from '../services/email_service';
import { AuthenticatedRequest } from '../middlewares/auth_middleware';
import { sanitizeErrorMessage } from '../utils/error_sanitizer';
import { AppDataSource } from '../config/database';
import { OtpModel } from '../models/otp_model';
import { TaiKhoanModel } from '../models/tai_khoan_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { TokenBlacklistService } from '../services/token_blacklist_service';

export class AuthController {
  private authService = new AuthService();
  private userService = new UserService();
  private auditLogService = new (require('../services/admin/audit_log_service').AuditLogService)();

  registerRequestOtp = async (req: Request, res: Response) => {
    try {
      const email = (req.body.email || '').trim().toLowerCase();
      const fullName = (req.body.fullName || req.body.name || '').trim();

      if (!email) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Vui lòng cung cấp địa chỉ email hợp lệ!',
        });
      }

      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Định dạng email không hợp lệ!',
        });
      }

      // Kiểm tra xem email đã được đăng ký trước đó chưa
      const existing = await this.userService.findByTenDangNhapOrEmail(email);
      if (existing) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Email này đã được sử dụng. Vui lòng đăng nhập hoặc sử dụng email khác!',
        });
      }

      // Tạo mã OTP 6 chữ số ngẫu nhiên
      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

      // Lưu mã OTP vào CSDL (hết hạn sau 5 phút)
      const otpRepo = AppDataSource.getRepository(OtpModel);
      await otpRepo.update({ email, daSuDung: false, loai: 'REGISTER' }, { daSuDung: true });

      const hetHanLuc = new Date(Date.now() + 5 * 60 * 1000);
      const otpEntity = otpRepo.create({
        email,
        otpCode,
        loai: 'REGISTER',
        daSuDung: false,
        hetHanLuc,
      });
      await otpRepo.save(otpEntity);

      // Gửi email xác thực tài khoản qua SMTP
      const sendResult = await EmailService.getInstance().sendOtpEmail({
        toEmail: email,
        otpCode,
        recipientName: fullName,
        type: 'REGISTER',
      });

      if (!sendResult.success) {
        console.warn(`[Auth] SMTP không khả dụng trên cloud (Render chặn port SMTP). Fallback OTP cho ${email}: >>> ${otpCode} <<<`);
        return res.status(200).json({
          statusCode: 200,
          status: '1',
          message: `Do máy chủ Cloud chặn cổng gửi mail, mã OTP của bạn là: ${otpCode}`,
          payload: { email, otp: otpCode, cloudFallback: true },
          data: { email, otp: otpCode, cloudFallback: true },
        });
      }

      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Mã xác thực OTP đã được gửi đến email của bạn!',
        payload: { email },
        data: { email },
      });
    } catch (error: any) {
      return res.status(500).json({
        statusCode: 500,
        status: '0',
        message: sanitizeErrorMessage(error, 'Lỗi hệ thống khi gửi mã xác thực đăng ký'),
      });
    }
  };

  register = async (req: Request, res: Response) => {
    try {
      const email = (req.body.email || '').trim().toLowerCase();
      const password = req.body.password;
      const fullName = (req.body.fullName || req.body.name || '').trim();
      const phone = (req.body.phone || req.body.mobile || req.body.sdt || '').trim();
      const address = (req.body.address || req.body.diaChi || '').trim();
      const otp = (req.body.otp || req.body.reset_code || '').trim();

      if (!email || !password || !fullName) {
        return res.status(400).json({
          statusCode: 400,
          status: "0",
          message: 'Vui lòng nhập đầy đủ email, mật khẩu và họ tên!',
        });
      }

      // Xác thực mã OTP gửi về email bắt buộc
      if (!otp) {
        return res.status(400).json({
          statusCode: 400,
          status: "0",
          message: 'Vui lòng nhập mã xác thực OTP (6 chữ số) đã được gửi đến email của bạn!',
        });
      }

      const otpRepo = AppDataSource.getRepository(OtpModel);
      const otpRecord = await otpRepo.findOne({
        where: { email, otpCode: otp, daSuDung: false, loai: 'REGISTER' },
        order: { ngayTao: 'DESC' },
      });

      if (!otpRecord) {
        return res.status(400).json({
          statusCode: 400,
          status: "0",
          message: 'Mã xác thực OTP không chính xác hoặc đã qua sử dụng!',
        });
      }

      if (new Date() > new Date(otpRecord.hetHanLuc)) {
        return res.status(400).json({
          statusCode: 400,
          status: "0",
          message: 'Mã OTP đã hết hiệu lực (chỉ có giá trị trong 5 phút). Vui lòng yêu cầu mã mới!',
        });
      }

      const result = await this.authService.register({ email, password, fullName, phone, address });

      // Đánh dấu OTP đã sử dụng
      otpRecord.daSuDung = true;
      await otpRepo.save(otpRecord);

      try {
        const clientIp = req.ip || req.headers['x-forwarded-for']?.toString() || req.socket.remoteAddress || '127.0.0.1';
        this.auditLogService.logAction({
          maTaiKhoan: result?.user?.id,
          tenNguoiThucHien: fullName,
          actorEmail: email,
          actorRole: 'USER',
          loaiHanhDong: 'DANG_KY_TAI_KHOAN_MOI',
          moTa: `Tài khoản người dùng mới vừa đăng ký và xác thực email thành công: ${fullName} (${email})`,
          doiTuong: 'TAI_KHOAN',
          maDoiTuong: result?.user?.id,
          result: 'success',
          ipAddress: clientIp,
        }).catch(() => {});
      } catch (e) {}

      return res.status(201).json({
        statusCode: 201,
        status: "1",
        message: 'Đăng ký tài khoản thành công',
        payload: result,
        data: result,
      });
    } catch (error: any) {
      console.error('[AuthController] [Error] Register Error:', error);
      return res.status(400).json({
        statusCode: 400,
        status: "0",
        message: sanitizeErrorMessage(error, 'Hệ thống đang gặp lỗi, vui lòng thử lại'),
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
      try {
        const clientIp = req.ip || req.headers['x-forwarded-for']?.toString() || req.socket.remoteAddress || '127.0.0.1';
        const role = String(result?.user?.role || '').toUpperCase();
        if (role === 'ADMIN' || role === 'CUAN_HANG' || role === 'CUA_HANG' || role === 'RESTAURANT') {
          this.auditLogService.logAction({
            maTaiKhoan: result.user.id,
            tenNguoiThucHien: result.user.username || result.user.email || 'Quản trị viên',
            actorEmail: result.user.email,
            actorRole: role,
            loaiHanhDong: role === 'ADMIN' ? 'DANG_NHAP_ADMIN_THANH_CONG' : 'DANG_NHAP_CUAN_HANG_THANH_CONG',
            moTa: `Đăng nhập quản trị hệ thống thành công với vai trò ${role}`,
            doiTuong: 'HE_THONG_ADMIN',
            result: 'success',
            ipAddress: clientIp,
          }).catch(() => {});
        }
      } catch (e) {}
      return res.status(200).json({
        statusCode: 200,
        status: "1",
        message: 'Đăng nhập thành công',
        payload: result,
        data: result,
      });
    } catch (error: any) {
      console.error('[AuthController] [Error] Login Error:', error);
      try {
        const clientIp = req.ip || req.headers['x-forwarded-for']?.toString() || req.socket.remoteAddress || '127.0.0.1';
        this.auditLogService.logAction({
          tenNguoiThucHien: 'Khách / Vãng lai',
          actorEmail: req.body?.email || 'N/A',
          actorRole: 'ANONYMOUS',
          loaiHanhDong: 'CANH_BAO_DANG_NHAP',
          moTa: `Cảnh báo đăng nhập thất bại với tài khoản "${req.body?.email || ''}". Lý do: ${error.message}`,
          doiTuong: 'XAC_THUC',
          result: 'failed',
          reason: error.message,
          ipAddress: clientIp,
        }).catch(() => {});
      } catch (e) {}
      return res.status(401).json({
        statusCode: 401,
        status: "0",
        message: sanitizeErrorMessage(error, 'Đăng nhập thất bại, vui lòng kiểm tra lại tài khoản hoặc thử lại sau!'),
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
      console.error('[AuthController] [Error] Google Auth Error:', error);
      return res.status(400).json({
        statusCode: 400,
        status: "0",
        message: sanitizeErrorMessage(error, 'Đăng nhập Google thất bại, vui lòng thử lại sau!'),
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
      console.error('[AuthController] [Error] GetProfile Error:', error);
      return res.status(500).json({
        statusCode: 500,
        status: "0",
        message: sanitizeErrorMessage(error, 'Hệ thống đang gặp lỗi, vui lòng thử lại'),
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
      console.error('[AuthController] [Error] UpdateProfile Error:', error);
      return res.status(500).json({
        statusCode: 500,
        status: '0',
        message: sanitizeErrorMessage(error, 'Hệ thống đang gặp lỗi, vui lòng thử lại'),
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
      console.error('[AuthController] [Error] ChangePassword Error:', error);
      return res.status(500).json({
        statusCode: 500,
        status: '0',
        message: sanitizeErrorMessage(error, 'Hệ thống đang gặp lỗi, vui lòng thử lại'),
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
        message: sanitizeErrorMessage(error, 'Làm mới token thất bại, vui lòng thử lại'),
      });
    }
  };

  refreshProfile = async (req: AuthenticatedRequest, res: Response) => {
    try {
      const userId = Number(req.user?.sub);
      if (!userId) {
        return res.status(401).json({ statusCode: 401, status: '0', message: 'Bạn cần đăng nhập' });
      }
      const result = await this.authService.refreshProfileSession(userId);
      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Làm mới phiên thành công',
        payload: result,
        data: result,
      });
    } catch (error: any) {
      return res.status(500).json({ statusCode: 500, status: '0', message: sanitizeErrorMessage(error, 'Hệ thống đang gặp lỗi, vui lòng thử lại') });
    }
  };
  scanCCCD = async (req: Request, res: Response) => {
    try {
      const { image, frontImage, backImage, side } = req.body;
      const adminService = new AdminService();
      const result = await adminService.scanCCCD({ image, frontImage, backImage, side }, side);
      return res.status(200).json({ statusCode: 200, status: '1', data: result });
    } catch (error: any) {
      return res.status(400).json({ statusCode: 400, message: sanitizeErrorMessage(error, 'Quét CCCD thất bại, vui lòng thử lại') });
    }
  };

  forgotPasswordRequest = async (req: Request, res: Response) => {
    try {
      const email = (req.body.email || '').trim().toLowerCase();
      if (!email) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Vui lòng cung cấp địa chỉ email hợp lệ!',
        });
      }

      // Kiểm tra tài khoản có tồn tại không
      const user = await this.userService.findByTenDangNhapOrEmail(email);
      if (!user) {
        return res.status(404).json({
          statusCode: 404,
          status: '0',
          message: 'Không tìm thấy tài khoản nào gắn với email này!',
        });
      }

      // Tạo mã OTP ngẫu nhiên 6 chữ số
      const otpCode = Math.floor(100000 + Math.random() * 900000).toString();

      // Lưu mã OTP vào CSDL (hết hạn sau 5 phút)
      const otpRepo = AppDataSource.getRepository(OtpModel);
      // Vô hiệu hóa các OTP cũ chưa sử dụng của email này
      await otpRepo.update({ email, daSuDung: false, loai: 'FORGOT_PASSWORD' }, { daSuDung: true });

      const hetHanLuc = new Date(Date.now() + 5 * 60 * 1000);
      const otpEntity = otpRepo.create({
        email,
        otpCode,
        loai: 'FORGOT_PASSWORD',
        daSuDung: false,
        hetHanLuc,
      });
      await otpRepo.save(otpEntity);

      // Gửi email OTP
      const recipientName = user.khachHang?.hoTen || user.taiKhoan.tenDangNhap;
      const sendResult = await EmailService.getInstance().sendOtpEmail({
        toEmail: email,
        otpCode,
        recipientName,
      });

      if (!sendResult.success) {
        console.warn(`[Auth] SMTP không khả dụng trên cloud (Render chặn port SMTP). Fallback OTP quên MK cho ${email}: >>> ${otpCode} <<<`);
        return res.status(200).json({
          statusCode: 200,
          status: '1',
          message: `Do máy chủ Cloud chặn cổng gửi mail, mã OTP của bạn là: ${otpCode}`,
          payload: { email, otp: otpCode, cloudFallback: true },
          data: { email, otp: otpCode, cloudFallback: true },
        });
      }

      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Mã xác thực OTP đã được gửi đến email của bạn!',
        payload: { email },
        data: { email },
      });
    } catch (error: any) {
      return res.status(500).json({
        statusCode: 500,
        status: '0',
        message: sanitizeErrorMessage(error, 'Lỗi hệ thống khi gửi mã OTP'),
      });
    }
  };

  forgotPasswordVerify = async (req: Request, res: Response) => {
    try {
      const email = (req.body.email || '').trim().toLowerCase();
      const resetCode = (req.body.reset_code || req.body.otp || '').trim();

      if (!email || !resetCode) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Vui lòng nhập đầy đủ email và mã xác thực OTP (6 chữ số)!',
        });
      }

      const otpRepo = AppDataSource.getRepository(OtpModel);
      const otpRecord = await otpRepo.findOne({
        where: { email, otpCode: resetCode, daSuDung: false, loai: 'FORGOT_PASSWORD' },
        order: { ngayTao: 'DESC' },
      });

      if (!otpRecord) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Mã OTP không chính xác hoặc đã được sử dụng!',
        });
      }

      if (new Date() > new Date(otpRecord.hetHanLuc)) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Mã OTP đã hết hiệu lực (chỉ có giá trị trong 5 phút). Vui lòng yêu cầu gửi lại!',
        });
      }

      const user = await this.userService.findByTenDangNhapOrEmail(email);
      if (!user) {
        return res.status(404).json({
          statusCode: 404,
          status: '0',
          message: 'Không tìm thấy tài khoản người dùng tương ứng!',
        });
      }

      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Xác thực OTP thành công!',
        payload: {
          user_id: user.taiKhoan.maTaiKhoan,
          reset_code: resetCode,
          email,
        },
        data: {
          user_id: user.taiKhoan.maTaiKhoan,
          reset_code: resetCode,
          email,
        },
      });
    } catch (error: any) {
      return res.status(500).json({
        statusCode: 500,
        status: '0',
        message: sanitizeErrorMessage(error, 'Lỗi hệ thống khi xác thực OTP'),
      });
    }
  };

  forgotPasswordSetNew = async (req: Request, res: Response) => {
    try {
      const userId = Number(req.body.user_id);
      const resetCode = (req.body.reset_code || '').trim();
      const newPassword = req.body.new_password;

      if (!userId || !resetCode || !newPassword) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Vui lòng cung cấp đầy đủ thông tin đặt lại mật khẩu!',
        });
      }

      if (typeof newPassword !== 'string' || newPassword.length < 6) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Mật khẩu mới phải có tối thiểu 6 ký tự!',
        });
      }

      const otpRepo = AppDataSource.getRepository(OtpModel);
      const otpRecord = await otpRepo.findOne({
        where: { otpCode: resetCode, daSuDung: false, loai: 'FORGOT_PASSWORD' },
        order: { ngayTao: 'DESC' },
      });

      if (!otpRecord) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Mã xác thực không hợp lệ hoặc đã qua sử dụng!',
        });
      }

      if (new Date() > new Date(otpRecord.hetHanLuc)) {
        return res.status(400).json({
          statusCode: 400,
          status: '0',
          message: 'Phiên xác thực đã hết hạn. Vui lòng thực hiện lại từ đầu!',
        });
      }

      const taiKhoanRepo = AppDataSource.getRepository(TaiKhoanModel);
      const taiKhoan = await taiKhoanRepo.findOne({
        where: { maTaiKhoan: userId },
      });

      if (!taiKhoan) {
        return res.status(404).json({
          statusCode: 404,
          status: '0',
          message: 'Không tìm thấy tài khoản người dùng!',
        });
      }

      // Hash mật khẩu mới với bcrypt
      const saltRounds = 10;
      taiKhoan.matKhau = await bcrypt.hash(newPassword, saltRounds);
      await taiKhoanRepo.save(taiKhoan);

      // Đánh dấu OTP đã sử dụng
      otpRecord.daSuDung = true;
      await otpRepo.save(otpRecord);

      // Thu hồi tất cả phiên đăng nhập cũ của tài khoản để đảm bảo an toàn
      try {
        TokenBlacklistService.getInstance().revokeAllUserTokens(userId);
      } catch (_) {}

      // Ghi audit log
      try {
        const clientIp = req.ip || req.headers['x-forwarded-for']?.toString() || req.socket.remoteAddress || '127.0.0.1';
        this.auditLogService.logAction({
          maTaiKhoan: userId,
          tenNguoiThucHien: taiKhoan.tenDangNhap,
          actorEmail: otpRecord.email,
          actorRole: taiKhoan.loaiTaiKhoan,
          loaiHanhDong: 'DAT_LAI_MAT_KHAU_OTP',
          moTa: `Người dùng đặt lại mật khẩu thành công qua Email OTP (${otpRecord.email})`,
          doiTuong: 'TAI_KHOAN',
          maDoiTuong: userId,
          result: 'success',
          ipAddress: clientIp,
        }).catch(() => {});
      } catch (_) {}

      return res.status(200).json({
        statusCode: 200,
        status: '1',
        message: 'Đổi mật khẩu thành công! Vui lòng đăng nhập bằng mật khẩu mới.',
        payload: {},
        data: {},
      });
    } catch (error: any) {
      return res.status(500).json({
        statusCode: 500,
        status: '0',
        message: sanitizeErrorMessage(error, 'Lỗi hệ thống khi cập nhật mật khẩu mới'),
      });
    }
  };
}

