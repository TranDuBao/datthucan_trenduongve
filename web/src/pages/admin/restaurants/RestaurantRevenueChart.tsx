import React, { useState } from 'react';
import { BarChart3, Calendar, Filter, DollarSign, ShoppingBag, Eye, Info } from 'lucide-react';
import { apiFetch } from '../../../api/apiClient';
import { Modal } from '../../../components/Modal';
import { StatusBadge } from '../../../components/StatusBadge';

interface TrendItem {
  label: string;
  fullDate?: string;
  revenue: number;
  orders: number;
  ordersCount?: number;
  orderIds?: number[];
}

interface RestaurantRevenueChartProps {
  restaurantId: number;
  revenueTrend?: {
    day?: TrendItem[];
    week?: TrendItem[];
    month?: TrendItem[];
    year?: TrendItem[];
    custom?: TrendItem[];
  };
  chartDataFallback?: any[];
  formatVND: (amount: number) => string;
  allOrders?: any[];
  onViewOrdersTab?: () => void;
}

export const RestaurantRevenueChart: React.FC<RestaurantRevenueChartProps> = ({
  restaurantId,
  revenueTrend,
  chartDataFallback = [],
  formatVND,
  allOrders = [],
  onViewOrdersTab,
}) => {
  const [timeframe, setTimeframe] = useState<'day' | 'week' | 'month' | 'year' | 'single_date' | 'date_range'>('day');
  const [metricMode, setMetricMode] = useState<'revenue' | 'orders'>('revenue');
  const [hoveredIndex, setHoveredIndex] = useState<number | null>(null);
  const [selectedSlot, setSelectedSlot] = useState<TrendItem | null>(null);

  const getTodayStr = () => {
    const d = new Date();
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };

  const getNDaysAgoStr = (days: number) => {
    const d = new Date();
    d.setDate(d.getDate() - days);
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  };

  const [singleDate, setSingleDate] = useState<string>(getTodayStr());
  const [fromDate, setFromDate] = useState<string>(getNDaysAgoStr(6));
  const [toDate, setToDate] = useState<string>(getTodayStr());

  const [customTrend, setCustomTrend] = useState<TrendItem[] | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const fetchCustomData = (type: 'single' | 'range', sDate?: string, fDate?: string, tDate?: string) => {
    setIsLoading(true);
    let url = `/admin/restaurants/${restaurantId}/detail?`;
    if (type === 'single') {
      url += `singleDate=${encodeURIComponent(sDate || singleDate)}`;
    } else {
      url += `fromDate=${encodeURIComponent(fDate || fromDate)}&toDate=${encodeURIComponent(tDate || toDate)}`;
    }

    apiFetch<any>(url)
      .then((res) => {
        const trend = res.data?.customTrend || res.data?.revenueTrend?.custom || [];
        setCustomTrend(trend);
      })
      .catch((err) => {
        console.error('Lỗi tải dữ liệu theo ngày:', err);
      })
      .finally(() => {
        setIsLoading(false);
      });
  };

  const handleSelectTimeframe = (key: 'day' | 'week' | 'month' | 'year' | 'single_date' | 'date_range') => {
    setTimeframe(key);
    if (key === 'single_date') {
      fetchCustomData('single', singleDate);
    } else if (key === 'date_range') {
      fetchCustomData('range', undefined, fromDate, toDate);
    }
  };

  let currentData: TrendItem[] = [];
  if (timeframe === 'single_date' || timeframe === 'date_range') {
    currentData = customTrend || [];
  } else if (revenueTrend?.[timeframe]) {
    currentData = revenueTrend[timeframe] || [];
  } else if (timeframe === 'day') {
    currentData = chartDataFallback.map((c) => ({
      label: c.date,
      fullDate: c.fullDate,
      revenue: c.revenue || 0,
      orders: c.ordersCount || 0,
    }));
  }

  const maxVal = Math.max(
    ...currentData.map((d) => (metricMode === 'revenue' ? d.revenue || 0 : d.orders || d.ordersCount || 0)),
    metricMode === 'revenue' ? 100000 : 5
  );

  const totalRevenue = currentData.reduce((sum, d) => sum + (d.revenue || 0), 0);
  const totalOrders = currentData.reduce((sum, d) => sum + (d.orders || d.ordersCount || 0), 0);

  const formatDateDisplay = (dateStr: string) => {
    if (!dateStr) return '';
    try {
      const parts = dateStr.split('-');
      if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`;
    } catch (_) {}
    return dateStr;
  };

  const getMatchingOrders = (slot: TrendItem | null) => {
    if (!slot || !allOrders || allOrders.length === 0) return [];

    if (slot.orderIds && Array.isArray(slot.orderIds) && slot.orderIds.length > 0) {
      const idSet = new Set(slot.orderIds.map(Number));
      return allOrders.filter((o) => idSet.has(Number(o.maDonHang)));
    }

    return allOrders.filter((ord) => {
      const ordDate = new Date(ord.thoiGianDat);
      if (isNaN(ordDate.getTime())) return false;

      if (timeframe === 'day') {
        return ordDate.toISOString().split('T')[0] === slot.fullDate;
      }
      if (timeframe === 'month') {
        const mNum = parseInt(slot.label.replace(/\D/g, ''), 10);
        if (!isNaN(mNum)) {
          return ordDate.getMonth() + 1 === mNum && ordDate.getFullYear() === new Date().getFullYear();
        }
      }
      if (timeframe === 'year') {
        const yNum = parseInt(slot.label, 10);
        if (!isNaN(yNum)) {
          return ordDate.getFullYear() === yNum;
        }
      }
      return false;
    });
  };

  return (
    <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '18px' }}>
      {/* Top Header & Controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px', marginBottom: '14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <div style={{ width: '32px', height: '32px', borderRadius: '8px', background: '#fff4ee', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <BarChart3 size={18} color="#fc6011" />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
              <h3 style={{ fontSize: '15px', fontWeight: 800, margin: 0, color: '#0f172a' }}>
                Biểu Đồ Phân Tích Doanh Thu & Đơn Hàng Của Quán
              </h3>
              <span style={{ fontSize: '11px', background: '#eff6ff', color: '#2563eb', padding: '2px 8px', borderRadius: '12px', fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                💡 Bấm vào cột để xem chi tiết
              </span>
            </div>
            <p style={{ fontSize: '12px', color: '#64748b', margin: '2px 0 0 0' }}>
              Thống kê bán hàng thực tế từ cơ sở dữ liệu
            </p>
          </div>
        </div>

        {/* Action Controls: Metric Toggle & Timeframe selector */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
          {/* Metric Toggle */}
          <div style={{ display: 'flex', background: '#f1f5f9', padding: '3px', borderRadius: '8px', gap: '2px' }}>
            <button
              onClick={() => setMetricMode('revenue')}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
                padding: '5px 10px',
                fontSize: '12px',
                fontWeight: 700,
                borderRadius: '6px',
                border: 'none',
                cursor: 'pointer',
                background: metricMode === 'revenue' ? '#10b981' : 'transparent',
                color: metricMode === 'revenue' ? '#ffffff' : '#64748b',
                transition: 'all 0.2s',
              }}
            >
              <DollarSign size={13} /> Doanh Thu
            </button>
            <button
              onClick={() => setMetricMode('orders')}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
                padding: '5px 10px',
                fontSize: '12px',
                fontWeight: 700,
                borderRadius: '6px',
                border: 'none',
                cursor: 'pointer',
                background: metricMode === 'orders' ? '#3b82f6' : 'transparent',
                color: metricMode === 'orders' ? '#ffffff' : '#64748b',
                transition: 'all 0.2s',
              }}
            >
              <ShoppingBag size={13} /> Đơn Hàng
            </button>
          </div>

          {/* Timeframe Selector */}
          <div style={{ display: 'flex', background: '#f1f5f9', padding: '3px', borderRadius: '8px', gap: '2px' }}>
            {[
              { key: 'day', label: '7 Ngày' },
              { key: 'week', label: '4 Tuần' },
              { key: 'month', label: '12 Tháng' },
              { key: 'year', label: 'Năm' },
              { key: 'single_date', label: '1 Ngày cụ thể' },
              { key: 'date_range', label: 'Khoảng ngày' },
            ].map((t) => (
              <button
                key={t.key}
                onClick={() => handleSelectTimeframe(t.key as any)}
                style={{
                  padding: '5px 10px',
                  fontSize: '12px',
                  fontWeight: 700,
                  borderRadius: '6px',
                  border: 'none',
                  cursor: 'pointer',
                  background: timeframe === t.key ? '#fc6011' : 'transparent',
                  color: timeframe === t.key ? '#ffffff' : '#64748b',
                  transition: 'all 0.2s',
                }}
              >
                {t.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Date Pickers */}
      {timeframe === 'single_date' && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px', padding: '10px 12px', background: '#fff7ed', borderRadius: '8px', border: '1px solid #fed7aa', flexWrap: 'wrap' }}>
          <Calendar size={18} color="#ea580c" />
          <span style={{ fontSize: '13px', fontWeight: 700, color: '#9a3412' }}>Chọn ngày xem:</span>
          <input
            type="date"
            value={singleDate}
            onChange={(e) => {
              const val = e.target.value;
              setSingleDate(val);
              if (val) fetchCustomData('single', val);
            }}
            style={{ padding: '6px 12px', minHeight: '44px', borderRadius: '8px', border: '1px solid #fdba74', fontSize: '16px', fontWeight: 600, outline: 'none' }}
          />
          <span style={{ fontSize: '12px', color: '#7c2d12', fontStyle: 'italic' }}>
            (Phân bổ theo khung giờ ngày {formatDateDisplay(singleDate)})
          </span>
        </div>
      )}

      {timeframe === 'date_range' && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px', padding: '10px 12px', background: '#fff7ed', borderRadius: '8px', border: '1px solid #fed7aa', flexWrap: 'wrap' }}>
          <Filter size={18} color="#ea580c" />
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '13px', fontWeight: 700, color: '#9a3412' }}>Từ ngày:</span>
            <input
              type="date"
              value={fromDate}
              onChange={(e) => setFromDate(e.target.value)}
              style={{ padding: '6px 12px', minHeight: '44px', borderRadius: '8px', border: '1px solid #fdba74', fontSize: '16px', fontWeight: 600, outline: 'none' }}
            />
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '13px', fontWeight: 700, color: '#9a3412' }}>Đến ngày:</span>
            <input
              type="date"
              value={toDate}
              onChange={(e) => setToDate(e.target.value)}
              style={{ padding: '6px 12px', minHeight: '44px', borderRadius: '8px', border: '1px solid #fdba74', fontSize: '16px', fontWeight: 600, outline: 'none' }}
            />
          </div>
          <button
            onClick={() => fetchCustomData('range', undefined, fromDate, toDate)}
            style={{
              padding: '8px 16px',
              minHeight: '44px',
              background: '#fc6011',
              color: '#ffffff',
              border: 'none',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: 700,
              cursor: 'pointer',
            }}
          >
            Lọc kết quả
          </button>
        </div>
      )}

      {/* Summary Info */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px', padding: '0 4px', flexWrap: 'wrap', gap: '8px' }}>
        <div style={{ fontSize: '12px', fontWeight: 700, color: '#475569' }}>
          {timeframe === 'day' && 'Biến động 7 ngày gần nhất'}
          {timeframe === 'week' && 'Biến động 4 tuần gần nhất'}
          {timeframe === 'month' && `Biến động 12 tháng năm ${new Date().getFullYear()} (T1 - T12)`}
          {timeframe === 'year' && 'Biến động qua các năm'}
          {timeframe === 'single_date' && `Chi tiết theo giờ ngày ${formatDateDisplay(singleDate)}`}
          {timeframe === 'date_range' && `Từ ngày ${formatDateDisplay(fromDate)} đến ngày ${formatDateDisplay(toDate)}`}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <span style={{ fontSize: '12px', color: '#10b981', fontWeight: 800 }}>
            Doanh thu: {formatVND(totalRevenue)}
          </span>
          <span style={{ fontSize: '12px', color: '#3b82f6', fontWeight: 800 }}>
            Tổng đơn: {totalOrders} đơn
          </span>
        </div>
      </div>

      {/* Bar Chart Container */}
      <div
        style={{
          position: 'relative',
          background: 'linear-gradient(180deg, #fafafa 0%, #f8fafc 100%)',
          borderRadius: '10px',
          padding: '20px 16px 12px 16px',
          border: '1px solid #f1f5f9',
          overflowX: 'auto',
        }}
      >
        {isLoading ? (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '160px', color: '#64748b', fontSize: '13px', fontWeight: 600 }}>
            Đang tổng hợp dữ liệu...
          </div>
        ) : currentData.length === 0 ? (
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '160px', color: '#94a3b8', fontSize: '13px' }}>
            Không có dữ liệu trong khoảng thời gian đã chọn
          </div>
        ) : (
          <div
            style={{
              display: 'flex',
              alignItems: 'flex-end',
              justifyContent: 'space-between',
              height: '160px',
              gap: currentData.length > 8 ? '8px' : '14px',
              width: '100%',
              minWidth: currentData.length > 8 ? `${Math.max(currentData.length * 48, 560)}px` : '100%',
              padding: '0 4px',
            }}
          >
            {currentData.map((d, idx) => {
              const val = metricMode === 'revenue' ? d.revenue || 0 : d.orders || d.ordersCount || 0;
              const heightPercent = maxVal > 0 ? Math.max((val / maxVal) * 100, 8) : 8;
              const isHovered = hoveredIndex === idx;
              const currentMonthNum = new Date().getMonth() + 1;
              const isCurrentMonth = timeframe === 'month' && (d.label === `T${currentMonthNum}` || d.label === `Thg ${currentMonthNum}`);

              return (
                <div
                  key={idx}
                  onClick={() => setSelectedSlot(d)}
                  onMouseEnter={() => setHoveredIndex(idx)}
                  onMouseLeave={() => setHoveredIndex(null)}
                  style={{
                    flex: 1,
                    minWidth: '28px',
                    maxWidth: '64px',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    height: '100%',
                    justifyContent: 'flex-end',
                    position: 'relative',
                    cursor: 'pointer',
                    transform: isHovered ? 'translateY(-2px)' : 'none',
                    transition: 'transform 0.15s ease',
                  }}
                >
                  {/* Tooltip */}
                  {isHovered && (
                    <div
                      style={{
                        position: 'absolute',
                        bottom: heightPercent > 55 ? 'auto' : `${heightPercent + 14}%`,
                        top: heightPercent > 55 ? '8px' : 'auto',
                        background: '#0f172a',
                        color: '#ffffff',
                        padding: '8px 12px',
                        borderRadius: '8px',
                        fontSize: '11px',
                        fontWeight: 700,
                        whiteSpace: 'nowrap',
                        boxShadow: '0 4px 14px rgba(0,0,0,0.3)',
                        zIndex: 20,
                        pointerEvents: 'none',
                        minWidth: '150px',
                      }}
                    >
                      <div style={{ borderBottom: '1px solid #334155', paddingBottom: '3px', marginBottom: '3px' }}>{d.fullDate || d.label}</div>
                      <div style={{ color: '#34d399', marginTop: '2px' }}>Doanh thu: {formatVND(d.revenue)}</div>
                      <div style={{ color: '#60a5fa', marginTop: '1px' }}>Số đơn: {d.orders || d.ordersCount || 0} đơn</div>
                      <div style={{ color: '#fb923c', marginTop: '4px', fontSize: '10px', display: 'flex', alignItems: 'center', gap: '3px' }}>
                        <span>👆 Bấm để xem chi tiết</span>
                      </div>
                    </div>
                  )}

                  {/* Value on top of bar */}
                  <div
                    style={{
                      fontSize: '10px',
                      fontWeight: val > 0 ? 800 : 500,
                      color: val > 0 ? (metricMode === 'revenue' ? '#10b981' : '#3b82f6') : '#cbd5e1',
                      marginBottom: '4px',
                      whiteSpace: 'nowrap',
                      textAlign: 'center',
                    }}
                  >
                    {metricMode === 'revenue'
                      ? val > 0
                        ? val >= 1000000
                          ? `${(val / 1000000).toFixed(1)}M`
                          : `${(val / 1000).toFixed(0)}k`
                        : '-'
                      : val > 0
                      ? `${val}`
                      : '-'}
                  </div>

                  {/* Bar */}
                  <div
                    style={{
                      width: '65%',
                      maxWidth: '28px',
                      minWidth: '12px',
                      height: `${heightPercent}%`,
                      background:
                        val > 0
                          ? metricMode === 'revenue'
                            ? isHovered
                              ? 'linear-gradient(180deg, #059669 0%, #10b981 100%)'
                              : 'linear-gradient(180deg, #10b981 0%, #34d399 100%)'
                            : isHovered
                            ? 'linear-gradient(180deg, #2563eb 0%, #3b82f6 100%)'
                            : 'linear-gradient(180deg, #3b82f6 0%, #60a5fa 100%)'
                          : isHovered
                          ? '#94a3b8'
                          : '#e2e8f0',
                      borderRadius: '5px 5px 0 0',
                      transition: 'height 0.4s ease, background 0.2s ease',
                      boxShadow: isHovered && val > 0 ? '0 3px 8px rgba(0,0,0,0.2)' : 'none',
                    }}
                  />

                  {/* Label */}
                  <div
                    style={{
                      fontSize: '11px',
                      color: isCurrentMonth ? '#ea580c' : isHovered ? '#0f172a' : '#64748b',
                      marginTop: '6px',
                      fontWeight: isCurrentMonth || isHovered ? 800 : 600,
                      textAlign: 'center',
                      whiteSpace: 'nowrap',
                      padding: isCurrentMonth ? '1px 4px' : '0',
                      borderRadius: isCurrentMonth ? '4px' : '0',
                      background: isCurrentMonth ? '#ffedd5' : 'transparent',
                    }}
                  >
                    {d.label}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Detail Modal when clicking on a bar */}
      <Modal
        isOpen={!!selectedSlot}
        onClose={() => setSelectedSlot(null)}
        title={`Chi Tiết Doanh Thu & Đơn Hàng - ${selectedSlot?.fullDate || selectedSlot?.label || ''}`}
        maxWidth="800px"
      >
        {selectedSlot && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            {/* Quick KPI Cards */}
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: '12px' }}>
              <div style={{ background: '#ecfdf5', border: '1px solid #a7f3d0', padding: '12px 14px', borderRadius: '10px' }}>
                <div style={{ fontSize: '12px', color: '#047857', fontWeight: 600 }}>Doanh Thu Mốc Này</div>
                <div style={{ fontSize: '18px', fontWeight: 800, color: '#065f46', marginTop: '4px' }}>
                  {formatVND(selectedSlot.revenue)}
                </div>
              </div>

              <div style={{ background: '#eff6ff', border: '1px solid #bfdbfe', padding: '12px 14px', borderRadius: '10px' }}>
                <div style={{ fontSize: '12px', color: '#1d4ed8', fontWeight: 600 }}>Số Đơn Hoàn Tất</div>
                <div style={{ fontSize: '18px', fontWeight: 800, color: '#1e40af', marginTop: '4px' }}>
                  {selectedSlot.orders || selectedSlot.ordersCount || 0} Đơn Hàng
                </div>
              </div>

              <div style={{ background: '#fff7ed', border: '1px solid #fed7aa', padding: '12px 14px', borderRadius: '10px' }}>
                <div style={{ fontSize: '12px', color: '#c2410c', fontWeight: 600 }}>Thời Gian</div>
                <div style={{ fontSize: '14px', fontWeight: 800, color: '#9a3412', marginTop: '4px' }}>
                  {selectedSlot.fullDate || selectedSlot.label}
                </div>
              </div>
            </div>

            {/* Matching Orders List */}
            {(() => {
              const matchingOrders = getMatchingOrders(selectedSlot);
              return (
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px', flexWrap: 'wrap', gap: '8px' }}>
                    <div style={{ fontSize: '14px', fontWeight: 800, color: '#0f172a' }}>
                      Danh Sách Đơn Hàng ({matchingOrders.length})
                    </div>
                    {onViewOrdersTab && (
                      <button
                        onClick={() => {
                          setSelectedSlot(null);
                          onViewOrdersTab();
                        }}
                        style={{
                          fontSize: '12px',
                          color: '#fc6011',
                          fontWeight: 700,
                          background: 'none',
                          border: 'none',
                          cursor: 'pointer',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '4px',
                        }}
                      >
                        <ShoppingBag size={14} /> Xem trong tab Lịch Sử Đơn Hàng
                      </button>
                    )}
                  </div>

                  {matchingOrders.length === 0 ? (
                    <div style={{ textAlign: 'center', padding: '32px 16px', background: '#f8fafc', borderRadius: '10px', color: '#64748b' }}>
                      <ShoppingBag size={32} style={{ opacity: 0.4, margin: '0 auto 8px auto' }} />
                      <div style={{ fontSize: '14px', fontWeight: 600 }}>Không có đơn hàng nào trong mốc này</div>
                      <p style={{ fontSize: '12px', color: '#94a3b8', margin: '4px 0 0 0' }}>
                        Chưa ghi nhận đơn hàng hoàn tất hoặc đã thanh toán trong khoảng thời gian này.
                      </p>
                    </div>
                  ) : (
                    <div style={{ maxHeight: '340px', overflowY: 'auto', border: '1px solid #e2e8f0', borderRadius: '10px' }}>
                      <table className="data-table" style={{ margin: 0, width: '100%' }}>
                        <thead>
                          <tr>
                            <th style={{ width: '50px', textAlign: 'center' }}>STT</th>
                            <th>Mã Đơn</th>
                            <th>Khách Hàng</th>
                            <th>Tổng Tiền</th>
                            <th>Thời Gian Đặt</th>
                            <th>Trạng Thái</th>
                          </tr>
                        </thead>
                        <tbody>
                          {matchingOrders.map((ord: any, idx: number) => (
                            <tr key={ord.maDonHang}>
                              <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{idx + 1}</td>
                              <td style={{ fontWeight: 700 }}>#{ord.maDonHang}</td>
                              <td>{ord.tenKhachHang || `Khách #${ord.maKhachHang}`}</td>
                              <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(ord.tongTien)}</td>
                              <td style={{ fontSize: '12px' }}>{new Date(ord.thoiGianDat).toLocaleString('vi-VN')}</td>
                              <td><StatusBadge status={ord.trangThai} /></td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              );
            })()}

            {/* Modal Actions */}
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', paddingTop: '8px', borderTop: '1px solid #e2e8f0' }}>
              <button
                type="button"
                onClick={() => setSelectedSlot(null)}
                className="btn btn-outline"
                style={{ padding: '8px 18px', fontSize: '13px', fontWeight: 600 }}
              >
                Đóng
              </button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};

