import { AppDataSource } from '../../config/database';
import { CuaHangModel } from '../../models/cua_hang_model';
import { TaiKhoanModel } from '../../models/tai_khoan_model';
import { KhachHangModel } from '../../models/khach_hang_model';
import { MonAnModel } from '../../models/mon_an_model';
import { DonHangModel } from '../../models/don_hang_model';
import { DanhMucModel } from '../../models/danh_muc_model';

export class AdminRestaurantService {
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private userRepo = AppDataSource.getRepository(TaiKhoanModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private foodRepo = AppDataSource.getRepository(MonAnModel);
  private orderRepo = AppDataSource.getRepository(DonHangModel);
  private categoryRepo = AppDataSource.getRepository(DanhMucModel);

  async getRestaurants(page: number = 1, limit: number = 1000, search: string = '') {
    const skip = (page - 1) * limit;
    const qb = this.storeRepo.createQueryBuilder('ch')
      .addSelect(
        `CASE WHEN ch.is_deleted = true OR UPPER(ch.trangThai) IN ('ĐÃ XÓA', 'DA_XOA', 'DELETED') THEN 1 ELSE 0 END`,
        'deleted_priority'
      )
      .orderBy('deleted_priority', 'ASC')
      .addOrderBy('ch.maQuan', 'DESC')
      .skip(skip)
      .take(limit);

    if (search.trim()) {
      qb.andWhere('(ch.tenQuan ILIKE :s OR ch.diaChi ILIKE :s OR ch.sdt ILIKE :s)', { s: `%${search.trim()}%` });
    }

    const [items, total] = await qb.getManyAndCount();

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
    if (!data.ngaySinhChuQuan || (typeof data.ngaySinhChuQuan === 'string' && !(data.ngaySinhChuQuan as string).trim())) {
      data.ngaySinhChuQuan = null;
    }
    const newStore = this.storeRepo.create(data);
    return await this.storeRepo.save(newStore);
  }

  async getRestaurantDetail(maQuan: number) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy nhà hàng');

    const foods = await this.foodRepo.find({ where: { maQuan }, order: { maMonAn: 'DESC' } });
    const orders = await this.orderRepo.find({ where: { maQuan }, order: { thoiGianDat: 'DESC' } });

    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();

    let totalRevenue = 0;
    let todayRevenue = 0;
    let monthRevenue = 0;
    let completedOrders = 0;

    for (const ord of orders) {
      const isCompleted =
        ord.trangThai === 'COMPLETED' ||
        ord.trangThai === 'HOAN_THANH' ||
        ord.trangThai === 'đã hoàn thành' ||
        ord.trangThai === 'ĐÃ HOÀN THÀNH' ||
        ord.trangThai === 'PICKED_UP';
      const amount = Number(ord.tongTien || 0);
      const ordDate = new Date(ord.thoiGianDat);

      totalRevenue += amount;
      if (isCompleted) completedOrders++;

      if (ordDate.toISOString().split('T')[0] === todayStr) {
        todayRevenue += amount;
      }

      if (ordDate.getMonth() === currentMonth && ordDate.getFullYear() === currentYear) {
        monthRevenue += amount;
      }
    }

    const chartData = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dayStr = d.toISOString().split('T')[0];
      const displayLabel = `${d.getDate()}/${d.getMonth() + 1}`;

      let dayRev = 0;
      let dayCount = 0;

      for (const ord of orders) {
        const ordDate = new Date(ord.thoiGianDat);
        if (ordDate.toISOString().split('T')[0] === dayStr) {
          dayCount++;
          dayRev += Number(ord.tongTien || 0);
        }
      }

      chartData.push({
        date: displayLabel,
        fullDate: dayStr,
        revenue: dayRev,
        ordersCount: dayCount,
      });
    }

    return {
      store,
      stats: {
        totalRevenue,
        todayRevenue,
        monthRevenue,
        totalFoods: foods.length,
        totalOrders: orders.length,
        completedOrders,
      },
      chartData,
      foods,
      recentOrders: orders,
    };
  }

  async updateRestaurant(maQuan: number, data: Partial<CuaHangModel>) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy nhà hàng');

    if (!data.ngaySinhChuQuan || (typeof data.ngaySinhChuQuan === 'string' && !(data.ngaySinhChuQuan as string).trim())) {
      data.ngaySinhChuQuan = null;
    }

    Object.assign(store, data);
    const savedStore = await this.storeRepo.save(store);

    if (savedStore.maTaiKhoan) {
      let kh = await this.khachHangRepo.findOne({ where: { maTaiKhoan: savedStore.maTaiKhoan } });
      if (kh) {
        if (data.sdt !== undefined) kh.sdt = data.sdt;
        if (data.diaChi !== undefined) kh.diaChi = data.diaChi;
        if (data.hoTenChuQuan) kh.hoTen = data.hoTenChuQuan;
        if (data.img !== undefined) kh.avatar = data.img;
        await this.khachHangRepo.save(kh);
      }
    }

    return savedStore;
  }

  async deleteRestaurant(maQuan: number) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy nhà hàng');

    store.isDeleted = true;
    store.trangThai = 'ĐÃ XÓA';
    return await this.storeRepo.save(store);
  }

  async restoreRestaurant(maQuan: number) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy nhà hàng');

    store.isDeleted = false;
    store.trangThai = 'mở cửa';
    return await this.storeRepo.save(store);
  }
}

