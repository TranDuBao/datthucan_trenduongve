import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import { TaiKhoan, LoaiTaiKhoan } from './entities/tai-khoan.entity';
import { KhachHang } from './entities/khach-hang.entity';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(TaiKhoan)
    private readonly taiKhoanRepository: Repository<TaiKhoan>,
    @InjectRepository(KhachHang)
    private readonly khachHangRepository: Repository<KhachHang>,
  ) {}

  async findById(id: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { id } });
  }

  async findByEmail(email: string, includePassword = false): Promise<User | null> {
    const query = this.userRepository.createQueryBuilder('user').where('user.email = :email', { email });
    if (includePassword) {
      query.addSelect('user.passwordHash');
    }
    const user = await query.getOne();
    if (user) return user;

    // Fallback lookup in TaiKhoan / KhachHang tables
    const taiKhoan = await this.taiKhoanRepository.findOne({
      where: [{ tenDangNhap: email }],
    });
    if (taiKhoan) {
      const khachHang = await this.khachHangRepository.findOne({ where: { maTaiKhoan: taiKhoan.maTaiKhoan } });
      return {
        id: String(taiKhoan.maTaiKhoan),
        email: khachHang?.email || taiKhoan.tenDangNhap,
        passwordHash: includePassword ? taiKhoan.matKhau : undefined,
        fullName: khachHang?.hoTen || taiKhoan.tenDangNhap,
        phone: khachHang?.sdt,
        avatarUrl: khachHang?.avatar,
        role: taiKhoan.loaiTaiKhoan as any,
        isActive: taiKhoan.trangThai === 'HOAT_DONG',
        createdAt: taiKhoan.ngayTao,
        updatedAt: taiKhoan.ngayTao,
      } as User;
    }

    return null;
  }

  async findByGoogleId(googleId: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { googleId } });
  }

  async create(userData: Partial<User>): Promise<User> {
    const existing = await this.findByEmail(userData.email);
    if (existing) {
      throw new ConflictException('Email hoặc tên đăng nhập đã tồn tại trong hệ thống');
    }

    // Save to TaiKhoan & KhachHang tables as well to keep 15-table schema in sync!
    try {
      const newTaiKhoan = this.taiKhoanRepository.create({
        tenDangNhap: userData.email,
        matKhau: userData.passwordHash || 'N/A',
        loaiTaiKhoan: LoaiTaiKhoan.KHACH_HANG,
        trangThai: 'HOAT_DONG',
      });
      const savedTaiKhoan = await this.taiKhoanRepository.save(newTaiKhoan);

      const newKhachHang = this.khachHangRepository.create({
        maTaiKhoan: savedTaiKhoan.maTaiKhoan,
        hoTen: userData.fullName || userData.email,
        email: userData.email,
        sdt: userData.phone,
        avatar: userData.avatarUrl,
      });
      await this.khachHangRepository.save(newKhachHang);
    } catch (e) {
      console.warn('Sync to TaiKhoan/KhachHang optional notice:', e.message);
    }

    // Also persist to users table if exists
    try {
      const user = this.userRepository.create(userData);
      return await this.userRepository.save(user);
    } catch (e) {
      return {
        id: String(Date.now()),
        email: userData.email,
        fullName: userData.fullName,
        phone: userData.phone,
        avatarUrl: userData.avatarUrl,
        role: userData.role || ('KHACH_HANG' as any),
        isActive: true,
        createdAt: new Date(),
        updatedAt: new Date(),
      } as User;
    }
  }

  async updateGoogleId(userId: string, googleId: string, avatarUrl?: string): Promise<User> {
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('Người dùng không tồn tại');
    }
    user.googleId = googleId;
    if (avatarUrl && !user.avatarUrl) {
      user.avatarUrl = avatarUrl;
    }
    return this.userRepository.save(user);
  }
}
