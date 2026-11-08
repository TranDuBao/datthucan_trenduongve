import { AppDataSource } from '../../config/database';
import { NhatKyHoatDongModel } from '../../models/nhat_ky_hoat_dong_model';

export interface AuditLogEntryOptions {
  maTaiKhoan?: number;
  tenNguoiThucHien?: string;
  actorEmail?: string;
  actorRole?: string;
  loaiHanhDong: string;
  moTa: string;
  doiTuong?: string;
  maDoiTuong?: string | number;
  changes?: { before?: any; after?: any } | Record<string, any> | null;
  result?: 'success' | 'failed' | 'denied';
  errorCode?: string;
  reason?: string;
  context?: Record<string, any> | null;
  requestId?: string;
  userAgent?: string;
  ipAddress?: string;
}

export interface GetAuditLogsQuery {
  page?: number;
  limit?: number;
  search?: string;
  actionType?: string;
  category?: 'ALL' | 'SECURITY' | 'STORE_APPROVAL' | 'ORDERS' | 'DEVOPS';
  result?: string;
  actor?: string;
  period?: 'today' | '7days' | '30days' | 'custom';
  startDate?: string;
  endDate?: string;
}

export class AuditLogService {
  private logRepo = AppDataSource.getRepository(NhatKyHoatDongModel);

  /**
   * Log an audit action asynchronously (non-blocking for main business flow)
   */
  async logAction(options: AuditLogEntryOptions): Promise<NhatKyHoatDongModel | null> {
    try {
      const entry = this.logRepo.create({
        maTaiKhoan: options.maTaiKhoan,
        tenNguoiThucHien: options.tenNguoiThucHien || 'Hệ Thống',
        actorEmail: options.actorEmail,
        actorRole: options.actorRole || 'ADMIN',
        loaiHanhDong: options.loaiHanhDong,
        moTa: options.moTa,
        doiTuong: options.doiTuong,
        maDoiTuong: options.maDoiTuong !== undefined ? String(options.maDoiTuong) : undefined,
        changes: options.changes,
        result: options.result || 'success',
        errorCode: options.errorCode,
        reason: options.reason,
        context: options.context,
        requestId: options.requestId,
        userAgent: options.userAgent,
        ipAddress: options.ipAddress || '127.0.0.1',
        thoiGianTuyen: new Date(),
      });

      return await this.logRepo.save(entry);
    } catch (err) {
      console.error('[AuditLogService] [Error] Failed to record audit log entry:', err);
      return null;
    }
  }

  /**
   * Query filtered audit logs with pagination and summary counts
   */
  async getLogs(query: GetAuditLogsQuery) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(Math.max(1, query.limit || 50), 500);
    const skip = (page - 1) * limit;

    const qb = this.logRepo.createQueryBuilder('nk');

    // 1. Text Search (actor, description, target)
    if (query.search && query.search.trim()) {
      const term = `%${query.search.trim()}%`;
      qb.andWhere(
        '(LOWER(nk.tenNguoiThucHien) LIKE LOWER(:term) OR LOWER(nk.actorEmail) LIKE LOWER(:term) OR LOWER(nk.moTa) LIKE LOWER(:term) OR LOWER(nk.doiTuong) LIKE LOWER(:term) OR LOWER(nk.loaiHanhDong) LIKE LOWER(:term))',
        { term }
      );
    }

    // 2. Action Type Filter
    if (query.actionType && query.actionType !== 'ALL') {
      qb.andWhere('nk.loaiHanhDong = :actionType', { actionType: query.actionType });
    }

    // 2.1 Domain / Category Filter
    if (query.category && query.category !== 'ALL') {
      if (query.category === 'SECURITY') {
        qb.andWhere(
          "(nk.loaiHanhDong IN ('DANG_NHAP_ADMIN_THANH_CONG', 'CANH_BAO_DANG_NHAP', 'DOI_MAT_KHAU', 'KHOA_USER', 'MO_KHOA_USER', 'KHOA_TAI_KHOAN', 'MO_KHOA_TAI_KHOAN', 'TAO_TAI_KHOAN', 'XOA_TAI_KHOAN', 'PHAN_QUYEN', 'DANG_KY_TAI_KHOAN_MOI') OR nk.doiTuong = 'TAI_KHOAN' OR nk.loaiHanhDong LIKE '%PASSWORD%' OR nk.loaiHanhDong LIKE '%KHOA%' OR nk.loaiHanhDong LIKE '%AUTH%' OR nk.loaiHanhDong LIKE '%MAT_KHAU%' OR nk.loaiHanhDong LIKE '%DANG_KY%')"
        );
      } else if (query.category === 'STORE_APPROVAL') {
        qb.andWhere(
          "(nk.loaiHanhDong IN ('DUYET_DANG_KY_QUAN', 'TU_CHOI_DANG_KY_QUAN', 'KHOA_QUAN', 'MO_KHOA_QUAN', 'XOA_NHA_HANG', 'PHUOC_HOI_NHA_HANG', 'KHOI_PHUC_NHA_HANG', 'YEU_CAU_BO_SUNG_KYC') OR nk.doiTuong IN ('CUA_HANG', 'DON_DANG_KY', 'KYC') OR nk.loaiHanhDong LIKE '%QUAN%' OR nk.loaiHanhDong LIKE '%STORE%')"
        );
      } else if (query.category === 'ORDERS') {
        qb.andWhere(
          "(nk.loaiHanhDong IN ('XAC_NHAN_DON', 'CAP_NHAT_TRANG_THAI_DON', 'HOAN_THANH_DON', 'HUY_DON_HANG', 'HUY_DON', 'HOAN_TIEN') OR nk.doiTuong = 'DON_HANG' OR nk.loaiHanhDong LIKE '%DON%')"
        );
      } else if (query.category === 'DEVOPS') {
        qb.andWhere(
          "(nk.loaiHanhDong IN ('DEVOPS_HEALTH_CHECK', 'DEVOPS_APP_RELEASE', 'DEVOPS_SOCKET_RELOAD', 'DEVOPS_BACKUP_DB', 'EXPORT_AUDIT_LOG', 'system.export_audit_log_csv') OR nk.loaiHanhDong LIKE 'DEVOPS%' OR nk.doiTuong LIKE '%HE_THONG%' OR nk.doiTuong LIKE '%HA_TANG%')"
        );
      }
    }

    // 3. Result Filter
    if (query.result && query.result !== 'ALL') {
      qb.andWhere('nk.result = :result', { result: query.result });
    }

    // 4. Actor Filter
    if (query.actor && query.actor.trim()) {
      qb.andWhere(
        '(LOWER(nk.tenNguoiThucHien) LIKE LOWER(:actor) OR LOWER(nk.actorEmail) LIKE LOWER(:actor))',
        { actor: `%${query.actor.trim()}%` }
      );
    }

    // 5. Time Period Filter
    const now = new Date();
    if (query.period === 'today') {
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0);
      qb.andWhere('nk.thoiGianTuyen >= :startOfDay', { startOfDay });
    } else if (query.period === '7days') {
      const past7 = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      qb.andWhere('nk.thoiGianTuyen >= :past7', { past7 });
    } else if (query.period === '30days') {
      const past30 = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      qb.andWhere('nk.thoiGianTuyen >= :past30', { past30 });
    } else if (query.startDate || query.endDate) {
      if (query.startDate) {
        qb.andWhere('nk.thoiGianTuyen >= :st', { st: new Date(query.startDate) });
      }
      if (query.endDate) {
        const ed = new Date(query.endDate);
        ed.setHours(23, 59, 59, 999);
        qb.andWhere('nk.thoiGianTuyen <= :ed', { ed });
      }
    }

    // Order descending by event time
    qb.orderBy('nk.thoiGianTuyen', 'DESC');

    // Get count and paginated data
    const [items, total] = await qb.skip(skip).take(limit).getManyAndCount();

    // Compute summary breakdown
    const totalCount = await this.logRepo.count();
    const successCount = await this.logRepo.count({ where: { result: 'success' } });
    const failedCount = await this.logRepo.count({ where: { result: 'failed' } });
    const deniedCount = await this.logRepo.count({ where: { result: 'denied' } });

    // Category breakdown counts
    const securityCount = await this.logRepo.createQueryBuilder('nk')
      .where("(nk.loaiHanhDong IN ('DANG_NHAP_ADMIN_THANH_CONG', 'CANH_BAO_DANG_NHAP', 'DOI_MAT_KHAU', 'KHOA_USER', 'MO_KHOA_USER', 'KHOA_TAI_KHOAN', 'MO_KHOA_TAI_KHOAN', 'TAO_TAI_KHOAN', 'XOA_TAI_KHOAN', 'PHAN_QUYEN', 'DANG_KY_TAI_KHOAN_MOI') OR nk.doiTuong = 'TAI_KHOAN' OR nk.loaiHanhDong LIKE '%PASSWORD%' OR nk.loaiHanhDong LIKE '%KHOA%' OR nk.loaiHanhDong LIKE '%AUTH%' OR nk.loaiHanhDong LIKE '%MAT_KHAU%' OR nk.loaiHanhDong LIKE '%DANG_KY%')")
      .getCount();

    const storeApprovalCount = await this.logRepo.createQueryBuilder('nk')
      .where("(nk.loaiHanhDong IN ('DUYET_DANG_KY_QUAN', 'TU_CHOI_DANG_KY_QUAN', 'KHOA_QUAN', 'MO_KHOA_QUAN', 'XOA_NHA_HANG', 'PHUOC_HOI_NHA_HANG', 'KHOI_PHUC_NHA_HANG', 'YEU_CAU_BO_SUNG_KYC') OR nk.doiTuong IN ('CUA_HANG', 'DON_DANG_KY', 'KYC') OR nk.loaiHanhDong LIKE '%QUAN%' OR nk.loaiHanhDong LIKE '%STORE%')")
      .getCount();

    const orderCount = await this.logRepo.createQueryBuilder('nk')
      .where("(nk.loaiHanhDong IN ('XAC_NHAN_DON', 'CAP_NHAT_TRANG_THAI_DON', 'HOAN_THANH_DON', 'HUY_DON_HANG', 'HUY_DON', 'HOAN_TIEN') OR nk.doiTuong = 'DON_HANG' OR nk.loaiHanhDong LIKE '%DON%')")
      .getCount();

    const devopsCount = await this.logRepo.createQueryBuilder('nk')
      .where("(nk.loaiHanhDong IN ('DEVOPS_HEALTH_CHECK', 'DEVOPS_APP_RELEASE', 'DEVOPS_SOCKET_RELOAD', 'DEVOPS_BACKUP_DB', 'EXPORT_AUDIT_LOG', 'system.export_audit_log_csv') OR nk.loaiHanhDong LIKE 'DEVOPS%' OR nk.doiTuong LIKE '%HE_THONG%' OR nk.doiTuong LIKE '%HA_TANG%')")
      .getCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit) || 1,
      stats: {
        total: totalCount,
        success: successCount,
        failed: failedCount,
        denied: deniedCount,
        securityCount,
        storeApprovalCount,
        orderCount,
        devopsCount,
      },
    };
  }

  /**
   * Export logs as CSV for auditing & compliance reporting
   */
  async exportCsv(query: GetAuditLogsQuery, exporterInfo: {
    maTaiKhoan?: number;
    tenNguoiThucHien?: string;
    actorEmail?: string;
    ipAddress?: string;
  }): Promise<string> {
    // Audit log the export action itself!
    await this.logAction({
      maTaiKhoan: exporterInfo.maTaiKhoan,
      tenNguoiThucHien: exporterInfo.tenNguoiThucHien || 'Admin',
      actorEmail: exporterInfo.actorEmail,
      actorRole: 'ADMIN',
      loaiHanhDong: 'EXPORT_AUDIT_LOG',
      moTa: 'Xuất báo cáo nhật ký kiểm toán hệ thống sang định dạng CSV',
      doiTuong: 'AUDIT_LOG',
      context: query,
      result: 'success',
      ipAddress: exporterInfo.ipAddress,
    });

    const result = await this.getLogs({ ...query, limit: 5000, page: 1 });
    const items = result.items;

    const headers = [
      'ID',
      'Thời gian',
      'Người thực hiện',
      'Email',
      'Vai trò',
      'Hành động',
      'Mô tả',
      'Đối tượng',
      'Mã ĐT',
      'Kết quả',
      'Lý do / Lỗi',
      'IP Address',
    ];

    const escapeCsv = (str: any) => {
      if (str === null || str === undefined) return '""';
      const s = String(str).replace(/"/g, '""');
      return `"${s}"`;
    };

    const rows = items.map((log) => [
      log.maNhatKy,
      log.thoiGianTuyen ? new Date(log.thoiGianTuyen).toLocaleString('vi-VN') : '',
      escapeCsv(log.tenNguoiThucHien),
      escapeCsv(log.actorEmail),
      escapeCsv(log.actorRole),
      escapeCsv(log.loaiHanhDong),
      escapeCsv(log.moTa),
      escapeCsv(log.doiTuong),
      escapeCsv(log.maDoiTuong),
      escapeCsv(log.result),
      escapeCsv(log.reason || log.errorCode),
      escapeCsv(log.ipAddress),
    ]);

    const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\r\n');
    return '\uFEFF' + csvContent; // UTF-8 BOM for Excel compatibility
  }
}
