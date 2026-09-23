import { AppDataSource } from '../config/database';
import { TaiKhoanModel } from '../models/tai_khoan_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { DanhMucModel } from '../models/danh_muc_model';
import { MonAnModel } from '../models/mon_an_model';
import { DonHangModel } from '../models/don_hang_model';
import { ThanhToanModel } from '../models/thanh_toan_model';

export class AdminService {
  private userRepo = AppDataSource.getRepository(TaiKhoanModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private categoryRepo = AppDataSource.getRepository(DanhMucModel);
  private foodRepo = AppDataSource.getRepository(MonAnModel);
  private orderRepo = AppDataSource.getRepository(DonHangModel);
  private paymentRepo = AppDataSource.getRepository(ThanhToanModel);

  // ── 1. Thống kê Dashboard Admin toàn hệ thống ─────────────────────────────────
  async getDashboardStats() {
    const totalUsers = await this.userRepo.count();
    const totalRestaurants = await this.storeRepo.count();
    const totalOrders = await this.orderRepo.count();

    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayOrders = await this.orderRepo
      .createQueryBuilder('donhang')
      .where('donhang.thoigiandat >= :todayStart', { todayStart })
      .getCount();

    const revenueResult = await this.orderRepo
      .createQueryBuilder('donhang')
      .select('SUM(donhang.tongtien)', 'sum')
      .where('donhang.trangthai IN (:...completedStatuses)', {
        completedStatuses: ['HOAN_THANH', 'COMPLETED', 'PICKED_UP', 'thành công', 'Đã lấy món'],
      })
      .getRawOne();
    const totalRevenue = Number(revenueResult?.sum || 0);

    const processingOrders = await this.orderRepo
      .createQueryBuilder('donhang')
      .where('donhang.trangthai IN (:...processingStatuses)', {
        processingStatuses: ['PENDING', 'chờ xử lý', 'CONFIRMED', 'đã xác nhận', 'PREPARING', 'đang chuẩn bị'],
      })
      .getCount();

    const pickupWaitingOrders = await this.orderRepo
      .createQueryBuilder('donhang')
      .where('donhang.trangthai IN (:...waitingStatuses)', {
        waitingStatuses: ['READY_FOR_PICKUP', 'sẵn sàng ghé lấy', 'Sẵn sàng'],
      })
      .getCount();

    const activeRestaurants = await this.storeRepo
      .createQueryBuilder('cuahang')
      .where('LOWER(cuahang.trangthai) IN (:...activeStatuses)', {
        activeStatuses: ['mở cửa', 'hoat_dong', 'open', 'hoạt động'],
      })
      .getCount();

    const recentOrdersRaw = await this.orderRepo
      .createQueryBuilder('donhang')
      .orderBy('donhang.thoigiandat', 'DESC')
      .take(8)
      .getMany();

    const recentOrders = [];
    for (const ord of recentOrdersRaw) {
      let storeName = 'Chưa xác định';
      let customerName = 'Khách hàng';
      if (ord.maQuan) {
        const s = await this.storeRepo.findOne({ where: { maQuan: ord.maQuan } });
        if (s) storeName = s.tenQuan;
      }
      if (ord.maKhachHang) {
        const c = await this.khachHangRepo.findOne({ where: { maKhachHang: ord.maKhachHang } });
        if (c) customerName = c.hoTen;
      }
      recentOrders.push({
        ...ord,
        tenQuan: storeName,
        tenKhachHang: customerName,
      });
    }

    return {
      totalUsers,
      totalRestaurants,
      totalOrders,
      todayOrders,
      totalRevenue,
      processingOrders,
      pickupWaitingOrders,
      activeRestaurants,
      recentOrders,
    };
  }

  // ── 2. Quản lý Người dùng ──────────────────────────────────────────────────
  async getUsers(page: number = 1, limit: number = 10, search: string = '', roleFilter: string = '') {
    const skip = (page - 1) * limit;
    const qb = this.userRepo.createQueryBuilder('tk')
      .leftJoinAndSelect('tk.khachHang', 'kh')
      .orderBy('tk.maTaiKhoan', 'DESC')
      .skip(skip)
      .take(limit);

    if (search.trim()) {
      qb.andWhere('(tk.tenDangNhap ILIKE :s OR kh.hoTen ILIKE :s OR kh.email ILIKE :s OR kh.sdt ILIKE :s)', {
        s: `%${search.trim()}%`,
      });
    }

    if (roleFilter.trim()) {
      qb.andWhere('tk.loaiTaiKhoan = :role', { role: roleFilter.trim() });
    }

    const [items, total] = await qb.getManyAndCount();
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async updateUserRole(maTaiKhoan: number, loaiTaiKhoan: string, trangThai?: string) {
    const account = await this.userRepo.findOne({ where: { maTaiKhoan } });
    if (!account) throw new Error('Không tìm thấy tài khoản');
    account.loaiTaiKhoan = loaiTaiKhoan;
    if (trangThai) account.trangThai = trangThai;
    return await this.userRepo.save(account);
  }

  // ── 3. Quản lý Nhà hàng ────────────────────────────────────────────────────
  async getRestaurants(page: number = 1, limit: number = 10, search: string = '') {
    const skip = (page - 1) * limit;
    const qb = this.storeRepo.createQueryBuilder('ch')
      .orderBy('ch.maQuan', 'DESC')
      .skip(skip)
      .take(limit);

    if (search.trim()) {
      qb.andWhere('(ch.tenQuan ILIKE :s OR ch.diaChi ILIKE :s OR ch.sdt ILIKE :s)', { s: `%${search.trim()}%` });
    }

    const [items, total] = await qb.getManyAndCount();

    // Attach linked account info
    const enriched = [];
    for (const item of items) {
      let linkedUser = null;
      if (item.maTaiKhoan) {
        linkedUser = await this.userRepo.findOne({ where: { maTaiKhoan: item.maTaiKhoan } });
      }
      enriched.push({
        ...item,
        taiKhoanLienKet: linkedUser ? { maTaiKhoan: linkedUser.maTaiKhoan, tenDangNhap: linkedUser.tenDangNhap } : null,
      });
    }

    return { items: enriched, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async createRestaurant(data: Partial<CuaHangModel>) {
    const newStore = this.storeRepo.create(data);
    return await this.storeRepo.save(newStore);
  }

  async updateRestaurant(maQuan: number, data: Partial<CuaHangModel>) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy nhà hàng');
    Object.assign(store, data);
    return await this.storeRepo.save(store);
  }

  // ── 4. Quản lý Danh mục & Món ăn ─────────────────────────────────────────
  async getCategories() {
    return await this.categoryRepo.find({ order: { maDanhMuc: 'ASC' } });
  }

  async createCategory(tenDanhMuc: string) {
    const cat = this.categoryRepo.create({ tenDanhMuc });
    return await this.categoryRepo.save(cat);
  }

  async getFoods(page: number = 1, limit: number = 10, search: string = '', maQuan?: number) {
    const skip = (page - 1) * limit;
    const qb = this.foodRepo.createQueryBuilder('m')
      .orderBy('m.maMonAn', 'DESC')
      .skip(skip)
      .take(limit);

    if (search.trim()) {
      qb.andWhere('m.tenMonAn ILIKE :s', { s: `%${search.trim()}%` });
    }

    if (maQuan) {
      qb.andWhere('m.maQuan = :maQuan', { maQuan });
    }

    const [items, total] = await qb.getManyAndCount();
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async updateFood(maMonAn: number, data: Partial<MonAnModel>) {
    const food = await this.foodRepo.findOne({ where: { maMonAn } });
    if (!food) throw new Error('Không tìm thấy món ăn');
    Object.assign(food, data);
    return await this.foodRepo.save(food);
  }

  // ── 5. Quản lý Đơn hàng & Thanh toán ───────────────────────────────────────
  async getOrders(page: number = 1, limit: number = 10, status: string = '', search: string = '') {
    const skip = (page - 1) * limit;
    const qb = this.orderRepo.createQueryBuilder('dh')
      .orderBy('dh.thoiGianDat', 'DESC')
      .skip(skip)
      .take(limit);

    if (status.trim()) {
      qb.andWhere('dh.trangThai = :status', { status });
    }

    if (search.trim()) {
      qb.andWhere('CAST(dh.maDonHang AS TEXT) ILIKE :s', { s: `%${search.trim()}%` });
    }

    const [items, total] = await qb.getManyAndCount();
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async getPayments(page: number = 1, limit: number = 10) {
    const skip = (page - 1) * limit;
    const [items, total] = await this.paymentRepo.findAndCount({
      order: { maThanhToan: 'DESC' },
      skip,
      take: limit,
    });
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }
}
