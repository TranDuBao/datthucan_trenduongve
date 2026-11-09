import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../../api/apiClient';
import {
  Smartphone,
  Apple,
  Save,
  Radio,
  Sparkles,
  CheckCircle2,
  AlertCircle,
  ExternalLink,
} from 'lucide-react';

interface VersionConfig {
  platform: 'android' | 'ios';
  latestVersion: string;
  minRequiredVersion: string;
  storeUrl: string;
  changelogVi: string;
  changelogEn: string;
}

export const AppVersionManager: React.FC<{ onVersionUpdated: () => void }> = ({ onVersionUpdated }) => {
  const [activePlatform, setActivePlatform] = useState<'android' | 'ios'>('android');
  const [androidConfig, setAndroidConfig] = useState<VersionConfig>({
    platform: 'android',
    latestVersion: '1.0.0',
    minRequiredVersion: '1.0.0',
    storeUrl: 'https://play.google.com/store/apps/details?id=com.foodroute.app',
    changelogVi: '',
    changelogEn: '',
  });
  const [iosConfig, setIosConfig] = useState<VersionConfig>({
    platform: 'ios',
    latestVersion: '1.0.0',
    minRequiredVersion: '1.0.0',
    storeUrl: 'https://apps.apple.com/app/food-route/id123456789',
    changelogVi: '',
    changelogEn: '',
  });

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const fetchVersions = async () => {
    setLoading(true);
    try {
      const res = await apiFetch('/admin/app-versions');
      if (res && res.data) {
        if (res.data.android) setAndroidConfig((prev) => ({ ...prev, ...res.data.android }));
        if (res.data.ios) setIosConfig((prev) => ({ ...prev, ...res.data.ios }));
      }
    } catch (e) {
      console.error('[AppVersionManager] fetch error:', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchVersions();
  }, []);

  const currentConfig = activePlatform === 'android' ? androidConfig : iosConfig;
  const setConfig = (data: Partial<VersionConfig>) => {
    if (activePlatform === 'android') {
      setAndroidConfig((prev) => ({ ...prev, ...data }));
    } else {
      setIosConfig((prev) => ({ ...prev, ...data }));
    }
  };

  const handleSave = async (notifyUsers: boolean = false) => {
    setSaving(true);
    setFeedback(null);
    try {
      const res = await apiFetch(`/admin/app-versions/${activePlatform}`, {
        method: 'PUT',
        body: JSON.stringify({
          ...currentConfig,
          notifyUsers,
        }),
      });

      if (res && res.success !== false) {
        setFeedback({
          type: 'success',
          message: notifyUsers
            ? `Đã lưu cấu hình ${activePlatform.toUpperCase()} và phát thông báo cập nhật thành công!`
            : `Đã lưu cấu hình phiên bản ${activePlatform.toUpperCase()} thành công!`,
        });
        onVersionUpdated();
      } else {
        setFeedback({ type: 'error', message: res.message || 'Lỗi khi lưu cấu hình' });
      }
    } catch (e: any) {
      setFeedback({ type: 'error', message: e.message || 'Lỗi khi lưu cấu hình' });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={{ background: '#fff', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '20px' }}>
        <div>
          <h3 style={{ fontSize: '18px', fontWeight: 700, margin: '0 0 4px 0', color: '#1e293b' }}>
            Quản Lý Phiên Bản Ứng Dụng (Android & iOS)
          </h3>
          <p style={{ fontSize: '13px', color: '#64748b', margin: 0 }}>
            Kiểm soát phiên bản mới nhất, phiên bản bắt buộc cập nhật và đường dẫn Store
          </p>
        </div>

        {/* Platform Tabs */}
        <div style={{ display: 'flex', gap: '8px', backgroundColor: '#f1f5f9', padding: '4px', borderRadius: '10px' }}>
          <button
            type="button"
            onClick={() => setActivePlatform('android')}
            style={{
              padding: '8px 16px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: activePlatform === 'android' ? '#fff' : 'transparent',
              color: activePlatform === 'android' ? '#0f172a' : '#64748b',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              boxShadow: activePlatform === 'android' ? '0 2px 4px rgba(0,0,0,0.06)' : 'none',
            }}
          >
            <Smartphone size={16} color="#10b981" />
            Android App
          </button>

          <button
            type="button"
            onClick={() => setActivePlatform('ios')}
            style={{
              padding: '8px 16px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: activePlatform === 'ios' ? '#fff' : 'transparent',
              color: activePlatform === 'ios' ? '#0f172a' : '#64748b',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              boxShadow: activePlatform === 'ios' ? '0 2px 4px rgba(0,0,0,0.06)' : 'none',
            }}
          >
            <Apple size={16} color="#0284c7" />
            iOS (Apple)
          </button>
        </div>
      </div>

      {feedback && (
        <div
          style={{
            padding: '12px 16px',
            borderRadius: '10px',
            marginBottom: '20px',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            backgroundColor: feedback.type === 'success' ? '#f0fdf4' : '#fef2f2',
            color: feedback.type === 'success' ? '#166534' : '#991b1b',
            border: `1px solid ${feedback.type === 'success' ? '#bbf7d0' : '#fecaca'}`,
          }}
        >
          {feedback.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
          <span style={{ fontSize: '14px', fontWeight: 500 }}>{feedback.message}</span>
        </div>
      )}

      {loading ? (
        <div style={{ padding: '36px', textAlign: 'center', color: '#94a3b8' }}>Đang nạp cấu hình phiên bản...</div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
          {/* Version Inputs */}
          <div>
            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
              Phiên bản mới nhất (Latest Version)
            </label>
            <input
              type="text"
              value={currentConfig.latestVersion}
              onChange={(e) => setConfig({ latestVersion: e.target.value })}
              placeholder="VD: 1.0.1"
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
                outline: 'none',
                marginBottom: '16px',
              }}
            />

            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
              Phiên bản tối thiểu bắt buộc (Min Required Version)
            </label>
            <input
              type="text"
              value={currentConfig.minRequiredVersion}
              onChange={(e) => setConfig({ minRequiredVersion: e.target.value })}
              placeholder="VD: 1.0.0"
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
                outline: 'none',
                marginBottom: '4px',
              }}
            />
            <span style={{ display: 'block', fontSize: '12px', color: '#64748b', marginBottom: '16px' }}>
              Nếu người dùng có app version thấp hơn giá trị này, app sẽ hiển thị màn hình khóa bắt buộc cập nhật.
            </span>

            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
              Đường dẫn Store (Google Play / Apple App Store URL)
            </label>
            <input
              type="text"
              value={currentConfig.storeUrl}
              onChange={(e) => setConfig({ storeUrl: e.target.value })}
              placeholder="https://..."
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
                outline: 'none',
              }}
            />
          </div>

          {/* Changelog Inputs */}
          <div>
            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
              Nội dung cập nhật (Tiếng Việt)
            </label>
            <textarea
              rows={3}
              value={currentConfig.changelogVi}
              onChange={(e) => setConfig({ changelogVi: e.target.value })}
              placeholder="- Tối ưu hóa định vị theo lộ trình&#10;- Bổ sung hệ thống thông báo đẩy thời gian thực&#10;- Sửa lỗi và nâng cao hiệu năng"
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                outline: 'none',
                marginBottom: '14px',
                resize: 'vertical',
              }}
            />

            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginBottom: '6px' }}>
              Changelog (English)
            </label>
            <textarea
              rows={3}
              value={currentConfig.changelogEn}
              onChange={(e) => setConfig({ changelogEn: e.target.value })}
              placeholder="- Route discovery enhancements&#10;- Push notifications on lock screen&#10;- Bug fixes & stability improvements"
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                outline: 'none',
                resize: 'vertical',
              }}
            />
          </div>

          {/* Action Buttons */}
          <div
            style={{
              gridColumn: '1 / -1',
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '12px',
              paddingTop: '16px',
              borderTop: '1px solid #f1f5f9',
            }}
          >
            <button
              type="button"
              disabled={saving}
              onClick={() => handleSave(false)}
              style={{
                padding: '10px 20px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                backgroundColor: '#fff',
                color: '#334155',
                fontSize: '14px',
                fontWeight: 600,
                cursor: saving ? 'not-allowed' : 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
              }}
            >
              <Save size={16} />
              Lưu cấu hình
            </button>

            <button
              type="button"
              disabled={saving}
              onClick={() => handleSave(true)}
              style={{
                padding: '10px 24px',
                borderRadius: '8px',
                backgroundColor: '#7c3aed',
                color: '#fff',
                border: 'none',
                fontSize: '14px',
                fontWeight: 700,
                cursor: saving ? 'not-allowed' : 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                boxShadow: '0 4px 12px rgba(124, 58, 237, 0.25)',
              }}
            >
              <Sparkles size={16} />
              {saving ? 'Đang lưu & phát...' : 'Lưu & Phát Thông Báo Cập Nhật'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

