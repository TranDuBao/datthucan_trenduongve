import { AppDataSource } from '../config/database';
import { VoucherModel } from '../models/voucher_model';
import { KhachHangVoucherModel } from '../models/khach_hang_voucher_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { RealtimeService } from './realtime_service';

export interface CreateVoucherInput {
  maCode: string;
  tenVoucher: string;
  moTa?: string;
  giamGia: number;
  loaiGiam?: string; // 'VND' | 'PERCENT'
  giaTriGiamToiDa?: number;
  dieuKienDonToiThieu?: number;
  ngayBatDau?: string | Date;
  ngayHetHan?: string | Date;
  soLuongToiDa?: number;
  trangThai?: string; // 'HOAT_DONG' | 'TAM_TAT'
}

export interface UpdateVoucherInput {
  tenVoucher?: string;
  moTa?: string;
  giamGia?: number;
  loaiGiam?: string;
  giaTriGiamToiDa?: number;
  dieuKienDonToiThieu?: number;
  ngayBatDau?: string | Date;
  ngayHetHan?: string | Date;
  soLuongToiDa?: number;
  trangThai?: string;
}

export class VoucherService {
  private voucherRepo = AppDataSource.getRepository(VoucherModel);
  private khachHangRepo = AppDataSource.getRepository(KhachHangModel);
  private khachHangVoucherRepo = AppDataSource.getRepository(KhachHangVoucherModel);

  /**
   * Tính toán trạng thái động thực tế của Voucher
   */
  public computeVoucherStatus(v: VoucherModel): string {
    if (v.trangThai === 'TAM_TAT') return 'TAM_TAT';

    const now = new Date();
    const startDate = v.ngayBatDau ? new Date(v.ngayBatDau) : null;
    const endDate = v.ngayHetHan ? new Date(v.ngayHetHan) : null;

    if (startDate && startDate > now) return 'SAP_DIEN_RA';
    if (endDate && endDate < now) return 'HET_HAN';
    if (v.soLuongToiDa > 0 && (v.soLuongDaSuDung || 0) >= v.soLuongToiDa) return 'HET_LUOT';

    return 'DANG_HOAT_DONG';
  }

  /**
   * Lấy danh sách voucher thuộc quyền sở hữu của Store (maQuan)
   */
  async getStoreVouchers(maQuan: number, statusFilter?: string, searchQuery?: string) {
    const rawVouchers = await this.voucherRepo.find({
      where: { maQuan },
      order: { ngayTao: 'DESC' },
    });

    const now = new Date();
    const sevenDaysLater = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    let activeCount = 0;
    let totalUsed = 0;
    let expiringSoonCount = 0;

    const enrichedList = rawVouchers.map((v) => {
      const computedStatus = this.computeVoucherStatus(v);
      const usedCount = Number(v.soLuongDaSuDung || 0);
      const totalLimit = Number(v.soLuongToiDa || 0);

      if (computedStatus === 'DANG_HOAT_DONG') activeCount++;
      totalUsed += usedCount;

      const endDate = v.ngayHetHan ? new Date(v.ngayHetHan) : null;
      if (endDate && endDate > now && endDate <= sevenDaysLater && computedStatus === 'DANG_HOAT_DONG') {
        expiringSoonCount++;
      }

      return {
        ...v,
        giamGia: Number(v.giamGia),
        giaTriGiamToiDa: v.giaTriGiamToiDa ? Number(v.giaTriGiamToiDa) : null,
        dieuKienDonToiThieu: Number(v.dieuKienDonToiThieu || 0),
        soLuongToiDa: totalLimit,
        soLuongDaLuu: Number(v.soLuongDaLuu || 0),
        soLuongDaSuDung: usedCount,
        computedStatus,
      };
    });

    // Filtering
    let filtered = enrichedList;

    if (searchQuery && searchQuery.trim()) {
      const q = searchQuery.trim().toLowerCase();
      filtered = filtered.filter(
        (v) => v.maCode.toLowerCase().includes(q) || v.tenVoucher.toLowerCase().includes(q)
      );
    }

    if (statusFilter && statusFilter.toUpperCase() !== 'ALL') {
      const targetStatus = statusFilter.toUpperCase();
      filtered = filtered.filter((v) => v.computedStatus === targetStatus);
    }

    return {
      summary: {
        totalVouchers: rawVouchers.length,
        activeVouchers: activeCount,
        totalUsedCount: totalUsed,
        expiringSoonCount,
      },
      vouchers: filtered,
    };
  }

  /**
   * Lấy chi tiết voucher
   */
  async getVoucherById(maQuan: number, maVoucher: number) {
    const v = await this.voucherRepo.findOne({
      where: { maVoucher, maQuan },
    });

    if (!v) {
      throw new Error('Không tìm thấy voucher hoặc bạn không có quyền truy cập');
    }

    return {
      ...v,
      giamGia: Number(v.giamGia),
      giaTriGiamToiDa: v.giaTriGiamToiDa ? Number(v.giaTriGiamToiDa) : null,
      dieuKienDonToiThieu: Number(v.dieuKienDonToiThieu || 0),
      computedStatus: this.computeVoucherStatus(v),
    };
  }

  /**
   * Tạo Voucher mới
   */
  async createVoucher(maQuan: number, input: CreateVoucherInput) {
    const rawCode = (input.maCode || '').trim().toUpperCase();
    if (!rawCode) throw new Error('Mã voucher không được để trống');
    if (rawCode.length < 3 || rawCode.length > 50) throw new Error('Mã voucher từ 3 đến 50 ký tự');
    if (!/^[A-Z0-9_-]+$/.test(rawCode)) throw new Error('Mã voucher chỉ chứa chữ cái, số, gạch ngang (-) hoặc gạch dưới (_)');

    const existingCode = await this.voucherRepo.findOne({ where: { maCode: rawCode } });
    if (existingCode) {
      throw new Error(`Mã voucher '${rawCode}' đã tồn tại trên hệ thống`);
    }

    const tenVoucher = (input.tenVoucher || '').trim();
    if (!tenVoucher) throw new Error('Tên voucher không được để trống');

    const giamGia = Number(input.giamGia);
    if (isNaN(giamGia) || giamGia <= 0) throw new Error('Giá trị giảm phải lớn hơn 0');

    const loaiGiam = (input.loaiGiam || 'VND').toUpperCase();
    if (loaiGiam === 'PERCENT' && (giamGia <= 0 || giamGia > 100)) {
      throw new Error('Phần trăm giảm phải lớn hơn 0 và nhỏ hơn hoặc bằng 100%');
    }

    const giaTriGiamToiDa = input.giaTriGiamToiDa ? Number(input.giaTriGiamToiDa) : undefined;
    if (giaTriGiamToiDa !== undefined && giaTriGiamToiDa <= 0) {
      throw new Error('Giá trị giảm tối đa phải lớn hơn 0');
    }

    const dieuKienDonToiThieu = Math.max(Number(input.dieuKienDonToiThieu || 0), 0);
    const soLuongToiDa = Math.max(Number(input.soLuongToiDa || 0), 0);

    const ngayBatDau = input.ngayBatDau ? new Date(input.ngayBatDau) : new Date();
    const ngayHetHan = input.ngayHetHan ? new Date(input.ngayHetHan) : undefined;

    if (ngayHetHan && ngayHetHan <= ngayBatDau) {
      throw new Error('Thời gian kết thúc phải sau thời gian bắt đầu');
    }

    const newVoucher = this.voucherRepo.create({
      maCode: rawCode,
      tenVoucher,
      moTa: input.moTa ? input.moTa.trim() : undefined,
      giamGia,
      loaiGiam,
      giaTriGiamToiDa,
      dieuKienDonToiThieu,
      ngayBatDau,
      ngayHetHan,
      soLuongToiDa,
      soLuongDaLuu: 0,
      soLuongDaSuDung: 0,
      trangThai: input.trangThai === 'TAM_TAT' ? 'TAM_TAT' : 'HOAT_DONG',
      maQuan,
    });

    const saved = await this.voucherRepo.save(newVoucher);
    RealtimeService.getInstance().emitVoucherUpdated(maQuan, { maVoucher: saved.maVoucher, action: 'CREATED' });
    return {
      ...saved,
      computedStatus: this.computeVoucherStatus(saved),
    };
  }

  /**
   * Cập nhật Voucher
   */
  async updateVoucher(maQuan: number, maVoucher: number, input: UpdateVoucherInput) {
    const v = await this.voucherRepo.findOne({ where: { maVoucher, maQuan } });
    if (!v) throw new Error('Không tìm thấy voucher hoặc bạn không có quyền thao tác');

    const hasBeenUsed = (v.soLuongDaSuDung || 0) > 0;

    if (input.tenVoucher !== undefined) {
      const ten = input.tenVoucher.trim();
      if (!ten) throw new Error('Tên voucher không được để trống');
      v.tenVoucher = ten;
    }

    if (input.moTa !== undefined) {
      v.moTa = input.moTa ? input.moTa.trim() : undefined;
    }

    if (input.giamGia !== undefined) {
      if (hasBeenUsed && Number(input.giamGia) !== Number(v.giamGia)) {
        throw new Error('Voucher đã được khách hàng sử dụng, không thể thay đổi giá trị giảm giá');
      }
      const giamGia = Number(input.giamGia);
      if (isNaN(giamGia) || giamGia <= 0) throw new Error('Giá trị giảm phải lớn hơn 0');
      if (v.loaiGiam === 'PERCENT' && (giamGia <= 0 || giamGia > 100)) {
        throw new Error('Phần trăm giảm phải lớn hơn 0 và nhỏ hơn hoặc bằng 100%');
      }
      v.giamGia = giamGia;
    }

    if (input.giaTriGiamToiDa !== undefined) {
      const maxVal = Number(input.giaTriGiamToiDa);
      if (maxVal > 0) v.giaTriGiamToiDa = maxVal;
      else v.giaTriGiamToiDa = undefined;
    }

    if (input.dieuKienDonToiThieu !== undefined) {
      v.dieuKienDonToiThieu = Math.max(Number(input.dieuKienDonToiThieu), 0);
    }

    if (input.soLuongToiDa !== undefined) {
      const newLimit = Math.max(Number(input.soLuongToiDa), 0);
      if (newLimit > 0 && newLimit < (v.soLuongDaSuDung || 0)) {
        throw new Error(`Số lượng tối đa (${newLimit}) không được nhỏ hơn số lượt đã dùng (${v.soLuongDaSuDung})`);
      }
      v.soLuongToiDa = newLimit;
    }

    if (input.ngayBatDau !== undefined) {
      v.ngayBatDau = new Date(input.ngayBatDau);
    }

    if (input.ngayHetHan !== undefined) {
      v.ngayHetHan = input.ngayHetHan ? new Date(input.ngayHetHan) : undefined;
    }

    if (v.ngayHetHan && v.ngayBatDau && v.ngayHetHan <= v.ngayBatDau) {
      throw new Error('Thời gian kết thúc phải sau thời gian bắt đầu');
    }

    if (input.trangThai !== undefined) {
      v.trangThai = input.trangThai === 'TAM_TAT' ? 'TAM_TAT' : 'HOAT_DONG';
    }

    const updated = await this.voucherRepo.save(v);
    RealtimeService.getInstance().emitVoucherUpdated(maQuan, { maVoucher: updated.maVoucher, action: 'UPDATED' });
    return {
      ...updated,
      computedStatus: this.computeVoucherStatus(updated),
    };
  }

  /**
   * Bật / Tắt trạng thái voucher nhanh
   */
  async toggleVoucherStatus(maQuan: number, maVoucher: number, targetStatus?: string) {
    const v = await this.voucherRepo.findOne({ where: { maVoucher, maQuan } });
    if (!v) throw new Error('Không tìm thấy voucher hoặc bạn không có quyền thao tác');

    if (targetStatus) {
      v.trangThai = targetStatus.toUpperCase() === 'HOAT_DONG' ? 'HOAT_DONG' : 'TAM_TAT';
    } else {
      v.trangThai = v.trangThai === 'HOAT_DONG' ? 'TAM_TAT' : 'HOAT_DONG';
    }

    const saved = await this.voucherRepo.save(v);
    RealtimeService.getInstance().emitVoucherUpdated(maQuan, { maVoucher: saved.maVoucher, status: saved.trangThai, action: 'STATUS_TOGGLED' });
    return {
      ...saved,
      computedStatus: this.computeVoucherStatus(saved),
    };
  }

  /**
   * Xóa Voucher (Kiểm tra điều kiện an toàn dữ liệu)
   */
  async deleteVoucher(maQuan: number, maVoucher: number) {
    const v = await this.voucherRepo.findOne({ where: { maVoucher, maQuan } });
    if (!v) throw new Error('Không tìm thấy voucher hoặc bạn không có quyền thao tác');

    if ((v.soLuongDaSuDung || 0) > 0 || (v.soLuongDaLuu || 0) > 0) {
      // Chuyển sang TẠM TẮT để bảo vệ lịch sử giao dịch
      v.trangThai = 'TAM_TAT';
      await this.voucherRepo.save(v);
      RealtimeService.getInstance().emitVoucherUpdated(maQuan, { maVoucher: v.maVoucher, status: 'TAM_TAT', action: 'STATUS_TOGGLED' });
      return {
        deleted: false,
        message: 'Voucher đã có lượt lưu/sử dụng trong lịch sử giao dịch. Đã chuyển trạng thái sang TẠM TẮT để bảo toàn lịch sử dữ liệu.',
      };
    }

    await this.voucherRepo.remove(v);
    RealtimeService.getInstance().emitVoucherUpdated(maQuan, { maVoucher, action: 'DELETED' });
    return {
      deleted: true,
      message: 'Đã xóa voucher thành công',
    };
  }

  /**
   * Áp dụng Voucher vào Đơn Hàng (Đảm bảo Atomic Update chống Race Condition)
   */
  async applyAndIncrementVoucherUsage(maCode: string, maQuan: number, orderTotal: number) {
    const v = await this.voucherRepo.findOne({ where: { maCode: maCode.trim().toUpperCase() } });
    if (!v) throw new Error('Mã voucher không tồn tại');

    if (v.maQuan && v.maQuan !== maQuan) {
      throw new Error('Voucher không áp dụng cho nhà hàng này');
    }

    const computedStatus = this.computeVoucherStatus(v);
    if (computedStatus === 'TAM_TAT') throw new Error('Voucher đang bị tạm tắt');
    if (computedStatus === 'SAP_DIEN_RA') throw new Error('Chương trình voucher chưa đến thời gian áp dụng');
    if (computedStatus === 'HET_HAN') throw new Error('Voucher đã hết hạn sử dụng');
    if (computedStatus === 'HET_LUOT') throw new Error('Voucher đã hết lượt sử dụng');

    if (Number(v.dieuKienDonToiThieu) > 0 && orderTotal < Number(v.dieuKienDonToiThieu)) {
      throw new Error(`Đơn hàng phải từ ${Number(v.dieuKienDonToiThieu).toLocaleString('vi-VN')}₫ để áp dụng voucher này`);
    }

    // Atomic update to prevent race conditions when multiple customers order at once
    const result = await this.voucherRepo.createQueryBuilder()
      .update(VoucherModel)
      .set({ soLuongDaSuDung: () => 'soluongdasudung + 1' })
      .where('mavoucher = :id', { id: v.maVoucher })
      .andWhere('(soluongtoida = 0 OR soluongdasudung < soluongtoida)')
      .execute();

    if (result.affected === 0) {
      throw new Error('Rất tiếc, voucher vừa hết lượt sử dụng cuối cùng');
    }

    // Compute discount amount
    let discountAmount = 0;
    if (v.loaiGiam === 'PERCENT') {
      discountAmount = (orderTotal * Number(v.giamGia)) / 100;
      if (v.giaTriGiamToiDa && Number(v.giaTriGiamToiDa) > 0) {
        discountAmount = Math.min(discountAmount, Number(v.giaTriGiamToiDa));
      }
    } else {
      discountAmount = Number(v.giamGia);
    }

    return {
      maVoucher: v.maVoucher,
      maCode: v.maCode,
      tenVoucher: v.tenVoucher,
      discountAmount: Math.min(discountAmount, orderTotal),
    };
  }

  /**
   * Áp dụng Voucher trong DB Transaction (Pessimistic Write Lock chống Race Condition & Rollback an toàn)
   */
  async applyAndIncrementVoucherUsageInTransaction(
    manager: any,
    maCode: string,
    maQuan: number,
    orderTotal: number,
    maKhachHang?: number
  ) {
    const rawCode = (maCode || '').trim().toUpperCase();
    if (!rawCode) throw new Error('Vui lòng nhập mã voucher');

    const v = await manager.findOne(VoucherModel, {
      where: { maCode: rawCode },
      lock: { mode: 'pessimistic_write' },
    });

    if (!v) throw new Error(`Mã voucher '${rawCode}' không tồn tại`);

    if (v.maQuan && Number(v.maQuan) !== Number(maQuan)) {
      throw new Error('Mã voucher này không áp dụng cho nhà hàng bạn đang chọn');
    }

    const computedStatus = this.computeVoucherStatus(v);
    if (computedStatus === 'TAM_TAT') throw new Error('Voucher đang bị tạm dừng');
    if (computedStatus === 'SAP_DIEN_RA') throw new Error('Chương trình voucher chưa đến thời gian bắt đầu');
    if (computedStatus === 'HET_HAN') throw new Error('Voucher đã hết hạn sử dụng');
    if (computedStatus === 'HET_LUOT') throw new Error('Voucher đã hết lượt sử dụng');

    const minOrder = Number(v.dieuKienDonToiThieu || 0);
    if (minOrder > 0 && orderTotal < minOrder) {
      throw new Error(`Đơn hàng tối thiểu phải từ ${minOrder.toLocaleString('vi-VN')}₫ để sử dụng mã này`);
    }

    const maxLimit = Number(v.soLuongToiDa || 0);
    const currentUsed = Number(v.soLuongDaSuDung || 0);
    if (maxLimit > 0 && currentUsed >= maxLimit) {
      throw new Error('Rất tiếc, voucher vừa hết lượt sử dụng cuối cùng');
    }

    // Kiểm tra và cập nhật trạng thái đã dùng trong ví của khách hàng
    if (maKhachHang && Number(maKhachHang) > 0) {
      const validKhId = Number(maKhachHang);
      let customerVoucher = await manager.findOne(KhachHangVoucherModel, {
        where: { maKhachHang: validKhId, maVoucher: v.maVoucher },
        lock: { mode: 'pessimistic_write' },
      });

      if (customerVoucher) {
        if (customerVoucher.daSuDung) {
          throw new Error('Bạn đã sử dụng mã voucher này rồi');
        }
        customerVoucher.daSuDung = true;
        await manager.save(customerVoucher);
      } else {
        customerVoucher = manager.create(KhachHangVoucherModel, {
          maKhachHang: validKhId,
          maVoucher: v.maVoucher,
          daSuDung: true,
        });
        await manager.save(customerVoucher);
      }
    }

    v.soLuongDaSuDung = currentUsed + 1;
    await manager.save(v);

    let discountAmount = 0;
    if (v.loaiGiam === 'PERCENT') {
      discountAmount = (orderTotal * Number(v.giamGia)) / 100;
      if (v.giaTriGiamToiDa && Number(v.giaTriGiamToiDa) > 0) {
        discountAmount = Math.min(discountAmount, Number(v.giaTriGiamToiDa));
      }
    } else {
      discountAmount = Number(v.giamGia);
    }

    return {
      maVoucher: v.maVoucher,
      maCode: v.maCode,
      tenVoucher: v.tenVoucher,
      discountAmount: Math.min(discountAmount, orderTotal),
    };
  }

  /**
   * Lấy danh sách Voucher công khai đang hoạt động dành cho Khách Hàng (Tùy chọn lọc theo maQuan)
   */
  async getActiveCustomerVouchers(maQuan?: number, includeSystem = false) {
    const query = this.voucherRepo.createQueryBuilder('v')
      .where("v.trangthai = 'HOAT_DONG'")
      .andWhere("LOWER(v.macode) NOT LIKE '%freeship%'")
      .andWhere("LOWER(v.tenvoucher) NOT LIKE '%freeship%'");

    if (maQuan && Number(maQuan) > 0) {
      if (includeSystem) {
        query.andWhere('(v.maquan = :maQuan OR v.maquan IS NULL)', { maQuan: Number(maQuan) });
      } else {
        query.andWhere('v.maquan = :maQuan', { maQuan: Number(maQuan) });
      }
    }

    const vouchers = await query.orderBy('v.ngaytao', 'DESC').getMany();

    const activeVouchers = vouchers
      .map((v) => ({
        ...v,
        giamGia: Number(v.giamGia),
        giaTriGiamToiDa: v.giaTriGiamToiDa ? Number(v.giaTriGiamToiDa) : null,
        dieuKienDonToiThieu: Number(v.dieuKienDonToiThieu || 0),
        computedStatus: this.computeVoucherStatus(v),
      }))
      .filter((v) => v.computedStatus === 'DANG_HOAT_DONG');

    return activeVouchers;
  }

  /**
   * Thẩm định và tính toán số tiền giảm của Voucher trước khi đặt hàng
   */
  async validateCustomerVoucher(maCode: string, maQuan: number, orderTotal: number) {
    const rawCode = (maCode || '').trim().toUpperCase();
    if (!rawCode) throw new Error('Vui lòng nhập mã voucher');
    if (rawCode.includes('FREESHIP')) throw new Error('Mã voucher này không còn hiệu lực');

    const v = await this.voucherRepo.findOne({ where: { maCode: rawCode } });
    if (!v || v.maCode.toUpperCase().includes('FREESHIP')) throw new Error(`Mã voucher '${rawCode}' không tồn tại`);

    if (v.maQuan && Number(v.maQuan) !== Number(maQuan)) {
      throw new Error('Mã voucher này không áp dụng cho nhà hàng bạn đang chọn');
    }

    const computedStatus = this.computeVoucherStatus(v);
    if (computedStatus === 'TAM_TAT') throw new Error('Voucher đang bị tạm dừng');
    if (computedStatus === 'SAP_DIEN_RA') throw new Error('Chương trình voucher chưa đến thời gian bắt đầu');
    if (computedStatus === 'HET_HAN') throw new Error('Voucher đã hết hạn sử dụng');
    if (computedStatus === 'HET_LUOT') throw new Error('Voucher đã hết lượt sử dụng');

    const minOrder = Number(v.dieuKienDonToiThieu || 0);
    if (minOrder > 0 && orderTotal < minOrder) {
      throw new Error(`Đơn hàng tối thiểu phải từ ${minOrder.toLocaleString('vi-VN')}₫ để sử dụng mã này`);
    }

    let discountAmount = 0;
    if (v.loaiGiam === 'PERCENT') {
      discountAmount = (orderTotal * Number(v.giamGia)) / 100;
      if (v.giaTriGiamToiDa && Number(v.giaTriGiamToiDa) > 0) {
        discountAmount = Math.min(discountAmount, Number(v.giaTriGiamToiDa));
      }
    } else {
      discountAmount = Number(v.giamGia);
    }

    const finalDiscount = Math.min(discountAmount, orderTotal);

    return {
      isValid: true,
      maVoucher: v.maVoucher,
      maCode: v.maCode,
      tenVoucher: v.tenVoucher,
      loaiGiam: v.loaiGiam,
      giamGia: Number(v.giamGia),
      discountAmount: finalDiscount,
      finalTotal: Math.max(orderTotal - finalDiscount, 0),
    };
  }

  /**
   * Khách hàng thu thập (lưu) voucher vào ví
   */
  async collectVoucher(userSub: number, maVoucher: number) {
    const v = await this.voucherRepo.findOne({ where: { maVoucher } });
    if (!v) throw new Error('Voucher không tồn tại');

    // Strictly resolve maKhachHang from user's account ID (maTaiKhoan)
    let kh = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
    if (!kh) {
      const newKh = this.khachHangRepo.create({
        maTaiKhoan: userSub,
        hoTen: 'Khách Hàng',
      });
      kh = await this.khachHangRepo.save(newKh);
    }
    const maKhachHang = kh.maKhachHang;

    const existing = await this.khachHangVoucherRepo.findOne({
      where: { maKhachHang, maVoucher },
    });

    if (existing) {
      return { collected: true, message: 'Bạn đã lưu mã này vào ví voucher rồi!' };
    }

    const newSave = this.khachHangVoucherRepo.create({
      maKhachHang,
      maVoucher,
      daSuDung: false,
    });

    await this.khachHangVoucherRepo.save(newSave);

    // Tăng số lượng đã lưu của Voucher
    await this.voucherRepo.increment({ maVoucher }, 'soLuongDaLuu', 1);

    return { collected: true, message: 'Lưu voucher vào ví thành công!' };
  }

  /**
   * Lấy danh sách Voucher khách hàng đã lưu trong ví
   */
  async getMyCollectedVouchers(userSub: number) {
    const kh = await this.khachHangRepo.findOne({ where: { maTaiKhoan: userSub } });
    if (!kh) return [];

    const maKhachHang = kh.maKhachHang;

    const myVouchers = await this.khachHangVoucherRepo.find({
      where: { maKhachHang, daSuDung: false },
      order: { ngayLuu: 'DESC' },
    });

    if (myVouchers.length === 0) return [];

    const voucherIds = myVouchers.map((mv) => mv.maVoucher);
    const vouchers = await this.voucherRepo.createQueryBuilder('v')
      .where('v.mavoucher IN (:...voucherIds)', { voucherIds })
      .andWhere("LOWER(v.macode) NOT LIKE '%freeship%'")
      .andWhere("LOWER(v.tenvoucher) NOT LIKE '%freeship%'")
      .getMany();

    return vouchers.map((v) => ({
      ...v,
      giamGia: Number(v.giamGia),
      giaTriGiamToiDa: v.giaTriGiamToiDa ? Number(v.giaTriGiamToiDa) : null,
      dieuKienDonToiThieu: Number(v.dieuKienDonToiThieu || 0),
      computedStatus: this.computeVoucherStatus(v),
      isCollected: true,
      daLuu: true,
    }));
  }
}
