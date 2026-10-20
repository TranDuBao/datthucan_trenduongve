import React, { useState, useEffect } from 'react';
import { ShoppingBag, Clock, User, Store, CreditCard, X, MapPin, CheckCircle } from 'lucide-react';
import { StatusBadge } from './StatusBadge';
import { apiFetch } from '../api/apiClient';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../utils/imageUtils';

interface OrderDetailModalProps {
  order: any | null;
  onClose: () => void;
  onUpdateStatus?: (maDonHang: number, newStatus: string, actionLabel: string) => void;
}

export const OrderDetailModal: React.FC<OrderDetailModalProps> = ({ order, onClose, onUpdateStatus }) => {
  const [mouseDownTarget, setMouseDownTarget] = useState<EventTarget | null>(null);
  const [detailItems, setDetailItems] = useState<any[]>(order?.items || []);
  const [loadingItems, setLoadingItems] = useState(false);

  useEffect(() => {
    if (order && order.maDonHang) {
      if (order.items && order.items.length > 0) {
        setDetailItems(order.items);
      } else {
        setLoadingItems(true);
        apiFetch<any>(`/admin/orders?search=${order.maDonHang}`)
          .then((res) => {
            const list = res.data?.items || res.items || res.data || [];
            const found = list.find((o: any) => o.maDonHang === order.maDonHang || o.madonhang === order.maDonHang);
            if (found && found.items && found.items.length > 0) {
              setDetailItems(found.items);
            }
          })
          .catch(() => { })
          .finally(() => setLoadingItems(false));
      }
    }
  }, [order?.maDonHang, order?.items]);

  if (!order) return null;

  const normalizeStatusKey = (st?: string): string => {
    if (!st) return 'PENDING';
    const s = st.trim().toUpperCase();
    if (s === 'CHO_XAC_NHAN' || s === 'PENDING' || s.includes('CHỜ') || s === 'CHỜ XÁC NHẬN' || s === 'CHỜ XỬ LÝ') return 'PENDING';
    if (s === 'DA_XAC_NHAN' || s === 'CONFIRMED' || s.includes('XÁC NHẬN')) return 'CONFIRMED';
    if (s === 'DANG_CHUAN_BI' || s === 'PREPARING' || s.includes('CHUẨN BỊ') || s.includes('CHƯA LÀM')) return 'PREPARING';
    if (s === 'SAN_SANG' || s === 'READY' || s === 'READY_FOR_PICKUP' || s.includes('SẴN SÀNG')) return 'READY_FOR_PICKUP';
    if (s === 'HOAN_TAT' || s === 'HOAN_THANH' || s === 'COMPLETED' || s === 'PICKED_UP' || s.includes('HOÀN')) return 'COMPLETED';
    if (s === 'DA_HUY' || s === 'CANCELLED' || s.includes('HỦY')) return 'CANCELLED';
    return s;
  };

  const normSt = normalizeStatusKey(order.trangThai);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  return (
    <div
      className="modal-backdrop"
      style={{ zIndex: 1100 }}
      onMouseDown={(e) => setMouseDownTarget(e.target)}
      onClick={(e) => {
        if (e.target === e.currentTarget && mouseDownTarget === e.currentTarget) {
          onClose();
        }
      }}
    >
      <div
        className="modal-content"
        style={{ maxWidth: '640px', padding: '0', borderRadius: '16px', overflow: 'hidden' }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Modal Header */}
        <div
          style={{
            background: 'linear-gradient(135deg, #1e293b 0%, #0f172a 100%)',
            color: '#ffffff',
            padding: '20px 24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '10px',
                background: 'rgba(252, 96, 17, 0.2)',
                border: '1px solid #fc6011',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <ShoppingBag size={22} color="#fc6011" />
            </div>
            <div>
              <div style={{ fontSize: '18px', fontWeight: 800 }}>Chi Tiết Đơn Hàng #{order.maDonHang}</div>
              <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '2px' }}>
                Loại hình: <span style={{ color: '#38bdf8', fontWeight: 700 }}>{order.loaiDonHang || 'PRE_ORDER (Ghé Lấy)'}</span>
              </div>
            </div>
          </div>
          <button
            onClick={onClose}
            style={{
              background: 'rgba(255,255,255,0.1)',
              border: 'none',
              color: '#ffffff',
              borderRadius: '50%',
              width: '32px',
              height: '32px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
            }}
          >
            <X size={18} />
          </button>
        </div>

        {/* Modal Body */}
        <div style={{ padding: '24px', maxHeight: '75vh', overflowY: 'auto' }}>
          {/* Status & Timing Banner */}
          <div
            style={{
              background: '#f8fafc',
              border: '1px solid #e2e8f0',
              borderRadius: '12px',
              padding: '16px',
              marginBottom: '20px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: '12px',
            }}
          >
            <div>
              <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
                Trạng Thái Đơn Hàng
              </div>
              <div style={{ marginTop: '4px' }}>
                <StatusBadge status={order.trangThai} />
              </div>
            </div>

            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: '#fffbeb', padding: '8px 14px', borderRadius: '8px', border: '1px solid #fef3c7' }}>
              <Clock size={16} color="#d97706" />
              <div>
                <div style={{ fontSize: '11px', color: '#92400e', fontWeight: 600 }}>Thời Gian Ghé Lấy:</div>
                <div style={{ fontSize: '13px', fontWeight: 800, color: '#b45309' }}>
                  {order.thoiGianHenNhan ? new Date(order.thoiGianHenNhan).toLocaleString('vi-VN') : 'Ghé Lấy Ngay'}
                </div>
              </div>
            </div>
          </div>

          {/* Customer & Merchant Information Grid */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '20px' }}>
            <div style={{ background: '#f1f5f9', padding: '14px', borderRadius: '10px' }}>
              <div style={{ fontSize: '11px', fontWeight: 700, color: '#475569', textTransform: 'uppercase', marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <User size={14} color="#fc6011" /> Thông Tin Khách Hàng
              </div>
              <div style={{ fontSize: '14px', fontWeight: 700, color: '#0f172a' }}>
                {order.tenKhachHang || order.khachHang?.hoTen || `Khách hàng #${order.maKhachHang}`}
              </div>
              <div style={{ fontSize: '12px', color: '#64748b', marginTop: '4px' }}>
                SDT: {order.sdtKhachHang || order.khachHang?.sdt || 'Chưa cập nhật'}
              </div>
              <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
                Email: {order.khachHang?.email || '—'}
              </div>
            </div>

            <div style={{ background: '#f1f5f9', padding: '14px', borderRadius: '10px' }}>
              <div style={{ fontSize: '11px', fontWeight: 700, color: '#475569', textTransform: 'uppercase', marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Store size={14} color="#fc6011" /> Thông Tin Nhà Hàng
              </div>
              <div style={{ fontSize: '14px', fontWeight: 700, color: '#0f172a' }}>
                {order.tenQuan || order.cuaHang?.tenQuan || `Nhà hàng #${order.maQuan}`}
              </div>
              <div style={{ fontSize: '12px', color: '#64748b', marginTop: '4px' }}>
                Địa chỉ: {order.cuaHang?.diaChi || 'Trụ sở cửa hàng'}
              </div>
              <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
                SDT: {order.cuaHang?.sdt || '—'}
              </div>
            </div>
          </div>

          {/* Items Table */}
          <div style={{ marginBottom: '20px' }}>
            <div style={{ fontSize: '13px', fontWeight: 700, color: '#334155', marginBottom: '10px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <ShoppingBag size={15} color="#fc6011" /> Danh Sách Món Ăn Trong Đơn
            </div>

            <div style={{ border: '1px solid #e2e8f0', borderRadius: '10px', overflow: 'hidden' }}>
              <table className="data-table" style={{ margin: 0 }}>
                <thead>
                  <tr style={{ background: '#f8fafc' }}>
                    <th style={{ width: '54px', textAlign: 'center' }}>Hình Ảnh</th>
                    <th>Tên Món Ăn</th>
                    <th style={{ textAlign: 'center' }}>Số Lượng</th>
                    <th style={{ textAlign: 'right' }}>Đơn Giá</th>
                    <th style={{ textAlign: 'right' }}>Thành Tiền</th>
                  </tr>
                </thead>
                <tbody>
                  {detailItems && detailItems.length > 0 ? (
                    detailItems.map((item: any, idx: number) => {
                      const price = Number(item.donGia || item.gia || 0);
                      const qty = Number(item.soLuong || item.soluong || 1);
                      return (
                        <tr key={idx}>
                          <td style={{ textAlign: 'center' }}>
                            <img
                              src={getImageUrl(item.img || item.monAn?.img, DEFAULT_IMAGE_PLACEHOLDER)}
                              alt=""
                              onError={handleImageError}
                              style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover', background: '#f1f5f9' }}
                            />
                          </td>
                          <td style={{ fontWeight: 600, color: '#0f172a' }}>{item.tenMonAn || item.monAn?.tenMonAn || `Món #${item.maMonAn}`}</td>
                          <td style={{ textAlign: 'center', fontWeight: 700 }}>x{qty}</td>
                          <td style={{ textAlign: 'right', color: '#64748b' }}>{formatVND(price)}</td>
                          <td style={{ textAlign: 'right', fontWeight: 700, color: '#fc6011' }}>
                            {formatVND(price * qty)}
                          </td>
                        </tr>
                      );
                    })
                  ) : loadingItems ? (
                    <tr>
                      <td colSpan={5} style={{ textAlign: 'center', color: '#64748b', padding: '16px' }}>
                        Đang tải danh sách món ăn...
                      </td>
                    </tr>
                  ) : (
                    <tr>
                      <td colSpan={5} style={{ textAlign: 'center', color: '#94a3b8', padding: '16px' }}>
                        Chi tiết đơn hàng #{order.maDonHang} • Tổng tiền: {formatVND(order.tongTien)}
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>

          {/* Order Financial Breakdown */}
          <div
            style={{
              background: '#fff7ed',
              border: '1px solid #ffedd5',
              borderRadius: '12px',
              padding: '16px',
              marginBottom: '16px',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#64748b', marginBottom: '6px' }}>
              <span>Tạm tính:</span>
              <span style={{ fontWeight: 700, color: '#334155' }}>{formatVND(order.tamTinh || order.tongTien)}</span>
            </div>
            {order.voucherInfo && (
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', color: '#10b981', marginBottom: '6px' }}>
                <span>Giảm giá Voucher ({order.voucherInfo.maCode}):</span>
                <span style={{ fontWeight: 700 }}>
                  -{order.voucherInfo.loaiGiam === 'PERCENT' ? `${order.voucherInfo.giamGia}%` : formatVND(order.voucherInfo.giamGia)}
                </span>
              </div>
            )}
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                paddingTop: '10px',
                borderTop: '1px dashed #fed7aa',
                marginTop: '6px',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <CreditCard size={18} color="#ea580c" />
                <div>
                  <div style={{ fontSize: '11px', color: '#c2410c', fontWeight: 600 }}>Phương Thức Thanh Toán</div>
                  <div style={{ fontSize: '13px', fontWeight: 800, color: '#9a3412' }}>
                    {order.phuongThucThanhToan || 'Thanh toán khi nhận (COD)'}
                  </div>
                </div>
              </div>

              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '11px', color: '#c2410c', fontWeight: 700, textTransform: 'uppercase' }}>TỔNG CỘNG THANH TOÁN</div>
                <div style={{ fontSize: '20px', fontWeight: 900, color: '#ea580c' }}>
                  {formatVND(order.tongTien)}
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Modal Footer */}
        <div
          style={{
            padding: '16px 24px',
            background: '#f8fafc',
            borderTop: '1px solid #e2e8f0',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <div style={{ display: 'flex', gap: '8px' }}>
            {onUpdateStatus && (
              <>
                {normSt === 'PENDING' && (
                  <>
                    <button
                      className="btn btn-outline"
                      onClick={() => {
                        onUpdateStatus(order.maDonHang, 'DA_HUY', 'Đã Hủy');
                        onClose();
                      }}
                      style={{ color: '#ef4444', borderColor: '#fecaca', fontSize: '13px' }}
                    >
                      Từ Chối Đơn
                    </button>
                    <button
                      className="btn btn-primary"
                      onClick={() => {
                        onUpdateStatus(order.maDonHang, 'DA_XAC_NHAN', 'Đã Xác Nhận');
                        onClose();
                      }}
                      style={{ background: '#3b82f6', border: 'none', fontSize: '13px' }}
                    >
                      ✓ Xác Nhận Đơn
                    </button>
                  </>
                )}

                {normSt === 'CONFIRMED' && (
                  <button
                    className="btn btn-primary"
                    onClick={() => {
                      onUpdateStatus(order.maDonHang, 'DANG_CHUAN_BI', 'Đang Chuẩn Bị');
                      onClose();
                    }}
                    style={{ background: '#f59e0b', border: 'none', fontSize: '13px' }}
                  >
                    🍳 Chuẩn Bị Món
                  </button>
                )}

                {normSt === 'PREPARING' && (
                  <button
                    className="btn btn-primary"
                    onClick={() => {
                      onUpdateStatus(order.maDonHang, 'SAN_SANG', 'Sẵn Sàng Ghé Lấy');
                      onClose();
                    }}
                    style={{ background: '#8b5cf6', border: 'none', fontSize: '13px' }}
                  >
                    🔔 Món Đã Sẵn Sàng
                  </button>
                )}

                {normSt === 'READY_FOR_PICKUP' && (
                  <button
                    className="btn btn-primary"
                    onClick={() => {
                      onUpdateStatus(order.maDonHang, 'HOAN_TAT', 'Hoàn Thành');
                      onClose();
                    }}
                    style={{ background: '#10b981', border: 'none', fontSize: '13px' }}
                  >
                    ✓ Đã Giao Khách
                  </button>
                )}
              </>
            )}
          </div>

          <button className="btn btn-outline" onClick={onClose} style={{ minWidth: '100px' }}>
            Đóng Chi Tiết
          </button>
        </div>
      </div>
    </div>
  );
};
