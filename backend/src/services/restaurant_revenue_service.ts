import { AppDataSource } from '../config/database';
import { DonHangModel } from '../models/don_hang_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';
import { MonAnModel } from '../models/mon_an_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { DatBanModel } from '../models/dat_ban_model';
import { ThanhToanModel } from '../models/thanh_toan_model';
import { ReservationService } from './reservation_service';
import { In } from 'typeorm';

export class RestaurantRevenueService {
  private orderRepo = AppDataSource.getRepository(DonHangModel);
  private orderItemRepo = AppDataSource.getRepository(ChiTietDonHangModel);
  private foodRepo = AppDataSource.getRepository(MonAnModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private paymentRepo = AppDataSource.getRepository(ThanhToanModel);
  private reservationService = new ReservationService();

  // ── 1. Dashboard Thống kê riêng của Nhà hàng ──────────────────────────────
  async getDashboardStats(maQuan: number) {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayOrdersCount = await this.orderRepo
      .createQueryBuilder('dh')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.thoigiandat >= :todayStart', { todayStart })
      .getCount();

    const upcomingPickupCount = await this.orderRepo
      .createQueryBuilder('dh')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.trangthai IN (:...statuses)', {
        statuses: ['DA_XAC_NHAN', 'CONFIRMED', 'đã xác nhận', 'DANG_CHUAN_BI', 'PREPARING', 'đang chuẩn bị'],
      })
      .getCount();

    const preparingCount = await this.orderRepo
      .createQueryBuilder('dh')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.trangthai IN (:...statuses)', {
        statuses: ['DANG_CHUAN_BI', 'PREPARING', 'đang chuẩn bị'],
      })
      .getCount();

    const readyCount = await this.orderRepo
      .createQueryBuilder('dh')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.trangthai IN (:...statuses)', {
        statuses: ['SAN_SANG', 'READY_FOR_PICKUP', 'READY', 'sẵn sàng ghé lấy', 'Sẵn sàng'],
      })
      .getCount();

    const revenueRaw = await this.orderRepo
      .createQueryBuilder('dh')
      .select('SUM(dh.tongtien)', 'sum')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.trangthai IN (:...completedStatuses)', {
        completedStatuses: ['HOAN_TAT', 'HOAN_THANH', 'COMPLETED', 'PICKED_UP', 'thành công', 'Đã lấy món'],
      })
      .getRawOne();
    const revenue = Number(revenueRaw?.sum || 0);

    // Fetch recent 5 orders
    const rawRecentOrders = await this.orderRepo.find({
      where: { maQuan },
      order: { thoiGianDat: 'DESC' },
      take: 5,
    });

    const recentOrders = [];
    for (const ord of rawRecentOrders) {
      let customerName = 'Khách hàng';
      let customerPhone = '';
      if (ord.maKhachHang) {
        try {
          const kh = await this.khachHangRepo.findOne({ where: { maKhachHang: ord.maKhachHang } });
          if (kh) {
            customerName = kh.hoTen || 'Khách hàng';
            customerPhone = kh.sdt || '';
          }
        } catch (e) {}
      }
      recentOrders.push({
        maDonHang: ord.maDonHang,
        thoiGianDat: ord.thoiGianDat,
        tenKhachHang: customerName,
        sdtKhachHang: customerPhone,
        trangThai: ord.trangThai,
        tongTien: Number(ord.tongTien || 0),
        phuongThucThanhToan: ord.phuongThucThanhToan || 'COD',
      });
    }

    // Thống kê đặt bàn đồng bộ 100% với ReservationService
    const reservationStats = await this.reservationService.getDashboardStats(maQuan);

    const datBanRepo = AppDataSource.getRepository(DatBanModel);
    const rawRecentReservations = await datBanRepo.find({
      where: { maQuan },
      relations: ['ban', 'khachHang'],
      order: { thoiGianBatDau: 'DESC' },
      take: 5,
    });

    const recentReservations = rawRecentReservations.map((r) => ({
      maDatBan: r.maDatBan,
      maBan: r.maBan,
      tenBan: r.ban?.tenBan || `Bàn #${r.maBan}`,
      tenKhachHang: r.tenKhachHang || r.khachHang?.hoTen || 'Khách hàng',
      sdtKhachHang: r.sdtKhachHang || r.khachHang?.sdt || '',
      soNguoi: r.soNguoi,
      thoiGianBatDau: r.thoiGianBatDau,
      thoiGianKetThuc: r.thoiGianKetThuc,
      trangThai: r.trangThai,
    }));

    return {
      pendingReservationsCount: reservationStats.choXacNhan,
      todayReservationsCount: reservationStats.homNay,
      tablesInUseCount: reservationStats.dangSuDung,
      todayOrdersCount,
      upcomingPickupCount,
      preparingCount,
      readyCount,
      revenue,
      recentOrders,
      recentReservations,
    };
  }

  // ── 1b. Thống kê Doanh Thu Chi Tiết (Scope maQuan, Reconciled with Payments) ──
  async getRevenueAnalytics(maQuan: number, period: string = '7days', fromStr?: string, toStr?: string) {
    const now = new Date();
    let startDate = new Date();
    let endDate = new Date();
    let prevStartDate = new Date();
    let prevEndDate = new Date();

    const normalizedPeriod = (period || '7days').toLowerCase();

    if (normalizedPeriod === 'today') {
      startDate.setHours(0, 0, 0, 0);
      endDate.setHours(23, 59, 59, 999);

      prevStartDate = new Date(startDate);
      prevStartDate.setDate(prevStartDate.getDate() - 1);
      prevEndDate = new Date(endDate);
      prevEndDate.setDate(prevEndDate.getDate() - 1);
    } else if (normalizedPeriod === '7days') {
      startDate.setDate(now.getDate() - 6);
      startDate.setHours(0, 0, 0, 0);
      endDate.setHours(23, 59, 59, 999);

      prevStartDate = new Date(startDate);
      prevStartDate.setDate(prevStartDate.getDate() - 7);
      prevEndDate = new Date(startDate);
      prevEndDate.setMilliseconds(-1);
    } else if (normalizedPeriod === '30days') {
      startDate.setDate(now.getDate() - 29);
      startDate.setHours(0, 0, 0, 0);
      endDate.setHours(23, 59, 59, 999);

      prevStartDate = new Date(startDate);
      prevStartDate.setDate(prevStartDate.getDate() - 30);
      prevEndDate = new Date(startDate);
      prevEndDate.setMilliseconds(-1);
    } else if (normalizedPeriod === 'this_month') {
      startDate = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
      endDate.setHours(23, 59, 59, 999);

      prevStartDate = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0, 0);
      prevEndDate = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);
    } else if (normalizedPeriod === 'last_month') {
      startDate = new Date(now.getFullYear(), now.getMonth() - 1, 1, 0, 0, 0, 0);
      endDate = new Date(now.getFullYear(), now.getMonth(), 0, 23, 59, 59, 999);

      prevStartDate = new Date(now.getFullYear(), now.getMonth() - 2, 1, 0, 0, 0, 0);
      prevEndDate = new Date(now.getFullYear(), now.getMonth() - 1, 0, 23, 59, 59, 999);
    } else if (normalizedPeriod === 'custom' && fromStr && toStr) {
      startDate = new Date(fromStr);
      endDate = new Date(toStr);
      if (isNaN(startDate.getTime())) startDate = new Date(now.setDate(now.getDate() - 7));
      if (isNaN(endDate.getTime())) endDate = new Date();
      endDate.setHours(23, 59, 59, 999);

      const diffMs = endDate.getTime() - startDate.getTime();
      prevStartDate = new Date(startDate.getTime() - diffMs);
      prevEndDate = new Date(startDate.getTime() - 1);
    } else {
      startDate.setDate(now.getDate() - 6);
      startDate.setHours(0, 0, 0, 0);
      endDate.setHours(23, 59, 59, 999);
    }

    const completedStatuses = ['HOAN_TAT', 'HOAN_THANH', 'COMPLETED', 'PICKED_UP', 'thành công', 'Đã lấy món', 'đã hoàn thành'];

    // 1. Fetch all orders for this store in time range
    const orders = await this.orderRepo.createQueryBuilder('dh')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.thoigiandat >= :startDate AND dh.thoigiandat <= :endDate', { startDate, endDate })
      .orderBy('dh.thoigiandat', 'ASC')
      .getMany();

    // 2. Fetch payments for reconciliation
    const orderIds = orders.map((o) => o.maDonHang).filter(Boolean);
    let payments: ThanhToanModel[] = [];
    if (orderIds.length > 0) {
      payments = await this.paymentRepo.find({
        where: { maDonHang: In(orderIds) },
      });
    }
    const paymentMap = new Map<number, ThanhToanModel>();
    for (const p of payments) {
      paymentMap.set(p.maDonHang, p);
    }

    // 3. Fetch previous period revenue for growth percentage calculation
    const prevRevenueRaw = await this.orderRepo.createQueryBuilder('dh')
      .select('SUM(dh.tongtien)', 'sum')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.trangthai IN (:...completedStatuses)', { completedStatuses })
      .andWhere('dh.thoigiandat >= :prevStartDate AND dh.thoigiandat <= :prevEndDate', { prevStartDate, prevEndDate })
      .getRawOne();

    const previousPeriodRevenue = Number(prevRevenueRaw?.sum || 0);

    // 4. Compute Summary & Payment Reconciliation
    const totalOrders = orders.length;
    let completedOrders = 0;
    let cancelledOrders = 0;
    let totalRevenue = 0;
    let onlineRevenue = 0;
    let cashRevenue = 0;
    let paidOrdersCount = 0;
    let unpaidOrdersCount = 0;

    for (const ord of orders) {
      const st = String(ord.trangThai || '').toLowerCase().trim();
      const isComp = completedStatuses.some((s) => st.includes(s.toLowerCase()));
      const isCanc = st === 'da_huy' || st === 'cancelled' || st.includes('hủy') || st.includes('huy');

      const p = paymentMap.get(ord.maDonHang);
      const isPaidOnline = p?.trangThai === 'THANH_TOAN_THANH_CONG';
      const isCash = (ord.phuongThucThanhToan || '').toUpperCase().includes('TIEN_MAT') ||
                     (ord.phuongThucThanhToan || '').toUpperCase() === 'COD';

      let isPaid = false;
      if (isPaidOnline) {
        isPaid = true;
      } else if (isComp && isCash) {
        isPaid = true;
      }

      if (isComp) {
        completedOrders++;
        totalRevenue += Number(ord.tongTien || 0);
      } else if (isCanc) {
        cancelledOrders++;
      }

      if (isPaid) {
        paidOrdersCount++;
        if (isPaidOnline) {
          onlineRevenue += Number(p?.soTien || ord.tongTien || 0);
        } else {
          cashRevenue += Number(ord.tongTien || 0);
        }
      } else if (!isCanc) {
        unpaidOrdersCount++;
      }
    }

    const averageOrderValue = completedOrders > 0 ? totalRevenue / completedOrders : 0;
    let growthRate = 0;
    if (previousPeriodRevenue > 0) {
      growthRate = Number((((totalRevenue - previousPeriodRevenue) / previousPeriodRevenue) * 100).toFixed(1));
    } else if (totalRevenue > 0) {
      growthRate = 100;
    }

    // 5. Time-Series Chart Data
    const chart = [];
    if (normalizedPeriod === 'today') {
      for (let h = 0; h < 24; h += 3) {
        const slotStart = new Date(startDate);
        slotStart.setHours(h, 0, 0, 0);
        const slotEnd = new Date(startDate);
        slotEnd.setHours(h + 2, 59, 59, 999);

        const slotLabel = `${h.toString().padStart(2, '0')}:00`;
        let slotRev = 0;
        let slotCount = 0;

        for (const ord of orders) {
          const ordDate = new Date(ord.thoiGianDat || Date.now());
          const st = String(ord.trangThai || '').toLowerCase().trim();
          const isComp = completedStatuses.some((s) => st.includes(s.toLowerCase()));
          if (ordDate >= slotStart && ordDate <= slotEnd) {
            slotCount++;
            if (isComp) slotRev += Number(ord.tongTien || 0);
          }
        }
        chart.push({
          label: slotLabel,
          fullDate: slotLabel,
          revenue: slotRev,
          orders: slotCount,
        });
      }
    } else {
      const cur = new Date(startDate);
      while (cur <= endDate) {
        const dayStr = cur.toISOString().split('T')[0];
        const displayLabel = `${cur.getDate()}/${cur.getMonth() + 1}`;

        let dayRev = 0;
        let dayCount = 0;

        for (const ord of orders) {
          const ordDate = new Date(ord.thoiGianDat || Date.now());
          const st = String(ord.trangThai || '').toLowerCase().trim();
          const isComp = completedStatuses.some((s) => st.includes(s.toLowerCase()));
          const ordDayStr = ordDate.toISOString().split('T')[0];

          if (ordDayStr === dayStr) {
            dayCount++;
            if (isComp) dayRev += Number(ord.tongTien || 0);
          }
        }

        chart.push({
          label: displayLabel,
          fullDate: dayStr,
          revenue: dayRev,
          orders: dayCount,
        });

        cur.setDate(cur.getDate() + 1);
      }
    }

    // 6. Order Status Breakdown
    const statusMap: Record<string, { label: string; count: number; revenue: number }> = {
      'chờ xử lý': { label: 'Chờ xử lý', count: 0, revenue: 0 },
      'đã xác nhận': { label: 'Đã xác nhận', count: 0, revenue: 0 },
      'đang chuẩn bị': { label: 'Đang chuẩn bị', count: 0, revenue: 0 },
      'sẵn sàng ghé lấy': { label: 'Sẵn sàng ghé lấy', count: 0, revenue: 0 },
      'đã hoàn thành': { label: 'Đã hoàn thành', count: 0, revenue: 0 },
      'đã hủy': { label: 'Đã hủy', count: 0, revenue: 0 },
    };

    for (const ord of orders) {
      const rawSt = String(ord.trangThai || '').trim();
      const upperSt = rawSt.toUpperCase();
      const lowerSt = rawSt.toLowerCase();

      let mappedKey = 'chờ xử lý';
      if (upperSt === 'CHO_XAC_NHAN' || upperSt === 'PENDING' || lowerSt.includes('chờ') || lowerSt.includes('xử lý')) {
        mappedKey = 'chờ xử lý';
      } else if (upperSt === 'DA_XAC_NHAN' || upperSt === 'CONFIRMED' || lowerSt.includes('xác nhận')) {
        mappedKey = 'đã xác nhận';
      } else if (upperSt === 'DANG_CHUAN_BI' || upperSt === 'PREPARING' || lowerSt.includes('chuẩn bị')) {
        mappedKey = 'đang chuẩn bị';
      } else if (upperSt === 'SAN_SANG' || upperSt === 'READY' || upperSt === 'READY_FOR_PICKUP' || lowerSt.includes('sẵn sàng')) {
        mappedKey = 'sẵn sàng ghé lấy';
      } else if (upperSt === 'HOAN_TAT' || upperSt === 'HOAN_THANH' || upperSt === 'COMPLETED' || upperSt === 'PICKED_UP' || lowerSt.includes('hoàn') || lowerSt.includes('thành công')) {
        mappedKey = 'đã hoàn thành';
      } else if (upperSt === 'DA_HUY' || upperSt === 'CANCELLED' || lowerSt.includes('hủy')) {
        mappedKey = 'đã hủy';
      }

      if (!statusMap[mappedKey]) {
        statusMap[mappedKey] = { label: rawSt, count: 0, revenue: 0 };
      }
      statusMap[mappedKey].count += 1;
      if (mappedKey === 'đã hoàn thành') {
        statusMap[mappedKey].revenue += Number(ord.tongTien || 0);
      }
    }

    const orderStatus = Object.entries(statusMap).map(([key, val]) => ({
      statusKey: key,
      label: val.label,
      count: val.count,
      revenue: val.revenue,
    }));

    // 7. Top Selling Foods
    const topFoods = [];
    if (orders.length > 0) {
      const rawTopItems = await this.orderItemRepo.createQueryBuilder('ct')
        .innerJoin(DonHangModel, 'dh', 'ct.madonhang = dh.madonhang')
        .select('ct.mamonan', 'maMonAn')
        .addSelect('ct.tenmonan', 'tenMonAn')
        .addSelect('SUM(ct.soluong)', 'soLuong')
        .addSelect('SUM(ct.gia * ct.soluong)', 'doanhThu')
        .where('dh.maquan = :maQuan', { maQuan })
        .andWhere('dh.trangthai IN (:...completedStatuses)', { completedStatuses })
        .andWhere('dh.thoigiandat >= :startDate AND dh.thoigiandat <= :endDate', { startDate, endDate })
        .groupBy('ct.mamonan')
        .addGroupBy('ct.tenmonan')
        .orderBy('SUM(ct.gia * ct.soluong)', 'DESC')
        .limit(10)
        .getRawMany();

      for (const item of rawTopItems) {
        const maMonAn = Number(item.maMonAn || item.mamonan);
        let foodImg = '';
        let rating = 0.0;

        if (maMonAn) {
          const f = await this.foodRepo.findOne({ where: { maMonAn } });
          if (f) {
            foodImg = f.img || '';
            rating = Number(f.diemDanhGiaTB || 0.0);
          }
        }

        const itemRevenue = Number(item.doanhThu || item.doanhthu || 0);
        const itemQuantity = Number(item.soLuong || item.soluong || 0);
        const sharePercent = totalRevenue > 0 ? Number(((itemRevenue / totalRevenue) * 100).toFixed(1)) : 0;

        topFoods.push({
          maMonAn,
          tenMonAn: item.tenMonAn || item.tenmonan || 'Món ăn',
          soLuong: itemQuantity,
          doanhThu: itemRevenue,
          sharePercent,
          rate: rating,
          img: foodImg,
        });
      }
    }

    // 8. Order Types Breakdown
    const typeMap: Record<string, { label: string; count: number; revenue: number }> = {
      'PRE_ORDER': { label: 'Tự Đến Lấy (Take-away)', count: 0, revenue: 0 },
      'EAT_IN': { label: 'Ăn Tại Quán (Eat-in)', count: 0, revenue: 0 },
    };

    for (const ord of orders) {
      const typeKey = (ord.loaiDonHang || 'PRE_ORDER').toUpperCase();
      const st = String(ord.trangThai || '').toLowerCase().trim();
      const isComp = completedStatuses.some((s) => st.includes(s.toLowerCase()));

      if (!typeMap[typeKey]) {
        typeMap[typeKey] = { label: typeKey === 'EAT_IN' ? 'Ăn Tại Quán' : 'Tự Đến Lấy', count: 0, revenue: 0 };
      }
      typeMap[typeKey].count += 1;
      if (isComp) {
        typeMap[typeKey].revenue += Number(ord.tongTien || 0);
      }
    }

    const orderTypes = Object.entries(typeMap).map(([key, val]) => ({
      typeKey: key,
      label: val.label,
      count: val.count,
      revenue: val.revenue,
    }));

    // 9. Store & Store Owner Info
    let store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) {
      store = await this.storeRepo.findOne({ order: { maQuan: 'ASC' } });
    }

    let ownerName = store?.hoTenChuQuan || '';
    let storePhone = store?.sdt || '';
    let storeEmail = store?.email || '';

    if (store && store.maTaiKhoan) {
      try {
        const kh = await this.khachHangRepo.findOne({ where: { maTaiKhoan: store.maTaiKhoan } });
        if (kh) {
          if (!ownerName) ownerName = kh.hoTen;
          if (!storePhone) storePhone = kh.sdt || '';
          if (!storeEmail) storeEmail = kh.email || '';
        }
      } catch (err) {}
    }

    const storeInfo = store
      ? {
          maQuan: store.maQuan,
          tenQuan: store.tenQuan || 'Nhà hàng FoodRoute',
          diaChi: store.diaChi || 'Chưa cập nhật địa chỉ',
          sdt: storePhone || store.sdt || '',
          email: storeEmail || store.email || '',
          hoTenChuQuan: ownerName || 'Chủ cơ sở',
          soCCCD: store.soCCCD || '',
          tenNganHang: store.tenNganHang || '',
          soTaiKhoanNganHang: store.soTaiKhoanNganHang || '',
          tenChuTaiKhoan: store.tenChuTaiKhoan || ownerName || '',
        }
      : {
          maQuan,
          tenQuan: 'Nhà hàng FoodRoute',
          diaChi: 'Chưa cập nhật địa chỉ',
          sdt: '',
          email: '',
          hoTenChuQuan: 'Chủ cơ sở',
          soCCCD: '',
          tenNganHang: '',
          soTaiKhoanNganHang: '',
          tenChuTaiKhoan: '',
        };

    // 10. Detailed Orders List with Payment Reconciliation
    const ordersList = [];
    for (const ord of orders) {
      let tenKhachHang = 'Khách lẻ / Khách hàng';
      let sdtKhachHang = '';
      if (ord.maKhachHang) {
        try {
          const kh = await this.khachHangRepo.findOne({ where: { maKhachHang: ord.maKhachHang } });
          if (kh) {
            tenKhachHang = kh.hoTen || 'Khách hàng';
            sdtKhachHang = kh.sdt || '';
          }
        } catch (err) {}
      }

      const orderItems = [];
      try {
        const rawDetails = await this.orderItemRepo.find({ where: { maDonHang: ord.maDonHang } });
        for (const d of rawDetails) {
          let foodName = d.tenMonAn || 'Món ăn';
          let foodImg = '';
          if (d.maMonAn) {
            const f = await this.foodRepo.findOne({ where: { maMonAn: d.maMonAn } });
            if (f) {
              foodName = f.tenMonAn;
              foodImg = f.img || '';
            }
          }
          orderItems.push({
            maChiTiet: d.maChiTietDon,
            maMonAn: d.maMonAn,
            tenMonAn: foodName,
            soLuong: Number(d.soLuong || 1),
            donGia: Number(d.gia || 0),
            img: foodImg,
          });
        }
      } catch (e) {}

      const p = paymentMap.get(ord.maDonHang);
      const isPaidOnline = p?.trangThai === 'THANH_TOAN_THANH_CONG';
      const isCash = (ord.phuongThucThanhToan || '').toUpperCase().includes('TIEN_MAT') ||
                     (ord.phuongThucThanhToan || '').toUpperCase() === 'COD';
      const st = String(ord.trangThai || '').toLowerCase().trim();
      const isComp = completedStatuses.some((s) => st.includes(s.toLowerCase()));

      let isPaid = false;
      let paymentStatusText = 'CHUA_THANH_TOAN';
      if (isPaidOnline) {
        isPaid = true;
        paymentStatusText = 'DA_THANH_TOAN_ONLINE';
      } else if (isComp && isCash) {
        isPaid = true;
        paymentStatusText = 'DA_THANH_TOAN_TIEN_MAT';
      }

      ordersList.push({
        maDonHang: ord.maDonHang,
        thoiGianDat: ord.thoiGianDat,
        tenKhachHang,
        sdtKhachHang,
        loaiDonHang: ord.loaiDonHang === 'EAT_IN' ? 'Ăn Tại Quán' : 'Tự Đến Lấy',
        trangThai: ord.trangThai,
        phuongThucThanhToan: ord.phuongThucThanhToan || 'COD',
        tongTien: Number(ord.tongTien || 0),
        daThanhToan: isPaid,
        trangThaiThanhToan: paymentStatusText,
        maThanhToan: p?.maThanhToan || null,
        items: orderItems,
      });
    }

    return {
      period: normalizedPeriod,
      summary: {
        totalRevenue,
        onlineRevenue,
        cashRevenue,
        previousPeriodRevenue,
        growthRate,
        totalOrders,
        completedOrders,
        cancelledOrders,
        paidOrdersCount,
        unpaidOrdersCount,
        averageOrderValue,
      },
      chart,
      orderStatus,
      topFoods,
      orderTypes,
      storeInfo,
      ordersList,
    };
  }
}
