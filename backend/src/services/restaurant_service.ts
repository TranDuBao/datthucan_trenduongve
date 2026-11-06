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
    const stores = await this.cuaHangRepo.createQueryBuilder('ch')
      .where('(ch.is_deleted IS NULL OR ch.is_deleted = false)')
      .andWhere('(ch.trangThai IS NULL OR UPPER(ch.trangThai) NOT IN (:...deletedStatus))', {
        deletedStatus: ['ĐÃ XÓA', 'DA_XOA', 'DELETED'],
      })
      .getMany();

    return stores.map((s) => {
      const reviewCount = Number(s.soLuongDanhGia || 0);
      const avgRate = reviewCount > 0 ? Number(s.danhGiaTrungBinh || 0) : 0.0;
      return {
        ...s,
        danhGiaTrungBinh: avgRate,
        soLuongDanhGia: reviewCount,
        diemDanhGiaTB: avgRate,
        soLuotDanhGia: reviewCount,
        rate: avgRate,
        rating: reviewCount,
        chuaCoDanhGia: reviewCount === 0,
      };
    });
  }

  async getRestaurantById(maQuan: number) {
    const store = await this.cuaHangRepo.findOne({
      where: { maQuan },
    });
    if (!store) return null;
    if (store.isDeleted || ['ĐÃ XÓA', 'DA_XOA', 'DELETED'].includes((store.trangThai || '').toUpperCase())) {
      return null;
    }
    const reviewCount = Number(store.soLuongDanhGia || 0);
    const avgRate = reviewCount > 0 ? Number(store.danhGiaTrungBinh || 0) : 0.0;
    return {
      ...store,
      danhGiaTrungBinh: avgRate,
      soLuongDanhGia: reviewCount,
      diemDanhGiaTB: avgRate,
      soLuotDanhGia: reviewCount,
      rate: avgRate,
      rating: reviewCount,
      chuaCoDanhGia: reviewCount === 0,
    };
  }

  async getAllCategories() {
    const categories = await this.danhMucRepo.find({ order: { maDanhMuc: 'ASC' } });
    const items = await this.monAnRepo.find();
    return categories.map((cat) => {
      const catItems = items.filter((item) => Number(item.maDanhMuc) === Number(cat.maDanhMuc));
      const firstFoodWithImage = catItems.find((item) => this.getValidFoodImageUrl(item.img));
      const foodImg = cat.hinhAnh ? this.getValidFoodImageUrl(cat.hinhAnh) : (firstFoodWithImage ? this.getValidFoodImageUrl(firstFoodWithImage.img) : '');
      return {
        maDanhMuc: cat.maDanhMuc,
        id: cat.maDanhMuc,
        tenDanhMuc: cat.tenDanhMuc,
        name: cat.tenDanhMuc,
        maQuan: cat.maQuan,
        soLuongMon: catItems.length,
        itemsCount: catItems.length,
        hinhAnh: foodImg,
        image: foodImg,
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
      if (trimmed.length > 4 && (trimmed.endsWith('.jpg') || trimmed.endsWith('.png') || trimmed.endsWith('.jpeg') || trimmed.endsWith('.webp'))) {
        return `/uploads/${trimmed}`;
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

    const dishRatings = await AppDataSource.query(`
      WITH dish_reviews_combined AS (
        SELECT 
          dgm.mamon as mamonan,
          dg.madanhgia,
          COALESCE(dgm.soluongsao, dg.soluongsao) as stars
        FROM danhgia_mon dgm
        JOIN danhgia dg ON dg.madanhgia = dgm.madanhgia
        WHERE (dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)

        UNION

        SELECT 
          ct.mamonan,
          dg.madanhgia,
          dg.soluongsao as stars
        FROM chitietdonhang ct
        JOIN danhgia dg ON dg.madonhang = ct.madonhang
        WHERE (dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)
          AND ct.mamonan IS NOT NULL
      )
      SELECT 
        mamonan,
        COUNT(DISTINCT madanhgia) as total_reviews,
        ROUND(AVG(stars)::numeric, 1) as avg_rating
      FROM dish_reviews_combined
      GROUP BY mamonan
    `);
    const dishRatingMap = new Map<number, { count: number; avg: number }>();
    for (const dr of dishRatings) {
      dishRatingMap.set(Number(dr.mamonan), {
        count: Number(dr.total_reviews || 0),
        avg: Math.round(Number(dr.avg_rating || 0) * 10) / 10,
      });
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
          const ratingInfo = dishRatingMap.get(i.maMonAn);
          const actualRatingCount = ratingInfo ? Number(ratingInfo.count || 0) : 0;
          const actualRating = actualRatingCount > 0 ? Number(ratingInfo?.avg || 0.0) : 0.0;
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
            rating: actualRating,
            diemDanhGiaTB: actualRating,
            danhGiaTrungBinh: actualRating,
            ratingCount: actualRatingCount,
            soLuotDanhGia: actualRatingCount,
            soLuongDanhGia: actualRatingCount,
            chuaCoDanhGia: actualRatingCount === 0,
            maQuan: cat.maQuan,
            lat: res?.lat ? Number(res.lat) : 10.762622,
            lng: res?.lng ? Number(res.lng) : 106.682029,
            tenQuan: res?.tenQuan || '',
            moTa: i.moTa || '',
            mota: i.moTa || '',
            dacTinh: i.dacTinh || '',
            dactinh: i.dacTinh || '',
          };
        }),
      };
    });
  }

  /**
   * Spatial query: Find restaurants along a given route polyline within maxDistanceMeters
   * Supports optional keyword to find specific food along the route
   */
  async getRestaurantsAlongRoute(
    routePoints: { lat: number; lng: number }[],
    maxDistanceMeters: number = 800,
    keyword?: string
  ) {
    if (!routePoints || routePoints.length === 0) {
      return [];
    }

    const allStores = await this.getAllRestaurants();
    let validStores = allStores.filter((s) => s.lat != null && s.lng != null);

    if (validStores.length === 0) {
      return [];
    }

function removeVietnameseTones(str: string): string {
  if (!str) return '';
  str = str.replace(/à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ/g, 'a');
  str = str.replace(/è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ/g, 'e');
  str = str.replace(/ì|í|ị|ỉ|ĩ/g, 'i');
  str = str.replace(/ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ/g, 'o');
  str = str.replace(/ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ/g, 'u');
  str = str.replace(/ỳ|ý|ỵ|ỷ|ỹ/g, 'y');
  str = str.replace(/đ/g, 'd');
  str = str.replace(/À|Á|Ạ|Ả|Ã|Â|Ầ|Ấ|Ậ|Ẩ|Ẫ|Ă|Ằ|Ắ|Ặ|Ẳ|Ẵ/g, 'a');
  str = str.replace(/È|É|Ẹ|Ẻ|Ẽ|Ê|Ề|Ế|Ệ|Ể|Ễ/g, 'e');
  str = str.replace(/Ì|Í|Ị|Ỉ|Ĩ/g, 'i');
  str = str.replace(/Ò|Ó|Ọ|Ỏ|Õ|Ô|Ồ|Ố|Ộ|Ổ|Ỗ|Ơ|Ờ|Ớ|Ợ|Ở|Ỡ/g, 'o');
  str = str.replace(/Ù|Ú|Ụ|Ủ|Ũ|Ư|Ừ|Ứ|Ự|Ử|Ữ/g, 'u');
  str = str.replace(/Ỳ|Ý|Ỵ|Ỷ|Ỹ/g, 'y');
  str = str.replace(/Đ/g, 'd');
  str = str.replace(/\u0300|\u0301|\u0303|\u0309|\u0323/g, '');
  str = str.replace(/\u02C6|\u0306|\u031B/g, '');
  return str.toLowerCase().trim();
}

    // Filter by keyword if provided
    const matchingFoodsMap = new Map<number, any[]>();
    const cleanKw = (keyword || '').trim().toLowerCase();
    const cleanKwNoTone = removeVietnameseTones(cleanKw);

    if (cleanKw.length > 0) {
      const allActiveFoods = await this.monAnRepo
        .createQueryBuilder('m')
        .where('m.soLuongMon > 0')
        .andWhere("(m.trangThaiMon IS NULL OR UPPER(m.trangThaiMon) NOT IN ('HET_HANG', 'HET_MON', 'TAM_NGUNG'))")
        .getMany();

      const foods = allActiveFoods.filter((f) => {
        const nameLower = (f.tenMonAn || '').toLowerCase();
        const nameNoTone = removeVietnameseTones(nameLower);
        return nameLower.includes(cleanKw) || nameNoTone.includes(cleanKwNoTone);
      });

      for (const f of foods) {
        if (!f.maQuan) continue;
        const list = matchingFoodsMap.get(f.maQuan) || [];
        list.push({
          id: f.maMonAn,
          maMonAn: f.maMonAn,
          name: f.tenMonAn,
          tenMonAn: f.tenMonAn,
          price: Number(f.giaMonAn),
          giaMonAn: Number(f.giaMonAn),
          quantity: f.soLuongMon,
          soLuongMon: f.soLuongMon,
          image: this.getValidFoodImageUrl(f.img),
          img: this.getValidFoodImageUrl(f.img),
          rating: Number(f.soLuotDanhGia || 0) > 0 ? Number(f.diemDanhGiaTB || 0.0) : 0.0,
          diemDanhGiaTB: Number(f.soLuotDanhGia || 0) > 0 ? Number(f.diemDanhGiaTB || 0.0) : 0.0,
          soLuotDanhGia: Number(f.soLuotDanhGia || 0),
          chuaCoDanhGia: Number(f.soLuotDanhGia || 0) === 0,
          trangThaiMon: f.trangThaiMon || 'DANG_BAN',
        });
        matchingFoodsMap.set(f.maQuan, list);
      }

      // Also support matching store names directly
      const matchingStoreIds = validStores
        .filter((s) => {
          const sNameLower = (s.tenQuan || '').toLowerCase();
          const sNameNoTone = removeVietnameseTones(sNameLower);
          return sNameLower.includes(cleanKw) || sNameNoTone.includes(cleanKwNoTone);
        })
        .map((s) => s.maQuan);

      if (matchingStoreIds.length > 0) {
        const storeFoods = allActiveFoods.filter((f) => f.maQuan && matchingStoreIds.includes(f.maQuan));
        for (const f of storeFoods) {
          if (!f.maQuan) continue;
          const list = matchingFoodsMap.get(f.maQuan) || [];
          if (!list.some((existing) => existing.id === f.maMonAn)) {
            list.push({
              id: f.maMonAn,
              maMonAn: f.maMonAn,
              name: f.tenMonAn,
              tenMonAn: f.tenMonAn,
              price: Number(f.giaMonAn),
              giaMonAn: Number(f.giaMonAn),
              quantity: f.soLuongMon,
              soLuongMon: f.soLuongMon,
              image: this.getValidFoodImageUrl(f.img),
              img: this.getValidFoodImageUrl(f.img),
              rating: Number(f.soLuotDanhGia || 0) > 0 ? Number(f.diemDanhGiaTB || 0.0) : 0.0,
              diemDanhGiaTB: Number(f.soLuotDanhGia || 0) > 0 ? Number(f.diemDanhGiaTB || 0.0) : 0.0,
              soLuotDanhGia: Number(f.soLuotDanhGia || 0),
              chuaCoDanhGia: Number(f.soLuotDanhGia || 0) === 0,
              trangThaiMon: f.trangThaiMon || 'DANG_BAN',
              moTa: f.moTa || '',
              mota: f.moTa || '',
              dacTinh: f.dacTinh || '',
              dactinh: f.dacTinh || '',
            });
            matchingFoodsMap.set(f.maQuan, list);
          }
        }
      }

      validStores = validStores.filter((s) => matchingFoodsMap.has(s.maQuan));
      if (validStores.length === 0) {
        return [];
      }
    } else {
      const storeIds = validStores.map((s) => s.maQuan);
      if (storeIds.length > 0) {
        const topFoods = await this.monAnRepo
          .createQueryBuilder('m')
          .where('m.maQuan IN (:...storeIds)', { storeIds })
          .andWhere('m.soLuongMon > 0')
          .andWhere("(m.trangThaiMon IS NULL OR UPPER(m.trangThaiMon) NOT IN ('HET_HANG', 'HET_MON', 'TAM_NGUNG'))")
          .getMany();

        for (const f of topFoods) {
          if (!f.maQuan) continue;
          const list = matchingFoodsMap.get(f.maQuan) || [];
          if (list.length < 5) {
            list.push({
              id: f.maMonAn,
              maMonAn: f.maMonAn,
              name: f.tenMonAn,
              tenMonAn: f.tenMonAn,
              price: Number(f.giaMonAn),
              giaMonAn: Number(f.giaMonAn),
              quantity: f.soLuongMon,
              soLuongMon: f.soLuongMon,
              image: this.getValidFoodImageUrl(f.img),
              img: this.getValidFoodImageUrl(f.img),
              rating: Number(f.soLuotDanhGia || 0) > 0 ? Number(f.diemDanhGiaTB || 0.0) : 0.0,
              diemDanhGiaTB: Number(f.soLuotDanhGia || 0) > 0 ? Number(f.diemDanhGiaTB || 0.0) : 0.0,
              soLuotDanhGia: Number(f.soLuotDanhGia || 0),
              chuaCoDanhGia: Number(f.soLuotDanhGia || 0) === 0,
              trangThaiMon: f.trangThaiMon || 'DANG_BAN',
              moTa: f.moTa || '',
              mota: f.moTa || '',
              dacTinh: f.dacTinh || '',
              dactinh: f.dacTinh || '',
            });
            matchingFoodsMap.set(f.maQuan, list);
          }
        }
      }
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

    // Fast bounding-box pre-filtering to avoid checking stores far away from route
    let minLat = 90;
    let maxLat = -90;
    let minLng = 180;
    let maxLng = -180;
    for (const pt of routePoints) {
      if (pt.lat < minLat) minLat = pt.lat;
      if (pt.lat > maxLat) maxLat = pt.lat;
      if (pt.lng < minLng) minLng = pt.lng;
      if (pt.lng > maxLng) maxLng = pt.lng;
    }
    // Margin buffer based on maxDistanceMeters + safety buffer (~0.01 deg ~= 1.1km)
    const latBuffer = (maxDistanceMeters / 110540) + 0.01;
    const lngBuffer = (maxDistanceMeters / (111320 * Math.cos(((minLat + maxLat) / 2) * deg2rad))) + 0.01;
    const bMinLat = minLat - latBuffer;
    const bMaxLat = maxLat + latBuffer;
    const bMinLng = minLng - lngBuffer;
    const bMaxLng = maxLng + lngBuffer;

    const candidateStores = validStores.filter((s) => {
      const sLat = Number(s.lat);
      const sLng = Number(s.lng);
      return sLat >= bMinLat && sLat <= bMaxLat && sLng >= bMinLng && sLng <= bMaxLng;
    });

    let tableStoreIds = new Set<number>();
    try {
      const storesWithTables = await this.cuaHangRepo.manager
        .createQueryBuilder()
        .select('DISTINCT b.maQuan', 'maQuan')
        .from('ban', 'b')
        .where("b.trangThai != 'TAM_NGUNG'")
        .getRawMany();
      tableStoreIds = new Set(storesWithTables.map((r: any) => Number(r.maQuan)));
    } catch (_) {}

    const matchedStores: any[] = [];

    for (const store of candidateStores) {
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
        const matchedFoods = matchingFoodsMap.get(store.maQuan) || [];
        const tienIchStr = String(store.tienIch || (store as any).tienich || '').toLowerCase();
        const hasDineIn = tableStoreIds.has(Number(store.maQuan)) ||
                          tienIchStr.includes('chỗ ngồi') ||
                          tienIchStr.includes('cho ngoi') ||
                          tienIchStr.includes('tại chỗ') ||
                          tienIchStr.includes('tai cho') ||
                          tienIchStr.includes('dine-in');
        const hasPreOrder = store.coChoDatTruoc !== false;
        const hasTakeaway = !tienIchStr.includes('no-takeaway');

        matchedStores.push({
          ...store,
          hasDineIn,
          hasPreOrder,
          hasTakeaway,
          coChoNgoi: hasDineIn,
          distanceFromRouteMeters: Math.round(minDistance),
          thoiGianChuanBi: store.thoiGianChuanBi || 20,
          matchedFoods,
          primaryFood: matchedFoods.length > 0 ? matchedFoods[0] : null,
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
        rating: Number(i.soLuotDanhGia || 0) > 0 ? Number(i.diemDanhGiaTB || 0.0) : 0.0,
        diemDanhGiaTB: Number(i.soLuotDanhGia || 0) > 0 ? Number(i.diemDanhGiaTB || 0.0) : 0.0,
        ratingCount: Number(i.soLuotDanhGia || 0),
        soLuotDanhGia: Number(i.soLuotDanhGia || 0),
        chuaCoDanhGia: Number(i.soLuotDanhGia || 0) === 0,
        maQuan: i.maQuan,
        lat: store?.lat ? Number(store.lat) : 10.762622,
        lng: store?.lng ? Number(store.lng) : 106.682029,
        tenQuan: store?.tenQuan || '',
        diaChi: store?.diaChi || '',
        thoiGianChuanBi: store?.thoiGianChuanBi ? Number(store.thoiGianChuanBi) : 5,
        moTa: i.moTa || '',
        mota: i.moTa || '',
        dacTinh: i.dacTinh || '',
        dactinh: i.dacTinh || '',
      };
    });
  }
}
