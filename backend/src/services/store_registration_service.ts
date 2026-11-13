import { AppDataSource } from '../config/database';
import { DonDangKyCuaHangModel, TrangThaiDonDangKy } from '../models/don_dang_ky_cua_hang_model';
import { TaiKhoanModel, LoaiTaiKhoan } from '../models/tai_khoan_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { NotificationService } from './notification_service';
import { RealtimeService } from './realtime_service';
import { LEGAL_REQUIREMENTS, validateMaSoThue, LoaiHinhPhapLy } from '../config/legal_requirements';
import { LegalDocumentService } from './legal_document_service';
import { AuditLogService } from './admin/audit_log_service';

export interface SubmitRegistrationDTO {
  tenQuan: string;
  danhMuc?: string;
  diaChi: string;
  lat?: number;
  lng?: number;
  sdt: string;
  hoTenChuQuan: string;
  ngaySinhChuQuan: string; // YYYY-MM-DD
  soCCCD: string;
  diaChiThuongTru: string;
  tenNganHang: string;
  soTaiKhoanNganHang: string;
  tenChuTaiKhoan: string;

  // Legal Information
  loaiHinhPhapLy?: string;
  maSoThue?: string;
  soGiayPhepKinhDoanh?: string;
  soGiayAttp?: string;

  // Proof of Consent
  dongYDieuKhoan: boolean;
  dongYChinhSachDuLieu: boolean;
  maPhienBanDieuKhoan?: number;
  maPhienBanChinhSach?: number;
}

export class StoreRegistrationService {
  private static instance: StoreRegistrationService;
  private regRepo = AppDataSource.getRepository(DonDangKyCuaHangModel);

  public static getInstance(): StoreRegistrationService {
    if (!StoreRegistrationService.instance) {
      StoreRegistrationService.instance = new StoreRegistrationService();
    }
    return StoreRegistrationService.instance;
  }

  public maskCCCD(cccd?: string | null): string {
    if (!cccd) return '';
    const clean = String(cccd).trim();
    if (clean.length <= 4) return '********';
    return '*'.repeat(clean.length - 4) + clean.slice(-4);
  }

  public maskBankAccount(acc?: string | null): string {
    if (!acc) return '';
    const clean = String(acc).trim();
    if (clean.length <= 4) return '****';
    return '*'.repeat(clean.length - 4) + clean.slice(-4);
  }

  private validateAge(dobStr: string): boolean {
    const dob = new Date(dobStr);
    if (isNaN(dob.getTime())) return false;
    const now = new Date();
    let age = now.getFullYear() - dob.getFullYear();
    const m = now.getMonth() - dob.getMonth();
    if (m < 0 || (m === 0 && now.getDate() < dob.getDate())) {
      age--;
    }
    return age >= 18;
  }

  public async submitRegistration(maTaiKhoan: number, dto: SubmitRegistrationDTO) {
    // 1. Validation
    if (!dto.tenQuan || !dto.tenQuan.trim()) throw new Error('Tên thương hiệu không được để trống');
    if (!dto.diaChi || !dto.diaChi.trim()) throw new Error('Địa chỉ vị trí quán không được để trống');
    if (!dto.sdt || !dto.sdt.trim()) throw new Error('Số điện thoại không được để trống');
    if (!dto.hoTenChuQuan || !dto.hoTenChuQuan.trim()) throw new Error('Họ tên chủ quán không được để trống');
    if (!dto.ngaySinhChuQuan) throw new Error('Ngày sinh không được để trống');
    if (!dto.soCCCD || !dto.soCCCD.trim()) throw new Error('Số CCCD không được để trống');
    if (!dto.diaChiThuongTru || !dto.diaChiThuongTru.trim()) throw new Error('Địa chỉ thường trú không được để trống');
    if (!dto.tenNganHang || !dto.tenNganHang.trim()) throw new Error('Tên ngân hàng không được để trống');
    if (!dto.soTaiKhoanNganHang || !dto.soTaiKhoanNganHang.trim()) throw new Error('Số tài khoản ngân hàng không được để trống');
    if (!dto.tenChuTaiKhoan || !dto.tenChuTaiKhoan.trim()) throw new Error('Tên chủ tài khoản ngân hàng không được để trống');

    // Phone regex
    const phoneRegex = /^(0|\+84)[0-9]{9,10}$/;
    if (!phoneRegex.test(dto.sdt.replace(/\s+/g, ''))) {
      throw new Error('Số điện thoại không đúng định dạng (10 chữ số)');
    }

    // CCCD 12 digits
    const cleanCCCD = dto.soCCCD.replace(/\s+/g, '');
    if (!/^\d{12}$/.test(cleanCCCD)) {
      throw new Error('Số CCCD phải bao gồm đúng 12 chữ số');
    }

    // Age >= 18
    if (!this.validateAge(dto.ngaySinhChuQuan)) {
      throw new Error('Chủ quán phải đủ từ 18 tuổi trở lên để đăng ký kinh doanh');
    }

    // 2. Validate Legal Requirements (Tax code, Business license, Food safety cert)
    if (dto.loaiHinhPhapLy && Object.values(LoaiHinhPhapLy).includes(dto.loaiHinhPhapLy as any)) {
      const reqConfig = LEGAL_REQUIREMENTS[dto.loaiHinhPhapLy as LoaiHinhPhapLy];
      if (reqConfig.requireTaxCode) {
        if (!dto.maSoThue || !dto.maSoThue.trim()) {
          throw new Error(`Mã số thuế là bắt buộc đối với loại hình ${reqConfig.label}`);
        }
        if (!validateMaSoThue(dto.maSoThue)) {
          throw new Error('Mã số thuế không đúng định dạng (gồm 10 hoặc 13 chữ số)');
        }
      }
      if (reqConfig.requireBusinessLicense) {
        if (!dto.soGiayPhepKinhDoanh || !dto.soGiayPhepKinhDoanh.trim()) {
          throw new Error(`Số giấy phép kinh doanh là bắt buộc đối với loại hình ${reqConfig.label}`);
        }
      }
      if (reqConfig.requireFoodSafetyCert) {
        if (!dto.soGiayAttp || !dto.soGiayAttp.trim()) {
          throw new Error(`Số giấy chứng nhận an toàn thực phẩm là bắt buộc đối với loại hình ${reqConfig.label}`);
        }
      }
    } else if (dto.maSoThue && !validateMaSoThue(dto.maSoThue)) {
      throw new Error('Mã số thuế không đúng định dạng (gồm 10 hoặc 13 chữ số)');
    }

    // 3. Validate Mandatory Consent (Must agree to both terms & privacy policy)
    if (dto.dongYDieuKhoan !== true || dto.dongYChinhSachDuLieu !== true) {
      throw new Error('Bạn bắt buộc phải đọc và đồng ý đầy đủ Điều khoản đối tác và Chính sách dữ liệu để gửi đăng ký');
    }

    // 4. Validate and attach active legal document versions
    const activeDocs = await LegalDocumentService.getInstance().getActiveDocuments();
    if (!activeDocs.dieuKhoan || !activeDocs.chinhSach) {
      throw new Error('Hệ thống hiện chưa có phiên bản điều khoản đối tác hiệu lực. Vui lòng liên hệ bộ phận hỗ trợ.');
    }

    // Check if client agreed to an outdated version
    if (dto.maPhienBanDieuKhoan && dto.maPhienBanDieuKhoan !== activeDocs.dieuKhoan.maPhienBan) {
      const err: any = new Error('Điều khoản đối tác cửa hàng vừa được cập nhật phiên bản mới. Vui lòng xem lại và xác nhận đồng ý trước khi gửi.');
      err.code = 'TERMS_VERSION_OUTDATED';
      err.statusCode = 409;
      throw err;
    }

    if (dto.maPhienBanChinhSach && dto.maPhienBanChinhSach !== activeDocs.chinhSach.maPhienBan) {
      const err: any = new Error('Chính sách dữ liệu cá nhân vừa được cập nhật phiên bản mới. Vui lòng xem lại và xác nhận đồng ý trước khi gửi.');
      err.code = 'TERMS_VERSION_OUTDATED';
      err.statusCode = 409;
      throw err;
    }

    const consentTimestamp = new Date();

    // 5. Check existing registration
    const existing = await this.regRepo.findOne({
      where: { maTaiKhoan },
      order: { ngayTao: 'DESC' },
    });

    if (existing) {
      if (existing.trangThai === TrangThaiDonDangKy.CHO_DUYET) {
        throw new Error('Bạn đã có đơn đăng ký đang chờ duyệt. Vui lòng chờ quản trị viên xử lý.');
      }
      if (existing.trangThai === TrangThaiDonDangKy.DA_DUYET) {
        throw new Error('Tài khoản của bạn đã được duyệt làm cửa hàng đối tác.');
      }
    }

    let regToSave: DonDangKyCuaHangModel;

    if (existing && existing.trangThai === TrangThaiDonDangKy.TU_CHOI) {
      // Re-submit updated info
      regToSave = existing;
      regToSave.tenQuan = dto.tenQuan.trim();
      regToSave.danhMuc = dto.danhMuc?.trim() || 'Cửa hàng';
      regToSave.diaChi = dto.diaChi.trim();
      regToSave.lat = dto.lat ?? existing.lat;
      regToSave.lng = dto.lng ?? existing.lng;
      regToSave.sdt = dto.sdt.trim();
      regToSave.hoTenChuQuan = dto.hoTenChuQuan.trim();
      regToSave.ngaySinhChuQuan = dto.ngaySinhChuQuan;
      regToSave.soCCCD = cleanCCCD;
      regToSave.diaChiThuongTru = dto.diaChiThuongTru.trim();
      regToSave.tenNganHang = dto.tenNganHang.trim();
      regToSave.soTaiKhoanNganHang = dto.soTaiKhoanNganHang.trim();
      regToSave.tenChuTaiKhoan = dto.tenChuTaiKhoan.trim().toUpperCase();

      // Legal & Consent
      regToSave.loaiHinhPhapLy = dto.loaiHinhPhapLy || null;
      regToSave.maSoThue = dto.maSoThue?.trim() || null;
      regToSave.soGiayPhepKinhDoanh = dto.soGiayPhepKinhDoanh?.trim() || null;
      regToSave.soGiayAttp = dto.soGiayAttp?.trim() || null;
      regToSave.maPhienBanDieuKhoan = activeDocs.dieuKhoan.maPhienBan;
      regToSave.maPhienBanChinhSach = activeDocs.chinhSach.maPhienBan;
      regToSave.thoiGianDongY = consentTimestamp;
      regToSave.dongYDieuKhoan = true;
      regToSave.dongYChinhSachDuLieu = true;

      regToSave.trangThai = TrangThaiDonDangKy.CHO_DUYET;
      regToSave.lyDoTuChoi = null;
      regToSave.ngayTao = new Date();
      regToSave.ngayDuyet = null;
      regToSave.nguoiDuyet = null;
    } else {
      regToSave = this.regRepo.create({
        maTaiKhoan,
        tenQuan: dto.tenQuan.trim(),
        danhMuc: dto.danhMuc?.trim() || 'Cửa hàng',
        diaChi: dto.diaChi.trim(),
        lat: dto.lat,
        lng: dto.lng,
        sdt: dto.sdt.trim(),
        hoTenChuQuan: dto.hoTenChuQuan.trim(),
        ngaySinhChuQuan: dto.ngaySinhChuQuan,
        soCCCD: cleanCCCD,
        diaChiThuongTru: dto.diaChiThuongTru.trim(),
        tenNganHang: dto.tenNganHang.trim(),
        soTaiKhoanNganHang: dto.soTaiKhoanNganHang.trim(),
        tenChuTaiKhoan: dto.tenChuTaiKhoan.trim().toUpperCase(),

        // Legal & Consent
        loaiHinhPhapLy: dto.loaiHinhPhapLy || null,
        maSoThue: dto.maSoThue?.trim() || null,
        soGiayPhepKinhDoanh: dto.soGiayPhepKinhDoanh?.trim() || null,
        soGiayAttp: dto.soGiayAttp?.trim() || null,
        maPhienBanDieuKhoan: activeDocs.dieuKhoan.maPhienBan,
        maPhienBanChinhSach: activeDocs.chinhSach.maPhienBan,
        thoiGianDongY: consentTimestamp,
        dongYDieuKhoan: true,
        dongYChinhSachDuLieu: true,

        trangThai: TrangThaiDonDangKy.CHO_DUYET,
      });
    }

    const saved = await this.regRepo.save(regToSave);

    // Notify Admin via Realtime + DB
    try {
      await NotificationService.getInstance().sendNotification({
        recipientId: 0,
        recipientRole: 'admin',
        type: 'store_registration_new',
        title: 'Đơn đăng ký cửa hàng mới',
        body: `Cửa hàng "${saved.tenQuan}" vừa gửi đơn đăng ký đối tác.`,
        data: { maDon: saved.maDon, tenQuan: saved.tenQuan, maTaiKhoan },
      });

      RealtimeService.getInstance().emitToRoom('admin', 'new_store_registration', {
        maDon: saved.maDon,
        tenQuan: saved.tenQuan,
        hoTenChuQuan: saved.hoTenChuQuan,
        ngayTao: saved.ngayTao,
      });
    } catch (e) {
      console.error('[StoreRegistrationService] Realtime notify error:', e);
    }

    return {
      ...saved,
      soCCCD: this.maskCCCD(saved.soCCCD),
      soTaiKhoanNganHang: this.maskBankAccount(saved.soTaiKhoanNganHang),
    };
  }

  public async getMyStatus(maTaiKhoan: number) {
    const reg = await this.regRepo.findOne({
      where: { maTaiKhoan },
      order: { ngayTao: 'DESC' },
    });

    if (!reg) return null;

    return {
      ...reg,
      soCCCD: this.maskCCCD(reg.soCCCD),
      rawCCCDLength: reg.soCCCD ? reg.soCCCD.length : 0,
      soTaiKhoanNganHang: this.maskBankAccount(reg.soTaiKhoanNganHang),
    };
  }

  public async getAdminRegistrations(page: number = 1, limit: number = 10, status?: string) {
    const qb = this.regRepo.createQueryBuilder('reg')
      .leftJoinAndSelect('reg.taiKhoan', 'taiKhoan')
      .leftJoinAndSelect('reg.phienBanDieuKhoan', 'phienBanDieuKhoan')
      .leftJoinAndSelect('reg.phienBanChinhSach', 'phienBanChinhSach')
      .orderBy('reg.ngayTao', 'DESC');

    if (status && status !== 'ALL') {
      qb.where('reg.trangThai = :status', { status });
    }

    const [items, total] = await qb
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    // Data masking for list view
    const maskedItems = items.map((item) => ({
      ...item,
      soCCCD: this.maskCCCD(item.soCCCD),
      soTaiKhoanNganHang: this.maskBankAccount(item.soTaiKhoanNganHang),
      taiKhoan: item.taiKhoan ? {
        maTaiKhoan: item.taiKhoan.maTaiKhoan,
        tenDangNhap: item.taiKhoan.tenDangNhap,
        loaiTaiKhoan: item.taiKhoan.loaiTaiKhoan,
        trangThai: item.taiKhoan.trangThai,
      } : null,
    }));

    return {
      data: maskedItems,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  public async getAdminRegistrationDetail(maDon: number) {
    const item = await this.regRepo.findOne({
      where: { maDon },
      relations: ['taiKhoan', 'phienBanDieuKhoan', 'phienBanChinhSach'],
    });

    if (!item) throw new Error('Không tìm thấy đơn đăng ký');

    return {
      ...item,
      // Admin detail view keeps full CCCD for legitimate verification
      taiKhoan: item.taiKhoan ? {
        maTaiKhoan: item.taiKhoan.maTaiKhoan,
        tenDangNhap: item.taiKhoan.tenDangNhap,
        loaiTaiKhoan: item.taiKhoan.loaiTaiKhoan,
        trangThai: item.taiKhoan.trangThai,
      } : null,
    };
  }

  public async approveRegistration(maDon: number, adminMaTaiKhoan: number) {
    let approvedReg: DonDangKyCuaHangModel;
    let createdStore: CuaHangModel;

    // Single DB Transaction
    await AppDataSource.transaction(async (manager) => {
      const reg = await manager.findOne(DonDangKyCuaHangModel, {
        where: { maDon },
        lock: { mode: 'pessimistic_write' },
      });

      if (!reg) {
        throw new Error('Đơn đăng ký không tồn tại');
      }

      if (reg.trangThai !== TrangThaiDonDangKy.CHO_DUYET) {
        throw new Error(`Đơn đăng ký đã ở trạng thái ${reg.trangThai}, không thể duyệt lại.`);
      }

      // 1. Update user role to CUAN_HANG
      await manager.update(TaiKhoanModel, { maTaiKhoan: reg.maTaiKhoan }, {
        loaiTaiKhoan: LoaiTaiKhoan.CUAN_HANG,
      });

      // 2. Create or sync CuaHangModel
      let store = await manager.findOne(CuaHangModel, {
        where: { maTaiKhoan: reg.maTaiKhoan },
      });

      if (!store) {
        // Query next available maquan to guarantee NOT NULL constraint is never violated
        let nextMaQuan: number | undefined = undefined;
        try {
          const seqRes = await manager.query(`SELECT nextval('cuahang_maquan_seq') AS next_val`);
          if (seqRes && seqRes[0] && seqRes[0].next_val) {
            nextMaQuan = Number(seqRes[0].next_val);
          }
        } catch (_) {
          const maxRes = await manager.query(`SELECT COALESCE(MAX(maquan), 0) + 1 AS next_val FROM cuahang`);
          if (maxRes && maxRes[0] && maxRes[0].next_val) {
            nextMaQuan = Number(maxRes[0].next_val);
          }
        }

        store = manager.create(CuaHangModel, {
          maQuan: nextMaQuan,
          maTaiKhoan: reg.maTaiKhoan,
          tenQuan: reg.tenQuan,
          diaChi: reg.diaChi,
          lat: reg.lat,
          lng: reg.lng,
          sdt: reg.sdt,
          hoTenChuQuan: reg.hoTenChuQuan,
          ngaySinhChuQuan: reg.ngaySinhChuQuan,
          soCCCD: reg.soCCCD,
          diaChiThuongTru: reg.diaChiThuongTru,
          tenNganHang: reg.tenNganHang,
          soTaiKhoanNganHang: reg.soTaiKhoanNganHang,
          tenChuTaiKhoan: reg.tenChuTaiKhoan,
          danhMuc: reg.danhMuc || 'Cửa hàng',
          loaiHinhPhapLy: reg.loaiHinhPhapLy,
          maSoThue: reg.maSoThue,
          soGiayPhepKinhDoanh: reg.soGiayPhepKinhDoanh,
          soGiayAttp: reg.soGiayAttp,
          trangThai: 'mở cửa',
          img: (reg as any).img || null,
        });

        if (nextMaQuan && !store.maQuan) {
          store.maQuan = nextMaQuan;
        }
      } else {
        store.tenQuan = reg.tenQuan;
        store.diaChi = reg.diaChi;
        if (reg.lat) store.lat = reg.lat;
        if (reg.lng) store.lng = reg.lng;
        store.sdt = reg.sdt;
        store.hoTenChuQuan = reg.hoTenChuQuan;
        store.ngaySinhChuQuan = reg.ngaySinhChuQuan;
        store.soCCCD = reg.soCCCD;
        store.diaChiThuongTru = reg.diaChiThuongTru;
        store.tenNganHang = reg.tenNganHang;
        store.soTaiKhoanNganHang = reg.soTaiKhoanNganHang;
        store.tenChuTaiKhoan = reg.tenChuTaiKhoan;
        store.danhMuc = reg.danhMuc || store.danhMuc || 'Cửa hàng';
        if (reg.loaiHinhPhapLy) store.loaiHinhPhapLy = reg.loaiHinhPhapLy;
        if (reg.maSoThue) store.maSoThue = reg.maSoThue;
        if (reg.soGiayPhepKinhDoanh) store.soGiayPhepKinhDoanh = reg.soGiayPhepKinhDoanh;
        if (reg.soGiayAttp) store.soGiayAttp = reg.soGiayAttp;
      }

      createdStore = await manager.save(CuaHangModel, store);

      // Sync sequence with highest maquan
      await manager.query(`
        SELECT setval('cuahang_maquan_seq', COALESCE((SELECT MAX(maquan) FROM cuahang), 0), true);
      `).catch(() => {});

      // 3. Update registration status
      reg.trangThai = TrangThaiDonDangKy.DA_DUYET;
      reg.ngayDuyet = new Date();
      reg.nguoiDuyet = adminMaTaiKhoan;
      approvedReg = await manager.save(DonDangKyCuaHangModel, reg);
    });

    // Realtime notification AFTER successful transaction commit
    try {
      const payload = {
        maDon: approvedReg!.maDon,
        maTaiKhoan: approvedReg!.maTaiKhoan,
        role: 'CUAN_HANG',
        tenQuan: approvedReg!.tenQuan,
        storeId: createdStore!.maQuan,
      };

      // Emit to user rooms
      RealtimeService.getInstance().emitToRoom(`user:${approvedReg!.maTaiKhoan}`, 'store_registration_approved', payload);
      RealtimeService.getInstance().emitToRoom(`account:${approvedReg!.maTaiKhoan}`, 'store_registration_approved', payload);

      // System notification
      await NotificationService.getInstance().sendNotification({
        recipientId: approvedReg!.maTaiKhoan,
        recipientRole: 'user',
        type: 'store_registration_approved',
        title: 'Chúc mừng! Đơn đăng ký cửa hàng đã được duyệt',
        body: `Chào mừng bạn gia nhập Food Route với vai trò cửa hàng "${approvedReg!.tenQuan}". Bạn đã có thể quản lý cửa hàng ngay trên app hoặc qua FoodRoute Restaurant Portal.`,
        data: payload,
      });

      // Audit Log for Store Approval
      await new AuditLogService().logAction({
        maTaiKhoan: adminMaTaiKhoan,
        tenNguoiThucHien: 'Quản Trị Viên Hệ Thống',
        actorRole: 'ADMIN',
        loaiHanhDong: 'DUYET_DANG_KY_QUAN',
        moTa: `Duyệt đơn đăng ký mở quán cho "${approvedReg!.tenQuan}" (Mã ĐK #${approvedReg!.maDon})`,
        doiTuong: 'CUA_HANG',
        maDoiTuong: createdStore!.maQuan,
        changes: {
          before: { trangThai: 'CHO_DUYET' },
          after: { trangThai: 'DA_DUYET', maQuan: createdStore!.maQuan, tenQuan: createdStore!.tenQuan },
        },
        result: 'success',
      });
    } catch (e) {
      console.error('[StoreRegistrationService] Error sending approval realtime notice or audit log:', e);
    }

    return {
      message: 'Duyệt đơn đăng ký thành công',
      registration: approvedReg!,
      store: createdStore!,
    };
  }

  public async rejectRegistration(maDon: number, adminMaTaiKhoan: number, lyDoTuChoi: string) {
    if (!lyDoTuChoi || !lyDoTuChoi.trim()) {
      throw new Error('Vui lòng nhập lý do từ chối đơn đăng ký');
    }

    let rejectedReg: DonDangKyCuaHangModel;

    await AppDataSource.transaction(async (manager) => {
      const reg = await manager.findOne(DonDangKyCuaHangModel, {
        where: { maDon },
        lock: { mode: 'pessimistic_write' },
      });

      if (!reg) throw new Error('Đơn đăng ký không tồn tại');
      if (reg.trangThai !== TrangThaiDonDangKy.CHO_DUYET) {
        throw new Error(`Đơn đăng ký đã ở trạng thái ${reg.trangThai}, không thể từ chối.`);
      }

      reg.trangThai = TrangThaiDonDangKy.TU_CHOI;
      reg.lyDoTuChoi = lyDoTuChoi.trim();
      reg.ngayDuyet = new Date();
      reg.nguoiDuyet = adminMaTaiKhoan;
      rejectedReg = await manager.save(DonDangKyCuaHangModel, reg);
    });

    try {
      const payload = {
        maDon: rejectedReg!.maDon,
        maTaiKhoan: rejectedReg!.maTaiKhoan,
        reason: rejectedReg!.lyDoTuChoi,
      };

      RealtimeService.getInstance().emitToRoom(`user:${rejectedReg!.maTaiKhoan}`, 'store_registration_rejected', payload);
      RealtimeService.getInstance().emitToRoom(`account:${rejectedReg!.maTaiKhoan}`, 'store_registration_rejected', payload);

      await NotificationService.getInstance().sendNotification({
        recipientId: rejectedReg!.maTaiKhoan,
        recipientRole: 'user',
        type: 'store_registration_rejected',
        title: 'Đơn đăng ký cửa hàng bị từ chối',
        body: `Đơn đăng ký "${rejectedReg!.tenQuan}" chưa được chấp thuận. Lý do: ${rejectedReg!.lyDoTuChoi}`,
        data: payload,
      });

      // Audit Log for Store Rejection
      await new AuditLogService().logAction({
        maTaiKhoan: adminMaTaiKhoan,
        tenNguoiThucHien: 'Quản Trị Viên Hệ Thống',
        actorRole: 'ADMIN',
        loaiHanhDong: 'TU_CHOI_DANG_KY_QUAN',
        moTa: `Từ chối đơn đăng ký mở quán "${rejectedReg!.tenQuan}" (Mã ĐK #${rejectedReg!.maDon}). Lý do: ${rejectedReg!.lyDoTuChoi}`,
        doiTuong: 'DON_DANG_KY',
        maDoiTuong: rejectedReg!.maDon,
        reason: rejectedReg!.lyDoTuChoi,
        changes: {
          before: { trangThai: 'CHO_DUYET' },
          after: { trangThai: 'TU_CHOI', lyDoTuChoi: rejectedReg!.lyDoTuChoi },
        },
        result: 'denied',
      });
    } catch (e) {
      console.error('[StoreRegistrationService] Error sending rejection realtime notice or audit log:', e);
    }

    return {
      message: 'Từ chối đơn đăng ký thành công',
      registration: rejectedReg!,
    };
  }
}
