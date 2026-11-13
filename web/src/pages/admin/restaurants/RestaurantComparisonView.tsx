import React, { useState, useEffect } from 'react';
import { apiFetch } from '../../../api/apiClient';
import {
  TrendingUp,
  DollarSign,
  ShoppingBag,
  Calendar,
  Filter,
  Check,
  Search,
  Store,
  Award,
  BarChart2,
  RefreshCw,
  X,
} from 'lucide-react';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../../utils/imageUtils';

interface RestaurantItem {
  maQuan: number;
  tenQuan: string;
  diaChi?: string;
  img?: string;
  trangThai?: string;
  isDeleted?: boolean;
}

const PALETTE = [
  { color: '#fc6011', light: '#fff4ee', name: 'Cam FoodRoute' },
  { color: '#10b981', light: '#ecfdf5', name: 'Xanh Lá' },
  { color: '#3b82f6', light: '#eff6ff', name: 'Xanh Dương' },
  { color: '#8b5cf6', light: '#f5f3ff', name: 'Tím' },
  { color: '#ec4899', light: '#fdf2f8', name: 'Hồng' },
  { color: '#06b6d4', light: '#ecfeff', name: 'Cyan' },
];

export const RestaurantComparisonView: React.FC = () => {
  const [allStores, setAllStores] = useState<RestaurantItem[]>([]);
  const [selectedIds, setSelectedIds] = useState<number[]>([]);
  const [searchStore, setSearchStore] = useState<string>('');
  const [isDropdownOpen, setIsDropdownOpen] = useState<boolean>(false);

  // Filter & Metric state
  const [metricMode, setMetricMode] = useState<'revenue' | 'orders'>('revenue');
  const [timeframe, setTimeframe] = useState<'day' | 'week' | 'month' | 'year' | 'single_date' | 'date_range'>('day');

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

  // Comparison data from API
  const [comparisonData, setComparisonData] = useState<{
    timeSlots: Array<{ key: string; label: string; fullDate?: string }>;
    restaurants: Array<{
      maQuan: number;
      tenQuan: string;
      diaChi: string;
      img: string;
      trangThai: string;
      totalRevenue: number;
      totalOrders: number;
      avgOrderValue: number;
      series: Array<{ slotKey: string; label: string; fullDate?: string; revenue: number; orders: number }>;
    }>;
  } | null>(null);

  const [loading, setLoading] = useState<boolean>(false);
  const [hoveredSlotIndex, setHoveredSlotIndex] = useState<number | null>(null);

  // Fetch store list on mount
  useEffect(() => {
    apiFetch<any>('/admin/restaurants?limit=1000')
      .then((res) => {
        const items = res.data?.items || res.items || [];
        const active = items.filter((s: any) => !s.isDeleted && s.trangThai !== 'ĐÃ XÓA');
        setAllStores(active);
        // Default select stores with known order history if available, else first 3
        if (active.length > 0 && selectedIds.length === 0) {
          const preferredIds = [12, 11, 3, 4, 2];
          const matched = active.filter((s: any) => preferredIds.includes(s.maQuan));
          const initial = matched.length >= 2 ? matched.slice(0, 3) : active.slice(0, 3);
          setSelectedIds(initial.map((s: any) => s.maQuan));
        }
      })
      .catch((err) => console.error('Error fetching restaurants for comparison:', err));
  }, []);

  // Fetch comparison data when selectedIds or timeframe/dates change
  const fetchComparison = () => {
    if (selectedIds.length === 0) {
      setComparisonData(null);
      return;
    }

    setLoading(true);
    let url = `/admin/restaurants/compare?ids=${selectedIds.join(',')}&timeframe=${timeframe}`;
    if (timeframe === 'single_date') {
      url += `&singleDate=${encodeURIComponent(singleDate)}`;
    } else if (timeframe === 'date_range') {
      url += `&fromDate=${encodeURIComponent(fromDate)}&toDate=${encodeURIComponent(toDate)}`;
    }

    apiFetch<any>(url)
      .then((res) => {
        if (res.data) {
          setComparisonData(res.data);
        }
      })
      .catch(async (err) => {
        console.error('Lỗi tải dữ liệu so sánh quán từ backend, chuyển sang tổng hợp trực tiếp:', err);
        try {
          const res = await apiFetch<any>('/admin/orders?limit=1000');
          const allOrders = res.data?.items || res.items || [];
          const now = new Date();
          const yr = now.getFullYear();
          const isComp = (o: any) => !['DA_HUY', 'CANCELLED', 'THAT_BAI'].includes((o.trangThai || '').toUpperCase());

          const slots: Array<{ key: string; label: string; fullDate?: string; match: (d: Date) => boolean }> = [];
          if (timeframe === 'month') {
            for (let m = 0; m < 12; m++) {
              slots.push({ key: `m_${m}`, label: `T${m + 1}`, fullDate: `Tháng ${m + 1}/${yr}`, match: (d) => d.getMonth() === m && d.getFullYear() === yr });
            }
          } else if (timeframe === 'year') {
            for (let i = 4; i >= 0; i--) {
              slots.push({ key: `y_${yr - i}`, label: `${yr - i}`, fullDate: `Năm ${yr - i}`, match: (d) => d.getFullYear() === yr - i });
            }
          } else if (timeframe === 'week') {
            for (let i = 3; i >= 0; i--) {
              const eD = new Date(now.getTime() - i * 7 * 86400000);
              const sD = new Date(eD.getTime() - 6 * 86400000);
              slots.push({ key: `w_${i}`, label: `Tuần ${4 - i}`, fullDate: `${sD.getDate()}/${sD.getMonth() + 1} - ${eD.getDate()}/${eD.getMonth() + 1}`, match: (d) => d >= sD && d <= eD });
            }
          } else {
            for (let i = 6; i >= 0; i--) {
              const d = new Date(now.getTime() - i * 86400000);
              const ds = d.toISOString().split('T')[0];
              slots.push({ key: ds, label: `${d.getDate()}/${d.getMonth() + 1}`, fullDate: ds, match: (dt) => dt.toISOString().split('T')[0] === ds });
            }
          }

          const stores = allStores.filter((s) => selectedIds.includes(s.maQuan)).map((store) => {
            const sOrders = allOrders.filter((o: any) => Number(o.maQuan) === Number(store.maQuan) && isComp(o));
            let tRev = 0, tOrd = 0;
            const series = slots.map((sl) => {
              let rev = 0, ords = 0;
              for (const ord of sOrders) {
                if (sl.match(new Date(ord.thoiGianDat))) { ords++; rev += Number(ord.tongTien || 0); }
              }
              tRev += rev; tOrd += ords;
              return { slotKey: sl.key, label: sl.label, fullDate: sl.fullDate, revenue: rev, orders: ords };
            });
            return {
              maQuan: store.maQuan, tenQuan: store.tenQuan, diaChi: store.diaChi || '', img: store.img || '',
              trangThai: store.trangThai || 'mở cửa', totalRevenue: tRev, totalOrders: tOrd,
              avgOrderValue: tOrd > 0 ? Math.round(tRev / tOrd) : 0, series,
            };
          });
          setComparisonData({ timeSlots: slots.map(({ key, label, fullDate }) => ({ key, label, fullDate })), restaurants: stores });
        } catch (_) {}
      })
      .finally(() => {
        setLoading(false);
      });
  };

  useEffect(() => {
    if (selectedIds.length > 0) {
      fetchComparison();
    }
  }, [selectedIds, timeframe]);

  const toggleSelectStore = (id: number) => {
    if (selectedIds.includes(id)) {
      if (selectedIds.length === 1) return; // Keep at least 1
      setSelectedIds(selectedIds.filter((item) => item !== id));
    } else {
      if (selectedIds.length >= 6) {
        alert('Tối đa so sánh cùng lúc 6 nhà hàng');
        return;
      }
      setSelectedIds([...selectedIds, id]);
    }
  };

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  const formatDateDisplay = (dateStr: string) => {
    if (!dateStr) return '';
    try {
      const parts = dateStr.split('-');
      if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`;
    } catch (_) {}
    return dateStr;
  };

  // Filtered dropdown stores
  const filteredSearchStores = allStores.filter((s) =>
    (s.tenQuan || '').toLowerCase().includes(searchStore.toLowerCase())
  );

  // Calculate highest value in series to scale bars
  const timeSlots = comparisonData?.timeSlots || [];
  const restaurants = comparisonData?.restaurants || [];

  let maxChartVal = 1;
  restaurants.forEach((r) => {
    (r.series || []).forEach((s) => {
      const v = metricMode === 'revenue' ? s.revenue : s.orders;
      if (v > maxChartVal) maxChartVal = v;
    });
  });
  if (metricMode === 'revenue' && maxChartVal < 100000) maxChartVal = 100000;
  if (metricMode === 'orders' && maxChartVal < 5) maxChartVal = 5;

  const totalAllRevenue = restaurants.reduce((sum, r) => sum + (r.totalRevenue || 0), 0);
  const totalAllOrders = restaurants.reduce((sum, r) => sum + (r.totalOrders || 0), 0);

  // Sorted restaurants for ranking
  const sortedRestaurants = [...restaurants].sort((a, b) => {
    return metricMode === 'revenue' ? b.totalRevenue - a.totalRevenue : b.totalOrders - a.totalOrders;
  });

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
      {/* Header */}
      <div className="page-header" style={{ marginBottom: 0 }}>
        <div>
          <h1 className="page-title" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <TrendingUp size={22} color="#fc6011" /> So Sánh Hiệu Quả Kinh Doanh Các Quán Ăn
          </h1>
          <p className="page-subtitle">
            Phân tích và đối sánh doanh thu, đơn hàng đã bán giữa các nhà hàng do Quản trị viên chọn
          </p>
        </div>
        <button
          onClick={fetchComparison}
          className="btn btn-outline"
          style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px' }}
        >
          <RefreshCw size={14} /> Làm Mới
        </button>
      </div>

      {/* Restaurant Selector Bar */}
      <div
        style={{
          background: '#ffffff',
          borderRadius: '14px',
          border: '1px solid #e2e8f0',
          padding: '16px 20px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px', flexWrap: 'wrap', gap: '10px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Store size={18} color="#fc6011" />
            <span style={{ fontSize: '14px', fontWeight: 800, color: '#0f172a' }}>
              Chọn nhà hàng đối sánh ({selectedIds.length}/6 quán):
            </span>
          </div>
          <span style={{ fontSize: '12px', color: '#64748b' }}>
            Bấm vào quán để thêm hoặc bớt khỏi danh sách so sánh
          </span>
        </div>

        {/* Selected Store Badges */}
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap', marginBottom: '14px' }}>
          {selectedIds.map((id, idx) => {
            const store = allStores.find((s) => s.maQuan === id);
            const paletteItem = PALETTE[idx % PALETTE.length];
            return (
              <div
                key={id}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '6px 12px',
                  borderRadius: '20px',
                  background: paletteItem.light,
                  border: `1.5px solid ${paletteItem.color}`,
                  color: '#0f172a',
                  fontSize: '13px',
                  fontWeight: 700,
                }}
              >
                <div
                  style={{
                    width: '10px',
                    height: '10px',
                    borderRadius: '50%',
                    background: paletteItem.color,
                  }}
                />
                <img
                  src={getImageUrl(store?.img, DEFAULT_IMAGE_PLACEHOLDER)}
                  onError={handleImageError}
                  alt=""
                  style={{ width: '20px', height: '20px', borderRadius: '50%', objectFit: 'cover' }}
                />
                <span>{store?.tenQuan || `#${id}`}</span>
                {selectedIds.length > 1 && (
                  <button
                    onClick={() => toggleSelectStore(id)}
                    style={{
                      border: 'none',
                      background: 'transparent',
                      cursor: 'pointer',
                      padding: 0,
                      display: 'flex',
                      alignItems: 'center',
                      color: '#64748b',
                    }}
                  >
                    <X size={14} />
                  </button>
                )}
              </div>
            );
          })}
        </div>

        {/* Search & Select dropdown trigger */}
        <div style={{ position: 'relative' }}>
          <div style={{ display: 'flex', gap: '10px' }}>
            <div style={{ position: 'relative', flex: 1 }}>
              <Search size={16} style={{ position: 'absolute', left: '12px', top: '10px', color: '#94a3b8' }} />
              <input
                type="text"
                placeholder="Tìm thêm nhà hàng để đưa vào biểu đồ so sánh..."
                value={searchStore}
                onFocus={() => setIsDropdownOpen(true)}
                onChange={(e) => {
                  setSearchStore(e.target.value);
                  setIsDropdownOpen(true);
                }}
                style={{
                  width: '100%',
                  padding: '10px 14px 10px 38px',
                  minHeight: '44px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '16px',
                  outline: 'none',
                }}
              />
            </div>
            {isDropdownOpen && (
              <button
                onClick={() => setIsDropdownOpen(false)}
                className="btn btn-outline btn-sm"
                style={{ fontSize: '12px', padding: '6px 12px' }}
              >
                Đóng danh sách
              </button>
            )}
          </div>

          {/* Dropdown list */}
          {isDropdownOpen && (
            <div
              style={{
                position: 'absolute',
                top: '100%',
                left: 0,
                right: 0,
                marginTop: '6px',
                background: '#ffffff',
                border: '1px solid #cbd5e1',
                borderRadius: '10px',
                maxHeight: '260px',
                overflowY: 'auto',
                boxShadow: '0 8px 24px rgba(0,0,0,0.12)',
                zIndex: 30,
                padding: '6px',
              }}
            >
              {filteredSearchStores.length === 0 ? (
                <div style={{ padding: '12px', textAlign: 'center', color: '#94a3b8', fontSize: '13px' }}>
                  Không tìm thấy quán nào phù hợp
                </div>
              ) : (
                filteredSearchStores.map((s) => {
                  const isChecked = selectedIds.includes(s.maQuan);
                  return (
                    <div
                      key={s.maQuan}
                      onClick={() => toggleSelectStore(s.maQuan)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        padding: '8px 12px',
                        borderRadius: '6px',
                        cursor: 'pointer',
                        background: isChecked ? '#fff7ed' : 'transparent',
                        transition: 'background 0.15s',
                      }}
                      onMouseEnter={(e) => {
                        if (!isChecked) (e.currentTarget as any).style.background = '#f8fafc';
                      }}
                      onMouseLeave={(e) => {
                        if (!isChecked) (e.currentTarget as any).style.background = 'transparent';
                      }}
                    >
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <img
                          src={getImageUrl(s.img, DEFAULT_IMAGE_PLACEHOLDER)}
                          onError={handleImageError}
                          alt=""
                          style={{ width: '32px', height: '32px', borderRadius: '6px', objectFit: 'cover' }}
                        />
                        <div>
                          <div style={{ fontSize: '13px', fontWeight: 700, color: '#0f172a' }}>{s.tenQuan}</div>
                          <div style={{ fontSize: '11px', color: '#64748b' }}>{s.diaChi || 'Chưa cập nhật địa chỉ'}</div>
                        </div>
                      </div>
                      <div
                        style={{
                          width: '20px',
                          height: '20px',
                          borderRadius: '4px',
                          border: isChecked ? '2px solid #fc6011' : '2px solid #cbd5e1',
                          background: isChecked ? '#fc6011' : '#ffffff',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: '#ffffff',
                        }}
                      >
                        {isChecked && <Check size={14} />}
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          )}
        </div>
      </div>

      {/* Main Chart Box */}
      <div
        style={{
          background: '#ffffff',
          borderRadius: '16px',
          border: '1px solid #e2e8f0',
          padding: '24px',
          boxShadow: '0 2px 8px rgba(0,0,0,0.04)',
        }}
      >
        {/* Controls: Metric Mode Toggle & Timeframe Selector */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '12px', marginBottom: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <BarChart2 size={20} color="#fc6011" />
            <span style={{ fontSize: '16px', fontWeight: 800, color: '#0f172a' }}>
              Biểu Đồ Đối Sánh Trực Quan
            </span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
            {/* Metric Toggle: Doanh thu / Đơn hàng */}
            <div style={{ display: 'flex', background: '#f1f5f9', padding: '3px', borderRadius: '8px', gap: '2px' }}>
              <button
                onClick={() => setMetricMode('revenue')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  padding: '6px 12px',
                  fontSize: '12px',
                  fontWeight: 700,
                  borderRadius: '6px',
                  border: 'none',
                  cursor: 'pointer',
                  background: metricMode === 'revenue' ? '#10b981' : 'transparent',
                  color: metricMode === 'revenue' ? '#ffffff' : '#64748b',
                  transition: 'all 0.2s',
                  boxShadow: metricMode === 'revenue' ? '0 2px 6px rgba(16,185,129,0.3)' : 'none',
                }}
              >
                <DollarSign size={14} /> Doanh Thu (VNĐ)
              </button>
              <button
                onClick={() => setMetricMode('orders')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  padding: '6px 12px',
                  fontSize: '12px',
                  fontWeight: 700,
                  borderRadius: '6px',
                  border: 'none',
                  cursor: 'pointer',
                  background: metricMode === 'orders' ? '#3b82f6' : 'transparent',
                  color: metricMode === 'orders' ? '#ffffff' : '#64748b',
                  transition: 'all 0.2s',
                  boxShadow: metricMode === 'orders' ? '0 2px 6px rgba(59,130,246,0.3)' : 'none',
                }}
              >
                <ShoppingBag size={14} /> Đơn Hàng Đã Bán
              </button>
            </div>

            {/* Timeframe selector */}
            <div style={{ display: 'flex', background: '#f1f5f9', padding: '3px', borderRadius: '8px', gap: '2px' }}>
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
                  onClick={() => setTimeframe(t.key as any)}
                  style={{
                    padding: '6px 12px',
                    fontSize: '12px',
                    fontWeight: 700,
                    borderRadius: '6px',
                    border: 'none',
                    cursor: 'pointer',
                    background: timeframe === t.key ? '#fc6011' : 'transparent',
                    color: timeframe === t.key ? '#ffffff' : '#64748b',
                    transition: 'all 0.2s',
                    boxShadow: timeframe === t.key ? '0 2px 6px rgba(252,96,17,0.3)' : 'none',
                  }}
                >
                  {t.label}
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Date pickers */}
        {timeframe === 'single_date' && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              marginBottom: '16px',
              padding: '10px 16px',
              background: '#fff7ed',
              borderRadius: '10px',
              border: '1px solid #fed7aa',
              flexWrap: 'wrap',
            }}
          >
            <Calendar size={18} color="#ea580c" />
            <span style={{ fontSize: '13px', fontWeight: 700, color: '#9a3412' }}>Chọn ngày đối sánh:</span>
            <input
              type="date"
              value={singleDate}
              onChange={(e) => {
                setSingleDate(e.target.value);
              }}
              style={{
                padding: '6px 12px',
                minHeight: '44px',
                borderRadius: '8px',
                border: '1px solid #fdba74',
                fontSize: '16px',
                fontWeight: 600,
                outline: 'none',
              }}
            />
            <button
              onClick={fetchComparison}
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
              Áp dụng
            </button>
            <span style={{ fontSize: '12px', color: '#7c2d12', fontStyle: 'italic' }}>
              (So sánh doanh thu các khung giờ ngày {formatDateDisplay(singleDate)})
            </span>
          </div>
        )}

        {timeframe === 'date_range' && (
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              marginBottom: '16px',
              padding: '10px 16px',
              background: '#fff7ed',
              borderRadius: '10px',
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
              onClick={fetchComparison}
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
              }}
            >
              Lọc kết quả
            </button>
          </div>
        )}

        {/* Legend showing Color + Store + Metric Total */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '16px',
            flexWrap: 'wrap',
            marginBottom: '16px',
            padding: '10px 14px',
            background: '#f8fafc',
            borderRadius: '10px',
            border: '1px solid #f1f5f9',
          }}
        >
          <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b' }}>Chú giải màu:</span>
          {restaurants.map((r, idx) => {
            const p = PALETTE[idx % PALETTE.length];
            return (
              <div key={r.maQuan} style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <div style={{ width: '12px', height: '12px', borderRadius: '3px', background: p.color }} />
                <span style={{ fontSize: '12px', fontWeight: 700, color: '#0f172a' }}>{r.tenQuan}:</span>
                <span style={{ fontSize: '12px', fontWeight: 800, color: p.color }}>
                  {metricMode === 'revenue' ? formatVND(r.totalRevenue) : `${r.totalOrders} đơn`}
                </span>
              </div>
            );
          })}
        </div>

        {/* Grouped Bar Chart Area */}
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
          {loading ? (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '240px', gap: '10px' }}>
              <div className="loading-spinner" />
              <span style={{ fontSize: '13px', color: '#64748b', fontWeight: 600 }}>Đang so sánh dữ liệu các quán...</span>
            </div>
          ) : timeSlots.length === 0 || restaurants.length === 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '240px', color: '#94a3b8' }}>
              <BarChart2 size={40} style={{ opacity: 0.4, marginBottom: '8px' }} />
              <span style={{ fontSize: '13px', fontWeight: 600 }}>Chưa có dữ liệu so sánh trong mốc thời gian này</span>
            </div>
          ) : (
            <div
              style={{
                display: 'flex',
                alignItems: 'flex-end',
                justifyContent: 'space-between',
                height: '240px',
                gap: timeSlots.length > 7 ? '10px' : '16px',
                minWidth: timeSlots.length > 7 ? `${timeSlots.length * 64}px` : '100%',
                width: '100%',
                paddingBottom: '6px',
              }}
            >
              {timeSlots.map((slot, slotIdx) => {
                const isSlotHovered = hoveredSlotIndex === slotIdx;
                return (
                  <div
                    key={slot.key}
                    onMouseEnter={() => setHoveredSlotIndex(slotIdx)}
                    onMouseLeave={() => setHoveredSlotIndex(null)}
                    style={{
                      flex: 1,
                      minWidth: `${Math.max(restaurants.length * 16 + 12, 44)}px`,
                      maxWidth: '120px',
                      display: 'flex',
                      flexDirection: 'column',
                      alignItems: 'center',
                      height: '100%',
                      justifyContent: 'flex-end',
                      position: 'relative',
                      cursor: 'pointer',
                    }}
                  >
                    {/* Tooltip on Slot Hover */}
                    {isSlotHovered && (
                      <div
                        style={{
                          position: 'absolute',
                          top: '8px',
                          bottom: 'auto',
                          left: slotIdx <= 1 ? '0px' : slotIdx >= timeSlots.length - 2 ? 'auto' : '50%',
                          right: slotIdx >= timeSlots.length - 2 ? '0px' : 'auto',
                          transform: slotIdx <= 1 || slotIdx >= timeSlots.length - 2 ? 'none' : 'translateX(-50%)',
                          background: '#0f172a',
                          color: '#ffffff',
                          padding: '10px 14px',
                          borderRadius: '10px',
                          fontSize: '12px',
                          boxShadow: '0 10px 28px rgba(0,0,0,0.4)',
                          border: '1px solid #334155',
                          zIndex: 50,
                          minWidth: '240px',
                          maxWidth: '320px',
                          pointerEvents: 'none',
                        }}
                      >
                        <div style={{ fontWeight: 800, color: '#f8fafc', borderBottom: '1px solid #334155', paddingBottom: '6px', marginBottom: '8px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                          <span>{slot.fullDate || slot.label}</span>
                          <span style={{ fontSize: '10px', color: '#94a3b8', fontWeight: 600 }}>Đối sánh {restaurants.length} quán</span>
                        </div>
                        {restaurants.map((r, rIdx) => {
                          const p = PALETTE[rIdx % PALETTE.length];
                          const sItem = (r.series || []).find((s) => s.slotKey === slot.key);
                          const rev = sItem?.revenue || 0;
                          const ords = sItem?.orders || 0;
                          const val = metricMode === 'revenue' ? rev : ords;
                          return (
                            <div key={r.maQuan} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '5px', gap: '10px' }}>
                              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', minWidth: 0 }}>
                                <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: p.color, flexShrink: 0 }} />
                                <span style={{ color: '#e2e8f0', fontWeight: 600, fontSize: '11px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '160px' }} title={r.tenQuan}>
                                  {r.tenQuan}
                                </span>
                              </div>
                              <span style={{ fontWeight: 800, fontSize: '12px', whiteSpace: 'nowrap', color: val > 0 ? '#34d399' : '#94a3b8', flexShrink: 0 }}>
                                {metricMode === 'revenue' ? formatVND(rev) : `${ords} đơn`}
                              </span>
                            </div>
                          );
                        })}
                      </div>
                    )}

                    {/* Group of Bars for each Restaurant */}
                    <div
                      style={{
                        display: 'flex',
                        alignItems: 'flex-end',
                        justifyContent: 'center',
                        gap: '4px',
                        width: '100%',
                        height: '100%',
                      }}
                    >
                      {restaurants.map((r, rIdx) => {
                        const p = PALETTE[rIdx % PALETTE.length];
                        const sItem = (r.series || []).find((s) => s.slotKey === slot.key);
                        const val = metricMode === 'revenue' ? sItem?.revenue || 0 : sItem?.orders || 0;
                        const heightPercent = maxChartVal > 0 ? Math.max((val / maxChartVal) * 100, 6) : 6;

                        return (
                          <div
                            key={r.maQuan}
                            style={{
                              flex: 1,
                              maxWidth: '18px',
                              height: `${heightPercent}%`,
                              background: val > 0 ? p.color : '#e2e8f0',
                              borderRadius: '4px 4px 0 0',
                              transition: 'height 0.4s ease, opacity 0.2s',
                              opacity: isSlotHovered ? 1 : 0.88,
                              boxShadow: isSlotHovered && val > 0 ? `0 2px 8px ${p.color}55` : 'none',
                            }}
                          />
                        );
                      })}
                    </div>

                    {/* Slot Label */}
                    <div style={{ fontSize: '11px', color: '#475569', marginTop: '8px', fontWeight: 700, textAlign: 'center', whiteSpace: 'nowrap' }}>
                      {slot.label}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Comparison Summary & Ranking Table */}
      <div
        style={{
          background: '#ffffff',
          borderRadius: '16px',
          border: '1px solid #e2e8f0',
          padding: '20px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '16px' }}>
          <Award size={20} color="#fc6011" />
          <h3 style={{ fontSize: '16px', fontWeight: 800, margin: 0, color: '#0f172a' }}>
            Bảng Xếp Hạng & Thống Kê Tổng Hợp Trong Kỳ
          </h3>
        </div>

        <div className="table-responsive">
          <table className="table" style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#f8fafc', borderBottom: '1px solid #e2e8f0', textAlign: 'left' }}>
                <th style={{ padding: '12px', fontSize: '12px', fontWeight: 800, color: '#475569' }}>HẠNG</th>
                <th style={{ padding: '12px', fontSize: '12px', fontWeight: 800, color: '#475569' }}>NHÀ HÀNG</th>
                <th style={{ padding: '12px', fontSize: '12px', fontWeight: 800, color: '#475569' }}>DOANH THU KỲ NÀY</th>
                <th style={{ padding: '12px', fontSize: '12px', fontWeight: 800, color: '#475569' }}>ĐƠN HÀNG ĐÃ BÁN</th>
                <th style={{ padding: '12px', fontSize: '12px', fontWeight: 800, color: '#475569' }}>TB / ĐƠN HÀNG</th>
                <th style={{ padding: '12px', fontSize: '12px', fontWeight: 800, color: '#475569' }}>TỶ TRỌNG DOANH THU</th>
              </tr>
            </thead>
            <tbody>
              {sortedRestaurants.map((store, rank) => {
                const origIndex = restaurants.findIndex((r) => r.maQuan === store.maQuan);
                const p = PALETTE[origIndex % PALETTE.length];
                const revenueShare = totalAllRevenue > 0 ? ((store.totalRevenue / totalAllRevenue) * 100).toFixed(1) : '0';

                return (
                  <tr key={store.maQuan} style={{ borderBottom: '1px solid #f1f5f9' }}>
                    <td style={{ padding: '12px', fontWeight: 800 }}>
                      <span
                        style={{
                          width: '24px',
                          height: '24px',
                          borderRadius: '50%',
                          background: rank === 0 ? '#fef3c7' : rank === 1 ? '#e2e8f0' : '#f1f5f9',
                          color: rank === 0 ? '#d97706' : rank === 1 ? '#475569' : '#64748b',
                          display: 'inline-flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontSize: '12px',
                        }}
                      >
                        #{rank + 1}
                      </span>
                    </td>
                    <td style={{ padding: '12px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <div style={{ width: '4px', height: '32px', borderRadius: '2px', background: p.color }} />
                        <img
                          src={getImageUrl(store.img, DEFAULT_IMAGE_PLACEHOLDER)}
                          onError={handleImageError}
                          alt=""
                          style={{ width: '36px', height: '36px', borderRadius: '8px', objectFit: 'cover' }}
                        />
                        <div>
                          <div style={{ fontWeight: 700, fontSize: '13px', color: '#0f172a' }}>{store.tenQuan}</div>
                          <div style={{ fontSize: '11px', color: '#64748b' }}>{store.diaChi || 'Chưa có địa chỉ'}</div>
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '12px', fontWeight: 800, color: '#10b981', fontSize: '14px' }}>
                      {formatVND(store.totalRevenue)}
                    </td>
                    <td style={{ padding: '12px', fontWeight: 800, color: '#3b82f6', fontSize: '14px' }}>
                      {store.totalOrders} đơn
                    </td>
                    <td style={{ padding: '12px', fontWeight: 600, color: '#64748b', fontSize: '13px' }}>
                      {formatVND(store.avgOrderValue)}
                    </td>
                    <td style={{ padding: '12px' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <div style={{ flex: 1, maxWidth: '100px', height: '6px', background: '#e2e8f0', borderRadius: '3px', overflow: 'hidden' }}>
                          <div
                            style={{
                              width: `${revenueShare}%`,
                              height: '100%',
                              background: p.color,
                              borderRadius: '3px',
                            }}
                          />
                        </div>
                        <span style={{ fontSize: '12px', fontWeight: 700, color: '#0f172a' }}>{revenueShare}%</span>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

