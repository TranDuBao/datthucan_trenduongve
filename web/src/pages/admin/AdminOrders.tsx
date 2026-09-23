import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { StatusBadge } from '../../components/StatusBadge';
import { Search } from 'lucide-react';

export const AdminOrders: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const fetchOrders = () => {
    setLoading(true);
    apiFetch<any>(`/admin/orders?search=${encodeURIComponent(search)}&status=${encodeURIComponent(statusFilter)}`)
      .then((res) => setData(res.data))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchOrders();
  }, [search, statusFilter]);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản Lý Tất Cả Đơn Hàng</h1>
          <p className="page-subtitle">Theo dõi trạng thái & chi tiết giao dịch đơn hàng toàn hệ thống</p>
        </div>
      </div>

      <div className="card-table">
        <div className="table-toolbar">
          <div className="search-input-group">
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm theo Mã đơn hàng..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <select
            className="form-control"
            style={{ width: '200px' }}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="">Tất cả trạng thái</option>
            <option value="PENDING">Chờ xác nhận (PENDING)</option>
            <option value="CONFIRMED">Đã xác nhận (CONFIRMED)</option>
            <option value="PREPARING">Đang chuẩn bị (PREPARING)</option>
            <option value="READY_FOR_PICKUP">Chờ ghé lấy (READY_FOR_PICKUP)</option>
            <option value="COMPLETED">Hoàn thành (COMPLETED)</option>
            <option value="CANCELLED">Đã hủy (CANCELLED)</option>
          </select>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : data.items.length === 0 ? (
          <div className="empty-state">Không có đơn hàng nào phù hợp</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã Đơn</th>
                <th>Mã Khách Hàng</th>
                <th>Mã Nhà Hàng</th>
                <th>Tổng Tiền</th>
                <th>Hình Thức Hẹn Nhanh</th>
                <th>Thanh Toán</th>
                <th>Thời Gian Đặt</th>
                <th>Trạng Thái</th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((ord: any) => (
                <tr key={ord.maDonHang}>
                  <td style={{ fontWeight: 700 }}>#{ord.maDonHang}</td>
                  <td>Khách #{ord.maKhachHang}</td>
                  <td>Quán #{ord.maQuan}</td>
                  <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(ord.tongTien)}</td>
                  <td><span className="badge badge-info">{ord.loaiDonHang || 'PRE_ORDER'}</span></td>
                  <td>{ord.phuongThucThanhToan || 'COD'}</td>
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
