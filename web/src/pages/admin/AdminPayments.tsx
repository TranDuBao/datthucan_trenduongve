import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { CreditCard, ChevronLeft, ChevronRight, RotateCcw, CheckCircle, AlertTriangle, Clock } from 'lucide-react';
import { StatusBadge } from '../../components/StatusBadge';

export const AdminPayments: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'payments' | 'refunds'>('payments');

  // Payments State
  const [data, setData] = useState<any>({ items: [], total: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState<number>(1);
  const [limit, setLimit] = useState<number>(15);

  // Refunds State
  const [refunds, setRefunds] = useState<any[]>([]);
  const [refundsLoading, setRefundsLoading] = useState(false);
  const [selectedRefund, setSelectedRefund] = useState<any | null>(null);
  const [refTxId, setRefTxId] = useState('');
  const [refNote, setRefNote] = useState('');
  const [updatingRefund, setUpdatingRefund] = useState(false);

  const fetchPayments = () => {
    setLoading(true);
    apiFetch<any>(`/admin/payments?page=${page}&limit=${limit}`)
      .then((res) => {
        setData(res.data || { items: [], total: 0, totalPages: 1 });
      })
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  const fetchRefunds = () => {
    setRefundsLoading(true);
    apiFetch<any>('/refunds')
      .then((res) => {
        setRefunds(res.data || []);
      })
      .catch((err) => console.error(err))
      .finally(() => setRefundsLoading(false));
  };

  useEffect(() => {
    if (activeTab === 'payments') {
      fetchPayments();
    } else {
      fetchRefunds();
    }
  }, [activeTab, page, limit]);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  const handleConfirmRefund = async (refundId: number, status: string) => {
    setUpdatingRefund(true);
    try {
      await apiFetch(`/refunds/${refundId}/status`, {
        method: 'PATCH',
        body: JSON.stringify({
          trangThai: status,
          maGiaoDich: refTxId.trim(),
          ghiChu: refNote.trim(),
        }),
      });
      setSelectedRefund(null);
      setRefTxId('');
      setRefNote('');
      fetchRefunds();
    } catch (err: any) {
      alert(err.message || 'Lỗi khi cập nhật trạng thái hoàn tiền');
    } finally {
      setUpdatingRefund(false);
    }
  };

  const getRefundBadge = (status: string) => {
    switch (status) {
      case 'HOAN_TIEN_THANH_CONG':
        return <span className="badge badge-success" style={{ background: '#dcfce7', color: '#15803d' }}>Đã hoàn tiền</span>;
      case 'CHO_XU_LY':
      case 'DANG_XU_LY':
        return <span className="badge badge-warning" style={{ background: '#fef3c7', color: '#b45309' }}>Chờ xử lý</span>;
      case 'CAN_DUYET_THU_CONG':
        return <span className="badge badge-danger" style={{ background: '#fee2e2', color: '#b91c1c' }}>Cần duyệt chi</span>;
      default:
        return <span className="badge badge-secondary">{status}</span>;
    }
  };

  const totalPages = data.totalPages || Math.ceil((data.total || 0) / limit) || 1;
  const startItem = (page - 1) * limit + 1;
  const endItem = Math.min(page * limit, data.total || 0);

  return (
    <div>
      <div className="page-header" style={{ marginBottom: '20px' }}>
        <div>
          <h1 className="page-title">Quản Lý Thanh Toán & Hoàn Tiền</h1>
          <p className="page-subtitle">Theo dõi lịch sử giao dịch và đối soát các yêu cầu hoàn tiền trong hệ thống</p>
        </div>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '8px' }}>
        <button
          onClick={() => { setActiveTab('payments'); setPage(1); }}
          style={{
            padding: '10px 18px',
            borderRadius: '8px',
            border: 'none',
            background: activeTab === 'payments' ? '#fc6011' : 'transparent',
            color: activeTab === 'payments' ? '#fff' : '#64748b',
            fontWeight: 700,
            fontSize: '14px',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
          }}
        >
          <CreditCard size={17} /> Lịch Sử Giao Dịch ({data.total || 0})
        </button>
        <button
          onClick={() => { setActiveTab('refunds'); }}
          style={{
            padding: '10px 18px',
            borderRadius: '8px',
            border: 'none',
            background: activeTab === 'refunds' ? '#fc6011' : 'transparent',
            color: activeTab === 'refunds' ? '#fff' : '#64748b',
            fontWeight: 700,
            fontSize: '14px',
            cursor: 'pointer',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
          }}
        >
          <RotateCcw size={17} /> Yêu Cầu Hoàn Tiền ({refunds.length})
        </button>
      </div>

      {activeTab === 'payments' ? (
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
      ) : (
        /* TAB 2: REFUNDS MANAGEMENT */
        <div className="card-table">
          {refundsLoading ? (
            <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
          ) : refunds.length === 0 ? (
            <div className="empty-state">Chưa có yêu cầu hoàn tiền nào</div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                  <th>Mã Hoàn Tiền</th>
                  <th>Đơn Hàng</th>
                  <th>Số Tiền Hoàn</th>
                  <th>Lý Do Hủy</th>
                  <th>Bên Hủy</th>
                  <th>Tài Khoản Nhận</th>
                  <th>Trạng Thái</th>
                  <th>Thời Gian Yêu Cầu</th>
                  <th style={{ textAlign: 'center' }}>Thao Tác</th>
                </tr>
              </thead>
              <tbody>
                {refunds.map((r: any, idx: number) => {
                  const mId = r.h_mahoantien || r.maHoanTien;
                  const oId = r.h_madonhang || r.maDonHang;
                  const amount = Number(r.h_sotienhoan || r.soTienHoan || 0);
                  const reason = r.h_lydohoan || r.lyDoHoan || 'Không có';
                  const reqBy = r.h_nguoiyeucau || r.nguoiYeuCau;
                  const status = r.h_trangthaihoantien || r.trangThaiHoanTien;
                  const bank = r.h_nganhangnhan || r.nganHangNhan;
                  const acc = r.h_sotaikhoannhan || r.soTaiKhoanNhan;
                  const accName = r.h_tenchutaikhoannhan || r.tenChuTaiKhoanNhan;
                  const time = r.h_thoigianyeucau || r.thoiGianYeuCau;

                  return (
                    <tr key={mId}>
                      <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{idx + 1}</td>
                      <td style={{ fontWeight: 700 }}>#{mId}</td>
                      <td style={{ fontWeight: 700 }}>#{oId}</td>
                      <td style={{ fontWeight: 700, color: '#dc2626' }}>{formatVND(amount)}</td>
                      <td style={{ maxWidth: '200px', fontSize: '13px', color: '#475569' }}>{reason}</td>
                      <td>
                        <span className="badge" style={{ background: '#f1f5f9', color: '#334155' }}>
                          {reqBy === 'KHACH_HANG' ? 'Khách hàng' : 'Cửa hàng'}
                        </span>
                      </td>
                      <td style={{ fontSize: '12px' }}>
                        {acc ? (
                          <div>
                            <strong>{bank}</strong>: {acc}
                            {accName && <div style={{ color: '#64748b' }}>({accName})</div>}
                          </div>
                        ) : (
                          <span style={{ color: '#94a3b8', fontStyle: 'italic' }}>Chờ khách cập nhật</span>
                        )}
                      </td>
                      <td>{getRefundBadge(status)}</td>
                      <td style={{ fontSize: '12px', color: '#64748b' }}>
                        {time ? new Date(time).toLocaleString('vi-VN') : '—'}
                      </td>
                      <td style={{ textAlign: 'center' }}>
                        {status !== 'HOAN_TIEN_THANH_CONG' ? (
                          <button
                            className="btn btn-sm"
                            onClick={() => setSelectedRefund({ id: mId, orderId: oId, amount, acc, bank })}
                            style={{
                              background: '#10b981',
                              color: '#fff',
                              border: 'none',
                              borderRadius: '6px',
                              padding: '5px 10px',
                              fontSize: '12px',
                              fontWeight: 700,
                              cursor: 'pointer',
                            }}
                          >
                            Xác Nhận Đã Hoàn
                          </button>
                        ) : (
                          <span style={{ color: '#10b981', fontSize: '12px', fontWeight: 700, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px' }}>
                            <CheckCircle size={14} /> Hoàn tất
                          </span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Modal Xác Nhận Đã Hoàn Tiền */}
      {selectedRefund && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 9999,
          }}
        >
          <div
            style={{
              background: '#fff',
              borderRadius: '16px',
              padding: '24px',
              maxWidth: '460px',
              width: '90%',
              boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1)',
            }}
          >
            <h3 style={{ fontSize: '18px', fontWeight: 700, marginBottom: '12px', color: '#0f172a' }}>
              Xác Nhận Đã Chuyển Tiền Hoàn
            </h3>
            <p style={{ fontSize: '13px', color: '#64748b', marginBottom: '16px' }}>
              Xác nhận đã chuyển khoản hoàn lại số tiền <strong>{formatVND(selectedRefund.amount)}</strong> cho đơn hàng <strong>#{selectedRefund.orderId}</strong>.
            </p>

            <div style={{ marginBottom: '14px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
                Mã tham chiếu ngân hàng / FT (Nếu có):
              </label>
              <input
                type="text"
                className="form-control"
                value={refTxId}
                onChange={(e) => setRefTxId(e.target.value)}
                placeholder="Ví dụ: FT260192847291..."
                style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
              />
            </div>

            <div style={{ marginBottom: '20px' }}>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
                Ghi chú đối soát:
              </label>
              <textarea
                className="form-control"
                rows={2}
                value={refNote}
                onChange={(e) => setRefNote(e.target.value)}
                placeholder="Ví dụ: Đã chuyển khoản qua app ngân hàng lúc 13:00..."
                style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button
                type="button"
                className="btn btn-secondary"
                onClick={() => setSelectedRefund(null)}
                disabled={updatingRefund}
                style={{ padding: '8px 16px', borderRadius: '8px' }}
              >
                Hủy bỏ
              </button>
              <button
                type="button"
                className="btn btn-primary"
                onClick={() => handleConfirmRefund(selectedRefund.id, 'HOAN_TIEN_THANH_CONG')}
                disabled={updatingRefund}
                style={{
                  padding: '8px 16px',
                  borderRadius: '8px',
                  background: '#10b981',
                  color: '#fff',
                  fontWeight: 700,
                  border: 'none',
                }}
              >
                {updatingRefund ? 'Đang cập nhật...' : 'Xác Nhận Đã Hoàn Tiền'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
