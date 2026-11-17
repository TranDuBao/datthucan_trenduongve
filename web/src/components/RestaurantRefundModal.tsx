import React, { useState } from 'react';
import {
  X,
  QrCode,
  Copy,
  Check,
  AlertCircle,
  CheckCircle2,
  Building,
  User,
  CreditCard,
  Upload,
  Eye,
  Clock,
  AlertTriangle,
} from 'lucide-react';
import { apiFetch, API_HOST } from '../api/apiClient';

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

  const [overrideBankCode, setOverrideBankCode] = useState<string | null>(null);
  const [isEditingBank, setIsEditingBank] = useState(false);

  const [receiptImage, setReceiptImage] = useState<string>('');
  const [isUploadingReceipt, setIsUploadingReceipt] = useState(false);
  const [bankTxCode, setBankTxCode] = useState('');
  const [showFullReceipt, setShowFullReceipt] = useState(false);
  const [receiptUrlToView, setReceiptUrlToView] = useState<string>('');

  if (!isOpen || !order) return null;

  const refund = order.refundInfo || order.refund || {};
  const maHoanTien = refund.maHoanTien || refund.id;
  const amount = Number(refund.soTienHoan || order.tongTien || 0);
  const rawBankName = (refund.nganHangNhan || '').trim();
  const accountNumber = (refund.soTaiKhoanNhan || '').trim();
  const accountHolder = (refund.tenChuTaiKhoanNhan || order.tenKhachHang || '').trim();

  const isCompleted = refund.trangThaiHoanTien === 'HOAN_TIEN_THANH_CONG';
  const isWaitingCustomer = refund.trangThaiHoanTien === 'CHO_KHACH_XAC_NHAN';
  const isDisputed = refund.trangThaiHoanTien === 'TRANH_CHAP';
  const currentReceipt = receiptImage || refund.anhBienLai || '';
  const hasBankInfo = (rawBankName.length > 0 || overrideBankCode !== null) && accountNumber.length > 0;

  const getFullImageUrl = (path?: string) => {
    if (!path) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return `${API_HOST}${path.startsWith('/') ? '' : '/'}${path}`;
  };

  const POPULAR_VIETQR_BANKS = [
    { code: 'ICB', bin: '970415', shortName: 'VietinBank', name: 'Ngân hàng TMCP Công thương Việt Nam' },
    { code: 'VCB', bin: '970436', shortName: 'Vietcombank', name: 'Ngân hàng TMCP Ngoại Thương Việt Nam' },
    { code: 'BIDV', bin: '970418', shortName: 'BIDV', name: 'Ngân hàng TMCP Đầu tư & Phát triển Việt Nam' },
    { code: 'VBA', bin: '970405', shortName: 'Agribank', name: 'Ngân hàng Nông nghiệp & PTNT Việt Nam' },
    { code: 'MB', bin: '970422', shortName: 'MBBank', name: 'Ngân hàng TMCP Quân đội' },
    { code: 'TCB', bin: '970407', shortName: 'Techcombank', name: 'Ngân hàng TMCP Kỹ thương Việt Nam' },
    { code: 'ACB', bin: '970416', shortName: 'ACB', name: 'Ngân hàng TMCP Á Châu' },
    { code: 'VPB', bin: '970432', shortName: 'VPBank', name: 'Ngân hàng TMCP Việt Nam Thịnh Vượng' },
    { code: 'TPB', bin: '970423', shortName: 'TPBank', name: 'Ngân hàng TMCP Tiên Phong' },
    { code: 'STB', bin: '970403', shortName: 'Sacombank', name: 'Ngân hàng TMCP Sài Gòn Thương Tín' },
    { code: 'HDB', bin: '970437', shortName: 'HDBank', name: 'Ngân hàng TMCP Phát triển TP.HCM' },
    { code: 'OCB', bin: '970448', shortName: 'OCB', name: 'Ngân hàng TMCP Phương Đông' },
    { code: 'VIB', bin: '970441', shortName: 'VIB', name: 'Ngân hàng TMCP Quốc tế Việt Nam' },
    { code: 'SHB', bin: '970443', shortName: 'SHB', name: 'Ngân hàng TMCP Sài Gòn - Hà Nội' },
    { code: 'MSB', bin: '970426', shortName: 'MSB', name: 'Ngân hàng TMCP Hàng Hải' },
    { code: 'CAKE', bin: '546034', shortName: 'CAKE', name: 'TMCP Việt Nam Thịnh Vượng - Số CAKE' },
    { code: 'TIMO', bin: '963388', shortName: 'Timo', name: 'Ngân hàng số Timo by Ban Viet Bank' },
    { code: 'momo', bin: '971025', shortName: 'MoMo', name: 'Ví điện tử MoMo' },
    { code: 'ZALOPAY', bin: '971101', shortName: 'ZaloPay', name: 'Ví điện tử ZaloPay' },
  ];

  const resolveBank = (b: string) => {
    if (!b) return POPULAR_VIETQR_BANKS[0];
    const q = b.toUpperCase().replace(/[^A-Z0-9]/g, '');
    if (q === 'CTG' || q.includes('VIETINBANK') || q === '970415' || q === 'ICB' || q === '623817') {
      return POPULAR_VIETQR_BANKS[0]; // VietinBank
    }
    for (const item of POPULAR_VIETQR_BANKS) {
      if (item.code.toUpperCase() === q || item.bin === q || item.shortName.toUpperCase() === q) {
        return item;
      }
    }
    for (const item of POPULAR_VIETQR_BANKS) {
      if (item.shortName.toUpperCase().includes(q) || item.name.toUpperCase().includes(q)) {
        return item;
      }
    }
    return { code: q || 'ICB', bin: '', shortName: b, name: b };
  };

  const activeBank = resolveBank(overrideBankCode || rawBankName);
  const cleanAcc = accountNumber.replace(/[^0-9A-Za-z]/g, '');

  // VietQR QuickLink standard format
  const transferContent = `Hoan tien don #${order.maDonHang}`;
  const qrUrl = hasBankInfo
    ? `https://img.vietqr.io/image/${activeBank.code}-${cleanAcc}-compact2.png?amount=${Math.round(amount)}&addInfo=${encodeURIComponent(transferContent)}&accountName=${encodeURIComponent(accountHolder)}`
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

  const handleReceiptFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (file.size > 15 * 1024 * 1024) {
      setErrorMsg('Ảnh biên lai không được vượt quá 15MB');
      return;
    }

    setIsUploadingReceipt(true);
    setErrorMsg('');

    const reader = new FileReader();
    reader.onerror = () => {
      setErrorMsg('Không thể đọc tệp ảnh từ thiết bị');
      setIsUploadingReceipt(false);
    };

    reader.onload = () => {
      const rawBase64 = reader.result as string;
      const img = new Image();
      img.onload = async () => {
        try {
          // Auto compress & resize with canvas if dimensions exceed 1600px
          const maxDim = 1600;
          let w = img.width;
          let h = img.height;
          if (w > maxDim || h > maxDim) {
            if (w > h) {
              h = Math.round((h * maxDim) / w);
              w = maxDim;
            } else {
              w = Math.round((w * maxDim) / h);
              h = maxDim;
            }
          }
          const canvas = document.createElement('canvas');
          canvas.width = w;
          canvas.height = h;
          const ctx = canvas.getContext('2d');
          if (!ctx) throw new Error('Trình duyệt không hỗ trợ canvas');
          ctx.drawImage(img, 0, 0, w, h);
          const compressedBase64 = canvas.toDataURL('image/jpeg', 0.88);

          const res = await apiFetch<{ url: string }>('/upload', {
            method: 'POST',
            body: JSON.stringify({ image: compressedBase64 }),
          });

          const url = res.url || (res as any).data?.url;
          if (url) {
            setReceiptImage(url);
          } else {
            setErrorMsg('Không nhận được đường dẫn ảnh từ máy chủ');
          }
        } catch (err: any) {
          setErrorMsg(err.message || 'Lỗi tải ảnh biên lai lên máy chủ');
        } finally {
          setIsUploadingReceipt(false);
        }
      };
      img.onerror = () => {
        setErrorMsg('Tệp hình ảnh không hợp lệ hoặc bị lỗi');
        setIsUploadingReceipt(false);
      };
      img.src = rawBase64;
    };
    reader.readAsDataURL(file);
  };

  const handleConfirmRefund = async () => {
    if (!maHoanTien) {
      setErrorMsg('Không tìm thấy mã yêu cầu hoàn tiền');
      return;
    }
    const activeReceipt = receiptImage || refund.anhBienLai;
    if (!activeReceipt) {
      setErrorMsg('Vui lòng tải lên ảnh chụp biên lai chuyển tiền thành công trước khi gửi cho khách');
      return;
    }
    try {
      setIsSubmitting(true);
      setErrorMsg('');
      const res = await apiFetch<any>(`/refunds/${maHoanTien}/status`, {
        method: 'PATCH',
        body: JSON.stringify({
          trangThai: 'CHO_KHACH_XAC_NHAN',
          anhBienLai: activeReceipt,
          maGiaoDichNganHang: bankTxCode.trim() || undefined,
          ghiChu: 'Cửa hàng đã quét VietQR chuyển khoản và gửi biên lai đối soát',
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
                Khách hàng đã xác nhận nhận đủ {amount.toLocaleString('vi-VN')} đ về tài khoản ngân hàng.
              </div>
              {currentReceipt && (
                <div style={{ marginTop: '14px' }}>
                  <button
                    type="button"
                    onClick={() => {
                      setReceiptUrlToView(getFullImageUrl(currentReceipt));
                      setShowFullReceipt(true);
                    }}
                    style={{
                      background: '#ffffff',
                      border: '1px solid #86efac',
                      borderRadius: '8px',
                      padding: '7px 14px',
                      fontSize: '12px',
                      fontWeight: 700,
                      color: '#166534',
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '6px',
                    }}
                  >
                    <Eye size={14} /> Xem ảnh biên lai chuyển tiền
                  </button>
                </div>
              )}
            </div>
          ) : isWaitingCustomer ? (
            <div
              style={{
                background: '#f0f9ff',
                border: '1.5px solid #bae6fd',
                borderRadius: '14px',
                padding: '22px',
                textAlign: 'center',
                marginBottom: '16px',
              }}
            >
              <Clock size={42} color="#0284c7" style={{ margin: '0 auto 8px' }} />
              <div style={{ fontSize: '16px', fontWeight: 800, color: '#0369a1' }}>
                Đã gửi biên lai - Chờ khách xác nhận
              </div>
              <div style={{ fontSize: '12.5px', color: '#0369a1', marginTop: '6px', lineHeight: 1.5 }}>
                Quán đã hoàn tiền và tải lên biên lai chuyển khoản. Hệ thống đã gửi thông báo đến ứng dụng của khách hàng để đối soát và bấm xác nhận nhận tiền.
              </div>
              {currentReceipt && (
                <div style={{ marginTop: '14px' }}>
                  <button
                    type="button"
                    onClick={() => {
                      setReceiptUrlToView(getFullImageUrl(currentReceipt));
                      setShowFullReceipt(true);
                    }}
                    style={{
                      background: '#ffffff',
                      border: '1px solid #7dd3fc',
                      borderRadius: '8px',
                      padding: '7px 14px',
                      fontSize: '12px',
                      fontWeight: 700,
                      color: '#0284c7',
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '6px',
                    }}
                  >
                    <Eye size={14} /> Xem lại biên lai đã gửi
                  </button>
                </div>
              )}
            </div>
          ) : isDisputed ? (
            <div
              style={{
                background: '#fef2f2',
                border: '1.5px solid #fecaca',
                borderRadius: '14px',
                padding: '18px',
                marginBottom: '16px',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#b91c1c', fontWeight: 800, fontSize: '15px' }}>
                <AlertTriangle size={20} color="#dc2626" /> Khách hàng khiếu nại chưa nhận được tiền!
              </div>
              <div style={{ marginTop: '8px', padding: '10px 12px', background: '#ffffff', borderRadius: '8px', border: '1px solid #fecaca', fontSize: '13px', color: '#7f1d1d' }}>
                <strong>Lý do khiếu nại:</strong> {refund.lyDoKhieuNai || 'Khách hàng báo tài khoản chưa nhận được tiền hoàn.'}
              </div>
              <div style={{ marginTop: '8px', fontSize: '12px', color: '#991b1b', lineHeight: 1.5 }}>
                Vui lòng kiểm tra lại tài khoản trích tiền hoặc quét lại mã VietQR bên dưới để chuyển khoản đúng STK. Sau đó tải lên ảnh biên lai mới để gửi lại cho khách.
              </div>
              {currentReceipt && (
                <div style={{ marginTop: '10px' }}>
                  <button
                    type="button"
                    onClick={() => {
                      setReceiptUrlToView(getFullImageUrl(currentReceipt));
                      setShowFullReceipt(true);
                    }}
                    style={{
                      background: '#ffffff',
                      border: '1px solid #fca5a5',
                      borderRadius: '8px',
                      padding: '6px 12px',
                      fontSize: '12px',
                      fontWeight: 700,
                      color: '#b91c1c',
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '6px',
                    }}
                  >
                    <Eye size={14} /> Xem biên lai cũ
                  </button>
                </div>
              )}
            </div>
          ) : null}

          {!isCompleted && !isWaitingCustomer && !hasBankInfo ? (
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
          ) : (!isCompleted && (!isWaitingCustomer || isDisputed)) && (
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
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', fontSize: '13px', flexWrap: 'wrap', gap: '6px' }}>
                    <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <Building size={14} color="#94a3b8" /> Ngân hàng:
                    </span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <img
                        src={`https://cdn.vietqr.io/img/${activeBank.code}.png`}
                        alt={activeBank.shortName}
                        onError={(e) => { (e.target as HTMLElement).style.display = 'none'; }}
                        style={{ width: '22px', height: '22px', objectFit: 'contain', background: '#fff', borderRadius: '4px', border: '1px solid #e2e8f0', padding: '1px' }}
                      />
                      <strong style={{ color: '#0f172a' }}>{activeBank.shortName} ({activeBank.code})</strong>
                      <button
                        type="button"
                        onClick={() => setIsEditingBank(!isEditingBank)}
                        style={{
                          background: '#fff',
                          border: '1px solid #cbd5e1',
                          borderRadius: '6px',
                          padding: '2px 8px',
                          fontSize: '11px',
                          fontWeight: 700,
                          color: '#ea580c',
                          cursor: 'pointer',
                        }}
                      >
                        {isEditingBank ? 'Đóng' : 'Đổi ngân hàng'}
                      </button>
                    </div>
                  </div>

                  {isEditingBank && (
                    <div style={{ padding: '8px 10px', background: '#fff', borderRadius: '8px', border: '1px solid #fed7aa', marginTop: '4px' }}>
                      <div style={{ fontSize: '11px', fontWeight: 600, color: '#9a3412', marginBottom: '4px' }}>
                        Chọn ngân hàng thụ hưởng đúng để hiển thị mã VietQR:
                      </div>
                      <select
                        value={activeBank.code}
                        onChange={(e) => {
                          setOverrideBankCode(e.target.value);
                          setQrImgError(false);
                        }}
                        style={{
                          width: '100%',
                          padding: '6px 10px',
                          borderRadius: '6px',
                          border: '1px solid #cbd5e1',
                          fontSize: '12.5px',
                          fontWeight: 600,
                          color: '#0f172a',
                          background: '#fff',
                          cursor: 'pointer',
                        }}
                      >
                        {POPULAR_VIETQR_BANKS.map((b) => (
                          <option key={b.code} value={b.code}>
                            {b.shortName} ({b.code}) - {b.name}
                          </option>
                        ))}
                      </select>
                    </div>
                  )}

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
                    <div style={{ padding: '20px 16px', textAlign: 'center', color: '#64748b' }}>
                      <p style={{ margin: '0 0 6px 0', fontSize: '13px', fontWeight: 700, color: '#b45309' }}>
                        ⚠️ Không thể tải ảnh mã QR với ngân hàng "{activeBank.shortName}"
                      </p>
                      <p style={{ margin: '0 0 12px 0', fontSize: '12px' }}>
                        Vui lòng thử chọn lại ngân hàng thụ hưởng khác hoặc chuyển khoản thủ công theo STK.
                      </p>
                      <button
                        type="button"
                        onClick={() => {
                          setIsEditingBank(true);
                          setQrImgError(false);
                        }}
                        style={{
                          background: '#ea580c',
                          color: '#ffffff',
                          border: 'none',
                          borderRadius: '8px',
                          padding: '6px 14px',
                          fontSize: '12px',
                          fontWeight: 700,
                          cursor: 'pointer',
                        }}
                      >
                        Chọn lại ngân hàng thụ hưởng
                      </button>
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

              {/* Receipt Upload Box */}
              <div
                style={{
                  marginTop: '18px',
                  padding: '16px',
                  background: '#faf5ff',
                  border: '1.5px dashed #c084fc',
                  borderRadius: '14px',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
                  <label style={{ fontSize: '13px', fontWeight: 800, color: '#581c87', display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Upload size={15} color="#9333ea" /> Ảnh biên lai chuyển tiền <span style={{ color: '#dc2626' }}>*</span>
                  </label>
                  {receiptImage && (
                    <button
                      type="button"
                      onClick={() => setReceiptImage('')}
                      style={{ background: 'none', border: 'none', color: '#9333ea', fontSize: '11.5px', fontWeight: 700, cursor: 'pointer' }}
                    >
                      Đổi ảnh khác
                    </button>
                  )}
                </div>
                <div style={{ fontSize: '11.5px', color: '#6b21a8', marginBottom: '10px', lineHeight: 1.4 }}>
                  Sau khi quét mã VietQR và chuyển tiền thành công, chụp màn hình biên lai và tải lên đây để làm bằng chứng gửi khách hàng đối soát.
                </div>

                {receiptImage ? (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px', background: '#ffffff', padding: '8px 12px', borderRadius: '10px', border: '1px solid #e9d5ff' }}>
                    <img
                      src={getFullImageUrl(receiptImage)}
                      alt="Biên lai"
                      style={{ width: '60px', height: '60px', objectFit: 'cover', borderRadius: '6px', border: '1px solid #cbd5e1', cursor: 'pointer' }}
                      onClick={() => {
                        setReceiptUrlToView(getFullImageUrl(receiptImage));
                        setShowFullReceipt(true);
                      }}
                    />
                    <div style={{ flex: 1 }}>
                      <div style={{ fontSize: '12px', fontWeight: 700, color: '#16a34a', display: 'flex', alignItems: 'center', gap: '4px' }}>
                        <CheckCircle2 size={14} /> Đã tải lên ảnh biên lai
                      </div>
                      <button
                        type="button"
                        onClick={() => {
                          setReceiptUrlToView(getFullImageUrl(receiptImage));
                          setShowFullReceipt(true);
                        }}
                        style={{ background: 'none', border: 'none', padding: 0, color: '#7c3aed', fontSize: '11.5px', fontWeight: 600, cursor: 'pointer', textDecoration: 'underline', marginTop: '2px' }}
                      >
                        Nhấn để xem ảnh phóng to
                      </button>
                    </div>
                  </div>
                ) : (
                  <div>
                    <label
                      style={{
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        justifyContent: 'center',
                        padding: '16px',
                        border: '1.5px dashed #a855f7',
                        borderRadius: '10px',
                        background: '#ffffff',
                        cursor: isUploadingReceipt ? 'wait' : 'pointer',
                        transition: 'all 0.2s',
                      }}
                    >
                      <input
                        type="file"
                        accept="image/*"
                        disabled={isUploadingReceipt}
                        onChange={handleReceiptFileChange}
                        style={{ display: 'none' }}
                      />
                      {isUploadingReceipt ? (
                        <div style={{ fontSize: '13px', fontWeight: 700, color: '#7c3aed', display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <Clock size={16} /> Đang tải ảnh lên...
                        </div>
                      ) : (
                        <>
                          <Upload size={22} color="#9333ea" style={{ marginBottom: '6px' }} />
                          <div style={{ fontSize: '13px', fontWeight: 700, color: '#7c3aed' }}>
                            Bấm vào đây để tải ảnh biên lai
                          </div>
                          <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '2px' }}>
                            Định dạng JPG, PNG (Tối đa 10MB)
                          </div>
                        </>
                      )}
                    </label>
                  </div>
                )}

                {/* Optional Bank Transaction Reference Code */}
                <div style={{ marginTop: '12px' }}>
                  <label style={{ display: 'block', fontSize: '11.5px', fontWeight: 600, color: '#581c87', marginBottom: '4px' }}>
                    Mã giao dịch / Bút toán ngân hàng (Không bắt buộc):
                  </label>
                  <input
                    type="text"
                    value={bankTxCode}
                    onChange={(e) => setBankTxCode(e.target.value)}
                    placeholder="Ví dụ: FT24098192847291..."
                    style={{
                      width: '100%',
                      padding: '7px 10px',
                      borderRadius: '8px',
                      border: '1px solid #d8b4fe',
                      fontSize: '12px',
                      background: '#ffffff',
                      boxSizing: 'border-box',
                    }}
                  />
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
            disabled={isSubmitting || isUploadingReceipt}
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

          {!isCompleted && !isWaitingCustomer && hasBankInfo && (
            <button
              onClick={handleConfirmRefund}
              disabled={isSubmitting || isUploadingReceipt}
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
                opacity: isSubmitting || isUploadingReceipt ? 0.7 : 1,
              }}
            >
              {isSubmitting ? (
                'Đang xử lý...'
              ) : (
                <>
                  <CheckCircle2 size={16} />
                  {isDisputed ? 'Gửi lại biên lai cho khách' : 'Xác nhận đã chuyển & Gửi biên lai'}
                </>
              )}
            </button>
          )}
        </div>
      </div>

      {/* Lightbox / Full-size Receipt View Modal */}
      {showFullReceipt && receiptUrlToView && (
        <div
          style={{
            position: 'fixed',
            inset: 0,
            background: 'rgba(0, 0, 0, 0.85)',
            zIndex: 10000,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '16px',
          }}
          onClick={() => setShowFullReceipt(false)}
        >
          <div
            style={{
              position: 'relative',
              maxWidth: '92vw',
              maxHeight: '92vh',
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
            }}
            onClick={(e) => e.stopPropagation()}
          >
            <button
              type="button"
              onClick={() => setShowFullReceipt(false)}
              style={{
                position: 'absolute',
                top: '-40px',
                right: '0',
                background: '#ffffff',
                border: 'none',
                borderRadius: '50%',
                width: '32px',
                height: '32px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                cursor: 'pointer',
                color: '#0f172a',
              }}
            >
              <X size={18} />
            </button>
            <img
              src={receiptUrlToView}
              alt="Biên lai chuyển tiền"
              style={{
                maxWidth: '100%',
                maxHeight: '85vh',
                objectFit: 'contain',
                borderRadius: '12px',
                boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.5)',
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
};

