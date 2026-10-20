import { AppDataSource } from '../config/database';
import { DatBanModel } from '../models/dat_ban_model';
import { BanModel } from '../models/ban_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { Between, LessThan, MoreThan, Not, In, Like } from 'typeorm';
import { RealtimeService } from './realtime_service';
import { NotificationService } from './notification_service';

export interface ReservationFilters {
  timeRange?: 'today' | 'tomorrow' | '7days' | '30days' | 'custom' | 'all';
  startDate?: string;
  endDate?: string;
  trangThai?: string;
  maBan?: number | string;
  search?: string;
  page?: number;
  limit?: number;
}

export class ReservationService {
  private get datBanRepo() {
    return AppDataSource.getRepository(DatBanModel);
  }

  private get banRepo() {
    return AppDataSource.getRepository(BanModel);
  }

  private get khachHangRepo() {
    return AppDataSource.getRepository(KhachHangModel);
  }

  private get cuaHangRepo() {
    return AppDataSource.getRepository(CuaHangModel);
  }

  private async validateOperatingHours(maQuan: number, start: Date, end: Date) {
    const store = await this.cuaHangRepo.findOne({ where: { maQuan } });
    if (!store) throw new Error('Nhà hàng không tồn tại');

    const st = String(store.trangThai || '').toLowerCase().trim();
    if (st === 'ngưng kinh doanh' || st === 'đóng cửa') {
      throw new Error(`Cửa hàng "${store.tenQuan}" hiện đang tạm ngưng nhận lịch đặt bàn!`);
    }

    if (store.coChoDatTruoc === false) {
      throw new Error(`Cửa hàng "${store.tenQuan}" hiện không hỗ trợ dịch vụ đặt bàn trước!`);
    }

    if (store.gioHoatDong && store.gioHoatDong.includes('-')) {
      const [openStr, closeStr] = store.gioHoatDong.split('-').map((s) => s.trim());
      const parseTime = (timeStr: string) => {
        const parts = timeStr.split(':').map((val) => parseInt(val, 10));
        const h = isNaN(parts[0]) ? 0 : parts[0];
        const m = parts.length > 1 && !isNaN(parts[1]) ? parts[1] : 0;
        return h * 60 + m;
      };

      const openMin = parseTime(openStr);
      const closeMin = parseTime(closeStr);
      const startMin = start.getHours() * 60 + start.getMinutes();

      if (openMin < closeMin) {
        if (startMin < openMin || startMin >= closeMin) {
          throw new Error(`Giờ hẹn nằm ngoài giờ mở cửa của nhà hàng (${store.gioHoatDong})`);
        }
      } else if (openMin > closeMin) {
        // Overnight operating hours (e.g. 18:00 - 02:00)
        if (startMin < openMin && startMin >= closeMin) {
          throw new Error(`Giờ hẹn nằm ngoài giờ mở cửa của nhà hàng (${store.gioHoatDong})`);
        }
      }
    }
  }

  private async checkTableOverlap(maQuan: number, maBan: number, start: Date, end: Date, excludeId?: number) {
    const qb = this.datBanRepo.createQueryBuilder('db')
      .where('db.maQuan = :maQuan', { maQuan })
      .andWhere('db.maBan = :maBan', { maBan })
      .andWhere('db.trangThai NOT IN (:...cancelledStatuses)', {
        cancelledStatuses: ['DA_HUY', 'TU_CHOI', 'KHACH_KHONG_DEN', 'da_huy', 'tu_choi', 'khach_khong_den'],
      })
      .andWhere('(db.thoiGianBatDau < :end AND db.thoiGianKetThuc > :start)', { start, end });

    if (excludeId) {
      qb.andWhere('db.maDatBan != :excludeId', { excludeId });
    }

    const count = await qb.getCount();
    if (count > 0) {
      throw new Error('Bàn đã được khách khác đặt trong khung giờ này!');
    }
  }

  async getDashboardStats(maQuan: number) {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const choXacNhan = await this.datBanRepo.count({
      where: {
        maQuan,
        trangThai: In(['CHO_XAC_NHAN', 'cho_xac_nhan', 'PENDING', 'pending']),
      },
    });

    const daXacNhan = await this.datBanRepo.count({
      where: {
        maQuan,
        trangThai: In(['DA_XAC_NHAN', 'da_xac_nhan', 'CONFIRMED', 'confirmed']),
      },
    });

    const homNay = await this.datBanRepo.count({
      where: {
        maQuan,
        thoiGianBatDau: Between(todayStart, todayEnd),
        trangThai: Not(In(['DA_HUY', 'TU_CHOI', 'KHACH_KHONG_DEN', 'da_huy', 'tu_choi', 'khach_khong_den'])),
      },
    });

    const dangSuDung = await this.datBanRepo.count({
      where: {
        maQuan,
        trangThai: In(['DANG_SU_DUNG', 'dang_su_dung', 'DA_DEN', 'da_den', 'CUSTOMER_ARRIVED']),
      },
    });

    const daHoanTat = await this.datBanRepo.count({
      where: {
        maQuan,
        trangThai: In(['DA_HOAN_TAT', 'da_hoan_tat', 'HOAN_TAT', 'hoan_tat', 'COMPLETED', 'completed']),
      },
    });

    return {
      choXacNhan,
      daXacNhan,
      homNay,
      dangSuDung,
      daHoanTat,
    };
  }

  async getReservations(maQuan: number, filters: ReservationFilters) {
    const page = Math.max(1, Number(filters.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(filters.limit) || 15));
    const skip = (page - 1) * limit;

    const qb = this.datBanRepo.createQueryBuilder('db')
      .leftJoinAndSelect('db.ban', 'ban')
      .leftJoinAndSelect('db.khachHang', 'khachHang')
      .where('db.maQuan = :maQuan', { maQuan });

    if (filters.timeRange && filters.timeRange !== 'all') {
      const now = new Date();
      let start: Date;
      let end: Date;

      if (filters.timeRange === 'today') {
        start = new Date(now.setHours(0, 0, 0, 0));
        end = new Date(now.setHours(23, 59, 59, 999));
      } else if (filters.timeRange === 'tomorrow') {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        start = new Date(tomorrow.setHours(0, 0, 0, 0));
        end = new Date(tomorrow.setHours(23, 59, 59, 999));
      } else if (filters.timeRange === '7days') {
        start = new Date(now.setHours(0, 0, 0, 0));
        end = new Date();
        end.setDate(end.getDate() + 7);
        end.setHours(23, 59, 59, 999);
      } else if (filters.timeRange === '30days') {
        start = new Date(now.setHours(0, 0, 0, 0));
        end = new Date();
        end.setDate(end.getDate() + 30);
        end.setHours(23, 59, 59, 999);
      } else if (filters.timeRange === 'custom' && filters.startDate && filters.endDate) {
        start = new Date(filters.startDate);
        end = new Date(filters.endDate);
        end.setHours(23, 59, 59, 999);
      }

      if (start! && end!) {
        qb.andWhere('db.thoiGianBatDau BETWEEN :start AND :end', { start, end });
      }
    }

    if (filters.trangThai && filters.trangThai !== 'ALL') {
      if (filters.trangThai === 'DANG_SU_DUNG') {
        qb.andWhere('db.trangThai IN (:...stList)', { stList: ['DANG_SU_DUNG', 'DA_DEN'] });
      } else {
        qb.andWhere('db.trangThai = :trangThai', { trangThai: filters.trangThai });
      }
    }

    if (filters.maBan && filters.maBan !== 'ALL') {
      qb.andWhere('db.maBan = :maBanFilter', { maBanFilter: Number(filters.maBan) });
    }

    if (filters.search && filters.search.trim()) {
      const keyword = `%${filters.search.trim().toLowerCase()}%`;
      const searchNum = Number(filters.search.trim());

      if (!isNaN(searchNum) && searchNum > 0) {
        qb.andWhere(
          '(db.maDatBan = :searchNum OR LOWER(db.tenKhachHang) LIKE :keyword OR LOWER(db.sdtKhachHang) LIKE :keyword OR LOWER(ban.tenBan) LIKE :keyword OR LOWER(khachHang.hoTen) LIKE :keyword OR LOWER(khachHang.sdt) LIKE :keyword)',
          { searchNum, keyword }
        );
      } else {
        qb.andWhere(
          '(LOWER(db.tenKhachHang) LIKE :keyword OR LOWER(db.sdtKhachHang) LIKE :keyword OR LOWER(ban.tenBan) LIKE :keyword OR LOWER(khachHang.hoTen) LIKE :keyword OR LOWER(khachHang.sdt) LIKE :keyword)',
          { keyword }
        );
      }
    }

    // Add status priority column alias for sorting: CHO_XAC_NHAN (1) -> DA_XAC_NHAN (2) -> DANG_SU_DUNG/DA_DEN (3) -> HOAN_TAT (4) -> Others (5)
    qb.addSelect(
      `CASE UPPER(db.trangThai)
        WHEN 'CHO_XAC_NHAN' THEN 1
        WHEN 'PENDING' THEN 1
        WHEN 'DA_XAC_NHAN' THEN 2
        WHEN 'CONFIRMED' THEN 2
        WHEN 'DA_DEN' THEN 3
        WHEN 'DANG_SU_DUNG' THEN 3
        WHEN 'CUSTOMER_ARRIVED' THEN 3
        WHEN 'DA_HOAN_TAT' THEN 4
        WHEN 'HOAN_TAT' THEN 4
        WHEN 'COMPLETED' THEN 4
        ELSE 5
      END`,
      'status_priority'
    );

    qb.orderBy('status_priority', 'ASC');
    qb.addOrderBy('db.thoiGianBatDau', 'DESC');
    qb.addOrderBy('db.maDatBan', 'DESC');
    qb.skip(skip).take(limit);

    const [reservations, total] = await qb.getManyAndCount();

    return {
      reservations,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getReservationById(maQuan: number, maDatBan: number) {
    const reservation = await this.datBanRepo.findOne({
      where: { maDatBan, maQuan },
      relations: ['ban', 'khachHang'],
    });

    if (!reservation) {
      throw new Error('Không tìm thấy thông tin đặt bàn hoặc bạn không có quyền xem');
    }

    return reservation;
  }

  async updateReservationStatus(
    maQuan: number,
    maDatBan: number,
    newStatus: string,
    note?: string
  ) {
    const reservation = await this.datBanRepo.findOne({
      where: { maDatBan, maQuan },
      relations: ['ban'],
    });

    if (!reservation) {
      throw new Error('Không tìm thấy lượt đặt bàn');
    }

    const currentStatus = reservation.trangThai.toUpperCase();
    const targetStatus = newStatus.toUpperCase();

    const terminalStatuses = ['DA_HOAN_TAT', 'DA_HUY', 'TU_CHOI', 'KHACH_KHONG_DEN'];
    if (terminalStatuses.includes(currentStatus)) {
      throw new Error(`Đặt bàn đã kết thúc (${currentStatus}), không thể đổi trạng thái!`);
    }

    const allowedTransitions: Record<string, string[]> = {
      CHO_XAC_NHAN: ['DA_XAC_NHAN', 'TU_CHOI', 'DA_HUY'],
      DA_XAC_NHAN: ['DA_DEN', 'KHACH_KHONG_DEN', 'DA_HUY'],
      DA_DEN: ['DANG_SU_DUNG', 'DA_HOAN_TAT'],
      DANG_SU_DUNG: ['DA_HOAN_TAT'],
    };

    const validNextList = allowedTransitions[currentStatus] || [];
    if (!validNextList.includes(targetStatus)) {
      throw new Error(`Không thể chuyển trạng thái từ "${currentStatus}" sang "${targetStatus}"`);
    }

    reservation.trangThai = targetStatus;
    if (note) {
      reservation.ghiChu = note;
    }

    const saved = await this.datBanRepo.save(reservation);

    if (reservation.maBan) {
      const ban = await this.banRepo.findOne({ where: { maBan: reservation.maBan } });
      if (ban) {
        if (['DA_DEN', 'DANG_SU_DUNG'].includes(targetStatus)) {
          ban.trangThai = 'DANG_SU_DUNG';
        } else if (['DA_HOAN_TAT', 'DA_HUY', 'TU_CHOI', 'KHACH_KHONG_DEN'].includes(targetStatus)) {
          const activeOverlap = await this.datBanRepo.count({
            where: {
              maQuan,
              maBan: reservation.maBan,
              maDatBan: Not(reservation.maDatBan),
              trangThai: In(['DANG_SU_DUNG', 'DA_DEN']),
            },
          });
          if (activeOverlap === 0 && ban.trangThai !== 'TAM_NGUNG') {
            ban.trangThai = 'TRONG';
          }
        }
        await this.banRepo.save(ban);
      }
    }

    try {
      RealtimeService.getInstance().emitReservationStatusChanged(
        maQuan,
        saved.maDatBan,
        saved.trangThai,
        saved.maKhachHang
      );
    } catch (_) {}

    // Persist & Emit Notifications
    try {
      const store = await this.cuaHangRepo.findOne({ where: { maQuan } });
      const tenQuan = store?.tenQuan || 'Nhà hàng';

      if (targetStatus === 'DA_XAC_NHAN' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'reservation:confirmed',
          title: 'Đặt bàn đã được xác nhận',
          body: `${tenQuan} đã xác nhận lượt đặt bàn #DB-${saved.maDatBan} cho bạn.`,
          data: { reservationId: saved.maDatBan, maQuan: saved.maQuan, status: targetStatus },
        });
      } else if (targetStatus === 'TU_CHOI' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'reservation:rejected',
          title: 'Yêu cầu đặt bàn bị từ chối',
          body: `${tenQuan} rất tiếc phải từ chối yêu cầu đặt bàn #DB-${saved.maDatBan}.${note ? ` Lý do: ${note}` : ''}`,
          data: { reservationId: saved.maDatBan, maQuan: saved.maQuan, status: targetStatus, note },
        });
      } else if ((targetStatus === 'DA_DEN' || targetStatus === 'DANG_SU_DUNG') && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'reservation:checked_in',
          title: 'Chào mừng quý khách',
          body: `Chào mừng bạn đã đến ${tenQuan}! Chúc bạn có trải nghiệm tuyệt vời.`,
          data: { reservationId: saved.maDatBan, maQuan: saved.maQuan, status: targetStatus },
        });
      } else if (targetStatus === 'DA_HOAN_TAT' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'reservation:completed',
          title: 'Bữa ăn đã hoàn tất',
          body: `Lượt đặt bàn #DB-${saved.maDatBan} tại ${tenQuan} đã hoàn tất. Cảm ơn quý khách!`,
          data: { reservationId: saved.maDatBan, maQuan: saved.maQuan, status: targetStatus },
        });
      } else if (targetStatus === 'DA_HUY') {
        if (note && note.includes('Khách hàng')) {
          // Khách hàng tự hủy -> Gửi thông báo cho nhà hàng
          await NotificationService.getInstance().sendNotification({
            recipientId: maQuan,
            recipientRole: 'restaurant',
            type: 'reservation:cancelled',
            title: 'Khách hàng hủy đặt bàn',
            body: `Khách hàng ${saved.tenKhachHang || ''} đã hủy lượt đặt bàn #DB-${saved.maDatBan}.`,
            data: { reservationId: saved.maDatBan, maQuan: saved.maQuan, status: targetStatus },
          });
        } else if (saved.maKhachHang) {
          // Nhà hàng hủy -> Gửi thông báo cho khách hàng
          await NotificationService.getInstance().sendNotification({
            recipientId: saved.maKhachHang,
            recipientRole: 'user',
            type: 'reservation:cancelled',
            title: 'Lượt đặt bàn bị hủy',
            body: `Lượt đặt bàn #DB-${saved.maDatBan} tại ${tenQuan} đã bị hủy.${note ? ` Lý do: ${note}` : ''}`,
            data: { reservationId: saved.maDatBan, maQuan: saved.maQuan, status: targetStatus, note },
          });
        }
      }
    } catch (notifErr) {
      console.error('[ReservationService] Failed to send status notification:', notifErr);
    }

    return saved;
  }

  async updateReservation(maQuan: number, maDatBan: number, data: any) {
    const reservation = await this.datBanRepo.findOne({ where: { maDatBan, maQuan } });
    if (!reservation) {
      throw new Error('Không tìm thấy lượt đặt bàn hoặc không thuộc quyền quản lý của quán!');
    }

    // Whitelist allowed fields to prevent Mass Assignment (BOLA / Parameter Tampering)
    // NEVER allow overwriting: maQuan, maKhachHang, trangThai, maDatBan
    if (data.soNguoi !== undefined) {
      const num = Number(data.soNguoi);
      if (isNaN(num) || num <= 0) {
        throw new Error('Số lượng khách không hợp lệ');
      }
      reservation.soNguoi = num;
    }

    if (data.ghiChu !== undefined) {
      reservation.ghiChu = String(data.ghiChu || '');
    }

    if (data.tenKhachHang !== undefined) {
      reservation.tenKhachHang = String(data.tenKhachHang || '');
    }

    if (data.sdtKhachHang !== undefined) {
      reservation.sdtKhachHang = String(data.sdtKhachHang || '');
    }

    let newStart = reservation.thoiGianBatDau;
    let newEnd = reservation.thoiGianKetThuc;
    let timeChanged = false;

    if (data.thoiGianBatDau !== undefined) {
      const parsedStart = new Date(data.thoiGianBatDau);
      if (isNaN(parsedStart.getTime())) {
        throw new Error('Thời gian hẹn không hợp lệ');
      }
      newStart = parsedStart;
      newEnd = new Date(parsedStart.getTime() + 90 * 60 * 1000);
      reservation.thoiGianBatDau = newStart;
      reservation.thoiGianKetThuc = newEnd;
      timeChanged = true;
    }

    if (data.maBan !== undefined) {
      const targetTableId = data.maBan ? Number(data.maBan) : null;
      if (targetTableId) {
        const tableRecord = await this.banRepo.findOne({ where: { maBan: targetTableId, maQuan } });
        if (!tableRecord) {
          throw new Error('Bàn không tồn tại hoặc không thuộc nhà hàng');
        }
        if (reservation.soNguoi > Number(tableRecord.sucChua || 4)) {
          throw new Error(`Bàn "${tableRecord.tenBan}" chỉ có sức chứa tối đa ${tableRecord.sucChua} người`);
        }
        await this.checkTableOverlap(maQuan, targetTableId, newStart, newEnd, reservation.maDatBan);
        reservation.maBan = targetTableId;
      } else {
        reservation.maBan = null as any;
      }
    } else if (timeChanged && reservation.maBan) {
      await this.checkTableOverlap(maQuan, reservation.maBan, newStart, newEnd, reservation.maDatBan);
    }

    return await this.datBanRepo.save(reservation);
  }

  private async checkTableOverlapWithManager(
    manager: any,
    maQuan: number,
    maBan: number,
    start: Date,
    end: Date,
    excludeId?: number
  ) {
    const qb = manager.createQueryBuilder(DatBanModel, 'db')
      .where('db.maQuan = :maQuan', { maQuan })
      .andWhere('db.maBan = :maBan', { maBan })
      .andWhere('db.trangThai NOT IN (:...cancelledStatuses)', {
        cancelledStatuses: ['DA_HUY', 'TU_CHOI', 'KHACH_KHONG_DEN', 'da_huy', 'tu_choi', 'khach_khong_den'],
      })
      .andWhere('(db.thoiGianBatDau < :end AND db.thoiGianKetThuc > :start)', { start, end });

    if (excludeId) {
      qb.andWhere('db.maDatBan != :excludeId', { excludeId });
    }

    const count = await qb.getCount();
    if (count > 0) {
      throw new Error('Bàn đã được khách khác đặt trong khung giờ này!');
    }
  }

  async createReservation(maQuanOrData: number | any, data?: any) {
    let payload: any;
    if (typeof maQuanOrData === 'number') {
      payload = { ...data, maQuan: maQuanOrData };
    } else {
      payload = maQuanOrData;
    }

    const start = new Date(payload.thoiGianBatDau);
    if (isNaN(start.getTime())) {
      throw new Error('Thời gian hẹn không hợp lệ');
    }

    const now = new Date();
    if (start.getTime() < now.getTime() - 5 * 60 * 1000) {
      throw new Error('Thời gian hẹn phải ở trong tương lai');
    }

    const end = new Date(start.getTime() + 90 * 60 * 1000);

    await this.validateOperatingHours(payload.maQuan, start, end);

    const saved = await AppDataSource.transaction(async (manager) => {
      let assignedTableId = payload.maBan ? Number(payload.maBan) : null;
      const numGuests = Math.max(1, Number(payload.soNguoi) || 2);

      if (assignedTableId) {
        // Lock table record (pessimistic_write) to prevent double-booking race condition
        const tableRecord = await manager.findOne(BanModel, {
          where: { maBan: assignedTableId, maQuan: payload.maQuan },
          lock: { mode: 'pessimistic_write' },
        });

        if (!tableRecord) {
          throw new Error('Bàn không tồn tại hoặc không thuộc nhà hàng đã chọn');
        }

        if (tableRecord.trangThai === 'TAM_NGUNG') {
          throw new Error(`Bàn "${tableRecord.tenBan}" hiện đang tạm ngưng phục vụ/bảo trì`);
        }

        if (numGuests > Number(tableRecord.sucChua || 4)) {
          throw new Error(`Bàn "${tableRecord.tenBan}" chỉ có sức chứa tối đa ${tableRecord.sucChua} người, không đủ cho ${numGuests} người`);
        }

        await this.checkTableOverlapWithManager(manager, payload.maQuan, assignedTableId, start, end);
      } else {
        // Customer did not specify a table: find an available table with capacity >= numGuests
        // Exclude suspended tables (TAM_NGUNG)
        const allTables = await manager.find(BanModel, {
          where: { maQuan: payload.maQuan },
          order: { sucChua: 'ASC' },
        });

        if (allTables.length > 0) {
          for (const tbl of allTables) {
            if (tbl.trangThai === 'TAM_NGUNG') continue;
            if (Number(tbl.sucChua || 0) >= numGuests) {
              try {
                // Lock the candidate table record to serialize concurrent bookings
                await manager.findOne(BanModel, {
                  where: { maBan: tbl.maBan, maQuan: payload.maQuan },
                  lock: { mode: 'pessimistic_write' },
                });
                await this.checkTableOverlapWithManager(manager, payload.maQuan, tbl.maBan, start, end);
                assignedTableId = tbl.maBan;
                break;
              } catch (_) {}
            }
          }
        }
      }

      if (!assignedTableId) {
        throw new Error(
          `Nhà hàng hiện không còn bàn trống phù hợp cho ${numGuests} người trong khung giờ này. Vui lòng chọn khung giờ khác!`
        );
      }

      const reservation = manager.create(DatBanModel, {
        maQuan: payload.maQuan,
        maBan: assignedTableId || null,
        maKhachHang: payload.maKhachHang || null,
        tenKhachHang: payload.tenKhachHang,
        sdtKhachHang: payload.sdtKhachHang,
        soNguoi: numGuests,
        thoiGianBatDau: start,
        thoiGianKetThuc: end,
        trangThai: payload.trangThai || 'CHO_XAC_NHAN',
        ghiChu: payload.ghiChu || '',
      });

      return await manager.save(reservation);
    });

    try {
      RealtimeService.getInstance().emitReservationCreated(payload.maQuan, saved.maDatBan, {
        maDatBan: saved.maDatBan,
        tenKhachHang: saved.tenKhachHang,
        sdtKhachHang: saved.sdtKhachHang,
        soNguoi: saved.soNguoi,
        thoiGianBatDau: saved.thoiGianBatDau,
        trangThai: saved.trangThai,
      });

      // Notify Restaurant of new reservation
      const timeStr = new Date(saved.thoiGianBatDau).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
      const dateStr = new Date(saved.thoiGianBatDau).toLocaleDateString('vi-VN');
      await NotificationService.getInstance().sendNotification({
        recipientId: payload.maQuan,
        recipientRole: 'restaurant',
        type: 'reservation:created',
        title: 'Yêu cầu đặt bàn mới',
        body: `Yêu cầu đặt bàn mới #DB-${saved.maDatBan}: ${saved.tenKhachHang || 'Khách'} (${saved.soNguoi} người) vào lúc ${timeStr} ngày ${dateStr}.`,
        data: { reservationId: saved.maDatBan, maQuan: payload.maQuan },
      });
    } catch (err: any) {
      console.warn('⚠️ Realtime emit error (reservation:created):', err?.message || err);
    }

    return saved;
  }

  // ── CUSTOMER RESERVATION METHODS ──────────────────────────────────────────
  async createCustomerReservation(userSub: number, dto: any) {
    const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
    if (!khachHang) {
      throw new Error('Chưa tìm thấy thông tin khách hàng cho tài khoản này');
    }

    return await this.createReservation({
      ...dto,
      maKhachHang: khachHang.maKhachHang,
      tenKhachHang: dto.tenKhachHang || khachHang.hoTen,
      sdtKhachHang: dto.sdtKhachHang || khachHang.sdt,
    });
  }

  async getCustomerReservations(userSub: number) {
    const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
    if (!khachHang) return [];

    return await this.datBanRepo.find({
      where: { maKhachHang: khachHang.maKhachHang },
      relations: ['cuaHang', 'ban'],
      order: { thoiGianBatDau: 'DESC' },
    });
  }

  async getCustomerReservationById(userSub: number, maDatBan: number) {
    const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
    if (!khachHang) throw new Error('Không tìm thấy thông tin khách hàng');

    const reservation = await this.datBanRepo.findOne({
      where: { maDatBan, maKhachHang: khachHang.maKhachHang },
      relations: ['cuaHang', 'ban'],
    });

    if (!reservation) throw new Error('Không tìm thấy lượt đặt bàn');
    return reservation;
  }

  async cancelCustomerReservation(userSub: number, maDatBan: number) {
    const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
    if (!khachHang) throw new Error('Không tìm thấy thông tin khách hàng');

    const reservation = await this.datBanRepo.findOne({
      where: { maDatBan, maKhachHang: khachHang.maKhachHang },
    });

    if (!reservation) throw new Error('Không tìm thấy lượt đặt bàn');

    if (['DA_HOAN_TAT', 'DA_HUY', 'TU_CHOI', 'KHACH_KHONG_DEN'].includes(reservation.trangThai.toUpperCase())) {
      throw new Error('Đặt bàn đã hoàn tất hoặc đã hủy, không thể thao tác!');
    }

    return await this.updateReservationStatus(reservation.maQuan, maDatBan, 'DA_HUY', 'Khách hàng tự hủy');
  }

  // ── QUẢN LÝ BÀN PHỤC VỤ (TABLE MANAGEMENT) ──────────────────────────────────
  async getTables(maQuan: number) {
    return await this.banRepo.find({
      where: { maQuan },
      order: { tenBan: 'ASC' },
    });
  }

  async createTable(maQuan: number, data: Partial<BanModel>) {
    const ban = this.banRepo.create({
      ...data,
      maQuan,
      trangThai: data.trangThai || 'TRONG',
    });
    return await this.banRepo.save(ban);
  }

  async updateTable(maQuan: number, maBan: number, data: Partial<BanModel>) {
    const ban = await this.banRepo.findOne({ where: { maBan, maQuan } });
    if (!ban) throw new Error('Bàn không tồn tại hoặc không thuộc quyền quản lý của quán');
    Object.assign(ban, data);
    return await this.banRepo.save(ban);
  }

  async toggleTableStatus(maQuan: number, maBan: number, newTrangThai?: string) {
    const ban = await this.banRepo.findOne({ where: { maBan, maQuan } });
    if (!ban) throw new Error('Bàn không tồn tại');
    ban.trangThai = newTrangThai || (ban.trangThai === 'TRONG' ? 'DANG_SU_DUNG' : 'TRONG');
    return await this.banRepo.save(ban);
  }
}
