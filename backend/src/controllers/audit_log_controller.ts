import { Request, Response } from 'express';
import { AuditLogService } from '../services/admin/audit_log_service';
import { AppDataSource } from '../config/database';

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
      const category = String(req.query.category || '') as any;
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
        category,
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
      console.error('[AuditLogController] [Error] Lỗi lấy Nhật ký Audit Log:', error);
      return res.status(500).json({
        statusCode: 500,
        status: 'error',
        message: error.message || 'Lỗi server khi lấy nhật ký hoạt động',
      });
    }
  };

  /**
   * Trigger a real-time DevOps health check and log it in the audit trail
   */
  runDevOpsHealthCheck = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user || {};
      const clientIp = req.ip || req.headers['x-forwarded-for']?.toString() || req.socket.remoteAddress || '127.0.0.1';

      // 1. Measure DB query latency
      const startDb = Date.now();
      await AppDataSource.query('SELECT 1');
      const dbLatencyMs = Date.now() - startDb;

      // 2. Measure memory & system uptime
      const memUsage = process.memoryUsage();
      const heapUsedMB = (memUsage.heapUsed / (1024 * 1024)).toFixed(1);
      const rssMB = (memUsage.rss / (1024 * 1024)).toFixed(1);
      const uptimeSec = Math.floor(process.uptime());
      const hours = Math.floor(uptimeSec / 3600);
      const mins = Math.floor((uptimeSec % 3600) / 60);
      const secs = uptimeSec % 60;
      const uptimeStr = `${hours}h ${mins}m ${secs}s`;

      const healthPayload = {
        database: {
          status: 'UP',
          latency: `${dbLatencyMs}ms`,
        },
        memory: {
          heapUsed: `${heapUsedMB} MB`,
          rss: `${rssMB} MB`,
        },
        uptime: uptimeStr,
        nodeVersion: process.version,
        environment: process.env.NODE_ENV || 'production',
        checkedAt: new Date().toISOString(),
      };

      // Record audit log entry
      await this.auditLogService.logAction({
        maTaiKhoan: user.maTaiKhoan || user.sub,
        tenNguoiThucHien: user.tenDangNhap || 'Quản Trị Viên (DevOps)',
        actorEmail: user.email,
        actorRole: user.role || 'ADMIN',
        loaiHanhDong: 'DEVOPS_HEALTH_CHECK',
        moTa: `Kiểm tra sức khỏe hạ tầng hệ thống. DB Latency: ${dbLatencyMs}ms, RAM: ${rssMB}MB, Uptime: ${uptimeStr}`,
        doiTuong: 'HA_TANG_HE_THONG',
        changes: healthPayload,
        result: 'success',
        ipAddress: clientIp,
      });

      return res.status(200).json({
        statusCode: 200,
        status: 'success',
        message: 'Kiểm tra hạ tầng DevOps thành công!',
        data: healthPayload,
      });
    } catch (error: any) {
      console.error('[AuditLogController] [Error] DevOps Health Check Error:', error);
      return res.status(500).json({
        statusCode: 500,
        status: 'error',
        message: error.message || 'Lỗi khi kiểm tra sức khỏe hạ tầng',
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
      console.error('[AuditLogController] [Error] Lỗi xuất file CSV Nhật ký:', error);
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
