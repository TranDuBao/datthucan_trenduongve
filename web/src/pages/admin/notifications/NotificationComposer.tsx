import React, { useState } from 'react';
import { apiFetch } from '../../../api/apiClient';
import {
  Send,
  Calendar,
  Smartphone,
  Info,
  Bell,
  ArrowUpCircle,
  Megaphone,
  Gift,
  Users,
  ShieldCheck,
  Clock,
  CheckCircle2,
  AlertCircle,
  HelpCircle,
} from 'lucide-react';

interface NotificationComposerProps {
  onNotificationCreated: () => void;
}

export const NotificationComposer: React.FC<NotificationComposerProps> = ({ onNotificationCreated }) => {
  const [type, setType] = useState<'system' | 'update' | 'alert' | 'promo'>('system');
  const [titleVi, setTitleVi] = useState('');
  const [bodyVi, setBodyVi] = useState('');
  const [titleEn, setTitleEn] = useState('');
  const [bodyEn, setBodyEn] = useState('');
  const [target, setTarget] = useState<'ALL' | 'ROLE' | 'VERSION_LT'>('ALL');
  const [targetRole, setTargetRole] = useState<'KHACH_HANG' | 'CUAN_HANG'>('KHACH_HANG');
  const [versionTarget, setVersionTarget] = useState('');
  const [sendMode, setSendMode] = useState<'now' | 'scheduled'>('now');
  const [scheduledDate, setScheduledDate] = useState('');
  const [previewLang, setPreviewLang] = useState<'vi' | 'en'>('vi');

  const [testUserId, setTestUserId] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isTesting, setIsTesting] = useState(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const getTypePreviewInfo = () => {
    switch (type) {
      case 'update':
        return { label: 'Cập Nhật App', icon: <ArrowUpCircle size={12} />, bg: '#2563eb' };
      case 'alert':
        return { label: 'Khẩn Cấp', icon: <Megaphone size={12} />, bg: '#dc2626' };
      case 'promo':
        return { label: 'Ưu Đãi Lộ Trình', icon: <Gift size={12} />, bg: '#16a34a' };
      case 'system':
      default:
        return { label: 'Hệ Thống', icon: <Bell size={12} />, bg: '#fc6011' };
    }
  };

  const handleSendOrSchedule = async () => {
    if (!titleVi.trim() || !bodyVi.trim()) {
      setFeedback({ type: 'error', message: 'Vui lòng nhập đầy đủ tiêu đề và nội dung tiếng Việt.' });
      return;
    }

    if (sendMode === 'scheduled' && !scheduledDate) {
      setFeedback({ type: 'error', message: 'Vui lòng chọn thời gian hẹn giờ gửi.' });
      return;
    }

    setIsSubmitting(true);
    setFeedback(null);

    try {
      const payload: any = {
        type,
        titleVi: titleVi.trim(),
        bodyVi: bodyVi.trim(),
        titleEn: titleEn.trim() || undefined,
        bodyEn: bodyEn.trim() || undefined,
        target,
        targetValue:
          target === 'ROLE' ? targetRole : target === 'VERSION_LT' ? versionTarget : undefined,
        sendNow: sendMode === 'now',
        scheduledAt: sendMode === 'scheduled' ? new Date(scheduledDate).toISOString() : undefined,
      };

      const res = await apiFetch('/admin/notifications', {
        method: 'POST',
        body: JSON.stringify(payload),
      });

      if (res && res.success !== false) {
        setFeedback({
          type: 'success',
          message: sendMode === 'now' ? 'Đã phát thông báo thành công!' : 'Đã lên lịch gửi thông báo thành công!',
        });
        // Reset form
        setTitleVi('');
        setBodyVi('');
        setTitleEn('');
        setBodyEn('');
        onNotificationCreated();
      } else {
        setFeedback({ type: 'error', message: res.message || 'Lỗi khi tạo thông báo' });
      }
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Lỗi kết nối khi gửi thông báo' });
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSendTest = async () => {
    if (!titleVi.trim() || !bodyVi.trim()) {
      setFeedback({ type: 'error', message: 'Vui lòng nhập tiêu đề & nội dung trước khi gửi thử.' });
      return;
    }
    if (!testUserId.trim()) {
      setFeedback({ type: 'error', message: 'Vui lòng nhập ID người dùng để gửi thử.' });
      return;
    }

    setIsTesting(true);
    setFeedback(null);

    try {
      // Create draft or send directly to user
      const draftRes = await apiFetch('/admin/notifications', {
        method: 'POST',
        body: JSON.stringify({
          type,
          titleVi: titleVi.trim(),
          bodyVi: bodyVi.trim(),
          titleEn: titleEn.trim() || undefined,
          bodyEn: bodyEn.trim() || undefined,
          target: 'USER',
          sendNow: false,
        }),
      });

      if (draftRes && draftRes.data?.id) {
        const notifId = draftRes.data.id;
        const testRes = await apiFetch(`/admin/notifications/${notifId}/test`, {
          method: 'POST',
          body: JSON.stringify({ targetUserId: parseInt(testUserId) }),
        });
        setFeedback({ type: 'success', message: testRes.message || `Đã gửi thử tới User #${testUserId}` });
      } else {
        setFeedback({ type: 'error', message: 'Không thể tạo bản nháp thử nghiệm' });
      }
    } catch (err: any) {
      setFeedback({ type: 'error', message: err.message || 'Lỗi khi gửi thử nghiệm' });
    } finally {
      setIsTesting(false);
    }
  };

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 0.8fr', gap: '24px', alignItems: 'start' }}>
      {/* LEFT: Composer Form */}
      <div style={{ background: '#fff', borderRadius: '16px', border: '1px solid #e2e8f0', padding: '24px' }}>
        <h3 style={{ fontSize: '18px', fontWeight: 700, margin: '0 0 16px 0', color: '#1e293b' }}>
          Soạn Thông Báo Hệ Thống & Cập Nhật
        </h3>

        {feedback && (
          <div
            style={{
              padding: '12px 16px',
              borderRadius: '10px',
              marginBottom: '16px',
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

        {/* 1. Chọn loại thông báo */}
        <div style={{ marginBottom: '20px' }}>
          <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '8px' }}>
            Loại thông báo & Biểu tượng logo hiển thị
          </label>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '12px' }}>
            {/* 1. Hệ thống */}
            <div
              onClick={() => {
                setType('system');
                if (target === 'VERSION_LT') setTarget('ALL');
              }}
              style={{
                padding: '12px',
                borderRadius: '12px',
                border: type === 'system' ? '2px solid #fc6011' : '1px solid #cbd5e1',
                backgroundColor: type === 'system' ? '#fff7ed' : '#f8fafc',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                transition: 'all 0.15s ease',
              }}
            >
              <div
                style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '8px',
                  backgroundColor: type === 'system' ? '#fc6011' : '#e2e8f0',
                  color: type === 'system' ? '#fff' : '#64748b',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                <Bell size={18} />
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: '13px', color: '#1e293b' }}>Hệ Thống</div>
                <div style={{ fontSize: '11px', color: '#64748b', lineHeight: 1.25 }}>Bảo trì máy chủ, thông báo chung</div>
              </div>
            </div>

            {/* 2. Cập nhật phiên bản */}
            <div
              onClick={() => setType('update')}
              style={{
                padding: '12px',
                borderRadius: '12px',
                border: type === 'update' ? '2px solid #2563eb' : '1px solid #cbd5e1',
                backgroundColor: type === 'update' ? '#eff6ff' : '#f8fafc',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                transition: 'all 0.15s ease',
              }}
            >
              <div
                style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '8px',
                  backgroundColor: type === 'update' ? '#2563eb' : '#e2e8f0',
                  color: type === 'update' ? '#fff' : '#64748b',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                <ArrowUpCircle size={18} />
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: '13px', color: '#1e293b' }}>Cập Nhật App</div>
                <div style={{ fontSize: '11px', color: '#64748b', lineHeight: 1.25 }}>Phiên bản mới, tính năng mới</div>
              </div>
            </div>

            {/* 3. Khẩn cấp / Cảnh báo */}
            <div
              onClick={() => {
                setType('alert');
                if (target === 'VERSION_LT') setTarget('ALL');
              }}
              style={{
                padding: '12px',
                borderRadius: '12px',
                border: type === 'alert' ? '2px solid #dc2626' : '1px solid #cbd5e1',
                backgroundColor: type === 'alert' ? '#fef2f2' : '#f8fafc',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                transition: 'all 0.15s ease',
              }}
            >
              <div
                style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '8px',
                  backgroundColor: type === 'alert' ? '#dc2626' : '#e2e8f0',
                  color: type === 'alert' ? '#fff' : '#64748b',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                <Megaphone size={18} />
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: '13px', color: '#1e293b' }}>Khẩn Cấp</div>
                <div style={{ fontSize: '11px', color: '#64748b', lineHeight: 1.25 }}>Cảnh báo thời tiết, gián đoạn</div>
              </div>
            </div>

            {/* 4. Ưu đãi / Khuyến mãi */}
            <div
              onClick={() => {
                setType('promo');
                if (target === 'VERSION_LT') setTarget('ALL');
              }}
              style={{
                padding: '12px',
                borderRadius: '12px',
                border: type === 'promo' ? '2px solid #16a34a' : '1px solid #cbd5e1',
                backgroundColor: type === 'promo' ? '#f0fdf4' : '#f8fafc',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '10px',
                transition: 'all 0.15s ease',
              }}
            >
              <div
                style={{
                  width: '36px',
                  height: '36px',
                  borderRadius: '8px',
                  backgroundColor: type === 'promo' ? '#16a34a' : '#e2e8f0',
                  color: type === 'promo' ? '#fff' : '#64748b',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                }}
              >
                <Gift size={18} />
              </div>
              <div>
                <div style={{ fontWeight: 700, fontSize: '13px', color: '#1e293b' }}>Ưu Đãi Lộ Trình</div>
                <div style={{ fontSize: '11px', color: '#64748b', lineHeight: 1.25 }}>Khuyến mãi quán, voucher tiện đường</div>
              </div>
            </div>
          </div>
        </div>

        {/* 2. Soạn nội dung song ngữ */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '20px' }}>
          {/* Tiếng Việt */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '6px' }}>
              <span style={{ fontSize: '15px' }}>🇻🇳</span>
              <label style={{ fontSize: '13px', fontWeight: 600, color: '#334155' }}>
                Tiêu đề (Tiếng Việt) <span style={{ color: '#ef4444' }}>*</span>
              </label>
            </div>
            <input
              type="text"
              value={titleVi}
              onChange={(e) => setTitleVi(e.target.value)}
              placeholder="VD: Thông báo bảo trì máy chủ đêm nay"
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
                outline: 'none',
              }}
            />

            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginTop: '12px', marginBottom: '6px' }}>
              Nội dung (Tiếng Việt) <span style={{ color: '#ef4444' }}>*</span>
            </label>
            <textarea
              rows={4}
              value={bodyVi}
              onChange={(e) => setBodyVi(e.target.value)}
              placeholder="Nhập nội dung thông báo gửi đến khách hàng..."
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
                outline: 'none',
                resize: 'vertical',
              }}
            />
          </div>

          {/* Tiếng Anh */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '6px' }}>
              <span style={{ fontSize: '15px' }}>🇬🇧</span>
              <label style={{ fontSize: '13px', fontWeight: 600, color: '#334155' }}>
                Title (English) <span style={{ fontSize: '11px', color: '#64748b' }}>(Tùy chọn)</span>
              </label>
            </div>
            <input
              type="text"
              value={titleEn}
              onChange={(e) => setTitleEn(e.target.value)}
              placeholder="e.g. Scheduled System Maintenance"
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
                outline: 'none',
              }}
            />

            <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#334155', marginTop: '12px', marginBottom: '6px' }}>
              Body (English) <span style={{ fontSize: '11px', color: '#64748b' }}>(Tùy chọn)</span>
            </label>
            <textarea
              rows={4}
              value={bodyEn}
              onChange={(e) => setBodyEn(e.target.value)}
              placeholder="English message for international users..."
              style={{
                width: '100%',
                padding: '10px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '14px',
                outline: 'none',
                resize: 'vertical',
              }}
            />
          </div>
        </div>

        {/* 3. Đối tượng nhận */}
        <div style={{ marginBottom: '20px' }}>
          <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '8px' }}>
            Đối tượng nhận thông báo
          </label>
          <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
            <label
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '8px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                backgroundColor: target === 'ALL' ? '#f1f5f9' : '#fff',
                cursor: 'pointer',
                fontSize: '13px',
                fontWeight: 600,
              }}
            >
              <input type="radio" checked={target === 'ALL'} onChange={() => setTarget('ALL')} />
              Tất cả người dùng
            </label>

            <label
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '8px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                backgroundColor: target === 'ROLE' ? '#f1f5f9' : '#fff',
                cursor: 'pointer',
                fontSize: '13px',
                fontWeight: 600,
              }}
            >
              <input type="radio" checked={target === 'ROLE'} onChange={() => setTarget('ROLE')} />
              Theo vai trò
            </label>

            {type === 'update' && (
              <label
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '8px 14px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  backgroundColor: target === 'VERSION_LT' ? '#f1f5f9' : '#fff',
                  cursor: 'pointer',
                  fontSize: '13px',
                  fontWeight: 600,
                }}
              >
                <input type="radio" checked={target === 'VERSION_LT'} onChange={() => setTarget('VERSION_LT')} />
                Phiên bản app thấp hơn X
              </label>
            )}
          </div>

          {target === 'ROLE' && (
            <div style={{ marginTop: '10px', display: 'flex', gap: '12px' }}>
              <select
                value={targetRole}
                onChange={(e) => setTargetRole(e.target.value as any)}
                style={{
                  padding: '8px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '13px',
                  outline: 'none',
                }}
              >
                <option value="KHACH_HANG">Khách Hàng (Customer)</option>
                <option value="CUAN_HANG">Chủ Nhà Hàng / Đối Tác</option>
              </select>
            </div>
          )}

          {target === 'VERSION_LT' && (
            <div style={{ marginTop: '10px' }}>
              <input
                type="text"
                placeholder="Nhập phiên bản ngưỡng (VD: 1.1.0)"
                value={versionTarget}
                onChange={(e) => setVersionTarget(e.target.value)}
                style={{
                  padding: '8px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '13px',
                  width: '260px',
                  outline: 'none',
                }}
              />
              <span style={{ fontSize: '12px', color: '#64748b', marginLeft: '10px' }}>
                Chỉ thiết bị có app version &lt; {versionTarget || 'X'} mới nhận thông báo này
              </span>
            </div>
          )}
        </div>

        {/* 4. Tùy chọn gửi ngay hoặc hẹn giờ */}
        <div style={{ marginBottom: '24px' }}>
          <label style={{ display: 'block', fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '8px' }}>
            Thời gian gửi
          </label>
          <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
            <label
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '8px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                backgroundColor: sendMode === 'now' ? '#f1f5f9' : '#fff',
                cursor: 'pointer',
                fontSize: '13px',
                fontWeight: 600,
              }}
            >
              <input type="radio" checked={sendMode === 'now'} onChange={() => setSendMode('now')} />
              Phát ngay lập tức
            </label>

            <label
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                padding: '8px 14px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                backgroundColor: sendMode === 'scheduled' ? '#f1f5f9' : '#fff',
                cursor: 'pointer',
                fontSize: '13px',
                fontWeight: 600,
              }}
            >
              <input type="radio" checked={sendMode === 'scheduled'} onChange={() => setSendMode('scheduled')} />
              Hẹn giờ gửi
            </label>

            {sendMode === 'scheduled' && (
              <input
                type="datetime-local"
                value={scheduledDate}
                onChange={(e) => setScheduledDate(e.target.value)}
                style={{
                  padding: '8px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '13px',
                  outline: 'none',
                }}
              />
            )}
          </div>
        </div>

        {/* 5. Gửi thử & Phát chính thức */}
        <div
          style={{
            padding: '16px',
            backgroundColor: '#f8fafc',
            borderRadius: '12px',
            border: '1px solid #e2e8f0',
            display: 'flex',
            flexDirection: 'column',
            gap: '12px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <input
                type="number"
                placeholder="Nhập ID User gửi thử"
                value={testUserId}
                onChange={(e) => setTestUserId(e.target.value)}
                style={{
                  padding: '8px 12px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  fontSize: '13px',
                  width: '180px',
                  outline: 'none',
                }}
              />
              <button
                type="button"
                onClick={handleSendTest}
                disabled={isTesting}
                style={{
                  padding: '8px 16px',
                  borderRadius: '8px',
                  border: '1px solid #cbd5e1',
                  backgroundColor: '#fff',
                  cursor: isTesting ? 'not-allowed' : 'pointer',
                  fontSize: '13px',
                  fontWeight: 600,
                  color: '#334155',
                }}
              >
                {isTesting ? 'Đang gửi thử...' : 'Gửi thử nghiệm'}
              </button>
            </div>

            <button
              type="button"
              onClick={handleSendOrSchedule}
              disabled={isSubmitting}
              style={{
                padding: '10px 24px',
                borderRadius: '10px',
                backgroundColor: '#fc6011',
                color: '#fff',
                border: 'none',
                cursor: isSubmitting ? 'not-allowed' : 'pointer',
                fontSize: '14px',
                fontWeight: 700,
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                boxShadow: '0 4px 12px rgba(252, 96, 17, 0.25)',
              }}
            >
              <Send size={16} />
              {isSubmitting
                ? 'Đang phát...'
                : sendMode === 'now'
                ? 'Phát Thông Báo Toàn Mạng'
                : 'Lên Lịch Hẹn Giờ Gửi'}
            </button>
          </div>
        </div>
      </div>

      {/* RIGHT: Lock Screen Phone Mockup Preview */}
      <div style={{ position: 'sticky', top: '24px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, color: '#334155' }}>
            <Smartphone size={20} color="#fc6011" />
            Xem trước màn hình khóa
          </div>
          <div style={{ display: 'flex', gap: '6px' }}>
            <button
              type="button"
              onClick={() => setPreviewLang('vi')}
              style={{
                padding: '4px 10px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: previewLang === 'vi' ? '#fc6011' : '#e2e8f0',
                color: previewLang === 'vi' ? '#fff' : '#64748b',
                fontSize: '12px',
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              🇻🇳 VI
            </button>
            <button
              type="button"
              onClick={() => setPreviewLang('en')}
              style={{
                padding: '4px 10px',
                borderRadius: '6px',
                border: 'none',
                backgroundColor: previewLang === 'en' ? '#fc6011' : '#e2e8f0',
                color: previewLang === 'en' ? '#fff' : '#64748b',
                fontSize: '12px',
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              🇬🇧 EN
            </button>
          </div>
        </div>

        {/* Smartphone Mockup */}
        <div
          style={{
            width: '320px',
            height: '580px',
            borderRadius: '40px',
            backgroundColor: '#0f172a',
            border: '8px solid #1e293b',
            boxShadow: '0 20px 40px rgba(0,0,0,0.35)',
            margin: '0 auto',
            position: 'relative',
            overflow: 'hidden',
            display: 'flex',
            flexDirection: 'column',
          }}
        >
          {/* Top Notch / Camera pill */}
          <div
            style={{
              width: '90px',
              height: '20px',
              backgroundColor: '#000',
              borderRadius: '0 0 14px 14px',
              margin: '0 auto',
              zIndex: 10,
            }}
          />

          {/* Clock Header */}
          <div style={{ textAlign: 'center', color: '#fff', marginTop: '36px', marginBottom: '24px' }}>
            <div style={{ fontSize: '54px', fontWeight: 300, letterSpacing: '-1px' }}>09:41</div>
            <div style={{ fontSize: '14px', color: 'rgba(255,255,255,0.7)', fontWeight: 500 }}>
              Thứ Hai, 9 tháng 11
            </div>
          </div>

          {/* Push Notification Card */}
          <div style={{ padding: '0 14px' }}>
            <div
              style={{
                backgroundColor: 'rgba(255, 255, 255, 0.88)',
                backdropFilter: 'blur(20px)',
                borderRadius: '16px',
                padding: '12px 14px',
                boxShadow: '0 8px 24px rgba(0,0,0,0.18)',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '6px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                  <div
                    style={{
                      width: '20px',
                      height: '20px',
                      borderRadius: '6px',
                      backgroundColor: getTypePreviewInfo().bg,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: '#fff',
                    }}
                  >
                    {getTypePreviewInfo().icon}
                  </div>
                  <span style={{ fontSize: '11px', fontWeight: 700, color: '#334155', textTransform: 'uppercase' }}>
                    FOOD ROUTE • {getTypePreviewInfo().label}
                  </span>
                </div>
                <span style={{ fontSize: '10px', color: '#64748b' }}>Vừa xong</span>
              </div>

              {/* Title & Body */}
              <div style={{ fontSize: '13px', fontWeight: 700, color: '#0f172a', marginBottom: '3px' }}>
                {previewLang === 'vi'
                  ? titleVi || 'Tiêu đề thông báo'
                  : titleEn || titleVi || 'Notification Title'}
              </div>
              <div
                style={{
                  fontSize: '12px',
                  color: '#334155',
                  lineHeight: 1.35,
                  display: '-webkit-box',
                  WebkitLineClamp: 3,
                  WebkitBoxOrient: 'vertical',
                  overflow: 'hidden',
                }}
              >
                {previewLang === 'vi'
                  ? bodyVi || 'Nội dung thông báo sẽ hiển thị ở đây trên màn hình khóa của thiết bị di động.'
                  : bodyEn || bodyVi || 'Notification content will appear here on the device lock screen.'}
              </div>
            </div>
          </div>

          {/* Bottom Home Indicator Bar */}
          <div
            style={{
              marginTop: 'auto',
              marginBottom: '10px',
              width: '120px',
              height: '4px',
              backgroundColor: 'rgba(255,255,255,0.4)',
              borderRadius: '2px',
              alignSelf: 'center',
            }}
          />
        </div>
      </div>
    </div>
  );
};

