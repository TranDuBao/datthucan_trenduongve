import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Store, Save } from 'lucide-react';
import { ImageCropUpload } from '../../components/ImageCropUpload';

export const RestaurantProfile: React.FC = () => {
  const [profile, setProfile] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  const [form, setForm] = useState({
    tenQuan: '',
    diaChi: '',
    sdt: '',
    img: '',
    trangThai: 'mở cửa',
  });

  useEffect(() => {
    apiFetch<any>('/restaurant/profile')
      .then((res) => {
        const p = res.data;
        setProfile(p);
        setForm({
          tenQuan: p.tenQuan || '',
          diaChi: p.diaChi || '',
          sdt: p.sdt || '',
          img: p.img || '',
          trangThai: p.trangThai || 'mở cửa',
        });
      })
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setMessage('');
    try {
      await apiFetch('/restaurant/profile', {
        method: 'PUT',
        body: JSON.stringify(form),
      });
      setMessage('Cập nhật thông tin nhà hàng thành công!');
    } catch (err: any) {
      alert(err.message || 'Lỗi cập nhật');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div style={{ textAlign: 'center', padding: '60px' }}><div className="loading-spinner" /></div>;
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Thông Tin Nhà Hàng</h1>
          <p className="page-subtitle">Quản lý tên quán, địa chỉ, hình ảnh banner & trạng thái hoạt động</p>
        </div>
      </div>

      <div style={{ background: '#ffffff', border: '1px solid #e2e8f0', borderRadius: '14px', padding: '28px', maxWidth: '640px', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
        {message && (
          <div style={{ background: '#ecfdf5', color: '#10b981', padding: '10px 14px', borderRadius: '8px', fontSize: '13px', fontWeight: 600, marginBottom: '20px' }}>
            {message}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Tên Nhà Hàng</label>
            <input type="text" className="form-control" value={form.tenQuan} onChange={(e) => setForm({ ...form, tenQuan: e.target.value })} required />
          </div>

          <div className="form-group">
            <label className="form-label">Địa Chỉ Nhà Hàng</label>
            <textarea className="form-control" rows={3} value={form.diaChi} onChange={(e) => setForm({ ...form, diaChi: e.target.value })} required />
          </div>

          <div className="form-group">
            <label className="form-label">Số Điện Thoại Liên Hệ</label>
            <input type="text" className="form-control" value={form.sdt} onChange={(e) => setForm({ ...form, sdt: e.target.value })} />
          </div>

          <ImageCropUpload
            label="Hình Ảnh Banner/Logo Nhà Hàng (Upload & Cắt Ảnh 16:9)"
            value={form.img}
            onChange={(url) => setForm({ ...form, img: url })}
            aspectRatio={1.77}
          />

          <div className="form-group">
            <label className="form-label">Trạng Thái Hoạt Động</label>
            <select className="form-control" value={form.trangThai} onChange={(e) => setForm({ ...form, trangThai: e.target.value })}>
              <option value="mở cửa">Đang mở cửa (Hoạt động)</option>
              <option value="đóng cửa">Tạm đóng cửa</option>
            </select>
          </div>

          <button type="submit" className="btn btn-primary" style={{ width: '100%', justifyContent: 'center', marginTop: '12px' }} disabled={saving}>
            {saving ? <div className="loading-spinner" /> : <><Save size={18} /> Lưu Thay Đổi Thông Tin</>}
          </button>
        </form>
      </div>
    </div>
  );
};
