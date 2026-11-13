import { AppDataSource } from '../../config/database';
import { In } from 'typeorm';
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

  async getRestaurantDetail(maQuan: number, filters?: { singleDate?: string; fromDate?: string; toDate?: string }) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy nhà hàng');

    const foods = await this.foodRepo.find({ where: { maQuan }, order: { maMonAn: 'DESC' } });
    const orders = await this.orderRepo.find({ where: { maQuan }, order: { thoiGianDat: 'DESC' } });

    const isCompleted = (ord: DonHangModel) => {
      const st = (ord.trangThai || '').toUpperCase();
      return (
        st === 'HOAN_TAT' ||
        st === 'DA_HOAN_TAT' ||
        st === 'HOÀN TẤT' ||
        st === 'COMPLETED' ||
        st === 'HOAN_THANH' ||
        st === 'đã hoàn thành' ||
        st === 'ĐÃ HOÀN THÀNH' ||
        st === 'DA_HOAN_THANH' ||
        st === 'PICKED_UP' ||
        st === 'PAID' ||
        st === 'DA_THANH_TOAN'
      ) && !['DA_HUY', 'CANCELLED', 'THAT_BAI', 'CHO_THANH_TOAN', 'UNPAID'].includes(st);
    };

    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();

    let totalRevenue = 0;
    let todayRevenue = 0;
    let monthRevenue = 0;
    let completedOrders = 0;

    for (const ord of orders) {
      if (isCompleted(ord)) {
        const amount = Number(ord.tongTien || 0);
        const ordDate = new Date(ord.thoiGianDat);

        totalRevenue += amount;
        completedOrders++;

        if (ordDate.toISOString().split('T')[0] === todayStr) {
          todayRevenue += amount;
        }

        if (ordDate.getMonth() === currentMonth && ordDate.getFullYear() === currentYear) {
          monthRevenue += amount;
        }
      }
    }

    // Build 7-day trend (for backward compat and day tab)
    const dayTrend = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dayStr = d.toISOString().split('T')[0];
      const displayLabel = `${d.getDate()}/${d.getMonth() + 1}`;

      let dayRev = 0;
      let dayCount = 0;
      const dayOrderIds: number[] = [];

      for (const ord of orders) {
        if (!isCompleted(ord)) continue;
        const ordDate = new Date(ord.thoiGianDat);
        if (ordDate.toISOString().split('T')[0] === dayStr) {
          dayCount++;
          dayRev += Number(ord.tongTien || 0);
          dayOrderIds.push(Number(ord.maDonHang));
        }
      }

      dayTrend.push({
        date: displayLabel,
        label: displayLabel,
        fullDate: dayStr,
        revenue: dayRev,
        ordersCount: dayCount,
        orders: dayCount,
        orderIds: dayOrderIds,
      });
    }

    // Build 4-week trend
    const weekTrend = [];
    for (let i = 3; i >= 0; i--) {
      const endDay = new Date(now);
      endDay.setDate(now.getDate() - i * 7);
      const startDay = new Date(endDay);
      startDay.setDate(endDay.getDate() - 6);
      startDay.setHours(0, 0, 0, 0);
      endDay.setHours(23, 59, 59, 999);

      let weekRev = 0;
      let weekCount = 0;
      const weekOrderIds: number[] = [];
      for (const ord of orders) {
        if (!isCompleted(ord)) continue;
        const ordDate = new Date(ord.thoiGianDat);
        if (ordDate >= startDay && ordDate <= endDay) {
          weekCount++;
          weekRev += Number(ord.tongTien || 0);
          weekOrderIds.push(Number(ord.maDonHang));
        }
      }
      weekTrend.push({
        label: `Tuần ${4 - i}`,
        fullDate: `${startDay.getDate()}/${startDay.getMonth() + 1} - ${endDay.getDate()}/${endDay.getMonth() + 1}`,
        revenue: weekRev,
        orders: weekCount,
        ordersCount: weekCount,
        orderIds: weekOrderIds,
      });
    }

    // Build 12-month trend for the current year (T1 -> T12)
    const monthTrend = [];
    for (let m = 0; m < 12; m++) {
      let mRev = 0;
      let mCount = 0;
      const monthOrderIds: number[] = [];
      for (const ord of orders) {
        if (!isCompleted(ord)) continue;
        const ordDate = new Date(ord.thoiGianDat);
        if (ordDate.getMonth() === m && ordDate.getFullYear() === currentYear) {
          mCount++;
          mRev += Number(ord.tongTien || 0);
          monthOrderIds.push(Number(ord.maDonHang));
        }
      }
      monthTrend.push({
        label: `T${m + 1}`,
        fullDate: `Tháng ${m + 1}/${currentYear}`,
        revenue: mRev,
        orders: mCount,
        ordersCount: mCount,
        orderIds: monthOrderIds,
      });
    }

    // Build 5-year trend
    const yearTrend = [];
    for (let i = 4; i >= 0; i--) {
      const y = now.getFullYear() - i;
      let yRev = 0;
      let yCount = 0;
      const yearOrderIds: number[] = [];
      for (const ord of orders) {
        if (!isCompleted(ord)) continue;
        const ordDate = new Date(ord.thoiGianDat);
        if (ordDate.getFullYear() === y) {
          yCount++;
          yRev += Number(ord.tongTien || 0);
          yearOrderIds.push(Number(ord.maDonHang));
        }
      }
      yearTrend.push({
        label: `${y}`,
        fullDate: `Năm ${y}`,
        revenue: yRev,
        orders: yCount,
        ordersCount: yCount,
        orderIds: yearOrderIds,
      });
    }

    // Custom trend if singleDate or fromDate/toDate is provided
    let customTrend: any[] = [];
    if (filters?.singleDate) {
      const targetDate = filters.singleDate;
      const hours = [
        { label: '00h - 04h', start: 0, end: 4 },
        { label: '04h - 08h', start: 4, end: 8 },
        { label: '08h - 11h', start: 8, end: 11 },
        { label: '11h - 14h', start: 11, end: 14 },
        { label: '14h - 17h', start: 14, end: 17 },
        { label: '17h - 20h', start: 17, end: 20 },
        { label: '20h - 24h', start: 20, end: 24 },
      ];
      for (const h of hours) {
        let rev = 0;
        let count = 0;
        const hourOrderIds: number[] = [];
        for (const ord of orders) {
          if (!isCompleted(ord)) continue;
          const ordDate = new Date(ord.thoiGianDat);
          const dateStr = ordDate.toISOString().split('T')[0];
          const hour = ordDate.getHours();
          if (dateStr === targetDate && hour >= h.start && hour < h.end) {
            count++;
            rev += Number(ord.tongTien || 0);
            hourOrderIds.push(Number(ord.maDonHang));
          }
        }
        customTrend.push({
          label: h.label,
          fullDate: targetDate,
          revenue: rev,
          orders: count,
          ordersCount: count,
          orderIds: hourOrderIds,
        });
      }
    } else if (filters?.fromDate && filters?.toDate) {
      const start = new Date(filters.fromDate);
      const end = new Date(filters.toDate);
      const diffDays = Math.min(Math.max(Math.ceil((end.getTime() - start.getTime()) / (1000 * 3600 * 24)) + 1, 1), 60);

      for (let i = 0; i < diffDays; i++) {
        const cur = new Date(start);
        cur.setDate(start.getDate() + i);
        const curStr = cur.toISOString().split('T')[0];
        const displayLabel = `${cur.getDate()}/${cur.getMonth() + 1}`;

        let rev = 0;
        let count = 0;
        const rangeOrderIds: number[] = [];
        for (const ord of orders) {
          if (!isCompleted(ord)) continue;
          const ordDate = new Date(ord.thoiGianDat);
          if (ordDate.toISOString().split('T')[0] === curStr) {
            count++;
            rev += Number(ord.tongTien || 0);
            rangeOrderIds.push(Number(ord.maDonHang));
          }
        }
        customTrend.push({
          label: displayLabel,
          fullDate: curStr,
          revenue: rev,
          orders: count,
          ordersCount: count,
          orderIds: rangeOrderIds,
        });
      }
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
      chartData: dayTrend,
      revenueTrend: {
        day: dayTrend,
        week: weekTrend,
        month: monthTrend,
        year: yearTrend,
        custom: customTrend.length > 0 ? customTrend : undefined,
      },
      customTrend: customTrend.length > 0 ? customTrend : undefined,
      foods: enrichedFoods,
      recentOrders: orders,
    };
  }

  async getRestaurantComparison(
    restaurantIds: number[],
    timeframe: string = 'day',
    singleDate?: string,
    fromDate?: string,
    toDate?: string
  ) {
    if (!restaurantIds || restaurantIds.length === 0) {
      const topStores = await this.storeRepo.find({
        where: { isDeleted: false },
        take: 3,
      });
      restaurantIds = topStores.map((s) => s.maQuan);
    }

    const stores = await this.storeRepo.find({
      where: { maQuan: In(restaurantIds) },
    });

    const orders = await this.orderRepo.find({
      where: { maQuan: In(restaurantIds) },
      order: { thoiGianDat: 'ASC' },
    });

    const isCompleted = (ord: DonHangModel) => {
      const st = (ord.trangThai || '').toUpperCase();
      return (
        st === 'HOAN_TAT' ||
        st === 'DA_HOAN_TAT' ||
        st === 'HOÀN TẤT' ||
        st === 'COMPLETED' ||
        st === 'HOAN_THANH' ||
        st === 'đã hoàn thành' ||
        st === 'ĐÃ HOÀN THÀNH' ||
        st === 'DA_HOAN_THANH' ||
        st === 'PICKED_UP' ||
        st === 'PAID' ||
        st === 'DA_THANH_TOAN'
      ) && !['DA_HUY', 'CANCELLED', 'THAT_BAI', 'CHO_THANH_TOAN', 'UNPAID'].includes(st);
    };

    interface Slot {
      key: string;
      label: string;
      fullDate?: string;
      matches: (date: Date) => boolean;
    }

    const slots: Slot[] = [];
    const now = new Date();

    if (singleDate) {
      const targetDateStr = singleDate;
      const hours = [
        { label: '00h - 04h', start: 0, end: 4 },
        { label: '04h - 08h', start: 4, end: 8 },
        { label: '08h - 11h', start: 8, end: 11 },
        { label: '11h - 14h', start: 11, end: 14 },
        { label: '14h - 17h', start: 14, end: 17 },
        { label: '17h - 20h', start: 17, end: 20 },
        { label: '20h - 24h', start: 20, end: 24 },
      ];
      for (const h of hours) {
        slots.push({
          key: h.label,
          label: h.label,
          fullDate: targetDateStr,
          matches: (d: Date) => {
            const dateStr = d.toISOString().split('T')[0];
            const hour = d.getHours();
            return dateStr === targetDateStr && hour >= h.start && hour < h.end;
          },
        });
      }
    } else if (fromDate && toDate) {
      const start = new Date(fromDate);
      const end = new Date(toDate);
      const diffDays = Math.min(Math.max(Math.ceil((end.getTime() - start.getTime()) / (1000 * 3600 * 24)) + 1, 1), 60);

      for (let i = 0; i < diffDays; i++) {
        const cur = new Date(start);
        cur.setDate(start.getDate() + i);
        const curStr = cur.toISOString().split('T')[0];
        const displayLabel = `${cur.getDate()}/${cur.getMonth() + 1}`;
        slots.push({
          key: curStr,
          label: displayLabel,
          fullDate: curStr,
          matches: (d: Date) => d.toISOString().split('T')[0] === curStr,
        });
      }
    } else if (timeframe === 'week') {
      for (let i = 3; i >= 0; i--) {
        const endDay = new Date(now);
        endDay.setDate(now.getDate() - i * 7);
        const startDay = new Date(endDay);
        startDay.setDate(endDay.getDate() - 6);
        startDay.setHours(0, 0, 0, 0);
        endDay.setHours(23, 59, 59, 999);

        slots.push({
          key: `week_${i}`,
          label: `Tuần ${4 - i}`,
          fullDate: `${startDay.getDate()}/${startDay.getMonth() + 1} - ${endDay.getDate()}/${endDay.getMonth() + 1}`,
          matches: (d: Date) => d >= startDay && d <= endDay,
        });
      }
    } else if (timeframe === 'month') {
      const currentYear = now.getFullYear();
      for (let m = 0; m < 12; m++) {
        slots.push({
          key: `m_${currentYear}_${m}`,
          label: `T${m + 1}`,
          fullDate: `Tháng ${m + 1}/${currentYear}`,
          matches: (date: Date) => date.getMonth() === m && date.getFullYear() === currentYear,
        });
      }
    } else if (timeframe === 'year') {
      for (let i = 4; i >= 0; i--) {
        const y = now.getFullYear() - i;
        slots.push({
          key: `year_${y}`,
          label: `${y}`,
          fullDate: `Năm ${y}`,
          matches: (date: Date) => date.getFullYear() === y,
        });
      }
    } else {
      // Default: 'day' (7 days)
      for (let i = 6; i >= 0; i--) {
        const d = new Date(now);
        d.setDate(now.getDate() - i);
        const dayStr = d.toISOString().split('T')[0];
        const displayLabel = `${d.getDate()}/${d.getMonth() + 1}`;
        slots.push({
          key: dayStr,
          label: displayLabel,
          fullDate: dayStr,
          matches: (date: Date) => date.toISOString().split('T')[0] === dayStr,
        });
      }
    }

    const comparisonResults = stores.map((store) => {
      const storeOrders = orders.filter((o) => o.maQuan === store.maQuan && isCompleted(o));
      let totalRevenue = 0;
      let totalOrders = 0;

      const series = slots.map((slot) => {
        let slotRevenue = 0;
        let slotOrders = 0;

        for (const ord of storeOrders) {
          const ordDate = new Date(ord.thoiGianDat);
          if (slot.matches(ordDate)) {
            slotOrders++;
            slotRevenue += Number(ord.tongTien || 0);
          }
        }

        totalRevenue += slotRevenue;
        totalOrders += slotOrders;

        return {
          slotKey: slot.key,
          label: slot.label,
          fullDate: slot.fullDate,
          revenue: slotRevenue,
          orders: slotOrders,
        };
      });

      return {
        maQuan: store.maQuan,
        tenQuan: store.tenQuan,
        diaChi: store.diaChi,
        img: store.img,
        trangThai: store.trangThai,
        totalRevenue,
        totalOrders,
        avgOrderValue: totalOrders > 0 ? Math.round(totalRevenue / totalOrders) : 0,
        series,
      };
    });

    return {
      timeSlots: slots.map((s) => ({ key: s.key, label: s.label, fullDate: s.fullDate })),
      restaurants: comparisonResults,
      timeframe,
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

