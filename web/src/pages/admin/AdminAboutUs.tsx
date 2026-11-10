import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { ImageCropUpload } from '../../components/ImageCropUpload';
import { NotificationModal } from '../../components/NotificationModal';
import {
  Info,
  Save,
  RotateCcw,
  LayoutTemplate,
  Smartphone,
  Eye,
  Plus,
  Trash2,
  CheckCircle2,
  Compass,
  Flame,
  Shield,
  Store,
  Phone,
  Mail,
  MapPin,
  Globe,
  Navigation,
  Clock,
  Leaf,
  Heart,
  Award,
  Utensils,
  Facebook,
  Instagram,
  Send,
} from 'lucide-react';

interface CoreValueItem {
  icon: string;
  title: string;
  desc: string;
}

const renderLibraryIcon = (iconName: string, size = 18, color = '#ea580c') => {
  switch (iconName?.toLowerCase()) {
    case 'navigation':
      return <Navigation size={size} color={color} />;
    case 'flame':
      return <Flame size={size} color={color} />;
    case 'shield':
      return <Shield size={size} color={color} />;
    case 'store':
      return <Store size={size} color={color} />;
    case 'leaf':
      return <Leaf size={size} color={color} />;
    case 'clock':
      return <Clock size={size} color={color} />;
    case 'heart':
      return <Heart size={size} color={color} />;
    case 'award':
      return <Award size={size} color={color} />;
    default:
      return <Utensils size={size} color={color} />;
  }
};

const BrandFacebookIcon = ({ size = 18 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path
      d="M14 13.5H16.5L17.5 9.5H14V7.5C14 6.47 14.32 5.76 15.77 5.76H17.5V2.18C16.92 2.1 15.86 2 14.62 2C11.83 2 9.92 3.7 9.92 6.82V9.5H6.52V13.5H9.92V22.5H14V13.5Z"
      fill="currentColor"
    />
  </svg>
);

const BrandInstagramIcon = ({ size = 18 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <rect x="2.5" y="2.5" width="19" height="19" rx="5.5" stroke="currentColor" strokeWidth="2" />
    <circle cx="12" cy="12" r="4.5" stroke="currentColor" strokeWidth="2" />
    <circle cx="17.5" cy="6.5" r="1.2" fill="currentColor" />
  </svg>
);

const BrandTelegramIcon = ({ size = 18 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path
      d="M21.5 2.8L2.2 10.6L7.2 12.8L17.5 6.5L9.5 14.2L9.0 19.2L12.5 16.0L17.5 19.8L21.5 2.8Z"
      fill="currentColor"
    />
    <path
      d="M7.2 12.8L12.5 16.0L9.0 19.2L7.2 12.8Z"
      fill="currentColor"
      opacity={0.72}
    />
  </svg>
);

const BrandGmailIcon = ({ size = 18 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
    <path d="M3 18V7.5L7 10.5V20H4.5C3.67 20 3 19.33 3 18.5V18Z" fill="#4285F4" />
    <path d="M21 18V7.5L17 10.5V20H19.5C20.33 20 21 19.33 21 18.5V18Z" fill="#34A853" />
    <path d="M3 6.5C3 5.67 3.67 5 4.5 5H7V10.5L3 7.5V6.5Z" fill="#C5221F" />
    <path d="M21 6.5C21 5.67 20.33 5 19.5 5H17V10.5L21 7.5V6.5Z" fill="#FBBC05" />
    <path d="M4.5 5L12 10.8L19.5 5H17L12 8.8L7 5H4.5Z" fill="#EA4335" />
  </svg>
);

export const AdminAboutUs: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [activeTab, setActiveTab] = useState<'hero' | 'mission' | 'values' | 'contact'>('hero');

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

  const [formData, setFormData] = useState({
    badge: 'ẨM THỰC TRÊN LỘ TRÌNH',
    tieude: 'Đặt Món Tiện Đường - Ghé Lấy Nóng Hổi',
    mota: 'Nền tảng tìm kiếm và đặt món thông minh dọc theo lộ trình di chuyển của bạn. Ghé lấy thức ăn tươi nóng mà không cần chờ đợi, trải nghiệm ẩm thực tiện lợi tối ưu thời gian.',
    sub_badge: 'Hơn 500+ quán ngon trên mọi cung đường',
    hinhanh: '',
    sumenh_tieude: 'SỨ MỆNH & TÂM NHÌN',
    sumenh_phude: 'Kiến tạo phong cách ẩm thực di chuyển thông minh',
    sumenh_noidung: 'Định vị thành giải pháp kết nối ẩm thực lộ trình hàng đầu, giúp tối ưu hóa thời gian di chuyển hàng ngày của người dùng bằng công nghệ gợi ý món ngon thông minh, đặt trước tiện lợi và thanh toán không tiền mặt an toàn.',
    stat1_val: '500K+',
    stat1_label: 'Lộ trình phục vụ',
    stat2_val: '4.9★',
    stat2_label: 'Đánh giá cao',
    stat3_val: '99%',
    stat3_label: 'Khách hài lòng',
    giatricotloi: [
      { icon: 'navigation', title: 'Tiện đường ghé lấy', desc: 'Đặt món trước, ghé lấy ngay trên lộ trình di chuyển mà không mất thời gian chờ đợi.' },
      { icon: 'flame', title: 'Nóng hổi chuẩn giờ', desc: 'Quán canh thời gian chuẩn bị để món ăn vừa hoàn thành đúng lúc bạn có mặt.' },
      { icon: 'shield', title: 'Thanh toán an toàn', desc: 'Tích hợp thanh toán tiện lợi qua VietQR, PayOS và MoMo với độ bảo mật tuyệt đối.' },
      { icon: 'store', title: 'Quán ngon chọn lọc', desc: 'Hệ thống nhà hàng, quán ăn dọc tuyến đường được tuyển chọn kỹ lưỡng về vệ sinh an toàn.' }
    ] as CoreValueItem[],
    hotline: '1900 6868',
    email: 'support@foodroute.vn',
    website: 'https://foodroute.vn',
    facebook: 'https://facebook.com/foodroute.official',
    instagram: 'https://instagram.com/foodroute.vn',
    telegram: 'https://t.me/foodroute_support',
    gmail: 'foodroute.official@gmail.com',
    diachi: 'Khu Công Nghệ Cao, TP. Thủ Đức, TP. Hồ Chí Minh',
    phienban: 'Phiên bản 1.0.0 • FoodRoute Official',
    banquyen: '© 2026 FoodRoute Inc. Giữ toàn bộ bản quyền hệ thống.',
  });

  const fetchAboutUs = async () => {
    try {
      setLoading(true);
      const res = await apiFetch<any>('/admin/about-us');
      if (res.data) {
        setFormData({
          ...res.data,
          giatricotloi: Array.isArray(res.data.giatricotloi) ? res.data.giatricotloi : formData.giatricotloi,
        });
      }
    } catch (err: any) {
      console.error('Error fetching about us:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAboutUs();
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSaving(true);
      await apiFetch('/admin/about-us', {
        method: 'PUT',
        body: JSON.stringify(formData),
      });
      setNotifyModal({
        isOpen: true,
        type: 'success',
        title: 'Cập Nhật Thành Công',
        message: 'Đã lưu thông tin "Về chúng tôi" và tự động phát tín hiệu cập nhật thời gian thực sang ứng dụng Mobile!',
      });
    } catch (err: any) {
      setNotifyModal({
        isOpen: true,
        type: 'error',
        title: 'Lỗi Lưu Dữ Liệu',
        message: err.message || 'Không thể lưu thông tin. Vui lòng thử lại.',
      });
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateCoreValue = (index: number, field: keyof CoreValueItem, value: string) => {
    const nextValues = [...formData.giatricotloi];
    nextValues[index] = { ...nextValues[index], [field]: value };
    setFormData({ ...formData, giatricotloi: nextValues });
  };

  const handleAddCoreValue = () => {
    if (formData.giatricotloi.length >= 6) return;
    setFormData({
      ...formData,
      giatricotloi: [
        ...formData.giatricotloi,
        { icon: 'store', title: 'Giá trị mới', desc: 'Mô tả giá trị cam kết mang lại cho khách hàng.' },
      ],
    });
  };

  const handleRemoveCoreValue = (index: number) => {
    if (formData.giatricotloi.length <= 1) return;
    setFormData({
      ...formData,
      giatricotloi: formData.giatricotloi.filter((_, i) => i !== index),
    });
  };

  if (loading) {
    return (
      <div style={{ padding: '32px', textAlign: 'center', color: '#64748b' }}>
        Đang tải thông tin hệ thống...
      </div>
    );
  }

  return (
    <div style={{ maxWidth: '1400px', margin: '0 auto', paddingBottom: '40px' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: '#fff7ed', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Info size={22} color="#ea580c" />
            </div>
            <div>
              <h1 style={{ fontSize: '24px', fontWeight: 800, color: '#0f172a', margin: 0 }}>
                Quản Lý Trang "Về Chúng Tôi" (About Us)
              </h1>
              <p style={{ fontSize: '13px', color: '#64748b', margin: 0 }}>
                Kiểm soát thông tin giới thiệu, sứ mệnh, số liệu & hình ảnh hiển thị trên ứng dụng FoodRoute Mobile
              </p>
            </div>
          </div>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            type="button"
            onClick={fetchAboutUs}
            disabled={saving}
            className="btn btn-outline"
            style={{ display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <RotateCcw size={16} />
            <span>Tải Lại</span>
          </button>
          <button
            type="button"
            onClick={handleSave}
            disabled={saving}
            className="btn btn-primary"
            style={{ display: 'flex', alignItems: 'center', gap: '6px', backgroundColor: '#ea580c', borderColor: '#ea580c' }}
          >
            <Save size={16} />
            <span>{saving ? 'Đang Lưu...' : 'Lưu Thay Đổi'}</span>
          </button>
        </div>
      </div>

      {/* Main Grid: Form Left (7 cols) + Preview Right (5 cols) */}
      <div style={{ display: 'grid', gridTemplateColumns: '7fr 5fr', gap: '24px', alignItems: 'start' }}>
        {/* Left Column: Edit Form with Tabs */}
        <div style={{ background: '#ffffff', borderRadius: '16px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.05)', overflow: 'hidden' }}>
          {/* Navigation Tabs */}
          <div style={{ display: 'flex', borderBottom: '1px solid #e2e8f0', background: '#f8fafc', padding: '6px 12px', gap: '6px' }}>
            {[
              { id: 'hero', label: '1. Banner & Giới thiệu', icon: LayoutTemplate },
              { id: 'mission', label: '2. Sứ mệnh & Số liệu', icon: Compass },
              { id: 'values', label: '3. Giá trị cốt lõi', icon: Shield },
              { id: 'contact', label: '4. Liên hệ & Bản quyền', icon: Phone },
            ].map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  type="button"
                  onClick={() => setActiveTab(tab.id as any)}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '8px 14px',
                    borderRadius: '8px',
                    border: 'none',
                    background: isActive ? '#ffffff' : 'transparent',
                    color: isActive ? '#ea580c' : '#64748b',
                    fontWeight: isActive ? 700 : 500,
                    fontSize: '13px',
                    cursor: 'pointer',
                    boxShadow: isActive ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
                    transition: 'all 0.15s',
                  }}
                >
                  <Icon size={15} />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </div>

          <form onSubmit={handleSave} style={{ padding: '24px' }}>
            {/* Tab 1: Hero Card & Image */}
            {activeTab === 'hero' && (
              <div>
                <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0f172a', marginBottom: '16px' }}>
                  Thông tin Thẻ Giới Thiệu Chính (Hero Banner)
                </h3>

                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label className="form-label">Huy hiệu trên cùng (Badge)</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.badge}
                    onChange={(e) => setFormData({ ...formData, badge: e.target.value })}
                    placeholder="VD: ẨM THỰC TRÊN LỘ TRÌNH"
                    required
                  />
                </div>

                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label className="form-label">Tiêu đề lớn</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.tieude}
                    onChange={(e) => setFormData({ ...formData, tieude: e.target.value })}
                    placeholder="VD: Đặt Món Tiện Đường - Ghé Lấy Nóng Hổi"
                    required
                  />
                </div>

                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label className="form-label">Mô tả ngắn</label>
                  <textarea
                    className="form-control"
                    rows={3}
                    value={formData.mota}
                    onChange={(e) => setFormData({ ...formData, mota: e.target.value })}
                    placeholder="Giới thiệu điểm nổi bật của dịch vụ..."
                    required
                  />
                </div>

                <div className="form-group" style={{ marginBottom: '20px' }}>
                  <label className="form-label">Huy hiệu phụ ở chân thẻ</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.sub_badge}
                    onChange={(e) => setFormData({ ...formData, sub_badge: e.target.value })}
                    placeholder="VD: Hơn 500+ quán ngon trên mọi cung đường"
                  />
                </div>

                <div style={{ borderTop: '1px solid #f1f5f9', paddingTop: '16px' }}>
                  <ImageCropUpload
                    label="Hình ảnh Nền / Minh họa Hero Banner (Tùy chọn)"
                    value={formData.hinhanh}
                    onChange={(url) => setFormData({ ...formData, hinhanh: url })}
                    aspectRatio={16 / 9}
                  />
                  <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>
                    * Nếu không tải ảnh lên, ứng dụng Mobile sẽ tự động sử dụng dải màu Gradient Cam thương hiệu FoodRoute cao cấp.
                  </div>
                </div>
              </div>
            )}

            {/* Tab 2: Mission & Stats */}
            {activeTab === 'mission' && (
              <div>
                <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0f172a', marginBottom: '16px' }}>
                  Sứ Mệnh & Tầm Nhìn
                </h3>

                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label className="form-label">Tiêu đề khối</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.sumenh_tieude}
                    onChange={(e) => setFormData({ ...formData, sumenh_tieude: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label className="form-label">Phụ đề truyền cảm hứng</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.sumenh_phude}
                    onChange={(e) => setFormData({ ...formData, sumenh_phude: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group" style={{ marginBottom: '24px' }}>
                  <label className="form-label">Nội dung sứ mệnh (Trích dẫn)</label>
                  <textarea
                    className="form-control"
                    rows={4}
                    value={formData.sumenh_noidung}
                    onChange={(e) => setFormData({ ...formData, sumenh_noidung: e.target.value })}
                    required
                  />
                </div>

                <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0f172a', marginBottom: '16px', borderTop: '1px solid #f1f5f9', paddingTop: '16px' }}>
                  3 Con Số Ấn Tượng (Thống Kê)
                </h3>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '12px' }}>
                  <div style={{ background: '#f8fafc', padding: '12px', borderRadius: '10px', border: '1px solid #e2e8f0' }}>
                    <label style={{ fontSize: '11px', fontWeight: 700, color: '#64748b' }}>SỐ 1 (GIÁ TRỊ)</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.stat1_val}
                      onChange={(e) => setFormData({ ...formData, stat1_val: e.target.value })}
                      style={{ fontWeight: 800, color: '#ea580c', marginBottom: '6px' }}
                    />
                    <label style={{ fontSize: '11px', fontWeight: 700, color: '#64748b' }}>NHÃN SỐ 1</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.stat1_label}
                      onChange={(e) => setFormData({ ...formData, stat1_label: e.target.value })}
                    />
                  </div>

                  <div style={{ background: '#f8fafc', padding: '12px', borderRadius: '10px', border: '1px solid #e2e8f0' }}>
                    <label style={{ fontSize: '11px', fontWeight: 700, color: '#64748b' }}>SỐ 2 (GIÁ TRỊ)</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.stat2_val}
                      onChange={(e) => setFormData({ ...formData, stat2_val: e.target.value })}
                      style={{ fontWeight: 800, color: '#ea580c', marginBottom: '6px' }}
                    />
                    <label style={{ fontSize: '11px', fontWeight: 700, color: '#64748b' }}>NHÃN SỐ 2</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.stat2_label}
                      onChange={(e) => setFormData({ ...formData, stat2_label: e.target.value })}
                    />
                  </div>

                  <div style={{ background: '#f8fafc', padding: '12px', borderRadius: '10px', border: '1px solid #e2e8f0' }}>
                    <label style={{ fontSize: '11px', fontWeight: 700, color: '#64748b' }}>SỐ 3 (GIÁ TRỊ)</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.stat3_val}
                      onChange={(e) => setFormData({ ...formData, stat3_val: e.target.value })}
                      style={{ fontWeight: 800, color: '#ea580c', marginBottom: '6px' }}
                    />
                    <label style={{ fontSize: '11px', fontWeight: 700, color: '#64748b' }}>NHÃN SỐ 3</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.stat3_label}
                      onChange={(e) => setFormData({ ...formData, stat3_label: e.target.value })}
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Tab 3: Core Values Grid */}
            {activeTab === 'values' && (
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                  <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0f172a', margin: 0 }}>
                    Cam Kết & Giá Trị Cốt Lõi ({formData.giatricotloi.length} mục)
                  </h3>
                  {formData.giatricotloi.length < 6 && (
                    <button
                      type="button"
                      onClick={handleAddCoreValue}
                      className="btn btn-outline"
                      style={{ fontSize: '12px', padding: '4px 10px', display: 'flex', alignItems: 'center', gap: '4px' }}
                    >
                      <Plus size={14} />
                      <span>Thêm Giá Trị</span>
                    </button>
                  )}
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  {formData.giatricotloi.map((val, idx) => (
                    <div
                      key={idx}
                      style={{
                        padding: '14px',
                        background: '#f8fafc',
                        border: '1px solid #e2e8f0',
                        borderRadius: '12px',
                        position: 'relative',
                      }}
                    >
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                        <span style={{ fontSize: '12px', fontWeight: 700, color: '#ea580c' }}>
                          Mục #{idx + 1}
                        </span>
                        {formData.giatricotloi.length > 1 && (
                          <button
                            type="button"
                            onClick={() => handleRemoveCoreValue(idx)}
                            style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', padding: '2px' }}
                            title="Xóa mục này"
                          >
                            <Trash2 size={16} />
                          </button>
                        )}
                      </div>

                      <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '10px', marginBottom: '8px' }}>
                        <div>
                          <label style={{ fontSize: '11px', color: '#64748b' }}>Biểu tượng (Lucide Icon)</label>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <div style={{ width: '38px', height: '38px', borderRadius: '8px', background: '#fff7ed', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '1px solid #fdba74', flexShrink: 0 }}>
                              {renderLibraryIcon(val.icon, 18)}
                            </div>
                            <select
                              className="form-control"
                              value={val.icon}
                              onChange={(e) => handleUpdateCoreValue(idx, 'icon', e.target.value)}
                              style={{ flex: 1 }}
                            >
                              <option value="navigation">Lộ trình (navigation)</option>
                              <option value="flame">Nóng hổi (flame)</option>
                              <option value="shield">Bảo mật (shield)</option>
                              <option value="store">Quán ngon (store)</option>
                              <option value="leaf">Tươi sạch (leaf)</option>
                              <option value="clock">Nhanh chóng (clock)</option>
                              <option value="heart">Tận tâm (heart)</option>
                              <option value="award">Chất lượng (award)</option>
                            </select>
                          </div>
                        </div>
                        <div>
                          <label style={{ fontSize: '11px', color: '#64748b' }}>Tiêu đề</label>
                          <input
                            type="text"
                            className="form-control"
                            value={val.title}
                            onChange={(e) => handleUpdateCoreValue(idx, 'title', e.target.value)}
                            required
                          />
                        </div>
                      </div>

                      <div>
                        <label style={{ fontSize: '11px', color: '#64748b' }}>Mô tả chi tiết</label>
                        <textarea
                          className="form-control"
                          rows={2}
                          value={val.desc}
                          onChange={(e) => handleUpdateCoreValue(idx, 'desc', e.target.value)}
                          required
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Tab 4: Contact & Footer */}
            {activeTab === 'contact' && (
              <div>
                <h3 style={{ fontSize: '15px', fontWeight: 700, color: '#0f172a', marginBottom: '16px' }}>
                  Thông Tin Liên Hệ & Chân Trang
                </h3>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Hotline hỗ trợ</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.hotline}
                      onChange={(e) => setFormData({ ...formData, hotline: e.target.value })}
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Email liên hệ</label>
                    <input
                      type="email"
                      className="form-control"
                      value={formData.email}
                      onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    />
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '16px' }}>
                  <div className="form-group">
                    <label className="form-label">Website</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.website}
                      onChange={(e) => setFormData({ ...formData, website: e.target.value })}
                    />
                  </div>
                  <div className="form-group">
                    <label className="form-label">Địa chỉ trụ sở</label>
                    <input
                      type="text"
                      className="form-control"
                      value={formData.diachi}
                      onChange={(e) => setFormData({ ...formData, diachi: e.target.value })}
                    />
                  </div>
                </div>

                {/* Social Media Links Section */}
                <div style={{ borderTop: '1px solid #f1f5f9', paddingTop: '16px', marginBottom: '18px' }}>
                  <h4 style={{ fontSize: '13px', fontWeight: 800, color: '#0f172a', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <span>Mạng Xã Hội & Kênh Liên Hệ (Icon & Đường Dẫn)</span>
                  </h4>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '14px' }}>
                    <div className="form-group">
                      <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <div style={{ width: '20px', height: '20px', borderRadius: '4px', background: '#1877F2', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
                          <BrandFacebookIcon size={13} />
                        </div>
                        <span>Facebook (Link Trang/Cộng Đồng)</span>
                      </label>
                      <input
                        type="text"
                        className="form-control"
                        placeholder="https://facebook.com/..."
                        value={formData.facebook || ''}
                        onChange={(e) => setFormData({ ...formData, facebook: e.target.value })}
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <div style={{ width: '20px', height: '20px', borderRadius: '4px', background: 'linear-gradient(45deg, #f09433, #e6683c, #dc2743, #cc2366, #bc1888)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
                          <BrandInstagramIcon size={13} />
                        </div>
                        <span>Instagram (Link Profile)</span>
                      </label>
                      <input
                        type="text"
                        className="form-control"
                        placeholder="https://instagram.com/..."
                        value={formData.instagram || ''}
                        onChange={(e) => setFormData({ ...formData, instagram: e.target.value })}
                      />
                    </div>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
                    <div className="form-group">
                      <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <div style={{ width: '20px', height: '20px', borderRadius: '4px', background: '#24A1DE', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
                          <BrandTelegramIcon size={12} />
                        </div>
                        <span>Telegram (Link Kênh/Nhóm hỗ trợ)</span>
                      </label>
                      <input
                        type="text"
                        className="form-control"
                        placeholder="https://t.me/..."
                        value={formData.telegram || ''}
                        onChange={(e) => setFormData({ ...formData, telegram: e.target.value })}
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <div style={{ width: '20px', height: '20px', borderRadius: '4px', background: '#ffffff', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <BrandGmailIcon size={13} />
                        </div>
                        <span>Gmail Hỗ Trợ Trực Tiếp</span>
                      </label>
                      <input
                        type="email"
                        className="form-control"
                        placeholder="your-email@gmail.com"
                        value={formData.gmail || ''}
                        onChange={(e) => setFormData({ ...formData, gmail: e.target.value })}
                      />
                    </div>
                  </div>
                </div>

                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label className="form-label">Thông tin phiên bản</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.phienban}
                    onChange={(e) => setFormData({ ...formData, phienban: e.target.value })}
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Bản quyền sở hữu trí tuệ</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.banquyen}
                    onChange={(e) => setFormData({ ...formData, banquyen: e.target.value })}
                  />
                </div>
              </div>
            )}

            <div style={{ marginTop: '24px', paddingTop: '16px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button
                type="submit"
                disabled={saving}
                className="btn btn-primary"
                style={{ display: 'flex', alignItems: 'center', gap: '6px', backgroundColor: '#ea580c', borderColor: '#ea580c' }}
              >
                <Save size={16} />
                <span>{saving ? 'Đang Lưu Dữ Liệu...' : 'Lưu Thay Đổi Thông Tin'}</span>
              </button>
            </div>
          </form>
        </div>

        {/* Right Column: Live Mobile Mockup Preview */}
        <div style={{ position: 'sticky', top: '20px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '12px' }}>
            <Smartphone size={18} color="#ea580c" />
            <span style={{ fontSize: '14px', fontWeight: 700, color: '#0f172a' }}>Xem Trước Trực Quan Trên Mobile (Live Preview)</span>
          </div>

          {/* Smartphone Frame */}
          <div
            style={{
              width: '100%',
              maxWidth: '380px',
              margin: '0 auto',
              background: '#f8fafc',
              borderRadius: '36px',
              border: '10px solid #1e293b',
              boxShadow: '0 20px 40px rgba(0,0,0,0.15)',
              overflow: 'hidden',
              height: '720px',
              display: 'flex',
              flexDirection: 'column',
            }}
          >
            {/* Status bar */}
            <div style={{ height: '24px', background: '#ffffff', display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '0 16px', fontSize: '11px', fontWeight: 600, color: '#334155' }}>
              <span>9:41</span>
              <span>5G 100%</span>
            </div>

            {/* App Header */}
            <div style={{ height: '44px', background: '#ffffff', display: 'flex', alignItems: 'center', justifyContent: 'center', borderBottom: '1px solid #f1f5f9', fontWeight: 700, fontSize: '15px', color: '#0f172a' }}>
              Về chúng tôi
            </div>

            {/* Scrollable Mobile Content */}
            <div style={{ flex: 1, overflowY: 'auto', padding: '14px' }}>
              {/* Hero Card */}
              <div
                style={{
                  background: formData.hinhanh
                    ? `linear-gradient(rgba(0,0,0,0.5), rgba(0,0,0,0.8)), url(${formData.hinhanh}) center/cover`
                    : 'linear-gradient(135deg, #FF5722 0%, #FF8A65 100%)',
                  borderRadius: '20px',
                  padding: '16px',
                  color: '#ffffff',
                  boxShadow: '0 8px 16px rgba(255,87,34,0.25)',
                  marginBottom: '14px',
                }}
              >
                <div style={{ display: 'inline-block', padding: '4px 10px', background: 'rgba(255,255,255,0.25)', borderRadius: '14px', fontSize: '10px', fontWeight: 700, letterSpacing: '0.5px', marginBottom: '10px' }}>
                  {formData.badge}
                </div>
                <div style={{ fontSize: '17px', fontWeight: 800, lineHeight: 1.3, marginBottom: '8px' }}>
                  {formData.tieude}
                </div>
                <div style={{ fontSize: '11px', opacity: 0.95, lineHeight: 1.4, marginBottom: '12px' }}>
                  {formData.mota}
                </div>
                <div style={{ fontSize: '11px', fontWeight: 600, opacity: 0.9, display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <span>✓</span>
                  <span>{formData.sub_badge}</span>
                </div>
              </div>

              {/* Stats Row */}
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '8px', marginBottom: '16px' }}>
                <div style={{ background: '#ffffff', padding: '10px 4px', borderRadius: '12px', textAlign: 'center', border: '1px solid #f1f5f9' }}>
                  <div style={{ fontSize: '15px', fontWeight: 800, color: '#ea580c' }}>{formData.stat1_val}</div>
                  <div style={{ fontSize: '10px', color: '#64748b' }}>{formData.stat1_label}</div>
                </div>
                <div style={{ background: '#ffffff', padding: '10px 4px', borderRadius: '12px', textAlign: 'center', border: '1px solid #f1f5f9' }}>
                  <div style={{ fontSize: '15px', fontWeight: 800, color: '#ea580c' }}>{formData.stat2_val}</div>
                  <div style={{ fontSize: '10px', color: '#64748b' }}>{formData.stat2_label}</div>
                </div>
                <div style={{ background: '#ffffff', padding: '10px 4px', borderRadius: '12px', textAlign: 'center', border: '1px solid #f1f5f9' }}>
                  <div style={{ fontSize: '15px', fontWeight: 800, color: '#ea580c' }}>{formData.stat3_val}</div>
                  <div style={{ fontSize: '10px', color: '#64748b' }}>{formData.stat3_label}</div>
                </div>
              </div>

              {/* Mission Card */}
              <div style={{ background: '#ffffff', borderRadius: '16px', padding: '14px', border: '1px solid #f1f5f9', marginBottom: '16px' }}>
                <div style={{ fontSize: '11px', fontWeight: 800, color: '#ea580c', letterSpacing: '0.5px' }}>
                  {formData.sumenh_tieude}
                </div>
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#0f172a', marginBottom: '8px' }}>
                  {formData.sumenh_phude}
                </div>
                <div style={{ fontStyle: 'italic', fontSize: '11px', color: '#475569', lineHeight: 1.45, background: '#f8fafc', padding: '10px', borderRadius: '10px' }}>
                  "{formData.sumenh_noidung}"
                </div>
              </div>

              {/* Core values */}
              <div style={{ fontSize: '13px', fontWeight: 700, color: '#0f172a', marginBottom: '8px' }}>
                Giá trị cốt lõi
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', marginBottom: '16px' }}>
                {formData.giatricotloi.slice(0, 4).map((v, i) => (
                  <div key={i} style={{ background: '#ffffff', padding: '10px', borderRadius: '12px', border: '1px solid #f1f5f9' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px' }}>
                      <div style={{ width: '22px', height: '22px', borderRadius: '6px', background: '#fff7ed', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        {renderLibraryIcon(v.icon, 12)}
                      </div>
                      <div style={{ fontSize: '11px', fontWeight: 700, color: '#0f172a' }}>{v.title}</div>
                    </div>
                    <div style={{ fontSize: '9px', color: '#64748b', lineHeight: 1.3 }}>{v.desc}</div>
                  </div>
                ))}
              </div>

              {/* Contact */}
              <div style={{ background: '#ffffff', borderRadius: '14px', padding: '12px', border: '1px solid #f1f5f9', fontSize: '11px', color: '#475569', marginBottom: '16px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px' }}>
                  <Phone size={12} color="#ea580c" />
                  <span>{formData.hotline}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '4px' }}>
                  <Mail size={12} color="#ea580c" />
                  <span>{formData.email}</span>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '10px' }}>
                  <MapPin size={12} color="#ea580c" />
                  <span>{formData.diachi}</span>
                </div>

                {/* Social media buttons row in mockup */}
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', paddingTop: '8px', borderTop: '1px solid #f1f5f9' }}>
                  <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: '#1877F2', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', boxShadow: '0 2px 4px rgba(24,119,242,0.3)' }} title={formData.facebook || 'Facebook'}>
                    <BrandFacebookIcon size={15} />
                  </div>
                  <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: 'linear-gradient(45deg, #f09433, #e6683c, #dc2743, #cc2366, #bc1888)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', boxShadow: '0 2px 4px rgba(220,39,67,0.3)' }} title={formData.instagram || 'Instagram'}>
                    <BrandInstagramIcon size={15} />
                  </div>
                  <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: '#24A1DE', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff', boxShadow: '0 2px 4px rgba(36,161,222,0.3)' }} title={formData.telegram || 'Telegram'}>
                    <BrandTelegramIcon size={14} />
                  </div>
                  <div style={{ width: '28px', height: '28px', borderRadius: '50%', background: '#ffffff', border: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: '0 2px 4px rgba(0,0,0,0.06)' }} title={formData.gmail || 'Gmail'}>
                    <BrandGmailIcon size={15} />
                  </div>
                </div>
              </div>

              {/* Footer */}
              <div style={{ textAlign: 'center', fontSize: '10px', color: '#94a3b8', paddingBottom: '16px' }}>
                <div>{formData.phienban}</div>
                <div>{formData.banquyen}</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <NotificationModal
        isOpen={notifyModal.isOpen}
        type={notifyModal.type}
        title={notifyModal.title}
        message={notifyModal.message}
        onClose={() => setNotifyModal({ ...notifyModal, isOpen: false })}
      />
    </div>
  );
};
