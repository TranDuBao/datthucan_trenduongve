import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { StatusBadge } from '../../components/StatusBadge';
import { OrderDetailModal } from '../../components/OrderDetailModal';
import { Search, Store } from 'lucide-react';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../utils/imageUtils';

export const AdminOrders: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [storeFilter, setStoreFilter] = useState('');
  const [stores, setStores] = useState<any[]>([]);
  const [usersList, setUsersList] = useState<any[]>([]);
  const [selectedOrder, setSelectedOrder] = useState<any | null>(null);

  useEffect(() => {
    apiFetch<any>('/admin/restaurants?limit=1000')
      .then((res) => {
        const list = res.data?.items || res.items || res.data || [];
        setStores(list);
      })
      .catch((err) => console.error(err));

    apiFetch<any>('/admin/users?limit=1000')
      .then((res) => {
        const list = res.data?.items || res.items || res.data || [];
        setUsersList(list);
      })
      .catch((err) => console.error(err));
  }, []);

  const fetchOrders = () => {
    setLoading(true);
    const query = new URLSearchParams({
      limit: '1000',
      search: search.trim(),
      status: statusFilter.trim(),
      storeId: storeFilter,
    }).toString();

    apiFetch<any>(`/admin/orders?${query}`)
      .then((res) => setData(res.data))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchOrders();
  }, [search, statusFilter, storeFilter]);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
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
        <div className="table-toolbar" style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
          <div className="search-input-group" style={{ flex: 1, minWidth: '240px' }}>
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm tên món, tên khách hàng, tên nhà hàng, mã đơn..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          {/* Store Filter Select Dropdown */}
          <select
            className="form-control"
            style={{ width: '220px', fontWeight: 600 }}
            value={storeFilter}
            onChange={(e) => setStoreFilter(e.target.value)}
          >
            <option value="">🏪 Tất cả nhà hàng ({stores.length})</option>
            {stores.map((s: any) => (
              <option key={s.maQuan} value={s.maQuan}>
                {s.tenQuan}
              </option>
            ))}
          </select>

          {/* Status Filter Select Dropdown */}
          <select
            className="form-control"
            style={{ width: '200px', fontWeight: 600 }}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="">📋 Tất cả trạng thái</option>
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
                <th style={{ width: '50px', textAlign: 'center' }}>STT</th>
                <th>Món Ăn</th>
                <th>Khách Hàng</th>
                <th>Nhà Hàng</th>
                <th>Tổng Tiền</th>
                <th>Hình Thức</th>
                <th>Thanh Toán</th>
                <th>Thời Gian Đặt</th>
                <th>Trạng Thái</th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((ord: any, idx: number) => {
                const firstItem = ord.items && ord.items.length > 0 ? ord.items[0] : null;
                const extraItemsCount = ord.items && ord.items.length > 1 ? ord.items.length - 1 : 0;

                // Resolve Customer Name
                let resolvedCustomerName = ord.tenKhachHang;
                let resolvedCustomerPhone = ord.sdtKhachHang || '';

                if (!resolvedCustomerName || resolvedCustomerName.startsWith('Khách hàng #')) {
                  const matchedUser = usersList.find(
                    (u: any) =>
                      u.maTaiKhoan === ord.maKhachHang ||
                      (u.khachHang && u.khachHang.maKhachHang === ord.maKhachHang)
                  );
                  if (matchedUser) {
                    resolvedCustomerName = matchedUser.khachHang?.hoTen || matchedUser.hoTen || matchedUser.tenDangNhap;
                    resolvedCustomerPhone = matchedUser.khachHang?.sdt || matchedUser.sdt || resolvedCustomerPhone;
                  }
                }

                // Resolve Store Name & Matched Store
                let resolvedStoreName = ord.tenQuan;
                const matchedStore = stores.find(
                  (s: any) => s.maQuan === ord.maQuan
                );
                if ((!resolvedStoreName || resolvedStoreName.startsWith('Nhà hàng #')) && matchedStore) {
                  resolvedStoreName = matchedStore.tenQuan;
                }

                // Resolve Food Name & Image strictly from DB
                const displayFoodName = firstItem?.tenMonAn || ord.tenMonAn || `Đơn hàng #${ord.maDonHang || ord.madonhang || ''}`;
                const displayFoodImg = firstItem?.img || '';

                return (
                  <tr
                    key={ord.maDonHang}
                    onClick={() => setSelectedOrder({
                      ...ord,
                      tenKhachHang: resolvedCustomerName || ord.tenKhachHang,
                      sdtKhachHang: resolvedCustomerPhone || ord.sdtKhachHang,
                      tenQuan: resolvedStoreName || ord.tenQuan,
                    })}
                    style={{ cursor: 'pointer' }}
                    title="Click để xem chi tiết đơn hàng"
                  >
                    <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{idx + 1}</td>

                    {/* Food Image & Name */}
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <img
                          src={getImageUrl(displayFoodImg, DEFAULT_IMAGE_PLACEHOLDER)}
                          alt=""
                          onError={handleImageError}
                          style={{ width: '42px', height: '42px', borderRadius: '8px', objectFit: 'cover', background: '#f1f5f9' }}
                        />
                        <div>
                          <div style={{ fontWeight: 700, color: '#0f172a' }}>
                            {displayFoodName}
                          </div>
                          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
                            x{firstItem?.soLuong || 1}
                            {extraItemsCount > 0 && (
                              <span style={{ marginLeft: '6px', color: '#fc6011', fontWeight: 700, background: '#fff4ee', padding: '2px 6px', borderRadius: '4px', fontSize: '11px' }}>
                                +{extraItemsCount} món khác
                              </span>
                            )}
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* Customer Name */}
                    <td>
                      <div style={{ fontWeight: 700, color: '#0f172a' }}>
                        {resolvedCustomerName || 'Khách vãng lai'}
                      </div>
                      {resolvedCustomerPhone && (
                        <div style={{ fontSize: '11px', color: '#64748b', marginTop: '2px' }}>{resolvedCustomerPhone}</div>
                      )}
                    </td>

                    {/* Store Name */}
                    <td>
                      <div style={{ fontWeight: 700, color: '#0f172a' }}>
                        {resolvedStoreName || 'Chưa xác định'}
                      </div>
                    </td>

                    <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(ord.tongTien)}</td>
                    <td><span className="badge badge-info">{ord.loaiDonHang === 'EAT_IN' ? 'Ăn Tại Quán' : 'Tự Đến Lấy'}</span></td>
                    <td>{ord.phuongThucThanhToan || 'COD'}</td>
                    <td>{new Date(ord.thoiGianDat).toLocaleString('vi-VN')}</td>
                    <td><StatusBadge status={ord.trangThai} /></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* Order Detail Modal */}
      <OrderDetailModal order={selectedOrder} onClose={() => setSelectedOrder(null)} />
    </div>
  );
};
