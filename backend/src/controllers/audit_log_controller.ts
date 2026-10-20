import { Request, Response } from 'express';
import { AuditLogService } from '../services/admin/audit_log_service';

export class AuditLogController {
  private auditLogService = new AuditLogService();

  /**
   * Get filtered audit logs list
   */
  getLogs = async (req: Request, res: Response) => {
    try {
      const page = Number(req.query.page) || 1;
      const limit = Number(queryLimit(req.query.limit)) || 100;
      const search = String(req.query.search || '');
      const actionType = String(req.query.actionType || '');
      const result = String(req.query.result || '');
      const actor = String(req.query.actor || '');
      const period = String(req.query.period || '') as any;
      const startDate = String(req.query.startDate || '');
      const endDate = String(req.query.endDate || '');

      const logs = await this.auditLogService.getLogs({
        page,
        limit,
        search,
        actionType,
        result,
        actor,
        period,
        startDate,
        endDate,
      });

      return res.status(200).json({
        statusCode: 200,
        status: 'success',
        data: logs,
      });
    } catch (error: any) {
      console.error('❌ Lỗi lấy Nhật ký Audit Log:', error);
      return res.status(500).json({
        statusCode: 500,
        status: 'error',
        message: error.message || 'Lỗi server khi lấy nhật ký hoạt động',
      });
    }
  };

  /**
   * Export audit logs as a downloadable CSV file
   */
  exportCsv = async (req: Request, res: Response) => {
    try {
      const search = String(req.query.search || '');
      const actionType = String(req.query.actionType || '');
      const result = String(req.query.result || '');
      const actor = String(req.query.actor || '');
      const period = String(req.query.period || '') as any;
      const startDate = String(req.query.startDate || '');
      const endDate = String(req.query.endDate || '');

      const user = (req as any).user || {};
      const clientIp = req.ip || req.headers['x-forwarded-for']?.toString() || req.socket.remoteAddress || '127.0.0.1';

      const csvData = await this.auditLogService.exportCsv(
        {
          search,
          actionType,
          result,
          actor,
          period,
          startDate,
          endDate,
        },
        {
          maTaiKhoan: user.maTaiKhoan,
          tenNguoiThucHien: user.tenDangNhap || 'Admin',
          actorEmail: user.email,
          ipAddress: clientIp,
        }
      );

      const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
      const filename = `audit_logs_report_${timestamp}.csv`;

      res.setHeader('Content-Type', 'text/csv; charset=utf-8');
      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      return res.status(200).send(csvData);
    } catch (error: any) {
      console.error('❌ Lỗi xuất file CSV Nhật ký:', error);
      return res.status(500).json({
        statusCode: 500,
        status: 'error',
        message: error.message || 'Lỗi khi xuất file báo cáo CSV',
      });
    }
  };
}

function queryLimit(val: any): number {
  const n = Number(val);
  return isNaN(n) || n <= 0 ? 100 : Math.min(n, 5000);
}
