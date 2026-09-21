import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { UserService } from './user_service';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  user: {
    id: number;
    username: string;
    fullName: string;
    email: string;
    phone?: string;
    avatar?: string;
    role: string;
  };
}

export class AuthService {
  private userService = new UserService();
  private jwtSecret = process.env.JWT_SECRET || 'super_secret_key_smart_city_food_route_2026';
  private jwtRefreshSecret = process.env.JWT_REFRESH_SECRET || 'super_refresh_secret_key_2026';

  async register(data: {
    email: string;
    password: string;
    fullName: string;
    phone?: string;
  }): Promise<AuthTokens> {
    const existing = await this.userService.findByTenDangNhapOrEmail(data.email);
    if (existing) {
      throw new Error('Email hoặc tên đăng nhập đã tồn tại!');
    }

    // 1. Mã hoá mật khẩu với Bcrypt (Salt rounds = 10)
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(data.password, saltRounds);

    // 2. Lưu chuỗi mật khẩu ĐÃ MÃ HOÁ vào CSDL
    const { taiKhoan, khachHang } = await this.userService.createUser({
      tenDangNhap: data.email,
      matKhau: passwordHash,
      hoTen: data.fullName,
      email: data.email,
      phone: data.phone,
    });

    return this.generateTokens(taiKhoan, khachHang);
  }

  async login(data: { email: string; password: string }): Promise<AuthTokens> {
    const account = await this.userService.findByTenDangNhapOrEmail(data.email);
    if (!account || !account.taiKhoan.matKhau) {
      throw new Error('Tài khoản hoặc mật khẩu không chính xác!');
    }

    const dbPassword = account.taiKhoan.matKhau;
    let isValidPassword = false;

    // 3. Kiểm tra mã hoá Bcrypt ($2a$, $2b$, $2y$)
    if (dbPassword.startsWith('$2a$') || dbPassword.startsWith('$2b$') || dbPassword.startsWith('$2y$')) {
      isValidPassword = await bcrypt.compare(data.password, dbPassword);
    } else {
      // Nếu dữ liệu mẫu CSDL cũ lưu chữ thường (ví dụ: 'matkhau123'), kiểm tra & tự động nâng cấp sang mã hoá Bcrypt Hash
      if (data.password === dbPassword) {
        isValidPassword = true;
        const newHash = await bcrypt.hash(data.password, 10);
        await this.userService.updatePassword(account.taiKhoan.maTaiKhoan, newHash);
        console.log(`🔒 Đã tự động mã hóa Bcrypt Hash cho maTaiKhoan: ${account.taiKhoan.maTaiKhoan}`);
      }
    }

    if (!isValidPassword) {
      throw new Error('Tài khoản hoặc mật khẩu không chính xác!');
    }

    if (account.taiKhoan.trangThai !== 'HOAT_DONG') {
      throw new Error('Tài khoản đã bị tạm khóa!');
    }

    return this.generateTokens(account.taiKhoan, account.khachHang);
  }

  async loginWithGoogle(data: {
    googleId: string;
    email: string;
    fullName: string;
    avatarUrl?: string;
  }): Promise<AuthTokens> {
    let account = await this.userService.findByTenDangNhapOrEmail(data.email);

    if (!account) {
      const randomPass = Math.random().toString(36).slice(-8);
      const passwordHash = await bcrypt.hash(randomPass, 10);

      const created = await this.userService.createUser({
        tenDangNhap: data.email,
        matKhau: passwordHash,
        hoTen: data.fullName,
        email: data.email,
        avatar: data.avatarUrl,
      });

      account = { taiKhoan: created.taiKhoan, khachHang: created.khachHang };
    }

    return this.generateTokens(account.taiKhoan, account.khachHang);
  }

  private generateTokens(taiKhoan: any, khachHang: any): AuthTokens {
    const payload = {
      sub: taiKhoan.maTaiKhoan,
      email: khachHang?.email || taiKhoan.tenDangNhap,
      role: taiKhoan.loaiTaiKhoan,
    };

    const accessToken = jwt.sign(payload, this.jwtSecret, { expiresIn: '7d' });
    const refreshToken = jwt.sign(payload, this.jwtRefreshSecret, { expiresIn: '30d' });

    return {
      accessToken,
      refreshToken,
      user: {
        id: taiKhoan.maTaiKhoan,
        username: taiKhoan.tenDangNhap,
        fullName: khachHang?.hoTen || taiKhoan.tenDangNhap,
        email: khachHang?.email || taiKhoan.tenDangNhap,
        phone: khachHang?.sdt,
        avatar: khachHang?.avatar,
        role: taiKhoan.loaiTaiKhoan,
      },
    };
  }
}
