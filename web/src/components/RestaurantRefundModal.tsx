import React, { useState } from 'react';
import { X, QrCode, Copy, Check, AlertCircle, ArrowUpRight, CheckCircle2, Building, User, CreditCard } from 'lucide-react';
import { apiFetch } from '../api/apiClient';

interface RestaurantRefundModalProps {
  isOpen: boolean;
  order: any | null;
  onClose: () => void;
  onSuccess: () => void;
}

export const RestaurantRefundModal: React.FC<RestaurantRefundModalProps> = ({
  isOpen,
  order,
  onClose,
  onSuccess,
}) => {
  const [copiedAcc, setCopiedAcc] = useState(false);
  const [copiedAmount, setCopiedAmount] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');
  const [qrImgError, setQrImgError] = useState(false);

  if (!isOpen || !order) return null;

  const refund = order.refundInfo || order.refund || {};
  const maHoanTien = refund.maHoanTien || refund.id;
  const amount = Number(refund.soTienHoan || order.tongTien || 0);
  const bankName = (refund.nganHangNhan || '').trim();
  const accountNumber = (refund.soTaiKhoanNhan || '').trim();
  const accountHolder = (refund.tenChuTaiKhoanNhan || order.tenKhachHang || '').trim();
  const isCompleted = refund.trangThaiHoanTien === 'HOAN_TIEN_THANH_CONG';
  const hasBankInfo = bankName.length > 0 && accountNumber.length > 0;

  const normalizeBankCode = (b: string) => {
    const clean = b.toUpperCase().replace(/[^A-Z0-9]/g, '');
    if (clean.includes('VIETCOMBANK')) return 'VCB';
    if (clean.includes('TECHCOMBANK')) return 'TCB';
    if (clean.includes('VIETINBANK')) return 'CTG';
    if (clean.includes('AGRIBANK')) return 'VBA';
    if (clean.includes('SACOMBANK')) return 'STB';
    if (clean.includes('MBBANK')) return 'MB';
    if (clean.includes('VPBANK')) return 'VPB';
    if (clean.includes('TPBANK')) return 'TPB';
    if (clean.includes('HDBANK')) return 'HDB';
    return clean || 'MB';
  };
  const cleanBank = normalizeBankCode(bankName);
  const cleanAcc = accountNumber.replace(/[^0-9A-Za-z]/g, '');

  // VietQR QuickLink standard format
  const transferContent = `Hoan tien don #${order.maDonHang}`;
  const qrUrl = hasBankInfo
    ? `https://img.vietqr.io/image/${cleanBank}-${cleanAcc}-compact2.png?amount=${Math.round(amount)}&addInfo=${encodeURIComponent(transferContent)}&accountName=${encodeURIComponent(accountHolder)}`
    : '';

  const handleCopy = (text: string, type: 'acc' | 'amount') => {
    navigator.clipboard.writeText(text);
    if (type === 'acc') {
      setCopiedAcc(true);
      setTimeout(() => setCopiedAcc(false), 2000);
    } else {
      setCopiedAmount(true);
      setTimeout(() => setCopiedAmount(false), 2000);
    }
  };

  const handleConfirmRefund = async () => {
    if (!maHoanTien) {
      setErrorMsg('Không tìm thấy mã yêu cầu hoàn tiền');
      return;
    }
    try {
      setIsSubmitting(true);
      setErrorMsg('');
      const res = await apiFetch<any>(`/refunds/${maHoanTien}/status`, {
        method: 'PATCH',
        body: JSON.stringify({
          trangThai: 'HOAN_TIEN_THANH_CONG',
          ghiChu: 'Cửa hàng đã quét VietQR chuyển khoản trực tiếp cho khách',
        }),
      });

      if (res.status === 'success') {
        onSuccess();
        onClose();
      } else {
        setErrorMsg(res.message || 'Lỗi khi cập nhật trạng thái hoàn tiền');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Lỗi kết nối máy chủ khi xác nhận hoàn tiền');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(15, 23, 42, 0.65)',
        backdropFilter: 'blur(4px)',
        zIndex: 9999,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '16px',
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget && !isSubmitting) onClose();
      }}
    >
      <div
        style={{
          background: '#ffffff',
          borderRadius: '20px',
          width: '100%',
          maxWidth: '540px',
          maxHeight: '92vh',
          display: 'flex',
          flexDirection: 'column',
          overflow: 'hidden',
          boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
        }}
      >
        {/* Header */}
        <div
          style={{
            padding: '18px 24px',
            borderBottom: '1px solid #f1f5f9',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            background: '#ffffff',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div
              style={{
                width: '40px',
                height: '40px',
                borderRadius: '12px',
                background: '#ffedd5',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#ea580c',
              }}
            >
              <QrCode size={22} />
            </div>
            <div>
              <h3 style={{ margin: 0, fontSize: '17px', fontWeight: 800, color: '#0f172a' }}>
                Hoàn Tiền Cho Khách Hàng
              </h3>
              <p style={{ margin: 0, fontSize: '12px', color: '#64748b' }}>
                Đơn hàng #{order.maDonHang} • Khách: <strong>{order.tenKhachHang || 'Khách hàng'}</strong>
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={isSubmitting}
            style={{
              background: '#f8fafc',
              border: 'none',
              borderRadius: '50%',
              width: '34px',
              height: '34px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#64748b',
              cursor: 'pointer',
            }}
          >
            <X size={18} />
          </button>
        </div>

        {/* Content Body */}
        <div style={{ padding: '20px 24px', overflowY: 'auto' }}>
          {errorMsg && (
            <div
              style={{
                padding: '10px 14px',
                background: '#fef2f2',
                border: '1px solid #fecaca',
                borderRadius: '10px',
                color: '#b91c1c',
                fontSize: '13px',
                marginBottom: '16px',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
              }}
            >
              <AlertCircle size={16} />
              <span>{errorMsg}</span>
            </div>
          )}

          {/* Amount Box */}
          <div
            style={{
              background: 'linear-gradient(135deg, #fff7ed 0%, #ffedd5 100%)',
              border: '1.5px solid #fed7aa',
              borderRadius: '14px',
              padding: '16px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '18px',
            }}
          >
            <div>
              <div style={{ fontSize: '12px', fontWeight: 600, color: '#9a3412', textTransform: 'uppercase' }}>
                Số tiền cần hoàn lại cho khách
              </div>
              <div style={{ fontSize: '24px', fontWeight: 900, color: '#c2410c', marginTop: '2px' }}>
                {amount.toLocaleString('vi-VN')} đ
              </div>
            </div>
            <button
              onClick={() => handleCopy(amount.toString(), 'amount')}
              style={{
                background: '#ffffff',
                border: '1px solid #fed7aa',
                padding: '6px 12px',
                borderRadius: '8px',
                fontSize: '12px',
                fontWeight: 700,
                color: '#ea580c',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
              }}
            >
              {copiedAmount ? <Check size={14} color="#16a34a" /> : <Copy size={14} />}
              {copiedAmount ? 'Đã chép' : 'Sao chép'}
            </button>
          </div>

          {/* Status Check */}
          {isCompleted ? (
            <div
              style={{
                background: '#f0fdf4',
                border: '1.5px solid #bbf7d0',
                borderRadius: '14px',
                padding: '24px',
                textAlign: 'center',
                marginBottom: '16px',
              }}
            >
              <CheckCircle2 size={44} color="#16a34a" style={{ margin: '0 auto 8px' }} />
              <div style={{ fontSize: '16px', fontWeight: 800, color: '#166534' }}>
                Đã hoàn tiền thành công
              </div>
              <div style={{ fontSize: '13px', color: '#15803d', marginTop: '4px' }}>
                Cửa hàng đã xác nhận hoàn trả {amount.toLocaleString('vi-VN')} đ về tài khoản của khách hàng.
              </div>
            </div>
          ) : !hasBankInfo ? (
            <div
              style={{
                background: '#fffbeb',
                border: '1.5px solid #fde68a',
                borderRadius: '14px',
                padding: '20px',
                textAlign: 'center',
                marginBottom: '16px',
              }}
            >
              <AlertCircle size={36} color="#d97706" style={{ margin: '0 auto 8px' }} />
              <div style={{ fontSize: '15px', fontWeight: 700, color: '#92400e' }}>
                Khách hàng chưa cung cấp STK nhận tiền hoàn
              </div>
              <div style={{ fontSize: '12.5px', color: '#b45309', marginTop: '6px', lineHeight: 1.5 }}>
                Hệ thống đã gửi thông báo yêu cầu khách bổ sung thông tin ngân hàng trên app.
                Mã VietQR sẽ tự động xuất hiện tại đây ngay khi khách gửi STK (đồng bộ Realtime).
              </div>
            </div>
          ) : (
            <>
              {/* Bank Info Cards */}
              <div
                style={{
                  background: '#f8fafc',
                  border: '1px solid #e2e8f0',
                  borderRadius: '14px',
                  padding: '14px 16px',
                  marginBottom: '18px',
                }}
              >
                <div style={{ fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '10px', textTransform: 'uppercase' }}>
                  Thông tin tài khoản nhận tiền
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: '8px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: '13px' }}>
                    <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Building size={14} color="#94a3b8" /> Ngân hàng:
                    </span>
                    <strong style={{ color: '#0f172a' }}>{bankName}</strong>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: '13px' }}>
                    <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <CreditCard size={14} color="#94a3b8" /> Số tài khoản:
                    </span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <strong style={{ color: '#ea580c', fontSize: '14px', letterSpacing: '0.5px' }}>{accountNumber}</strong>
                      <button
                        onClick={() => handleCopy(accountNumber, 'acc')}
                        style={{
                          background: 'transparent',
                          border: 'none',
                          padding: '2px',
                          color: '#64748b',
                          cursor: 'pointer',
                        }}
                        title="Sao chép số tài khoản"
                      >
                        {copiedAcc ? <Check size={14} color="#16a34a" /> : <Copy size={14} />}
                      </button>
                    </div>
                  </div>

                  {accountHolder && (
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: '13px' }}>
                      <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '6px' }}>
                        <User size={14} color="#94a3b8" /> Chủ tài khoản:
                      </span>
                      <strong style={{ color: '#0f172a', textTransform: 'uppercase' }}>{accountHolder}</strong>
                    </div>
                  )}

                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: '13px' }}>
                    <span style={{ color: '#64748b' }}>Nội dung chuyển:</span>
                    <span style={{ color: '#475569', fontWeight: 600 }}>{transferContent}</span>
                  </div>
                </div>
              </div>

              {/* VietQR Dynamic Code Preview */}
              <div
                style={{
                  background: '#ffffff',
                  border: '1.5px solid #e2e8f0',
                  borderRadius: '16px',
                  padding: '16px',
                  textAlign: 'center',
                  boxShadow: '0 4px 12px rgba(0, 0, 0, 0.04)',
                }}
              >
                <div style={{ fontSize: '13px', fontWeight: 700, color: '#334155', marginBottom: '8px' }}>
                  Quét mã VietQR để chuyển khoản ngay
                </div>
                <div style={{ fontSize: '11.5px', color: '#64748b', marginBottom: '12px' }}>
                  Mở ứng dụng ngân hàng bất kỳ để quét. Số tiền và nội dung đã được điền tự động.
                </div>

                <div
                  style={{
                    display: 'inline-block',
                    padding: '8px',
                    background: '#ffffff',
                    borderRadius: '12px',
                    border: '1px solid #cbd5e1',
                  }}
                >
                  {qrImgError ? (
                    <div style={{ padding: '24px 16px', textAlign: 'center', color: '#64748b' }}>
                      <p style={{ margin: '0 0 8px 0', fontSize: '13px', fontWeight: 700, color: '#b45309' }}>
                        ⚠️ Không thể tải ảnh mã QR
                      </p>
                      <p style={{ margin: 0, fontSize: '12px' }}>
                        Vui lòng sao chép STK bên cạnh và chuyển khoản thủ công trên App ngân hàng.
                      </p>
                    </div>
                  ) : (
                    <img
                      src={qrUrl}
                      alt="VietQR Refund"
                      onError={() => setQrImgError(true)}
                      style={{
                        width: '220px',
                        height: 'auto',
                        display: 'block',
                        margin: '0 auto',
                        borderRadius: '8px',
                      }}
                    />
                  )}
                </div>
              </div>
            </>
          )}
        </div>

        {/* Footer Actions */}
        <div
          style={{
            padding: '16px 24px',
            borderTop: '1px solid #f1f5f9',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'flex-end',
            gap: '12px',
            background: '#ffffff',
          }}
        >
          <button
            onClick={onClose}
            disabled={isSubmitting}
            style={{
              padding: '10px 18px',
              borderRadius: '10px',
              border: '1px solid #cbd5e1',
              background: '#ffffff',
              color: '#475569',
              fontSize: '13px',
              fontWeight: 600,
              cursor: 'pointer',
            }}
          >
            Đóng
          </button>

          {!isCompleted && hasBankInfo && (
            <button
              onClick={handleConfirmRefund}
              disabled={isSubmitting}
              style={{
                padding: '10px 20px',
                borderRadius: '10px',
                border: 'none',
                background: 'linear-gradient(135deg, #ea580c 0%, #c2410c 100%)',
                color: '#ffffff',
                fontSize: '13px',
                fontWeight: 700,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                boxShadow: '0 4px 12px rgba(234, 88, 12, 0.35)',
                opacity: isSubmitting ? 0.7 : 1,
              }}
            >
              {isSubmitting ? (
                'Đang xử lý...'
              ) : (
                <>
                  <CheckCircle2 size={16} />
                  Xác nhận đã chuyển tiền thành công
                </>
              )}
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

