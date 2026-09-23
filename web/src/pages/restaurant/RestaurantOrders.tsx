import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { StatusBadge } from '../../components/StatusBadge';
import { Clock, CheckCircle, AlertTriangle, User, Phone, ShoppingBag } from 'lucide-react';

export const RestaurantOrders: React.FC = () => {
  const [orders, setOrders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');

  const fetchOrders = () => {
    setLoading(true);
    apiFetch<any>(`/restaurant/orders?status=${encodeURIComponent(statusFilter)}`)
      .then((res) => setOrders(res.data?.items || []))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchOrders();
  }, [statusFilter]);

  const handleUpdateStatus = async (maDonHang: number, newStatus: string) => {
    try {
      await apiFetch(`/restaurant/orders/${maDonHang}/status`, {
        method: 'PUT',
        body: JSON.stringify({ trangThai: newStatus }),
      });
      fetchOrders();
    } catch (err: any) {
      alert(err.message || 'Lỗi cập nhật trạng thái đơn');
    }
  };

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản Lý Đơn Hàng Nhà Hàng</h1>
          <p className="page-subtitle">Xử lý tiến trình chuẩn bị món & thời gian ghé lấy của khách hàng</p>
        </div>

        <select
          className="form-control"
          style={{ width: '220px' }}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
        >
          <option value="">Tất cả trạng thái</option>
          <option value="PENDING">Chờ xác nhận (PENDING)</option>
          <option value="CONFIRMED">Đã xác nhận (CONFIRMED)</option>
          <option value="PREPARING">Đang chuẩn bị (PREPARING)</option>
          <option value="READY_FOR_PICKUP">Chờ ghé lấy (READY_FOR_PICKUP)</option>
          <option value="COMPLETED">Hoàn tất (COMPLETED)</option>
          <option value="CANCELLED">Đã hủy (CANCELLED)</option>
        </select>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: '60px' }}><div className="loading-spinner" /></div>
      ) : orders.length === 0 ? (
        <div className="card-table">
          <div className="empty-state">Hiện không có đơn hàng nào cần xử lý</div>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: '16px' }}>
          {orders.map((ord) => (
            <div
              key={ord.maDonHang}
              style={{
                background: '#ffffff',
                border: '1px solid #e2e8f0',
                borderRadius: '14px',
                padding: '20px',
                boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', borderBottom: '1px solid #f1f5f9', paddingBottom: '12px', marginBottom: '14px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                  <div style={{ fontWeight: 800, fontSize: '18px', color: '#0f172a' }}>
                    Đơn #{ord.maDonHang}
                  </div>
                  <StatusBadge status={ord.trangThai} />
                  <span className="badge badge-info">{ord.loaiDonHang || 'PRE_ORDER'}</span>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: '#fffbeb', padding: '6px 14px', borderRadius: '20px', border: '1px solid #fef3c7' }}>
                  <Clock size={16} color="#d97706" />
                  <span style={{ fontSize: '13px', fontWeight: 800, color: '#b45309' }}>
                    HẸN GHÉ LẤY: {ord.thoiGianHenNhan ? new Date(ord.thoiGianHenNhan).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : 'Ghé Ngay'}
                  </span>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr 1.2fr', gap: '20px' }}>
                {/* Khách hàng */}
                <div>
                  <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', marginBottom: '6px' }}>Mã Khách Hàng</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 700, fontSize: '14px' }}>
                    <User size={16} color="#64748b" /> {ord.tenKhachHang}
                  </div>
                  {ord.sdtKhachHang && (
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', color: '#64748b', marginTop: '4px' }}>
                      <Phone size={14} color="#64748b" /> {ord.sdtKhachHang}
                    </div>
                  )}
                  <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '8px' }}>
                    Đặt lúc: {new Date(ord.thoiGianDat).toLocaleString('vi-VN')}
                  </div>
                </div>

                {/* Danh sách món */}
                <div>
                  <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', marginBottom: '6px' }}>Danh Sách Món Đặt</div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '6px' }}>
                    {ord.items && ord.items.length > 0 ? (
                      ord.items.map((item: any, idx: number) => (
                        <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', background: '#f8fafc', padding: '6px 10px', borderRadius: '6px' }}>
                          <span style={{ fontWeight: 600 }}>{item.tenMonAn}</span>
                          <span style={{ fontWeight: 700, color: '#fc6011' }}>x{item.soLuong} ({formatVND(item.donGia * item.soLuong)})</span>
                        </div>
                      ))
                    ) : (
                      <div style={{ fontSize: '12px', color: '#94a3b8' }}>Món ăn theo đơn hàng #{ord.maDonHang}</div>
                    )}
                  </div>
                </div>

                {/* Tổng tiền & Xử lý */}
                <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'space-between', alignItems: 'flex-end', borderLeft: '1px solid #f1f5f9', paddingLeft: '16px' }}>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>Tổng Tiền Đơn</div>
                    <div style={{ fontSize: '20px', fontWeight: 900, color: '#fc6011' }}>{formatVND(ord.tongTien)}</div>
                    <div style={{ fontSize: '11px', color: '#64748b' }}>Thanh toán: {ord.phuongThucThanhToan || 'COD'}</div>
                  </div>

                  {/* Nút hành động chuẩn nghiệp vụ */}
                  <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', justifyContent: 'flex-end', marginTop: '12px' }}>
                    {(ord.trangThai === 'PENDING' || ord.trangThai === 'chờ xử lý') && (
                      <>
                        <button className="btn btn-outline btn-sm" style={{ color: '#ef4444' }} onClick={() => handleUpdateStatus(ord.maDonHang, 'CANCELLED')}>Từ Chối</button>
                        <button className="btn btn-primary btn-sm" onClick={() => handleUpdateStatus(ord.maDonHang, 'CONFIRMED')}>✓ Xác Nhận Đơn</button>
                      </>
                    )}

                    {(ord.trangThai === 'CONFIRMED' || ord.trangThai === 'đã xác nhận') && (
                      <button className="btn btn-primary btn-sm" style={{ background: '#f59e0b' }} onClick={() => handleUpdateStatus(ord.maDonHang, 'PREPARING')}>🍳 Bắt Đầu Chuẩn Bị</button>
                    )}

                    {(ord.trangThai === 'PREPARING' || ord.trangThai === 'đang chuẩn bị') && (
                      <button className="btn btn-primary btn-sm" style={{ background: '#8b5cf6' }} onClick={() => handleUpdateStatus(ord.maDonHang, 'READY_FOR_PICKUP')}>🔔 Báo Sẵn Sàng Ghé Lấy</button>
                    )}

                    {(ord.trangThai === 'READY_FOR_PICKUP' || ord.trangThai === 'sẵn sàng ghé lấy' || ord.trangThai === 'Sẵn sàng') && (
                      <button className="btn btn-primary btn-sm" style={{ background: '#10b981' }} onClick={() => handleUpdateStatus(ord.maDonHang, 'COMPLETED')}>✓ Đã Giao Khách Lấy</button>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
