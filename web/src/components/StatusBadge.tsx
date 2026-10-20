import React from 'react';

interface StatusBadgeProps {
  status: string;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status }) => {
  const s = (status || '').toUpperCase().trim();

  // 1. Pending / Waiting for confirmation
  if (
    s === 'PENDING' ||
    s === 'CHỜ XỬ LÝ' ||
    s === 'CHO_XAC_NHAN' ||
    s === 'CHỜ XÁC NHẬN' ||
    s === 'CHO_PHE_DUYET' ||
    s === 'DANG_CHO'
  ) {
    return <span className="badge badge-warning">● Chờ xác nhận</span>;
  }

  // 2. Confirmed
  if (
    s === 'CONFIRMED' ||
    s === 'ĐÃ XÁC NHẬN' ||
    s === 'DA_XAC_NHAN' ||
    s === 'CONFIRM'
  ) {
    return <span className="badge badge-info">● Đã xác nhận</span>;
  }

  // 3. Preparing
  if (
    s === 'PREPARING' ||
    s === 'DANG_CHUAN_BI' ||
    s === 'ĐANG CHUẨN BỊ' ||
    s === 'PROCESSING' ||
    s === 'DANG_XU_LY'
  ) {
    return (
      <span
        className="badge"
        style={{
          background: '#fffbeb',
          color: '#b45309',
          border: '1px solid #fde68a',
          fontWeight: 600,
        }}
      >
        👨‍🍳 Đang chuẩn bị
      </span>
    );
  }

  // 4. Ready for Pickup
  if (
    s === 'READY_FOR_PICKUP' ||
    s === 'CHO_GHE_LAY' ||
    s === 'CHỜ GHÉ LẤY' ||
    s === 'READY' ||
    s === 'SAN_SANG'
  ) {
    return (
      <span
        className="badge"
        style={{
          background: '#f0f9ff',
          color: '#0284c7',
          border: '1px solid #bae6fd',
          fontWeight: 600,
        }}
      >
        🛍️ Chờ ghé lấy
      </span>
    );
  }

  // 5. Customer Arrived
  if (s === 'DA_DEN' || s === 'KHÁCH ĐÃ ĐẾN' || s === 'KHACH_DA_DEN') {
    return (
      <span
        className="badge"
        style={{
          background: '#e0f2fe',
          color: '#0369a1',
          fontWeight: 600,
        }}
      >
        ● Khách đã đến
      </span>
    );
  }

  // 6. In progress / Using
  if (s === 'DANG_SU_DUNG' || s === 'ĐANG SỬ DỤNG' || s === 'IN_PROGRESS') {
    return (
      <span
        className="badge"
        style={{
          background: '#f3e8ff',
          color: '#7e22ce',
          fontWeight: 600,
        }}
      >
        ● Đang sử dụng
      </span>
    );
  }

  // 7. Completed / Finished (Standardized to single ✓ Hoàn tất badge)
  if (
    s === 'HOAN_TAT' ||
    s === 'DA_HOAN_TAT' ||
    s === 'COMPLETED' ||
    s === 'PICKED_UP' ||
    s === 'HOAN_THANH' ||
    s === 'DA_HOAN_THANH' ||
    s === 'THÀNH CÔNG' ||
    s === 'THANH_CONG' ||
    s === 'ĐÃ LẤY MÓN' ||
    s === 'DA_LAY_MON' ||
    s === 'ĐÃ HOÀN THÀNH' ||
    s === 'HOÀN TẤT'
  ) {
    return <span className="badge badge-success">✓ Hoàn tất</span>;
  }

  // 8. Customer No-show
  if (s === 'KHACH_KHONG_DEN' || s === 'KHÁCH KHÔNG ĐẾN') {
    return (
      <span
        className="badge"
        style={{
          background: '#fff1f2',
          color: '#e11d48',
          fontWeight: 600,
        }}
      >
        ✕ Khách không đến
      </span>
    );
  }

  // 9. Rejected
  if (s === 'TU_CHOI' || s === 'TỪ CHỐI' || s === 'REJECTED') {
    return (
      <span
        className="badge"
        style={{
          background: '#f3f4f6',
          color: '#4b5563',
          fontWeight: 600,
        }}
      >
        ✕ Từ chối
      </span>
    );
  }

  // 10. Cancelled
  if (
    s === 'CANCELLED' ||
    s === 'CANCELED' ||
    s === 'DA_HUY' ||
    s === 'ĐÃ HỦY' ||
    s === 'HỦY'
  ) {
    return <span className="badge badge-danger">✕ Đã hủy</span>;
  }

  // 11. Soft Deleted
  if (s.includes('XÓA') || s.includes('XOA') || s === 'DELETED') {
    return (
      <span
        className="badge"
        style={{
          background: '#f1f5f9',
          color: '#64748b',
          border: '1px solid #cbd5e1',
          fontWeight: 600,
          display: 'inline-flex',
          alignItems: 'center',
          gap: '4px',
          padding: '4px 10px',
          borderRadius: '20px',
          fontSize: '12px',
        }}
      >
        🗑️ Đã xóa mềm
      </span>
    );
  }

  // 12. Store Open / Closed
  if (s.includes('MỞ CỬA') || s.includes('MO CUA') || s === 'OPEN') {
    return (
      <span
        className="badge badge-success"
        style={{
          background: '#ecfdf5',
          color: '#059669',
          border: '1px solid #a7f3d0',
          fontWeight: 700,
        }}
      >
        Mở cửa
      </span>
    );
  }

  if (
    s.includes('ĐÓNG CỬA') ||
    s.includes('DONG CUA') ||
    s.includes('NGƯNG') ||
    s === 'CLOSED'
  ) {
    return (
      <span
        className="badge badge-danger"
        style={{
          background: '#fef2f2',
          color: '#dc2626',
          border: '1px solid #fecaca',
          fontWeight: 700,
        }}
      >
        Đóng cửa
      </span>
    );
  }

  // 13. Roles
  if (s === 'ADMIN') {
    return <span className="badge badge-primary">ADMIN</span>;
  }
  if (s === 'CUAN_HANG' || s === 'CUA_HANG') {
    return <span className="badge badge-info">NHÀ HÀNG</span>;
  }
  if (s === 'KHACH_HANG') {
    return <span className="badge badge-success">KHÁCH HÀNG</span>;
  }

  return <span className="badge badge-info">{status}</span>;
};
