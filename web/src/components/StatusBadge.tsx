import React from 'react';

interface StatusBadgeProps {
  status: string;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status }) => {
  const s = (status || '').toUpperCase();

  if (s === 'PENDING' || s === 'CHỜ XỬ LÝ') {
    return <span className="badge badge-warning">● Chờ xác nhận</span>;
  }
  if (s === 'CONFIRMED' || s === 'ĐÃ XÁC NHẬN') {
    return <span className="badge badge-info">● Đã xác nhận</span>;
  }
  if (s === 'PREPARING' || s === 'ĐANG CHUẨN BỊ') {
    return <span className="badge badge-primary">● Đang chuẩn bị</span>;
  }
  if (s === 'READY_FOR_PICKUP' || s === 'SẴN SÀNG GHÉ LẤY' || s === 'SẴN SÀNG') {
    return <span className="badge badge-warning" style={{ background: '#f3e8ff', color: '#7e22ce' }}>● Chờ khách lấy</span>;
  }
  if (s === 'PICKED_UP' || s === 'COMPLETED' || s === 'HOAN_THANH' || s === 'THÀNH CÔNG' || s === 'ĐÃ LẤY MÓN') {
    return <span className="badge badge-success">✓ Hoàn tất</span>;
  }
  if (s === 'CANCELLED' || s === 'ĐÃ HỦY' || s === 'HỦY') {
    return <span className="badge badge-danger">✕ Đã hủy</span>;
  }
  if (s === 'ADMIN') {
    return <span className="badge badge-primary">ADMIN</span>;
  }
  if (s === 'CUAN_HANG') {
    return <span className="badge badge-info">NHÀ HÀNG</span>;
  }
  if (s === 'KHACH_HANG') {
    return <span className="badge badge-success">KHÁCH HÀNG</span>;
  }

  return <span className="badge badge-info">{status}</span>;
};
