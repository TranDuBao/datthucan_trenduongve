import { AppDataSource } from '../config/database';
import { DonHangModel } from '../models/don_hang_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';
import { MonAnModel } from '../models/mon_an_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { DanhMucModel } from '../models/danh_muc_model';
import { IsNull } from 'typeorm';

export class RestaurantMgmtService {
  private orderRepo = AppDataSource.getRepository(DonHangModel);
  private orderItemRepo = AppDataSource.getRepository(ChiTietDonHangModel);
  private foodRepo = AppDataSource.getRepository(MonAnModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private categoryRepo = AppDataSource.getRepository(DanhMucModel);

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
        statuses: ['CONFIRMED', 'đã xác nhận', 'PREPARING', 'đang chuẩn bị'],
      })
      .getCount();

    const preparingCount = await this.orderRepo
      .createQueryBuilder('dh')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.trangthai IN (:...statuses)', {
        statuses: ['PREPARING', 'đang chuẩn bị'],
      })
      .getCount();

    const readyCount = await this.orderRepo
      .createQueryBuilder('dh')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.trangthai IN (:...statuses)', {
        statuses: ['READY_FOR_PICKUP', 'sẵn sàng ghé lấy', 'Sẵn sàng'],
      })
      .getCount();

    const revenueRaw = await this.orderRepo
      .createQueryBuilder('dh')
      .select('SUM(dh.tongtien)', 'sum')
      .where('dh.maquan = :maQuan', { maQuan })
      .andWhere('dh.trangthai IN (:...completedStatuses)', {
        completedStatuses: ['HOAN_THANH', 'COMPLETED', 'PICKED_UP', 'thành công', 'Đã lấy món'],
      })
      .getRawOne();
    const revenue = Number(revenueRaw?.sum || 0);

    const recentOrders = await this.getOrders(maQuan, '', 1, 5);

    return {
      todayOrdersCount,
      upcomingPickupCount,
      preparingCount,
      readyCount,
      revenue,
      recentOrders: recentOrders.items,
    };
  }

  // ── 2. Quản lý Đơn hàng (Scope maQuan) ───────────────────────────────────
  async getOrders(maQuan: number, statusFilter: string = '', page: number = 1, limit: number = 10) {
    const skip = (page - 1) * limit;
    const qb = this.orderRepo.createQueryBuilder('dh')
      .where('dh.maquan = :maQuan', { maQuan })
      .orderBy('dh.thoiGianDat', 'DESC')
      .skip(skip)
      .take(limit);

    if (statusFilter.trim()) {
      qb.andWhere('dh.trangThai = :statusFilter', { statusFilter: statusFilter.trim() });
    }

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
        orderItems.push({
          maChiTiet: d.maChiTietDon,
          maMonAn: d.maMonAn,
          tenMonAn: d.tenMonAn || foodName,
          soLuong: d.soLuong,
          donGia: Number(d.gia),
          img: foodImg,
        });
      }

      enrichedOrders.push({
        ...ord,
        tenKhachHang: customerName,
        sdtKhachHang: customerPhone,
        items: orderItems,
      });
    }

    return { items: enrichedOrders, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  async updateOrderStatus(maQuan: number, maDonHang: number, newStatus: string) {
    const order = await this.orderRepo.findOne({ where: { maDonHang, maQuan } });
    if (!order) {
      throw new Error('Đơn hàng không tồn tại hoặc không thuộc nhà hàng này!');
    }

    // Standard Business Logic Allowed Transitions
    const allowedStatuses = [
      'PENDING',
      'CONFIRMED',
      'PREPARING',
      'READY_FOR_PICKUP',
      'PICKED_UP',
      'COMPLETED',
      'CANCELLED',
      'chờ xử lý',
      'đã xác nhận',
      'đang chuẩn bị',
      'sẵn sàng ghé lấy',
      'đã lấy món',
    ];

    if (!allowedStatuses.includes(newStatus)) {
      throw new Error(`Trạng thái "${newStatus}" không hợp lệ!`);
    }

    order.trangThai = newStatus;
    return await this.orderRepo.save(order);
  }

  // ── 3. Quản lý Menu / Thực đơn (Scope maQuan) ───────────────────────────
  async getCategories(maQuan: number) {
    return await this.categoryRepo.find({
      where: [{ maQuan }, { maQuan: IsNull() }],
      order: { maDanhMuc: 'ASC' },
    });
  }

  async getMenu(maQuan: number) {
    const items = await this.foodRepo.find({
      where: { maQuan },
      order: { maMonAn: 'DESC' },
    });

    const categories = await this.categoryRepo.find();
    const catMap = new Map(categories.map((c) => [c.maDanhMuc, c.tenDanhMuc]));

    return items.map((f) => ({
      ...f,
      tenDanhMuc: f.maDanhMuc ? catMap.get(f.maDanhMuc) || `Danh mục #${f.maDanhMuc}` : 'Chưa phân loại',
    }));
  }

  async createFoodItem(maQuan: number, data: Partial<MonAnModel>) {
    const food = this.foodRepo.create({
      ...data,
      maQuan,
    });
    return await this.foodRepo.save(food);
  }

  async updateFoodItem(maQuan: number, maMonAn: number, data: Partial<MonAnModel>) {
    const food = await this.foodRepo.findOne({ where: { maMonAn, maQuan } });
    if (!food) {
      throw new Error('Món ăn không tồn tại hoặc không thuộc quyền quản lý của quán!');
    }
    Object.assign(food, data);
    return await this.foodRepo.save(food);
  }

  async deleteFoodItem(maQuan: number, maMonAn: number) {
    const food = await this.foodRepo.findOne({ where: { maMonAn, maQuan } });
    if (!food) {
      throw new Error('Món ăn không tồn tại hoặc không thuộc quyền quản lý của quán!');
    }
    return await this.foodRepo.remove(food);
  }

  // ── 4. Quản lý Thông tin Nhà hàng (Scope maQuan) ─────────────────────────
  async getStoreProfile(maQuan: number) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy thông tin nhà hàng');
    return store;
  }

  async updateStoreProfile(maQuan: number, data: Partial<CuaHangModel>) {
    const store = await this.storeRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Không tìm thấy thông tin nhà hàng');

    // Only allow permitted fields to be edited by restaurant role
    if (data.tenQuan) store.tenQuan = data.tenQuan;
    if (data.diaChi) store.diaChi = data.diaChi;
    if (data.sdt !== undefined) store.sdt = data.sdt;
    if (data.img !== undefined) store.img = data.img;
    if (data.trangThai) store.trangThai = data.trangThai;
    if (data.lat !== undefined) store.lat = data.lat;
    if (data.lng !== undefined) store.lng = data.lng;

    return await this.storeRepo.save(store);
  }
}
