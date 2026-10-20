import { AppDataSource } from '../config/database';
import { CuaHangModel } from '../models/cua_hang_model';
import { DanhMucModel } from '../models/danh_muc_model';
import { MonAnModel } from '../models/mon_an_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';

export class RestaurantService {
  private cuaHangRepo = AppDataSource.getRepository(CuaHangModel);
  private danhMucRepo = AppDataSource.getRepository(DanhMucModel);
  private monAnRepo = AppDataSource.getRepository(MonAnModel);

  async getAllRestaurants() {
    return await this.cuaHangRepo.createQueryBuilder('ch')
      .where('(ch.is_deleted IS NULL OR ch.is_deleted = false)')
      .andWhere('(ch.trangThai IS NULL OR UPPER(ch.trangThai) NOT IN (:...deletedStatus))', {
        deletedStatus: ['ĐÃ XÓA', 'DA_XOA', 'DELETED'],
      })
      .getMany();
  }

  async getRestaurantById(maQuan: number) {
    const store = await this.cuaHangRepo.findOne({
      where: { maQuan },
    });
    if (!store) return null;
    if (store.isDeleted || ['ĐÃ XÓA', 'DA_XOA', 'DELETED'].includes((store.trangThai || '').toUpperCase())) {
      return null;
    }
    return store;
  }

  async getAllCategories() {
    const categories = await this.danhMucRepo.find();
    const items = await this.monAnRepo.find();
    return categories.map((cat) => {
      const catItems = items.filter((item) => item.maDanhMuc === cat.maDanhMuc);
      return {
        maDanhMuc: cat.maDanhMuc,
        id: cat.maDanhMuc,
        tenDanhMuc: cat.tenDanhMuc,
        name: cat.tenDanhMuc,
        maQuan: cat.maQuan,
        soLuongMon: catItems.length,
        itemsCount: catItems.length,
      };
    });
  }

  private getValidFoodImageUrl(img: string | undefined | null): string {
    if (img && typeof img === 'string') {
      const trimmed = img.trim();
      if (
        trimmed.startsWith('/uploads/') ||
        trimmed.startsWith('uploads/') ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:image/')
      ) {
        return trimmed;
      }
    }
    return '';
  }

  async getRestaurantMenu(maQuan: number) {
    const res = await this.cuaHangRepo.findOne({
      where: { maQuan },
    });
    if (!res) return [];
    if (res.isDeleted || ['ĐÃ XÓA', 'DA_XOA', 'DELETED', 'NGUNG_HOAT_DONG'].includes((res.trangThai || '').toUpperCase())) {
      return [];
    }

    let categories = await this.danhMucRepo.find({
      where: { maQuan },
    });

    const items = await this.monAnRepo.find({
      where: { maQuan },
    });

    const chiTietRepo = AppDataSource.getRepository(ChiTietDonHangModel);
    const soldCounts = await chiTietRepo
      .createQueryBuilder('ct')
      .select('ct.mamonan', 'maMonAn')
      .addSelect('SUM(ct.soluong)', 'totalSold')
      .where('ct.mamonan IS NOT NULL')
      .groupBy('ct.mamonan')
      .getRawMany();

    const soldMap = new Map<number, number>();
    for (const sc of soldCounts) {
      soldMap.set(Number(sc.maMonAn), Number(sc.totalSold || 0));
    }

    if (categories.length === 0) {
      categories = [{ maDanhMuc: 0, maQuan, tenDanhMuc: 'Thực đơn' } as any];
    }

    const categoryIds = new Set(categories.map((c) => c.maDanhMuc));
    const firstCatId = categories[0].maDanhMuc;

    return categories.map((cat) => {
      const catItems = items.filter((item) => {
        // Direct match with category
        if (item.maDanhMuc === cat.maDanhMuc) return true;
        // If item has no category or category doesn't belong to this store's categories, assign to first category
        if (cat.maDanhMuc === firstCatId && (!item.maDanhMuc || !categoryIds.has(item.maDanhMuc))) {
          return true;
        }
        return false;
      });

      // Helper to check if item is sold out
      const isSoldOut = (item: any) => {
        const qty = Number(item.soLuongMon ?? 0);
        const status = (item.trangThaiMon || '').toUpperCase();
        return qty <= 0 || status === 'HET_HANG' || status === 'HET_MON' || status === 'TAM_NGUNG';
      };

      // Sort items: available & top-rated/best-selling first, sold-out items at the bottom
      catItems.sort((a, b) => {
        const aOut = isSoldOut(a);
        const bOut = isSoldOut(b);
        if (aOut !== bOut) {
          return aOut ? 1 : -1;
        }
        const aSales = soldMap.get(a.maMonAn) || Number(a.soLuotDanhGia || 0);
        const bSales = soldMap.get(b.maMonAn) || Number(b.soLuotDanhGia || 0);
        if (bSales !== aSales) {
          return bSales - aSales;
        }
        const aRating = Number(a.diemDanhGiaTB || 0);
        const bRating = Number(b.diemDanhGiaTB || 0);
        return bRating - aRating;
      });

      return {
        id: cat.maDanhMuc,
        name: cat.tenDanhMuc,
        maQuan: cat.maQuan,
        lat: res?.lat ? Number(res.lat) : 10.762622,
        lng: res?.lng ? Number(res.lng) : 106.682029,
        tenQuan: res?.tenQuan || '',
        itemsCount: catItems.length,
        items: catItems.map((i) => {
          const dbSold = soldMap.get(i.maMonAn) || 0;
          const totalSold = dbSold > 0 ? dbSold : 0;
          return {
            id: i.maMonAn,
            maMonAn: i.maMonAn,
            name: i.tenMonAn,
            tenMonAn: i.tenMonAn,
            price: Number(i.giaMonAn),
            giaMonAn: Number(i.giaMonAn),
            quantity: i.soLuongMon !== null && i.soLuongMon !== undefined ? Number(i.soLuongMon) : 0,
            soLuongMon: i.soLuongMon !== null && i.soLuongMon !== undefined ? Number(i.soLuongMon) : 0,
            soLuongDaBan: totalSold,
            soLuotBan: totalSold,
            soldCount: totalSold,
            trangThaiMon: i.trangThaiMon || ((Number(i.soLuongMon) > 0) ? 'DANG_BAN' : 'HET_HANG'),
            image: this.getValidFoodImageUrl(i.img),
            img: this.getValidFoodImageUrl(i.img),
            rating: Number(i.diemDanhGiaTB || 0.0),
            diemDanhGiaTB: Number(i.diemDanhGiaTB || 0.0),
            ratingCount: i.soLuotDanhGia || 0,
            soLuotDanhGia: i.soLuotDanhGia || 0,
            maQuan: cat.maQuan,
            lat: res?.lat ? Number(res.lat) : 10.762622,
            lng: res?.lng ? Number(res.lng) : 106.682029,
            tenQuan: res?.tenQuan || '',
          };
        }),
      };
    });
  }

  /**
   * Spatial query: Find restaurants along a given route polyline within maxDistanceMeters
   */
  async getRestaurantsAlongRoute(
    routePoints: { lat: number; lng: number }[],
    maxDistanceMeters: number = 1000
  ) {
    if (!routePoints || routePoints.length === 0) {
      return [];
    }

    const allStores = await this.getAllRestaurants();
    const validStores = allStores.filter((s) => s.lat != null && s.lng != null);

    if (validStores.length === 0) {
      return [];
    }

    // Pre-calculate segments from route points
    const deg2rad = Math.PI / 180;
    const segments: {
      lat1: number;
      lng1: number;
      lat2: number;
      lng2: number;
      dx: number;
      dy: number;
      lenSq: number;
    }[] = [];

    // Sample or use full polyline points
    const step = Math.max(1, Math.floor(routePoints.length / 300));
    const sampledPoints: { lat: number; lng: number }[] = [];
    for (let i = 0; i < routePoints.length; i += step) {
      sampledPoints.push(routePoints[i]);
    }
    if (sampledPoints[sampledPoints.length - 1] !== routePoints[routePoints.length - 1]) {
      sampledPoints.push(routePoints[routePoints.length - 1]);
    }

    for (let i = 0; i < sampledPoints.length - 1; i++) {
      const p1 = sampledPoints[i];
      const p2 = sampledPoints[i + 1];
      const midLat = ((p1.lat + p2.lat) / 2) * deg2rad;
      const dx = (p2.lng - p1.lng) * 111320 * Math.cos(midLat);
      const dy = (p2.lat - p1.lat) * 110540;
      const lenSq = dx * dx + dy * dy;
      segments.push({
        lat1: p1.lat,
        lng1: p1.lng,
        lat2: p2.lat,
        lng2: p2.lng,
        dx,
        dy,
        lenSq,
      });
    }

    const matchedStores: any[] = [];

    for (const store of validStores) {
      const sLat = Number(store.lat);
      const sLng = Number(store.lng);
      let minDistance = Infinity;

      for (const seg of segments) {
        const midLat = ((seg.lat1 + sLat) / 2) * deg2rad;
        const px = (sLng - seg.lng1) * 111320 * Math.cos(midLat);
        const py = (sLat - seg.lat1) * 110540;

        let t = 0;
        if (seg.lenSq > 0) {
          t = Math.max(0, Math.min(1, (px * seg.dx + py * seg.dy) / seg.lenSq));
        }

        const projX = seg.dx * t;
        const projY = seg.dy * t;
        const dist = Math.sqrt((px - projX) ** 2 + (py - projY) ** 2);

        if (dist < minDistance) {
          minDistance = dist;
        }
      }

      if (minDistance <= maxDistanceMeters) {
        matchedStores.push({
          ...store,
          distanceFromRouteMeters: Math.round(minDistance),
          thoiGianChuanBi: store.thoiGianChuanBi || 20,
        });
      }
    }

    // Sort stores by deviation distance from the route
    matchedStores.sort((a, b) => a.distanceFromRouteMeters - b.distanceFromRouteMeters);

    return matchedStores;
  }

  /**
   * Fast aggregated overview of all foods with store and rating info in a single query
   */
  async getAllFoodsOverview() {
    const stores = await this.getAllRestaurants();
    const storeMap = new Map<number, CuaHangModel>();
    for (const s of stores) storeMap.set(s.maQuan, s);

    const categories = await this.danhMucRepo.find();
    const catMap = new Map<number, string>();
    for (const c of categories) catMap.set(c.maDanhMuc, c.tenDanhMuc);

    const items = await this.monAnRepo.find();

    const chiTietRepo = AppDataSource.getRepository(ChiTietDonHangModel);
    const soldCounts = await chiTietRepo
      .createQueryBuilder('ct')
      .select('ct.mamonan', 'maMonAn')
      .addSelect('SUM(ct.soluong)', 'totalSold')
      .where('ct.mamonan IS NOT NULL')
      .groupBy('ct.mamonan')
      .getRawMany();

    const soldMap = new Map<number, number>();
    for (const sc of soldCounts) {
      soldMap.set(Number(sc.maMonAn), Number(sc.totalSold || 0));
    }

    return items.map((i) => {
      const store = storeMap.get(i.maQuan);
      const totalSold = soldMap.get(i.maMonAn) || 0;
      const catName = i.maDanhMuc ? catMap.get(i.maDanhMuc) || '' : '';
      return {
        id: i.maMonAn,
        maMonAn: i.maMonAn,
        name: i.tenMonAn,
        tenMonAn: i.tenMonAn,
        maDanhMuc: i.maDanhMuc,
        tenDanhMuc: catName,
        categoryName: catName,
        price: Number(i.giaMonAn),
        giaMonAn: Number(i.giaMonAn),
        quantity: i.soLuongMon !== null && i.soLuongMon !== undefined ? Number(i.soLuongMon) : 0,
        soLuongMon: i.soLuongMon !== null && i.soLuongMon !== undefined ? Number(i.soLuongMon) : 0,
        soLuongDaBan: totalSold,
        soLuotBan: totalSold,
        soldCount: totalSold,
        trangThaiMon: i.trangThaiMon || ((Number(i.soLuongMon) > 0) ? 'DANG_BAN' : 'HET_HANG'),
        image: this.getValidFoodImageUrl(i.img),
        img: this.getValidFoodImageUrl(i.img),
        rating: Number(i.diemDanhGiaTB || 0.0),
        diemDanhGiaTB: Number(i.diemDanhGiaTB || 0.0),
        ratingCount: i.soLuotDanhGia || 0,
        soLuotDanhGia: i.soLuotDanhGia || 0,
        maQuan: i.maQuan,
        lat: store?.lat ? Number(store.lat) : 10.762622,
        lng: store?.lng ? Number(store.lng) : 106.682029,
        tenQuan: store?.tenQuan || '',
        diaChi: store?.diaChi || '',
      };
    });
  }
}
