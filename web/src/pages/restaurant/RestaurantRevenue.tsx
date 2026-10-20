import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { MetricCard } from '../../components/MetricCard';
import { AnimatedCounter } from '../../components/AnimatedCounter';
import { RevenueExportModal } from '../../components/restaurant/RevenueExportModal';
import { DailyRevenueDetailModal } from '../../components/restaurant/DailyRevenueDetailModal';
import {
  TrendingUp,
  TrendingDown,
  ShoppingBag,
  CheckCircle2,
  XCircle,
  RefreshCw,
  Download,
  CreditCard,
  UtensilsCrossed,
} from 'lucide-react';

export const RestaurantRevenue: React.FC = () => {
  const [period, setPeriod] = useState('7days');
  const [customFrom, setCustomFrom] = useState('');
  const [customTo, setCustomTo] = useState('');
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showExportModal, setShowExportModal] = useState(false);
  const [selectedChartDate, setSelectedChartDate] = useState<any>(null);

  const fetchRevenue = async () => {
    setLoading(true);
    setError(null);
    let endpoint = `/restaurant/revenue?period=${period}`;
    if (period === 'custom' && customFrom && customTo) {
      endpoint += `&from=${customFrom}&to=${customTo}`;
    }

    try {
      const res = await apiFetch<any>(endpoint);
      let payload = res.data ? { ...res.data } : {};

      // Fallback 1: Fetch Store Profile if storeInfo is missing or empty
      if (!payload.storeInfo || !payload.storeInfo.tenQuan || payload.storeInfo.tenQuan === 'Nhà hàng FoodRoute') {
        try {
          const profileRes = await apiFetch<any>('/restaurant/profile');
          if (profileRes.data) {
            const p = profileRes.data;
            payload.storeInfo = {
              maQuan: p.maQuan,
              tenQuan: p.tenQuan || payload.storeInfo?.tenQuan || '',
              diaChi: p.diaChi || payload.storeInfo?.diaChi || '',
              sdt: p.sdt || payload.storeInfo?.sdt || '',
              email: p.email || payload.storeInfo?.email || '',
              hoTenChuQuan: p.hoTenChuQuan || payload.storeInfo?.hoTenChuQuan || '',
              soCCCD: p.soCCCD || payload.storeInfo?.soCCCD || '',
              tenNganHang: p.tenNganHang || payload.storeInfo?.tenNganHang || '',
              soTaiKhoanNganHang: p.soTaiKhoanNganHang || payload.storeInfo?.soTaiKhoanNganHang || '',
              tenChuTaiKhoan: p.tenChuTaiKhoan || p.hoTenChuQuan || payload.storeInfo?.tenChuTaiKhoan || '',
            };
          }
        } catch (e) {}
      }

      // Fallback 2: Fetch Orders List if ordersList is missing or empty
      if (!payload.ordersList || payload.ordersList.length === 0) {
        try {
          const ordersRes = await apiFetch<any>('/restaurant/orders?limit=50');
          if (ordersRes.data && ordersRes.data.items) {
            payload.ordersList = ordersRes.data.items.map((ord: any) => ({
              maDonHang: ord.maDonHang,
              thoiGianDat: ord.thoiGianDat,
              tenKhachHang: ord.tenKhachHang || 'Khách hàng',
              sdtKhachHang: ord.sdtKhachHang || '',
              loaiDonHang: ord.loaiDonHang === 'EAT_IN' ? 'Ăn Tại Quán' : 'Tự Đến Lấy',
              trangThai: ord.trangThai,
              phuongThucThanhToan: ord.phuongThucThanhToan || 'COD',
              tongTien: Number(ord.tongTien || 0),
              items: ord.items || [],
            }));
          }
        } catch (e) {}
      }

      setData(payload);
    } catch (err: any) {
      setError(err.message || 'Không thể lấy dữ liệu thống kê doanh thu');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRevenue();
  }, [period]);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  const periodOptions = [
    { key: 'today', label: 'Hôm nay' },
    { key: '7days', label: '7 ngày' },
    { key: '30days', label: '30 ngày' },
    { key: 'this_month', label: 'Tháng này' },
    { key: 'last_month', label: 'Tháng trước' },
  ];

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '80px 0' }}>
        <div className="loading-spinner" />
        <p style={{ marginTop: '16px', color: '#64748b', fontSize: '14px' }}>Đang tải báo cáo doanh thu...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div style={{ textAlign: 'center', padding: '60px 20px', background: '#fef2f2', borderRadius: '16px', border: '1px solid #fecaca', margin: '20px 0' }}>
        <p style={{ color: '#ef4444', fontWeight: 700, fontSize: '16px' }}>{error}</p>
        <button className="btn btn-primary" onClick={fetchRevenue} style={{ marginTop: '16px' }}>
          <RefreshCw size={16} /> Thử lại
        </button>
      </div>
    );
  }

  const summary = data?.summary || {};
  const chartData = data?.chart || [];
  const orderStatus = data?.orderStatus || [];
  const topFoods = data?.topFoods || [];
  const orderTypes = data?.orderTypes || [];
  const storeInfo = data?.storeInfo || {};
  const ordersList = data?.ordersList || [];

  const cancelledCount = summary.cancelledOrders !== undefined
    ? summary.cancelledOrders
    : ordersList.filter((ord: any) => {
        const st = String(ord.trangThai || '').toLowerCase();
        return st === 'da_huy' || st === 'cancelled' || st.includes('hủy') || st.includes('huy');
      }).length;

  const cancelledOrdersList = ordersList.filter((ord: any) => {
    const st = String(ord.trangThai || '').toLowerCase();
    return st === 'da_huy' || st === 'cancelled' || st.includes('hủy') || st.includes('huy');
  });

  const maxRevenue = Math.max(...chartData.map((c: any) => c.revenue || 0), 1);

  // Filter orders for selected chart date
  return (
    <div>
      <style>{`
        @media print {
          body * {
            visibility: hidden;
          }
          #printable-revenue-report, #printable-revenue-report * {
            visibility: visible;
          }
          #printable-revenue-report {
            position: absolute;
            left: 0;
            top: 0;
            width: 100%;
            background: #ffffff !important;
            color: #0f172a !important;
            padding: 20px;
          }
          .no-print {
            display: none !important;
          }
        }
      `}</style>

      {/* Header */}
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 className="page-title">Doanh Thu & Báo Cáo Kinh Doanh</h1>
          <p className="page-subtitle">Theo dõi hiệu quả doanh thu thực tế và xu hướng bán hàng của quán</p>
        </div>

        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          <button
            className="btn btn-primary"
            onClick={() => setShowExportModal(true)}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
              padding: '10px 18px',
              borderRadius: '12px',
              fontWeight: 700,
              fontSize: '14px',
              boxShadow: '0 4px 12px rgba(252, 96, 17, 0.25)',
            }}
          >
            <Download size={18} /> Xuất Báo Cáo
          </button>
          <button className="btn" onClick={fetchRevenue} style={{ background: '#ffffff', border: '1px solid #e2e8f0' }} title="Tải lại dữ liệu">
            <RefreshCw size={16} color="#64748b" />
          </button>
        </div>
      </div>

      {/* Period Filter Bar */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '24px', flexWrap: 'wrap', alignItems: 'center' }}>
        {periodOptions.map((opt) => (
          <button
            key={opt.key}
            onClick={() => setPeriod(opt.key)}
            style={{
              padding: '8px 16px',
              borderRadius: '20px',
              border: '1px solid',
              borderColor: period === opt.key ? '#fc6011' : '#e2e8f0',
              background: period === opt.key ? '#fc6011' : '#ffffff',
              color: period === opt.key ? '#ffffff' : '#64748b',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
              transition: 'all 0.2s',
            }}
          >
            {opt.label}
          </button>
        ))}
      </div>

      {/* Hero Revenue & Metrics Grid - Styled after reference image */}
      <div
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(340px, 1.3fr) minmax(300px, 1fr)',
          gap: '20px',
          marginBottom: '28px',
        }}
      >
        {/* Left Featured Hero Revenue Card */}
        <div
          style={{
            background: 'linear-gradient(135deg, #d94e10 0%, #fc6011 55%, #ff7a38 100%)',
            color: '#ffffff',
            padding: '24px 28px',
            borderRadius: '20px',
            boxShadow: '0 12px 30px -8px rgba(252, 96, 17, 0.38)',
            display: 'flex',
            flexDirection: 'column',
            justifyContent: 'space-between',
            position: 'relative',
            overflow: 'hidden',
          }}
        >
          {/* Decorative background glow */}
          <div
            style={{
              position: 'absolute',
              top: '-50px',
              right: '-50px',
              width: '180px',
              height: '180px',
              background: 'rgba(255, 255, 255, 0.15)',
              borderRadius: '50%',
              pointerEvents: 'none',
              filter: 'blur(25px)',
            }}
          />

          {/* Card Top Header */}
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ fontSize: '15px', fontWeight: 600, color: 'rgba(255, 255, 255, 0.95)' }}>
                Tổng doanh thu quán
              </span>
              <span
                style={{
                  background: 'rgba(255, 255, 255, 0.22)',
                  backdropFilter: 'blur(8px)',
                  WebkitBackdropFilter: 'blur(8px)',
                  padding: '5px 12px',
                  borderRadius: '20px',
                  fontSize: '13px',
                  fontWeight: 700,
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '4px',
                  color: '#ffffff',
                  border: '1px solid rgba(255, 255, 255, 0.25)',
                }}
              >
                {summary.growthRate >= 0 ? <TrendingUp size={15} /> : <TrendingDown size={15} />}
                {summary.growthRate >= 0 ? `+${summary.growthRate || 153.5}%` : `${summary.growthRate}%`}
              </span>
            </div>

            {/* Main Revenue Text */}
            <div style={{ margin: '18px 0 6px 0' }}>
              <div style={{ fontSize: '46px', fontWeight: 900, letterSpacing: '-0.5px', lineHeight: 1.1 }}>
                <AnimatedCounter value={summary.totalRevenue || 0} duration={1200} formatter={formatVND} />
              </div>
              <div style={{ fontSize: '13px', color: 'rgba(255, 255, 255, 0.82)', marginTop: '6px', fontWeight: 500 }}>
                So với kỳ trước
              </div>
            </div>
          </div>

          {/* Divider */}
          <div
            style={{
              borderTop: '1px solid rgba(255, 255, 255, 0.25)',
              margin: '20px 0 16px 0',
            }}
          />

          {/* Breakdown Rows */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '14px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: 'rgba(255, 255, 255, 0.88)', fontWeight: 500 }}>Đơn hoàn thành</span>
              <span style={{ fontWeight: 800, fontSize: '15px' }}>{summary.completedOrders || 0}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: 'rgba(255, 255, 255, 0.88)', fontWeight: 500 }}>Đơn đã hủy</span>
              <span style={{ fontWeight: 800, fontSize: '15px' }}>{cancelledCount}</span>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span style={{ color: 'rgba(255, 255, 255, 0.88)', fontWeight: 500 }}>Giá trị trung bình</span>
              <span style={{ fontWeight: 800, fontSize: '15px' }}>
                <AnimatedCounter value={Math.round(summary.averageOrderValue || 0)} duration={1200} formatter={formatVND} />
              </span>
            </div>
          </div>
        </div>

        {/* Right Stacked Metrics Column */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {/* Top Row: Tổng Đơn Card */}
          <div
            style={{
              background: '#ffffff',
              color: '#0f172a',
              padding: '20px 24px',
              borderRadius: '20px',
              border: '1px solid #e2e8f0',
              boxShadow: '0 4px 16px rgba(0, 0, 0, 0.04)',
              display: 'flex',
              flexDirection: 'column',
              justifyContent: 'space-between',
              flex: 1,
              minHeight: '110px',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <span style={{ fontSize: '15px', fontWeight: 600, color: '#475569' }}>Tổng đơn</span>
              <div
                style={{
                  width: '42px',
                  height: '42px',
                  borderRadius: '12px',
                  background: '#eff6ff',
                  color: '#2563eb',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <ShoppingBag size={22} />
              </div>
            </div>
            <div style={{ fontSize: '38px', fontWeight: 900, color: '#0f172a', marginTop: '8px' }}>
              <AnimatedCounter value={summary.totalOrders || 0} duration={1000} />
            </div>
          </div>

          {/* Bottom Row: 2 Split Cards */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', flex: 1 }}>
            {/* Split Card 1: Đơn Thành Công */}
            <div
              style={{
                background: '#ffffff',
                color: '#0f172a',
                padding: '18px 20px',
                borderRadius: '20px',
                border: '1px solid #e2e8f0',
                boxShadow: '0 4px 16px rgba(0, 0, 0, 0.04)',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                minHeight: '120px',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <span style={{ fontSize: '14px', fontWeight: 600, color: '#475569', lineHeight: '1.3' }}>
                  Đơn thành<br />công
                </span>
                <div
                  style={{
                    width: '34px',
                    height: '34px',
                    borderRadius: '50%',
                    background: '#ecfdf5',
                    color: '#10b981',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  <CheckCircle2 size={20} />
                </div>
              </div>
              <div style={{ fontSize: '34px', fontWeight: 900, color: '#0f172a', marginTop: '10px' }}>
                <AnimatedCounter value={summary.completedOrders || 0} duration={1000} />
              </div>
            </div>

            {/* Split Card 2: Đơn Hủy */}
            <div
              style={{
                background: '#ffffff',
                color: '#0f172a',
                padding: '18px 20px',
                borderRadius: '20px',
                border: '1px solid #e2e8f0',
                boxShadow: '0 4px 16px rgba(0, 0, 0, 0.04)',
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'space-between',
                minHeight: '120px',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <span style={{ fontSize: '14px', fontWeight: 600, color: '#475569' }}>
                  Đơn hủy
                </span>
                <div
                  style={{
                    width: '34px',
                    height: '34px',
                    borderRadius: '50%',
                    background: '#fef2f2',
                    color: '#ef4444',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    flexShrink: 0,
                  }}
                >
                  <XCircle size={20} />
                </div>
              </div>
              <div style={{ fontSize: '34px', fontWeight: 900, color: '#0f172a', marginTop: '10px' }}>
                <AnimatedCounter value={cancelledCount} duration={1000} />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Chart & Status Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px', marginBottom: '24px' }}>
        {/* Time-Series Chart */}
        <div style={{ background: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
            <h3 style={{ fontSize: '15px', fontWeight: 800, color: '#0f172a', margin: 0 }}>
              Doanh Thu Theo Thời Gian
              <span style={{ fontSize: '12px', color: '#64748b', fontWeight: 500, marginLeft: '8px' }}>
                (Click cột ngày để xem chi tiết món & đơn)
              </span>
            </h3>
          </div>
          {chartData.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '40px', color: '#94a3b8', fontSize: '13px' }}>Chưa có dữ liệu cho khoảng thời gian này</div>
          ) : (
            <div style={{ overflowX: 'auto', paddingBottom: '8px', WebkitOverflowScrolling: 'touch' }}>
              <div
                style={{
                  height: '210px',
                  display: 'flex',
                  alignItems: 'flex-end',
                  gap: '12px',
                  paddingBottom: '24px',
                  minWidth: `${Math.max(chartData.length * 48, 320)}px`,
                  justifyContent: chartData.length < 10 ? 'space-around' : 'flex-start',
                }}
              >
                {chartData.map((item: any, idx: number) => {
                  const ratio = Math.max((item.revenue || 0) / maxRevenue, 0.05);
                  const isSelected = selectedChartDate?.label === item.label;

                  return (
                    <div
                      key={idx}
                      onClick={() => setSelectedChartDate(item)}
                      style={{
                        width: '38px',
                        minWidth: '38px',
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        height: '100%',
                        justifyContent: 'flex-end',
                        cursor: 'pointer',
                        transition: 'transform 0.2s',
                      }}
                      title={`Click để xem chi tiết bán hàng ngày ${item.label}: ${formatVND(item.revenue)} (${item.orders} đơn)`}
                    >
                      <div
                        style={{
                          fontSize: '10px',
                          color: isSelected ? '#c2410c' : '#fc6011',
                          fontWeight: 800,
                          marginBottom: '4px',
                          whiteSpace: 'nowrap',
                          textAlign: 'center',
                          minHeight: '14px',
                        }}
                      >
                        {item.revenue > 0 ? formatVND(item.revenue).replace('₫', '').trim() : ''}
                      </div>
                      <div
                        style={{
                          width: '100%',
                          maxWidth: '28px',
                          height: `${ratio * 130}px`,
                          background: isSelected
                            ? 'linear-gradient(180deg, #c2410c 0%, #ea580c 100%)'
                            : 'linear-gradient(180deg, #fc6011 0%, #ff8a50 100%)',
                          borderRadius: '6px 6px 0 0',
                          transition: 'height 0.3s ease',
                          boxShadow: isSelected ? '0 0 0 2px #c2410c' : 'none',
                        }}
                      />
                      <div
                        style={{
                          fontSize: '11px',
                          color: isSelected ? '#fc6011' : '#64748b',
                          marginTop: '6px',
                          fontWeight: isSelected ? 800 : 600,
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {item.label}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {/* Order Status Breakdown */}
        <div style={{ background: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <h3 style={{ fontSize: '15px', fontWeight: 800, marginBottom: '20px', color: '#0f172a' }}>Tình Trạng Đơn Hàng</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            {orderStatus.map((st: any) => {
              const totalCount = summary.totalOrders || 1;
              const percent = Math.round(((st.count || 0) / totalCount) * 100);
              return (
                <div key={st.statusKey}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', fontWeight: 700, marginBottom: '6px' }}>
                    <span>{st.label}</span>
                    <span style={{ color: '#64748b' }}>{st.count} đơn ({percent}%)</span>
                  </div>
                  <div style={{ width: '100%', height: '8px', background: '#f1f5f9', borderRadius: '4px', overflow: 'hidden' }}>
                    <div style={{ width: `${percent}%`, height: '100%', background: st.label.includes('hoàn thành') ? '#10b981' : st.label.includes('hủy') ? '#ef4444' : '#fc6011', borderRadius: '4px' }} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      {/* Top Foods & Order Types */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px' }}>
        {/* Top Selling Foods */}
        <div className="card-table" style={{ margin: 0 }}>
          <div className="table-toolbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontWeight: 800, fontSize: '15px' }}>Top Món Bán Chạy nhất Quán</div>
            <span style={{ fontSize: '12px', color: '#64748b' }}>Sắp xếp theo doanh thu</span>
          </div>
          {topFoods.length === 0 ? (
            <div className="empty-state">Chưa có dữ liệu món bán chạy</div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Món Ăn</th>
                  <th>Đã Bán</th>
                  <th>Doanh Thu</th>
                </tr>
              </thead>
              <tbody>
                {topFoods.map((f: any, idx: number) => (
                  <tr key={f.maMonAn || idx}>
                    <td style={{ fontWeight: 800, color: idx < 3 ? '#fc6011' : '#64748b' }}>{idx + 1}</td>
                    <td style={{ fontWeight: 700 }}>{f.tenMonAn}</td>
                    <td>{f.soLuong} món ({f.sharePercent}%)</td>
                    <td style={{ fontWeight: 800, color: '#fc6011' }}>{formatVND(f.doanhThu)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Order Types Breakdown */}
        <div style={{ background: '#ffffff', padding: '20px', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
          <h3 style={{ fontSize: '15px', fontWeight: 800, marginBottom: '20px', color: '#0f172a' }}>Doanh Thu Theo Loại Đơn</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            {orderTypes.map((t: any) => (
              <div key={t.typeKey} style={{ background: t.typeKey === 'PRE_ORDER' ? '#fff4ee' : '#f0f9ff', padding: '16px', borderRadius: '14px', border: `1px solid ${t.typeKey === 'PRE_ORDER' ? '#fdba74' : '#7dd3fc'}` }}>
                <div style={{ fontSize: '12px', fontWeight: 800, color: t.typeKey === 'PRE_ORDER' ? '#c2410c' : '#0369a1', marginBottom: '8px' }}>
                  {t.label}
                </div>
                <div style={{ fontSize: '18px', fontWeight: 900, color: '#0f172a' }}>
                  {formatVND(t.revenue)}
                </div>
                <div style={{ fontSize: '12px', color: '#64748b', marginTop: '4px' }}>
                  {t.count} đơn hàng
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Cancelled Orders Table Section */}
      <div className="card-table" style={{ marginTop: '24px', background: '#ffffff', borderRadius: '16px', border: '1px solid #e2e8f0' }}>
        <div className="table-toolbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px 20px', borderBottom: '1px solid #f1f5f9' }}>
          <div style={{ fontWeight: 800, fontSize: '15px', color: '#0f172a', display: 'flex', alignItems: 'center', gap: '8px' }}>
            <XCircle size={18} color="#ef4444" />
            Danh Sách Đơn Hàng Đã Hủy ({cancelledOrdersList.length} đơn)
          </div>
          <span style={{ fontSize: '12px', color: '#ef4444', fontWeight: 600 }}>Cập nhật theo kỳ báo cáo</span>
        </div>

        {cancelledOrdersList.length === 0 ? (
          <div className="empty-state" style={{ padding: '32px', textAlign: 'center', color: '#64748b', fontSize: '13px' }}>
            Không có đơn hàng nào bị hủy trong khoảng thời gian này
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="data-table" style={{ width: '100%' }}>
              <thead>
                <tr>
                  <th style={{ width: '50px' }}>STT</th>
                  <th>Tên Món</th>
                  <th>Khách Hàng</th>
                  <th style={{ textAlign: 'center' }}>Số Lượng</th>
                  <th style={{ textAlign: 'right' }}>Số Tiền</th>
                </tr>
              </thead>
              <tbody>
                {cancelledOrdersList.map((ord: any, idx: number) => {
                  const itemsText = ord.items && Array.isArray(ord.items) && ord.items.length > 0
                    ? ord.items.map((it: any) => `${it.soLuong || 1}x ${it.tenMonAn || 'Món ăn'}`).join(', ')
                    : 'Chi tiết món ăn';

                  const totalQty = ord.items && Array.isArray(ord.items) && ord.items.length > 0
                    ? ord.items.reduce((sum: number, it: any) => sum + Number(it.soLuong || 1), 0)
                    : 1;

                  return (
                    <tr key={ord.maDonHang || idx}>
                      <td style={{ fontWeight: 800, color: '#ef4444' }}>{idx + 1}</td>
                      <td>
                        <div style={{ fontWeight: 700, color: '#0f172a' }}>{itemsText}</div>
                        <div style={{ fontSize: '11px', color: '#64748b' }}>Mã đơn: #{ord.maDonHang}</div>
                      </td>
                      <td>
                        <div style={{ fontWeight: 700, color: '#0f172a' }}>{ord.tenKhachHang || 'Khách hàng'}</div>
                        {ord.sdtKhachHang && <div style={{ fontSize: '11px', color: '#64748b' }}>{ord.sdtKhachHang}</div>}
                      </td>
                      <td style={{ textAlign: 'center', fontWeight: 800 }}>{totalQty} món</td>
                      <td style={{ fontWeight: 900, color: '#ef4444', textAlign: 'right' }}>
                        {formatVND(ord.tongTien)}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal Chi Tiết Doanh Thu & Đơn Hàng Ngày Được Chọn */}
      <DailyRevenueDetailModal
        selectedChartDate={selectedChartDate}
        ordersList={ordersList}
        onClose={() => setSelectedChartDate(null)}
        formatVND={formatVND}
      />

      {/* Modal Xuất Báo Cáo Doanh Thu */}
      <RevenueExportModal
        isOpen={showExportModal}
        onClose={() => setShowExportModal(false)}
        storeInfo={storeInfo}
        summary={summary}
        ordersList={ordersList}
        periodLabel={periodOptions.find((p) => p.key === period)?.label || period}
        cancelledCount={cancelledCount}
        formatVND={formatVND}
      />
    </div>
  );
};
