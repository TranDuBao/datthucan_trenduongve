import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { CreditCard, ChevronLeft, ChevronRight } from 'lucide-react';
import { StatusBadge } from '../../components/StatusBadge';

export const AdminPayments: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState<number>(1);
  const [limit, setLimit] = useState<number>(15);

  const fetchPayments = () => {
    setLoading(true);
    apiFetch<any>(`/admin/payments?page=${page}&limit=${limit}`)
      .then((res) => {
        setData(res.data || { items: [], total: 0, totalPages: 1 });
      })
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchPayments();
  }, [page, limit]);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  const totalPages = data.totalPages || Math.ceil((data.total || 0) / limit) || 1;
  const startItem = (page - 1) * limit + 1;
  const endItem = Math.min(page * limit, data.total || 0);

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản Lý Thanh Toán & Dòng Tiền</h1>
          <p className="page-subtitle">Lịch sử giao dịch VietQR / PayOS / Cash trong hệ thống ({data.total || 0} giao dịch)</p>
        </div>
      </div>

      <div className="card-table">
        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : data.items.length === 0 ? (
          <div className="empty-state">Chưa có lịch sử giao dịch thanh toán nào</div>
        ) : (
          <>
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                  <th>Mã Thanh Toán</th>
                  <th>Mã Đơn Hàng</th>
                  <th>Phương Thức</th>
                  <th>Số Tiền</th>
                  <th>Trạng Thái</th>
                  <th>Thời Gian Giao Dịch</th>
                </tr>
              </thead>
              <tbody>
                {data.items.map((p: any, idx: number) => (
                  <tr key={p.maThanhToan}>
                    <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>
                      {(page - 1) * limit + idx + 1}
                    </td>
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

            {/* Pagination footer */}
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                padding: '16px 20px',
                borderTop: '1px solid #e2e8f0',
                background: '#f8fafc',
                flexWrap: 'wrap',
                gap: '12px',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#64748b' }}>
                <span>
                  Hiển thị <strong>{data.total > 0 ? startItem : 0}</strong> - <strong>{endItem}</strong> trong <strong>{data.total || 0}</strong> giao dịch
                </span>
                <span style={{ margin: '0 4px' }}>•</span>
                <span>Số dòng:</span>
                <select
                  value={limit}
                  onChange={(e) => {
                    setLimit(Number(e.target.value));
                    setPage(1);
                  }}
                  style={{
                    padding: '4px 8px',
                    borderRadius: '6px',
                    border: '1px solid #cbd5e1',
                    fontSize: '12px',
                    background: '#fff',
                  }}
                >
                  <option value={10}>10</option>
                  <option value={15}>15</option>
                  <option value={25}>25</option>
                  <option value={50}>50</option>
                </select>
              </div>

              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <button
                  className="btn btn-secondary"
                  onClick={() => setPage((p) => Math.max(p - 1, 1))}
                  disabled={page <= 1}
                  style={{
                    padding: '6px 10px',
                    fontSize: '12px',
                    opacity: page <= 1 ? 0.5 : 1,
                    borderRadius: '7px',
                    cursor: page <= 1 ? 'not-allowed' : 'pointer',
                  }}
                >
                  <ChevronLeft size={15} />
                </button>

                {Array.from({ length: totalPages }, (_, i) => i + 1)
                  .filter((p) => p === 1 || p === totalPages || Math.abs(p - page) <= 2)
                  .map((p, idx, arr) => {
                    const prev = arr[idx - 1];
                    const showEllipsis = prev && p - prev > 1;

                    return (
                      <React.Fragment key={p}>
                        {showEllipsis && <span style={{ padding: '0 4px', color: '#94a3b8', fontSize: '12px' }}>...</span>}
                        <button
                          onClick={() => setPage(p)}
                          style={{
                            minWidth: '32px',
                            height: '32px',
                            borderRadius: '8px',
                            border: page === p ? 'none' : '1px solid #cbd5e1',
                            background: page === p ? '#fc6011' : '#ffffff',
                            color: page === p ? '#ffffff' : '#334155',
                            fontWeight: page === p ? 700 : 600,
                            fontSize: '13px',
                            cursor: 'pointer',
                          }}
                        >
                          {p}
                        </button>
                      </React.Fragment>
                    );
                  })}

                <button
                  className="btn btn-secondary"
                  onClick={() => setPage((p) => Math.min(p + 1, totalPages))}
                  disabled={page >= totalPages}
                  style={{
                    padding: '6px 10px',
                    fontSize: '12px',
                    opacity: page >= totalPages ? 0.5 : 1,
                    borderRadius: '7px',
                    cursor: page >= totalPages ? 'not-allowed' : 'pointer',
                  }}
                >
                  <ChevronRight size={15} />
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};
