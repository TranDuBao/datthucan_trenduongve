import React, { useEffect, useState } from 'react';
import { MetricCard } from '../../components/MetricCard';
import { StatusBadge } from '../../components/StatusBadge';
import { apiFetch } from '../../api/apiClient';
import { Users, Store, ShoppingBag, DollarSign, Clock, CheckCircle2, AlertCircle } from 'lucide-react';

export const AdminDashboard: React.FC = () => {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiFetch<any>('/admin/stats')
      .then((res) => {
        setStats(res.data);
      })
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '60px' }}>
        <div className="loading-spinner" />
      </div>
    );
  }

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Dashboard Tổng Quan Hệ Thống</h1>
          <p className="page-subtitle">Thống kê dữ liệu thực tế toàn bộ hệ thống Smart City Food Route</p>
        </div>
      </div>

      <div className="grid-metrics">
        <MetricCard label="Tổng Người Dùng" value={stats?.totalUsers || 0} icon={Users} color="#3b82f6" bgColor="#eff6ff" />
        <MetricCard label="Tổng Nhà Hàng" value={stats?.totalRestaurants || 0} icon={Store} color="#10b981" bgColor="#ecfdf5" />
        <MetricCard label="Tổng Đơn Hàng" value={stats?.totalOrders || 0} icon={ShoppingBag} color="#8b5cf6" bgColor="#f3e8ff" />
        <MetricCard label="Đơn Trong Ngày" value={stats?.todayOrders || 0} icon={Clock} color="#f59e0b" bgColor="#fffbeb" />
        <MetricCard label="Tổng Doanh Thu" value={formatVND(stats?.totalRevenue || 0)} icon={DollarSign} color="#fc6011" bgColor="#fff4ee" />
        <MetricCard label="Đơn Đang Xử Lý" value={stats?.processingOrders || 0} icon={AlertCircle} color="#ec4899" bgColor="#fdf2f8" />
        <MetricCard label="Đơn Chờ Khách Lấy" value={stats?.pickupWaitingOrders || 0} icon={CheckCircle2} color="#06b6d4" bgColor="#ecfeff" />
        <MetricCard label="Nhà Hàng Mở Cửa" value={stats?.activeRestaurants || 0} icon={Store} color="#10b981" bgColor="#ecfdf5" />
      </div>

      <div className="card-table">
        <div className="table-toolbar">
          <div style={{ fontWeight: 700, fontSize: '15px' }}>Đơn Hàng Gần Đây</div>
        </div>

        {(!stats?.recentOrders || stats.recentOrders.length === 0) ? (
          <div className="empty-state">Chưa có đơn hàng nào trong hệ thống</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã Đơn</th>
                <th>Khách Hàng</th>
                <th>Nhà Hàng</th>
                <th>Tổng Tiền</th>
                <th>Thời Gian Đặt</th>
                <th>Trạng Thái</th>
              </tr>
            </thead>
            <tbody>
              {stats.recentOrders.map((ord: any) => (
                <tr key={ord.maDonHang}>
                  <td style={{ fontWeight: 700 }}>#{ord.maDonHang}</td>
                  <td>{ord.tenKhachHang || `Khách hàng #${ord.maKhachHang}`}</td>
                  <td style={{ fontWeight: 600 }}>{ord.tenQuan}</td>
                  <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(ord.tongTien)}</td>
                  <td>{new Date(ord.thoiGianDat).toLocaleString('vi-VN')}</td>
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
