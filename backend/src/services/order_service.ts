import { In, LessThan } from 'typeorm';
import { AppDataSource } from '../config/database';
import { DonHangModel } from '../models/don_hang_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';
import { ThanhToanModel } from '../models/thanh_toan_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { MonAnModel } from '../models/mon_an_model';
import { VoucherModel } from '../models/voucher_model';
import { KhachHangVoucherModel } from '../models/khach_hang_voucher_model';
import { VoucherService } from './voucher_service';
import { RealtimeService } from './realtime_service';
import { NotificationService } from './notification_service';
import { PayOSService } from './payos_service';
import { HoanTienModel } from '../models/hoan_tien_model';

export enum OrderStatus {
  UNPAID = 'CHO_THANH_TOAN',
  PENDING = 'CHO_XAC_NHAN',
  CONFIRMED = 'DA_XAC_NHAN',
  PREPARING = 'DANG_CHUAN_BI',
  READY = 'SAN_SANG',
  COMPLETED = 'HOAN_TAT',
  CANCELLED = 'DA_HUY',
}

export function normalizeOrderStatus(statusStr: string | null | undefined): string {
  if (!statusStr) return OrderStatus.PENDING;
  const s = statusStr.trim().toUpperCase();
  if (s === 'CHO_THANH_TOAN' || s === 'UNPAID' || s === 'CHỜ THANH TOÁN') return OrderStatus.UNPAID;
  if (s === 'CHO_XAC_NHAN' || s === 'PENDING' || s === 'CHỜ XỬ LÝ' || s === 'CHỜ XÁC NHẬN') return OrderStatus.PENDING;
  if (s === 'DA_XAC_NHAN' || s === 'CONFIRMED' || s === 'ĐÃ XÁC NHẬN') return OrderStatus.CONFIRMED;
  if (s === 'DANG_CHUAN_BI' || s === 'PREPARING' || s === 'ĐANG CHUẨN BỊ' || s === 'CHƯA LÀM') return OrderStatus.PREPARING;
  if (s === 'SAN_SANG' || s === 'READY' || s === 'READY_FOR_PICKUP' || s === 'SẴN SÀNG GHÉ LẤY' || s === 'SẴN SÀNG') return OrderStatus.READY;
  if (s === 'HOAN_TAT' || s === 'HOAN_THANH' || s === 'COMPLETED' || s === 'PICKED_UP' || s === 'ĐÃ HOÀN THÀNH' || s === 'ĐÃ HOÀN TẤT' || s === 'THÀNH CÔNG') return OrderStatus.COMPLETED;
  if (s === 'DA_HUY' || s === 'CANCELLED' || s === 'ĐÃ HỦY') return OrderStatus.CANCELLED;
  return OrderStatus.PENDING;
}

export interface CreatePreOrderDto {
  items: { maMonAn: number; soLuong: number }[];
  maQuan: number;
  thoiGianHenNhan: string;
  phuongThucThanhToan?: string;
  maVoucher?: number;
  maCodeVoucher?: string;
  maKhachHang?: number;
}

export class OrderService {
  private donHangRepo = AppDataSource.getRepository(DonHangModel);
  private chiTietDonRepo = AppDataSource.getRepository(ChiTietDonHangModel);
  private thanhToanRepo = AppDataSource.getRepository(ThanhToanModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private foodRepo = AppDataSource.getRepository(MonAnModel);
  private voucherService = new VoucherService();

  async createPreOrder(dto: CreatePreOrderDto, userSub?: number) {
    if (!dto.items || dto.items.length === 0) {
      throw new Error('Đơn hàng phải chứa ít nhất 1 món ăn');
    }

    if (!userSub || isNaN(userSub)) {
      throw new Error('Thông tin người dùng không hợp lệ');
    }

    const khachHang = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
    if (!khachHang) {
      throw new Error('Tài khoản hiện tại chưa khởi tạo thông tin khách hàng');
    }
    const validKhachHangId = khachHang.maKhachHang;

    const store = await this.storeRepo.findOne({ where: { maQuan: dto.maQuan } });
    if (!store) {
      throw new Error('Nhà hàng không tồn tại');
    }

    const st = String(store.trangThai || '').toLowerCase().trim();
    if (st === 'ngưng kinh doanh' || st === 'đóng cửa') {
      throw new Error(`Cửa hàng "${store.tenQuan}" hiện đang đóng cửa hoặc tạm ngưng nhận đơn!`);
    }

    // BIZ-03 Hardening: Prevent online bank transfer if store has not configured receiving bank account
    const requestedPaymentMethod = (dto.phuongThucThanhToan || 'PAYOS').toUpperCase().trim();
    const isOnlinePayment = requestedPaymentMethod === 'PAYOS' || requestedPaymentMethod === 'VIETQR';
    if (isOnlinePayment) {
      const bankId = (store.tenNganHang || '').trim();
      const accountNo = (store.soTaiKhoanNganHang || '').trim();
      if (!bankId || !accountNo) {
        throw new Error(
          `Nhà hàng "${store.tenQuan}" chưa thiết lập tài khoản ngân hàng nhận tiền. Vui lòng liên hệ nhà hàng để cập nhật thông tin nhận tiền.`
        );
      }
    }

    const pickupDate = new Date(dto.thoiGianHenNhan);
    if (isNaN(pickupDate.getTime())) {
      throw new Error('Thời gian hẹn lấy không hợp lệ');
    }

    const now = new Date();
    if (pickupDate.getTime() < now.getTime() - 60000) {
      throw new Error('Thời gian hẹn nhận phải là thời gian trong tương lai');
    }

    const foodIds = dto.items.map((i) => i.maMonAn);
    const dbFoods = await this.foodRepo.find({ where: { maMonAn: In(foodIds) } });
    const foodMap = new Map<number, MonAnModel>();
    for (const f of dbFoods) foodMap.set(f.maMonAn, f);

    let itemsSubTotal = 0;
    const validatedItems: { maMonAn: number; tenMonAn: string; gia: number; soLuong: number }[] = [];

    for (const item of dto.items) {
      const dbFood = foodMap.get(item.maMonAn);
      if (!dbFood) {
        throw new Error(`Món ăn #${item.maMonAn} không tồn tại`);
      }
      if (dbFood.maQuan !== dto.maQuan) {
        throw new Error(`Món ăn "${dbFood.tenMonAn}" không thuộc nhà hàng đã chọn`);
      }
      if (dbFood.trangThaiMon === 'HET_HANG' || dbFood.trangThaiMon === 'TAM_NGUNG') {
        throw new Error(`Món ăn "${dbFood.tenMonAn}" hiện đang tạm hết hàng`);
      }

      const realPrice = Number(dbFood.giaMonAn);
      const qty = Math.max(1, Number(item.soLuong) || 1);

      const currentStock = dbFood.soLuongMon !== null && dbFood.soLuongMon !== undefined ? Number(dbFood.soLuongMon) : 100;
      if (currentStock < qty) {
        throw new Error(`Món ăn "${dbFood.tenMonAn}" chỉ còn ${currentStock} phần, không đủ số lượng đặt (${qty})`);
      }

      itemsSubTotal += realPrice * qty;

      validatedItems.push({
        maMonAn: dbFood.maMonAn,
        tenMonAn: dbFood.tenMonAn,
        gia: realPrice,
        soLuong: qty,
      });
    }

    const { savedOrder, itemEntities, thanhToan, finalTotal } = await AppDataSource.transaction(async (manager) => {
      let finalTotal = itemsSubTotal;
      let appliedVoucherId = dto.maVoucher;

      if (dto.maCodeVoucher && dto.maCodeVoucher.trim()) {
        try {
          const voucherRes = await this.voucherService.applyAndIncrementVoucherUsageInTransaction(
            manager,
            dto.maCodeVoucher,
            dto.maQuan,
            itemsSubTotal,
            validKhachHangId
          );
          appliedVoucherId = voucherRes.maVoucher;
          finalTotal = Math.max(itemsSubTotal - voucherRes.discountAmount, 0);
        } catch (err: any) {
          throw new Error(`Lỗi áp dụng Voucher: ${err.message}`);
        }
      }

      const method = (dto.phuongThucThanhToan || 'PAYOS').toUpperCase();
      const isOnlineMethod = method === 'PAYOS' || method === 'VIETQR' || method === 'MOMO' || method === 'VNPAY';
      const initialStatus = isOnlineMethod ? OrderStatus.UNPAID : OrderStatus.PENDING;

      const donHang = manager.create(DonHangModel, {
        maKhachHang: validKhachHangId,
        maQuan: dto.maQuan,
        maVoucher: appliedVoucherId,
        trangThai: initialStatus,
        tongTien: finalTotal,
        thoiGianHenNhan: pickupDate,
        loaiDonHang: 'PRE_ORDER',
        phuongThucThanhToan: dto.phuongThucThanhToan || 'PAYOS',
      });

      const savedOrder = await manager.save(donHang);

      const itemEntities = validatedItems.map((item) =>
        manager.create(ChiTietDonHangModel, {
          maDonHang: savedOrder.maDonHang,
          maMonAn: item.maMonAn,
          tenMonAn: item.tenMonAn,
          gia: item.gia,
          soLuong: item.soLuong,
          trangThaiMon: 'chưa làm',
        })
      );

      await manager.save(itemEntities);

      const thanhToan = manager.create(ThanhToanModel, {
        maDonHang: savedOrder.maDonHang,
        soTien: finalTotal,
        trangThai: 'CHO_THANH_TOAN',
        loaiThanhToan: dto.phuongThucThanhToan || 'PAYOS',
        noiDung: `Khởi tạo thanh toán cho đơn pre-order #${savedOrder.maDonHang}`,
      });

      await manager.save(thanhToan);

      // Gom số lượng cần trừ theo maMonAn và sắp xếp tăng dần theo ID để loại trừ hoàn toàn nguy cơ Deadlock giữa các transaction
      const itemQtyMap = new Map<number, { maMonAn: number; tenMonAn: string; totalQty: number }>();
      for (const item of validatedItems) {
        const existing = itemQtyMap.get(item.maMonAn);
        if (existing) {
          existing.totalQty += item.soLuong;
        } else {
          itemQtyMap.set(item.maMonAn, {
            maMonAn: item.maMonAn,
            tenMonAn: item.tenMonAn,
            totalQty: item.soLuong,
          });
        }
      }

      // Sắp xếp ID món tăng dần trước khi lock (pessimistic_write) trong cùng một transaction
      const sortedItemsForLock = Array.from(itemQtyMap.values()).sort((a, b) => a.maMonAn - b.maMonAn);

      // Trừ số lượng món ăn (soLuongMon) có khóa ghi pessimistic_write theo thứ tự ID đã sắp xếp
      for (const item of sortedItemsForLock) {
        const dbFood = await manager.findOne(MonAnModel, {
          where: { maMonAn: item.maMonAn },
          lock: { mode: 'pessimistic_write' },
        });

        if (dbFood) {
          const currentStock = dbFood.soLuongMon !== null && dbFood.soLuongMon !== undefined ? Number(dbFood.soLuongMon) : 100;
          if (currentStock < item.totalQty) {
            throw new Error(`Món ăn "${dbFood.tenMonAn}" chỉ còn ${currentStock} phần, không đủ số lượng đặt (${item.totalQty})`);
          }
          const newStock = Math.max(0, currentStock - item.totalQty);
          dbFood.soLuongMon = newStock;
          if (newStock === 0) {
            dbFood.trangThaiMon = 'HET_HANG';
          }
          await manager.save(dbFood);
        }
      }

      return { savedOrder, itemEntities, thanhToan, finalTotal };
    });

    const isOnline =
      (savedOrder.phuongThucThanhToan || '').toUpperCase() === 'PAYOS' ||
      (savedOrder.phuongThucThanhToan || '').toUpperCase() === 'VIETQR' ||
      (savedOrder.phuongThucThanhToan || '').toUpperCase() === 'MOMO' ||
      (savedOrder.phuongThucThanhToan || '').toUpperCase() === 'VNPAY';

    // Only emit order:created to restaurant immediately for non-online methods (e.g. COD)
    // For online payments, order:created will be emitted after payment verification succeeds
    if (!isOnline) {
      RealtimeService.getInstance().emitOrderCreated(savedOrder.maQuan, savedOrder.maDonHang, {
        maDonHang: savedOrder.maDonHang,
        maKhachHang: savedOrder.maKhachHang,
        tongTien: savedOrder.tongTien,
        thoiGianHenNhan: savedOrder.thoiGianHenNhan,
        itemsCount: validatedItems.length,
        status: savedOrder.trangThai,
      });

      // Persist & Emit Notifications for New Order
      try {
        if (savedOrder.maQuan) {
          await NotificationService.getInstance().sendNotification({
            recipientId: savedOrder.maQuan,
            recipientRole: 'restaurant',
            type: 'order:created',
            title: 'Đơn hàng mới',
            body: `Đơn hàng mới #DH-${savedOrder.maDonHang} (${validatedItems.length} món). Tổng tiền: ${Number(savedOrder.tongTien).toLocaleString('vi-VN')}đ.`,
            data: { orderId: savedOrder.maDonHang, maQuan: savedOrder.maQuan, status: savedOrder.trangThai },
          });
        }

        await NotificationService.getInstance().sendNotification({
          recipientId: 0,
          recipientRole: 'admin',
          type: 'order:created',
          title: 'Đơn hàng mới trên hệ thống',
          body: `Đơn hàng mới #DH-${savedOrder.maDonHang} vừa được tạo tại quán ID ${savedOrder.maQuan}.`,
          data: { orderId: savedOrder.maDonHang, maQuan: savedOrder.maQuan },
        });
      } catch (notifErr) {
        console.error('[OrderService] Failed to send order:created notification:', notifErr);
      }
    }

    if (savedOrder.maVoucher && savedOrder.maQuan) {
      RealtimeService.getInstance().emitVoucherUpdated(savedOrder.maQuan, {
        maVoucher: savedOrder.maVoucher,
        orderId: savedOrder.maDonHang,
        action: 'USED',
      });
    }

    let paymentData: any = null;
    if (isOnline && thanhToan) {
      // 1. Tạo Payment Link chính thức từ PayOS để nhận Webhook TỨC THÌ (1-2s)
      const payosResult = await PayOSService.createPaymentLink({
        orderCode: savedOrder.maDonHang,
        amount: finalTotal,
        description: `DH${savedOrder.maDonHang}`,
      });

      if (payosResult) {
        const transferContent = payosResult.description;
        // Sử dụng QR chuẩn từ PayOS
        const qrUrl = `https://img.vietqr.io/image/${payosResult.bin}-${payosResult.accountNumber}-compact2.png?amount=${Math.round(finalTotal)}&addInfo=${encodeURIComponent(transferContent)}&accountName=${encodeURIComponent(payosResult.accountName)}`;

        paymentData = {
          maThanhToan: thanhToan.maThanhToan,
          loaiThanhToan: savedOrder.phuongThucThanhToan,
          soTien: finalTotal,
          trangThai: thanhToan.trangThai,
          bankName: payosResult.bin,
          accountNumber: payosResult.accountNumber,
          accountName: payosResult.accountName,
          transferContent,
          qrUrl,
        };
      } else {
        // Fallback tài khoản ngân hàng của quán nếu PayOS gặp lỗi
        const rawBank = (store.tenNganHang || '').trim();
        const match = rawBank.match(/\(([^)]+)\)/);
        const bankId = match ? match[1].trim() : rawBank;
        const accountNo = (store.soTaiKhoanNganHang || '').trim();
        const accountName = (store.tenChuTaiKhoan || store.tenQuan || '').trim();

        if (bankId && accountNo) {
          const transferContent = `DH${savedOrder.maDonHang}`;
          const qrUrl = `https://img.vietqr.io/image/${bankId}-${accountNo}-compact2.png?amount=${Math.round(finalTotal)}&addInfo=${encodeURIComponent(transferContent)}&accountName=${encodeURIComponent(accountName)}`;

          paymentData = {
            maThanhToan: thanhToan.maThanhToan,
            loaiThanhToan: savedOrder.phuongThucThanhToan,
            soTien: finalTotal,
            trangThai: thanhToan.trangThai,
            bankName: bankId,
            accountNumber: accountNo,
            accountName: accountName,
            transferContent,
            qrUrl,
          };
        }
      }
    }

    return {
      orderId: savedOrder.maDonHang,
      maDonHang: savedOrder.maDonHang,
      restaurantId: store.maQuan,
      restaurantName: store.tenQuan,
      tenQuan: store.tenQuan,
      restaurantAddress: store.diaChi,
      diaChi: store.diaChi,
      lat: store.lat ? Number(store.lat) : undefined,
      lng: store.lng ? Number(store.lng) : undefined,
      restaurantPhone: store.sdt || '',
      sdt: store.sdt || '',
      status: savedOrder.trangThai,
      trangThai: savedOrder.trangThai,
      tongTien: savedOrder.tongTien,
      phuongThucThanhToan: savedOrder.phuongThucThanhToan,
      thoiGianHenNhan: savedOrder.thoiGianHenNhan,
      items: itemEntities.map((item) => ({
        maMonAn: item.maMonAn,
        tenMonAn: item.tenMonAn,
        soLuong: item.soLuong,
        gia: Number(item.gia),
        img: foodMap.get(item.maMonAn)?.img || '',
        image: foodMap.get(item.maMonAn)?.img || '',
      })),
      payment: paymentData,
    };
  }

  async getMyOrders(maKhachHang: number) {
    if (!maKhachHang || isNaN(maKhachHang)) return [];

    // Tự động hủy đơn hàng chờ thanh toán quá hạn 15 phút (tránh treo đơn rác)
    try {
      const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
      const expiredUnpaidOrders = await this.donHangRepo.find({
        where: {
          maKhachHang,
          trangThai: In(['CHO_THANH_TOAN', 'UNPAID', 'chờ thanh toán']),
          thoiGianDat: LessThan(fifteenMinutesAgo),
        },
      });

      for (const expOrder of expiredUnpaidOrders) {
        expOrder.trangThai = 'DA_HUY';
        expOrder.lyDoHuy = 'Hết thời gian chờ thanh toán (Quá 15 phút)';
        await this.donHangRepo.save(expOrder);
        await this.rollbackInventoryAndVoucher(expOrder.maDonHang);
      }
    } catch (e) {
      console.warn('[OrderService] Auto-cancel expired orders warning:', e);
    }


    const orders = await this.donHangRepo.find({
      where: { maKhachHang },
      order: { thoiGianDat: 'DESC' },
    });

    if (orders.length === 0) return [];

    // Batch load items
    const orderIds = orders.map((o) => o.maDonHang);
    const allItems = await this.chiTietDonRepo.find({
      where: { maDonHang: In(orderIds) },
    });

    const itemsByOrder = new Map<number, ChiTietDonHangModel[]>();
    for (const item of allItems) {
      if (!itemsByOrder.has(item.maDonHang)) {
        itemsByOrder.set(item.maDonHang, []);
      }
      itemsByOrder.get(item.maDonHang)!.push(item);
    }

    // Batch load restaurant info
    const restaurantIds = [...new Set(orders.map((o) => o.maQuan).filter(Boolean) as number[])];
    const restaurants = restaurantIds.length > 0
      ? await this.storeRepo.find({ where: { maQuan: In(restaurantIds) } })
      : [];
    const restaurantMap = new Map<number, CuaHangModel>();
    for (const r of restaurants) restaurantMap.set(r.maQuan, r);

    // Batch load refunds
    const hoanTienRepo = AppDataSource.getRepository(HoanTienModel);
    const refunds = await hoanTienRepo.find({ where: { maDonHang: In(orderIds) } });
    const refundMap = new Map<number, HoanTienModel>();
    for (const rf of refunds) refundMap.set(rf.maDonHang, rf);

    // Batch load food items to include images
    const allFoodIds = [...new Set(allItems.map((i) => i.maMonAn).filter(Boolean) as number[])];
    const foods = allFoodIds.length > 0
      ? await this.foodRepo.find({ where: { maMonAn: In(allFoodIds) } })
      : [];
    const foodMap = new Map<number, MonAnModel>();
    for (const f of foods) foodMap.set(f.maMonAn, f);

    return orders.map((order) => {
      const cuaHang = order.maQuan ? restaurantMap.get(order.maQuan) : undefined;
      const ref = refundMap.get(order.maDonHang);

      return {
        maDonHang: order.maDonHang,
        maQuan: order.maQuan,
        trangThai: order.trangThai,
        tongTien: order.tongTien,
        thoiGianHenNhan: order.thoiGianHenNhan,
        thoiGianDat: order.thoiGianDat,
        loaiDonHang: order.loaiDonHang,
        phuongThucThanhToan: order.phuongThucThanhToan,
        lyDoHuy: order.lyDoHuy,
        tenQuan: cuaHang?.tenQuan ?? 'Nhà hàng lộ trình',
        diaChi: cuaHang?.diaChi ?? 'Địa chỉ tự đến lấy',
        lat: cuaHang?.lat ? Number(cuaHang.lat) : undefined,
        lng: cuaHang?.lng ? Number(cuaHang.lng) : undefined,
        sdt: cuaHang?.sdt || undefined,
        refund: ref || null,
        refundStatus: ref?.trangThaiHoanTien || null,
        refundAmount: ref?.soTienHoan ? Number(ref.soTienHoan) : null,
        items: (itemsByOrder.get(order.maDonHang) || []).map((item) => {
          const food = foodMap.get(item.maMonAn);
          return {
            maMonAn: item.maMonAn,
            tenMonAn: item.tenMonAn,
            soLuong: item.soLuong,
            gia: Number(item.gia),
            img: food?.img || '',
            image: food?.img || '',
            hinhAnh: food?.img || '',
          };
        }),
      };
    });
  }

  async getOrderById(maDonHang: number) {
    if (!maDonHang || isNaN(maDonHang)) return null;

    const order = await this.donHangRepo.findOne({ where: { maDonHang } });
    if (!order) return null;

    const items = await this.chiTietDonRepo.find({ where: { maDonHang } });

    const cuaHang = order.maQuan
      ? await this.storeRepo.findOne({ where: { maQuan: order.maQuan } })
      : null;

    const foodIds = [...new Set(items.map((i) => i.maMonAn).filter(Boolean) as number[])];
    const foods = foodIds.length > 0
      ? await this.foodRepo.find({ where: { maMonAn: In(foodIds) } })
      : [];
    const foodMap = new Map<number, MonAnModel>();
    for (const f of foods) foodMap.set(f.maMonAn, f);

    return {
      ...order,
      tenQuan: cuaHang?.tenQuan ?? 'Nhà hàng lộ trình',
      diaChi: cuaHang?.diaChi ?? 'Địa chỉ tự đến lấy',
      lat: cuaHang?.lat ? Number(cuaHang.lat) : undefined,
      lng: cuaHang?.lng ? Number(cuaHang.lng) : undefined,
      sdt: cuaHang?.sdt || undefined,
      items: items.map((item) => {
        const food = foodMap.get(item.maMonAn);
        return {
          maMonAn: item.maMonAn,
          tenMonAn: item.tenMonAn,
          soLuong: item.soLuong,
          gia: Number(item.gia),
          img: food?.img || '',
          image: food?.img || '',
          hinhAnh: food?.img || '',
        };
      }),
    };
  }

  async updateOrderStatus(maDonHang: number, status: string, lyDo?: string, updatedBy?: string) {
    const order = await this.donHangRepo.findOne({
      where: { maDonHang },
    });
    if (!order) throw new Error('Đơn hàng không tồn tại');

    const prevStatus = order.trangThai;
    const normalized = normalizeOrderStatus(status);

    // Prevent duplicate notification emission if status didn't change
    if (prevStatus === normalized) {
      return order;
    }

    order.trangThai = normalized;
    if (lyDo) {
      order.lyDoHuy = lyDo;
    } else if (normalized === 'DA_HUY' && !order.lyDoHuy) {
      order.lyDoHuy = updatedBy === 'user' ? 'Khách hàng hủy đơn' : 'Quán hủy đơn';
    }
    const saved = await this.donHangRepo.save(order);

    // Rollback food stock and voucher when order is cancelled
    if (normalized === 'DA_HUY' && prevStatus !== 'DA_HUY') {
      await this.rollbackInventoryAndVoucher(maDonHang);
    }

    RealtimeService.getInstance().emitOrderStatusChanged(
      saved.maQuan,
      saved.maDonHang,
      saved.trangThai,
      saved.maKhachHang,
    );

    // Persist & Emit Notifications based on status
    try {
      const store = saved.maQuan ? await this.storeRepo.findOne({ where: { maQuan: saved.maQuan } }) : null;
      const tenQuan = store?.tenQuan || 'Nhà hàng';

      if (normalized === 'DA_XAC_NHAN' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'order:confirmed',
          title: 'Đơn hàng đã được xác nhận',
          body: `${tenQuan} đã xác nhận đơn hàng #DH-${saved.maDonHang}. Quán đang tiến hành chuẩn bị.`,
          data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalized },
        });
      } else if (normalized === 'DANG_CHUAN_BI' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'order:preparing',
          title: 'Đang chuẩn bị món',
          body: `${tenQuan} đang chuẩn bị món ăn cho đơn hàng #DH-${saved.maDonHang}.`,
          data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalized },
        });
      } else if (normalized === 'SAN_SANG' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'order:ready',
          title: 'Món ăn đã sẵn sàng',
          body: `Đơn hàng #DH-${saved.maDonHang} đã sẵn sàng! Mời bạn đến ${tenQuan} để nhận món.`,
          data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalized },
        });
      } else if (normalized === 'HOAN_TAT' && saved.maKhachHang) {
        await NotificationService.getInstance().sendNotification({
          recipientId: saved.maKhachHang,
          recipientRole: 'user',
          type: 'order:completed',
          title: 'Đơn hàng hoàn tất',
          body: `Đơn hàng #DH-${saved.maDonHang} đã hoàn tất. Cảm ơn bạn đã ủng hộ ${tenQuan}!`,
          data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalized },
        });
      } else if (normalized === 'DA_HUY') {
        if (updatedBy === 'user' && saved.maQuan) {
          // Khách hủy đơn -> Báo nhà hàng
          await NotificationService.getInstance().sendNotification({
            recipientId: saved.maQuan,
            recipientRole: 'restaurant',
            type: 'order:cancelled',
            title: 'Khách hàng hủy đơn',
            body: `Khách hàng đã hủy đơn hàng #DH-${saved.maDonHang}.${lyDo ? ` Lý do: ${lyDo}` : ''}`,
            data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalized },
          });
        } else if (saved.maKhachHang) {
          // Nhà hàng từ chối/hủy -> Báo khách hàng
          await NotificationService.getInstance().sendNotification({
            recipientId: saved.maKhachHang,
            recipientRole: 'user',
            type: 'order:rejected',
            title: 'Đơn hàng đã bị hủy / từ chối',
            body: `${tenQuan} đã từ chối/hủy đơn hàng #DH-${saved.maDonHang}.${lyDo ? ` Lý do: ${lyDo}` : ''}`,
            data: { orderId: saved.maDonHang, maQuan: saved.maQuan, status: normalized, lyDo },
          });
        }
      }
    } catch (notifErr) {
      console.error('[OrderService] Failed to send status notification:', notifErr);
    }

    return saved;
  }

  async rollbackInventoryAndVoucher(maDonHang: number) {
    const order = await this.donHangRepo.findOne({ where: { maDonHang } });
    if (!order) return;

    try {
      const orderItems = await this.chiTietDonRepo.find({ where: { maDonHang } });
      for (const item of orderItems) {
        if (item.maMonAn) {
          const dbFood = await this.foodRepo.findOne({ where: { maMonAn: item.maMonAn } });
          if (dbFood) {
            const currentStock =
              dbFood.soLuongMon !== null && dbFood.soLuongMon !== undefined
                ? Number(dbFood.soLuongMon)
                : 0;
            dbFood.soLuongMon = currentStock + Number(item.soLuong || 1);
            if (dbFood.trangThaiMon === 'HET_HANG') {
              dbFood.trangThaiMon = 'DANG_BAN';
            }
            await this.foodRepo.save(dbFood);
          }
        }
      }

      if (order.maVoucher) {
        const voucherRepo = AppDataSource.getRepository(VoucherModel);
        const v = await voucherRepo.findOne({ where: { maVoucher: order.maVoucher } });
        if (order.maKhachHang) {
          const khVoucherRepo = AppDataSource.getRepository(KhachHangVoucherModel);
          const khVoucher = await khVoucherRepo.findOne({
            where: { maKhachHang: order.maKhachHang, maVoucher: order.maVoucher },
          });
          // Idempotency check: only refund if customer voucher is currently marked as used
          if (khVoucher && khVoucher.daSuDung) {
            khVoucher.daSuDung = false;
            await khVoucherRepo.save(khVoucher);

            if (v && Number(v.soLuongDaSuDung || 0) > 0) {
              v.soLuongDaSuDung = Number(v.soLuongDaSuDung) - 1;
              await voucherRepo.save(v);
            }
          }
        } else if (v && Number(v.soLuongDaSuDung || 0) > 0) {
          v.soLuongDaSuDung = Number(v.soLuongDaSuDung) - 1;
          await voucherRepo.save(v);
        }
      }
    } catch (rollbackErr) {
      console.error('[OrderService] Error during inventory/voucher rollback:', rollbackErr);
    }
  }
}
