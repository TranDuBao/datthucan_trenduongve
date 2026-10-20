import { AppDataSource } from '../config/database';
import { DonHangModel } from '../models/don_hang_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';
import { MonAnModel } from '../models/mon_an_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { DanhMucModel } from '../models/danh_muc_model';
import { VoucherModel } from '../models/voucher_model';
import { DatBanModel } from '../models/dat_ban_model';
import { BanModel } from '../models/ban_model';
import { DanhGiaModel } from '../models/danh_gia_model';
import { DanhGiaMonModel } from '../models/danh_gia_mon_model';
import { ReservationService } from './reservation_service';
import { RealtimeService } from './realtime_service';
import { NotificationService } from './notification_service';
import { RestaurantRevenueService } from './restaurant_revenue_service';
import { IsNull, Between, Not, In } from 'typeorm';
import { deleteUploadFile } from '../controllers/upload_controller';

export interface GetRestaurantOrdersQuery {
  status?: string;
  period?: string;
  from?: string;
  to?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export class RestaurantMgmtService {
  private orderRepo = AppDataSource.getRepository(DonHangModel);
  private orderItemRepo = AppDataSource.getRepository(ChiTietDonHangModel);
  private foodRepo = AppDataSource.getRepository(MonAnModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private categoryRepo = AppDataSource.getRepository(DanhMucModel);
  private voucherRepo = AppDataSource.getRepository(VoucherModel);
  private reservationService = new ReservationService();
  private revenueService = new RestaurantRevenueService();

  // ── 1. Dashboard Thống kê riêng của Nhà hàng ──────────────────────────────
  async getDashboardStats(maQuan: number) {
    return await this.revenueService.getDashboardStats(maQuan);
  }

  // ── 1b. Thống kê Doanh Thu Chi Tiết (Scope maQuan, Reconciled with Payments) ──
  async getRevenueAnalytics(maQuan: number, period: string = '7days', fromStr?: string, toStr?: string) {
    return await this.revenueService.getRevenueAnalytics(maQuan, period, fromStr, toStr);
  }
  // ── 2. Quản lý Đơn hàng (Scope maQuan) ───────────────────────────────────
  async getOrders(
    maQuan: number,
    options: GetRestaurantOrdersQuery | string = {},
    pageParam: number = 1,
    limitParam: number = 20
  ) {
    let statusFilter = '';
    let period: string | undefined;
    let fromStr: string | undefined;
    let toStr: string | undefined;
    let searchQuery: string | undefined;
    let page = 1;
    let limit = 20;

    if (typeof options === 'string') {
      statusFilter = options;
      page = pageParam;
      limit = limitParam;
    } else {
      statusFilter = options.status || '';
      period = options.period;
      fromStr = options.from;
      toStr = options.to;
      searchQuery = options.search;
      page = options.page || 1;
      limit = options.limit || 20;
    }

    const skip = (page - 1) * limit;
    // NOTE: Do NOT use leftJoin here — TypeORM raw-table leftJoin breaks andWhere conditions.
    // Customer search is handled via a separate subquery below.
    const qb = this.orderRepo.createQueryBuilder('dh')
      .where('dh.maquan = :maQuan', { maQuan });

    // 1. Time / Period Filter (Local Timezone Preservation)
    // Skip time filter when user is searching — let search results span all time
    const hasSearch = !!(searchQuery && searchQuery.trim());
    const now = new Date();
    let startDate: Date | undefined;
    let endDate: Date | undefined;

    if (!hasSearch) {
      if (period === 'today') {
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
        endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
      } else if (period === '7days') {
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6, 0, 0, 0, 0);
        endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
      } else if (period === '30days') {
        startDate = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 29, 0, 0, 0, 0);
        endDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
      } else if (fromStr || toStr) {
        if (fromStr) {
          const parts = fromStr.split('-');
          if (parts.length === 3) {
            startDate = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 0, 0, 0, 0);
          } else {
            startDate = new Date(fromStr);
            startDate.setHours(0, 0, 0, 0);
          }
        }
        if (toStr) {
          const parts = toStr.split('-');
          if (parts.length === 3) {
            endDate = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]), 23, 59, 59, 999);
          } else {
            endDate = new Date(toStr);
            endDate.setHours(23, 59, 59, 999);
          }
        }
      }

      if (startDate && endDate) {
        qb.andWhere('dh.thoigiandat >= :startDate AND dh.thoigiandat <= :endDate', { startDate, endDate });
      } else if (startDate) {
        qb.andWhere('dh.thoigiandat >= :startDate', { startDate });
      } else if (endDate) {
        qb.andWhere('dh.thoigiandat <= :endDate', { endDate });
      }
    }

    // 2. Status Filter
    const trimmedStatus = statusFilter.trim().toUpperCase();
    if (trimmedStatus && trimmedStatus !== 'ALL') {
      if (trimmedStatus === 'PENDING') {
        qb.andWhere('LOWER(dh.trangthai) IN (:...stList)', {
          stList: ['cho_xac_nhan', 'pending', 'chờ xác nhận', 'chờ xử lý'],
        });
      } else if (trimmedStatus === 'CONFIRMED') {
        qb.andWhere('LOWER(dh.trangthai) IN (:...stList)', {
          stList: ['da_xac_nhan', 'confirmed', 'đã xác nhận'],
        });
      } else if (trimmedStatus === 'PREPARING') {
        qb.andWhere('LOWER(dh.trangthai) IN (:...stList)', {
          stList: ['dang_chuan_bi', 'preparing', 'đang chuẩn bị'],
        });
      } else if (trimmedStatus === 'READY_FOR_PICKUP') {
        qb.andWhere('LOWER(dh.trangthai) IN (:...stList)', {
          stList: ['san_sang', 'ready_for_pickup', 'ready', 'sẵn sàng ghé lấy', 'sẵn sàng'],
        });
      } else if (trimmedStatus === 'COMPLETED') {
        qb.andWhere('LOWER(dh.trangthai) IN (:...stList)', {
          stList: ['hoan_tat', 'hoan_thanh', 'completed', 'picked_up', 'thành công', 'đã lấy món', 'đã hoàn thành', 'hoàn thành'],
        });
      } else if (trimmedStatus === 'CANCELLED') {
        qb.andWhere('LOWER(dh.trangthai) IN (:...stList)', {
          stList: ['da_huy', 'cancelled', 'đã hủy', 'từ chối'],
        });
      } else {
        qb.andWhere('dh.trangthai = :rawStatus', { rawStatus: statusFilter.trim() });
      }
    }

    // 3. Search Filter — NO JOIN, uses a separate subquery to avoid TypeORM raw-join issues
    if (hasSearch) {
      const q = searchQuery!.trim();
      const cleanQ = q.replace(/^#/, '');
      const numVal = Number(cleanQ);

      if (!isNaN(numVal) && numVal > 0 && /^\d+$/.test(cleanQ)) {
        // Numeric input → exact order ID match only
        qb.andWhere('dh.madonhang = :numVal', { numVal });
      } else {
        // Text input → find matching customers by name or phone
        const matchingCustomers = await this.khachHangRepo
          .createQueryBuilder('kh')
          .select('kh.makhachhang', 'id')
          .where('kh.hoten ILIKE :qLike', { qLike: `%${q}%` })
          .orWhere('kh.sdt ILIKE :qLike', { qLike: `%${q}%` })
          .getRawMany();

        const khIds = matchingCustomers
          .map((r) => Number(r.id))
          .filter((id) => !isNaN(id) && id > 0);

        if (khIds.length > 0) {
          // Filter orders by matching customer IDs
          qb.andWhere('dh.makhachhang IN (:...khIds)', { khIds });
        } else {
          // No customers matched → must return empty result set
          qb.andWhere('1 = 0');
        }
      }
    }

    qb.orderBy('dh.thoiGianDat', 'DESC')
      .skip(skip)
      .take(limit);

    const [items, total] = await qb.getManyAndCount();

    const enrichedOrders = [];
    for (const ord of items) {
      // Fetch customer
      let customerName = 'Khách hàng';
      let customerPhone = '';
      if (ord.maKhachHang) {
        const kh = await this.khachHangRepo.findOne({ where: { maKhachHang: ord.maKhachHang } });
        if (kh) {
          customerName = kh.hoTen;
          customerPhone = kh.sdt || '';
        }
      }

      // Fetch items
      const rawDetails = await this.orderItemRepo.find({ where: { maDonHang: ord.maDonHang } });
      const orderItems = [];
      let subtotal = 0;

      for (const d of rawDetails) {
        let foodName = 'Món ăn';
        let foodImg = '';
        if (d.maMonAn) {
          const f = await this.foodRepo.findOne({ where: { maMonAn: d.maMonAn } });
          if (f) {
            foodName = f.tenMonAn;
            foodImg = f.img || '';
          }
        }
        const itemPrice = Number(d.gia || 0);
        const itemQty = Number(d.soLuong || 1);
        subtotal += itemPrice * itemQty;

        orderItems.push({
          maChiTiet: d.maChiTietDon,
          maMonAn: d.maMonAn,
          tenMonAn: d.tenMonAn || foodName,
          soLuong: itemQty,
          donGia: itemPrice,
          img: foodImg,
        });
      }

      // Fetch Voucher if applied
      let voucherInfo = null;
      if (ord.maVoucher) {
        try {
          const v = await this.voucherRepo.findOne({ where: { maVoucher: ord.maVoucher } });
          if (v) {
            voucherInfo = {
              maCode: v.maCode,
              tenVoucher: v.tenVoucher,
              giamGia: Number(v.giamGia || 0),
              loaiGiam: v.loaiGiam || 'VND',
            };
          }
        } catch (e) {}
      }

      enrichedOrders.push({
        ...ord,
        tenKhachHang: customerName,
        sdtKhachHang: customerPhone,
        items: orderItems,
        tamTinh: subtotal > 0 ? subtotal : Number(ord.tongTien || 0),
        voucherInfo,
      });
    }

    const totalPages = Math.max(Math.ceil(total / limit), 1);
    return { items: enrichedOrders, total, page, limit, totalPages };
  }

  async updateOrderStatus(maQuan: number, maDonHang: number, newStatus: string, lyDo?: string) {
    const order = await this.orderRepo.findOne({ where: { maDonHang, maQuan } });
    if (!order) {
      throw new Error('Đơn hàng không tồn tại hoặc không thuộc nhà hàng này!');
    }

    // Normalize to canonical DB enum value
    const s = String(newStatus || '').trim().toUpperCase();
    let normalizedStatus: string;

    if (s === 'CHO_XAC_NHAN' || s === 'PENDING' || s.includes('CHỜ')) {
      normalizedStatus = 'CHO_XAC_NHAN';
    } else if (s === 'DA_XAC_NHAN' || s === 'CONFIRMED') {
      normalizedStatus = 'DA_XAC_NHAN';
    } else if (s === 'DANG_CHUAN_BI' || s === 'PREPARING') {
      normalizedStatus = 'DANG_CHUAN_BI';
    } else if (s === 'SAN_SANG' || s === 'READY' || s === 'READY_FOR_PICKUP') {
      normalizedStatus = 'SAN_SANG';
    } else if (s === 'HOAN_TAT' || s === 'HOAN_THANH' || s === 'COMPLETED' || s === 'PICKED_UP') {
      normalizedStatus = 'HOAN_TAT';
    } else if (s === 'DA_HUY' || s === 'CANCELLED') {
      normalizedStatus = 'DA_HUY';
    } else {
      throw new Error(`Trạng thái "${newStatus}" không hợp lệ!`);
    }

    // Prevent duplicate notification emission if status didn't change
    if (order.trangThai === normalizedStatus) {
      return order;
    }

    const prevStatus = order.trangThai;
    order.trangThai = normalizedStatus;
    if (lyDo) {
      order.lyDoHuy = lyDo;
    } else if (normalizedStatus === 'DA_HUY' && !order.lyDoHuy) {
      order.lyDoHuy = 'Quán hủy đơn';
    }
    const saved = await this.orderRepo.save(order);

    if (normalizedStatus === 'DA_HUY' && prevStatus !== 'DA_HUY') {
      try {
        const { OrderService } = await import('./order_service');
        await new OrderService().rollbackInventoryAndVoucher(maDonHang);
      } catch (rollbackErr) {
        console.error('[RestaurantMgmt] Failed to rollback inventory/voucher on order cancellation:', rollbackErr);
      }
    }

    // Emit realtime domain event
    try {
      RealtimeService.getInstance().emitOrderStatusChanged(
        saved.maQuan,
        saved.maDonHang,
        saved.trangThai,
        saved.maKhachHang,
      );
    } catch (err) {
      console.error('[RestaurantMgmt] Failed to emit order status changed event:', err);
    }

    // Persist & Emit Notifications to Customer
    try {
      const store = await this.storeRepo.findOne({ where: { maQuan } });
      const tenQuan = store?.tenQuan || 'Nhà hàng';

      if (normalizedStatus === 'DA_XAC_NHAN' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'order:confirmed',
          title: 'Đơn hàng đã được xác nhận',
          body: `${tenQuan} đã xác nhận đơn hàng #DH-${saved.maDonHang}. Quán đang tiến hành chuẩn bị.`,
          data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalizedStatus },
        });
      } else if (normalizedStatus === 'DANG_CHUAN_BI' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'order:preparing',
          title: 'Đang chuẩn bị món',
          body: `${tenQuan} đang chuẩn bị món ăn cho đơn hàng #DH-${saved.maDonHang}.`,
          data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalizedStatus },
        });
      } else if (normalizedStatus === 'SAN_SANG' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'order:ready',
          title: 'Món ăn đã sẵn sàng',
          body: `Đơn hàng #DH-${saved.maDonHang} đã sẵn sàng! Mời bạn đến ${tenQuan} để nhận món.`,
          data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalizedStatus },
        });
      } else if (normalizedStatus === 'HOAN_TAT' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'order:completed',
          title: 'Đơn hàng hoàn tất',
          body: `Đơn hàng #DH-${saved.maDonHang} đã hoàn tất. Cảm ơn bạn đã ủng hộ ${tenQuan}!`,
          data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalizedStatus },
        });
      } else if (normalizedStatus === 'DA_HUY' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'order:rejected',
          title: 'Đơn hàng đã bị từ chối / hủy',
          body: `${tenQuan} đã từ chối/hủy đơn hàng #DH-${saved.maDonHang}.${lyDo ? ` Lý do: ${lyDo}` : ''}`,
          data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalizedStatus, lyDo },
        });
      }
    } catch (notifErr) {
      console.error('[RestaurantMgmt] Failed to send status notification:', notifErr);
    }

    return saved;
  }

  // ── 3. Quản lý Menu / Thực đơn (Scope maQuan) ───────────────────────────
  async getCategories(maQuan: number) {
    const all = await this.categoryRepo.find({
      order: { maDanhMuc: 'ASC' },
    });
    // Remove duplicate names if any, keeping the most relevant
    const seen = new Set<string>();
    const unique = [];
    // Prioritize store's own categories first, then global
    const sorted = [...all].sort((a, b) => {
      if (a.maQuan === maQuan && b.maQuan !== maQuan) return -1;
      if (b.maQuan === maQuan && a.maQuan !== maQuan) return 1;
      return a.maDanhMuc - b.maDanhMuc;
    });
    for (const cat of sorted) {
      const lower = (cat.tenDanhMuc || '').trim().toLowerCase();
      if (!seen.has(lower)) {
        seen.add(lower);
        unique.push(cat);
      }
    }
    return unique;
  }

  async createCategory(maQuan: number, tenDanhMuc: string) {
    const trimmed = tenDanhMuc.trim();
    if (!trimmed) throw new Error('Tên danh mục không được để trống');
    
    // Check if category name already exists
    const existing = await this.categoryRepo.createQueryBuilder('c')
      .where('LOWER(c.tenDanhMuc) = LOWER(:name)', { name: trimmed })
      .getOne();
    if (existing) {
      return existing;
    }

    const newCat = this.categoryRepo.create({
      tenDanhMuc: trimmed,
      maQuan: maQuan,
    });
    return await this.categoryRepo.save(newCat);
  }

  async getMenu(maQuan: number) {
    const items = await this.foodRepo.find({
      where: { maQuan },
      order: { maMonAn: 'DESC' },
    });

    const categories = await this.categoryRepo.find();
    const catMap = new Map(categories.map((c) => [c.maDanhMuc, c.tenDanhMuc]));

    const danhGiaMonRepo = AppDataSource.getRepository(DanhGiaMonModel);
    const storeObj = await this.storeRepo.findOne({ where: { maQuan } });
    const storeAvg = Number(storeObj?.danhGiaTrungBinh || 0.0);

    const menuWithRatings = await Promise.all(
      items.map(async (f) => {
        const dishRatings = await danhGiaMonRepo.find({ where: { maMon: f.maMonAn } });
        let score = 0.0;
        let reviewCount = 0;
        if (dishRatings.length > 0) {
          const sum = dishRatings.reduce((acc, r) => acc + Number(r.soLuongSao || 0), 0);
          score = Math.round((sum / dishRatings.length) * 10) / 10;
          reviewCount = dishRatings.length;
        }

        return {
          ...f,
          image: f.img,
          diemDanhGiaTB: score,
          soLuotDanhGia: reviewCount,
          tenDanhMuc: f.maDanhMuc ? catMap.get(f.maDanhMuc) || `Danh mục #${f.maDanhMuc}` : 'Chưa phân loại',
        };
      })
    );

    return menuWithRatings;
  }

  async createFoodItem(maQuan: number, data: Partial<MonAnModel>) {
    const qty = data.soLuongMon !== undefined ? Number(data.soLuongMon) : 0;
    let status = data.trangThaiMon || (qty > 0 ? 'DANG_BAN' : 'HET_HANG');
    if (qty <= 0 && status !== 'TAM_NGUNG') {
      status = 'HET_HANG';
    }

    const food = this.foodRepo.create({
      ...data,
      soLuongMon: qty,
      trangThaiMon: status,
      maQuan,
    });
    return await this.foodRepo.save(food);
  }

  async updateFoodItem(maQuan: number, maMonAn: number, data: Partial<MonAnModel>) {
    const food = await this.foodRepo.findOne({ where: { maMonAn, maQuan } });
    if (!food) {
      throw new Error('Món ăn không tồn tại hoặc không thuộc quyền quản lý của quán!');
    }

    const nextQty = data.soLuongMon !== undefined ? Number(data.soLuongMon) : Number(food.soLuongMon || 0);
    let nextStatus = data.trangThaiMon || food.trangThaiMon || (nextQty > 0 ? 'DANG_BAN' : 'HET_HANG');
    if (nextQty <= 0 && nextStatus !== 'TAM_NGUNG') {
      nextStatus = 'HET_HANG';
    } else if (nextQty > 0 && nextStatus === 'HET_HANG') {
      nextStatus = 'DANG_BAN';
    }

    Object.assign(food, data, {
      soLuongMon: nextQty,
      trangThaiMon: nextStatus,
    });
    return await this.foodRepo.save(food);
  }

  async deleteFoodItem(maQuan: number, maMonAn: number) {
    const food = await this.foodRepo.findOne({ where: { maMonAn, maQuan } });
    if (!food) {
      throw new Error('Món ăn không tồn tại hoặc không thuộc quyền quản lý của quán!');
    }
    const foodImg = food.img;
    const result = await this.foodRepo.remove(food);
    if (foodImg) {
      deleteUploadFile(foodImg);
    }
    return result;
  }

  // ── 4. Quản lý Thông tin Nhà hàng (Scope maQuan) ─────────────────────────
  async getStoreProfile(maQuan: number) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy thông tin nhà hàng');

    const actualStoreId = store.maQuan;

    // 1. Total real orders belonging to this store
    const totalOrders = await this.orderRepo.count({
      where: { maQuan: actualStoreId },
    });

    // 2. Real rating aggregated across all dishes of this store
    let avgRating = 0;
    let totalReviews = 0;

    try {
      // Direct query from dish reviews (danhgia_mon joined with monan)
      const dishReviewAgg = await AppDataSource.query(`
        SELECT 
          ROUND(AVG(dm.soluongsao)::numeric, 1) as avg_score,
          COUNT(dm.madanhgiamon) as total_reviews
        FROM danhgia_mon dm
        JOIN monan m ON dm.mamon = m.mamonan
        WHERE m.maquan = $1
      `, [actualStoreId]);

      if (dishReviewAgg && dishReviewAgg[0] && Number(dishReviewAgg[0].total_reviews) > 0) {
        avgRating = Number(dishReviewAgg[0].avg_score) || 0;
        totalReviews = Number(dishReviewAgg[0].total_reviews) || 0;
      } else {
        // Fallback: check average diemDanhGiaTB across all dishes of this restaurant
        const dishScoreAgg = await this.foodRepo
          .createQueryBuilder('m')
          .select('ROUND(AVG(m.diemdanhgiatb)::numeric, 1)', 'avgScore')
          .addSelect('SUM(m.soluotdanhgia)', 'totalReviews')
          .where('m.maquan = :maQuan', { maQuan: actualStoreId })
          .andWhere('m.diemdanhgiatb > 0')
          .getRawOne();

        if (dishScoreAgg && Number(dishScoreAgg.avgScore) > 0) {
          avgRating = Number(dishScoreAgg.avgScore) || 0;
          totalReviews = Number(dishScoreAgg.totalReviews) || 0;
        } else if (store.danhGiaTrungBinh && Number(store.danhGiaTrungBinh) > 0) {
          avgRating = Number(Number(store.danhGiaTrungBinh).toFixed(1)) || 0;
          totalReviews = Number(store.soLuongDanhGia) || 0;
        }
      }
    } catch (e) {
      avgRating = Number(store.danhGiaTrungBinh || 0);
      totalReviews = Number(store.soLuongDanhGia || 0);
    }

    return {
      ...store,
      danhGia: avgRating,
      rating: avgRating,
      danhGiaTrungBinh: avgRating,
      soLuongDanhGia: totalReviews,
      tongDonHang: totalOrders,
      totalOrders: totalOrders,
    };
  }

  async updateStoreProfile(maQuan: number, data: Partial<CuaHangModel>) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy thông tin nhà hàng');

    // Only allow permitted fields to be edited by restaurant role
    if (data.tenQuan !== undefined) store.tenQuan = data.tenQuan;
    if (data.diaChi !== undefined) store.diaChi = data.diaChi;
    if (data.sdt !== undefined) store.sdt = data.sdt;
    if (data.img !== undefined) store.img = data.img;
    if (data.trangThai !== undefined) store.trangThai = data.trangThai;
    if (data.lat !== undefined) store.lat = data.lat;
    if (data.lng !== undefined) store.lng = data.lng;

    if (data.hoTenChuQuan !== undefined) store.hoTenChuQuan = data.hoTenChuQuan;
    if (data.diaChiThuongTru !== undefined) store.diaChiThuongTru = data.diaChiThuongTru;
    if (data.ngaySinhChuQuan !== undefined) {
      if (!data.ngaySinhChuQuan || data.ngaySinhChuQuan === 'Invalid Date' || data.ngaySinhChuQuan === '') {
        store.ngaySinhChuQuan = null;
      } else {
        const parsed = new Date(data.ngaySinhChuQuan);
        store.ngaySinhChuQuan = isNaN(parsed.getTime()) ? null : parsed;
      }
    }
    if (data.soCCCD !== undefined) store.soCCCD = data.soCCCD;
    if (data.tenNganHang !== undefined) store.tenNganHang = data.tenNganHang;
    if (data.soTaiKhoanNganHang !== undefined) store.soTaiKhoanNganHang = data.soTaiKhoanNganHang;
    if (data.tenChuTaiKhoan !== undefined) store.tenChuTaiKhoan = data.tenChuTaiKhoan;
    if (data.cccdMatTruoc !== undefined) store.cccdMatTruoc = data.cccdMatTruoc;
    if (data.cccdMatSau !== undefined) store.cccdMatSau = data.cccdMatSau;

    if (data.moTa !== undefined) store.moTa = data.moTa;
    if (data.email !== undefined) store.email = data.email;
    if (data.danhMuc !== undefined) store.danhMuc = data.danhMuc;
    if (data.gioHoatDong !== undefined) store.gioHoatDong = data.gioHoatDong;
    if (data.thoiGianChuanBi !== undefined) store.thoiGianChuanBi = data.thoiGianChuanBi;
    if (data.coChoDatTruoc !== undefined) store.coChoDatTruoc = data.coChoDatTruoc;
    if (data.tienIch !== undefined) store.tienIch = data.tienIch;

    const savedStore = await this.storeRepo.save(store);

    // Bidirectional sync: update user khachHang profile if account is linked
    if (savedStore.maTaiKhoan) {
      let kh = await this.khachHangRepo.findOne({ where: { maTaiKhoan: savedStore.maTaiKhoan } });
      if (kh) {
        if (data.hoTenChuQuan) kh.hoTen = data.hoTenChuQuan;
        if (data.sdt !== undefined) kh.sdt = data.sdt;
        if (data.diaChi !== undefined) kh.diaChi = data.diaChi;
        if (data.img !== undefined) kh.avatar = data.img;
        await this.khachHangRepo.save(kh);
      }
    }

    try {
      RealtimeService.getInstance().emitStoreProfileUpdated(maQuan, savedStore);
    } catch (e) {
      console.error('[RestaurantMgmt] Failed to emit store profile updated:', e);
    }

    return savedStore;
  }

  // ── Get Reviews for a specific food item (owned by this store) ─────────────
  async getFoodReviews(maQuan: number, maMonAn: number, page = 1, limit = 10) {
    const food = await this.foodRepo.findOne({ where: { maMonAn, maQuan } });
    if (!food) {
      throw new Error('Món ăn không tồn tại hoặc không thuộc quán này');
    }

    const danhGiaMonRepo = AppDataSource.getRepository(DanhGiaMonModel);
    const danhGiaRepo = AppDataSource.getRepository(DanhGiaModel);
    const chiTietRepo = AppDataSource.getRepository(ChiTietDonHangModel);
    const skip = (page - 1) * limit;

    const dishRatingRecords = await danhGiaMonRepo.find({ where: { maMon: maMonAn } });
    const reviewIds = dishRatingRecords.map((dr) => dr.maDanhGia);

    const chiTietList = await chiTietRepo.find({ where: { maMonAn } });
    const orderIds = chiTietList.map((c) => c.maDonHang).filter(Boolean);
    const chiTietIds = chiTietList.map((c) => c.maChiTietDon).filter(Boolean);

    let rawReviews: any[] = [];
    let total = 0;

    let qb = danhGiaRepo.createQueryBuilder('dg')
      .where('(dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)');

    if (reviewIds.length > 0 || orderIds.length > 0 || chiTietIds.length > 0) {
      const conditions: string[] = [];
      const params: Record<string, any> = {};

      if (reviewIds.length > 0) {
        conditions.push('dg.madanhgia IN (:...reviewIds)');
        params.reviewIds = reviewIds;
      }
      if (orderIds.length > 0) {
        conditions.push('dg.madonhang IN (:...orderIds)');
        params.orderIds = orderIds;
      }
      if (chiTietIds.length > 0) {
        conditions.push('dg.machitietdon IN (:...chiTietIds)');
        params.chiTietIds = chiTietIds;
      }

      qb = qb.andWhere(`(${conditions.join(' OR ')})`, params);
      [rawReviews, total] = await qb.orderBy('dg.ngaynhanxet', 'DESC').skip(skip).take(limit).getManyAndCount();
    }

    const reviews = await Promise.all(
      rawReviews.map(async (dg: any) => {
        let customerName = 'Khách hàng';
        let customerAvatar = '';
        if (dg.maKhachHang || dg.makhachhang) {
          const kh = await this.khachHangRepo.findOne({ where: { maKhachHang: dg.maKhachHang || dg.makhachhang } });
          if (kh) {
            customerName = kh.hoTen;
            customerAvatar = kh.avatar || '';
          }
        }

        // Find dish specific rating comment if available
        const dishRating = dishRatingRecords.find((dr) => dr.maDanhGia === dg.maDanhGia || dr.maDanhGia === dg.madanhgia);

        return {
          maDanhGia: dg.maDanhGia || dg.madanhgia,
          soLuongSao: Number(dishRating?.soLuongSao || dg.soLuongSao || dg.soluongsao || 5),
          nhanXet: dishRating?.nhanXet || dg.nhanXet || dg.nhanxet || '',
          hinhAnh: dg.hinhAnh || dg.hinhanh || '',
          phanHoi: dg.phanHoi || dg.phanhoi || '',
          ngayNhanXet: dg.ngayNhanXet || dg.ngaynhanxet,
          customerName,
          customerAvatar,
        };
      }),
    );

    const breakdown: Record<number, number> = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    reviews.forEach((r) => {
      const s = Math.min(5, Math.max(1, Math.round(r.soLuongSao)));
      breakdown[s] = (breakdown[s] || 0) + 1;
    });

    const sumStars = reviews.reduce((sum, r) => sum + r.soLuongSao, 0);
    const avg = total > 0 ? sumStars / reviews.length : 0;

    return {
      reviews,
      total,
      totalPages: Math.max(1, Math.ceil(total / limit)),
      summary: {
        avg: Math.round(avg * 10) / 10,
        total,
        breakdown,
      },
      foodName: food.tenMonAn,
    };
  }
}

