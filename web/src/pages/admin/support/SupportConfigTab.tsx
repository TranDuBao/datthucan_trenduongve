import React, { useState, useEffect } from 'react';
import { Phone, Mail, Clock, Save, RefreshCw, CheckCircle, AlertCircle } from 'lucide-react';
import { apiFetch } from '../../../api/apiClient';

interface SupportConfig {
  hotline: string;
  gioLamViec: string;
  emailHoTro: string;
}

export const SupportConfigTab: React.FC = () => {
  const [config, setConfig] = useState<SupportConfig>({
    hotline: '',
    gioLamViec: '',
    emailHoTro: '',
  });
  const [loading, setLoading] = useState<boolean>(true);
  const [saving, setSaving] = useState<boolean>(false);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchConfig = async () => {
    try {
      setLoading(true);
      const res = await apiFetch<any>('/admin/support/config');
      if (res && res.data) {
        setConfig({
          hotline: res.data.hotline || '',
          gioLamViec: res.data.gioLamViec || '',
          emailHoTro: res.data.emailHoTro || '',
        });
      }
    } catch (err: any) {
      showToast('error', err.message || 'Lỗi tải cấu hình hỗ trợ');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchConfig();
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!config.hotline.trim()) {
      showToast('error', 'Vui lòng nhập số Hotline');
      return;
    }
    if (!config.emailHoTro.trim()) {
      showToast('error', 'Vui lòng nhập Email hỗ trợ');
      return;
    }
    try {
      setSaving(true);
      const res = await apiFetch<any>('/admin/support/config', {
        method: 'PUT',
        body: JSON.stringify(config),
      });
      if (res && res.success) {
        showToast('success', 'Đã lưu cấu hình liên hệ! App khách sẽ tự động cập nhật ngay lập tức.');
      }
    } catch (err: any) {
      showToast('error', err.message || 'Lỗi lưu cấu hình');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={{ maxWidth: '800px' }}>
      {toast && (
        <div
          style={{
            marginBottom: '16px',
            padding: '12px 16px',
            borderRadius: '10px',
            backgroundColor: toast.type === 'success' ? '#ecfdf5' : '#fef2f2',
            border: `1px solid ${toast.type === 'success' ? '#86efac' : '#fca5a5'}`,
            color: toast.type === 'success' ? '#166534' : '#991b1b',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            fontSize: '13px',
            fontWeight: 600,
          }}
        >
          {toast.type === 'success' ? <CheckCircle size={18} /> : <AlertCircle size={18} />}
          {toast.message}
        </div>
      )}

      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '14px',
          padding: '24px',
          border: '1px solid #e2e8f0',
          boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
          <div>
            <h3 style={{ fontSize: '16px', fontWeight: 700, color: '#0f172a' }}>Thông Tin Hotline & Email Hỗ Trợ</h3>
            <p style={{ fontSize: '13px', color: '#64748b', marginTop: '2px' }}>
              Các thông tin này sẽ hiển thị trực tiếp tại nút gọi và gửi email trên App Food Route
            </p>
          </div>
          <button
            onClick={fetchConfig}
            disabled={loading}
            style={{
              padding: '8px 14px',
              borderRadius: '8px',
              border: '1px solid #e2e8f0',
              backgroundColor: '#ffffff',
              color: '#475569',
              fontSize: '12px',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            Làm mới
          </button>
        </div>

        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
            <RefreshCw className="animate-spin inline mr-2" size={20} />
            Đang tải dữ liệu cấu hình...
          </div>
        ) : (
          <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
            <div>
              <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
                <Phone size={15} color="#fc6011" /> Số điện thoại Hotline tổng đài *
              </label>
              <input
                type="text"
                placeholder="Ví dụ: 1900 6868 hoặc 0901234567"
                value={config.hotline}
                onChange={(e) => setConfig({ ...config, hotline: e.target.value })}
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '14px',
                  color: '#0f172a',
                  backgroundColor: '#f8fafc',
                }}
              />
              <span style={{ fontSize: '11px', color: '#94a3b8', marginTop: '4px', display: 'block' }}>
                Khi người dùng bấm "Gọi tổng đài", ứng dụng sẽ tự động mở bàn phím quay số với số điện thoại này.
              </span>
            </div>

            <div>
              <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
                <Clock size={15} color="#fc6011" /> Giờ làm việc tổng đài *
              </label>
              <input
                type="text"
                placeholder="Ví dụ: 08:00 - 22:00 hàng ngày (T2 - CN)"
                value={config.gioLamViec}
                onChange={(e) => setConfig({ ...config, gioLamViec: e.target.value })}
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '14px',
                  color: '#0f172a',
                  backgroundColor: '#f8fafc',
                }}
              />
            </div>

            <div>
              <label style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', fontWeight: 700, color: '#334155', marginBottom: '6px' }}>
                <Mail size={15} color="#fc6011" /> Địa chỉ Email tiếp nhận hỗ trợ *
              </label>
              <input
                type="email"
                placeholder="Ví dụ: support@foodroute.vn"
                value={config.emailHoTro}
                onChange={(e) => setConfig({ ...config, emailHoTro: e.target.value })}
                style={{
                  width: '100%',
                  padding: '10px 14px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '14px',
                  color: '#0f172a',
                  backgroundColor: '#f8fafc',
                }}
              />
              <span style={{ fontSize: '11px', color: '#94a3b8', marginTop: '4px', display: 'block' }}>
                Khi bấm "Gửi email", app sẽ mở ứng dụng thư điện tử hoặc tự động sao chép email vào khay nhớ tạm nếu máy không có ứng dụng email.
              </span>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', paddingTop: '14px', borderTop: '1px solid #f1f5f9' }}>
              <button
                type="submit"
                disabled={saving}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '10px 22px',
                  borderRadius: '8px',
                  backgroundColor: '#fc6011',
                  color: '#ffffff',
                  fontSize: '13px',
                  fontWeight: 700,
                  border: 'none',
                  cursor: saving ? 'not-allowed' : 'pointer',
                  boxShadow: '0 2px 8px rgba(252, 96, 17, 0.25)',
                }}
              >
                <Save size={16} />
                {saving ? 'Đang lưu...' : 'Lưu Cấu Hình'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
};

