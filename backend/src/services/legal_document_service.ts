import { AppDataSource } from '../config/database';
import { DieuKhoanChinhSachModel, LoaiTaiLieuPhapLy, TrangThaiPhienBan } from '../models/dieu_khoan_chinh_sach_model';
import { DonDangKyCuaHangModel } from '../models/don_dang_ky_cua_hang_model';
import { AuditLogService } from './admin/audit_log_service';

export interface CreateDraftDTO {
  loaiTaiLieu: string;
  soPhienBan: string;
  tieuDe: string;
  noiDung: string;
  cloneFromId?: number;
  trangThai?: string;
}

export interface UpdateDraftDTO {
  loaiTaiLieu?: string;
  tieuDe?: string;
  noiDung?: string;
  soPhienBan?: string;
  trangThai?: string;
}

export class LegalDocumentService {
  private static instance: LegalDocumentService;
  private docRepo = AppDataSource.getRepository(DieuKhoanChinhSachModel);
  private regRepo = AppDataSource.getRepository(DonDangKyCuaHangModel);
  private auditLogService = new AuditLogService();

  public static getInstance(): LegalDocumentService {
    if (!LegalDocumentService.instance) {
      LegalDocumentService.instance = new LegalDocumentService();
    }
    return LegalDocumentService.instance;
  }

  /**
   * Seed default v1.0 draft documents if table is empty (in draft status, not published)
   */
  public async seedInitialDraftDocuments(): Promise<void> {
    try {
      const count = await this.docRepo.count();
      if (count > 0) return;

      const initialTermsContent = `
# ĐIỀU KHOẢN & ĐIỀU KIỆN DỊCH VỤ ĐỐI TÁC CỬA HÀNG FOOD ROUTE
Phiên bản: 1.0 (Bản thảo dự thảo)

1. CAM KẾT VÀ TÍNH CHÍNH XÁC CỦA THÔNG TIN
- Đối tác cửa hàng cam kết toàn bộ thông tin đăng ký (bao gồm tên thương hiệu, địa chỉ kinh doanh, CCCD, mã số thuế, giấy phép kinh doanh) là hoàn toàn chính xác, trung thực và hợp pháp.
- Đối tác chịu hoàn toàn trách nhiệm trước pháp luật nếu cung cấp thông tin sai lệch hoặc mạo danh.

2. TRÁCH NHIỆM VỀ CHẤT LƯỢNG MÓN ĂN VÀ AN TOÀN THỰC PHẨM
- Cửa hàng có nghĩa vụ đảm bảo tất cả món ăn, đồ uống chế biến và phục vụ khách hàng đáp ứng đầy đủ các tiêu chuẩn vệ sinh an toàn thực phẩm theo quy định hiện hành.
- Cửa hàng tự chịu trách nhiệm về nguồn gốc nguyên liệu, bảo quản và quy trình chế biến món ăn; hoàn toàn chịu trách nhiệm bồi thường nếu xảy ra sự cố ngộ độc thực phẩm.

3. NGHĨA VỤ THUẾ VÀ GIẤY PHÉP KINH DOANH
- Đối tác cam kết sở hữu đầy đủ giấy phép kinh doanh hợp lệ theo loại hình đăng ký (cá nhân kinh doanh, hộ kinh doanh hoặc doanh nghiệp).
- Đối tác tự chịu trách nhiệm kê khai và thực hiện đầy đủ các nghĩa vụ thuế, phí với cơ quan nhà nước theo quy định pháp luật.

4. CHÍNH SÁCH HỦY ĐƠN VÀ HOÀN TIỀN
- Đối tác phải tiếp nhận và xử lý đơn đặt món đúng thời gian cam kết.
- Trường hợp đối tác hết món hoặc không thể phục vụ, phải kịp thời từ chối đơn để hệ thống hoàn tiền tự động cho khách hàng.
- Lạm dụng việc hủy đơn mà không có lý do chính đáng sẽ bị xem xét áp dụng chế tài.

5. PHÍ DỊCH VỤ VÀ HOA HỒNG NỀN TẢNG
- Tỷ lệ chiết khấu và phí nền tảng: [Áp dụng theo biểu phí dịch vụ đối tác được Food Route ban hành và cập nhật chính thức từng thời kỳ].
- Tiền thanh toán đơn hàng sẽ được đối soát và chuyển về tài khoản ngân hàng thụ hưởng đã đăng ký theo định kỳ.

6. XỬ LÝ VI PHẠM VÀ TẠM KHÓA TÀI KHOẢN
- Food Route có quyền tạm ngưng hoặc khóa vĩnh viễn tài khoản cửa hàng nếu phát hiện: vi phạm nghiêm trọng vệ sinh ATTP, gian lận khuyến mãi, thái độ phục vụ xúc phạm khách hàng hoặc nhận nhiều phản hồi tiêu cực liên tục.

7. BẢO MẬT VÀ QUYỀN SỞ HỮU
- Các bên cam kết bảo mật thông tin kinh doanh và dữ liệu người dùng nhận được trong quá trình vận hành dịch vụ.

8. CHẤM DỨT HỢP TÁC
- Mỗi bên có quyền yêu cầu chấm dứt hợp tác bằng văn bản hoặc thông báo qua hệ thống trước ít nhất 15 ngày làm việc sau khi đã hoàn tất mọi nghĩa vụ tài chính tồn đọng.
      `.trim();

      const initialPrivacyContent = `
# CHÍNH SÁCH THU THẬP VÀ XỬ LÝ DỮ LIỆU CÁ NHÂN ĐỐI TÁC CỬA HÀNG
Phiên bản: 1.0 (Bản thảo dự thảo)

1. MỤC ĐÍCH THU THẬP DỮ LIỆU
Food Route thu thập các thông tin cá nhân của chủ quán (bao gồm: Họ tên, Ngày tháng năm sinh, Số Căn cước công dân (CCCD), Địa chỉ thường trú, Số điện thoại, Thông tin tài khoản ngân hàng thụ hưởng) nhằm các mục đích sau:
- Xác minh định danh chủ thể kinh doanh (KYC), đảm bảo chủ quán đủ tuổi chịu trách nhiệm dân sự (từ 18 tuổi trở lên).
- Thiết lập hồ sơ cửa hàng, liên hệ vận hành và hỗ trợ giải quyết sự cố phát sinh.
- Đối soát doanh thu và giải ngân thanh toán đơn hàng chính xác vào tài khoản ngân hàng của chủ quán.

2. PHẠM VI VÀ NGUYÊN TẮC BẢO MẬT
- Dữ liệu cá nhân nhạy cảm (CCCD, tài khoản ngân hàng) được mã hóa trong quá trình truyền tải và lưu trữ.
- Hệ thống áp dụng nguyên tắc che bớt (masking) khi hiển thị thông tin CCCD và tài khoản ngân hàng trên các màn hình quản trị để phòng ngừa rò rỉ thông tin.

3. KHÔNG CHIA SẺ DỮ LIỆU CHO BÊN THỨ BA TRÁI PHÉP
- Food Route cam kết không bán, không thương mại hóa hay chia sẻ thông tin cá nhân của đối tác cho bất kỳ bên thứ ba nào, ngoại trừ trường hợp có yêu cầu bằng văn bản từ cơ quan bảo vệ pháp luật có thẩm quyền.

4. QUYỀN HẠN CỦA ĐỐI TÁC
- Đối tác có quyền yêu cầu tra cứu, kiểm tra và đề nghị cập nhật thông tin cá nhân của mình bằng cách gửi yêu cầu hỗ trợ qua cổng quản trị cửa hàng.
      `.trim();

      await this.docRepo.save([
        this.docRepo.create({
          loaiTaiLieu: LoaiTaiLieuPhapLy.DIEU_KHOAN_DOI_TAC,
          soPhienBan: '1.0',
          tieuDe: 'Điều khoản & Điều kiện Dịch vụ Đối tác Cửa hàng Food Route',
          noiDung: initialTermsContent,
          trangThai: TrangThaiPhienBan.NHAP,
        }),
        this.docRepo.create({
          loaiTaiLieu: LoaiTaiLieuPhapLy.CHINH_SACH_DU_LIEU,
          soPhienBan: '1.0',
          tieuDe: 'Chính sách Thu thập và Xử lý Dữ liệu Cá nhân Đối tác Cửa hàng',
          noiDung: initialPrivacyContent,
          trangThai: TrangThaiPhienBan.NHAP,
        }),
      ]);

      console.log('[LegalDocumentService] Đã tạo thành công 2 bản nháp v1.0 ban đầu ở trạng thái NHAP');
    } catch (err: any) {
      console.error('[LegalDocumentService] Lỗi khi tạo dữ liệu mẫu điều khoản:', err.message);
    }
  }

  /**
   * Get active legal documents (strictly read-only for public/app usage)
   */
  public async getActiveDocuments(): Promise<{
    dieuKhoan: DieuKhoanChinhSachModel | null;
    chinhSach: DieuKhoanChinhSachModel | null;
  }> {
    const [dieuKhoan, chinhSach] = await Promise.all([
      this.docRepo.findOne({
        where: {
          loaiTaiLieu: LoaiTaiLieuPhapLy.DIEU_KHOAN_DOI_TAC,
          trangThai: TrangThaiPhienBan.DANG_HIEU_LUC,
        },
      }),
      this.docRepo.findOne({
        where: {
          loaiTaiLieu: LoaiTaiLieuPhapLy.CHINH_SACH_DU_LIEU,
          trangThai: TrangThaiPhienBan.DANG_HIEU_LUC,
        },
      }),
    ]);

    return { dieuKhoan, chinhSach };
  }

  /**
   * Admin: Get all documents with pagination and metadata (without loading full long body unless requested)
   */
  public async getAdminDocuments(query: {
    page?: number;
    limit?: number;
    loaiTaiLieu?: string;
    trangThai?: string;
    search?: string;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(50, Number(query.limit) || 10));
    const skip = (page - 1) * limit;

    const qb = this.docRepo
      .createQueryBuilder('doc')
      .leftJoinAndSelect('doc.nguoiTao', 'user')
      .select([
        'doc.maPhienBan',
        'doc.loaiTaiLieu',
        'doc.soPhienBan',
        'doc.tieuDe',
        'doc.trangThai',
        'doc.ngayHieuLuc',
        'doc.ngayTao',
        'doc.ngayCapNhat',
        'doc.maTaiKhoanTao',
        'user.maTaiKhoan',
        'user.tenDangNhap',
      ]);

    if (query.loaiTaiLieu && query.loaiTaiLieu !== 'ALL') {
      qb.andWhere('doc.loaiTaiLieu = :loai', { loai: query.loaiTaiLieu });
    }

    if (query.trangThai && query.trangThai !== 'ALL') {
      qb.andWhere('doc.trangThai = :trangThai', { trangThai: query.trangThai });
    }

    if (query.search && query.search.trim()) {
      qb.andWhere('(doc.tieuDe ILIKE :s OR doc.soPhienBan ILIKE :s)', { s: `%${query.search.trim()}%` });
    }

    qb.orderBy('doc.ngayTao', 'DESC');
    qb.skip(skip).take(limit);

    const [items, total] = await qb.getManyAndCount();
    return { items, total, page, limit, totalPages: Math.ceil(total / limit) };
  }

  /**
   * Get single document by ID (full details)
   */
  public async getDocumentById(id: number): Promise<DieuKhoanChinhSachModel> {
    const doc = await this.docRepo.findOne({
      where: { maPhienBan: id },
      relations: ['nguoiTao'],
    });
    if (!doc) throw new Error('Không tìm thấy phiên bản điều khoản / chính sách');
    return doc;
  }

  /**
   * Admin: Create a new draft document
   */
  public async createDraft(adminUser: { maTaiKhoan: number; tenDangNhap?: string; email?: string; role?: string }, dto: CreateDraftDTO) {
    if (!dto.loaiTaiLieu || !Object.values(LoaiTaiLieuPhapLy).includes(dto.loaiTaiLieu as any)) {
      throw new Error('Loại tài liệu không hợp lệ');
    }
    if (!dto.soPhienBan || !dto.soPhienBan.trim()) {
      throw new Error('Số phiên bản không được để trống');
    }
    if (!dto.tieuDe || !dto.tieuDe.trim()) {
      throw new Error('Tiêu đề tài liệu không được để trống');
    }

    let noiDung = dto.noiDung ? dto.noiDung.trim() : '';

    // If cloning from an existing document
    if (dto.cloneFromId) {
      const src = await this.docRepo.findOne({ where: { maPhienBan: dto.cloneFromId } });
      if (src && !noiDung) {
        noiDung = src.noiDung;
      }
    }

    if (!noiDung) {
      throw new Error('Nội dung tài liệu không được để trống');
    }

    // Check version uniqueness for the same document type
    const dup = await this.docRepo.findOne({
      where: { loaiTaiLieu: dto.loaiTaiLieu, soPhienBan: dto.soPhienBan.trim() },
    });
    if (dup) {
      throw new Error(`Số phiên bản ${dto.soPhienBan} đã tồn tại cho loại tài liệu này. Vui lòng chọn số phiên bản khác.`);
    }

    const targetStatus = dto.trangThai === TrangThaiPhienBan.DANG_HIEU_LUC
      ? TrangThaiPhienBan.DANG_HIEU_LUC
      : dto.trangThai === TrangThaiPhienBan.DA_LUU_TRU
      ? TrangThaiPhienBan.DA_LUU_TRU
      : TrangThaiPhienBan.NHAP;

    if (targetStatus === TrangThaiPhienBan.DANG_HIEU_LUC) {
      await this.docRepo.update(
        { loaiTaiLieu: dto.loaiTaiLieu, trangThai: TrangThaiPhienBan.DANG_HIEU_LUC },
        { trangThai: TrangThaiPhienBan.DA_LUU_TRU }
      );
    }

    const doc = this.docRepo.create({
      loaiTaiLieu: dto.loaiTaiLieu,
      soPhienBan: dto.soPhienBan.trim(),
      tieuDe: dto.tieuDe.trim(),
      noiDung,
      trangThai: targetStatus,
      ngayHieuLuc: targetStatus === TrangThaiPhienBan.DANG_HIEU_LUC ? new Date() : null,
      maTaiKhoanTao: adminUser.maTaiKhoan,
    });

    const saved = await this.docRepo.save(doc);

    // Audit Log
    await this.auditLogService.logAction({
      maTaiKhoan: adminUser.maTaiKhoan,
      tenNguoiThucHien: adminUser.tenDangNhap || 'Admin',
      actorEmail: adminUser.email,
      actorRole: adminUser.role || 'ADMIN',
      loaiHanhDong: 'TAO_DIEU_KHOAN',
      moTa: `Tạo tài liệu mới ${saved.loaiTaiLieu} v${saved.soPhienBan}: "${saved.tieuDe}" (${saved.trangThai})`,
      doiTuong: 'dieu_khoan_chinh_sach',
      maDoiTuong: saved.maPhienBan,
    });

    return saved;
  }

  /**
   * Admin: Update document (Title, Content, Version, Status)
   */
  public async updateDraft(
    id: number,
    adminUser: { maTaiKhoan: number; tenDangNhap?: string; email?: string; role?: string },
    dto: UpdateDraftDTO
  ) {
    const doc = await this.getDocumentById(id);

    if (dto.loaiTaiLieu && Object.values(LoaiTaiLieuPhapLy).includes(dto.loaiTaiLieu as any)) {
      doc.loaiTaiLieu = dto.loaiTaiLieu;
    }

    if (dto.soPhienBan && dto.soPhienBan.trim() !== doc.soPhienBan) {
      const dup = await this.docRepo.findOne({
        where: { loaiTaiLieu: doc.loaiTaiLieu, soPhienBan: dto.soPhienBan.trim() },
      });
      if (dup && dup.maPhienBan !== id) {
        throw new Error(`Số phiên bản ${dto.soPhienBan} đã tồn tại cho loại tài liệu này`);
      }
      doc.soPhienBan = dto.soPhienBan.trim();
    }

    if (dto.tieuDe && dto.tieuDe.trim()) {
      doc.tieuDe = dto.tieuDe.trim();
    }
    if (dto.noiDung && dto.noiDung.trim()) {
      doc.noiDung = dto.noiDung.trim();
    }

    // Handle status change if requested
    if (dto.trangThai && dto.trangThai !== doc.trangThai) {
      if (dto.trangThai === TrangThaiPhienBan.DANG_HIEU_LUC) {
        await this.docRepo.update(
          { loaiTaiLieu: doc.loaiTaiLieu, trangThai: TrangThaiPhienBan.DANG_HIEU_LUC },
          { trangThai: TrangThaiPhienBan.DA_LUU_TRU }
        );
        doc.trangThai = TrangThaiPhienBan.DANG_HIEU_LUC;
        doc.ngayHieuLuc = new Date();
      } else if (dto.trangThai === TrangThaiPhienBan.DA_LUU_TRU) {
        doc.trangThai = TrangThaiPhienBan.DA_LUU_TRU;
      } else if (dto.trangThai === TrangThaiPhienBan.NHAP) {
        doc.trangThai = TrangThaiPhienBan.NHAP;
      }
    }

    doc.maTaiKhoanCapNhat = adminUser.maTaiKhoan;
    const updated = await this.docRepo.save(doc);

    // Audit Log
    await this.auditLogService.logAction({
      maTaiKhoan: adminUser.maTaiKhoan,
      tenNguoiThucHien: adminUser.tenDangNhap || 'Admin',
      actorEmail: adminUser.email,
      actorRole: adminUser.role || 'ADMIN',
      loaiHanhDong: 'CAP_NHAT_DIEU_KHOAN',
      moTa: `Cập nhật tài liệu ${updated.loaiTaiLieu} v${updated.soPhienBan}: "${updated.tieuDe}"`,
      doiTuong: 'dieu_khoan_chinh_sach',
      maDoiTuong: updated.maPhienBan,
    });

    return updated;
  }

  /**
   * Admin: Delete document
   */
  public async deleteDraft(id: number, adminUser: { maTaiKhoan: number; tenDangNhap?: string; email?: string; role?: string }) {
    const doc = await this.getDocumentById(id);

    // Safely clear registration references if any before deletion
    await this.regRepo.update({ maPhienBanDieuKhoan: id }, { maPhienBanDieuKhoan: null as any });
    await this.regRepo.update({ maPhienBanChinhSach: id }, { maPhienBanChinhSach: null as any });

    await this.docRepo.remove(doc);

    // Audit Log
    await this.auditLogService.logAction({
      maTaiKhoan: adminUser.maTaiKhoan,
      tenNguoiThucHien: adminUser.tenDangNhap || 'Admin',
      actorEmail: adminUser.email,
      actorRole: adminUser.role || 'ADMIN',
      loaiHanhDong: 'XOA_DIEU_KHOAN',
      moTa: `Xóa tài liệu ${doc.loaiTaiLieu} v${doc.soPhienBan}: "${doc.tieuDe}"`,
      doiTuong: 'dieu_khoan_chinh_sach',
      maDoiTuong: id,
    });

    return { message: 'Đã xóa tài liệu thành công' };
  }

  /**
   * Admin: Publish a draft in a single atomic DB transaction
   * Moves existing active version of the same type to DA_LUU_TRU, and activates target version.
   */
  public async publishDocument(id: number, adminUser: { maTaiKhoan: number; tenDangNhap?: string; email?: string; role?: string }) {
    return await AppDataSource.transaction(async (manager) => {
      const doc = await manager.findOne(DieuKhoanChinhSachModel, {
        where: { maPhienBan: id },
      });

      if (!doc) throw new Error('Không tìm thấy phiên bản cần xuất bản');
      if (doc.trangThai === TrangThaiPhienBan.DANG_HIEU_LUC) {
        throw new Error('Phiên bản này hiện đã đang có hiệu lực');
      }

      // Archive currently active document of the same type
      const activeOld = await manager.findOne(DieuKhoanChinhSachModel, {
        where: {
          loaiTaiLieu: doc.loaiTaiLieu,
          trangThai: TrangThaiPhienBan.DANG_HIEU_LUC,
        },
      });

      if (activeOld) {
        activeOld.trangThai = TrangThaiPhienBan.DA_LUU_TRU;
        await manager.save(activeOld);
      }

      // Activate new document
      doc.trangThai = TrangThaiPhienBan.DANG_HIEU_LUC;
      doc.ngayHieuLuc = new Date();
      doc.maTaiKhoanCapNhat = adminUser.maTaiKhoan;
      const published = await manager.save(doc);

      // Audit Log
      await this.auditLogService.logAction({
        maTaiKhoan: adminUser.maTaiKhoan,
        tenNguoiThucHien: adminUser.tenDangNhap || 'Admin',
        actorEmail: adminUser.email,
        actorRole: adminUser.role || 'ADMIN',
        loaiHanhDong: 'XUAT_BAN_DIEU_KHOAN',
        moTa: `Xuất bản ${published.loaiTaiLieu} v${published.soPhienBan} (Bản cũ ${activeOld ? `v${activeOld.soPhienBan}` : 'không có'} chuyển sang Đã lưu trữ)`,
        doiTuong: 'dieu_khoan_chinh_sach',
        maDoiTuong: published.maPhienBan,
        changes: {
          previousActiveId: activeOld?.maPhienBan,
          newActiveId: published.maPhienBan,
        },
      });

      return published;
    });
  }
}

