import React, { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { apiFetch } from '../../api/apiClient';
import { getSocket } from '../../api/socketClient';
import { normalizeReservationStatus } from '../../components/restaurant/ReservationStatusBadge';
import { ReservationTable } from '../../components/restaurant/ReservationTable';
import { ReservationDetailModal } from '../../components/restaurant/ReservationDetailModal';
import { CreateReservationModal } from '../../components/restaurant/CreateReservationModal';
import { TableManagementView } from '../../components/restaurant/TableManagementView';
import { ReservationCalendarView } from '../../components/restaurant/ReservationCalendarView';
import { NotificationModal } from '../../components/NotificationModal';
import { UnderlineTabs } from '../../components/UnderlineTabs';
import {
  CalendarDays,
  Clock,
  CheckCircle2,
  Utensils,
  Search,
  RefreshCw,
  Plus,
  ChevronLeft,
  ChevronRight,
  List,
  Calendar as CalendarIcon,
  AlertCircle,
  RotateCcw,
} from 'lucide-react';

const ACTIVE_STATUSES = ['CHO_XAC_NHAN', 'DA_XAC_NHAN', 'DA_DEN', 'DANG_SU_DUNG'];
const HISTORY_STATUSES = ['DA_HOAN_TAT', 'KHACH_KHONG_DEN', 'DA_HUY', 'TU_CHOI'];

export const RestaurantReservations: React.FC = () => {
  // Main Tab State: 'reservations' | 'tables'
  const [activeTab, setActiveTab] = useState<'reservations' | 'tables'>('reservations');

  // Sub Tab State for Reservations (?tab=pending | ?tab=history)
  const [searchParams, setSearchParams] = useSearchParams();
  const tabFromUrl = searchParams.get('tab');
  const reservationTab: 'pending' | 'history' = tabFromUrl === 'history' ? 'history' : 'pending';

  // Sub View Mode State for Reservations: 'list' | 'calendar'
  const [viewMode, setViewMode] = useState<'list' | 'calendar'>('list');

  // Dashboard Stats
  const [stats, setStats] = useState<{
    choXacNhan: number;
    daXacNhan: number;
    homNay: number;
    dangSuDung: number;
    daHoanTat: number;
  }>({
    choXacNhan: 0,
    daXacNhan: 0,
    homNay: 0,
    dangSuDung: 0,
    daHoanTat: 0,
  });

  // Table List State
  const [tables, setTables] = useState<any[]>([]);

  // Reservation Filters State
  const [timeRange, setTimeRange] = useState<string>('all');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');
  const [trangThaiFilter, setTrangThaiFilter] = useState<string>('ALL');
  const [tableFilter, setTableFilter] = useState<string>('ALL');
  const [searchInput, setSearchInput] = useState<string>('');
  const [appliedSearch, setAppliedSearch] = useState<string>('');

  // Pagination State for Tab 2 ("Hoàn tất / Lịch sử")
  const [page, setPage] = useState<number>(1);
  const [limit, setLimit] = useState<number>(15);

  // Data & Loading State
  const [allReservations, setAllReservations] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Modals State
  const [selectedReservation, setSelectedReservation] = useState<any | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);

  // Toast Notification State
  const [notifyModal, setNotifyModal] = useState<{
    isOpen: boolean;
    type: 'success' | 'error' | 'warning' | 'info';
    title: string;
    message: string;
  }>({
    isOpen: false,
    type: 'info',
    title: '',
    message: '',
  });

  const handleReservationTabChange = (newTab: 'pending' | 'history') => {
    if (newTab === reservationTab) return;
    setTrangThaiFilter('ALL');
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

  // Fetch Dashboard Stats & Tables
  const fetchStatsAndTables = async () => {
    try {
      const [statsRes, tablesRes] = await Promise.all([
        apiFetch<any>('/restaurant/reservations/stats'),
        apiFetch<any>('/restaurant/tables'),
      ]);
      if (statsRes.data) setStats(statsRes.data);
      if (tablesRes.data) setTables(tablesRes.data);
    } catch (_) {}
  };

  // Fetch Reservations List
  const fetchReservations = async () => {
    setLoading(true);
    setError(null);
    try {
      const queryParams = new URLSearchParams();
      if (timeRange !== 'all') queryParams.append('timeRange', timeRange);
      if (timeRange === 'custom' && startDate && endDate) {
        queryParams.append('startDate', startDate);
        queryParams.append('endDate', endDate);
      }
      if (tableFilter !== 'ALL') queryParams.append('maBan', tableFilter);
      if (appliedSearch.trim()) queryParams.append('search', appliedSearch.trim());

      queryParams.append('page', '1');
      queryParams.append('limit', '100');

      const res = await apiFetch<any>(`/restaurant/reservations?${queryParams.toString()}`);
      if (res.reservations) {
        setAllReservations(res.reservations);
      }
    } catch (err: any) {
      setError(err.message || 'Không thể tải danh sách đặt bàn');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchStatsAndTables();
  }, []);

  useEffect(() => {
    fetchReservations();

    const socket = getSocket();
    if (socket) {
      const handleRealtimeReservation = (payload: any) => {
        console.log('⚡ Realtime reservation update received:', payload);
        fetchStatsAndTables();
        fetchReservations();
      };

      socket.on('reservation:created', handleRealtimeReservation);
      socket.on('reservation:status_changed', handleRealtimeReservation);

      return () => {
        socket.off('reservation:created', handleRealtimeReservation);
        socket.off('reservation:status_changed', handleRealtimeReservation);
      };
    }
  }, [timeRange, startDate, endDate, tableFilter, appliedSearch]);

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

  const isFilterActive =
    trangThaiFilter !== 'ALL' ||
    timeRange !== 'all' ||
    tableFilter !== 'ALL' ||
    appliedSearch.trim() !== '' ||
    startDate !== '' ||
    endDate !== '';

  const handleResetFilters = () => {
    setTrangThaiFilter('ALL');
    setTimeRange('all');
    setStartDate('');
    setEndDate('');
    setTableFilter('ALL');
    setSearchInput('');
    setAppliedSearch('');
    setPage(1);
  };

  const handleCardClick = (targetStatus: string, targetTab: 'pending' | 'history') => {
    setActiveTab('reservations');
    if (reservationTab !== targetTab) {
      handleReservationTabChange(targetTab);
    }
    if (trangThaiFilter === targetStatus && timeRange === 'all') {
      setTrangThaiFilter('ALL');
    } else {
      setTrangThaiFilter(targetStatus);
      setTimeRange('all');
    }
    setPage(1);
  };

  const handleTodayCardClick = () => {
    setActiveTab('reservations');
    if (timeRange === 'today' && trangThaiFilter === 'ALL') {
      setTimeRange('all');
    } else {
      setTimeRange('today');
      setTrangThaiFilter('ALL');
    }
    setPage(1);
  };

  // Handle Reservation Status Change / Action
  const handleAction = async (idOrAction: number | string, actionTypeOrNote?: string, noteParam?: string) => {
    let id: number;
    let actionType: string;
    let note: string | undefined = noteParam;

    if (typeof idOrAction === 'number') {
      id = idOrAction;
      actionType = actionTypeOrNote || '';
    } else {
      if (!selectedReservation) return;
      id = selectedReservation.maDatBan;
      actionType = idOrAction;
      note = actionTypeOrNote;
    }

    if (!id || !actionType) return;

    let endpoint = actionType.toLowerCase().trim().replace(/_/g, '-');
    if (endpoint === 'checkin') endpoint = 'check-in';
    if (endpoint === 'noshow') endpoint = 'no-show';

    setActionLoading(true);
    try {
      const res = await apiFetch<any>(`/restaurant/reservations/${id}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ note }),
      });

      setSelectedReservation(null);
      setNotifyModal({
        isOpen: true,
        type: 'success',
        title: 'Thành công',
        message: res.message || 'Cập nhật trạng thái đặt bàn thành công!',
      });

      fetchStatsAndTables();
      fetchReservations();
    } catch (err: any) {
      setSelectedReservation(null);
      setNotifyModal({
        isOpen: true,
        type: 'error',
        title: 'Thất bại',
        message: err.message || 'Lỗi khi cập nhật trạng thái',
      });
    } finally {
      setActionLoading(false);
    }
  };

  // Filter & Categorize Reservations
  const activeList = allReservations.filter((r) => {
    const norm = normalizeReservationStatus(r.trangThai);
    return ACTIVE_STATUSES.includes(norm);
  });

  const displayActiveList = activeList.filter((r) => {
    if (trangThaiFilter === 'ALL') return true;
    return normalizeReservationStatus(r.trangThai) === trangThaiFilter;
  });

  // Sort CHO_XAC_NHAN to top, then newest
  const sortedActiveList = [...displayActiveList].sort((a, b) => {
    const aIsPending = normalizeReservationStatus(a.trangThai) === 'CHO_XAC_NHAN';
    const bIsPending = normalizeReservationStatus(b.trangThai) === 'CHO_XAC_NHAN';
    if (aIsPending && !bIsPending) return -1;
    if (!aIsPending && bIsPending) return 1;
    const timeA = new Date(a.thoiGianBatDau || 0).getTime();
    const timeB = new Date(b.thoiGianBatDau || 0).getTime();
    return timeB - timeA;
  });

  const historyList = allReservations.filter((r) => {
    const norm = normalizeReservationStatus(r.trangThai);
    return HISTORY_STATUSES.includes(norm);
  });

  const displayHistoryList = historyList.filter((r) => {
    if (trangThaiFilter === 'ALL') return true;
    return normalizeReservationStatus(r.trangThai) === trangThaiFilter;
  });

  const sortedHistoryList = [...displayHistoryList].sort((a, b) => {
    const timeA = new Date(a.thoiGianBatDau || 0).getTime();
    const timeB = new Date(b.thoiGianBatDau || 0).getTime();
    return timeB - timeA;
  });

  const historyTotal = sortedHistoryList.length;
  const historyTotalPages = Math.max(1, Math.ceil(historyTotal / limit));
  const paginatedHistoryList = sortedHistoryList.slice((page - 1) * limit, page * limit);

  const hasPendingReservations =
    activeList.some((r) => normalizeReservationStatus(r.trangThai) === 'CHO_XAC_NHAN') ||
    stats.choXacNhan > 0;

  return (
    <div style={{ paddingBottom: '40px' }}>
      {/* Top Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h1 style={{ margin: 0, fontSize: '24px', fontWeight: 800, color: '#1e293b' }}>
            Quản Lý Đặt Bàn
          </h1>
          <p style={{ margin: '4px 0 0 0', fontSize: '14px', color: '#64748b' }}>
            Theo dõi, điều phối lịch hẹn và quản lý trạng thái các bàn phục vụ tại nhà hàng
          </p>
        </div>

        <div style={{ display: 'flex', gap: '12px' }}>
          <button
            onClick={() => { fetchStatsAndTables(); fetchReservations(); }}
            className="btn"
            style={{ background: '#ffffff', color: '#475569', border: '1px solid #cbd5e1', display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <RefreshCw size={16} className={loading ? 'spin' : ''} /> Làm mới
          </button>
          <button
            onClick={() => setShowCreateModal(true)}
            className="btn btn-primary"
            style={{ background: '#fc6011', borderColor: '#fc6011', display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 700 }}
          >
            <Plus size={18} /> Thêm Đặt Bàn Mới
          </button>
        </div>
      </div>

      {/* Dashboard Overview Cards */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: '16px',
          marginBottom: '28px',
        }}
      >
        {[
          {
            key: 'CHO_XAC_NHAN',
            label: 'Chờ xác nhận',
            count: stats.choXacNhan,
            icon: <Clock size={20} color="#ca8a04" />,
            iconBg: '#fef9c3',
            color: '#ca8a04',
            borderActive: '2px solid #eab308',
            isActive: reservationTab === 'pending' && trangThaiFilter === 'CHO_XAC_NHAN' && timeRange === 'all',
            onClick: () => handleCardClick('CHO_XAC_NHAN', 'pending'),
          },
          {
            key: 'DA_XAC_NHAN',
            label: 'Đã xác nhận',
            count: stats.daXacNhan,
            icon: <CheckCircle2 size={20} color="#0284c7" />,
            iconBg: '#e0f2fe',
            color: '#0284c7',
            borderActive: '2px solid #0284c7',
            isActive: reservationTab === 'pending' && trangThaiFilter === 'DA_XAC_NHAN' && timeRange === 'all',
            onClick: () => handleCardClick('DA_XAC_NHAN', 'pending'),
          },
          {
            key: 'today',
            label: 'Lịch hẹn Hôm Nay',
            count: stats.homNay,
            icon: <CalendarDays size={20} color="#fc6011" />,
            iconBg: '#ffedd5',
            color: '#fc6011',
            borderActive: '2px solid #fc6011',
            isActive: timeRange === 'today' && trangThaiFilter === 'ALL',
            onClick: handleTodayCardClick,
          },
          {
            key: 'DANG_SU_DUNG',
            label: 'Đang sử dụng',
            count: stats.dangSuDung,
            icon: <Utensils size={20} color="#7e22ce" />,
            iconBg: '#f3e8ff',
            color: '#7e22ce',
            borderActive: '2px solid #7e22ce',
            isActive: reservationTab === 'pending' && trangThaiFilter === 'DANG_SU_DUNG' && timeRange === 'all',
            onClick: () => handleCardClick('DANG_SU_DUNG', 'pending'),
          },
          {
            key: 'DA_HOAN_TAT',
            label: 'Hoàn tất',
            count: stats.daHoanTat,
            icon: <CheckCircle2 size={20} color="#16a34a" />,
            iconBg: '#dcfce7',
            color: '#16a34a',
            borderActive: '2px solid #16a34a',
            isActive: reservationTab === 'history' && trangThaiFilter === 'DA_HOAN_TAT' && timeRange === 'all',
            onClick: () => handleCardClick('DA_HOAN_TAT', 'history'),
          },
        ].map((card) => (
          <div
            key={card.key}
            onClick={card.onClick}
            style={{
              background: '#ffffff',
              borderRadius: '16px',
              padding: '20px',
              border: card.isActive ? card.borderActive : '1px solid #e2e8f0',
              boxShadow: '0 2px 4px rgba(0,0,0,0.03)',
              cursor: 'pointer',
              transition: 'all 0.2s ease',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
              <span style={{ fontSize: '13px', color: '#64748b', fontWeight: 600 }}>{card.label}</span>
              <div style={{ width: '36px', height: '36px', borderRadius: '10px', background: card.iconBg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {card.icon}
              </div>
            </div>
            <div style={{ fontSize: '28px', fontWeight: 800, color: card.color }}>
              {card.count}
            </div>
          </div>
        ))}
      </div>

      {/* Main Tabs Header (Reservations vs Tables) */}
      <UnderlineTabs
        tabs={[
          { key: 'reservations', label: 'Danh Sách Đặt Bàn', icon: <CalendarDays size={18} /> },
          { key: 'tables', label: 'Quản Lý Bàn Phục Vụ', icon: <Utensils size={18} /> },
        ]}
        activeTab={activeTab}
        onChange={(k) => setActiveTab(k as 'reservations' | 'tables')}
        rightExtra={
          activeTab === 'reservations' && (
            <div style={{ display: 'flex', background: '#f1f5f9', padding: '4px', borderRadius: '10px', gap: '4px' }}>
              <button
                onClick={() => setViewMode('list')}
                style={{
                  padding: '6px 14px',
                  borderRadius: '8px',
                  border: 'none',
                  background: viewMode === 'list' ? '#ffffff' : 'transparent',
                  color: viewMode === 'list' ? '#1e293b' : '#64748b',
                  fontWeight: 600,
                  fontSize: '13px',
                  cursor: 'pointer',
                  boxShadow: viewMode === 'list' ? '0 1px 2px rgba(0,0,0,0.1)' : 'none',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                }}
              >
                <List size={15} /> Bảng danh sách
              </button>
              <button
                onClick={() => setViewMode('calendar')}
                style={{
                  padding: '6px 14px',
                  borderRadius: '8px',
                  border: 'none',
                  background: viewMode === 'calendar' ? '#ffffff' : 'transparent',
                  color: viewMode === 'calendar' ? '#1e293b' : '#64748b',
                  fontWeight: 600,
                  fontSize: '13px',
                  cursor: 'pointer',
                  boxShadow: viewMode === 'calendar' ? '0 1px 2px rgba(0,0,0,0.1)' : 'none',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                }}
              >
                <CalendarIcon size={15} /> Lịch theo giờ
              </button>
            </div>
          )
        }
      />

      {/* TAB 1: RESERVATIONS VIEW */}
      {activeTab === 'reservations' && (
        <>
          {/* Filters Bar */}
          <div
            style={{
              background: '#ffffff',
              borderRadius: '16px',
              padding: '20px',
              border: '1px solid #e2e8f0',
              marginBottom: '20px',
              display: 'flex',
              flexDirection: 'column',
              gap: '16px',
            }}
          >
            <form onSubmit={handleSearchSubmit} style={{ display: 'flex', flexWrap: 'wrap', gap: '12px', alignItems: 'center' }}>
              {/* Search Box */}
              <div style={{ flex: 1, minWidth: '240px', position: 'relative' }}>
                <Search size={18} color="#94a3b8" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
                <input
                  type="text"
                  placeholder="Tìm mã đặt bàn, tên khách, số điện thoại, tên bàn..."
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  style={{
                    width: '100%',
                    paddingLeft: '38px',
                    paddingRight: searchInput ? '34px' : '12px',
                    paddingTop: '9px',
                    paddingBottom: '9px',
                    borderRadius: '10px',
                    border: '1px solid #cbd5e1',
                    fontSize: '14px',
                  }}
                />
                {searchInput && (
                  <button
                    type="button"
                    onClick={handleClearSearch}
                    style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#94a3b8', fontSize: '16px' }}
                  >
                    ×
                  </button>
                )}
              </div>

              {/* Time Range Filter */}
              <select
                value={timeRange}
                onChange={(e) => { setTimeRange(e.target.value); setPage(1); }}
                style={{ padding: '9px 12px', borderRadius: '10px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: 600 }}
              >
                <option value="all">Tất cả thời gian</option>
                <option value="today">Hôm nay</option>
                <option value="tomorrow">Ngày mai</option>
                <option value="7days">7 ngày tới</option>
                <option value="30days">30 ngày tới</option>
                <option value="custom">Tùy chọn ngày</option>
              </select>

              {/* Custom Date Pickers */}
              {timeRange === 'custom' && (
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <input
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    style={{ padding: '8px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                  />
                  <span>➔</span>
                  <input
                    type="date"
                    value={endDate}
                    onChange={(e) => setEndDate(e.target.value)}
                    style={{ padding: '8px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
                  />
                </div>
              )}

              {/* Status Filter (Context-aware based on active tab) */}
              <select
                value={trangThaiFilter}
                onChange={(e) => { setTrangThaiFilter(e.target.value); setPage(1); }}
                style={{ padding: '9px 12px', borderRadius: '10px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: 600 }}
              >
                {reservationTab === 'pending' ? (
                  <>
                    <option value="ALL">Tất cả trạng thái cần xử lý</option>
                    <option value="CHO_XAC_NHAN">Chờ xác nhận</option>
                    <option value="DA_XAC_NHAN">Đã xác nhận</option>
                    <option value="DA_DEN">Khách đã đến</option>
                    <option value="DANG_SU_DUNG">Đang sử dụng</option>
                  </>
                ) : (
                  <>
                    <option value="ALL">Tất cả trạng thái lịch sử</option>
                    <option value="DA_HOAN_TAT">Hoàn tất</option>
                    <option value="KHACH_KHONG_DEN">Khách không đến</option>
                    <option value="DA_HUY">Đã hủy</option>
                    <option value="TU_CHOI">Từ chối</option>
                  </>
                )}
              </select>

              {/* Table Filter */}
              <select
                value={tableFilter}
                onChange={(e) => { setTableFilter(e.target.value); setPage(1); }}
                style={{ padding: '9px 12px', borderRadius: '10px', border: '1px solid #cbd5e1', fontSize: '14px', fontWeight: 600 }}
              >
                <option value="ALL">Tất cả bàn</option>
                {tables.map((t) => (
                  <option key={t.maBan} value={t.maBan}>
                    {t.tenBan}
                  </option>
                ))}
              </select>

              <button type="submit" className="btn btn-primary" style={{ background: '#fc6011', borderColor: '#fc6011', padding: '9px 16px' }}>
                Tìm kiếm
              </button>

              {isFilterActive && (
                <button
                  type="button"
                  onClick={handleResetFilters}
                  style={{
                    background: 'none',
                    border: 'none',
                    cursor: 'pointer',
                    color: '#ef4444',
                    fontSize: '13px',
                    fontWeight: 700,
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: '4px',
                    marginLeft: 'auto',
                  }}
                  title="Xóa bộ lọc"
                >
                  <RotateCcw size={14} /> Xóa bộ lọc
                </button>
              )}
            </form>

            {/* Search Active Notification */}
            {appliedSearch.trim() && (
              <div style={{
                background: '#eff6ff',
                border: '1px solid #bfdbfe',
                borderRadius: '8px',
                padding: '8px 14px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: '8px',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '13px', color: '#1d4ed8' }}>
                  <Search size={14} color="#3b82f6" />
                  <span>
                    Đang tìm kiếm <strong>"{appliedSearch}"</strong> trong toàn bộ danh sách đặt bàn
                  </span>
                </div>
                <button
                  type="button"
                  onClick={handleClearSearch}
                  style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#3b82f6', fontSize: '12px', fontWeight: 700 }}
                >
                  Xóa tìm kiếm
                </button>
              </div>
            )}
          </div>

          {/* Render List View or Calendar View */}
          {viewMode === 'calendar' ? (
            <ReservationCalendarView
              reservations={allReservations}
              onSelectReservation={(res) => setSelectedReservation(res)}
              loading={loading}
            />
          ) : (
            <>
              {/* ── Sub Tabs Navigation (Cần xử lý vs Hoàn tất / Lịch sử) ── */}
              <UnderlineTabs
                tabs={[
                  {
                    key: 'pending',
                    label: 'Cần xử lý',
                    icon: <Clock size={18} />,
                    count: activeList.length,
                    highlightCount: hasPendingReservations,
                  },
                  {
                    key: 'history',
                    label: 'Hoàn tất / Lịch sử',
                    icon: <CheckCircle2 size={18} />,
                    count: historyList.length,
                    highlightCount: false,
                  },
                ]}
                activeTab={reservationTab}
                onChange={handleReservationTabChange}
              />

              {loading ? (
                <div style={{ background: '#ffffff', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '48px', textAlign: 'center', color: '#64748b' }}>
                  <RefreshCw size={28} className="spin" style={{ marginBottom: '12px' }} />
                  <div>Đang tải dữ liệu đặt bàn...</div>
                </div>
              ) : error ? (
                <div style={{ background: '#fef2f2', borderRadius: '16px', border: '1px solid #fecaca', padding: '48px', textAlign: 'center', color: '#ef4444' }}>
                  <AlertCircle size={32} style={{ marginBottom: '12px' }} />
                  <div style={{ fontWeight: 600 }}>{error}</div>
                  <button onClick={fetchReservations} className="btn btn-primary" style={{ marginTop: '16px', background: '#fc6011' }}>
                    Thử lại
                  </button>
                </div>
              ) : reservationTab === 'pending' ? (
                /* ══════════════════════════════════════════════════════════════════
                    TAB 1: "Cần xử lý" (Chờ xác nhận, Đã xác nhận, Khách đã đến, Đang dùng)
                   ══════════════════════════════════════════════════════════════════ */
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px', padding: '0 4px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <h3 style={{ fontSize: '15px', fontWeight: 800, color: '#0f172a', margin: 0, display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span>Đặt Bàn Cần Xử Lý</span>
                        <span
                          style={{
                            background: sortedActiveList.length > 0 ? '#ea580c' : '#94a3b8',
                            color: '#ffffff',
                            fontSize: '11px',
                            fontWeight: 700,
                            padding: '2px 8px',
                            borderRadius: '12px',
                          }}
                        >
                          {sortedActiveList.length}
                        </span>
                      </h3>
                    </div>
                    <span style={{ fontSize: '12px', color: '#64748b' }}>
                      Các lượt đặt bàn chờ xác nhận, đã xác nhận & đang phục vụ
                    </span>
                  </div>

                  <ReservationTable
                    items={sortedActiveList}
                    startIndex={0}
                    showActions={true}
                    emptyTitle="Không có lượt đặt bàn nào cần xử lý"
                    emptySubtitle="Tất cả các lượt đặt bàn hiện tại đã được xác nhận và hoàn tất."
                    actionLoading={actionLoading}
                    onSelectReservation={setSelectedReservation}
                    onAction={handleAction}
                  />
                </div>
              ) : (
                /* ══════════════════════════════════════════════════════════════════
                    TAB 2: "Hoàn tất / Lịch sử" (Hoàn tất, Khách không đến, Đã hủy, Từ chối)
                   ══════════════════════════════════════════════════════════════════ */
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px', padding: '0 4px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <h3 style={{ fontSize: '15px', fontWeight: 800, color: '#0f172a', margin: 0, display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <span>Lịch Sử Đặt Bàn</span>
                        <span
                          style={{
                            background: historyTotal > 0 ? '#10b981' : '#94a3b8',
                            color: '#ffffff',
                            fontSize: '11px',
                            fontWeight: 700,
                            padding: '2px 8px',
                            borderRadius: '12px',
                          }}
                        >
                          {historyTotal}
                        </span>
                      </h3>
                    </div>
                    <span style={{ fontSize: '12px', color: '#64748b' }}>
                      Lịch sử các lượt đặt bàn đã hoàn tất, khách không đến hoặc đã hủy
                    </span>
                  </div>

                  <ReservationTable
                    items={paginatedHistoryList}
                    startIndex={(page - 1) * limit}
                    showActions={false}
                    emptyTitle="Chưa có lượt đặt bàn nào trong lịch sử"
                    emptySubtitle="Các lượt đặt bàn sau khi hoàn tất hoặc hủy sẽ được lưu trữ tại đây."
                    onSelectReservation={setSelectedReservation}
                    footer={
                      historyTotal > 0 && (
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
                              <strong style={{ color: '#0f172a' }}>{Math.min(page * limit, historyTotal)}</strong> /{' '}
                              <strong style={{ color: '#0f172a' }}>{historyTotal}</strong> lượt đặt bàn
                            </div>

                            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                              <span style={{ fontSize: '12px', color: '#64748b' }}>Hiển thị:</span>
                              <select
                                value={limit}
                                onChange={(e) => {
                                  setLimit(Number(e.target.value));
                                  setPage(1);
                                }}
                                style={{ width: 'auto', fontSize: '12px', padding: '4px 8px', borderRadius: '6px', border: '1px solid #cbd5e1' }}
                              >
                                <option value={10}>10 / trang</option>
                                <option value={15}>15 / trang</option>
                                <option value={20}>20 / trang</option>
                                <option value={50}>50 / trang</option>
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

                            {Array.from({ length: historyTotalPages }, (_, i) => i + 1)
                              .filter((p) => p === 1 || p === historyTotalPages || Math.abs(p - page) <= 2)
                              .map((p, idx, arr) => {
                                const prev = arr[idx - 1];
                                const showEllipsis = prev && p - prev > 1;

                                return (
                                  <React.Fragment key={p}>
                                    {showEllipsis && <span style={{ padding: '0 4px', color: '#94a3b8', fontSize: '12px' }}>...</span>}
                                    <button
                                      onClick={() => setPage(p)}
                                      style={{
                                        padding: '5px 11px',
                                        borderRadius: '7px',
                                        fontSize: '12px',
                                        fontWeight: 700,
                                        border: page === p ? 'none' : '1px solid #e2e8f0',
                                        background: page === p ? '#fc6011' : '#ffffff',
                                        color: page === p ? '#ffffff' : '#334155',
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
                              onClick={() => setPage((p) => Math.min(p + 1, historyTotalPages))}
                              disabled={page >= historyTotalPages}
                              style={{ padding: '6px 10px', fontSize: '12px', opacity: page >= historyTotalPages ? 0.5 : 1, borderRadius: '7px' }}
                            >
                              <ChevronRight size={15} />
                            </button>
                          </div>
                        </div>
                      )
                    }
                  />
                </div>
              )}
            </>
          )}
        </>
      )}

      {/* TAB 2: TABLE MANAGEMENT VIEW */}
      {activeTab === 'tables' && (
        <TableManagementView
          tables={tables}
          reservations={allReservations}
          onRefresh={fetchStatsAndTables}
          loading={loading}
          onSelectReservation={(res) => setSelectedReservation(res)}
        />
      )}

      {/* Detail Modal */}
      <ReservationDetailModal
        isOpen={!!selectedReservation}
        onClose={() => setSelectedReservation(null)}
        reservation={selectedReservation}
        onAction={handleAction}
        loadingAction={actionLoading}
      />

      {/* Create Modal */}
      <CreateReservationModal
        isOpen={showCreateModal}
        onClose={() => setShowCreateModal(false)}
        tables={tables}
        onSuccess={() => {
          fetchStatsAndTables();
          fetchReservations();
          setNotifyModal({
            isOpen: true,
            type: 'success',
            title: 'Thành công',
            message: 'Đã tạo lượt đặt bàn thành công!',
          });
        }}
      />

      {/* Toast Notification Modal */}
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
