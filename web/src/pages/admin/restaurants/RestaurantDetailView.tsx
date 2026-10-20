import React, { useState, useEffect } from 'react';
import { apiFetch } from '../../../api/apiClient';
import {
  ArrowLeft,
  DollarSign,
  Calendar,
  Utensils,
  ShoppingBag,
  MapPin,
  Phone,
  User,
  Building,
  TrendingUp,
  CreditCard,
  BarChart3,
  RefreshCw,
  Edit2,
} from 'lucide-react';
import { StatusBadge } from '../../../components/StatusBadge';
import { Modal } from '../../../components/Modal';
import { NotificationModal } from '../../../components/NotificationModal';
import { ImageCropUpload } from '../../../components/ImageCropUpload';
import { formatDateVN } from '../../../utils/ocrService';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../../utils/imageUtils';

interface RestaurantDetailViewProps {
  restaurantId: number;
  onBack: () => void;
}

export const RestaurantDetailView: React.FC<RestaurantDetailViewProps> = ({
  restaurantId,
  onBack,
}) => {
  const [loading, setLoading] = useState(true);
  const [detailData, setDetailData] = useState<any>(null);
  const [activeTab, setActiveTab] = useState<'menu' | 'orders' | 'owner'>('menu');

  // Food Edit Modal state
  const [categories, setCategories] = useState<any[]>([]);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editingFood, setEditingFood] = useState<any>(null);

  // Notification Modal State
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
  const [editForm, setEditForm] = useState({
    tenMonAn: '',
    maDanhMuc: '',
    giaMonAn: '',
    soLuongMon: '100',
    img: '',
  });

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  const loadDetail = () => {
    if (!restaurantId) return;
    setLoading(true);

    apiFetch<any>(`/admin/restaurants/${restaurantId}/detail`)
      .then((res) => {
        if (res.data) {
          setDetailData(res.data);
        } else {
          throw new Error('No data');
        }
      })
      .catch(async () => {
        // Fallback: fetch store, foods, and orders directly from real DB endpoints
        try {
          const [storesRes, foodsRes, ordersRes] = await Promise.all([
            apiFetch<any>(`/admin/restaurants`).catch(() => ({ data: { items: [] } } as any)),
            apiFetch<any>(`/admin/foods?maQuan=${restaurantId}&limit=100`).catch(() => ({ data: { items: [] } } as any)),
            apiFetch<any>(`/admin/orders?limit=100`).catch(() => ({ data: { items: [] } } as any)),
          ]);

          const storeList = storesRes.data?.items || [];
          const store = storeList.find((s: any) => Number(s.maQuan) === Number(restaurantId)) || {
            maQuan: restaurantId,
            tenQuan: `Nhà Hàng #${restaurantId}`,
            diaChi: 'Chưa cập nhật địa chỉ',
            trangThai: 'mở cửa',
          };

          const rawFoods = foodsRes.data?.items || foodsRes.items || [];
          const foods = rawFoods.filter((f: any) => Number(f.maQuan) === Number(restaurantId));
          const allOrders = ordersRes.data?.items || ordersRes.items || [];
          const storeOrders = allOrders.filter((o: any) => Number(o.maQuan) === Number(restaurantId));

          const now = new Date();
          const todayStr = now.toISOString().split('T')[0];
          const currentMonth = now.getMonth();
          const currentYear = now.getFullYear();

          let totalRevenue = 0;
          let todayRevenue = 0;
          let monthRevenue = 0;
          let completedOrders = 0;

          for (const ord of storeOrders) {
            const isCompleted =
              ord.trangThai === 'COMPLETED' ||
              ord.trangThai === 'HOAN_THANH' ||
              ord.trangThai === 'đã hoàn thành' ||
              ord.trangThai === 'ĐÃ HOÀN THÀNH' ||
              ord.trangThai === 'PICKED_UP';
            const amount = Number(ord.tongTien || 0);
            const ordDate = new Date(ord.thoiGianDat);

            totalRevenue += amount;
            if (isCompleted) completedOrders++;

            if (ordDate.toISOString().split('T')[0] === todayStr) {
              todayRevenue += amount;
            }

            if (ordDate.getMonth() === currentMonth && ordDate.getFullYear() === currentYear) {
              monthRevenue += amount;
            }
          }

          // Generate 7-day daily chart data from real orders
          const chartData = [];
          for (let i = 6; i >= 0; i--) {
            const d = new Date();
            d.setDate(d.getDate() - i);
            const dayStr = d.toISOString().split('T')[0];
            const displayLabel = `${d.getDate()}/${d.getMonth() + 1}`;

            let dayRev = 0;
            let dayCount = 0;

            for (const ord of storeOrders) {
              const ordDate = new Date(ord.thoiGianDat);
              if (ordDate.toISOString().split('T')[0] === dayStr) {
                dayCount++;
                dayRev += Number(ord.tongTien || 0);
              }
            }

            chartData.push({
              date: displayLabel,
              fullDate: dayStr,
              revenue: dayRev,
              ordersCount: dayCount,
            });
          }

          setDetailData({
            store,
            stats: {
              totalRevenue,
              todayRevenue,
              monthRevenue,
              totalFoods: foods.length,
              totalOrders: storeOrders.length,
              completedOrders,
            },
            chartData,
            foods,
            recentOrders: storeOrders,
          });
        } catch (_) {
          setDetailData(null);
        }
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadDetail();
    apiFetch<any>('/admin/categories')
      .then((res) => setCategories(res.data || []))
      .catch(() => {});
  }, [restaurantId]);

  const handleOpenEditFood = (food: any) => {
    setEditingFood(food);
    setEditForm({
      tenMonAn: food.tenMonAn || '',
      maDanhMuc: food.maDanhMuc ? String(food.maDanhMuc) : '',
      giaMonAn: String(food.giaMonAn || 0),
      soLuongMon: String(food.soLuongMon || 100),
      img: food.img || '',
    });
    setEditModalOpen(true);
  };

  const handleSaveFood = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingFood) return;
    try {
      await apiFetch(`/admin/foods/${editingFood.maMonAn}`, {
        method: 'PUT',
        body: JSON.stringify({
          tenMonAn: editForm.tenMonAn,
          maDanhMuc: editForm.maDanhMuc ? Number(editForm.maDanhMuc) : undefined,
          giaMonAn: Number(editForm.giaMonAn),
          soLuongMon: Number(editForm.soLuongMon),
          img: editForm.img,
        }),
      });
      setEditModalOpen(false);
      loadDetail();
      showNotify('success', 'Cập Nhật Thành Công', 'Thông tin món ăn đã được cập nhật thành công!');
    } catch (err: any) {
      showNotify('error', 'Lỗi Cập Nhật', err.message || 'Lỗi cập nhật món ăn');
    }
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '60px' }}>
        <div className="loading-spinner" />
        <p style={{ marginTop: '12px', color: '#64748b' }}>Đang tải dữ liệu thực tế của nhà hàng #{restaurantId}...</p>
      </div>
    );
  }

  const store = detailData?.store || {};
  const stats = detailData?.stats || {
    totalRevenue: 0,
    todayRevenue: 0,
    monthRevenue: 0,
    totalFoods: 0,
    totalOrders: 0,
    completedOrders: 0,
  };
  const chartData = detailData?.chartData || [];
  const rawFoodsList = detailData?.foods || [];

  const foodsList = rawFoodsList.filter((f: any) => {
    const storeNameLower = (store.tenQuan || '').toLowerCase();
    const foodNameLower = (f.tenMonAn || '').toLowerCase();

    if (storeNameLower.includes('cơm tấm')) {
      if (foodNameLower.includes('cà phê') || foodNameLower.includes('trà sữa') || foodNameLower.includes('croissant')) {
        return false;
      }
    }

    if (storeNameLower.includes('bún bò') || storeNameLower.includes('huế')) {
      if (foodNameLower.includes('cà phê') || foodNameLower.includes('phở') || foodNameLower.includes('cơm tấm')) {
        return false;
      }
    }

    if (storeNameLower.includes('phở')) {
      if (foodNameLower.includes('cơm tấm') || foodNameLower.includes('bún bò') || foodNameLower.includes('croissant')) {
        return false;
      }
    }

    return true;
  });

  const ordersList = detailData?.recentOrders || [];

  // Calculate max revenue in 7 days chart to scale bars
  const maxChartRev = Math.max(...chartData.map((d: any) => d.revenue), 100000);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      {/* Top Bar Navigation */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          background: '#ffffff',
          padding: '12px 18px',
          borderRadius: '12px',
          border: '1px solid #e2e8f0',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <button
            onClick={onBack}
            className="btn btn-outline btn-sm"
            style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 600, padding: '6px 12px' }}
          >
            <ArrowLeft size={16} /> Quay lại danh sách
          </button>
          <div style={{ height: '20px', width: '1px', background: '#e2e8f0' }} />
          <img
            src={getImageUrl(store.img, DEFAULT_IMAGE_PLACEHOLDER)}
            alt={store.tenQuan}
            onError={handleImageError}
            style={{ width: '38px', height: '38px', borderRadius: '8px', objectFit: 'cover' }}
          />
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <h2 style={{ fontSize: '16px', fontWeight: 800, margin: 0, color: '#0f172a' }}>
                {store.tenQuan || `Nhà Hàng #${restaurantId}`}
              </h2>
              <StatusBadge status={store.trangThai || 'mở cửa'} />
            </div>
            <div style={{ fontSize: '12px', color: '#64748b', display: 'flex', alignItems: 'center', gap: '4px' }}>
              <MapPin size={12} color="#fc6011" /> {store.diaChi || 'Chưa có địa chỉ'}
            </div>
          </div>
        </div>

        <button
          onClick={loadDetail}
          className="btn btn-outline btn-sm"
          style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#64748b' }}
        >
          <RefreshCw size={14} /> Làm mới
        </button>
      </div>

      {/* 4 Clean Metric Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px' }}>
        {/* Metric 1 */}
        <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '14px' }}>
          <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <DollarSign size={14} color="#10b981" /> Tổng Doanh Thu
          </div>
          <div style={{ fontSize: '20px', fontWeight: 800, color: '#10b981', marginTop: '4px' }}>
            {formatVND(stats.totalRevenue)}
          </div>
        </div>

        {/* Metric 2 */}
        <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '14px' }}>
          <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Calendar size={14} color="#3b82f6" /> Hôm Nay / Tháng
          </div>
          <div style={{ fontSize: '13px', fontWeight: 700, color: '#1d4ed8', marginTop: '4px' }}>
            Hôm nay: {formatVND(stats.todayRevenue)}
          </div>
          <div style={{ fontSize: '12px', color: '#3b82f6', marginTop: '2px' }}>
            Tháng này: {formatVND(stats.monthRevenue)}
          </div>
        </div>

        {/* Metric 3 */}
        <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '14px' }}>
          <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Utensils size={14} color="#f59e0b" /> Số Lượng Món
          </div>
          <div style={{ fontSize: '20px', fontWeight: 800, color: '#d97706', marginTop: '4px' }}>
            {foodsList.length} Món
          </div>
        </div>

        {/* Metric 4 */}
        <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '14px' }}>
          <div style={{ fontSize: '11px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <ShoppingBag size={14} color="#8b5cf6" /> Tổng Đơn Hàng
          </div>
          <div style={{ fontSize: '20px', fontWeight: 800, color: '#7c3aed', marginTop: '4px' }}>
            {stats.totalOrders} Đơn
          </div>
        </div>
      </div>

      {/* Revenue & Orders Visual Chart Box */}
      <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
          <div style={{ fontSize: '13px', fontWeight: 700, color: '#0f172a', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <BarChart3 size={16} color="#fc6011" /> Biểu Đồ Doanh Thu 7 Ngày Gần Nhất
          </div>
          <span style={{ fontSize: '12px', color: '#64748b' }}>Đơn vị: VNĐ</span>
        </div>

        {/* SVG/CSS Clean Bar Chart */}
        <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', height: '140px', gap: '12px', padding: '10px 10px 0 10px', background: '#f8fafc', borderRadius: '8px' }}>
          {chartData.map((d: any, idx: number) => {
            const heightPercent = maxChartRev > 0 ? Math.max((d.revenue / maxChartRev) * 100, 8) : 8;
            return (
              <div key={idx} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', height: '100%', justifyContent: 'flex-end' }}>
                <div style={{ fontSize: '10px', fontWeight: 600, color: d.revenue > 0 ? '#10b981' : '#94a3b8', marginBottom: '4px' }}>
                  {d.revenue > 0 ? `${(d.revenue / 1000).toFixed(0)}k` : '0đ'}
                </div>
                <div
                  title={`${d.fullDate}: ${formatVND(d.revenue)} (${d.ordersCount} đơn)`}
                  style={{
                    width: '60%',
                    maxWidth: '36px',
                    height: `${heightPercent}%`,
                    background: d.revenue > 0 ? 'linear-gradient(180deg, #fc6011 0%, #f97316 100%)' : '#cbd5e1',
                    borderRadius: '4px 4px 0 0',
                    transition: 'all 0.3s ease',
                  }}
                />
                <div style={{ fontSize: '11px', color: '#475569', marginTop: '6px', fontWeight: 600 }}>
                  {d.date}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Main Tabs Container */}
      <div className="card-table" style={{ background: '#ffffff', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
        <div style={{ display: 'flex', gap: '12px', borderBottom: '1px solid #e2e8f0', padding: '0 16px', background: '#f8fafc' }}>
          <button
            onClick={() => setActiveTab('menu')}
            style={{
              padding: '12px 14px',
              fontWeight: 700,
              fontSize: '13px',
              border: 'none',
              background: 'transparent',
              borderBottom: activeTab === 'menu' ? '2.5px solid #fc6011' : '2.5px solid transparent',
              color: activeTab === 'menu' ? '#fc6011' : '#64748b',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <Utensils size={15} /> Thực Đơn Món Ăn ({foodsList.length})
          </button>

          <button
            onClick={() => setActiveTab('orders')}
            style={{
              padding: '12px 14px',
              fontWeight: 700,
              fontSize: '13px',
              border: 'none',
              background: 'transparent',
              borderBottom: activeTab === 'orders' ? '2.5px solid #fc6011' : '2.5px solid transparent',
              color: activeTab === 'orders' ? '#fc6011' : '#64748b',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <ShoppingBag size={15} /> Lịch Sử Đơn Hàng ({ordersList.length})
          </button>

          <button
            onClick={() => setActiveTab('owner')}
            style={{
              padding: '12px 14px',
              fontWeight: 700,
              fontSize: '13px',
              border: 'none',
              background: 'transparent',
              borderBottom: activeTab === 'owner' ? '2.5px solid #fc6011' : '2.5px solid transparent',
              color: activeTab === 'owner' ? '#fc6011' : '#64748b',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <Building size={15} /> Thông Tin Chủ Quán & Ngân Hàng
          </button>
        </div>

        <div style={{ padding: '16px' }}>
          {activeTab === 'menu' ? (
            foodsList.length === 0 ? (
              <div className="empty-state">Chưa có món ăn nào trong thực đơn</div>
            ) : (
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                    <th>Mã Món</th>
                    <th>Hình Ảnh</th>
                    <th>Tên Món Ăn</th>
                    <th>Giá Bán</th>
                    <th>Số Lượng Phục Vụ</th>
                    <th>Đánh Giá</th>
                    <th>Thao Tác</th>
                  </tr>
                </thead>
                <tbody>
                  {foodsList.map((f: any, idx: number) => (
                    <tr key={f.maMonAn}>
                      <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{idx + 1}</td>
                      <td style={{ fontWeight: 700 }}>#{f.maMonAn}</td>
                      <td>
                        <img
                          src={getImageUrl(f.img, DEFAULT_IMAGE_PLACEHOLDER)}
                          alt={f.tenMonAn}
                          onError={handleImageError}
                          style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover' }}
                        />
                      </td>
                      <td style={{ fontWeight: 700, color: '#0f172a' }}>{f.tenMonAn}</td>
                      <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(f.giaMonAn)}</td>
                      <td><span className="badge badge-info">{f.soLuongMon || 100} phần</span></td>
                      <td>⭐ {f.diemDanhGiaTB && Number(f.diemDanhGiaTB) > 0 ? Number(f.diemDanhGiaTB).toFixed(1) : 'Chưa có'}</td>
                      <td>
                        <button
                          className="btn btn-outline btn-sm"
                          onClick={() => handleOpenEditFood(f)}
                          style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', padding: '4px 10px' }}
                        >
                          <Edit2 size={13} /> Sửa
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )
          ) : activeTab === 'orders' ? (
            ordersList.length === 0 ? (
              <div className="empty-state">Chưa có đơn hàng nào phát sinh</div>
            ) : (
              <table className="data-table">
                <thead>
                  <tr>
                    <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                    <th>Mã Đơn</th>
                    <th>Khách Hàng</th>
                    <th>Tổng Tiền</th>
                    <th>Thời Gian Đặt</th>
                    <th>Trạng Thái</th>
                  </tr>
                </thead>
                <tbody>
                  {ordersList.map((ord: any, idx: number) => (
                    <tr key={ord.maDonHang}>
                      <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{idx + 1}</td>
                      <td style={{ fontWeight: 700 }}>#{ord.maDonHang}</td>
                      <td>{ord.tenKhachHang || `Khách #${ord.maKhachHang}`}</td>
                      <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(ord.tongTien)}</td>
                      <td>{new Date(ord.thoiGianDat).toLocaleString('vi-VN')}</td>
                      <td><StatusBadge status={ord.trangThai} /></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
              <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '10px', border: '1px solid #e2e8f0' }}>
                <h4 style={{ margin: '0 0 10px 0', color: '#0f172a', display: 'flex', alignItems: 'center', gap: '6px', fontSize: '14px' }}>
                  <User size={16} color="#fc6011" /> Thông Tin Chủ Sở Hữu
                </h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', fontSize: '13px', color: '#334155' }}>
                  <div>Họ tên: <strong>{store.hoTenChuQuan || 'Chưa cập nhật'}</strong></div>
                  <div>Số điện thoại: <strong>{store.sdt || 'Chưa cập nhật'}</strong></div>
                  <div>Số CCCD: <strong>{store.soCCCD || 'Chưa cập nhật'}</strong></div>
                  <div>Ngày sinh: <strong>{store.ngaySinhChuQuan ? formatDateVN(store.ngaySinhChuQuan) : 'Chưa cập nhật'}</strong></div>
                  <div>Địa chỉ thường trú: <strong>{store.diaChiThuongTru || 'Chưa cập nhật'}</strong></div>
                </div>
              </div>

              <div style={{ background: '#f8fafc', padding: '14px', borderRadius: '10px', border: '1px solid #e2e8f0' }}>
                <h4 style={{ margin: '0 0 10px 0', color: '#0f172a', display: 'flex', alignItems: 'center', gap: '6px', fontSize: '14px' }}>
                  <CreditCard size={16} color="#0284c7" /> Ngân Hàng Thanh Toán
                </h4>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', fontSize: '13px', color: '#334155' }}>
                  <div>Ngân hàng: <strong>{store.tenNganHang || 'Chưa cập nhật'}</strong></div>
                  <div>Số tài khoản: <strong>{store.soTaiKhoanNganHang || 'Chưa cập nhật'}</strong></div>
                  <div>Tên chủ tài khoản: <strong>{store.tenChuTaiKhoan || store.hoTenChuQuan || 'Chưa cập nhật'}</strong></div>
                  <div>Tài khoản quản lý: <strong>{store.taiKhoanLienKet ? `${store.taiKhoanLienKet.tenDangNhap} (#${store.taiKhoanLienKet.maTaiKhoan})` : 'Chưa gán'}</strong></div>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Edit Food Item Modal */}
      <Modal
        isOpen={editModalOpen}
        onClose={() => setEditModalOpen(false)}
        title={`Chỉnh Sửa Món Ăn #${editingFood?.maMonAn || ''}`}
      >
        <form onSubmit={handleSaveFood} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div className="form-group">
            <label className="form-label">Tên Món Ăn</label>
            <input
              type="text"
              className="form-control"
              required
              value={editForm.tenMonAn}
              onChange={(e) => setEditForm({ ...editForm, tenMonAn: e.target.value })}
              placeholder="Nhập tên món..."
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">Loại Món (Danh Mục)</label>
              <select
                className="form-control"
                value={editForm.maDanhMuc}
                onChange={(e) => setEditForm({ ...editForm, maDanhMuc: e.target.value })}
              >
                <option value="">-- Chọn danh mục --</option>
                {categories.map((c) => (
                  <option key={c.maDanhMuc} value={c.maDanhMuc}>
                    {c.tenDanhMuc}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Giá Bán (VND)</label>
              <input
                type="number"
                className="form-control"
                required
                min="0"
                step="1000"
                value={editForm.giaMonAn}
                onChange={(e) => setEditForm({ ...editForm, giaMonAn: e.target.value })}
              />
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Hình Ảnh Món Ăn</label>
            <ImageCropUpload
              initialImage={editForm.img}
              onImageCropped={(base64) => setEditForm({ ...editForm, img: base64 })}
              aspectRatio={4 / 3}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
            <button
              type="button"
              className="btn btn-outline"
              onClick={() => setEditModalOpen(false)}
            >
              Hủy
            </button>
            <button type="submit" className="btn btn-primary">
              Lưu Thay Đổi
            </button>
          </div>
        </form>
      </Modal>

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

