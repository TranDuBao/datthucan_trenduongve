import React, { useState } from 'react';
import { TrendingUp, Calendar, Filter, BarChart2 } from 'lucide-react';
import { apiFetch } from '../../api/apiClient';

interface RevenueTrendItem {
  label: string;
  fullDate?: string;
  revenue: number;
  orders: number;
}

interface RevenueChartSectionProps {
  revenueTrend?: {
    day?: RevenueTrendItem[];
    week?: RevenueTrendItem[];
    month?: RevenueTrendItem[];
    year?: RevenueTrendItem[];
    custom?: RevenueTrendItem[];
  };
  formatVND: (amount: number) => string;
}

export const RevenueChartSection: React.FC<RevenueChartSectionProps> = ({ revenueTrend, formatVND }) => {
  const [revenueTimeframe, setRevenueTimeframe] = useState<'day' | 'week' | 'month' | 'year' | 'single_date' | 'date_range'>('day');
  const [hoveredBarIndex, setHoveredBarIndex] = useState<number | null>(null);

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

  const [customChartData, setCustomChartData] = useState<RevenueTrendItem[] | null>(null);
  const [isCustomLoading, setIsCustomLoading] = useState<boolean>(false);

  const fetchCustomTrend = (type: 'single' | 'range', sDate?: string, fDate?: string, tDate?: string) => {
    setIsCustomLoading(true);
    let url = '/admin/stats?';
    if (type === 'single') {
      url += `singleDate=${encodeURIComponent(sDate || singleDate)}`;
    } else {
      url += `fromDate=${encodeURIComponent(fDate || fromDate)}&toDate=${encodeURIComponent(tDate || toDate)}`;
    }

    apiFetch<any>(url)
      .then((res) => {
        const trend = res.data?.customTrend || res.data?.revenueTrend?.custom || [];
        setCustomChartData(trend);
      })
      .catch((err) => {
        console.error('Error fetching custom revenue trend:', err);
      })
      .finally(() => {
        setIsCustomLoading(false);
      });
  };

  const handleSelectTimeframe = (key: 'day' | 'week' | 'month' | 'year' | 'single_date' | 'date_range') => {
    setRevenueTimeframe(key);
    if (key === 'single_date') {
      fetchCustomTrend('single', singleDate);
    } else if (key === 'date_range') {
      fetchCustomTrend('range', undefined, fromDate, toDate);
    }
  };

  // Determine which data to display
  let currentChartData: RevenueTrendItem[] = [];
  if (revenueTimeframe === 'single_date' || revenueTimeframe === 'date_range') {
    currentChartData = customChartData || [];
  } else {
    currentChartData = revenueTrend?.[revenueTimeframe] || [];
  }

  const maxRevenueInTrend = Math.max(...currentChartData.map((d) => d.revenue || 0), 100000);
  const totalRevenue = currentChartData.reduce((sum, d) => sum + (d.revenue || 0), 0);
  const totalOrders = currentChartData.reduce((sum, d) => sum + (d.orders || 0), 0);

  const formatDateDisplay = (dateStr: string) => {
    if (!dateStr) return '';
    try {
      const parts = dateStr.split('-');
      if (parts.length === 3) {
        return `${parts[2]}/${parts[1]}/${parts[0]}`;
      }
    } catch (_) {}
    return dateStr;
  };

  return (
    <div>
      {/* Header & Controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px', marginBottom: '16px' }}>
        <div>
          <h3 style={{ fontSize: '18px', fontWeight: 800, margin: 0, color: '#0f172a', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <TrendingUp size={20} color="#fc6011" /> Phân Tích & Biểu Đồ Doanh Thu Hệ Thống
          </h3>
          <p style={{ fontSize: '13px', color: '#64748b', margin: '4px 0 0 0' }}>
            Theo dõi biến động doanh thu theo mốc thời gian thực tế
          </p>
        </div>

        {/* Timeframe buttons */}
        <div style={{ display: 'flex', gap: '4px', background: '#f1f5f9', padding: '4px', borderRadius: '10px', flexWrap: 'wrap' }}>
          {[
            { key: 'day', label: '7 Ngày' },
            { key: 'week', label: '4 Tuần' },
            { key: 'month', label: '12 Tháng' },
            { key: 'year', label: 'Các Năm' },
            { key: 'single_date', label: '1 Ngày cụ thể' },
            { key: 'date_range', label: 'Khoảng ngày' },
          ].map((t) => (
            <button
              key={t.key}
              onClick={() => handleSelectTimeframe(t.key as any)}
              style={{
                padding: '6px 12px',
                fontSize: '12px',
                fontWeight: 700,
                borderRadius: '8px',
                border: 'none',
                cursor: 'pointer',
                background: revenueTimeframe === t.key ? '#fc6011' : 'transparent',
                color: revenueTimeframe === t.key ? '#ffffff' : '#64748b',
                transition: 'all 0.2s ease',
                boxShadow: revenueTimeframe === t.key ? '0 2px 6px rgba(252,96,17,0.3)' : 'none',
              }}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>

      {/* Date Pickers for Custom Modes */}
      {revenueTimeframe === 'single_date' && (
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            marginBottom: '16px',
            padding: '10px 16px',
            background: '#fff7ed',
            borderRadius: '12px',
            border: '1px solid #fed7aa',
            flexWrap: 'wrap',
          }}
        >
          <Calendar size={18} color="#ea580c" />
          <span style={{ fontSize: '13px', fontWeight: 700, color: '#9a3412' }}>Chọn ngày xem:</span>
          <input
            type="date"
            value={singleDate}
            onChange={(e) => {
              const val = e.target.value;
              setSingleDate(val);
              if (val) {
                fetchCustomTrend('single', val);
              }
            }}
            style={{
              padding: '6px 12px',
              minHeight: '44px',
              borderRadius: '8px',
              border: '1px solid #fdba74',
              fontSize: '16px',
              fontWeight: 600,
              color: '#1e293b',
              background: '#ffffff',
              outline: 'none',
              cursor: 'pointer',
            }}
          />
          <span style={{ fontSize: '12px', color: '#7c2d12', fontStyle: 'italic' }}>
            (Hiển thị doanh thu phân bổ theo các khung giờ trong ngày {formatDateDisplay(singleDate)})
          </span>
        </div>
      )}

      {revenueTimeframe === 'date_range' && (
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            marginBottom: '16px',
            padding: '10px 16px',
            background: '#fff7ed',
            borderRadius: '12px',
            border: '1px solid #fed7aa',
            flexWrap: 'wrap',
          }}
        >
          <Filter size={18} color="#ea580c" />
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '13px', fontWeight: 700, color: '#9a3412' }}>Từ ngày:</span>
            <input
              type="date"
              value={fromDate}
              onChange={(e) => setFromDate(e.target.value)}
              style={{
                padding: '6px 12px',
                minHeight: '44px',
                borderRadius: '8px',
                border: '1px solid #fdba74',
                fontSize: '16px',
                fontWeight: 600,
                color: '#1e293b',
                background: '#ffffff',
                outline: 'none',
                cursor: 'pointer',
              }}
            />
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '13px', fontWeight: 700, color: '#9a3412' }}>Đến ngày:</span>
            <input
              type="date"
              value={toDate}
              onChange={(e) => setToDate(e.target.value)}
              style={{
                padding: '6px 12px',
                minHeight: '44px',
                borderRadius: '8px',
                border: '1px solid #fdba74',
                fontSize: '16px',
                fontWeight: 600,
                color: '#1e293b',
                background: '#ffffff',
                outline: 'none',
                cursor: 'pointer',
              }}
            />
          </div>
          <button
            onClick={() => fetchCustomTrend('range', undefined, fromDate, toDate)}
            style={{
              padding: '8px 18px',
              minHeight: '44px',
              background: '#fc6011',
              color: '#ffffff',
              border: 'none',
              borderRadius: '8px',
              fontSize: '13px',
              fontWeight: 700,
              cursor: 'pointer',
              boxShadow: '0 2px 6px rgba(252,96,17,0.3)',
              transition: 'opacity 0.2s',
            }}
          >
            Lọc kết quả
          </button>
        </div>
      )}

      {/* Summary Info Bar */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          marginBottom: '12px',
          padding: '0 4px',
          flexWrap: 'wrap',
          gap: '8px',
        }}
      >
        <div style={{ fontSize: '13px', fontWeight: 700, color: '#475569' }}>
          {revenueTimeframe === 'day' && 'Biến động doanh thu 7 ngày gần nhất'}
          {revenueTimeframe === 'week' && 'Biến động doanh thu 4 tuần gần nhất'}
          {revenueTimeframe === 'month' && `Biến động doanh thu 12 tháng năm ${new Date().getFullYear()} (T1 - T12)`}
          {revenueTimeframe === 'year' && 'Biến động doanh thu qua các năm'}
          {revenueTimeframe === 'single_date' && `Chi tiết theo khung giờ ngày ${formatDateDisplay(singleDate)}`}
          {revenueTimeframe === 'date_range' && `Từ ngày ${formatDateDisplay(fromDate)} đến ngày ${formatDateDisplay(toDate)}`}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <span style={{ fontSize: '13px', color: '#16a34a', fontWeight: 800 }}>
            Tổng doanh thu: {formatVND(totalRevenue)}
          </span>
          <span style={{ fontSize: '13px', color: '#64748b', fontWeight: 600 }}>
            ({totalOrders} đơn hàng)
          </span>
        </div>
      </div>

      {/* High Resolution SVG/CSS Animated Bar Chart with Tooltips */}
      <div
        style={{
          position: 'relative',
          background: 'linear-gradient(180deg, #fafafa 0%, #f8fafc 100%)',
          borderRadius: '14px',
          padding: '24px 20px 16px 20px',
          border: '1px solid #f1f5f9',
          overflowX: 'auto',
        }}
      >
        {isCustomLoading ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '220px', gap: '12px' }}>
            <div className="loading-spinner" />
            <span style={{ fontSize: '13px', color: '#64748b', fontWeight: 600 }}>Đang tổng hợp dữ liệu doanh thu...</span>
          </div>
        ) : currentChartData.length === 0 ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '220px', color: '#94a3b8' }}>
            <BarChart2 size={40} style={{ opacity: 0.4, marginBottom: '8px' }} />
            <span style={{ fontSize: '13px', fontWeight: 600 }}>Không có dữ liệu doanh thu trong khoảng thời gian đã chọn</span>
          </div>
        ) : (
          <div
            style={{
              display: 'flex',
              alignItems: 'flex-end',
              justifyContent: 'space-between',
              height: '220px',
              gap: currentChartData.length > 8 ? '8px' : '14px',
              width: '100%',
              minWidth: currentChartData.length > 8 ? `${Math.max(currentChartData.length * 48, 560)}px` : '100%',
              padding: '0 4px',
              paddingBottom: '4px',
            }}
          >
            {currentChartData.map((d, idx) => {
              const heightPercent = maxRevenueInTrend > 0 ? Math.max((d.revenue / maxRevenueInTrend) * 100, 6) : 6;
              const isHovered = hoveredBarIndex === idx;
              const currentMonthNum = new Date().getMonth() + 1;
              const isCurrentMonth = revenueTimeframe === 'month' && (d.label === `T${currentMonthNum}` || d.label === `Thg ${currentMonthNum}`);

              return (
                <div
                  key={idx}
                  onMouseEnter={() => setHoveredBarIndex(idx)}
                  onMouseLeave={() => setHoveredBarIndex(null)}
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
                  }}
                >
                  {/* Tooltip on Hover */}
                  {isHovered && (
                    <div
                      style={{
                        position: 'absolute',
                        bottom: heightPercent > 55 ? 'auto' : `${heightPercent + 12}%`,
                        top: heightPercent > 55 ? '8px' : 'auto',
                        background: '#0f172a',
                        color: '#ffffff',
                        padding: '8px 12px',
                        borderRadius: '8px',
                        fontSize: '12px',
                        fontWeight: 700,
                        whiteSpace: 'nowrap',
                        boxShadow: '0 4px 12px rgba(0,0,0,0.25)',
                        zIndex: 20,
                        pointerEvents: 'none',
                      }}
                    >
                      <div>{d.fullDate || d.label}</div>
                      <div style={{ color: '#34d399', marginTop: '2px' }}>Doanh thu: {formatVND(d.revenue)}</div>
                      <div style={{ color: '#cbd5e1', fontSize: '11px', marginTop: '1px' }}>{d.orders} đơn hàng</div>
                    </div>
                  )}

                  <div style={{ fontSize: '11px', fontWeight: d.revenue > 0 ? 800 : 500, color: d.revenue > 0 ? '#fc6011' : '#cbd5e1', marginBottom: '6px', whiteSpace: 'nowrap', textAlign: 'center' }}>
                    {d.revenue > 0 ? (d.revenue >= 1000000 ? `${(d.revenue / 1000000).toFixed(1)}M` : `${(d.revenue / 1000).toFixed(0)}k`) : '-'}
                  </div>

                  {/* Animated Column Bar */}
                  <div
                    style={{
                      width: '65%',
                      maxWidth: '32px',
                      minWidth: '12px',
                      height: `${heightPercent}%`,
                      background: d.revenue > 0
                        ? isHovered
                          ? 'linear-gradient(180deg, #ea580c 0%, #fc6011 100%)'
                          : 'linear-gradient(180deg, #fc6011 0%, #f97316 100%)'
                        : isHovered
                        ? '#94a3b8'
                        : '#e2e8f0',
                      borderRadius: '6px 6px 0 0',
                      transition: 'height 0.6s cubic-bezier(0.4, 0, 0.2, 1), background 0.2s ease',
                      boxShadow: isHovered && d.revenue > 0 ? '0 4px 12px rgba(252,96,17,0.4)' : 'none',
                    }}
                  />

                  <div
                    style={{
                      fontSize: '12px',
                      color: isCurrentMonth ? '#ea580c' : isHovered ? '#0f172a' : '#64748b',
                      marginTop: '8px',
                      fontWeight: isCurrentMonth || isHovered ? 800 : 600,
                      textAlign: 'center',
                      whiteSpace: 'nowrap',
                      padding: isCurrentMonth ? '1px 6px' : '0',
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
    </div>
  );
};

