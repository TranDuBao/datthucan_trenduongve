import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Store, Save, Building, Bot, CheckCircle, Clock, MapPin, Settings2, ShieldCheck, CheckSquare, Square } from 'lucide-react';
import { ImageCropUpload } from '../../components/ImageCropUpload';
import { LocationSelector } from '../../components/LocationSelector';
import { NotificationModal } from '../../components/NotificationModal';
import { BankSelector } from '../../components/BankSelector';
import { DatePickerInput } from '../../components/DatePickerInput';
import { parseCCCDImage, formatDateVN, toISODate } from '../../utils/ocrService';
import { fetchVietQRBanks, BankItem } from '../../utils/bankService';

const AMENITIES_LIST = [
  'Take-away',
  'Có chỗ ngồi',
  'Wi-Fi',
  'Điều hòa',
  'Thanh toán không tiền mặt',
  'Có chỗ đậu xe',
];

const DAYS_OF_WEEK = [
  { key: 'mon', label: 'Thứ 2' },
  { key: 'tue', label: 'Thứ 3' },
  { key: 'wed', label: 'Thứ 4' },
  { key: 'thu', label: 'Thứ 5' },
  { key: 'fri', label: 'Thứ 6' },
  { key: 'sat', label: 'Thứ 7' },
  { key: 'sun', label: 'Chủ nhật' },
];

const DEFAULT_HOURS = {
  mon: { open: true, from: '07:00', to: '22:00' },
  tue: { open: true, from: '07:00', to: '22:00' },
  wed: { open: true, from: '07:00', to: '22:00' },
  thu: { open: true, from: '07:00', to: '22:00' },
  fri: { open: true, from: '07:00', to: '22:00' },
  sat: { open: true, from: '07:00', to: '23:00' },
  sun: { open: true, from: '07:00', to: '23:00' },
};

export const RestaurantProfile: React.FC = () => {
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [ocrNotice, setOcrNotice] = useState<string | null>(null);
  const [scanningCCCD, setScanningCCCD] = useState(false);
  const [banks, setBanks] = useState<BankItem[]>([]);

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

  const [form, setForm] = useState({
    tenQuan: '',
    diaChi: '',
    sdt: '',
    email: '',
    moTa: '',
    danhMuc: 'Đồ ăn',
    img: '',
    trangThai: 'mở cửa',
    lat: 10.776889,
    lng: 106.700806,
    thoiGianChuanBi: 20,
    coChoDatTruoc: true,
    tienIch: ['Take-away', 'Wi-Fi', 'Điều hòa', 'Thanh toán không tiền mặt'] as string[],
    gioHoatDong: DEFAULT_HOURS as Record<string, { open: boolean; from: string; to: string }>,
    hoTenChuQuan: '',
    diaChiThuongTru: '',
    ngaySinhChuQuan: '',
    soCCCD: '',
    tenNganHang: 'Vietcombank (VCB)',
    soTaiKhoanNganHang: '',
    tenChuTaiKhoan: '',
    cccdMatTruoc: '',
    cccdMatSau: '',
  });

  useEffect(() => {
    fetchVietQRBanks().then((data) => setBanks(data));

    apiFetch<any>('/restaurant/profile')
      .then((res) => {
        const p = res.data;
        setProfile(p);

        let parsedHours = DEFAULT_HOURS;
        if (p.gioHoatDong) {
          try {
            parsedHours = typeof p.gioHoatDong === 'string' ? JSON.parse(p.gioHoatDong) : p.gioHoatDong;
          } catch (_) { }
        }

        let parsedAmenities = ['Take-away', 'Wi-Fi', 'Điều hòa', 'Thanh toán không tiền mặt'];
        if (p.tienIch) {
          try {
            parsedAmenities = typeof p.tienIch === 'string' ? JSON.parse(p.tienIch) : p.tienIch;
          } catch (_) { }
        }

        setForm({
          tenQuan: p.tenQuan || '',
          diaChi: p.diaChi || '',
          sdt: p.sdt || '',
          email: p.email || '',
          moTa: p.moTa || '',
          danhMuc: p.danhMuc || 'Đồ ăn',
          img: p.img || '',
          trangThai: p.trangThai || 'mở cửa',
          lat: p.lat ?? 10.776889,
          lng: p.lng ?? 106.700806,
          thoiGianChuanBi: p.thoiGianChuanBi ?? 20,
          coChoDatTruoc: p.coChoDatTruoc ?? true,
          tienIch: parsedAmenities,
          gioHoatDong: parsedHours,
          hoTenChuQuan: p.hoTenChuQuan || '',
          diaChiThuongTru: p.diaChiThuongTru || '',
          ngaySinhChuQuan: p.ngaySinhChuQuan ? formatDateVN(String(p.ngaySinhChuQuan)) : '',
          soCCCD: p.soCCCD || '',
          tenNganHang: p.tenNganHang,
          soTaiKhoanNganHang: p.soTaiKhoanNganHang || '',
          tenChuTaiKhoan: p.tenChuTaiKhoan || '',
          cccdMatTruoc: p.cccdMatTruoc || '',
          cccdMatSau: p.cccdMatSau || '',
        });
      })
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  }, []);

  const handleScanCCCD = async () => {
    const fImg = form.cccdMatTruoc;
    const bImg = form.cccdMatSau;

    if (!fImg && !bImg) {
      showNotify('warning', 'Chưa Chọn Ảnh CCCD', 'Vui lòng upload ảnh CCCD (Mặt trước hoặc Mặt sau) trước khi thực hiện AI Quét!');
      return;
    }

    setScanningCCCD(true);
    setOcrNotice(null);
    try {
      let ocrData: any = null;

      const endpoints = ['/restaurant/scan-cccd', '/auth/scan-cccd', '/admin/scan-cccd'];
      for (const ep of endpoints) {
        try {
          const res = await apiFetch<any>(ep, {
            method: 'POST',
            body: JSON.stringify({ image: fImg || bImg, frontImage: fImg, backImage: bImg, side: 'both' }),
          });
          const fetchedData = res?.data || res?.payload || res;
          if (fetchedData && (fetchedData.soCCCD || fetchedData.hoTen || fetchedData.success)) {
            ocrData = fetchedData;
            break;
          }
        } catch (_) { }
      }

      if (!ocrData || (!ocrData.soCCCD && !ocrData.hoTen)) {
        ocrData = await parseCCCDImage(fImg, bImg);
      }

      if (ocrData && (ocrData.success || ocrData.soCCCD || ocrData.hoTen)) {
        setForm((prev) => ({
          ...prev,
          soCCCD: ocrData.soCCCD || prev.soCCCD,
          hoTenChuQuan: ocrData.hoTen || ocrData.hoTenChuQuan || prev.hoTenChuQuan,
          ngaySinhChuQuan: ocrData.ngaySinh ? formatDateVN(ocrData.ngaySinh) : prev.ngaySinhChuQuan,
          diaChiThuongTru: ocrData.diaChiThuongTru || prev.diaChiThuongTru || prev.diaChi,
        }));
        const foundStr = [
          ocrData.soCCCD ? `Số CCCD: ${ocrData.soCCCD}` : '',
          ocrData.hoTen || ocrData.hoTenChuQuan ? `Họ tên: ${ocrData.hoTen || ocrData.hoTenChuQuan}` : '',
        ].filter(Boolean).join(' • ');
        setOcrNotice(`AI OCR đã trích xuất thành công! ${foundStr}`);
        showNotify('success', 'AI Quét Thành Công', 'Đã tự động trích xuất dữ liệu từ ảnh CCCD thành công.');
      } else {
        showNotify('warning', 'Không Thể Đọc Ảnh CCCD', 'AI không trích xuất được chữ từ ảnh này. Vui lòng tải ảnh CCCD chụp thẳng, rõ nét hơn.');
      }
    } catch (err: any) {
      showNotify('error', 'Quét AI Thất Bại', err.message || 'Không thể trích xuất dữ liệu CCCD từ hình ảnh.');
    } finally {
      setScanningCCCD(false);
    }
  };

  const toggleAmenity = (item: string) => {
    setForm((prev) => {
      const exists = prev.tienIch.includes(item);
      return {
        ...prev,
        tienIch: exists ? prev.tienIch.filter((i) => i !== item) : [...prev.tienIch, item],
      };
    });
  };

  const updateDaySchedule = (dayKey: string, field: 'open' | 'from' | 'to', value: any) => {
    setForm((prev) => ({
      ...prev,
      gioHoatDong: {
        ...prev.gioHoatDong,
        [dayKey]: {
          ...prev.gioHoatDong[dayKey],
          [field]: value,
        },
      },
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const missingFields: string[] = [];
    if (!form.tenQuan.trim()) missingFields.push('Tên Nhà Hàng / Quán');
    if (!form.diaChi.trim()) missingFields.push('Địa Chỉ Nhà Hàng');
    if (!form.sdt.trim()) missingFields.push('Số Điện Thoại Liên Hệ');

    if (missingFields.length > 0) {
      showNotify('warning', 'Thiếu Thông Tin Bắt Buộc', missingFields);
      return;
    }

    setSaving(true);
    try {
      const payload = {
        ...form,
        gioHoatDong: JSON.stringify(form.gioHoatDong),
        tienIch: JSON.stringify(form.tienIch),
        ngaySinhChuQuan: toISODate(form.ngaySinhChuQuan),
      };
      await apiFetch('/restaurant/profile', {
        method: 'PUT',
        body: JSON.stringify(payload),
      });
      showNotify('success', 'Lưu Thông Tin Thành Công', 'Hồ sơ nhà hàng đã được lưu và cập nhật vào Database thành công!');
    } catch (err: any) {
      showNotify('error', 'Lưu Thất Bại', err.message || 'Lỗi khi cập nhật thông tin nhà hàng.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div style={{ textAlign: 'center', padding: '60px' }}><div className="loading-spinner" /></div>;
  }

  return (
    <div>
      <NotificationModal
        isOpen={notifyModal.isOpen}
        type={notifyModal.type}
        title={notifyModal.title}
        message={notifyModal.message}
        onClose={() => setNotifyModal((prev) => ({ ...prev, isOpen: false }))}
      />

      <div className="page-header">
        <div>
          <h1 className="page-title">Hồ Sơ Nhà Hàng & Cửa Hàng</h1>
          <p className="page-subtitle">Quản lý thông tin cơ bản, vị trí bản đồ, giờ hoạt động, nhận đơn & tiện ích</p>
        </div>
      </div>

      <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '14px', padding: '28px', maxWidth: '840px', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
        {ocrNotice && (
          <div style={{ background: '#f0fdf4', border: '1px solid #86efac', borderRadius: '8px', padding: '10px 14px', color: '#166534', fontSize: '13px', marginBottom: '20px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <CheckCircle size={16} color="#16a34a" /> {ocrNotice}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          {/* SECTION 1: THÔNG TIN CƠ BẢN */}
          <div style={{ fontSize: '15px', fontWeight: 700, color: '#fc6011', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Store size={18} /> 1. Thông Tin Cơ Bản Quán
          </div>

          <div className="form-group">
            <label className="form-label">Tên Nhà Hàng / Quán *</label>
            <input type="text" className="form-control" value={form.tenQuan} onChange={(e) => setForm({ ...form, tenQuan: e.target.value })} required />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">Số Điện Thoại Liên Hệ *</label>
              <input type="text" className="form-control" value={form.sdt} onChange={(e) => setForm({ ...form, sdt: e.target.value })} required />
            </div>

            <div className="form-group">
              <label className="form-label">Email Liên Hệ</label>
              <input type="email" className="form-control" placeholder="example@gmail.com" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} />
            </div>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">Danh Mục / Loại Hình Quán</label>
              <select className="form-control" value={form.danhMuc} onChange={(e) => setForm({ ...form, danhMuc: e.target.value })}>
                <option value="Đồ ăn">Đồ ăn chính (Cơm, Bún, Phở)</option>
                <option value="Thức uống">Thức uống & Cà phê</option>
                <option value="Ăn vặt">Ăn vặt & Tráng miệng</option>
                <option value="Bánh mì & Fastfood">Bánh mì & Fastfood</option>
                <option value="Lẩu & Nướng">Lẩu & Nướng</option>
              </select>
            </div>

            <div className="form-group">
              <label className="form-label">Trạng Thái Hoạt Động</label>
              <select className="form-control" value={form.trangThai} onChange={(e) => setForm({ ...form, trangThai: e.target.value })}>
                <option value="mở cửa">Đang mở cửa (Nhận đơn)</option>
                <option value="tạm ngưng">Tạm ngưng nhận đơn</option>
                <option value="đóng cửa">Đang đóng cửa</option>
              </select>
            </div>
          </div>

          <div className="form-group">
            <label className="form-label">Mô Tả Giới Thiệu Quán</label>
            <textarea className="form-control" rows={3} placeholder="Mô tả các món ăn đặc trưng, không gian quán..." value={form.moTa} onChange={(e) => setForm({ ...form, moTa: e.target.value })} />
          </div>

          {/* SECTION 2: HÌNH ẢNH QUÁN */}
          <div style={{ marginTop: '20px', marginBottom: '20px' }}>
            <ImageCropUpload
              label="Logo / Ảnh Đại Diện & Banner Quán (Cắt Ảnh 16:9)"
              value={form.img}
              onChange={(url) => setForm({ ...form, img: url })}
              aspectRatio={1.77}
            />
          </div>

          {/* SECTION 3: ĐỊA CHỈ & VỊ TRÍ BẢN ĐỒ */}
          <div style={{ background: '#f8fafc', padding: '18px', borderRadius: '12px', border: '1px solid #e2e8f0', marginBottom: '20px' }}>
            <div style={{ fontSize: '15px', fontWeight: 700, color: '#0284c7', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <MapPin size={18} /> 3. Địa Chỉ & Vị Trí Tọa Độ Bản Đồ
            </div>

            <LocationSelector
              label="Địa Chỉ Phân Cấp (Tỉnh/Thành - Quận/Huyện - Phường/Xã)"
              value={form.diaChi}
              onChange={(val) => setForm({ ...form, diaChi: val })}
              required
            />

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginTop: '10px' }}>
              <div className="form-group">
                <label className="form-label">Vĩ Độ (Latitude)</label>
                <input type="number" step="any" className="form-control" value={form.lat} onChange={(e) => setForm({ ...form, lat: parseFloat(e.target.value) || 0 })} />
              </div>
              <div className="form-group">
                <label className="form-label">Kinh Độ (Longitude)</label>
                <input type="number" step="any" className="form-control" value={form.lng} onChange={(e) => setForm({ ...form, lng: parseFloat(e.target.value) || 0 })} />
              </div>
            </div>
          </div>

          {/* SECTION 4: GIỜ HOẠT ĐỘNG */}
          <div style={{ background: '#ffffff', padding: '18px', borderRadius: '12px', border: '1px solid #e2e8f0', marginBottom: '20px' }}>
            <div style={{ fontSize: '15px', fontWeight: 700, color: '#16a34a', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Clock size={18} /> 4. Giờ Hoạt Động Theo Từng Ngày Trong Tuần
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
              {DAYS_OF_WEEK.map((d) => {
                const sched = form.gioHoatDong[d.key] || { open: true, from: '07:00', to: '22:00' };
                return (
                  <div key={d.key} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 12px', background: '#f9fafb', borderRadius: '8px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px', width: '120px' }}>
                      <input
                        type="checkbox"
                        checked={sched.open}
                        onChange={(e) => updateDaySchedule(d.key, 'open', e.target.checked)}
                        style={{ width: '16px', height: '16px', accentColor: '#16a34a' }}
                      />
                      <span style={{ fontWeight: 600, fontSize: '13px', color: sched.open ? '#1e293b' : '#94a3b8' }}>{d.label}</span>
                    </div>

                    {sched.open ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <input
                          type="time"
                          className="form-control"
                          style={{ width: '110px', padding: '4px 8px', fontSize: '13px' }}
                          value={sched.from}
                          onChange={(e) => updateDaySchedule(d.key, 'from', e.target.value)}
                        />
                        <span style={{ fontSize: '12px', color: '#64748b' }}>đến</span>
                        <input
                          type="time"
                          className="form-control"
                          style={{ width: '110px', padding: '4px 8px', fontSize: '13px' }}
                          value={sched.to}
                          onChange={(e) => updateDaySchedule(d.key, 'to', e.target.value)}
                        />
                      </div>
                    ) : (
                      <span style={{ fontSize: '12px', color: '#ef4444', fontWeight: 600 }}>Nghỉ cả ngày</span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* SECTION 5: CÀI ĐẶT NHẬN ĐƠN & THỜI GIAN CHUẨN BỊ */}
          <div style={{ background: '#fdf4ff', padding: '18px', borderRadius: '12px', border: '1px solid #f5d0fe', marginBottom: '20px' }}>
            <div style={{ fontSize: '15px', fontWeight: 700, color: '#c026d3', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Settings2 size={18} /> 5. Cài Đặt Nhận Đơn & Thời Gian Chẩn Bị
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div className="form-group">
                <label className="form-label">Thời Gian Chuẩn Bị Mặc Định (Phút)</label>
                <input
                  type="number"
                  min="5"
                  max="120"
                  className="form-control"
                  value={form.thoiGianChuanBi}
                  onChange={(e) => setForm({ ...form, thoiGianChuanBi: parseInt(e.target.value) || 20 })}
                />
              </div>

              <div className="form-group" style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                <label className="form-label">Đặt Trước / Hẹn Giờ Lấy Món</label>
                <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer', marginTop: '6px' }}>
                  <input
                    type="checkbox"
                    checked={form.coChoDatTruoc}
                    onChange={(e) => setForm({ ...form, coChoDatTruoc: e.target.checked })}
                    style={{ width: '18px', height: '18px', accentColor: '#c026d3' }}
                  />
                  <span style={{ fontSize: '13px', fontWeight: 600, color: '#334155' }}>Cho phép khách hẹn giờ tự đến lấy</span>
                </label>
              </div>
            </div>
          </div>

          {/* SECTION 6: TIỆN ÍCH CỦA QUÁN */}
          <div style={{ background: '#f0fdf4', padding: '18px', borderRadius: '12px', border: '1px solid #bbf7d0', marginBottom: '20px' }}>
            <div style={{ fontSize: '15px', fontWeight: 700, color: '#15803d', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <ShieldCheck size={18} /> 6. Tiện Ích Hiển Thị Cho Khách Hàng
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
              {AMENITIES_LIST.map((item) => {
                const checked = form.tienIch.includes(item);
                return (
                  <div
                    key={item}
                    onClick={() => toggleAmenity(item)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      padding: '10px 12px',
                      background: checked ? '#dcfce7' : '#ffffff',
                      border: `1px solid ${checked ? '#86efac' : '#cbd5e1'}`,
                      borderRadius: '8px',
                      cursor: 'pointer',
                      userSelect: 'none',
                    }}
                  >
                    {checked ? <CheckSquare size={16} color="#15803d" /> : <Square size={16} color="#94a3b8" />}
                    <span style={{ fontSize: '13px', fontWeight: checked ? 700 : 500, color: checked ? '#14532d' : '#475569' }}>{item}</span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* SECTION 7: THÔNG TIN CHỦ QUÁN & XÁC THỰC CCCD */}
          <div style={{ background: '#f8fafc', padding: '18px', borderRadius: '12px', border: '1px solid #e2e8f0', marginTop: '24px', marginBottom: '20px' }}>
            <div style={{ fontSize: '15px', fontWeight: 700, color: '#0369a1', marginBottom: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Building size={18} /> 7. Thông Tin Chủ Quán, Ngân Hàng & CCCD 2 Mặt
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div className="form-group">
                <label className="form-label">Họ Tên Chủ Quán</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="VD: Nguyễn Văn A"
                  value={form.hoTenChuQuan}
                  onChange={(e) => setForm({ ...form, hoTenChuQuan: e.target.value })}
                />
              </div>

              <DatePickerInput
                label="Ngày Sinh Chủ Quán"
                value={form.ngaySinhChuQuan}
                onChange={(val) => setForm({ ...form, ngaySinhChuQuan: val })}
              />
            </div>

            <div className="form-group">
              <label className="form-label">Số CCCD (12 Số)</label>
              <input
                type="text"
                className="form-control"
                placeholder="079201000..."
                value={form.soCCCD}
                onChange={(e) => setForm({ ...form, soCCCD: e.target.value })}
              />
            </div>

            <LocationSelector
              label="Địa Chỉ Thường Trú (Theo CCCD)"
              value={form.diaChiThuongTru}
              onChange={(val) => setForm({ ...form, diaChiThuongTru: val })}
            />

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
              <BankSelector
                label="Tên Ngân Hàng"
                value={form.tenNganHang}
                onChange={(bankName) => setForm({ ...form, tenNganHang: bankName })}
              />
              <div className="form-group">
                <label className="form-label">Số Tài Khoản</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="101010..."
                  value={form.soTaiKhoanNganHang}
                  onChange={(e) => setForm({ ...form, soTaiKhoanNganHang: e.target.value })}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Chủ Tài Khoản</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="CHỦ TÀI KHOẢN"
                  value={form.tenChuTaiKhoan}
                  onChange={(e) => setForm({ ...form, tenChuTaiKhoan: e.target.value })}
                />
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginTop: '14px' }}>
              <div>
                <ImageCropUpload
                  label="CCCD Mặt Trước"
                  value={form.cccdMatTruoc}
                  onChange={(url) => setForm({ ...form, cccdMatTruoc: url })}
                  aspectRatio={1.58}
                />
              </div>

              <div>
                <ImageCropUpload
                  label="CCCD Mặt Sau"
                  value={form.cccdMatSau}
                  onChange={(url) => setForm({ ...form, cccdMatSau: url })}
                  aspectRatio={1.58}
                />
              </div>
            </div>

            <button
              type="button"
              className="btn btn-primary"
              style={{
                width: '100%',
                marginTop: '12px',
                background: 'linear-gradient(135deg, #fc6011, #ff7e40)',
                border: 'none',
                fontWeight: 700,
                padding: '12px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px',
                boxShadow: '0 4px 12px rgba(252, 96, 17, 0.25)',
              }}
              onClick={handleScanCCCD}
              disabled={scanningCCCD}
            >
              <Bot size={18} /> {scanningCCCD ? 'Đang Quét AI...' : 'AI Quét'}
            </button>
          </div>

          <button type="submit" className="btn btn-primary" style={{ width: '100%', justifyContent: 'center', marginTop: '16px', padding: '14px', fontSize: '15px', fontWeight: 800 }} disabled={saving}>
            {saving ? <div className="loading-spinner" /> : <><Save size={18} /> Lưu Thay Đổi Hồ Sơ Quán Đồng Bộ</>}
          </button>
        </form>
      </div>
    </div>
  );
};
