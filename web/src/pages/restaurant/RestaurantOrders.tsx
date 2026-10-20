import React, { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { apiFetch } from '../../api/apiClient';
import { getSocket } from '../../api/socketClient';
import { normalizeOrderStatus } from '../../components/OrderStatusBadge';
import { RestaurantOrderTable, getCancellationSource } from '../../components/RestaurantOrderTable';
import { OrderDetailModal } from '../../components/OrderDetailModal';
import { NotificationModal } from '../../components/NotificationModal';
import { Modal } from '../../components/Modal';
import { UnderlineTabs } from '../../components/UnderlineTabs';
import { playOrderAlertSound } from '../../utils/soundUtils';
import {
  Search,
  Calendar,
  RefreshCw,
  ChevronLeft,
  ChevronRight,
  RotateCcw,
  AlertCircle,
  Clock,
  CheckCircle2,
  XCircle,
  Trash2,
} from 'lucide-react';

export const RestaurantOrders: React.FC = () => {
  // Tab State synced with URL (?tab=pending | ?tab=picked-up | ?tab=cancelled)
  const [searchParams, setSearchParams] = useSearchParams();
  const tabFromUrl = searchParams.get('tab');
  const activeTab: 'pending' | 'picked-up' | 'cancelled' =
    tabFromUrl === 'picked-up'
      ? 'picked-up'
      : tabFromUrl === 'cancelled'
      ? 'cancelled'
      : 'pending';

  // Orders State
  const [activeOrders, setActiveOrders] = useState<any[]>([]);
  const [hasPending, setHasPending] = useState<boolean>(false);

  // Finished Orders State (Tab 2: "Khách đã lấy")
  const [finishedOrders, setFinishedOrders] = useState<any[]>([]);
  const [finishedTotal, setFinishedTotal] = useState<number>(0);
  const [finishedTotalPages, setFinishedTotalPages] = useState<number>(1);

  // Cancelled Orders State (Tab 3: "Đơn đã hủy")
  const [cancelledOrders, setCancelledOrders] = useState<any[]>([]);
  const [cancelledTotal, setCancelledTotal] = useState<number>(0);
  const [cancelledTotalPages, setCancelledTotalPages] = useState<number>(1);

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Time Period Filter State: 'today' | '7days' | '30days' | 'custom'
  const [period, setPeriod] = useState<string>('7days');
  const [customFrom, setCustomFrom] = useState<string>('');
  const [customTo, setCustomTo] = useState<string>('');
  const [appliedFrom, setAppliedFrom] = useState<string>('');
  const [appliedTo, setAppliedTo] = useState<string>('');

  // Status / Sub-Filter State (resets to 'ALL' on tab change)
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  // Search State
  const [searchInput, setSearchInput] = useState<string>('');
  const [appliedSearch, setAppliedSearch] = useState<string>('');

  // Pagination State for Tab 2 & Tab 3
  const [page, setPage] = useState<number>(1);
  const [limit, setLimit] = useState<number>(20);

  // Modals & Action Pending States
  const [selectedOrder, setSelectedOrder] = useState<any | null>(null);
  const [updatingOrderId, setUpdatingOrderId] = useState<number | null>(null);

  // Cancel Order Modal State
  const [cancelModal, setCancelModal] = useState<{
    isOpen: boolean;
    orderId: number | null;
    reason: string;
  }>({
    isOpen: false,
    orderId: null,
    reason: 'Hết món',
  });

  // Notification Toast Modal
  const [notifyModal, setNotifyModal] = useState<{
    isOpen: boolean;
    type: 'success' | 'error' | 'warning' | 'info';
    title: string;
    message: string | string[];
  }>({
    isOpen: false,
    type: 'info',
    title: '',
    message: '',
  });

  const showNotify = (type: 'success' | 'error' | 'warning' | 'info', title: string, message: string | string[]) => {
    setNotifyModal({ isOpen: true, type, title, message });
  };

  const handleTabChange = (newTab: 'pending' | 'picked-up' | 'cancelled') => {
    if (newTab === activeTab) return;
    setStatusFilter('ALL'); // Reset chip to "Tất cả"
    setPage(1);
    setSearchParams(
      (prev) => {
        const next = new URLSearchParams(prev);
        next.set('tab', newTab);
        return next;
      },
      { replace: true }
    );
  };

  const fetchOrders = async () => {
    // Only show full-screen loader on initial empty load to prevent flickers on tab switch
    if (activeOrders.length === 0 && finishedOrders.length === 0 && cancelledOrders.length === 0) {
      setLoading(true);
    }
    setError(null);

    let baseQuery = '';
    if (period) {
      baseQuery += `&period=${encodeURIComponent(period)}`;
    }
    if (period === 'custom' && appliedFrom && appliedTo) {
      baseQuery += `&from=${encodeURIComponent(appliedFrom)}&to=${encodeURIComponent(appliedTo)}`;
    }
    if (appliedSearch.trim()) {
      baseQuery += `&search=${encodeURIComponent(appliedSearch.trim())}`;
    }

    try {
      // 1. Fetch active orders (Tab 1): load up to 100 recent items without status constraint
      const activePromise = apiFetch<any>(`/restaurant/orders?page=1&limit=100${baseQuery}`);

      // 2. Fetch finished orders (Tab 2)
      const finishedLimit = activeTab === 'picked-up' ? limit : 1;
      const finishedPage = activeTab === 'picked-up' ? page : 1;
      const finishedPromise = apiFetch<any>(`/restaurant/orders?page=${finishedPage}&limit=${finishedLimit}&status=COMPLETED${baseQuery}`);

      // 3. Fetch cancelled orders (Tab 3)
      const cancelledLimit = activeTab === 'cancelled' ? limit : 1;
      const cancelledPage = activeTab === 'cancelled' ? page : 1;
      const cancelledPromise = apiFetch<any>(`/restaurant/orders?page=${cancelledPage}&limit=${cancelledLimit}&status=CANCELLED${baseQuery}`);

      const [activeRes, finishedRes, cancelledRes] = await Promise.all([
        activePromise,
        finishedPromise,
        cancelledPromise,
      ]);

      if (activeRes.data) {
        const allItems = activeRes.data.items || [];
        const rawActives = allItems.filter((o: any) => {
          const norm = normalizeOrderStatus(o.trangThai);
          return norm === 'PENDING' || norm === 'CONFIRMED' || norm === 'PREPARING' || norm === 'READY_FOR_PICKUP';
        });
        setActiveOrders(rawActives);
        setHasPending(rawActives.some((o: any) => normalizeOrderStatus(o.trangThai) === 'PENDING'));
      }

      if (finishedRes.data) {
        if (activeTab === 'picked-up') {
          setFinishedOrders(finishedRes.data.items || []);
          setFinishedTotalPages(finishedRes.data.totalPages || 1);
        }
        setFinishedTotal(finishedRes.data.total || 0);
      }

      if (cancelledRes.data) {
        if (activeTab === 'cancelled') {
          setCancelledOrders(cancelledRes.data.items || []);
          setCancelledTotalPages(cancelledRes.data.totalPages || 1);
        }
        setCancelledTotal(cancelledRes.data.total || 0);
      }
    } catch (err: any) {
      setError(err.message || 'Không thể tải danh sách đơn hàng');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();

    const socket = getSocket();
    if (socket) {
      const handleRealtimeOrder = (payload: any) => {
        console.log('⚡ Realtime order update received:', payload);
        playOrderAlertSound();
        fetchOrders();
      };

      socket.on('order:created', handleRealtimeOrder);
      socket.on('order:status_changed', handleRealtimeOrder);
      socket.on('payment:confirmed', handleRealtimeOrder);

      return () => {
        socket.off('order:created', handleRealtimeOrder);
        socket.off('order:status_changed', handleRealtimeOrder);
        socket.off('payment:confirmed', handleRealtimeOrder);
      };
    }
  }, [page, limit, statusFilter, period, appliedFrom, appliedTo, appliedSearch, activeTab]);

  const handlePeriodChange = (newPeriod: string) => {
    setPeriod(newPeriod);
    setPage(1);
    if (newPeriod !== 'custom') {
      setAppliedFrom('');
      setAppliedTo('');
    }
  };

  const handleApplyCustomDates = (e: React.FormEvent) => {
    e.preventDefault();
    if (!customFrom || !customTo) {
      showNotify('warning', 'Bộ Lọc Ngày', 'Vui lòng chọn đầy đủ Từ ngày và Đến ngày');
      return;
    }
    if (new Date(customTo) < new Date(customFrom)) {
      showNotify('warning', 'Bộ Lọc Ngày', 'Đến ngày phải lớn hơn hoặc bằng Từ ngày');
      return;
    }
    setAppliedFrom(customFrom);
    setAppliedTo(customTo);
    setPage(1);
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setAppliedSearch(searchInput);
    setPage(1);
  };

  const handleClearSearch = () => {
    setSearchInput('');
    setAppliedSearch('');
    setPage(1);
  };

  const handleStatusFilterChange = (newStatus: string) => {
    setStatusFilter(newStatus);
    setPage(1);
  };

  const handleResetFilters = () => {
    setPeriod('7days');
    setStatusFilter('ALL');
    setSearchInput('');
    setAppliedSearch('');
    setCustomFrom('');
    setCustomTo('');
    setAppliedFrom('');
    setAppliedTo('');
    setPage(1);
  };

  const handleUpdateStatus = async (maDonHang: number, newStatus: string, actionLabel: string) => {
    if (newStatus === 'DA_HUY' || actionLabel.toLowerCase().includes('từ chối') || actionLabel.toLowerCase().includes('hủy')) {
      // Open clean cancel modal
      setCancelModal({
        isOpen: true,
        orderId: maDonHang,
        reason: 'Hết món',
      });
      return;
    }

    setUpdatingOrderId(maDonHang);
    try {
      await apiFetch(`/restaurant/orders/${maDonHang}/status`, {
        method: 'PUT',
        body: JSON.stringify({ trangThai: newStatus, status: newStatus }),
      });
      fetchOrders();
      showNotify('success', 'Thành Công', `Đã chuyển đơn hàng #${maDonHang} sang trạng thái "${actionLabel}"`);
    } catch (err: any) {
      showNotify('error', 'Lỗi Cập Nhật', err.message || 'Không thể cập nhật trạng thái đơn hàng');
    } finally {
      setUpdatingOrderId(null);
    }
  };

  const handleConfirmCancelOrder = async () => {
    if (!cancelModal.orderId) return;
    const orderId = cancelModal.orderId;
    const trimmed = cancelModal.reason.trim();
    const lyDo = trimmed ? `Quán hủy: ${trimmed}` : 'Quán hủy đơn';

    setCancelModal({ isOpen: false, orderId: null, reason: '' });
    setUpdatingOrderId(orderId);
    try {
      await apiFetch(`/restaurant/orders/${orderId}/status`, {
        method: 'PUT',
        body: JSON.stringify({ trangThai: 'DA_HUY', status: 'DA_HUY', lyDo }),
      });
      fetchOrders();
      showNotify('success', 'Đã Hủy Đơn Hàng', `Đơn hàng #${orderId} đã được hủy và lưu vào mục "Đơn đã hủy".`);
    } catch (err: any) {
      showNotify('error', 'Lỗi Hủy Đơn', err.message || 'Không thể hủy đơn hàng');
    } finally {
      setUpdatingOrderId(null);
    }
  };

  const isFilterActive =
    statusFilter !== 'ALL' ||
    period !== '7days' ||
    appliedSearch.trim() !== '' ||
    appliedFrom !== '' ||
    appliedTo !== '';

  // Tab 1: "Cần xử lý"
  const displayActiveOrders = activeOrders.filter((o) => {
    if (statusFilter === 'ALL') return true;
    return normalizeOrderStatus(o.trangThai) === statusFilter;
  });

  const sortedActiveOrders = [...displayActiveOrders].sort((a, b) => {
    const aIsPending = normalizeOrderStatus(a.trangThai) === 'PENDING';
    const bIsPending = normalizeOrderStatus(b.trangThai) === 'PENDING';
    if (aIsPending && !bIsPending) return -1;
    if (!aIsPending && bIsPending) return 1;
    const timeA = new Date(a.thoiGianDat || 0).getTime();
    const timeB = new Date(b.thoiGianDat || 0).getTime();
    return timeB - timeA;
  });

  // Tab 3: "Đơn đã hủy" - Lọc theo người hủy (Khách hủy vs Chủ quán hủy)
  const displayCancelledOrders = cancelledOrders.filter((o) => {
    if (statusFilter === 'ALL') return true;
    const info = getCancellationSource(o.lyDoHuy);
    return info.source === statusFilter;
  });

  // Chip trạng thái phù hợp cho từng tab
  const statusChips = activeTab === 'pending'
    ? [
        { key: 'ALL', label: 'Tất cả' },
        { key: 'PENDING', label: 'Chờ xác nhận' },
        { key: 'CONFIRMED', label: 'Đã xác nhận' },
        { key: 'PREPARING', label: 'Đang chuẩn bị' },
        { key: 'READY_FOR_PICKUP', label: 'Sẵn sàng' },
      ]
    : activeTab === 'picked-up'
    ? [
        { key: 'ALL', label: 'Tất cả' },
        { key: 'COMPLETED', label: 'Đã hoàn tất' },
      ]
    : [
        { key: 'ALL', label: 'Tất cả' },
        { key: 'CUSTOMER', label: 'Khách hủy' },
        { key: 'RESTAURANT', label: 'Chủ quán hủy' },
      ];

  // Pagination variables for Tab 2 / Tab 3
  const currentTotal = activeTab === 'picked-up' ? finishedTotal : cancelledTotal;
  const currentTotalPages = activeTab === 'picked-up' ? finishedTotalPages : cancelledTotalPages;

  return (
    <div>
      {/* ── Page Header ──────────────────────────────────────────────────────── */}
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 className="page-title">Quản Lý Đơn Hàng</h1>
          <p className="page-subtitle">Xử lý tiến trình chuẩn bị món, thời gian ghé lấy & tra cứu đơn hàng của quán</p>
        </div>

        <button
          className="btn"
          onClick={fetchOrders}
          style={{ background: '#ffffff', border: '1px solid #cbd5e1', display: 'flex', alignItems: 'center', gap: '6px' }}
          title="Tải lại dữ liệu"
        >
          <RefreshCw size={16} color="#64748b" className={loading ? 'spin' : ''} />
          <span style={{ fontSize: '13px', fontWeight: 600 }}>Tải lại</span>
        </button>
      </div>

      {/* ── Toolbar: Search & Time Filter Presets ─────────────────────────── */}
      <div className="card" style={{ padding: '16px 20px', marginBottom: '20px', background: '#ffffff', borderRadius: '14px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.03)' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          {/* Top Controls: Search + Period Buttons */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px' }}>
            {/* Search Input */}
            <form onSubmit={handleSearchSubmit} style={{ position: 'relative', minWidth: '280px', flex: '1', maxWidth: '460px', display: 'flex', gap: '8px', alignItems: 'center' }}>
              <div style={{ position: 'relative', flex: 1 }}>
                <Search size={16} color="#94a3b8" style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)' }} />
                <input
                  type="text"
                  className="form-control"
                  placeholder="Tìm mã đơn hoặc tên khách hàng..."
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  style={{ paddingLeft: '38px', paddingRight: searchInput ? '34px' : '14px', fontSize: '13px', borderRadius: '10px', background: '#f8fafc' }}
                />
                {searchInput && (
                  <button
                    type="button"
                    onClick={handleClearSearch}
                    style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#94a3b8' }}
                  >
                    ×
                  </button>
                )}
              </div>
              <button
                type="submit"
                className="btn btn-primary btn-sm"
                style={{ background: '#fc6011', border: 'none', padding: '8px 16px', fontSize: '13px', flexShrink: 0 }}
              >
                Tìm
              </button>
            </form>

            {/* Time Period Filter Buttons */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', background: '#f1f5f9', padding: '4px', borderRadius: '10px' }}>
              {[
                { key: 'today', label: 'Hôm nay' },
                { key: '7days', label: '7 ngày' },
                { key: '30days', label: '30 ngày' },
                { key: 'custom', label: 'Tùy chọn' },
              ].map((p) => (
                <button
                  key={p.key}
                  type="button"
                  onClick={() => handlePeriodChange(p.key)}
                  style={{
                    padding: '7px 14px',
                    borderRadius: '8px',
                    border: 'none',
                    fontSize: '13px',
                    fontWeight: 700,
                    cursor: 'pointer',
                    background: period === p.key ? '#ffffff' : 'transparent',
                    color: period === p.key ? '#fc6011' : '#64748b',
                    boxShadow: period === p.key ? '0 1px 3px rgba(0,0,0,0.1)' : 'none',
                    transition: 'all 0.15s ease',
                  }}
                >
                  {p.label}
                </button>
              ))}
            </div>
          </div>

          {/* Custom Date Inputs (only when period === 'custom') */}
          {period === 'custom' && (
            <form onSubmit={handleApplyCustomDates} style={{ display: 'flex', alignItems: 'center', gap: '12px', background: '#fffbeb', padding: '10px 16px', borderRadius: '10px', border: '1px solid #fef3c7', flexWrap: 'wrap' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', fontWeight: 600, color: '#92400e' }}>
                <Calendar size={15} color="#d97706" />
                <span>Từ ngày:</span>
                <input
                  type="date"
                  className="form-control"
                  value={customFrom}
                  onChange={(e) => setCustomFrom(e.target.value)}
                  style={{ width: 'auto', fontSize: '13px', padding: '4px 8px', borderRadius: '6px' }}
                  required
                />
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', fontWeight: 600, color: '#92400e' }}>
                <span>Đến ngày:</span>
                <input
                  type="date"
                  className="form-control"
                  value={customTo}
                  onChange={(e) => setCustomTo(e.target.value)}
                  style={{ width: 'auto', fontSize: '13px', padding: '4px 8px', borderRadius: '6px' }}
                  required
                />
              </div>
              <button type="submit" className="btn btn-primary btn-sm" style={{ background: '#d97706', border: 'none', padding: '5px 14px', fontSize: '12px' }}>
                Áp dụng
              </button>
            </form>
          )}

          {/* Status Filter Chips */}
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', overflowX: 'auto', paddingBottom: '4px', borderTop: '1px solid #f1f5f9', paddingTop: '12px' }}>
            <span style={{ fontSize: '12px', fontWeight: 700, color: '#94a3b8', textTransform: 'uppercase', flexShrink: 0, marginRight: '4px' }}>
              {activeTab === 'cancelled' ? 'Lọc người hủy:' : 'Trạng thái:'}
            </span>
            {statusChips.map((st) => (
              <button
                key={st.key}
                type="button"
                onClick={() => handleStatusFilterChange(st.key)}
                style={{
                  padding: '6px 14px',
                  borderRadius: '20px',
                  border: statusFilter === st.key ? '1px solid #fc6011' : '1px solid #e2e8f0',
                  fontSize: '12px',
                  fontWeight: statusFilter === st.key ? 700 : 600,
                  cursor: 'pointer',
                  background: statusFilter === st.key ? '#fff4ee' : '#ffffff',
                  color: statusFilter === st.key ? '#fc6011' : '#475569',
                  whiteSpace: 'nowrap',
                  transition: 'all 0.15s ease',
                }}
              >
                {st.label}
              </button>
            ))}

            {isFilterActive && (
              <button
                type="button"
                onClick={handleResetFilters}
                style={{
                  marginLeft: 'auto',
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  color: '#ef4444',
                  fontSize: '12px',
                  fontWeight: 700,
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  whiteSpace: 'nowrap',
                }}
                title="Xóa bộ lọc"
              >
                <RotateCcw size={13} /> Xóa bộ lọc
              </button>
            )}
          </div>
        </div>
      </div>

      {/* ── Tabs Navigation: Placed right under filter card, above table ── */}
      <UnderlineTabs
        tabs={[
          {
            key: 'pending',
            label: 'Cần xử lý',
            icon: <Clock size={18} />,
            count: activeOrders.length,
            highlightCount: hasPending,
          },
          {
            key: 'picked-up',
            label: 'Khách đã lấy',
            icon: <CheckCircle2 size={18} />,
            count: finishedTotal,
            highlightCount: false,
          },
          {
            key: 'cancelled',
            label: 'Đơn đã hủy',
            icon: <XCircle size={18} />,
            count: cancelledTotal,
            highlightCount: false,
          },
        ]}
        activeTab={activeTab}
        onChange={handleTabChange}
      />

      {loading ? (
        <div className="card-table" style={{ textAlign: 'center', padding: '60px 0' }}>
          <div className="loading-spinner" />
          <p style={{ marginTop: '14px', color: '#64748b', fontSize: '13px' }}>Đang tải danh sách đơn hàng...</p>
        </div>
      ) : error ? (
        <div className="card-table" style={{ textAlign: 'center', padding: '40px 20px', background: '#fef2f2', margin: '20px 0', borderRadius: '12px' }}>
          <AlertCircle size={40} color="#ef4444" style={{ marginBottom: '8px' }} />
          <p style={{ color: '#ef4444', fontWeight: 700, fontSize: '15px' }}>Không thể tải danh sách đơn hàng</p>
          <p style={{ color: '#64748b', fontSize: '13px', marginTop: '4px', marginBottom: '16px' }}>{error}</p>
          <button className="btn btn-primary" onClick={fetchOrders} style={{ background: '#fc6011', border: 'none' }}>
            Thử lại
          </button>
        </div>
      ) : (
        <>
          {activeTab === 'pending' ? (
            /* ══════════════════════════════════════════════════════════════════════
                TAB 1: "Cần xử lý" (Chờ xác nhận, Đã xác nhận, Đang chuẩn bị, Sẵn sàng)
               ══════════════════════════════════════════════════════════════════════ */
            <RestaurantOrderTable
              orders={sortedActiveOrders}
              title="Đơn Cần Xử Lý"
              count={sortedActiveOrders.length}
              badgeBg="#ea580c"
              subtitle="Các đơn chờ xác nhận, đang chuẩn bị & sẵn sàng • Kéo đơn sang trái để hủy nhanh"
              emptyMessage="Không có đơn nào cần xử lý"
              headerBg="#fff7ed"
              headerColor="#c2410c"
              showActions={true}
              onSelectOrder={setSelectedOrder}
              onUpdateStatus={handleUpdateStatus}
              updatingOrderId={updatingOrderId}
              startIndex={0}
            />
          ) : activeTab === 'picked-up' ? (
            /* ══════════════════════════════════════════════════════════════════════
                TAB 2: "Khách đã lấy" (Đơn hoàn thành)
               ══════════════════════════════════════════════════════════════════════ */
            <RestaurantOrderTable
              orders={finishedOrders}
              title="Đơn Khách Đã Lấy"
              count={finishedTotal}
              badgeBg="#10b981"
              subtitle="Lịch sử các đơn đã hoàn tất khách đã lấy hàng"
              emptyMessage="Chưa có đơn nào hoàn thành"
              headerBg="#f8fafc"
              headerColor="#64748b"
              showActions={false}
              onSelectOrder={setSelectedOrder}
              startIndex={(page - 1) * limit}
              footer={
                finishedTotal > 0 && (
                  <div
                    style={{
                      padding: '12px 18px',
                      borderTop: '1px solid #e2e8f0',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      flexWrap: 'wrap',
                      gap: '12px',
                      background: '#ffffff',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
                      <div style={{ fontSize: '13px', color: '#64748b' }}>
                        Hiển thị <strong style={{ color: '#0f172a' }}>{(page - 1) * limit + 1}</strong> –{' '}
                        <strong style={{ color: '#0f172a' }}>{Math.min(page * limit, finishedTotal)}</strong> /{' '}
                        <strong style={{ color: '#0f172a' }}>{finishedTotal}</strong> đơn hàng
                      </div>

                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span style={{ fontSize: '12px', color: '#64748b' }}>Hiển thị:</span>
                        <select
                          value={limit}
                          onChange={(e) => {
                            setLimit(Number(e.target.value));
                            setPage(1);
                          }}
                          className="form-control"
                          style={{ width: 'auto', fontSize: '12px', padding: '4px 8px', borderRadius: '6px' }}
                        >
                          <option value={10}>10 / trang</option>
                          <option value={20}>20 / trang</option>
                          <option value={50}>50 / trang</option>
                          <option value={100}>100 / trang</option>
                        </select>
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <button
                        className="btn btn-secondary"
                        onClick={() => setPage((p) => Math.max(p - 1, 1))}
                        disabled={page <= 1}
                        style={{ padding: '6px 10px', fontSize: '12px', opacity: page <= 1 ? 0.5 : 1, borderRadius: '7px' }}
                      >
                        <ChevronLeft size={15} />
                      </button>

                      {Array.from({ length: finishedTotalPages }, (_, i) => i + 1)
                        .filter((p) => p === 1 || p === finishedTotalPages || Math.abs(p - page) <= 2)
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
                        onClick={() => setPage((p) => Math.min(p + 1, finishedTotalPages))}
                        disabled={page >= finishedTotalPages}
                        style={{ padding: '6px 10px', fontSize: '12px', opacity: page >= finishedTotalPages ? 0.5 : 1, borderRadius: '7px' }}
                      >
                        <ChevronRight size={15} />
                      </button>
                    </div>
                  </div>
                )
              }
            />
          ) : (
            /* ══════════════════════════════════════════════════════════════════════
                TAB 3: "Đơn đã hủy" (Khách hủy & Quán hủy)
               ══════════════════════════════════════════════════════════════════════ */
            <RestaurantOrderTable
              orders={displayCancelledOrders}
              title="Đơn Đã Hủy"
              count={cancelledTotal}
              badgeBg="#ef4444"
              subtitle="Lịch sử các đơn do khách hàng hoặc quán đã hủy"
              emptyMessage="Chưa có đơn hàng nào bị hủy"
              headerBg="#fef2f2"
              headerColor="#991b1b"
              showActions={false}
              isCancelledTab={true}
              onSelectOrder={setSelectedOrder}
              startIndex={(page - 1) * limit}
              footer={
                cancelledTotal > 0 && (
                  <div
                    style={{
                      padding: '12px 18px',
                      borderTop: '1px solid #e2e8f0',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      flexWrap: 'wrap',
                      gap: '12px',
                      background: '#ffffff',
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
                      <div style={{ fontSize: '13px', color: '#64748b' }}>
                        Hiển thị <strong style={{ color: '#0f172a' }}>{(page - 1) * limit + 1}</strong> –{' '}
                        <strong style={{ color: '#0f172a' }}>{Math.min(page * limit, cancelledTotal)}</strong> /{' '}
                        <strong style={{ color: '#0f172a' }}>{cancelledTotal}</strong> đơn hàng
                      </div>

                      <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span style={{ fontSize: '12px', color: '#64748b' }}>Hiển thị:</span>
                        <select
                          value={limit}
                          onChange={(e) => {
                            setLimit(Number(e.target.value));
                            setPage(1);
                          }}
                          className="form-control"
                          style={{ width: 'auto', fontSize: '12px', padding: '4px 8px', borderRadius: '6px' }}
                        >
                          <option value={10}>10 / trang</option>
                          <option value={20}>20 / trang</option>
                          <option value={50}>50 / trang</option>
                          <option value={100}>100 / trang</option>
                        </select>
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <button
                        className="btn btn-secondary"
                        onClick={() => setPage((p) => Math.max(p - 1, 1))}
                        disabled={page <= 1}
                        style={{ padding: '6px 10px', fontSize: '12px', opacity: page <= 1 ? 0.5 : 1, borderRadius: '7px' }}
                      >
                        <ChevronLeft size={15} />
                      </button>

                      {Array.from({ length: cancelledTotalPages }, (_, i) => i + 1)
                        .filter((p) => p === 1 || p === cancelledTotalPages || Math.abs(p - page) <= 2)
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
                        onClick={() => setPage((p) => Math.min(p + 1, cancelledTotalPages))}
                        disabled={page >= cancelledTotalPages}
                        style={{ padding: '6px 10px', fontSize: '12px', opacity: page >= cancelledTotalPages ? 0.5 : 1, borderRadius: '7px' }}
                      >
                        <ChevronRight size={15} />
                      </button>
                    </div>
                  </div>
                )
              }
            />
          )}
        </>
      )}

      {/* ── Cancel Confirmation Modal ────────────────────────────────────── */}
      <Modal
        isOpen={cancelModal.isOpen}
        onClose={() => setCancelModal({ isOpen: false, orderId: null, reason: '' })}
        title={`Xác Nhận Hủy Đơn Hàng #${cancelModal.orderId}`}
        maxWidth="480px"
      >
        <div style={{ padding: '4px 0' }}>
          <p style={{ fontSize: '13px', color: '#64748b', marginBottom: '14px', lineHeight: '1.5' }}>
            Vui lòng chọn hoặc nhập lý do hủy đơn. Đơn sau khi hủy sẽ được chuyển vào mục{' '}
            <strong style={{ color: '#ef4444' }}>Đơn đã hủy</strong> và hệ thống sẽ gửi thông báo cho khách hàng.
          </p>

          {/* Quick suggestions */}
          <div style={{ marginBottom: '12px' }}>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
              Lý do gợi ý:
            </label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px' }}>
              {[
                'Hết món / nguyên liệu',
                'Quán quá tải không kịp làm',
                'Khách gọi điện xin hủy',
                'Quán đóng cửa nghỉ đột xuất',
              ].map((r) => (
                <button
                  key={r}
                  type="button"
                  onClick={() => setCancelModal((prev) => ({ ...prev, reason: r }))}
                  style={{
                    padding: '5px 10px',
                    borderRadius: '6px',
                    border: cancelModal.reason === r ? '1px solid #ef4444' : '1px solid #e2e8f0',
                    background: cancelModal.reason === r ? '#fef2f2' : '#f8fafc',
                    color: cancelModal.reason === r ? '#dc2626' : '#475569',
                    fontSize: '12px',
                    fontWeight: 600,
                    cursor: 'pointer',
                    transition: 'all 0.15s ease',
                  }}
                >
                  {r}
                </button>
              ))}
            </div>
          </div>

          {/* Custom reason input */}
          <div style={{ marginBottom: '20px' }}>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
              Lý do chi tiết:
            </label>
            <textarea
              className="form-control"
              rows={3}
              value={cancelModal.reason}
              onChange={(e) => setCancelModal((prev) => ({ ...prev, reason: e.target.value }))}
              placeholder="Nhập lý do hủy đơn..."
              style={{ fontSize: '13px', resize: 'vertical' }}
            />
          </div>

          {/* Action Buttons */}
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
            <button
              type="button"
              className="btn"
              onClick={() => setCancelModal({ isOpen: false, orderId: null, reason: '' })}
              style={{ background: '#f1f5f9', color: '#475569', border: '1px solid #cbd5e1' }}
            >
              Quay lại
            </button>
            <button
              type="button"
              className="btn"
              onClick={handleConfirmCancelOrder}
              style={{
                background: '#ef4444',
                color: '#ffffff',
                border: 'none',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
              }}
            >
              <Trash2 size={15} />
              Xác Nhận Hủy Đơn
            </button>
          </div>
        </div>
      </Modal>

      {/* ── Order Detail Modal ───────────────────────────────────────────── */}
      <OrderDetailModal
        order={selectedOrder}
        onClose={() => setSelectedOrder(null)}
        onUpdateStatus={handleUpdateStatus}
      />

      {/* ── Notification Modal ───────────────────────────────────────────── */}
      <NotificationModal
        isOpen={notifyModal.isOpen}
        onClose={() => setNotifyModal((prev) => ({ ...prev, isOpen: false }))}
        type={notifyModal.type}
        title={notifyModal.title}
        message={notifyModal.message}
      />
    </div>
  );
};
