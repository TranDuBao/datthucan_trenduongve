import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { CreditCard } from 'lucide-react';
import { StatusBadge } from '../../components/StatusBadge';

export const AdminPayments: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    apiFetch<any>('/admin/payments')
      .then((res) => setData(res.data))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  }, []);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản Lý Thanh Toán & Dòng Tiền</h1>
          <p className="page-subtitle">Lịch sử giao dịch VietQR / PayOS / Cash trong hệ thống</p>
        </div>
      </div>

      <div className="card-table">
        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : data.items.length === 0 ? (
          <div className="empty-state">Chưa có lịch sử giao dịch thanh toán nào</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã Thanh Toán</th>
                <th>Mã Đơn Hàng</th>
                <th>Phương Thức</th>
                <th>Số Tiền</th>
                <th>Trạng Thái</th>
                <th>Thời Gian Giao Dịch</th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((p: any) => (
                <tr key={p.maThanhToan}>
                  <td style={{ fontWeight: 700 }}>#{p.maThanhToan}</td>
                  <td style={{ fontWeight: 700 }}>#{p.maDonHang}</td>
                  <td><span className="badge badge-info">{p.phuongThuc}</span></td>
                  <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(p.soTien)}</td>
                  <td><StatusBadge status={p.trangThai} /></td>
                  <td>{p.ngayThanhToan ? new Date(p.ngayThanhToan).toLocaleString('vi-VN') : 'Mới cập nhật'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
