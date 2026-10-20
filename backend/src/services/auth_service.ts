import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { UserService } from './user_service';
import { AppDataSource } from '../config/database';
import { CuaHangModel } from '../models/cua_hang_model';

import { OAuth2Client } from 'google-auth-library';
import { TokenBlacklistService } from './token_blacklist_service';

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

  private getJwtSecret(): string {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      throw new Error('CHÚ Ý BẢO MẬT: JWT_SECRET chưa được khai báo trong file .env!');
    }
    return secret;
  }

  private getJwtRefreshSecret(): string {
    const secret = process.env.JWT_REFRESH_SECRET;
    if (!secret) {
      throw new Error('CHÚ Ý BẢO MẬT: JWT_REFRESH_SECRET chưa được khai báo trong file .env!');
    }
    return secret;
  }

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

    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(data.password, saltRounds);

    const { taiKhoan, khachHang } = await this.userService.createUser({
      tenDangNhap: data.email,
      matKhau: passwordHash,
      hoTen: data.fullName,
      email: data.email,
      phone: data.phone,
    });

    return await this.generateTokens(taiKhoan, khachHang);
  }

  async login(data: { email: string; password: string }): Promise<AuthTokens> {
    const account = await this.userService.findByTenDangNhapOrEmail(data.email);
    if (!account || !account.taiKhoan.matKhau) {
      throw new Error('Tài khoản hoặc mật khẩu không chính xác!');
    }

    const dbPassword = account.taiKhoan.matKhau;
    let isValidPassword = false;

    if (dbPassword.startsWith('$2a$') || dbPassword.startsWith('$2b$') || dbPassword.startsWith('$2y$')) {
      isValidPassword = await bcrypt.compare(data.password, dbPassword);
    } else {
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

    const tk = account.taiKhoan;
    if (tk.trangThai === 'KHOA_VINH_VIEN') {
      throw new Error(`Tài khoản của bạn đã bị khóa vĩnh viễn! Lý do: ${tk.lyDoKhoa || 'Vi phạm quy định hệ thống'}`);
    }

    if (tk.trangThai === 'KHOA_TAM_THOI' || (tk.khoaDenNgay && new Date(tk.khoaDenNgay) > new Date())) {
      const lockUntil = tk.khoaDenNgay ? new Date(tk.khoaDenNgay) : null;
      if (lockUntil && lockUntil > new Date()) {
        const dateStr = lockUntil.toLocaleDateString('vi-VN') + ' ' + lockUntil.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
        throw new Error(`Tài khoản của bạn đang bị khóa tạm thời đến ${dateStr}. Lý do: ${tk.lyDoKhoa || 'Vi phạm điều khoản'}`);
      } else if (!lockUntil && tk.trangThai === 'KHOA_TAM_THOI') {
        throw new Error(`Tài khoản của bạn đang bị khóa tạm thời. Lý do: ${tk.lyDoKhoa || 'Vi phạm điều khoản'}`);
      } else {
        tk.trangThai = 'HOAT_DONG';
        tk.khoaDenNgay = null;
        tk.lyDoKhoa = null;
        await this.userService.updatePassword(tk.maTaiKhoan, tk.matKhau);
      }
    }

    return await this.generateTokens(account.taiKhoan, account.khachHang);
  }

  async loginWithGoogle(idToken: string): Promise<AuthTokens> {
    if (!idToken || typeof idToken !== 'string' || !idToken.trim()) {
      throw new Error('Google ID Token không được để trống');
    }

    const configuredClientId = process.env.GOOGLE_CLIENT_ID || '';
    const fallbackClientId = '963558323583-t3295k9m03vpbrqjaimfp7d8o3gsaaqd.apps.googleusercontent.com';
    const client = new OAuth2Client(configuredClientId || fallbackClientId);

    let payload;
    try {
      const ticket = await client.verifyIdToken({
        idToken: idToken.trim(),
        audience: configuredClientId ? [configuredClientId, fallbackClientId] : fallbackClientId,
      });
      payload = ticket.getPayload();
    } catch (err: any) {
      console.error('❌ Google Token Verification Error:', err?.message || err);
      throw new Error('Google ID Token không hợp lệ hoặc đã hết hạn');
    }

    if (!payload || !payload.email || !payload.email_verified) {
      throw new Error('Tài khoản Google chưa xác thực email hoặc không hợp lệ');
    }

    const email = payload.email;
    const fullName = payload.name || payload.email.split('@')[0];
    const avatarUrl = payload.picture || '';

    let account = await this.userService.findByTenDangNhapOrEmail(email);

    if (!account) {
      const randomPass = Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8);
      const passwordHash = await bcrypt.hash(randomPass, 10);

      const created = await this.userService.createUser({
        tenDangNhap: email,
        matKhau: passwordHash,
        hoTen: fullName,
        email: email,
        avatar: avatarUrl,
      });

      account = { taiKhoan: created.taiKhoan, khachHang: created.khachHang };
    }

    return await this.generateTokens(account.taiKhoan, account.khachHang);
  }

  async logout(accessToken?: string, refreshToken?: string): Promise<void> {
    const blacklist = TokenBlacklistService.getInstance();

    if (accessToken) {
      try {
        const decoded: any = jwt.decode(accessToken);
        blacklist.revokeToken(accessToken, decoded?.exp, 'logout');
      } catch (_) {}
    }

    if (refreshToken) {
      try {
        const decoded: any = jwt.decode(refreshToken);
        blacklist.revokeToken(refreshToken, decoded?.exp, 'logout');
      } catch (_) {}
    }
  }

  async refreshTokens(refreshTokenStr: string): Promise<AuthTokens> {
    if (!refreshTokenStr || typeof refreshTokenStr !== 'string' || !refreshTokenStr.trim()) {
      throw new Error('Refresh token không được để trống');
    }

    const token = refreshTokenStr.trim();
    const blacklist = TokenBlacklistService.getInstance();

    let decoded: any;
    try {
      decoded = jwt.verify(token, this.getJwtRefreshSecret());
    } catch (err: any) {
      throw new Error('Refresh token không hợp lệ hoặc đã hết hạn');
    }

    if (decoded.type !== 'refresh') {
      throw new Error('Token không phải là refresh token hợp lệ');
    }

    if (blacklist.isRevoked(token, decoded)) {
      if (decoded.sub) {
        blacklist.revokeAllUserTokens(Number(decoded.sub));
      }
      throw new Error('Refresh token đã bị thu hồi hoặc đã được sử dụng');
    }

    const account = await this.userService.findById(Number(decoded.sub));
    if (!account || !account.taiKhoan) {
      throw new Error('Tài khoản không tồn tại hoặc đã bị xóa');
    }

    const tk = account.taiKhoan;
    if (tk.trangThai === 'KHOA_VINH_VIEN' || tk.trangThai === 'KHOA_TAM_THOI' || tk.trangThai === 'DA_XOA') {
      throw new Error('Tài khoản hiện đang bị khóa hoặc ngưng hoạt động');
    }

    // Refresh token rotation: Revoke the used refresh token immediately to prevent reuse attacks
    blacklist.revokeToken(token, decoded.exp, 'rotated');

    return await this.generateTokens(account.taiKhoan, account.khachHang);
  }

  private async generateTokens(taiKhoan: any, khachHang: any): Promise<AuthTokens> {
    let displayName = khachHang?.hoTen || taiKhoan.tenDangNhap;
    let displayEmail = khachHang?.email || taiKhoan.tenDangNhap;
    let avatarUrl = khachHang?.avatar;

    const userRole = String(taiKhoan.loaiTaiKhoan || '').toUpperCase();
    if (userRole === 'CUAN_HANG' || userRole === 'CUA_HANG') {
      try {
        const storeRepo = AppDataSource.getRepository(CuaHangModel);
        const store = await storeRepo.findOne({ where: { maTaiKhoan: taiKhoan.maTaiKhoan } });
        if (store) {
          displayName = store.tenQuan;
          if (store.email) displayEmail = store.email;
          if (store.img) avatarUrl = store.img;
        }
      } catch (_) {}
    }

    const jti = Math.random().toString(36).substring(2) + Date.now().toString(36);

    const payload = {
      sub: taiKhoan.maTaiKhoan,
      email: displayEmail,
      role: taiKhoan.loaiTaiKhoan,
      type: 'access',
      jti: 'acc_' + jti,
    };

    const refreshPayload = {
      sub: taiKhoan.maTaiKhoan,
      email: displayEmail,
      role: taiKhoan.loaiTaiKhoan,
      type: 'refresh',
      jti: 'ref_' + jti,
    };

    const accessToken = jwt.sign(payload, this.getJwtSecret(), { expiresIn: '7d' });
    const refreshToken = jwt.sign(refreshPayload, this.getJwtRefreshSecret(), { expiresIn: '30d' });

    return {
      accessToken,
      refreshToken,
      user: {
        id: taiKhoan.maTaiKhoan,
        username: taiKhoan.tenDangNhap,
        fullName: displayName,
        email: displayEmail,
        phone: khachHang?.sdt,
        avatar: avatarUrl,
        role: taiKhoan.loaiTaiKhoan,
      },
    };
  }
}

