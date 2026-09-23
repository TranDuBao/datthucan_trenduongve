import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { MetricCard } from '../../components/MetricCard';
import { StatusBadge } from '../../components/StatusBadge';
import { ShoppingBag, Clock, Utensils, CheckCircle, DollarSign } from 'lucide-react';

export const RestaurantDashboard: React.FC = () => {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiFetch<any>('/restaurant/dashboard')
      .then((res) => setStats(res.data))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  }, []);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '60px' }}>
        <div className="loading-spinner" />
      </div>
    );
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Bảng Điều Khiển Nhà Hàng</h1>
          <p className="page-subtitle">Theo dõi tình hình vận hành & đơn hàng của quán hôm nay</p>
        </div>
      </div>

      <div className="grid-metrics">
        <MetricCard label="Đơn Hôm Nay" value={stats?.todayOrdersCount || 0} icon={ShoppingBag} color="#3b82f6" bgColor="#eff6ff" />
        <MetricCard label="Đơn Sắp Đến Giờ Lấy" value={stats?.upcomingPickupCount || 0} icon={Clock} color="#f59e0b" bgColor="#fffbeb" />
        <MetricCard label="Đơn Đang Chuẩn Bị" value={stats?.preparingCount || 0} icon={Utensils} color="#fc6011" bgColor="#fff4ee" />
        <MetricCard label="Đơn Đã Sẵn Sàng" value={stats?.readyCount || 0} icon={CheckCircle} color="#10b981" bgColor="#ecfdf5" />
        <MetricCard label="Doanh Thu Quán" value={formatVND(stats?.revenue || 0)} icon={DollarSign} color="#8b5cf6" bgColor="#f3e8ff" />
      </div>

      <div className="card-table">
        <div className="table-toolbar">
          <div style={{ fontWeight: 700, fontSize: '15px' }}>Đơn Hàng Gần Đây Của Quán</div>
        </div>

        {(!stats?.recentOrders || stats.recentOrders.length === 0) ? (
          <div className="empty-state">Chưa có đơn hàng nào cho quán</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã Đơn</th>
                <th>Khách Hàng</th>
                <th>Thời Gian Hẹn Lấy</th>
                <th>Tổng Tiền</th>
                <th>Trạng Thái</th>
              </tr>
            </thead>
            <tbody>
              {stats.recentOrders.map((ord: any) => (
                <tr key={ord.maDonHang}>
                  <td style={{ fontWeight: 700 }}>#{ord.maDonHang}</td>
                  <td>
                    <div style={{ fontWeight: 600 }}>{ord.tenKhachHang}</div>
                    <div style={{ fontSize: '11px', color: '#64748b' }}>{ord.sdtKhachHang}</div>
                  </td>
                  <td style={{ fontWeight: 700, color: '#f59e0b' }}>
                    ⏰ {ord.thoiGianHenNhan ? new Date(ord.thoiGianHenNhan).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' }) : 'Ghé liền'}
                  </td>
                  <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(ord.tongTien)}</td>
                  <td><StatusBadge status={ord.trangThai} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
