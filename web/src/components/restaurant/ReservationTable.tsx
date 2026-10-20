import React from 'react';
import { CalendarDays } from 'lucide-react';
import {
  ReservationStatusBadge,
  getReservationStatusConfig,
  normalizeReservationStatus,
} from './ReservationStatusBadge';

interface ReservationTableProps {
  items: any[];
  startIndex: number;
  showActions: boolean;
  emptyTitle: string;
  emptySubtitle: string;
  actionLoading?: boolean;
  onSelectReservation: (res: any) => void;
  onAction?: (maDatBan: number, actionType: string) => void;
  footer?: React.ReactNode;
}

export const ReservationTable: React.FC<ReservationTableProps> = ({
  items,
  startIndex,
  showActions,
  emptyTitle,
  emptySubtitle,
  actionLoading = false,
  onSelectReservation,
  onAction,
  footer,
}) => {
  if (items.length === 0) {
    return (
      <div style={{ background: '#ffffff', borderRadius: '16px', border: '1px solid #e2e8f0', overflow: 'hidden' }}>
        <div style={{ padding: '56px', textAlign: 'center', color: '#64748b' }}>
          <CalendarDays size={48} color="#cbd5e1" style={{ marginBottom: '12px' }} />
          <h4 style={{ margin: '0 0 6px 0', fontSize: '16px', color: '#334155' }}>{emptyTitle}</h4>
          <p style={{ margin: 0, fontSize: '14px', color: '#94a3b8' }}>{emptySubtitle}</p>
        </div>
      </div>
    );
  }

  return (
    <div style={{ background: '#ffffff', borderRadius: '16px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '14px' }}>
          <thead>
            <tr style={{ background: '#f8fafc', borderBottom: '1px solid #e2e8f0', color: '#475569', fontSize: '13px', textTransform: 'uppercase' }}>
              <th style={{ padding: '14px 16px', width: '50px' }}>STT</th>
              <th style={{ padding: '14px 16px' }}>Mã Đặt Bàn</th>
              <th style={{ padding: '14px 16px' }}>Khách Hàng</th>
              <th style={{ padding: '14px 16px' }}>Số Điện Thoại</th>
              <th style={{ padding: '14px 16px' }}>Bàn</th>
              <th style={{ padding: '14px 16px' }}>Số Người</th>
              <th style={{ padding: '14px 16px' }}>Thời Gian Đến</th>
              <th style={{ padding: '14px 16px' }}>Giờ Kết Thúc</th>
              <th style={{ padding: '14px 16px' }}>Trạng Thái</th>
              <th style={{ padding: '14px 16px', textAlign: 'center' }}>Thao Tác</th>
            </tr>
          </thead>
          <tbody>
            {items.map((res, index) => {
              const stt = startIndex + index + 1;
              const start = new Date(res.thoiGianBatDau);
              const end = new Date(res.thoiGianKetThuc);
              const customerName = res.tenKhachHang || res.khachHang?.hoTen || 'Khách vãng lai';
              const customerPhone = res.sdtKhachHang || res.khachHang?.sdt || '—';
              const statusConfig = getReservationStatusConfig(res.trangThai);
              const normStatus = normalizeReservationStatus(res.trangThai);
              const isPending = normStatus === 'CHO_XAC_NHAN';

              return (
                <tr
                  key={res.maDatBan}
                  tabIndex={0}
                  role="button"
                  title={`Nhấn để xem chi tiết đặt bàn #DB${res.maDatBan}`}
                  onClick={() => onSelectReservation(res)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault();
                      onSelectReservation(res);
                    }
                  }}
                  style={{
                    borderBottom: '1px solid #f1f5f9',
                    borderLeft: `4px solid ${statusConfig.barColor}`,
                    background: isPending ? '#fffdf7' : '#ffffff',
                    cursor: 'pointer',
                    transition: 'background 0.15s ease',
                    outline: 'none',
                  }}
                  onMouseEnter={(e) => {
                    (e.currentTarget as HTMLElement).style.backgroundColor = isPending ? '#fef9c3' : '#f8fafc';
                  }}
                  onMouseLeave={(e) => {
                    (e.currentTarget as HTMLElement).style.backgroundColor = isPending ? '#fffdf7' : '#ffffff';
                  }}
                  onFocus={(e) => {
                    (e.currentTarget as HTMLElement).style.backgroundColor = isPending ? '#fef9c3' : '#f8fafc';
                  }}
                  onBlur={(e) => {
                    (e.currentTarget as HTMLElement).style.backgroundColor = isPending ? '#fffdf7' : '#ffffff';
                  }}
                >
                  <td style={{ padding: '14px 16px', color: '#64748b', fontWeight: 600 }}>{stt}</td>
                  <td style={{ padding: '14px 16px', fontWeight: 700, color: '#fc6011' }}>#DB{res.maDatBan}</td>
                  <td style={{ padding: '14px 16px', fontWeight: 600, color: '#1e293b' }}>{customerName}</td>
                  <td style={{ padding: '14px 16px', color: '#475569' }}>{customerPhone}</td>
                  <td style={{ padding: '14px 16px', fontWeight: 700, color: '#0369a1' }}>
                    {res.ban?.tenBan || `Bàn #${res.maBan}`}
                  </td>
                  <td style={{ padding: '14px 16px', color: '#334155', fontWeight: 600 }}>{res.soNguoi} người</td>
                  <td style={{ padding: '14px 16px', color: '#15803d', fontWeight: 600 }}>
                    {!isNaN(start.getTime()) ? start.toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' }) : 'N/A'}
                  </td>
                  <td style={{ padding: '14px 16px', color: '#64748b' }}>
                    {!isNaN(end.getTime()) ? end.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : 'N/A'}
                  </td>
                  <td style={{ padding: '14px 16px' }}>
                    <ReservationStatusBadge status={res.trangThai} />
                  </td>
                  <td style={{ padding: '14px 16px', textAlign: 'center' }} onClick={(e) => e.stopPropagation()}>
                    {showActions && isPending && onAction ? (
                      <div style={{ display: 'inline-flex', gap: '6px', alignItems: 'center' }}>
                        <button
                          type="button"
                          disabled={actionLoading}
                          onClick={(e) => {
                            e.stopPropagation();
                            onAction(res.maDatBan, 'reject');
                          }}
                          className="btn"
                          style={{
                            padding: '5px 10px',
                            fontSize: '12px',
                            color: '#ef4444',
                            border: '1px solid #fca5a5',
                            background: '#ffffff',
                            borderRadius: '7px',
                            fontWeight: 600,
                            cursor: 'pointer',
                          }}
                          title="Từ chối đặt bàn"
                        >
                          Từ chối
                        </button>
                        <button
                          type="button"
                          disabled={actionLoading}
                          onClick={(e) => {
                            e.stopPropagation();
                            onAction(res.maDatBan, 'confirm');
                          }}
                          className="btn btn-primary"
                          style={{
                            padding: '5px 12px',
                            fontSize: '12px',
                            background: '#16a34a',
                            borderColor: '#16a34a',
                            color: '#ffffff',
                            borderRadius: '7px',
                            fontWeight: 600,
                            cursor: 'pointer',
                          }}
                          title="Xác nhận đặt bàn"
                        >
                          Xác nhận
                        </button>
                      </div>
                    ) : (
                      <span style={{ color: '#94a3b8', fontSize: '13px' }}>—</span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {footer}
    </div>
  );
};
