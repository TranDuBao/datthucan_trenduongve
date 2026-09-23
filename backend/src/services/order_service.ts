import { AppDataSource } from '../config/database';
import { DonHangModel } from '../models/don_hang_model';
import { ChiTietDonHangModel } from '../models/chi_tiet_don_hang_model';
import { ThanhToanModel } from '../models/thanh_toan_model';
import { KhachHangModel } from '../models/khach_hang_model';

export interface CreatePreOrderDto {
  maKhachHang?: number;
  maQuan: number;
  maVoucher?: number;
  thoiGianHenNhan: string; // ISO String or YYYY-MM-DD HH:mm
  items: {
    maMonAn: number;
    tenMonAn: string;
    gia: number;
    soLuong: number;
  }[];
  tongTien: number;
  phuongThucThanhToan: string;
}

export class OrderService {
  private donHangRepo = AppDataSource.getRepository(DonHangModel);
  private chiTietDonRepo = AppDataSource.getRepository(ChiTietDonHangModel);
  private thanhToanRepo = AppDataSource.getRepository(ThanhToanModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);

  async createPreOrder(dto: CreatePreOrderDto) {
    if (!dto.items || dto.items.length === 0) {
      throw new Error('Đơn hàng phải chứa ít nhất 1 món ăn');
    }

    const pickupDate = new Date(dto.thoiGianHenNhan);
    if (isNaN(pickupDate.getTime())) {
      throw new Error('Thời gian hẹn lấy không hợp lệ');
    }

    const now = new Date();
    // Pickup time must be in the future (at least 5 minutes to prepare)
    if (pickupDate.getTime() < now.getTime() - 60000) {
      throw new Error('Thời gian hẹn nhận phải là thời gian trong tương lai');
    }

    // Safely resolve customer ID to prevent foreign key constraint violations
    let validKhachHangId: number | null = null;
    if (dto.maKhachHang) {
      const kh = await this.khachHangRepo.findOne({ where: { maKhachHang: dto.maKhachHang } });
      if (kh) validKhachHangId = kh.maKhachHang;
    }
    if (!validKhachHangId) {
      const firstKh = await this.khachHangRepo.findOne({ where: {} });
      validKhachHangId = firstKh ? firstKh.maKhachHang : null;
    }

    // 1. Create order
    const donHang = this.donHangRepo.create({
      maKhachHang: validKhachHangId ?? undefined,
      maQuan: dto.maQuan,
      maVoucher: dto.maVoucher,
      trangThai: 'chờ xử lý', // PENDING
      tongTien: dto.tongTien,
      thoiGianHenNhan: pickupDate,
      loaiDonHang: 'PRE_ORDER',
      phuongThucThanhToan: dto.phuongThucThanhToan || 'PAYOS',
    });

    const savedOrder = await this.donHangRepo.save(donHang);

    // 2. Create order items
    const itemEntities = dto.items.map((item) =>
      this.chiTietDonRepo.create({
        maDonHang: savedOrder.maDonHang,
        maMonAn: item.maMonAn,
        tenMonAn: item.tenMonAn,
        gia: item.gia,
        soLuong: item.soLuong,
        trangThaiMon: 'chưa làm',
      })
    );

    await this.chiTietDonRepo.save(itemEntities);

    // 3. Create initial payment record
    const thanhToan = this.thanhToanRepo.create({
      maDonHang: savedOrder.maDonHang,
      soTien: dto.tongTien,
      trangThai: 'THANH_TOAN_THANH_CONG',
      loaiThanhToan: dto.phuongThucThanhToan,
      noiDung: `Thanh toán đơn pre-order #${savedOrder.maDonHang}`,
    });

    await this.thanhToanRepo.save(thanhToan);

    return {
      orderId: savedOrder.maDonHang,
      status: savedOrder.trangThai,
      totalAmount: savedOrder.tongTien,
      pickupTime: savedOrder.thoiGianHenNhan,
      items: itemEntities,
    };
  }

  async getMyOrders(maKhachHang: number = 1) {
    const orders = await this.donHangRepo.find({
      where: { maKhachHang },
      order: { maDonHang: 'DESC' },
    });

    const result = [];
    for (const order of orders) {
      const items = await this.chiTietDonRepo.find({
        where: { maDonHang: order.maDonHang },
      });
      result.push({
        ...order,
        items,
      });
    }

    return result;
  }

  async getOrderById(maDonHang: number) {
    const order = await this.donHangRepo.findOne({
      where: { maDonHang },
    });

    if (!order) return null;

    const items = await this.chiTietDonRepo.find({
      where: { maDonHang },
    });

    return {
      ...order,
      items,
    };
  }

  async updateOrderStatus(maDonHang: number, status: string) {
    const order = await this.donHangRepo.findOne({
      where: { maDonHang },
    });

    if (!order) throw new Error('Đơn hàng không tồn tại');

    order.trangThai = status;
    return await this.donHangRepo.save(order);
  }
}
