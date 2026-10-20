import React, { useEffect, useState } from 'react';
import { apiFetch, API_BASE_URL } from '../../api/apiClient';
import { Modal } from '../../components/Modal';
import {
  Search,
  ShieldAlert,
  FileText,
  Lock,
  DollarSign,
  RefreshCw,
  Download,
  Calendar,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  Clock,
  User,
  Info,
  Globe,
  FileJson,
  Layers,
} from 'lucide-react';

export const AdminActivityLogs: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [actionType, setActionType] = useState('');
  const [resultFilter, setResultFilter] = useState('');
  const [period, setPeriod] = useState<'all' | 'today' | '7days' | '30days' | 'custom'>('all');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [selectedLog, setSelectedLog] = useState<any | null>(null);
  const [exporting, setExporting] = useState(false);

  const fetchLogs = () => {
    setLoading(true);
    const queryParams: Record<string, string> = {
      limit: '100',
      search: search.trim(),
      actionType: actionType.trim(),
      result: resultFilter.trim(),
    };

    if (period !== 'all') {
      queryParams.period = period;
    }
    if (period === 'custom') {
      if (startDate) queryParams.startDate = startDate;
      if (endDate) queryParams.endDate = endDate;
    }

    const query = new URLSearchParams(queryParams).toString();

    apiFetch<any>(`/admin/activity-logs?${query}`)
      .then((res) => {
        setData(res.data || { items: [], total: 0 });
      })
      .catch((err) => console.error('❌ Error fetching activity logs:', err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchLogs();
  }, [search, actionType, resultFilter, period, startDate, endDate]);

  const handleExportCsv = async () => {
    try {
      setExporting(true);
      const queryParams: Record<string, string> = {
        search: search.trim(),
        actionType: actionType.trim(),
        result: resultFilter.trim(),
      };
      if (period !== 'all') queryParams.period = period;
      if (period === 'custom') {
        if (startDate) queryParams.startDate = startDate;
        if (endDate) queryParams.endDate = endDate;
      }

      const query = new URLSearchParams(queryParams).toString();
      const token = localStorage.getItem('auth_token') || localStorage.getItem('token');

      const response = await fetch(`${API_BASE_URL}/admin/activity-logs/export-csv?${query}`, {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${token || ''}`,
        },
      });

      if (!response.ok) throw new Error('Xuất CSV thất bại!');

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `audit_logs_export_${new Date().toISOString().slice(0, 10)}.csv`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      window.URL.revokeObjectURL(url);
    } catch (err: any) {
      alert(err.message || 'Lỗi khi xuất file báo cáo CSV!');
    } finally {
      setExporting(false);
    }
  };

  // Determine risk level of action
  const getRiskLevel = (type: string) => {
    const t = (type || '').toUpperCase();
    if (
      t.includes('XOA') ||
      t.includes('DELETE') ||
      t.includes('KHOA_QUAN') ||
      t.includes('LOCK_STORE') ||
      t.includes('KHOA_USER') ||
      t.includes('LOCK_USER') ||
      t.includes('HUY_DON') ||
      t.includes('HOAN_TIEN') ||
      t.includes('DOI_MAT_KHAU') ||
      t.includes('EXPORT')
    ) {
      return 'HIGH';
    }
    if (t.includes('UPDATE') || t.includes('CAP_NHAT') || t.includes('CHANGE')) {
      return 'MEDIUM';
    }
    return 'LOW';
  };

  const renderActionBadge = (type: string) => {
    const t = (type || '').toUpperCase();
    if (t.includes('HUY_DON') || t.includes('CANCEL')) {
      return <span className="badge" style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fca5a5', fontWeight: 700 }}>🚫 HỦY ĐƠN HÀNG</span>;
    }
    if (t.includes('HOAN_TIEN') || t.includes('REFUND')) {
      return <span className="badge" style={{ background: '#fffbeb', color: '#b45309', border: '1px solid #fde68a', fontWeight: 700 }}>💸 HOÀN TIỀN</span>;
    }
    if (t.includes('KHOA_QUAN') || t.includes('LOCK_STORE')) {
      return <span className="badge" style={{ background: '#fff1f2', color: '#e11d48', border: '1px solid #fecdd3', fontWeight: 700 }}>🔒 KHÓA NHÀ HÀNG</span>;
    }
    if (t.includes('MO_KHOA_QUAN') || t.includes('UNLOCK_STORE')) {
      return <span className="badge" style={{ background: '#f0fdf4', color: '#16a34a', border: '1px solid #bbf7d0', fontWeight: 700 }}>🔓 MỞ KHÓA QUÁN</span>;
    }
    if (t.includes('XOA_NHA_HANG') || t.includes('DELETE_STORE')) {
      return <span className="badge" style={{ background: '#fef2f2', color: '#b91c1c', border: '1px solid #fca5a5', fontWeight: 700 }}>🗑️ XÓA MỀM NHÀ HÀNG</span>;
    }
    if (t.includes('PHUOC_HOI_NHA_HANG') || t.includes('RESTORE_STORE')) {
      return <span className="badge" style={{ background: '#ecfdf5', color: '#047857', border: '1px solid #a7f3d0', fontWeight: 700 }}>♻️ PHỤC HỒI NHÀ HÀNG</span>;
    }
    if (t.includes('KHOA_USER') || t.includes('LOCK_USER')) {
      return <span className="badge" style={{ background: '#fdf2f8', color: '#db2777', border: '1px solid #fbcfe8', fontWeight: 700 }}>👤 KHÓA TÀI KHOẢN</span>;
    }
    if (t.includes('MO_KHOA_USER') || t.includes('UNLOCK_USER')) {
      return <span className="badge" style={{ background: '#f0fdf4', color: '#15803d', border: '1px solid #bbf7d0', fontWeight: 700 }}>✅ MỞ KHÓA USER</span>;
    }
    if (t.includes('DOI_MAT_KHAU') || t.includes('PASSWORD')) {
      return <span className="badge" style={{ background: '#eff6ff', color: '#2563eb', border: '1px solid #bfdbfe', fontWeight: 700 }}>🔑 ĐỔI MẬT KHAU</span>;
    }
    if (t.includes('EXPORT') || t.includes('CSV')) {
      return <span className="badge" style={{ background: '#f0f9ff', color: '#0284c7', border: '1px solid #bae6fd', fontWeight: 700 }}>📊 XUẤT CSV BÁO CÁO</span>;
    }
    return <span className="badge" style={{ background: '#f1f5f9', color: '#475569', border: '1px solid #cbd5e1', fontWeight: 600 }}>📝 {type}</span>;
  };

  const renderRiskBadge = (type: string) => {
    const risk = getRiskLevel(type);
    if (risk === 'HIGH') {
      return <span className="badge" style={{ background: '#fef2f2', color: '#b91c1c', border: '1px solid #fecaca', fontSize: '11px', fontWeight: 800 }}>⚠️ RỦI RO CAO</span>;
    }
    if (risk === 'MEDIUM') {
      return <span className="badge" style={{ background: '#fffbeb', color: '#d97706', border: '1px solid #fef3c7', fontSize: '11px', fontWeight: 700 }}>⚡ TRUNG BÌNH</span>;
    }
    return <span className="badge" style={{ background: '#f8fafc', color: '#64748b', border: '1px solid #e2e8f0', fontSize: '11px', fontWeight: 600 }}>ℹ️ THẤP</span>;
  };

  const renderResultBadge = (res: string) => {
    const r = (res || 'success').toLowerCase();
    if (r === 'success') {
      return <span style={{ color: '#16a34a', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px', fontSize: '12px' }}><CheckCircle2 size={14} /> Thành công</span>;
    }
    if (r === 'failed') {
      return <span style={{ color: '#dc2626', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px', fontSize: '12px' }}><XCircle size={14} /> Thất bại</span>;
    }
    return <span style={{ color: '#d97706', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px', fontSize: '12px' }}><AlertTriangle size={14} /> Bị từ chối</span>;
  };

  const logsList = data.items || [];
  const highRiskCount = logsList.filter((l: any) => getRiskLevel(l.loaiHanhDong) === 'HIGH').length;
  const financialCount = logsList.filter((l: any) => l.loaiHanhDong?.includes('HUY') || l.loaiHanhDong?.includes('HOAN')).length;
  const securityCount = logsList.filter((l: any) => l.loaiHanhDong?.includes('KHOA') || l.loaiHanhDong?.includes('PASSWORD') || l.loaiHanhDong?.includes('XOA')).length;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Page Header */}
      <div className="page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1 className="page-title" style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <ShieldAlert size={24} color="#fc6011" /> Nhật Ký Hoạt Động & Kiểm Toán (Audit Logs)
          </h1>
          <p className="page-subtitle">
            Ghi lại minh bạch toàn bộ thao tác hệ thống: Ai làm gì, lúc nào, đối tượng nào, IP nào và chi tiết thay đổi (Before/After JSON diff).
          </p>
        </div>
        <button
          className="btn btn-primary"
          onClick={handleExportCsv}
          disabled={exporting}
          style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700 }}
        >
          <Download size={18} /> {exporting ? 'Đang xuất CSV...' : 'Xuất Báo Cáo CSV'}
        </button>
      </div>

      {/* Overview Stat Widgets */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px' }}>
        <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '14px', padding: '16px', display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: '#fff4ee', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fc6011' }}>
            <FileText size={22} />
          </div>
          <div>
            <div style={{ fontSize: '12px', fontWeight: 700, color: '#64748b' }}>TỔNG NHẬT KÝ GHI NHẬN</div>
            <div style={{ fontSize: '22px', fontWeight: 900, color: '#0f172a', marginTop: '2px' }}>{data.total || logsList.length}</div>
          </div>
        </div>

        <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '14px', padding: '16px', display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: '#fef2f2', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#dc2626' }}>
            <AlertTriangle size={22} />
          </div>
          <div>
            <div style={{ fontSize: '12px', fontWeight: 700, color: '#64748b' }}>THAO TÁC RỦI RO CAO</div>
            <div style={{ fontSize: '22px', fontWeight: 900, color: '#dc2626', marginTop: '2px' }}>{highRiskCount} lượt</div>
          </div>
        </div>

        <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '14px', padding: '16px', display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div style={{ width: '42px', height: '42px', borderRadius: '10px', background: '#f0f9ff', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0284c7' }}>
            <Lock size={22} />
          </div>
          <div>
            <div style={{ fontSize: '12px', fontWeight: 700, color: '#64748b' }}>THAO TÁC AN NINH & TÀI CHÍNH</div>
            <div style={{ fontSize: '22px', fontWeight: 900, color: '#0284c7', marginTop: '2px' }}>{securityCount + financialCount} lượt</div>
          </div>
        </div>
      </div>

      {/* Filter Tabs & Toolbar Card */}
      <div className="card-table">
        {/* Date Filter Tabs */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '14px 16px', borderBottom: '1px solid #f1f5f9', background: '#f8fafc', borderTopLeftRadius: '14px', borderTopRightRadius: '14px' }}>
          <Calendar size={16} color="#64748b" />
          <span style={{ fontSize: '13px', fontWeight: 700, color: '#475569', marginRight: '6px' }}>Khoảng thời gian:</span>
          {[
            { id: 'all', label: 'Tất cả' },
            { id: 'today', label: 'Hôm nay' },
            { id: '7days', label: '7 ngày qua' },
            { id: '30days', label: '30 ngày qua' },
            { id: 'custom', label: 'Tùy chọn ngày' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setPeriod(tab.id as any)}
              style={{
                padding: '6px 14px',
                borderRadius: '20px',
                fontSize: '12px',
                fontWeight: period === tab.id ? 800 : 600,
                background: period === tab.id ? '#fc6011' : '#ffffff',
                color: period === tab.id ? '#ffffff' : '#64748b',
                border: period === tab.id ? '1px solid #fc6011' : '1px solid #cbd5e1',
                cursor: 'pointer',
                transition: 'all 0.2s ease',
              }}
            >
              {tab.label}
            </button>
          ))}

          {period === 'custom' && (
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginLeft: 'auto' }}>
              <input
                type="date"
                className="form-control"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                style={{ padding: '4px 8px', fontSize: '12px' }}
              />
              <span style={{ fontSize: '12px', color: '#64748b' }}>đến</span>
              <input
                type="date"
                className="form-control"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                style={{ padding: '4px 8px', fontSize: '12px' }}
              />
            </div>
          )}
        </div>

        {/* Search & Filter Dropdowns */}
        <div className="table-toolbar" style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', padding: '14px 16px' }}>
          <div className="search-input-group" style={{ flex: 1, minWidth: '240px' }}>
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm theo người thực hiện, email, nội dung, IP, Request ID..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <select
            className="form-control"
            style={{ width: '220px', fontWeight: 600 }}
            value={actionType}
            onChange={(e) => setActionType(e.target.value)}
          >
            <option value="">📋 Tất cả loại hành động</option>
            <option value="KHOA_QUAN">🔒 Khóa nhà hàng (KHOA_QUAN)</option>
            <option value="MO_KHOA_QUAN">🔓 Mở khóa quán (MO_KHOA_QUAN)</option>
            <option value="XOA_NHA_HANG">🗑️ Xóa mềm nhà hàng (XOA_NHA_HANG)</option>
            <option value="PHUOC_HOI_NHA_HANG">♻️ Phục hồi nhà hàng</option>
            <option value="HUY_DON">🚫 Hủy đơn hàng (HUY_DON)</option>
            <option value="HOAN_TIEN">💸 Hoàn tiền (HOAN_TIEN)</option>
            <option value="KHOA_USER">👤 Khóa tài khoản (KHOA_USER)</option>
            <option value="MO_KHOA_USER">✅ Mở khóa tài khoản (MO_KHOA_USER)</option>
            <option value="DOI_MAT_KHAU">🔑 Đổi mật khẩu (DOI_MAT_KHAU)</option>
            <option value="system.export_audit_log_csv">📊 Xuất CSV báo cáo</option>
          </select>

          <select
            className="form-control"
            style={{ width: '160px', fontWeight: 600 }}
            value={resultFilter}
            onChange={(e) => setResultFilter(e.target.value)}
          >
            <option value="">🎯 Tất cả kết quả</option>
            <option value="success">✅ Thành công</option>
            <option value="failed">❌ Thất bại</option>
            <option value="denied">⛔ Bị từ chối</option>
          </select>

          <button className="btn btn-outline" onClick={fetchLogs} title="Tải lại nhật ký">
            <RefreshCw size={16} /> Làm Mới
          </button>
        </div>

        {/* Data Table */}
        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : logsList.length === 0 ? (
          <div className="empty-state">Chưa có nhật ký hoạt động nào khớp với bộ lọc</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '50px', textAlign: 'center' }}>STT</th>
                <th style={{ width: '150px' }}>Thời Gian</th>
                <th style={{ width: '180px' }}>Người Thực Hiện</th>
                <th style={{ width: '170px' }}>Loại Hành Động</th>
                <th style={{ width: '110px', textAlign: 'center' }}>Rủi Ro</th>
                <th style={{ width: '130px' }}>Đối Tượng</th>
                <th style={{ width: '110px' }}>Kết Quả</th>
                <th>Mô Tả Chi Tiết</th>
                <th style={{ width: '110px' }}>IP Address</th>
              </tr>
            </thead>
            <tbody>
              {logsList.map((log: any, idx: number) => (
                <tr
                  key={log.maNhatKy || idx}
                  onClick={() => setSelectedLog(log)}
                  style={{ cursor: 'pointer', transition: 'background-color 0.15s ease' }}
                  className="hover-row"
                  title="Nhấp để xem chi tiết JSON Diff & Metadata"
                >
                  <td style={{ textAlign: 'center', fontWeight: 700, color: '#64748b' }}>{idx + 1}</td>
                  <td style={{ fontSize: '12px', color: '#475569', fontWeight: 600 }}>
                    {new Date(log.thoiGianTuyen || log.thoigiantuyen || Date.now()).toLocaleString('vi-VN')}
                  </td>
                  <td>
                    <div style={{ fontWeight: 700, color: '#0f172a' }}>{log.tenNguoiThucHien || 'Admin'}</div>
                    <div style={{ fontSize: '11px', color: '#64748b' }}>
                      {log.actorEmail ? log.actorEmail : `TK #${log.maTaiKhoan || 1}`}
                    </div>
                  </td>
                  <td>{renderActionBadge(log.loaiHanhDong)}</td>
                  <td style={{ textAlign: 'center' }}>{renderRiskBadge(log.loaiHanhDong)}</td>
                  <td>
                    <div style={{ fontWeight: 700, color: '#334155' }}>{log.doiTuong || 'HỆ THỐNG'}</div>
                    {log.maDoiTuong && (
                      <div style={{ fontSize: '11px', color: '#64748b' }}>Mã: #{log.maDoiTuong}</div>
                    )}
                  </td>
                  <td>{renderResultBadge(log.result)}</td>
                  <td style={{ color: '#1e293b', fontWeight: 500, lineHeight: '1.4' }}>
                    {log.moTa}
                  </td>
                  <td style={{ fontSize: '12px', color: '#64748b', fontFamily: 'monospace' }}>
                    {log.ipAddress || '127.0.0.1'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Modal View Audit Log Detail & JSON Diff */}
      {selectedLog && (
        <Modal
          isOpen={!!selectedLog}
          onClose={() => setSelectedLog(null)}
          title={`Chi Tiết Nhật Ký Kiểm Toán #${selectedLog.maNhatKy}`}
          maxWidth="750px"
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Header info card */}
            <div
              style={{
                background: '#f8fafc',
                border: '1px solid #e2e8f0',
                borderRadius: '12px',
                padding: '16px',
                display: 'grid',
                gridTemplateColumns: 'repeat(2, 1fr)',
                gap: '12px',
              }}
            >
              <div>
                <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
                  <User size={12} style={{ display: 'inline', marginRight: '4px' }} /> Người thực hiện
                </div>
                <div style={{ fontSize: '14px', fontWeight: 800, color: '#0f172a', marginTop: '2px' }}>
                  {selectedLog.tenNguoiThucHien || 'Admin'}
                </div>
                <div style={{ fontSize: '12px', color: '#475569' }}>
                  Email: {selectedLog.actorEmail || 'N/A'} | Vai trò: {selectedLog.actorRole || 'ADMIN'}
                </div>
              </div>

              <div>
                <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
                  <Clock size={12} style={{ display: 'inline', marginRight: '4px' }} /> Thời gian
                </div>
                <div style={{ fontSize: '14px', fontWeight: 800, color: '#0f172a', marginTop: '2px' }}>
                  {new Date(selectedLog.thoiGianTuyen || selectedLog.thoigiantuyen).toLocaleString('vi-VN')}
                </div>
                <div style={{ fontSize: '12px', color: '#475569' }}>
                  Mã bản ghi: #{selectedLog.maNhatKy}
                </div>
              </div>

              <div>
                <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
                  <Layers size={12} style={{ display: 'inline', marginRight: '4px' }} /> Loại hành động & Đối tượng
                </div>
                <div style={{ marginTop: '4px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  {renderActionBadge(selectedLog.loaiHanhDong)}
                  {renderRiskBadge(selectedLog.loaiHanhDong)}
                </div>
              </div>

              <div>
                <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
                  <Globe size={12} style={{ display: 'inline', marginRight: '4px' }} /> IP & Request ID
                </div>
                <div style={{ fontSize: '12px', fontFamily: 'monospace', fontWeight: 700, color: '#0f172a', marginTop: '4px' }}>
                  IP: {selectedLog.ipAddress || '127.0.0.1'}
                </div>
                {selectedLog.requestId && (
                  <div style={{ fontSize: '11px', fontFamily: 'monospace', color: '#64748b' }}>
                    REQ: {selectedLog.requestId}
                  </div>
                )}
              </div>
            </div>

            {/* Content Description */}
            <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '14px' }}>
              <div style={{ fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '4px' }}>
                📝 Nội dung mô tả hành động:
              </div>
              <div style={{ fontSize: '14px', fontWeight: 600, color: '#0f172a', lineHeight: '1.5' }}>
                {selectedLog.moTa}
              </div>
              {selectedLog.reason && (
                <div style={{ marginTop: '8px', padding: '8px 12px', background: '#fffbeb', border: '1px solid #fef3c7', borderRadius: '8px', fontSize: '12px', color: '#b45309' }}>
                  💬 Lý do ghi nhận: <strong>{selectedLog.reason}</strong>
                </div>
              )}
            </div>

            {/* JSON Diff section */}
            {selectedLog.changes ? (
              <div style={{ background: '#0f172a', borderRadius: '12px', padding: '14px', color: '#f8fafc' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', fontWeight: 700, color: '#38bdf8', marginBottom: '10px' }}>
                  <FileJson size={16} /> JSON Diff / Trạng Thái Dữ Liệu Chi Tiết:
                </div>
                <pre
                  style={{
                    background: '#1e293b',
                    padding: '12px',
                    borderRadius: '8px',
                    fontSize: '12px',
                    fontFamily: 'Consolas, Monaco, monospace',
                    overflowX: 'auto',
                    maxHeight: '260px',
                    color: '#a7f3d0',
                    margin: 0,
                  }}
                >
                  {JSON.stringify(selectedLog.changes, null, 2)}
                </pre>
              </div>
            ) : (
              <div style={{ padding: '12px', background: '#f8fafc', border: '1px dashed #cbd5e1', borderRadius: '8px', textAlign: 'center', fontSize: '12px', color: '#64748b' }}>
                Không có dữ liệu thay đổi cấu trúc (JSON diff) cho thao tác này.
              </div>
            )}

            {/* User Agent Info if available */}
            {selectedLog.userAgent && (
              <div style={{ fontSize: '11px', color: '#94a3b8', background: '#f8fafc', padding: '8px 12px', borderRadius: '6px', border: '1px solid #f1f5f9' }}>
                🌐 <strong>User Agent:</strong> {selectedLog.userAgent}
              </div>
            )}
          </div>
        </Modal>
      )}
    </div>
  );
};
