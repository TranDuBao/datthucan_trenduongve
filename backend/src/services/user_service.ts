import { AppDataSource } from '../config/database';
import { TaiKhoanModel, LoaiTaiKhoan } from '../models/tai_khoan_model';
import { KhachHangModel } from '../models/khach_hang_model';

export class UserService {
  private async getTaiKhoanRepo() {
    if (!AppDataSource.isInitialized) {
      await AppDataSource.initialize();
    }
    return AppDataSource.getRepository(TaiKhoanModel);
  }

  private async getKhachHangRepo() {
    if (!AppDataSource.isInitialized) {
      await AppDataSource.initialize();
    }
    return AppDataSource.getRepository(KhachHangModel);
  }

  async findByTenDangNhapOrEmail(identifier: string): Promise<{ taiKhoan: TaiKhoanModel; khachHang?: KhachHangModel } | null> {
    const searchIdentifier = identifier.trim();
    const taiKhoanRepo = await this.getTaiKhoanRepo();
    const khachHangRepo = await this.getKhachHangRepo();

    // 1. Tìm theo tên đăng nhập
    const taiKhoan = await taiKhoanRepo.findOne({
      where: { tenDangNhap: searchIdentifier.slice(0, 50) },
    });

    if (taiKhoan) {
      const khachHang = await khachHangRepo.findOne({ where: { maTaiKhoan: taiKhoan.maTaiKhoan } });
      return { taiKhoan, khachHang: khachHang || undefined };
    }

    // 2. Tìm theo Email trong bảng KhachHang
    const khachHang = await khachHangRepo.findOne({ where: { email: searchIdentifier } });
    if (khachHang) {
      const tk = await taiKhoanRepo.findOne({ where: { maTaiKhoan: khachHang.maTaiKhoan } });
      if (tk) {
        return { taiKhoan: tk, khachHang };
      }
    }

    return null;
  }

  async findById(maTaiKhoan: number): Promise<{ taiKhoan: TaiKhoanModel; khachHang?: KhachHangModel } | null> {
    const taiKhoanRepo = await this.getTaiKhoanRepo();
    const khachHangRepo = await this.getKhachHangRepo();

    const taiKhoan = await taiKhoanRepo.findOne({ where: { maTaiKhoan } });
    if (!taiKhoan) return null;
    const khachHang = await khachHangRepo.findOne({ where: { maTaiKhoan } });
    return { taiKhoan, khachHang: khachHang || undefined };
  }

  async createUser(data: {
    tenDangNhap: string;
    matKhau: string;
    hoTen: string;
    email: string;
    phone?: string;
    avatar?: string;
  }): Promise<{ taiKhoan: TaiKhoanModel; khachHang: KhachHangModel }> {
    const taiKhoanRepo = await this.getTaiKhoanRepo();
    const khachHangRepo = await this.getKhachHangRepo();
    const tenDangNhapSafe = data.tenDangNhap.trim().slice(0, 50);

    const newTaiKhoan = taiKhoanRepo.create({
      tenDangNhap: tenDangNhapSafe,
      matKhau: data.matKhau,
      loaiTaiKhoan: LoaiTaiKhoan.KHACH_HANG,
      trangThai: 'HOAT_DONG',
    });
    const savedTaiKhoan = await taiKhoanRepo.save(newTaiKhoan);

    const newKhachHang = khachHangRepo.create({
      maTaiKhoan: savedTaiKhoan.maTaiKhoan,
      hoTen: data.hoTen,
      email: data.email,
      sdt: data.phone,
      avatar: data.avatar,
    });
    const savedKhachHang = await khachHangRepo.save(newKhachHang);

    return { taiKhoan: savedTaiKhoan, khachHang: savedKhachHang };
  }

  async updatePassword(maTaiKhoan: number, passwordHash: string): Promise<void> {
    const taiKhoanRepo = await this.getTaiKhoanRepo();
    await taiKhoanRepo.update(maTaiKhoan, { matKhau: passwordHash });
  }
}
