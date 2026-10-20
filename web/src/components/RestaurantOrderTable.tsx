import React, { useState, useRef } from 'react';
import { Clock, PackageX, Phone, XCircle, Store, User, Trash2 } from 'lucide-react';
import {
  OrderStatusBadge,
  normalizeOrderStatus,
  getOrderStatusConfig,
} from './OrderStatusBadge';

export interface CancellationInfo {
  source: 'CUSTOMER' | 'RESTAURANT';
  label: string;
  badgeBg: string;
  badgeColor: string;
  badgeBorder: string;
  reason: string;
}

export const getCancellationSource = (lyDoHuy?: string): CancellationInfo => {
  const text = (lyDoHuy || '').trim();
  const lower = text.toLowerCase();

  const isRestaurant =
    lower.startsWith('quán') ||
    lower.startsWith('[quán') ||
    lower.startsWith('chủ quán') ||
    lower.startsWith('[chủ quán') ||
    lower.includes('quán hủy') ||
    lower.includes('chủ quán hủy') ||
    lower.includes('nhà hàng') ||
    lower.includes('hết món') ||
    lower.includes('từ chối') ||
    lower.includes('quán tạm thời');

  if (isRestaurant) {
    const clean = text
      .replace(/^\[?(quán|chủ quán)\s*(hủy)?\]?:?\s*/i, '')
      .replace(/^từ chối:?\s*/i, '')
      .trim();
    return {
      source: 'RESTAURANT',
      label: 'Chủ quán hủy',
      badgeBg: '#fff1f2',
      badgeColor: '#e11d48',
      badgeBorder: '#fecdd3',
      reason: clean || 'Quán hủy đơn',
    };
  }

  const clean = text
    .replace(/^\[?(khách|khách hàng)\s*(hủy)?\]?:?\s*/i, '')
    .trim();
  return {
    source: 'CUSTOMER',
    label: 'Khách hủy',
    badgeBg: '#eff6ff',
    badgeColor: '#1d4ed8',
    badgeBorder: '#bfdbfe',
    reason: clean || 'Khách hàng hủy đơn',
  };
};

interface RestaurantOrderTableProps {
  orders: any[];
  title: string;
  count: number;
  badgeBg: string;
  subtitle: string;
  emptyMessage: string;
  headerBg: string;
  headerColor: string;
  showActions?: boolean;
  isCancelledTab?: boolean;
  onSelectOrder: (order: any) => void;
  onUpdateStatus?: (maDonHang: number, newStatus: string, actionLabel: string) => void;
  updatingOrderId?: number | null;
  footer?: React.ReactNode;
  startIndex?: number;
}

// ── Subcomponent for Individual Order Row with Swipe-to-Cancel ───────────────
interface OrderRowProps {
  ord: any;
  stt: number;
  showActions: boolean;
  isCancelledTab: boolean;
  updatingOrderId?: number | null;
  onSelectOrder: (order: any) => void;
  onUpdateStatus?: (maDonHang: number, newStatus: string, actionLabel: string) => void;
  formatVND: (amount: number) => string;
  formatDateTime: (dateStr?: string | Date) => string;
  getPickupTimeInfo: (dateStr?: string | Date, isFinished?: boolean) => { text: string; isWarning: boolean };
}

const OrderRowItem: React.FC<OrderRowProps> = ({
  ord,
  stt,
  showActions,
  isCancelledTab,
  updatingOrderId,
  onSelectOrder,
  onUpdateStatus,
  formatVND,
  formatDateTime,
  getPickupTimeInfo,
}) => {
  const normSt = normalizeOrderStatus(ord.trangThai);
  const isPending = normSt === 'PENDING';
  const isCancelled = normSt === 'CANCELLED';
  const statusConfig = getOrderStatusConfig(ord.trangThai);
  const isUpdating = updatingOrderId === ord.maDonHang;
  const pickupInfo = getPickupTimeInfo(ord.thoiGianHenNhan, !showActions);
  const cancelInfo = isCancelled ? getCancellationSource(ord.lyDoHuy) : null;

  // Swipe / Drag to cancel state
  const [dragOffset, setDragOffset] = useState<number>(0);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const startXRef = useRef<number>(0);
  const hasMovedRef = useRef<boolean>(false);

  const canSwipe = showActions && !isCancelled && Boolean(onUpdateStatus);

  const handleTouchStart = (e: React.TouchEvent) => {
    if (!canSwipe) return;
    startXRef.current = e.touches[0].clientX;
    setIsDragging(true);
    hasMovedRef.current = false;
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!isDragging || !canSwipe) return;
    const diff = e.touches[0].clientX - startXRef.current;
    if (diff < -5) {
      hasMovedRef.current = true;
      setDragOffset(Math.max(-120, Math.min(0, diff)));
    } else if (diff > 5 && dragOffset < 0) {
      setDragOffset(0);
    }
  };

  const handleTouchEnd = () => {
    if (!isDragging) return;
    setIsDragging(false);
    if (dragOffset <= -65 && onUpdateStatus) {
      setDragOffset(0);
      onUpdateStatus(ord.maDonHang, 'DA_HUY', 'Đã Hủy');
    } else {
      setDragOffset(0);
    }
  };

  const handleMouseDown = (e: React.MouseEvent) => {
    if (!canSwipe || e.button !== 0) return;
    if ((e.target as HTMLElement).closest('button')) return;
    startXRef.current = e.clientX;
    setIsDragging(true);
    hasMovedRef.current = false;
  };

  const handleMouseMove = (e: React.MouseEvent) => {
    if (!isDragging || !canSwipe) return;
    const diff = e.clientX - startXRef.current;
    if (diff < -5) {
      hasMovedRef.current = true;
      setDragOffset(Math.max(-120, Math.min(0, diff)));
    } else if (diff > 5 && dragOffset < 0) {
      setDragOffset(0);
    }
  };

  const handleMouseUp = () => {
    if (!isDragging) return;
    setIsDragging(false);
    if (dragOffset <= -65 && onUpdateStatus) {
      setDragOffset(0);
      onUpdateStatus(ord.maDonHang, 'DA_HUY', 'Đã Hủy');
    } else {
      setDragOffset(0);
    }
  };

  const handleRowClick = () => {
    if (hasMovedRef.current) return;
    onSelectOrder(ord);
  };

  return (
    <tr
      key={ord.maDonHang}
      title={
        canSwipe
          ? `Kéo sang trái để hủy • Click để xem chi tiết đơn #${ord.maDonHang}`
          : `Click để xem chi tiết đơn #${ord.maDonHang}`
      }
      style={{
        position: 'relative',
        borderBottom: '1px solid #f1f5f9',
        borderLeft: `4px solid ${statusConfig.barColor}`,
        background: dragOffset < 0 ? '#fef2f2' : isPending ? '#fffbf5' : '#ffffff',
        cursor: canSwipe ? 'grab' : 'pointer',
        transform: dragOffset !== 0 ? `translateX(${dragOffset}px)` : 'none',
        transition: isDragging ? 'none' : 'transform 180ms ease, background 150ms ease',
        userSelect: isDragging ? 'none' : 'auto',
      }}
      onClick={handleRowClick}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
      onTouchEnd={handleTouchEnd}
      onMouseDown={handleMouseDown}
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      onMouseEnter={(e) => {
        if (!isDragging && dragOffset === 0) {
          (e.currentTarget as HTMLElement).style.background = isPending ? '#fff3e0' : '#f8fafc';
        }
      }}
    >
      {/* STT độc lập */}
      <td style={{ padding: '13px 14px', textAlign: 'center', fontWeight: 600, color: '#64748b' }}>
        {stt}
      </td>

      {/* Mã Đơn - Gạch ngang nhẹ nếu là đơn đã hủy */}
      <td
        style={{
          padding: '13px 14px',
          fontWeight: 800,
          color: isCancelled ? '#94a3b8' : '#0f172a',
          textDecoration: isCancelled ? 'line-through' : 'none',
        }}
      >
        #{ord.maDonHang}
      </td>

      {/* Khách Hàng */}
      <td style={{ padding: '13px 14px' }}>
        <div style={{ fontWeight: 700, color: '#0f172a', fontSize: '13px' }}>
          {ord.tenKhachHang || `Khách #${ord.maKhachHang}`}
        </div>
        {ord.sdtKhachHang && (
          <div style={{ fontSize: '11px', color: '#64748b', marginTop: '2px', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Phone size={11} color="#94a3b8" /> {ord.sdtKhachHang}
          </div>
        )}
      </td>

      {/* Loại Đơn - Chip nhỏ trung tính */}
      <td style={{ padding: '13px 14px' }}>
        <span
          style={{
            background: '#f1f5f9',
            color: '#475569',
            fontSize: '11px',
            fontWeight: 600,
            padding: '3px 8px',
            borderRadius: '6px',
            display: 'inline-block',
            border: '1px solid #e2e8f0',
            whiteSpace: 'nowrap',
          }}
        >
          {ord.loaiDonHang === 'EAT_IN' ? 'Ăn Tại Quán' : 'Tự Đến Lấy'}
        </span>
      </td>

      {/* Thời Gian Đặt */}
      <td style={{ padding: '13px 14px', fontSize: '12px', color: '#475569' }}>
        {formatDateTime(ord.thoiGianDat)}
      </td>

      {/* Thời Gian Nhận */}
      <td style={{ padding: '13px 14px' }}>
        <div
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '4px',
            fontSize: '12px',
            fontWeight: pickupInfo.isWarning ? 700 : 600,
            color: pickupInfo.isWarning ? '#dc2626' : '#334155',
          }}
        >
          <Clock size={12} color={pickupInfo.isWarning ? '#dc2626' : '#64748b'} />
          <span>{pickupInfo.text}</span>
        </div>
      </td>

      {/* Tổng Tiền */}
      <td
        style={{
          padding: '13px 14px',
          textAlign: 'right',
          fontWeight: 700,
          color: isCancelled ? '#94a3b8' : '#fc6011',
          fontSize: '13px',
          fontVariantNumeric: 'tabular-nums',
        }}
      >
        {formatVND(ord.tongTien)}
      </td>

      {/* Trạng Thái */}
      <td style={{ padding: '13px 14px', textAlign: 'center' }}>
        <OrderStatusBadge status={ord.trangThai} />
      </td>

      {/* Hiển thị Người Hủy & Lý Do nếu ở tab Đơn đã hủy */}
      {isCancelledTab && cancelInfo && (
        <td style={{ padding: '13px 14px', textAlign: 'left', minWidth: '190px' }} onClick={(e) => e.stopPropagation()}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '3px' }}>
            <span
              style={{
                background: cancelInfo.badgeBg,
                color: cancelInfo.badgeColor,
                border: `1px solid ${cancelInfo.badgeBorder}`,
                borderRadius: '12px',
                padding: '2px 8px',
                fontSize: '11px',
                fontWeight: 700,
                display: 'inline-flex',
                alignItems: 'center',
                gap: '4px',
                whiteSpace: 'nowrap',
              }}
            >
              {cancelInfo.source === 'RESTAURANT' ? <Store size={11} /> : <User size={11} />}
              {cancelInfo.label}
            </span>
          </div>
          <div
            style={{
              fontSize: '11px',
              color: '#475569',
              lineHeight: '1.4',
              wordBreak: 'break-word',
            }}
          >
            <span style={{ color: '#94a3b8' }}>Lý do: </span>
            <span style={{ fontWeight: 600, color: '#334155' }}>{cancelInfo.reason}</span>
          </div>
        </td>
      )}

      {/* Thao Tác (chỉ hiện cho bảng Cần xử lý) */}
      {showActions && (
        <td style={{ padding: '13px 14px', textAlign: 'right', position: 'relative' }} onClick={(e) => e.stopPropagation()}>
          {/* Visual indicator when swiping left */}
          {canSwipe && Math.abs(dragOffset) > 10 && (
            <div
              style={{
                position: 'absolute',
                right: '12px',
                top: '50%',
                transform: 'translateY(-50%)',
                background: Math.abs(dragOffset) >= 65 ? '#dc2626' : '#ef4444',
                color: '#ffffff',
                padding: '5px 12px',
                borderRadius: '8px',
                display: 'flex',
                alignItems: 'center',
                gap: '5px',
                fontSize: '11px',
                fontWeight: 700,
                boxShadow: '0 2px 8px rgba(220, 38, 38, 0.4)',
                zIndex: 20,
                pointerEvents: 'none',
                whiteSpace: 'nowrap',
              }}
            >
              <Trash2 size={13} />
              <span>{Math.abs(dragOffset) >= 65 ? 'Thả để hủy đơn' : 'Kéo tiếp để hủy'}</span>
            </div>
          )}

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '6px', alignItems: 'center' }}>
            {isUpdating ? (
              <span style={{ fontSize: '11px', color: '#64748b' }}>Đang lưu...</span>
            ) : (
              <>
                {/* Luôn có nút "Hủy" cho mọi đơn đang xử lý */}
                {onUpdateStatus && (
                  <button
                    className="btn btn-outline"
                    onClick={() => onUpdateStatus(ord.maDonHang, 'DA_HUY', 'Đã Hủy')}
                    style={{
                      padding: '5px 10px',
                      fontSize: '12px',
                      color: '#ef4444',
                      borderColor: '#fecaca',
                      borderRadius: '7px',
                      background: '#fff',
                    }}
                    title="Hủy đơn hàng này (hoặc kéo sang trái)"
                  >
                    Hủy
                  </button>
                )}

                {normSt === 'PENDING' && onUpdateStatus && (
                  <button
                    className="btn btn-primary"
                    onClick={() => onUpdateStatus(ord.maDonHang, 'DA_XAC_NHAN', 'Đã Xác Nhận')}
                    style={{ padding: '5px 12px', fontSize: '12px', background: '#3b82f6', border: 'none', borderRadius: '7px' }}
                    title="Xác nhận đơn"
                  >
                    ✓ Xác Nhận
                  </button>
                )}

                {normSt === 'CONFIRMED' && onUpdateStatus && (
                  <button
                    className="btn btn-primary"
                    onClick={() => onUpdateStatus(ord.maDonHang, 'DANG_CHUAN_BI', 'Đang Chuẩn Bị')}
                    style={{ padding: '5px 12px', fontSize: '12px', background: '#f59e0b', border: 'none', borderRadius: '7px' }}
                    title="Bắt đầu chuẩn bị món"
                  >
                    🍳 Chuẩn Bị
                  </button>
                )}

                {normSt === 'PREPARING' && onUpdateStatus && (
                  <button
                    className="btn btn-primary"
                    onClick={() => onUpdateStatus(ord.maDonHang, 'SAN_SANG', 'Sẵn Sàng Ghé Lấy')}
                    style={{ padding: '5px 12px', fontSize: '12px', background: '#8b5cf6', border: 'none', borderRadius: '7px' }}
                    title="Báo món ăn đã sẵn sàng"
                  >
                    🔔 Sẵn Sàng
                  </button>
                )}

                {normSt === 'READY_FOR_PICKUP' && onUpdateStatus && (
                  <button
                    className="btn btn-primary"
                    onClick={() => onUpdateStatus(ord.maDonHang, 'HOAN_TAT', 'Hoàn Thành')}
                    style={{ padding: '5px 12px', fontSize: '12px', background: '#10b981', border: 'none', borderRadius: '7px' }}
                    title="Xác nhận khách đã lấy món"
                  >
                    ✓ Đã Giao
                  </button>
                )}
              </>
            )}
          </div>
        </td>
      )}
    </tr>
  );
};

export const RestaurantOrderTable: React.FC<RestaurantOrderTableProps> = ({
  orders,
  title,
  count,
  badgeBg,
  subtitle,
  emptyMessage,
  headerBg,
  headerColor,
  showActions = false,
  isCancelledTab = false,
  onSelectOrder,
  onUpdateStatus,
  updatingOrderId,
  footer,
  startIndex = 0,
}) => {
  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  const formatDateTime = (dateStr?: string | Date) => {
    if (!dateStr) return '—';
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return '—';
    return d.toLocaleString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getPickupTimeInfo = (dateStr?: string | Date, isFinished?: boolean) => {
    if (!dateStr) return { text: 'Ghé liền', isWarning: false };
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return { text: 'Ghé liền', isWarning: false };
    const timeText = d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    if (isFinished) return { text: timeText, isWarning: false };

    const now = new Date();
    const diffMinutes = Math.floor((d.getTime() - now.getTime()) / (1000 * 60));
    if (diffMinutes < 0) return { text: `${timeText} (Quá giờ)`, isWarning: true };
    if (diffMinutes <= 20) return { text: `${timeText} (${diffMinutes}p)`, isWarning: true };
    return { text: timeText, isWarning: false };
  };

  return (
    <div style={{ marginBottom: '28px' }}>
      {/* Header Title & Count Badge */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px', padding: '0 4px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <h3 style={{ fontSize: '15px', fontWeight: 800, color: '#0f172a', margin: 0, display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span>{title}</span>
            <span
              style={{
                background: count > 0 ? badgeBg : '#94a3b8',
                color: '#ffffff',
                fontSize: '11px',
                fontWeight: 700,
                padding: '2px 8px',
                borderRadius: '12px',
              }}
            >
              {count}
            </span>
          </h3>
        </div>
        <span style={{ fontSize: '12px', color: '#64748b' }}>{subtitle}</span>
      </div>

      {/* Table Content Card */}
      <div className="card-table" style={{ background: '#ffffff', borderRadius: '14px', border: '1px solid #e2e8f0', overflow: 'hidden', boxShadow: '0 1px 3px rgba(0,0,0,0.02)' }}>
        {orders.length === 0 ? (
          <div style={{ padding: '36px 20px', textAlign: 'center', background: '#fafafa' }}>
            <PackageX size={32} color="#cbd5e1" style={{ marginBottom: '6px' }} />
            <p style={{ fontSize: '13px', fontWeight: 600, color: '#64748b', margin: 0 }}>
              {emptyMessage}
            </p>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="data-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ background: headerBg, textTransform: 'uppercase', fontSize: '11px', color: headerColor, letterSpacing: '0.4px', borderBottom: '1px solid #e2e8f0' }}>
                  <th style={{ padding: '12px 14px', textAlign: 'center', width: '50px' }}>STT</th>
                  <th style={{ padding: '12px 14px', textAlign: 'left' }}>Mã Đơn</th>
                  <th style={{ padding: '12px 14px', textAlign: 'left' }}>Khách Hàng</th>
                  <th style={{ padding: '12px 14px', textAlign: 'left' }}>Loại Đơn</th>
                  <th style={{ padding: '12px 14px', textAlign: 'left' }}>Thời Gian Đặt</th>
                  <th style={{ padding: '12px 14px', textAlign: 'left' }}>Thời Gian Nhận</th>
                  <th style={{ padding: '12px 14px', textAlign: 'right' }}>Tổng Tiền</th>
                  <th style={{ padding: '12px 14px', textAlign: 'center' }}>Trạng Thái</th>
                  {isCancelledTab && <th style={{ padding: '12px 14px', textAlign: 'left' }}>Người Hủy & Lý Do</th>}
                  {showActions && <th style={{ padding: '12px 14px', textAlign: 'right' }}>Thao Tác</th>}
                </tr>
              </thead>
              <tbody>
                {orders.map((ord: any, idx: number) => (
                  <OrderRowItem
                    key={ord.maDonHang}
                    ord={ord}
                    stt={startIndex + idx + 1}
                    showActions={showActions}
                    isCancelledTab={isCancelledTab}
                    updatingOrderId={updatingOrderId}
                    onSelectOrder={onSelectOrder}
                    onUpdateStatus={onUpdateStatus}
                    formatVND={formatVND}
                    formatDateTime={formatDateTime}
                    getPickupTimeInfo={getPickupTimeInfo}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}

        {footer}
      </div>
    </div>
  );
};
