import { Server as HttpServer } from 'http';
import { Server as SocketIOServer, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import { AppDataSource } from '../config/database';
import { CuaHangModel } from '../models/cua_hang_model';
import { DonHangModel } from '../models/don_hang_model';
import { DatBanModel } from '../models/dat_ban_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { SupportTicketModel } from '../models/support_ticket_model';
import { TokenBlacklistService } from './token_blacklist_service';

dotenv.config();

export const REALTIME_EVENTS = {
  ORDER_CREATED: 'order:created',
  ORDER_STATUS_CHANGED: 'order:status_changed',
  RESERVATION_CREATED: 'reservation:created',
  RESERVATION_STATUS_CHANGED: 'reservation:status_changed',
  PAYMENT_CONFIRMED: 'payment:confirmed',
  NOTIFICATION_NEW: 'notification:new',
  VOUCHER_UPDATED: 'voucher:updated',
  STORE_PROFILE_UPDATED: 'restaurant:profile_updated',
  RATING_UPDATED: 'rating:updated',
  REVIEW_CREATED: 'review:created',
  REVIEW_UPDATED: 'review:updated',
  REVIEW_VISIBILITY_CHANGED: 'review:visibility_changed',
  MENU_UPDATED: 'menu:updated',
} as const;

export interface RealtimeUserPayload {
  sub: number;
  email: string;
  role: string;
}

export class RealtimeService {
  private static instance: RealtimeService;
  private io: SocketIOServer | null = null;

  private constructor() {}

  public static getInstance(): RealtimeService {
    if (!RealtimeService.instance) {
      RealtimeService.instance = new RealtimeService();
    }
    return RealtimeService.instance;
  }

  public getIO(): SocketIOServer | null {
    return this.io;
  }

  public initialize(httpServer: HttpServer) {
    if (this.io) return;

    this.io = new SocketIOServer(httpServer, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST'],
      },
    });

    // Connection Authentication Guard
    this.io.use((socket: Socket, next) => {
      try {
        const token =
          socket.handshake.auth?.token ||
          socket.handshake.headers?.authorization?.replace('Bearer ', '');

        if (!token) {
          return next(new Error('Authentication token required'));
        }

        const secret = process.env.JWT_SECRET;
        if (!secret) {
          return next(new Error('JWT secret configuration missing'));
        }

        const decoded = jwt.verify(token, secret) as unknown as RealtimeUserPayload;

        if (TokenBlacklistService.getInstance().isRevoked(token, decoded)) {
          return next(new Error('Session revoked or token invalidated'));
        }

        socket.data.user = decoded;
        next();
      } catch (err: any) {
        next(new Error('Invalid authentication token'));
      }
    });

    this.io.on('connection', async (socket: Socket) => {
      const user = socket.data.user as RealtimeUserPayload;
      if (!user) return;

      const userSub = Number(user.sub);
      // Auto join personal account room by account ID (maTaiKhoan)
      socket.join(`account:${userSub}`);
      socket.join(`user:${userSub}`);

      // Auto join customer room by customer ID (maKhachHang)
      try {
        const khRepo = AppDataSource.getRepository(KhachHangModel);
        const kh = await khRepo.findOne({ where: { maTaiKhoan: userSub } });
        if (kh) {
          socket.join(`customer:${kh.maKhachHang}`);
        }
      } catch (e) {
        console.error('[RealtimeService] [Warn] Realtime auto-join customer room error:', e);
      }

      // Auto join admin rooms if user is an ADMIN
      const role = String(user.role || '').toUpperCase();
      if (role === 'ADMIN') {
        socket.join('admin');
        socket.join(`admin:${userSub}`);
        socket.join('support:admin');
      }

      // Auto join restaurant room if user is a store owner
      if (role === 'CUAN_HANG' || role === 'CUA_HANG' || role === 'ADMIN') {
        try {
          const storeRepo = AppDataSource.getRepository(CuaHangModel);
          const store = await storeRepo.findOne({ where: { maTaiKhoan: userSub } });
          if (store) {
            socket.join(`restaurant:${store.maQuan}`);
          }
        } catch (e) {
          console.error('[RealtimeService] [Warn] Realtime auto-join restaurant error:', e);
        }
      }

      // Per-socket rate limiter to protect database from room:join query flooding
      let joinCount = 0;
      let lastResetTime = Date.now();
      const MAX_JOINS_PER_MINUTE = 30;

      // Client room join requests (strictly validated by server for ownership)
      socket.on('room:join', async (data: { roomType: string; id?: number }) => {
        if (!data || typeof data.roomType !== 'string') return;

        // Check sliding window rate limit
        const now = Date.now();
        if (now - lastResetTime > 60000) {
          joinCount = 0;
          lastResetTime = now;
        }
        joinCount++;
        if (joinCount > MAX_JOINS_PER_MINUTE) {
          console.warn(`[RealtimeService] [Security] Rate limit exceeded on room:join for socket ${socket.id} (user #${user.sub})`);
          socket.emit('error', { code: 'RATE_LIMIT_EXCEEDED', message: 'Quá nhiều yêu cầu tham gia phòng. Vui lòng đợi 1 phút.' });
          return;
        }

        const roomId = Number(data.id || 0);
        if (isNaN(roomId) || roomId < 0) return;
        const userRole = String(user.role || '').toUpperCase();
        const subId = Number(user.sub);

        try {
          if (data.roomType === 'admin') {
            if (userRole === 'ADMIN') {
              socket.join('admin');
              console.log(`[RealtimeService] [Info] Admin #${subId} joined room: admin`);
            } else {
              console.warn(`[RealtimeService] [Security] Non-admin user #${subId} (role: ${userRole}) denied joining admin room`);
            }
          } else if (data.roomType === 'restaurant') {
            if (userRole === 'ADMIN') {
              socket.join(`restaurant:${roomId}`);
            } else if (userRole === 'CUAN_HANG' || userRole === 'CUA_HANG') {
              const store = await AppDataSource.getRepository(CuaHangModel).findOne({ where: { maTaiKhoan: subId } });
              if (store && store.maQuan === roomId) {
                socket.join(`restaurant:${roomId}`);
              }
            }
          } else if (data.roomType === 'restaurant_public' || data.roomType === 'restaurant_menu') {
            // Public viewers for real-time rating & menu sync
            socket.join(`restaurant_public:${roomId}`);
          } else if (data.roomType === 'order') {
            if (userRole === 'ADMIN') {
              socket.join(`order:${roomId}`);
            } else {
              const order = await AppDataSource.getRepository(DonHangModel).findOne({ where: { maDonHang: roomId } });
              if (order) {
                if (userRole === 'CUAN_HANG' || userRole === 'CUA_HANG') {
                  const store = await AppDataSource.getRepository(CuaHangModel).findOne({ where: { maTaiKhoan: subId } });
                  if (store && store.maQuan === order.maQuan) socket.join(`order:${roomId}`);
                } else {
                  const kh = await AppDataSource.getRepository(KhachHangModel).findOne({ where: { maTaiKhoan: subId } });
                  if (kh && kh.maKhachHang === order.maKhachHang) socket.join(`order:${roomId}`);
                }
              }
            }
          } else if (data.roomType === 'reservation') {
            if (userRole === 'ADMIN') {
              socket.join(`reservation:${roomId}`);
            } else {
              const resv = await AppDataSource.getRepository(DatBanModel).findOne({ where: { maDatBan: roomId } });
              if (resv) {
                if (userRole === 'CUAN_HANG' || userRole === 'CUA_HANG') {
                  const store = await AppDataSource.getRepository(CuaHangModel).findOne({ where: { maTaiKhoan: subId } });
                  if (store && store.maQuan === resv.maQuan) socket.join(`reservation:${roomId}`);
                } else {
                  const kh = await AppDataSource.getRepository(KhachHangModel).findOne({ where: { maTaiKhoan: subId } });
                  if (kh && kh.maKhachHang === resv.maKhachHang) socket.join(`reservation:${roomId}`);
                }
              }
            }
          } else if (data.roomType === 'ticket') {
            if (userRole === 'ADMIN') {
              socket.join(`ticket:${roomId}`);
            } else {
              const ticket = await AppDataSource.getRepository(SupportTicketModel).findOne({ where: { maPhieu: roomId } });
              if (ticket && ticket.maTaiKhoan === subId) {
                socket.join(`ticket:${roomId}`);
              } else {
                console.warn(`[RealtimeService] [Security] User #${subId} unauthorized to join ticket:${roomId}`);
              }
            }
          }
        } catch (err) {
          console.error('[RealtimeService] [Warn] Error validating socket room join:', err);
        }
      });

      socket.on('room:leave', (data: { roomType: string; id: number }) => {
        if (!data || !data.roomType || !data.id) return;
        socket.leave(`${data.roomType}:${data.id}`);
      });
    });

    console.log('[RealtimeService] [Info] Realtime Socket.io gateway initialized successfully');
  }

  // ── Emitter API Methods (Called ONLY AFTER Database Writes Succeed) ────────

  public emitOrderCreated(maQuan: number, orderId: number, data: any) {
    if (!this.io) return;
    try {
      const payload = {
        id: orderId,
        orderId,
        maDonHang: orderId,
        status: data.status || 'CHO_XAC_NHAN',
        trangThai: data.status || 'CHO_XAC_NHAN',
        updatedAt: new Date().toISOString(),
        data,
      };
      this.io.to(`restaurant:${maQuan}`).emit(REALTIME_EVENTS.ORDER_CREATED, payload);
      this.io.to('admin').emit(REALTIME_EVENTS.ORDER_CREATED, payload);
      if (data.maKhachHang) {
        this.io.to(`customer:${data.maKhachHang}`).emit(REALTIME_EVENTS.ORDER_CREATED, payload);
      }
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (order:created):', e);
    }
  }

  public emitOrderStatusChanged(maQuan: number, orderId: number, status: string, maKhachHang?: number) {
    if (!this.io) return;
    try {
      const payload = {
        id: orderId,
        orderId,
        maDonHang: orderId,
        status,
        trangThai: status,
        updatedAt: new Date().toISOString(),
      };
      this.io.to(`restaurant:${maQuan}`).emit(REALTIME_EVENTS.ORDER_STATUS_CHANGED, payload);
      this.io.to(`order:${orderId}`).emit(REALTIME_EVENTS.ORDER_STATUS_CHANGED, payload);
      this.io.to('admin').emit(REALTIME_EVENTS.ORDER_STATUS_CHANGED, payload);
      if (maKhachHang) {
        this.io.to(`customer:${maKhachHang}`).emit(REALTIME_EVENTS.ORDER_STATUS_CHANGED, payload);
      }
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (order:status_changed):', e);
    }
  }

  public emitReservationCreated(maQuan: number, reservationId: number, data: any) {
    if (!this.io) return;
    try {
      const payload = {
        id: reservationId,
        status: data.status || 'CHO_XAC_NHAN',
        updatedAt: new Date().toISOString(),
        data,
      };
      this.io.to(`restaurant:${maQuan}`).emit(REALTIME_EVENTS.RESERVATION_CREATED, payload);
      this.io.to('admin').emit(REALTIME_EVENTS.RESERVATION_CREATED, payload);
      if (data.maKhachHang) {
        this.io.to(`customer:${data.maKhachHang}`).emit(REALTIME_EVENTS.RESERVATION_CREATED, payload);
      }
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (reservation:created):', e);
    }
  }

  public emitReservationStatusChanged(maQuan: number, reservationId: number, status: string, maKhachHang?: number) {
    if (!this.io) return;
    try {
      const payload = {
        id: reservationId,
        status,
        updatedAt: new Date().toISOString(),
      };
      this.io.to(`restaurant:${maQuan}`).emit(REALTIME_EVENTS.RESERVATION_STATUS_CHANGED, payload);
      this.io.to(`reservation:${reservationId}`).emit(REALTIME_EVENTS.RESERVATION_STATUS_CHANGED, payload);
      this.io.to('admin').emit(REALTIME_EVENTS.RESERVATION_STATUS_CHANGED, payload);
      if (maKhachHang) {
        this.io.to(`customer:${maKhachHang}`).emit(REALTIME_EVENTS.RESERVATION_STATUS_CHANGED, payload);
      }
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (reservation:status_changed):', e);
    }
  }

  public emitPaymentConfirmed(maQuan: number, orderId: number, amount: number, maKhachHang?: number) {
    if (!this.io) return;
    try {
      const payload = {
        id: orderId,
        orderId,
        maDonHang: orderId,
        status: 'THANH_TOAN_THANH_CONG',
        trangThai: 'THANH_TOAN_THANH_CONG',
        amount,
        updatedAt: new Date().toISOString(),
      };
      this.io.to(`restaurant:${maQuan}`).emit(REALTIME_EVENTS.PAYMENT_CONFIRMED, payload);
      this.io.to(`order:${orderId}`).emit(REALTIME_EVENTS.PAYMENT_CONFIRMED, payload);
      this.io.to('admin').emit(REALTIME_EVENTS.PAYMENT_CONFIRMED, payload);
      if (maKhachHang) {
        this.io.to(`customer:${maKhachHang}`).emit(REALTIME_EVENTS.PAYMENT_CONFIRMED, payload);
      }
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (payment:confirmed):', e);
    }
  }

  public emitToRoom(room: string, event: string, payload: any) {
    if (!this.io) return;
    try {
      this.io.to(room).emit(event, payload);
    } catch (e) {
      console.error(`[RealtimeService] [Warn] Realtime emit error (${event} to ${room}):`, e);
    }
  }

  public emitNotification(recipientRole: string, recipientId: number, notification: any) {
    if (!this.io) return;
    try {
      const role = String(recipientRole || '').toLowerCase();
      const payload = {
        id: notification.id,
        recipientId: notification.recipientId,
        recipientRole: notification.recipientRole,
        type: notification.type,
        title: notification.title,
        body: notification.body,
        data: notification.data || {},
        isRead: Boolean(notification.isRead),
        createdAt: notification.createdAt || new Date().toISOString(),
      };

      if (role === 'admin') {
        this.io.to('admin').emit(REALTIME_EVENTS.NOTIFICATION_NEW, payload);
        if (recipientId) {
          this.io.to(`admin:${recipientId}`).emit(REALTIME_EVENTS.NOTIFICATION_NEW, payload);
          this.io.to(`account:${recipientId}`).emit(REALTIME_EVENTS.NOTIFICATION_NEW, payload);
        }
      } else if (role === 'restaurant') {
        this.io.to(`restaurant:${recipientId}`).emit(REALTIME_EVENTS.NOTIFICATION_NEW, payload);
      } else {
        // Customer / User
        this.io.to(`customer:${recipientId}`).emit(REALTIME_EVENTS.NOTIFICATION_NEW, payload);
      }
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (notification:new):', e);
    }
  }

  public emitVoucherUpdated(maQuan: number, data: any) {
    if (!this.io) return;
    try {
      const payload = {
        maQuan,
        updatedAt: new Date().toISOString(),
        ...data,
        data,
      };
      this.io.to(`restaurant:${maQuan}`).emit(REALTIME_EVENTS.VOUCHER_UPDATED, payload);
      this.io.to(`restaurant_public:${maQuan}`).emit(REALTIME_EVENTS.VOUCHER_UPDATED, payload);
      this.io.to('admin').emit(REALTIME_EVENTS.VOUCHER_UPDATED, payload);
      this.io.emit(REALTIME_EVENTS.VOUCHER_UPDATED, payload);
      console.log(`[RealtimeService] [Info] Broadcasted voucher:updated for store #${maQuan}, action: ${data?.action}`);
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (voucher:updated):', e);
    }
  }

  public emitStoreProfileUpdated(maQuan: number, store: any) {
    if (!this.io) return;
    try {
      const payload = {
        maQuan,
        updatedAt: new Date().toISOString(),
        data: store,
      };
      this.io.to(`restaurant:${maQuan}`).emit(REALTIME_EVENTS.STORE_PROFILE_UPDATED, payload);
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (restaurant:profile_updated):', e);
    }
  }

  public emitRatingUpdated(maQuan: number, payload: {
    storeId: number;
    dishIds: number[];
    storeRating: number;
    storeRatingCount: number;
    dishRatings: Array<{ dishId: number; rating: number; count: number }>;
    updatedAt: string;
  }) {
    if (!this.io) return;
    try {
      this.io.to(`restaurant:${maQuan}`).emit(REALTIME_EVENTS.RATING_UPDATED, payload);
      this.io.to(`restaurant_public:${maQuan}`).emit(REALTIME_EVENTS.RATING_UPDATED, payload);
      this.io.to('admin').emit(REALTIME_EVENTS.RATING_UPDATED, payload);
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (rating:updated):', e);
    }
  }

  public emitReviewEvent(event: string, maQuan: number, payload: any) {
    if (!this.io) return;
    try {
      this.io.to(`restaurant:${maQuan}`).emit(event, payload);
      this.io.to(`restaurant_public:${maQuan}`).emit(event, payload);
      this.io.to('admin').emit(event, payload);
    } catch (e) {
      console.error(`[RealtimeService] [Warn] Realtime emit error (${event}):`, e);
    }
  }

  public emitAboutUsUpdated(data: any) {
    if (!this.io) return;
    try {
      this.io.emit('about_us:updated', {
        updatedAt: new Date().toISOString(),
        data,
      });
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (about_us:updated):', e);
    }
  }

  public emitMenuUpdated(maQuan: number, action: 'CREATE' | 'UPDATE' | 'DELETE', food: any) {
    if (!this.io) return;
    try {
      const payload = {
        maQuan,
        action,
        food,
        updatedAt: new Date().toISOString(),
      };
      this.io.to(`restaurant:${maQuan}`).emit(REALTIME_EVENTS.MENU_UPDATED, payload);
      this.io.to(`restaurant_public:${maQuan}`).emit(REALTIME_EVENTS.MENU_UPDATED, payload);
      this.io.emit(REALTIME_EVENTS.MENU_UPDATED, payload);
      this.io.emit('dish:updated', payload);
      console.log(`[RealtimeService] [Info] Emitted menu:updated for store #${maQuan}, dish #${food?.maMonAn} (${action})`);
    } catch (e) {
      console.error('[RealtimeService] [Warn] Realtime emit error (menu:updated):', e);
    }
  }
}
