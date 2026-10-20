import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import {
  Users,
  Store,
  ShoppingBag,
  DollarSign,
  TrendingUp,
  Clock,
  CheckCircle2,
  AlertCircle,
  BarChart2,
  ArrowUpRight,
  UserCheck,
  Building2,
  Sparkles,
  ChevronRight,
  ChevronLeft,
  ChevronsLeft,
  ChevronsRight,
  RotateCcw,
  Calendar,
} from 'lucide-react';
import { StatusBadge } from '../../components/StatusBadge';
import { OrderDetailModal } from '../../components/OrderDetailModal';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../utils/imageUtils';

// Animated Count-Up Number Component
const AnimatedNumber: React.FC<{ value: number; isCurrency?: boolean }> = ({ value, isCurrency = false }) => {
  const [displayValue, setDisplayValue] = useState(0);

  useEffect(() => {
    let startTimestamp: number | null = null;
    const duration = 750;

    const step = (timestamp: number) => {
      if (!startTimestamp) startTimestamp = timestamp;
      const progress = Math.min((timestamp - startTimestamp) / duration, 1);
      const easeProgress = 1 - (1 - progress) * (1 - progress);
      setDisplayValue(Math.floor(easeProgress * value));

      if (progress < 1) {
        window.requestAnimationFrame(step);
      }
    };

    window.requestAnimationFrame(step);
  }, [value]);

  if (isCurrency) {
    return <>{new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(displayValue)}</>;
  }

  return <>{displayValue.toLocaleString('vi-VN')}</>;
};

export const AdminDashboard: React.FC = () => {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [selectedOrder, setSelectedOrder] = useState<any | null>(null);

  // Table pagination & loading state
  const [tableOrders, setTableOrders] = useState<any[]>([]);
  const [tablePagination, setTablePagination] = useState<{
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  }>({ total: 0, page: 1, limit: 10, totalPages: 1 });
  const [isTableLoading, setIsTableLoading] = useState<boolean>(false);
  const [tableError, setTableError] = useState<string | null>(null);
  const latestRequestIdRef = React.useRef<number>(0);

  // Active Metric Tab State: 'revenue' | 'users' | 'restaurants' | 'orders'
  const [activeCard, setActiveCard] = useState<'revenue' | 'users' | 'restaurants' | 'orders'>('revenue');

  // Revenue Chart Timeframe State: 'day' | 'week' | 'month' | 'year'
  const [revenueTimeframe, setRevenueTimeframe] = useState<'day' | 'week' | 'month' | 'year'>('day');

  // Hovered Chart Bar State for Tooltip
  const [hoveredBarIndex, setHoveredBarIndex] = useState<number | null>(null);

  useEffect(() => {
    const requestId = ++latestRequestIdRef.current;
    apiFetch<any>('/admin/stats?page=1&limit=10')
      .then((res) => {
        if (requestId !== latestRequestIdRef.current) return;
        setStats(res.data);
        setTableOrders(res.data?.recentOrders || []);
        if (res.data?.recentOrdersPagination) {
          setTablePagination(res.data.recentOrdersPagination);
        }
      })
      .catch((err) => {
        if (requestId !== latestRequestIdRef.current) return;
        console.error('Error fetching admin dashboard stats:', err);
      })
      .finally(() => {
        if (requestId === latestRequestIdRef.current) {
          setLoading(false);
        }
      });
  }, []);

  const handlePageChange = (targetPage: number) => {
    if (
      isTableLoading ||
      targetPage < 1 ||
      (tablePagination.totalPages > 0 && targetPage > tablePagination.totalPages) ||
      targetPage === tablePagination.page
    ) {
      return;
    }

    const requestId = ++latestRequestIdRef.current;
    setIsTableLoading(true);
    setTableError(null);

    apiFetch<any>(`/admin/stats?page=${targetPage}&limit=10&ordersOnly=true`)
      .then((res) => {
        if (requestId !== latestRequestIdRef.current) return;
        setTableOrders(res.data?.recentOrders || []);
        if (res.data?.recentOrdersPagination) {
          setTablePagination(res.data.recentOrdersPagination);
        }
      })
      .catch((err: any) => {
        if (requestId !== latestRequestIdRef.current) return;
        console.error('Error loading dashboard orders page:', err);
        setTableError(err?.message || 'Không thể tải danh sách đơn hàng. Vui lòng thử lại.');
      })
      .finally(() => {
        if (requestId === latestRequestIdRef.current) {
          setIsTableLoading(false);
        }
      });
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '80px' }}>
        <div className="loading-spinner" />
        <p style={{ marginTop: '16px', color: '#64748b', fontWeight: 600 }}>Đang tải dữ liệu tổng quan hệ thống...</p>
      </div>
    );
  }

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  // Extract revenue trend chart data based on selected timeframe
  const currentChartData = stats?.revenueTrend?.[revenueTimeframe] || [];
  const maxRevenueInTrend = Math.max(...currentChartData.map((d: any) => d.revenue), 100000);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Header */}
      <div className="page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1 className="page-title" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            Dashboard Tổng Quan Hệ Thống <Sparkles size={20} color="#fc6011" />
          </h1>
          <p className="page-subtitle">Dữ liệu kinh doanh và hoạt động thời gian thực của FoodRoute</p>
        </div>
      </div>

      {/* 4 Interactive Metric Cards Grid */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(4, 1fr)',
          gap: '16px',
        }}
      >
        {/* Card 1: Doanh Thu (Primary Hero Card) */}
        <div
          onClick={() => setActiveCard('revenue')}
          style={{
            background: activeCard === 'revenue' ? 'linear-gradient(135deg, #fff4ee 0%, #ffffff 100%)' : '#ffffff',
            border: activeCard === 'revenue' ? '2px solid #fc6011' : '1px solid #e2e8f0',
            borderRadius: '16px',
            padding: '18px',
            cursor: 'pointer',
            boxShadow: activeCard === 'revenue' ? '0 8px 24px rgba(252,96,17,0.15)' : '0 1px 3px rgba(0,0,0,0.04)',
            transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
            transform: activeCard === 'revenue' ? 'translateY(-2px)' : 'none',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
              💰 Tổng Doanh Thu
            </span>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '10px',
                background: '#fff4ee',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#fc6011',
              }}
            >
              <DollarSign size={20} />
            </div>
          </div>
          <div style={{ fontSize: '24px', fontWeight: 900, color: '#0f172a', marginTop: '10px' }}>
            <AnimatedNumber value={stats?.totalRevenue || 0} isCurrency={true} />
          </div>
          <div style={{ fontSize: '12px', color: '#10b981', marginTop: '6px', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 700 }}>
            <ArrowUpRight size={14} /> +{stats?.growthPercent || 0}% so với kỳ trước
          </div>
        </div>

        {/* Card 2: Người Dùng */}
        <div
          onClick={() => setActiveCard('users')}
          style={{
            background: activeCard === 'users' ? 'linear-gradient(135deg, #eff6ff 0%, #ffffff 100%)' : '#ffffff',
            border: activeCard === 'users' ? '2px solid #3b82f6' : '1px solid #e2e8f0',
            borderRadius: '16px',
            padding: '18px',
            cursor: 'pointer',
            boxShadow: activeCard === 'users' ? '0 8px 24px rgba(59,130,246,0.15)' : '0 1px 3px rgba(0,0,0,0.04)',
            transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
            transform: activeCard === 'users' ? 'translateY(-2px)' : 'none',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
              👥 Tổng Người Dùng
            </span>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '10px',
                background: '#eff6ff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#3b82f6',
              }}
            >
              <Users size={20} />
            </div>
          </div>
          <div style={{ fontSize: '24px', fontWeight: 900, color: '#0f172a', marginTop: '10px' }}>
            <AnimatedNumber value={stats?.totalUsers || 0} />
          </div>
          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '6px' }}>
            {stats?.userRoleCounts?.customers || 0} Khách hàng • {stats?.userRoleCounts?.merchants || 0} Chủ quán
          </div>
        </div>

        {/* Card 3: Nhà Hàng */}
        <div
          onClick={() => setActiveCard('restaurants')}
          style={{
            background: activeCard === 'restaurants' ? 'linear-gradient(135deg, #ecfdf5 0%, #ffffff 100%)' : '#ffffff',
            border: activeCard === 'restaurants' ? '2px solid #10b981' : '1px solid #e2e8f0',
            borderRadius: '16px',
            padding: '18px',
            cursor: 'pointer',
            boxShadow: activeCard === 'restaurants' ? '0 8px 24px rgba(16,185,129,0.15)' : '0 1px 3px rgba(0,0,0,0.04)',
            transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
            transform: activeCard === 'restaurants' ? 'translateY(-2px)' : 'none',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
              🏪 Tổng Nhà Hàng
            </span>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '10px',
                background: '#ecfdf5',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#10b981',
              }}
            >
              <Store size={20} />
            </div>
          </div>
          <div style={{ fontSize: '24px', fontWeight: 900, color: '#0f172a', marginTop: '10px' }}>
            <AnimatedNumber value={stats?.totalRestaurants || 0} />
          </div>
          <div style={{ fontSize: '12px', color: '#10b981', marginTop: '6px', fontWeight: 600 }}>
            {stats?.activeRestaurants || 0} nhà hàng đang mở cửa
          </div>
        </div>

        {/* Card 4: Đơn Hàng */}
        <div
          onClick={() => setActiveCard('orders')}
          style={{
            background: activeCard === 'orders' ? 'linear-gradient(135deg, #f3e8ff 0%, #ffffff 100%)' : '#ffffff',
            border: activeCard === 'orders' ? '2px solid #8b5cf6' : '1px solid #e2e8f0',
            borderRadius: '16px',
            padding: '18px',
            cursor: 'pointer',
            boxShadow: activeCard === 'orders' ? '0 8px 24px rgba(139,92,246,0.15)' : '0 1px 3px rgba(0,0,0,0.04)',
            transition: 'all 0.25s cubic-bezier(0.4, 0, 0.2, 1)',
            transform: activeCard === 'orders' ? 'translateY(-2px)' : 'none',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
              🛍️ Tổng Đơn Hàng
            </span>
            <div
              style={{
                width: '36px',
                height: '36px',
                borderRadius: '10px',
                background: '#f3e8ff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#8b5cf6',
              }}
            >
              <ShoppingBag size={20} />
            </div>
          </div>
          <div style={{ fontSize: '24px', fontWeight: 900, color: '#0f172a', marginTop: '10px' }}>
            <AnimatedNumber value={stats?.totalOrders || 0} />
          </div>
          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '6px' }}>
            {stats?.todayOrders || 0} đơn hôm nay • {stats?.completedOrders || 0} hoàn thành
          </div>
        </div>
      </div>

      {/* Prominent Revenue Chart & Interactive Content Area with Fade/Slide Animation */}
      <div
        style={{
          background: '#ffffff',
          borderRadius: '16px',
          border: '1px solid #e2e8f0',
          padding: '24px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.04)',
          transition: 'all 0.3s ease-in-out',
        }}
      >
        {/* Dynamic Header based on active card */}
        {activeCard === 'revenue' && (
          <div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
              <div>
                <h3 style={{ fontSize: '18px', fontWeight: 800, margin: 0, color: '#0f172a', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <TrendingUp size={20} color="#fc6011" /> Phân Tích & Biểu Đồ Doanh Thu Hệ Thống
                </h3>
                <p style={{ fontSize: '13px', color: '#64748b', margin: '4px 0 0 0' }}>
                  Theo dõi biến động doanh thu theo mốc thời gian thực tế
                </p>
              </div>

              {/* Timeframe selector controls */}
              <div style={{ display: 'flex', gap: '6px', background: '#f1f5f9', padding: '4px', borderRadius: '10px' }}>
                {[
                  { key: 'day', label: 'Ngày' },
                  { key: 'week', label: 'Tuần' },
                  { key: 'month', label: 'Tháng' },
                  { key: 'year', label: 'Năm' },
                ].map((t) => (
                  <button
                    key={t.key}
                    onClick={() => setRevenueTimeframe(t.key as any)}
                    style={{
                      padding: '6px 14px',
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

            {/* High Resolution SVG/CSS Animated Bar Chart with Tooltips */}
            <div
              style={{
                position: 'relative',
                background: 'linear-gradient(180deg, #fafafa 0%, #f8fafc 100%)',
                borderRadius: '14px',
                padding: '24px 20px 16px 20px',
                border: '1px solid #f1f5f9',
              }}
            >
              <div
                style={{
                  display: 'flex',
                  alignItems: 'flex-end',
                  justifyContent: 'space-between',
                  height: '220px',
                  gap: '16px',
                }}
              >
                {currentChartData.map((d: any, idx: number) => {
                  const heightPercent = maxRevenueInTrend > 0 ? Math.max((d.revenue / maxRevenueInTrend) * 100, 6) : 6;
                  const isHovered = hoveredBarIndex === idx;

                  return (
                    <div
                      key={idx}
                      onMouseEnter={() => setHoveredBarIndex(idx)}
                      onMouseLeave={() => setHoveredBarIndex(null)}
                      style={{
                        flex: 1,
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
                            bottom: `${heightPercent + 12}%`,
                            background: '#0f172a',
                            color: '#ffffff',
                            padding: '8px 12px',
                            borderRadius: '8px',
                            fontSize: '12px',
                            fontWeight: 700,
                            whiteSpace: 'nowrap',
                            boxShadow: '0 4px 12px rgba(0,0,0,0.25)',
                            zIndex: 10,
                            pointerEvents: 'none',
                          }}
                        >
                          <div>📅 {d.fullDate || d.label}</div>
                          <div style={{ color: '#34d399', marginTop: '2px' }}>Doanh thu: {formatVND(d.revenue)}</div>
                          <div style={{ color: '#cbd5e1', fontSize: '11px', marginTop: '1px' }}>{d.orders} đơn hàng</div>
                        </div>
                      )}

                      <div style={{ fontSize: '11px', fontWeight: 700, color: d.revenue > 0 ? '#fc6011' : '#94a3b8', marginBottom: '6px' }}>
                        {d.revenue > 0 ? `${(d.revenue / 1000).toFixed(0)}k` : '0đ'}
                      </div>

                      {/* Animated Column Bar */}
                      <div
                        style={{
                          width: '100%',
                          maxWidth: '48px',
                          height: `${heightPercent}%`,
                          background: isHovered
                            ? 'linear-gradient(180deg, #ea580c 0%, #fc6011 100%)'
                            : 'linear-gradient(180deg, #fc6011 0%, #f97316 100%)',
                          borderRadius: '6px 6px 0 0',
                          transition: 'height 0.6s cubic-bezier(0.4, 0, 0.2, 1), background 0.2s ease',
                          boxShadow: isHovered ? '0 4px 12px rgba(252,96,17,0.4)' : 'none',
                        }}
                      />

                      <div style={{ fontSize: '12px', color: '#475569', marginTop: '8px', fontWeight: 700 }}>
                        {d.label}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {/* Tab Content: Người Dùng */}
        {activeCard === 'users' && (
          <div>
            <h3 style={{ fontSize: '18px', fontWeight: 800, margin: '0 0 16px 0', color: '#0f172a', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Users size={20} color="#3b82f6" /> Phân Thống Kê Tài Khoản & Người Dùng
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px' }}>
              <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#64748b' }}>KHÁCH HÀNG (CÁ NHÂN)</div>
                <div style={{ fontSize: '24px', fontWeight: 900, color: '#3b82f6', marginTop: '6px' }}>
                  {stats?.userRoleCounts?.customers || 0}
                </div>
                <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>Tài khoản mua hàng</div>
              </div>

              <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#64748b' }}>CHỦ NHÀ HÀNG</div>
                <div style={{ fontSize: '24px', fontWeight: 900, color: '#10b981', marginTop: '6px' }}>
                  {stats?.userRoleCounts?.merchants || 0}
                </div>
                <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>Tài khoản đối tác quán ăn</div>
              </div>

              <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#64748b' }}>QUẢN TRỊ VIÊN ADMIN</div>
                <div style={{ fontSize: '24px', fontWeight: 900, color: '#8b5cf6', marginTop: '6px' }}>
                  {stats?.userRoleCounts?.admins || 0}
                </div>
                <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>Quyền quản trị toàn quyền</div>
              </div>
            </div>
          </div>
        )}

        {/* Tab Content: Nhà Hàng */}
        {activeCard === 'restaurants' && (
          <div>
            <h3 style={{ fontSize: '18px', fontWeight: 800, margin: '0 0 16px 0', color: '#0f172a', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Store size={20} color="#10b981" /> Danh Sách Nhà Hàng Mới Nhất
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '14px' }}>
              {(stats?.topRestaurants || []).map((store: any) => (
                <div key={store.maQuan} style={{ background: '#f8fafc', padding: '14px', borderRadius: '12px', border: '1px solid #e2e8f0', display: 'flex', gap: '12px', alignItems: 'center' }}>
                  <img src={getImageUrl(store.img, DEFAULT_IMAGE_PLACEHOLDER)} onError={handleImageError} alt="" style={{ width: '48px', height: '48px', borderRadius: '10px', objectFit: 'cover' }} />
                  <div>
                    <div style={{ fontWeight: 700, color: '#0f172a', fontSize: '14px' }}>{store.tenQuan}</div>
                    <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>{store.diaChi}</div>
                    <div style={{ marginTop: '4px' }}><StatusBadge status={store.trangThai || 'mở cửa'} /></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Tab Content: Đơn Hàng */}
        {activeCard === 'orders' && (
          <div>
            <h3 style={{ fontSize: '18px', fontWeight: 800, margin: '0 0 16px 0', color: '#0f172a', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <ShoppingBag size={20} color="#8b5cf6" /> Trạng Thái & Thống Kê Đơn Hàng
            </h3>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '16px', marginBottom: '20px' }}>
              <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#ec4899' }}>ĐANG XỬ LÝ</div>
                <div style={{ fontSize: '22px', fontWeight: 900, color: '#ec4899', marginTop: '4px' }}>{stats?.processingOrders || 0} đơn</div>
              </div>
              <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#06b6d4' }}>CHỜ KHÁCH LẤY</div>
                <div style={{ fontSize: '22px', fontWeight: 900, color: '#06b6d4', marginTop: '4px' }}>{stats?.pickupWaitingOrders || 0} đơn</div>
              </div>
              <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#10b981' }}>ĐÃ HOÀN THÀNH</div>
                <div style={{ fontSize: '22px', fontWeight: 900, color: '#10b981', marginTop: '4px' }}>{stats?.completedOrders || 0} đơn</div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Recent Orders Table */}
      <div className="card-table" style={{ background: '#ffffff', borderRadius: '16px', border: '1px solid #e2e8f0', overflow: 'hidden' }}>
        <div className="table-toolbar" style={{ borderBottom: '1px solid #e2e8f0', padding: '16px 20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div style={{ fontWeight: 800, fontSize: '15px', color: '#0f172a', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Clock size={18} color="#fc6011" /> Lịch Sử Đơn Hàng Mới Nhất Trên Hệ Thống
          </div>
          {tablePagination.total > 0 && (
            <div style={{ fontSize: '12px', color: '#64748b', fontWeight: 600 }}>
              Tổng cộng: <strong style={{ color: '#0f172a' }}>{tablePagination.total}</strong> đơn
            </div>
          )}
        </div>

        {tableError ? (
          <div style={{ padding: '40px 20px', textAlign: 'center', minHeight: '380px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
            <AlertCircle size={36} color="#ef4444" style={{ marginBottom: '12px' }} />
            <div style={{ color: '#0f172a', fontWeight: 700, marginBottom: '6px' }}>Đã xảy ra lỗi khi tải đơn hàng</div>
            <div style={{ color: '#64748b', fontSize: '13px', marginBottom: '16px' }}>{tableError}</div>
            <button
              onClick={() => handlePageChange(tablePagination.page)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 16px',
                borderRadius: '8px',
                background: '#fc6011',
                color: '#fff',
                border: 'none',
                fontWeight: 600,
                fontSize: '13px',
                cursor: 'pointer',
              }}
            >
              <RotateCcw size={14} /> Thử lại
            </button>
          </div>
        ) : (!isTableLoading && tableOrders.length === 0) ? (
          <div className="empty-state" style={{ minHeight: '380px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            Chưa có đơn hàng nào phát sinh
          </div>
        ) : (
          <div style={{ position: 'relative', minHeight: '380px' }}>
            {isTableLoading && (
              <div
                style={{
                  position: 'absolute',
                  inset: 0,
                  background: 'rgba(255, 255, 255, 0.7)',
                  backdropFilter: 'blur(1px)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  zIndex: 10,
                  transition: 'opacity 0.2s ease',
                }}
              >
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px' }}>
                  <div className="loading-spinner" style={{ width: '28px', height: '28px' }} />
                  <span style={{ fontSize: '12px', fontWeight: 600, color: '#64748b' }}>Đang tải trang {tablePagination.page}...</span>
                </div>
              </div>
            )}

            <table className="data-table" style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                  <th>Khách Hàng</th>
                  <th>Nhà Hàng</th>
                  <th>Tổng Tiền</th>
                  <th>Thời Gian Đặt</th>
                  <th>Trạng Thái</th>
                </tr>
              </thead>
              <tbody>
                {tableOrders.map((ord: any, idx: number) => {
                  const stt = (tablePagination.page - 1) * tablePagination.limit + idx + 1;
                  return (
                    <tr
                      key={ord.maDonHang || `ord-${idx}`}
                      onClick={() => setSelectedOrder(ord)}
                      style={{ cursor: 'pointer' }}
                      title="Click để xem chi tiết đơn hàng"
                    >
                      <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{stt}</td>
                      <td>{ord.tenKhachHang || `Khách hàng #${ord.maKhachHang}`}</td>
                      <td style={{ fontWeight: 600 }}>{ord.tenQuan}</td>
                      <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(ord.tongTien)}</td>
                      <td>{new Date(ord.thoiGianDat).toLocaleString('vi-VN')}</td>
                      <td><StatusBadge status={ord.trangThai} /></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination Controls */}
        {tablePagination.total > 10 && (
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: '14px 20px',
              borderTop: '1px solid #e2e8f0',
              background: '#f8fafc',
              flexWrap: 'wrap',
              gap: '12px',
            }}
          >
            {/* Summary text */}
            <div style={{ fontSize: '13px', color: '#64748b', fontWeight: 500 }}>
              Hiển thị <strong>{(tablePagination.page - 1) * tablePagination.limit + 1}</strong>-
              <strong>{Math.min(tablePagination.page * tablePagination.limit, tablePagination.total)}</strong> trên tổng{' '}
              <strong>{tablePagination.total}</strong> đơn
            </div>

            {/* Buttons */}
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              {/* Trang đầu */}
              <button
                onClick={() => handlePageChange(1)}
                disabled={tablePagination.page <= 1 || isTableLoading}
                title="Trang đầu"
                style={{
                  padding: '6px 10px',
                  fontSize: '12px',
                  fontWeight: 600,
                  borderRadius: '7px',
                  border: '1px solid #cbd5e1',
                  background: '#ffffff',
                  color: tablePagination.page <= 1 ? '#94a3b8' : '#334155',
                  cursor: tablePagination.page <= 1 ? 'not-allowed' : 'pointer',
                  opacity: tablePagination.page <= 1 ? 0.5 : 1,
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                }}
              >
                <ChevronsLeft size={14} /> Trang đầu
              </button>

              {/* Trước */}
              <button
                onClick={() => handlePageChange(tablePagination.page - 1)}
                disabled={tablePagination.page <= 1 || isTableLoading}
                title="Trang trước"
                style={{
                  padding: '6px 10px',
                  fontSize: '12px',
                  fontWeight: 600,
                  borderRadius: '7px',
                  border: '1px solid #cbd5e1',
                  background: '#ffffff',
                  color: tablePagination.page <= 1 ? '#94a3b8' : '#334155',
                  cursor: tablePagination.page <= 1 ? 'not-allowed' : 'pointer',
                  opacity: tablePagination.page <= 1 ? 0.5 : 1,
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                }}
              >
                <ChevronLeft size={14} /> Trước
              </button>

              {/* Page numbers with ellipsis */}
              {Array.from({ length: tablePagination.totalPages }, (_, i) => i + 1)
                .filter((p) => p === 1 || p === tablePagination.totalPages || Math.abs(p - tablePagination.page) <= 2)
                .map((p, idx, arr) => {
                  const prev = arr[idx - 1];
                  const showEllipsis = prev && p - prev > 1;
                  const isActive = p === tablePagination.page;

                  return (
                    <React.Fragment key={p}>
                      {showEllipsis && <span style={{ padding: '0 4px', color: '#94a3b8', fontSize: '13px' }}>...</span>}
                      <button
                        onClick={() => handlePageChange(p)}
                        disabled={isTableLoading}
                        style={{
                          minWidth: '32px',
                          height: '32px',
                          borderRadius: '8px',
                          border: isActive ? 'none' : '1px solid #cbd5e1',
                          background: isActive ? '#fc6011' : '#ffffff',
                          color: isActive ? '#ffffff' : '#334155',
                          fontWeight: isActive ? 700 : 600,
                          fontSize: '13px',
                          cursor: isActive ? 'default' : 'pointer',
                          transition: 'all 0.15s ease',
                        }}
                      >
                        {p}
                      </button>
                    </React.Fragment>
                  );
                })}

              {/* Sau */}
              <button
                onClick={() => handlePageChange(tablePagination.page + 1)}
                disabled={tablePagination.page >= tablePagination.totalPages || isTableLoading}
                title="Trang sau"
                style={{
                  padding: '6px 10px',
                  fontSize: '12px',
                  fontWeight: 600,
                  borderRadius: '7px',
                  border: '1px solid #cbd5e1',
                  background: '#ffffff',
                  color: tablePagination.page >= tablePagination.totalPages ? '#94a3b8' : '#334155',
                  cursor: tablePagination.page >= tablePagination.totalPages ? 'not-allowed' : 'pointer',
                  opacity: tablePagination.page >= tablePagination.totalPages ? 0.5 : 1,
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                }}
              >
                Sau <ChevronRight size={14} />
              </button>

              {/* Trang cuối */}
              <button
                onClick={() => handlePageChange(tablePagination.totalPages)}
                disabled={tablePagination.page >= tablePagination.totalPages || isTableLoading}
                title="Trang cuối"
                style={{
                  padding: '6px 10px',
                  fontSize: '12px',
                  fontWeight: 600,
                  borderRadius: '7px',
                  border: '1px solid #cbd5e1',
                  background: '#ffffff',
                  color: tablePagination.page >= tablePagination.totalPages ? '#94a3b8' : '#334155',
                  cursor: tablePagination.page >= tablePagination.totalPages ? 'not-allowed' : 'pointer',
                  opacity: tablePagination.page >= tablePagination.totalPages ? 0.5 : 1,
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                }}
              >
                Trang cuối <ChevronsRight size={14} />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Order Detail Modal */}
      {selectedOrder && (
        <OrderDetailModal
          order={selectedOrder}
          onClose={() => setSelectedOrder(null)}
        />
      )}
    </div>
  );
};
