import { AppDataSource } from '../config/database';
import { IsNull, In } from 'typeorm';
import { DanhGiaModel } from '../models/danh_gia_model';
import { DanhGiaMonModel } from '../models/danh_gia_mon_model';
import { DonHangModel } from '../models/don_hang_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { RealtimeService } from './realtime_service';

export interface CreateReviewDTO {
  userId: number;
  orderId: number;
  rating: number;
  comment?: string;
  image?: string;
  dishRatings?: { dishId: number; rating: number; comment?: string }[];
}

export interface UpdateReviewDTO {
  rating?: number;
  comment?: string;
  image?: string;
}

const COMPLETED_ORDER_STATUSES = [
  'HOAN_TAT',
  'HOAN_THANH',
  'COMPLETED',
  'PICKED_UP',
  'ĐÃ HOÀN THÀNH',
  'ĐÃ HOÀN TẤT',
  'ĐÃ LẤY',
];

export class ReviewService {
  private reviewRepo = AppDataSource.getRepository(DanhGiaModel);
  private reviewMonRepo = AppDataSource.getRepository(DanhGiaMonModel);
  private orderRepo = AppDataSource.getRepository(DonHangModel);
  private chiTietDonRepo = AppDataSource.getRepository(ChiTietDonHangModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private customerRepo = AppDataSource.getRepository(KhachHangModel);
  private realtimeService = RealtimeService.getInstance();

  private sanitizeText(text?: string): string | undefined {
    if (!text) return undefined;
    // Strip HTML tags and trim
    const clean = text.replace(/<[^>]*>?/gm, '').trim();
    return clean.slice(0, 1000);
  }

  private async recalculateStoreRating(queryRunner: any, storeId: number) {
    if (!storeId || isNaN(storeId)) return;

    await queryRunner.manager.createQueryBuilder(CuaHangModel, 'ch')
      .setLock('pessimistic_write')
      .where('ch.maquan = :storeId', { storeId })
      .getOne();

    const result = await queryRunner.manager.query(
      `SELECT AVG(soluongsao) as avg_rating, COUNT(*) as total_count 
       FROM danhgia 
       WHERE maquan = $1 AND (is_hidden IS NOT TRUE OR is_hidden IS NULL)`,
      [storeId],
    );

    const totalCount = Number(result[0]?.total_count || 0);
    const avgRating = totalCount > 0 ? (Math.round(Number(result[0]?.avg_rating || 0) * 100) / 100) : 0.0;

    await queryRunner.manager.update(
      CuaHangModel,
      { maQuan: storeId },
      {
        danhGiaTrungBinh: avgRating,
        soLuongDanhGia: totalCount,
      },
    );
  }

  async createReview(dto: CreateReviewDTO) {
    const customer = await this.customerRepo.findOne({ where: { maTaiKhoan: dto.userId } });
    if (!customer) {
      throw new Error('Không tìm thấy thông tin khách hàng');
    }

    const order = await this.orderRepo.findOne({ where: { maDonHang: dto.orderId } });
    if (!order) {
      throw new Error('Không tìm thấy đơn hàng');
    }

    if (order.maKhachHang !== customer.maKhachHang) {
      throw new Error('Bạn không có quyền đánh giá đơn hàng này');
    }

    const normalizedStatus = String(order.trangThai || '').trim().toUpperCase();
    if (!COMPLETED_ORDER_STATUSES.includes(normalizedStatus)) {
      throw new Error('Chỉ có thể đánh giá đơn hàng đã hoàn tất');
    }

    const existingReview = await this.reviewRepo.findOne({ where: { maDonHang: dto.orderId } });
    if (existingReview) {
      throw new Error('Đơn hàng này đã được đánh giá trước đó');
    }

    if (!order.maQuan) {
      console.error(`[ReviewService] Đơn hàng #${dto.orderId} thiếu thông tin maQuan (null).`);
      throw new Error('Đơn hàng không có thông tin cửa hàng liên kết');
    }

    const rating = Math.min(5, Math.max(1, Math.round(dto.rating || 5)));
    const cleanComment = this.sanitizeText(dto.comment);
    const storeId = order.maQuan;

    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const newReview = this.reviewRepo.create({
        maDonHang: dto.orderId,
        maQuan: storeId,
        maKhachHang: customer.maKhachHang,
        soLuongSao: rating,
        nhanXet: cleanComment,
        hinhAnh: dto.image,
        ngayNhanXet: new Date(),
        isEdited: false,
        isHidden: false,
      });

      const savedReview = await queryRunner.manager.save(DanhGiaModel, newReview);


      const orderDetails = await this.chiTietDonRepo.find({ where: { maDonHang: dto.orderId } });
      const dishRatingsToSave = (dto.dishRatings && dto.dishRatings.length > 0)
        ? dto.dishRatings
        : orderDetails.map((od) => ({ dishId: od.maMonAn || 1, rating: rating, comment: cleanComment }));

      for (const dr of dishRatingsToSave) {
        if (dr.dishId) {
          try {
            const dishRating = this.reviewMonRepo.create({
              maDanhGia: savedReview.maDanhGia,
              maMon: dr.dishId,
              soLuongSao: Math.min(5, Math.max(1, Math.round(dr.rating || 5))),
              nhanXet: this.sanitizeText(dr.comment),
            });
            await queryRunner.manager.save(DanhGiaMonModel, dishRating);
          } catch (e) {
            console.error('Không thể lưu đánh giá món chi tiết:', e);
          }
        }
      }

      await this.recalculateStoreRating(queryRunner, storeId);
      await queryRunner.commitTransaction();

      // Realtime Socket Notification to Store
      this.realtimeService.emitToRoom(`restaurant:${storeId}`, 'review:created', {
        id: savedReview.maDanhGia,
        orderId: dto.orderId,
        storeId,
        rating: savedReview.soLuongSao,
        comment: savedReview.nhanXet,
        createdAt: savedReview.ngayNhanXet,
      });

      return savedReview;
    } catch (err: any) {
      await queryRunner.rollbackTransaction();
      if (err.code === '23505' || err.message?.includes('uq_danhgia_madonhang') || err.message?.includes('duplicate key')) {
        const error = new Error('Đơn hàng này đã được đánh giá trước đó');
        (error as any).code = '23505';
        throw error;
      }
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async updateReview(reviewId: number, userId: number, dto: UpdateReviewDTO) {
    const customer = await this.customerRepo.findOne({ where: { maTaiKhoan: userId } });
    if (!customer) {
      throw new Error('Không tìm thấy thông tin khách hàng');
    }

    const review = await this.reviewRepo.findOne({ where: { maDanhGia: reviewId } });
    if (!review) {
      throw new Error('Không tìm thấy đánh giá');
    }

    if (review.maKhachHang !== customer.maKhachHang) {
      throw new Error('Bạn không có quyền chỉnh sửa đánh giá này');
    }

    if (review.isEdited) {
      throw new Error('Đánh giá này đã được chỉnh sửa 1 lần, không thể sửa thêm');
    }

    const hoursElapsed = (new Date().getTime() - new Date(review.ngayNhanXet).getTime()) / (1000 * 3600);
    if (hoursElapsed > 24) {
      throw new Error('Đã quá thời hạn 24 giờ để chỉnh sửa đánh giá');
    }

    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      if (dto.rating !== undefined) {
        review.soLuongSao = Math.min(5, Math.max(1, Math.round(dto.rating)));
      }
      if (dto.comment !== undefined) {
        review.nhanXet = this.sanitizeText(dto.comment);
      }
      if (dto.image !== undefined) {
        review.hinhAnh = dto.image;
      }
      review.isEdited = true;
      review.updatedAt = new Date();

      const updated = await queryRunner.manager.save(DanhGiaModel, review);

      if (review.maQuan) {
        await this.recalculateStoreRating(queryRunner, review.maQuan);
      }

      await queryRunner.commitTransaction();
      return updated;
    } catch (err: any) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async getRestaurantReviews(restaurantId: number, page: number = 1, limit: number = 10) {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(50, Math.max(1, limit));
    const offset = (safePage - 1) * safeLimit;

    let [reviews, total] = await this.reviewRepo.findAndCount({
      where: [
        { maQuan: restaurantId, isHidden: false },
        { maQuan: restaurantId, isHidden: IsNull() },
      ],
      order: { ngayNhanXet: 'DESC' },
      take: safeLimit,
      skip: offset,
    });

    // Batch lookup to eliminate N+1 queries
    const custIds = Array.from(new Set(reviews.map((r) => r.maKhachHang).filter((id): id is number => Boolean(id))));
    const reviewIds = reviews.map((r) => r.maDanhGia).filter(Boolean);

    const custMap = new Map<number, string>();
    if (custIds.length > 0) {
      const customers = await this.customerRepo.find({
        where: { maKhachHang: In(custIds) },
        select: ['maKhachHang', 'hoTen'],
      });
      customers.forEach((c) => custMap.set(c.maKhachHang, c.hoTen));
    }

    const dishReviewsMap = new Map<number, any[]>();
    if (reviewIds.length > 0) {
      const allDishReviews = await this.reviewMonRepo.find({
        where: { maDanhGia: In(reviewIds) },
        relations: ['monAn'],
      });
      allDishReviews.forEach((dr) => {
        const list = dishReviewsMap.get(dr.maDanhGia) || [];
        list.push({
          id: dr.maDanhGiaMon,
          dishId: dr.maMon,
          dishName: dr.monAn ? dr.monAn.tenMonAn : '',
          rating: dr.soLuongSao,
          comment: dr.nhanXet,
        });
        dishReviewsMap.set(dr.maDanhGia, list);
      });
    }

    const formattedReviews = reviews.map((r) => ({
      ...r,
      tenKhachHang: (r.maKhachHang ? custMap.get(r.maKhachHang) : null) || 'Khách hàng',
      dishReviews: dishReviewsMap.get(r.maDanhGia) || [],
    }));

    return {
      reviews: formattedReviews,
      total,
      page: safePage,
      limit: safeLimit,
      totalPages: Math.ceil(total / safeLimit),
    };
  }

  async replyReview(reviewId: number, userId: number, replyText: string) {
    const store = await this.storeRepo.findOne({ where: { maTaiKhoan: userId } });
    if (!store) {
      throw new Error('Tài khoản của bạn không gắn với cửa hàng nào');
    }

    const review = await this.reviewRepo.findOne({ where: { maDanhGia: reviewId } });
    if (!review) {
      throw new Error('Không tìm thấy đánh giá');
    }

    if (review.maQuan !== store.maQuan) {
      throw new Error('Bạn không có quyền phản hồi đánh giá của cửa hàng khác');
    }

    if (review.phanHoi) {
      throw new Error('Đánh giá này đã được phản hồi trước đó');
    }

    const cleanReply = this.sanitizeText(replyText);
    if (!cleanReply) {
      throw new Error('Nội dung phản hồi không được để trống');
    }

    review.phanHoi = cleanReply;
    review.ngayPhanHoi = new Date();
    const saved = await this.reviewRepo.save(review);

    // Notify Customer if customer account exists
    if (review.maKhachHang) {
      const customer = await this.customerRepo.findOne({ where: { maKhachHang: review.maKhachHang } });
      if (customer && customer.maTaiKhoan) {
        this.realtimeService.emitToRoom(`account:${customer.maTaiKhoan}`, 'review:replied', {
          id: saved.maDanhGia,
          storeId: store.maQuan,
          storeName: store.tenQuan,
          reply: saved.phanHoi,
          repliedAt: saved.ngayPhanHoi,
        });
      }
    }

    return saved;
  }

  async updateVisibility(reviewId: number, isHidden: boolean, reason?: string) {
    const review = await this.reviewRepo.findOne({ where: { maDanhGia: reviewId } });
    if (!review) {
      throw new Error('Không tìm thấy đánh giá');
    }

    const queryRunner = AppDataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      review.isHidden = Boolean(isHidden);
      review.lyDoAn = isHidden ? this.sanitizeText(reason) : undefined;
      const updated = await queryRunner.manager.save(DanhGiaModel, review);

      if (review.maQuan) {
        await this.recalculateStoreRating(queryRunner, review.maQuan);
      }

      await queryRunner.commitTransaction();
      return updated;
    } catch (err: any) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async getMyReviews(userId: number, page: number = 1, limit: number = 10) {
    const customer = await this.customerRepo.findOne({ where: { maTaiKhoan: userId } });
    if (!customer) {
      return { reviews: [], total: 0, page: 1, limit: 10, totalPages: 0 };
    }

    const safePage = Math.max(1, page);
    const safeLimit = Math.min(50, Math.max(1, limit));
    const offset = (safePage - 1) * safeLimit;

    const [reviews, total] = await this.reviewRepo.findAndCount({
      where: { maKhachHang: customer.maKhachHang },
      order: { ngayNhanXet: 'DESC' },
      take: safeLimit,
      skip: offset,
    });

    const formatted = await Promise.all(
      reviews.map(async (r) => {
        const store = r.maQuan ? await this.storeRepo.findOne({ where: { maQuan: r.maQuan } }) : null;
        return {
          ...r,
          tenQuan: store ? store.tenQuan : '',
          imgQuan: store ? store.img : '',
        };
      }),
    );

    return {
      reviews: formatted,
      total,
      page: safePage,
      limit: safeLimit,
      totalPages: Math.ceil(total / safeLimit),
    };
  }

  async getReviewByOrder(orderId: number, userId: number) {
    const customer = await this.customerRepo.findOne({ where: { maTaiKhoan: userId } });
    if (!customer) return null;

    const review = await this.reviewRepo.findOne({
      where: { maDonHang: orderId, maKhachHang: customer.maKhachHang },
    });

    return review;
  }

  async getDishReviews(dishId: number, page: number = 1, limit: number = 10) {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(50, Math.max(1, limit));
    const offset = (safePage - 1) * safeLimit;

    const dishRatingRepo = AppDataSource.getRepository(DanhGiaMonModel);
    const orderItemRepo = AppDataSource.getRepository(ChiTietDonHangModel);

    // 1. Get dish rating records for this dish
    const dishRatings = await dishRatingRepo.find({ where: { maMon: dishId } });
    const reviewIdsFromDishRatings = dishRatings.map((dr) => dr.maDanhGia).filter(Boolean);

    // 2. Get order IDs from chitietdonhang for this dish
    const orderItems = await orderItemRepo.find({ where: { maMonAn: dishId } });
    const orderIds = orderItems.map((oi) => oi.maDonHang).filter(Boolean);
    const chiTietIds = orderItems.map((oi) => oi.maChiTietDon).filter(Boolean);

    if (reviewIdsFromDishRatings.length === 0 && orderIds.length === 0 && chiTietIds.length === 0) {
      return {
        reviews: [],
        total: 0,
        page: safePage,
        limit: safeLimit,
        totalPages: 0,
        averageRating: 0.0,
      };
    }

    const qb = this.reviewRepo.createQueryBuilder('dg')
      .where('(dg.is_hidden IS NOT TRUE OR dg.is_hidden IS NULL)');

    const conditions: string[] = [];
    const params: Record<string, any> = {};

    if (reviewIdsFromDishRatings.length > 0) {
      conditions.push('dg.madanhgia IN (:...reviewIds)');
      params.reviewIds = reviewIdsFromDishRatings;
    }
    if (orderIds.length > 0) {
      conditions.push('dg.madonhang IN (:...orderIds)');
      params.orderIds = orderIds;
    }
    if (chiTietIds.length > 0) {
      conditions.push('dg.machitietdon IN (:...chiTietIds)');
      params.chiTietIds = chiTietIds;
    }

    qb.andWhere(`(${conditions.join(' OR ')})`, params);

    const [reviews, total] = await qb
      .orderBy('dg.ngaynhanxet', 'DESC')
      .skip(offset)
      .take(safeLimit)
      .getManyAndCount();

    // Enrich reviews
    const formattedReviews = await Promise.all(
      reviews.map(async (r) => {
        const cust = r.maKhachHang
          ? await this.customerRepo.findOne({ where: { maKhachHang: r.maKhachHang } })
          : null;

        const dr = dishRatings.find((item) => item.maDanhGia === r.maDanhGia);

        return {
          ...r,
          soLuongSao: dr?.soLuongSao || r.soLuongSao || 5,
          rating: dr?.soLuongSao || r.soLuongSao || 5,
          nhanXet: dr?.nhanXet || r.nhanXet || '',
          comment: dr?.nhanXet || r.nhanXet || '',
          tenKhachHang: cust ? cust.hoTen : 'Khách hàng',
        };
      }),
    );

    let avg = 0.0;
    if (formattedReviews.length > 0) {
      const sum = formattedReviews.reduce((acc, r) => acc + r.rating, 0);
      avg = Math.round((sum / formattedReviews.length) * 10) / 10;
    }

    return {
      reviews: formattedReviews,
      total,
      page: safePage,
      limit: safeLimit,
      totalPages: Math.max(1, Math.ceil(total / safeLimit)),
      averageRating: avg,
    };
  }
}
