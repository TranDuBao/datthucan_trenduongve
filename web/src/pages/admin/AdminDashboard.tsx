import React, { useEffect, useState, useRef } from 'react';
import { apiFetch } from '../../api/apiClient';
import { getSocket, joinAdminRoom } from '../../api/socketClient';
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
  ArrowDownRight,
  UserCheck,
  Building2,
  Sparkles,
  ChevronRight,
  ChevronLeft,
  ChevronsLeft,
  ChevronsRight,
  RotateCcw,
  Calendar,
  Smartphone,
  Download,
  Copy,
  Check,
} from 'lucide-react';
import { StatusBadge } from '../../components/StatusBadge';
import { OrderDetailModal } from '../../components/OrderDetailModal';
import { RevenueChartSection } from './RevenueChartSection';
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

  // Mobile App Download Telemetry & Release Monitor State
  const [appStats, setAppStats] = useState<any>(() => {
    try {
      const saved = localStorage.getItem('foodroute_last_apk_stats');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (parsed.apkName === 'FoodRoute_v1.0.apk') {
          parsed.apkName = 'FoodRoute_v1.1.apk';
          parsed.downloadUrl = parsed.downloadUrl?.replace('FoodRoute_v1.0.apk', 'FoodRoute_v1.1.apk');
        }
        return parsed;
      }
    } catch (_) {}
    return {
      totalDownloads: 12,
      apkDownloadCount: 12,
      version: 'v1.0.0',
      apkName: 'FoodRoute_v1.1.apk',
      apkSize: 73503258,
      downloadUrl: 'https://github.com/TranDuBao/datthucan_trenduongve/releases/download/v1.0.0/FoodRoute_v1.1.apk',
      releaseUrl: 'https://github.com/TranDuBao/datthucan_trenduongve/releases/tag/v1.0.0',
    };
  });
  const [copySuccess, setCopySuccess] = useState<boolean>(false);

  const fetchAppStats = () => {
    const handleStats = (data: any) => {
      if (!data) return;
      const count = Number(data.apkDownloadCount ?? data.totalDownloads ?? 0);
      setAppStats((prev: any) => {
        const prevCount = Number(prev?.apkDownloadCount ?? prev?.totalDownloads ?? 0);
        if (count === 0 && prevCount > 0) return prev;
        const merged = { ...prev, ...data, totalDownloads: Math.max(count, prevCount), apkDownloadCount: Math.max(count, prevCount) };
        if (merged.apkName === 'FoodRoute_v1.0.apk') {
          merged.apkName = 'FoodRoute_v1.1.apk';
          merged.downloadUrl = merged.downloadUrl?.replace('FoodRoute_v1.0.apk', 'FoodRoute_v1.1.apk');
        }
        try {
          localStorage.setItem('foodroute_last_apk_stats', JSON.stringify(merged));
        } catch (_) {}
        return merged;
      });
    };

    apiFetch<any>('/admin/app-stats')
      .then((res) => {
        if (res.data) handleStats(res.data);
      })
      .catch(() => {
        fetch('https://api.github.com/repos/TranDuBao/datthucan_trenduongve/releases')
          .then((r) => r.json())
          .then((releases) => {
            if (Array.isArray(releases) && releases.length > 0) {
              const rel = releases[0];
              const apk = rel.assets?.find((a: any) => a.name.endsWith('.apk'));
              const dlCount = rel.assets?.reduce((sum: number, a: any) => sum + (a.download_count || 0), 0) || 0;
              handleStats({
                totalDownloads: dlCount,
                version: rel.tag_name || 'v1.0.0',
                releaseName: rel.name || 'FoodRoute App v1.0.0',
                publishedAt: rel.published_at,
                apkName: apk?.name || 'FoodRoute_v1.1.apk',
                apkSize: apk?.size || 73503258,
                apkDownloadCount: apk?.download_count || dlCount,
                downloadUrl: apk?.browser_download_url || 'https://github.com/TranDuBao/datthucan_trenduongve/releases/download/v1.0.0/FoodRoute_v1.1.apk',
                releaseUrl: rel.html_url || 'https://github.com/TranDuBao/datthucan_trenduongve/releases/tag/v1.0.0',
              });
            }
          })
          .catch(console.error);
      });
  };

  const handleCopyDownloadLink = () => {
    let url = appStats?.downloadUrl || 'https://github.com/TranDuBao/datthucan_trenduongve/releases/download/v1.0.0/FoodRoute_v1.1.apk';
    if (url.includes('FoodRoute_v1.0.apk')) {
      url = url.replace('FoodRoute_v1.0.apk', 'FoodRoute_v1.1.apk');
    }
    navigator.clipboard.writeText(url).then(() => {
      setCopySuccess(true);
      setTimeout(() => setCopySuccess(false), 3000);
    });
  };

  const currentPageRef = useRef<number>(1);
  currentPageRef.current = tablePagination.page;

  const fetchDashboardStats = (targetPage: number = 1, silent: boolean = false) => {
    const requestId = ++latestRequestIdRef.current;
    if (!silent) {
      setLoading(true);
    }

    apiFetch<any>(`/admin/stats?page=${targetPage}&limit=10`)
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
        if (requestId === latestRequestIdRef.current && !silent) {
          setLoading(false);
        }
      });
  };

  useEffect(() => {
    fetchDashboardStats(1, false);
    fetchAppStats();

    const socket = getSocket();
    if (socket) {
      joinAdminRoom();

      const handleRealtimeUpdate = (payload: any) => {
        console.log('[AdminDashboard] [Info] Realtime update event received:', payload);
        fetchDashboardStats(currentPageRef.current, true);
      };

      socket.on('order:created', handleRealtimeUpdate);
      socket.on('order:status_changed', handleRealtimeUpdate);
      socket.on('payment:confirmed', handleRealtimeUpdate);

      return () => {
        socket.off('order:created', handleRealtimeUpdate);
        socket.off('order:status_changed', handleRealtimeUpdate);
        socket.off('payment:confirmed', handleRealtimeUpdate);
      };
    }
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
              Tổng Doanh Thu
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
          <div
            style={{
              fontSize: '12px',
              color: (stats?.growthPercent ?? 0) >= 0 ? '#10b981' : '#ef4444',
              marginTop: '6px',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
              fontWeight: 700,
            }}
          >
            {(stats?.growthPercent ?? 0) >= 0 ? (
              <>
                <ArrowUpRight size={14} /> +{stats?.growthPercent ?? 0}% so với kỳ trước
              </>
            ) : (
              <>
                <ArrowDownRight size={14} /> {stats?.growthPercent ?? 0}% so với kỳ trước
              </>
            )}
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
              Tổng Người Dùng
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
              Tổng Nhà Hàng
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
              Tổng Đơn Hàng
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

      {/* Mobile App Downloads & Release Monitor Banner */}
      <div
        style={{
          background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 100%)',
          borderRadius: '16px',
          padding: '18px 24px',
          color: '#ffffff',
          boxShadow: '0 4px 20px rgba(15,23,42,0.12)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div
            style={{
              width: '46px',
              height: '46px',
              borderRadius: '12px',
              background: 'linear-gradient(135deg, #fc6011 0%, #ff8342 100%)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#ffffff',
              boxShadow: '0 4px 12px rgba(252,96,17,0.4)',
              flexShrink: 0,
            }}
          >
            <Smartphone size={24} />
          </div>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
              <span style={{ fontSize: '15px', fontWeight: 800 }}>Ứng Dụng Di Động Android</span>
              <span
                style={{
                  fontSize: '11px',
                  fontWeight: 700,
                  padding: '2px 8px',
                  borderRadius: '6px',
                  background: 'rgba(16,185,129,0.2)',
                  color: '#34d399',
                  border: '1px solid rgba(52,211,153,0.3)',
                }}
              >
                {appStats?.version || 'v1.0.0'} • Chính Thức
              </span>
            </div>
            <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>
              Tệp: <b style={{ color: '#f1f5f9' }}>{appStats?.apkName || 'FoodRoute_v1.1.apk'}</b> ({appStats?.apkSize ? (appStats.apkSize / (1024 * 1024)).toFixed(1) : '70.1'} MB) • Hỗ trợ Android 7.0+
            </div>
          </div>
        </div>

        {/* Download Count Metric & Quick Actions */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '20px', flexWrap: 'wrap' }}>
          <div
            style={{
              textAlign: 'center',
              padding: '0 16px',
              borderLeft: '1px solid rgba(255,255,255,0.12)',
              borderRight: '1px solid rgba(255,255,255,0.12)',
            }}
          >
            <div style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.5px' }}>
              Tổng Lượt Tải APK
            </div>
            <div style={{ fontSize: '26px', fontWeight: 900, color: '#38bdf8', marginTop: '2px' }}>
              <AnimatedNumber value={appStats?.apkDownloadCount ?? appStats?.totalDownloads ?? 0} />
            </div>
          </div>

          <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
            <button
              onClick={handleCopyDownloadLink}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 14px',
                borderRadius: '8px',
                background: copySuccess ? '#10b981' : 'rgba(255,255,255,0.12)',
                color: '#ffffff',
                border: '1px solid rgba(255,255,255,0.2)',
                fontWeight: 600,
                fontSize: '12px',
                cursor: 'pointer',
                transition: 'all 0.2s',
              }}
              title="Sao chép link tải file APK trực tiếp"
            >
              {copySuccess ? <Check size={14} /> : <Copy size={14} />}
              {copySuccess ? 'Đã copy link tải!' : 'Copy Link Tải'}
            </button>

            <a
              href={appStats?.downloadUrl?.replace('FoodRoute_v1.0.apk', 'FoodRoute_v1.1.apk') || 'https://github.com/TranDuBao/datthucan_trenduongve/releases/download/v1.0.0/FoodRoute_v1.1.apk'}
              target="_blank"
              rel="noreferrer"
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                padding: '8px 14px',
                borderRadius: '8px',
                background: '#fc6011',
                color: '#ffffff',
                border: 'none',
                fontWeight: 700,
                fontSize: '12px',
                textDecoration: 'none',
                boxShadow: '0 2px 8px rgba(252,96,17,0.3)',
              }}
            >
              <Download size={14} /> Tải File APK
            </a>

            <button
              onClick={fetchAppStats}
              style={{
                background: 'rgba(255,255,255,0.08)',
                border: '1px solid rgba(255,255,255,0.15)',
                color: '#94a3b8',
                borderRadius: '8px',
                padding: '8px 10px',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
              title="Làm mới số lượt tải từ GitHub Release"
            >
              <RotateCcw size={14} />
            </button>
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
          <RevenueChartSection revenueTrend={stats?.revenueTrend} formatVND={formatVND} />
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
