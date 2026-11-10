import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../../api/apiClient';
import {
  Clock,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  Eye,
  Send,
  ArrowUpCircle,
  Bell,
  Megaphone,
  Gift,
  Info,
  RefreshCw,
  Ban,
} from 'lucide-react';

interface NotificationItem {
  id: number;
  type: string;
  title: string;
  titleEn?: string;
  body: string;
  bodyEn?: string;
  target: string;
  targetValue?: string;
  status: 'SENT' | 'SCHEDULED' | 'FAILED' | 'DRAFT';
  scheduledAt?: string;
  sentAt?: string;
  createdAt: string;
  sentCount: number;
  readCount: number;
  failedCount: number;
}

export const NotificationHistoryTable: React.FC<{ refreshTrigger: number }> = ({ refreshTrigger }) => {
  const [items, setItems] = useState<NotificationItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterType, setFilterType] = useState<string>('all');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [limit] = useState(15);
  const [cancellingId, setCancellingId] = useState<number | null>(null);

  const fetchHistory = async () => {
    setLoading(true);
    try {
      const typeQuery = filterType !== 'all' ? `&type=${filterType}` : '';
      const res = await apiFetch(`/admin/notifications?page=${page}&limit=${limit}${typeQuery}`);
      if (res && res.data) {
        setItems(res.data.items || []);
        setTotal(res.data.total || 0);
      }
    } catch (e) {
      console.error('[NotificationHistoryTable] Error:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHistory();
  }, [page, filterType, refreshTrigger]);

  const handleCancelScheduled = async (id: number) => {
    if (!window.confirm('Bạn có chắc muốn hủy thông báo hẹn giờ này?')) return;
    setCancellingId(id);
    try {
      const res = await apiFetch(`/admin/notifications/${id}/cancel`, { method: 'POST' });
      if (res && res.success !== false) {
        alert('Đã hủy thông báo hẹn giờ thành công');
        fetchHistory();
      } else {
        alert(res.message || 'Lỗi khi hủy thông báo');
      }
    } catch (e: any) {
      alert(e.message || 'Lỗi khi hủy thông báo');
    } finally {
      setCancellingId(null);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'SENT':
        return (
          <span
            style={{
              padding: '4px 10px',
              borderRadius: '20px',
              fontSize: '12px',
              fontWeight: 700,
              backgroundColor: '#ecfdf5',
              color: '#059669',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <CheckCircle2 size={13} /> Đã gửi
          </span>
        );
      case 'SCHEDULED':
        return (
          <span
            style={{
              padding: '4px 10px',
              borderRadius: '20px',
              fontSize: '12px',
              fontWeight: 700,
              backgroundColor: '#fef3c7',
              color: '#d97706',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <Clock size={13} /> Hẹn giờ
          </span>
        );
      case 'FAILED':
        return (
          <span
            style={{
              padding: '4px 10px',
              borderRadius: '20px',
              fontSize: '12px',
              fontWeight: 700,
              backgroundColor: '#fef2f2',
              color: '#dc2626',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <XCircle size={13} /> Đã hủy / Thất bại
          </span>
        );
      default:
        return (
          <span
            style={{
              padding: '4px 10px',
              borderRadius: '20px',
              fontSize: '12px',
              fontWeight: 700,
              backgroundColor: '#f1f5f9',
              color: '#475569',
            }}
          >
            {status}
          </span>
        );
    }
  };

  const getTypeBadge = (itemType: string) => {
    if (itemType === 'update') {
      return (
        <span
          style={{
            padding: '4px 8px',
            borderRadius: '6px',
            fontSize: '11px',
            fontWeight: 700,
            backgroundColor: '#eff6ff',
            color: '#2563eb',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '4px',
          }}
        >
          <ArrowUpCircle size={12} /> Cập nhật
        </span>
      );
    }
    if (itemType === 'alert') {
      return (
        <span
          style={{
            padding: '4px 8px',
            borderRadius: '6px',
            fontSize: '11px',
            fontWeight: 700,
            backgroundColor: '#fef2f2',
            color: '#dc2626',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '4px',
          }}
        >
          <Megaphone size={12} /> Khẩn cấp
        </span>
      );
    }
    if (itemType === 'promo') {
      return (
        <span
          style={{
            padding: '4px 8px',
            borderRadius: '6px',
            fontSize: '11px',
            fontWeight: 700,
            backgroundColor: '#f0fdf4',
            color: '#16a34a',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '4px',
          }}
        >
          <Gift size={12} /> Ưu đãi
        </span>
      );
    }
    return (
      <span
        style={{
          padding: '4px 8px',
          borderRadius: '6px',
          fontSize: '11px',
          fontWeight: 700,
          backgroundColor: '#fff7ed',
          color: '#fc6011',
          display: 'inline-flex',
          alignItems: 'center',
          gap: '4px',
        }}
      >
        <Bell size={12} /> Hệ thống
      </span>
    );
  };

  return (
    <div style={{ background: '#fff', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '16px' }}>
        <div>
          <h3 style={{ fontSize: '18px', fontWeight: 700, margin: '0 0 4px 0', color: '#1e293b' }}>
            Lịch Sử & Thống Kê Thông Báo
          </h3>
          <p style={{ fontSize: '13px', color: '#64748b', margin: 0 }}>
            Theo dõi tiến trình phát, số thiết bị nhận và số lượt đọc thực tế
          </p>
        </div>

        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <select
            value={filterType}
            onChange={(e) => {
              setFilterType(e.target.value);
              setPage(1);
            }}
            style={{
              padding: '8px 12px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '13px',
              outline: 'none',
              backgroundColor: '#fff',
            }}
          >
            <option value="all">Tất cả loại thông báo</option>
            <option value="system">🔔 Thông báo hệ thống</option>
            <option value="update">🚀 Cập nhật phiên bản</option>
            <option value="alert">📢 Khẩn cấp / Cảnh báo</option>
            <option value="promo">🎁 Ưu đãi lộ trình</option>
          </select>

          <button
            type="button"
            onClick={fetchHistory}
            style={{
              padding: '8px 12px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              backgroundColor: '#fff',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              fontSize: '13px',
              fontWeight: 600,
            }}
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            Làm mới
          </button>
        </div>
      </div>

      {/* Table */}
      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8fafc', borderBottom: '2px solid #e2e8f0', color: '#475569' }}>
              <th style={{ padding: '12px 14px', fontWeight: 600 }}>ID</th>
              <th style={{ padding: '12px 14px', fontWeight: 600 }}>Loại</th>
              <th style={{ padding: '12px 14px', fontWeight: 600 }}>Tiêu đề & Nội dung</th>
              <th style={{ padding: '12px 14px', fontWeight: 600 }}>Đối tượng</th>
              <th style={{ padding: '12px 14px', fontWeight: 600 }}>Trạng thái</th>
              <th style={{ padding: '12px 14px', fontWeight: 600 }}>Thời gian</th>
              <th style={{ padding: '12px 14px', fontWeight: 600 }}>Thống kê nhận / đọc</th>
              <th style={{ padding: '12px 14px', fontWeight: 600, textAlign: 'center' }}>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={8} style={{ padding: '36px', textAlign: 'center', color: '#94a3b8' }}>
                  Đang tải dữ liệu...
                </td>
              </tr>
            ) : items.length === 0 ? (
              <tr>
                <td colSpan={8} style={{ padding: '36px', textAlign: 'center', color: '#94a3b8' }}>
                  Chưa có thông báo nào được tạo
                </td>
              </tr>
            ) : (
              items.map((item) => (
                <tr key={item.id} style={{ borderBottom: '1px solid #f1f5f9' }}>
                  <td style={{ padding: '12px 14px', fontWeight: 600, color: '#64748b' }}>#{item.id}</td>
                  <td style={{ padding: '12px 14px' }}>{getTypeBadge(item.type)}</td>
                  <td style={{ padding: '12px 14px', maxWidth: '300px' }}>
                    <div style={{ fontWeight: 700, color: '#1e293b', marginBottom: '2px' }}>{item.title}</div>
                    <div
                      style={{
                        fontSize: '12px',
                        color: '#64748b',
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}
                    >
                      {item.body}
                    </div>
                  </td>
                  <td style={{ padding: '12px 14px' }}>
                    <span style={{ fontSize: '12px', fontWeight: 600, color: '#334155' }}>
                      {item.target === 'ALL'
                        ? 'Tất cả'
                        : item.target === 'ROLE'
                        ? `Role: ${item.targetValue}`
                        : item.target === 'VERSION_LT'
                        ? `Bản cũ < ${item.targetValue}`
                        : 'Cá nhân'}
                    </span>
                  </td>
                  <td style={{ padding: '12px 14px' }}>{getStatusBadge(item.status)}</td>
                  <td style={{ padding: '12px 14px', color: '#64748b', fontSize: '12px' }}>
                    {item.sentAt
                      ? new Date(item.sentAt).toLocaleString('vi-VN')
                      : item.scheduledAt
                      ? `Hẹn: ${new Date(item.scheduledAt).toLocaleString('vi-VN')}`
                      : new Date(item.createdAt).toLocaleString('vi-VN')}
                  </td>
                  <td style={{ padding: '12px 14px' }}>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <span
                        style={{
                          fontSize: '11px',
                          padding: '2px 8px',
                          borderRadius: '6px',
                          backgroundColor: '#f1f5f9',
                          color: '#334155',
                          fontWeight: 600,
                        }}
                      >
                        Đã gửi: {item.sentCount}
                      </span>
                      <span
                        style={{
                          fontSize: '11px',
                          padding: '2px 8px',
                          borderRadius: '6px',
                          backgroundColor: '#eff6ff',
                          color: '#2563eb',
                          fontWeight: 600,
                        }}
                      >
                        Đã đọc: {item.readCount}
                      </span>
                    </div>
                  </td>
                  <td style={{ padding: '12px 14px', textAlign: 'center' }}>
                    {item.status === 'SCHEDULED' && (
                      <button
                        type="button"
                        onClick={() => handleCancelScheduled(item.id)}
                        disabled={cancellingId === item.id}
                        style={{
                          padding: '6px 12px',
                          borderRadius: '6px',
                          backgroundColor: '#fee2e2',
                          color: '#b91c1c',
                          border: 'none',
                          cursor: 'pointer',
                          fontSize: '12px',
                          fontWeight: 700,
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '4px',
                        }}
                      >
                        <Ban size={13} />
                        {cancellingId === item.id ? 'Đang hủy...' : 'Hủy hẹn'}
                      </button>
                    )}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {total > limit && (
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '16px' }}>
          <span style={{ fontSize: '12px', color: '#64748b' }}>
            Tổng số: {total} thông báo (Trang {page} / {Math.ceil(total / limit)})
          </span>
          <div style={{ display: 'flex', gap: '6px' }}>
            <button
              disabled={page <= 1}
              onClick={() => setPage(page - 1)}
              style={{
                padding: '6px 12px',
                borderRadius: '6px',
                border: '1px solid #cbd5e1',
                backgroundColor: '#fff',
                cursor: page <= 1 ? 'not-allowed' : 'pointer',
                fontSize: '12px',
              }}
            >
              Trang trước
            </button>
            <button
              disabled={page >= Math.ceil(total / limit)}
              onClick={() => setPage(page + 1)}
              style={{
                padding: '6px 12px',
                borderRadius: '6px',
                border: '1px solid #cbd5e1',
                backgroundColor: '#fff',
                cursor: page >= Math.ceil(total / limit) ? 'not-allowed' : 'pointer',
                fontSize: '12px',
              }}
            >
              Trang sau
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

