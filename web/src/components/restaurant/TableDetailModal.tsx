import React, { useState } from 'react';
import { StatusBadge } from '../StatusBadge';
import { X, Utensils, Users, Calendar, Clock, Phone, Eye } from 'lucide-react';

interface TableDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  table: any | null;
  reservations: any[];
  onSelectReservation: (res: any) => void;
}

export const TableDetailModal: React.FC<TableDetailModalProps> = ({
  isOpen,
  onClose,
  table,
  reservations,
  onSelectReservation,
}) => {
  const [historyDateFilter, setHistoryDateFilter] = useState<string>('');

  if (!isOpen || !table) return null;

  // Filter reservations for this specific table (comparing numeric IDs)
  const tableReservations = reservations.filter(
    (r) => Number(r.maBan) === Number(table.maBan)
  );

  const activeBookings = tableReservations.filter((r) =>
    ['CHO_XAC_NHAN', 'DA_XAC_NHAN', 'DA_DEN', 'DANG_SU_DUNG'].includes(r.trangThai)
  );

  const pastBookings = tableReservations.filter((r) =>
    ['DA_HOAN_TAT', 'DA_HUY', 'TU_CHOI', 'KHACH_KHONG_DEN'].includes(r.trangThai)
  );

  // Filter past bookings by date if selected
  const filteredPastBookings = pastBookings.filter((r) => {
    if (!historyDateFilter) return true;
    try {
      const d = new Date(r.thoiGianBatDau);
      const year = d.getFullYear();
      const month = String(d.getMonth() + 1).padStart(2, '0');
      const day = String(d.getDate()).padStart(2, '0');
      const dateStr = `${year}-${month}-${day}`;
      return dateStr === historyDateFilter;
    } catch (e) {
      return true;
    }
  });

  const isInactive = table.trangThai === 'TAM_NGUNG';
  const isOccupied = table.trangThai === 'DANG_SU_DUNG' || table.trangThai === 'DA_DEN';
  const isBooked = table.trangThai === 'DA_DAT';

  let statusBg = '#f0fdf4';
  let statusColor = '#16a34a';
  let statusText = 'Bàn trống';

  if (isInactive) {
    statusBg = '#f1f5f9';
    statusColor = '#64748b';
    statusText = 'Tạm ngưng';
  } else if (isOccupied) {
    statusBg = '#f3e8ff';
    statusColor = '#7e22ce';
    statusText = 'Đang phục vụ';
  } else if (isBooked) {
    statusBg = '#fff7ed';
    statusColor = '#ea580c';
    statusText = 'Đang đặt';
  }

  return (
    <div
      className="modal-backdrop"
      onClick={onClose}
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(15, 23, 42, 0.65)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1200,
        backdropFilter: 'blur(3px)',
        padding: '20px',
      }}
    >
      <div
        className="modal-content"
        onClick={(e) => e.stopPropagation()}
        style={{
          maxWidth: '680px',
          width: '100%',
          maxHeight: '90vh',
          overflowY: 'auto',
          borderRadius: '16px',
          padding: '24px',
          background: '#ffffff',
          boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
        }}
      >
        {/* Modal Header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #e2e8f0', paddingBottom: '16px', marginBottom: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div style={{ width: '42px', height: '42px', borderRadius: '12px', background: statusBg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Utensils size={22} color={statusColor} />
            </div>
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <h3 style={{ margin: 0, fontSize: '20px', fontWeight: 800, color: '#1e293b' }}>
                  {table.tenBan}
                </h3>
                <span style={{ fontSize: '12px', fontWeight: 700, padding: '3px 10px', borderRadius: '20px', background: statusBg, color: statusColor }}>
                  {statusText}
                </span>
              </div>
              <p style={{ margin: '2px 0 0 0', fontSize: '13px', color: '#64748b' }}>
                Sức chứa tối đa: <strong style={{ color: '#334155' }}>{table.sucChua} người</strong>
              </p>
            </div>
          </div>
          <button onClick={onClose} style={{ background: '#f1f5f9', border: 'none', borderRadius: '50%', width: '36px', height: '36px', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', color: '#64748b' }}>
            <X size={20} />
          </button>
        </div>

        {/* Modal Body: Active Reservations */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div>
            <h4 style={{ margin: '0 0 12px 0', fontSize: '15px', fontWeight: 700, color: '#1e293b', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Calendar size={18} color="#fc6011" /> Đơn Đặt Bàn Đang Hoạt Động ({activeBookings.length})
            </h4>

            {activeBookings.length === 0 ? (
              <div style={{ background: '#f8fafc', borderRadius: '12px', padding: '20px', textAlign: 'center', color: '#64748b', fontSize: '14px', border: '1px dashed #cbd5e1' }}>
                Hiện chưa có lịch đặt bàn active nào cho {table.tenBan}.
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                {activeBookings.map((res) => {
                  const start = new Date(res.thoiGianBatDau);
                  const end = new Date(res.thoiGianKetThuc);
                  const customerName = res.tenKhachHang || res.khachHang?.hoTen || 'Khách vãng lai';
                  const customerPhone = res.sdtKhachHang || res.khachHang?.sdt || '—';

                  return (
                    <div
                      key={res.maDatBan}
                      style={{
                        background: '#ffffff',
                        borderRadius: '12px',
                        padding: '14px 16px',
                        border: '1px solid #cbd5e1',
                        borderLeft: '4px solid #fc6011',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        gap: '12px',
                      }}
                    >
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <span style={{ fontWeight: 800, fontSize: '15px', color: '#fc6011' }}>
                            #DB{res.maDatBan}
                          </span>
                          <span style={{ fontWeight: 700, fontSize: '14px', color: '#1e293b' }}>
                            {customerName}
                          </span>
                          <StatusBadge status={res.trangThai} />
                        </div>

                        <div style={{ fontSize: '13px', color: '#475569', display: 'flex', alignItems: 'center', gap: '12px', flexWrap: 'wrap' }}>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <Phone size={13} color="#64748b" /> {customerPhone}
                          </span>
                          <span>•</span>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <Users size={13} color="#64748b" /> {res.soNguoi} người
                          </span>
                          <span>•</span>
                          <span style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#0284c7', fontWeight: 600 }}>
                            <Clock size={13} /> {!isNaN(start.getTime()) ? start.toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit' }) : ''} - {!isNaN(end.getTime()) ? end.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : ''}
                          </span>
                        </div>
                      </div>

                      <button
                        onClick={() => { onClose(); onSelectReservation(res); }}
                        className="btn"
                        style={{ background: '#f1f5f9', color: '#0369a1', border: '1px solid #e2e8f0', fontSize: '13px', padding: '6px 12px', borderRadius: '8px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 600 }}
                      >
                        <Eye size={14} /> Chi tiết
                      </button>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Past / Completed Reservations with Date Filter */}
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <h4 style={{ margin: 0, fontSize: '14px', fontWeight: 700, color: '#64748b' }}>
                Lịch Sử Đặt Bàn Gần Đây ({filteredPastBookings.length})
              </h4>

              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ fontSize: '12px', color: '#64748b', fontWeight: 600 }}>Lọc ngày:</span>
                <input
                  type="date"
                  value={historyDateFilter}
                  onChange={(e) => setHistoryDateFilter(e.target.value)}
                  style={{
                    padding: '4px 8px',
                    borderRadius: '6px',
                    border: '1px solid #cbd5e1',
                    fontSize: '12px',
                    color: '#334155',
                    cursor: 'pointer',
                  }}
                />
                {historyDateFilter && (
                  <button
                    onClick={() => setHistoryDateFilter('')}
                    style={{
                      background: '#fee2e2',
                      color: '#dc2626',
                      border: 'none',
                      borderRadius: '4px',
                      fontSize: '11px',
                      fontWeight: 700,
                      padding: '4px 8px',
                      cursor: 'pointer',
                    }}
                  >
                    Tất cả
                  </button>
                )}
              </div>
            </div>

            {filteredPastBookings.length === 0 ? (
              <div style={{ background: '#f8fafc', borderRadius: '8px', padding: '16px', textAlign: 'center', color: '#94a3b8', fontSize: '13px', border: '1px dashed #cbd5e1' }}>
                {historyDateFilter ? `Không có lịch sử đặt bàn ngày ${new Date(historyDateFilter).toLocaleDateString('vi-VN')}` : 'Chưa có lịch sử đặt bàn.'}
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', maxHeight: '200px', overflowY: 'auto' }}>
                {filteredPastBookings.map((res) => {
                  const start = new Date(res.thoiGianBatDau);
                  const customerName = res.tenKhachHang || res.khachHang?.hoTen || 'Khách vãng lai';

                  return (
                    <div
                      key={res.maDatBan}
                      style={{
                        background: '#f8fafc',
                        borderRadius: '8px',
                        padding: '10px 14px',
                        border: '1px solid #e2e8f0',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        fontSize: '13px',
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontWeight: 700, color: '#64748b' }}>#DB{res.maDatBan}</span>
                        <span style={{ fontWeight: 600, color: '#1e293b' }}>{customerName}</span>
                        <span style={{ color: '#64748b' }}>({res.soNguoi} khách)</span>
                        <span style={{ color: '#94a3b8' }}>- {!isNaN(start.getTime()) ? start.toLocaleDateString('vi-VN') : ''}</span>
                      </div>
                      <StatusBadge status={res.trangThai} />
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
