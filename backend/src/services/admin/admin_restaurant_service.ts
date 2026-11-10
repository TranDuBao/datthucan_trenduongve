import { AppDataSource } from '../../config/database';
import { CuaHangModel } from '../../models/cua_hang_model';
import { TaiKhoanModel } from '../../models/tai_khoan_model';
import { KhachHangModel } from '../../models/khach_hang_model';
import { MonAnModel } from '../../models/mon_an_model';
import { DonHangModel } from '../../models/don_hang_model';
import { DanhMucModel } from '../../models/danh_muc_model';
import { AuditLogService } from './audit_log_service';
import { RealtimeService } from '../realtime_service';

export class AdminRestaurantService {
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private userRepo = AppDataSource.getRepository(TaiKhoanModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private foodRepo = AppDataSource.getRepository(MonAnModel);
  private orderRepo = AppDataSource.getRepository(DonHangModel);
  private categoryRepo = AppDataSource.getRepository(DanhMucModel);
  private auditLogService = new AuditLogService();

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

    let linkedUser = null;
    if (store.maTaiKhoan) {
      linkedUser = await this.userRepo.findOne({ where: { maTaiKhoan: store.maTaiKhoan } });
    }

    // Real ratings strictly from actual user reviews in danhgia & danhgia_mon
    const dishIds = foods.map((f) => f.maMonAn);
    const realRatingsByDish = new Map<number, { avgRating: number; count: number }>();
    if (dishIds.length > 0) {
      try {
        const realDishReviews = await AppDataSource.query(`
          WITH dish_reviews_combined AS (
            SELECT 
              dgm.mamon as mamonan,
              dg.madanhgia,
              COALESCE(dgm.soluongsao, dg.soluongsao) as stars
            FROM danhgia_mon dgm
            JOIN danhgia dg ON dg.madanhgia = dgm.madanhgia
            WHERE dgm.mamon = ANY($1) AND (dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)

            UNION

            SELECT 
              ct.mamonan,
              dg.madanhgia,
              dg.soluongsao as stars
            FROM chitietdonhang ct
            JOIN danhgia dg ON dg.madonhang = ct.madonhang
            WHERE ct.mamonan = ANY($1) AND (dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)
          )
          SELECT mamonan, COUNT(DISTINCT madanhgia) as total_count, ROUND(AVG(stars)::numeric, 1) as avg_rating
          FROM dish_reviews_combined
          GROUP BY mamonan
        `, [dishIds]);

        for (const r of realDishReviews) {
          realRatingsByDish.set(Number(r.mamonan), {
            avgRating: Number(r.avg_rating || 0),
            count: Number(r.total_count || 0),
          });
        }
      } catch (e) {
        console.warn('[AdminRestaurantService] Could not aggregate real dish reviews:', e);
      }
    }

    const enrichedFoods = foods.map((f) => {
      const real = realRatingsByDish.get(f.maMonAn);
      const count = real ? real.count : 0;
      const avg = real ? real.avgRating : 0;
      return {
        ...f,
        diemDanhGiaTB: avg,
        soLuotDanhGia: count,
        chuaCoDanhGia: count === 0,
      };
    });

    let realStoreCount = 0;
    let realStoreAvg = 0.0;
    try {
      const storeReviewAgg = await AppDataSource.query(`
        SELECT 
          ROUND(AVG(soluongsao)::numeric, 2) as avg_score,
          COUNT(madanhgia) as total_reviews
        FROM danhgia
        WHERE maquan = $1 AND (is_hidden IS NOT TRUE OR is_hidden IS NULL)
      `, [maQuan]);
      if (storeReviewAgg && storeReviewAgg[0] && Number(storeReviewAgg[0].total_reviews) > 0) {
        realStoreAvg = Number(storeReviewAgg[0].avg_score) || 0;
        realStoreCount = Number(storeReviewAgg[0].total_reviews) || 0;
      }
    } catch (_) {}

    return {
      store: {
        ...store,
        danhGiaTrungBinh: realStoreAvg,
        soLuongDanhGia: realStoreCount,
        chuaCoDanhGia: realStoreCount === 0,
        taiKhoanLienKet: linkedUser ? { maTaiKhoan: linkedUser.maTaiKhoan, tenDangNhap: linkedUser.tenDangNhap } : null,
      },
      stats: {
        totalRevenue,
        todayRevenue,
        monthRevenue,
        totalFoods: foods.length,
        totalOrders: orders.length,
        completedOrders,
      },
      chartData,
      foods: enrichedFoods,
      recentOrders: orders,
    };
  }

  async updateRestaurant(maQuan: number, data: Partial<CuaHangModel>) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy nhà hàng');

    if (data.ngaySinhChuQuan !== undefined) {
      if (!data.ngaySinhChuQuan || data.ngaySinhChuQuan === 'Invalid Date' || data.ngaySinhChuQuan === '') {
        store.ngaySinhChuQuan = null;
      } else {
        const parsed = new Date(data.ngaySinhChuQuan);
        store.ngaySinhChuQuan = isNaN(parsed.getTime()) ? null : parsed;
      }
    }

    if (data.maTaiKhoan !== undefined) {
      store.maTaiKhoan = data.maTaiKhoan ? Number(data.maTaiKhoan) : null as any;
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

    try {
      RealtimeService.getInstance().emitStoreProfileUpdated(maQuan, savedStore);
    } catch (e) {
      console.error('[AdminRestaurantService] Failed to emit store profile updated:', e);
    }

    return savedStore;
  }

  async deleteRestaurant(maQuan: number) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy nhà hàng');

    const previousStatus = store.trangThai;
    store.isDeleted = true;
    store.trangThai = 'ĐÃ XÓA';
    const saved = await this.storeRepo.save(store);

    this.auditLogService.logAction({
      tenNguoiThucHien: 'Quản Trị Viên Hệ Thống',
      actorRole: 'ADMIN',
      loaiHanhDong: 'XOA_NHA_HANG',
      moTa: `Thực hiện xóa mềm nhà hàng "${store.tenQuan}" (Mã #${maQuan})`,
      doiTuong: 'CUA_HANG',
      maDoiTuong: maQuan,
      result: 'success',
      changes: { before: { isDeleted: false, trangThai: previousStatus }, after: { isDeleted: true, trangThai: 'ĐÃ XÓA' } },
    }).catch(e => console.error('[AdminRestaurantService] Audit log error:', e));

    return saved;
  }

  async restoreRestaurant(maQuan: number) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy nhà hàng');

    store.isDeleted = false;
    store.trangThai = 'mở cửa';
    const saved = await this.storeRepo.save(store);

    this.auditLogService.logAction({
      tenNguoiThucHien: 'Quản Trị Viên Hệ Thống',
      actorRole: 'ADMIN',
      loaiHanhDong: 'PHUOC_HOI_NHA_HANG',
      moTa: `Khôi phục trạng thái hoạt động cho nhà hàng "${store.tenQuan}" (Mã #${maQuan})`,
      doiTuong: 'CUA_HANG',
      maDoiTuong: maQuan,
      result: 'success',
      changes: { before: { isDeleted: true, trangThai: 'ĐÃ XÓA' }, after: { isDeleted: false, trangThai: 'mở cửa' } },
    }).catch(e => console.error('[AdminRestaurantService] Audit log error:', e));

    return saved;
  }
}

