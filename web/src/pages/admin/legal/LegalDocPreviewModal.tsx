import React, { useState } from 'react';
import { RefreshCw, Smartphone } from 'lucide-react';
import { Modal } from '../../../components/Modal';
import { LegalDocument } from '../AdminLegalDocuments';

interface LegalDocPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  loading: boolean;
  doc: LegalDocument | null;
  renderStatusBadge: (status: string) => React.ReactNode;
  renderTypeBadge: (type: string) => React.ReactNode;
}

export const LegalDocPreviewModal: React.FC<LegalDocPreviewModalProps> = ({
  isOpen,
  onClose,
  loading,
  doc,
  renderStatusBadge,
  renderTypeBadge,
}) => {
  const [previewMode, setPreviewMode] = useState<'text' | 'mobile'>('text');

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Xem Trước Điều Khoản & Chính Sách"
      maxWidth="820px"
    >
      {loading ? (
        <div style={{ padding: '48px 0', textAlign: 'center', color: '#94a3b8' }}>
          <RefreshCw className="animate-spin inline mr-2" size={20} />
          Đang tải nội dung văn bản...
        </div>
      ) : doc ? (
        <div>
          {/* View Mode Toggle */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
            <div style={{ display: 'flex', gap: '6px' }}>
              <button
                type="button"
                onClick={() => setPreviewMode('text')}
                style={{
                  padding: '6px 14px',
                  borderRadius: '8px',
                  fontSize: '12px',
                  fontWeight: 700,
                  cursor: 'pointer',
                  border: previewMode === 'text' ? '1px solid #fc6011' : '1px solid #e2e8f0',
                  backgroundColor: previewMode === 'text' ? '#fff7ed' : '#ffffff',
                  color: previewMode === 'text' ? '#ea580c' : '#64748b',
                }}
              >
                Dạng Văn Bản Đầy Đủ
              </button>
              <button
                type="button"
                onClick={() => setPreviewMode('mobile')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '6px 14px',
                  borderRadius: '8px',
                  fontSize: '12px',
                  fontWeight: 700,
                  cursor: 'pointer',
                  border: previewMode === 'mobile' ? '1px solid #fc6011' : '1px solid #e2e8f0',
                  backgroundColor: previewMode === 'mobile' ? '#fff7ed' : '#ffffff',
                  color: previewMode === 'mobile' ? '#ea580c' : '#64748b',
                }}
              >
                <Smartphone size={14} />
                Mô Phỏng App Mobile
              </button>
            </div>

            <div>{renderStatusBadge(doc.trangThai)}</div>
          </div>

          {previewMode === 'text' ? (
            <div
              style={{
                backgroundColor: '#f8fafc',
                borderRadius: '12px',
                border: '1px solid #e2e8f0',
                overflow: 'hidden',
              }}
            >
              <div
                style={{
                  padding: '16px 20px',
                  backgroundColor: '#ffffff',
                  borderBottom: '1px solid #e2e8f0',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                  {renderTypeBadge(doc.loaiTaiLieu)}
                  <span style={{ fontSize: '12px', fontFamily: 'monospace', fontWeight: 700, color: '#475569' }}>
                    v{doc.soPhienBan}
                  </span>
                </div>
                <h3 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a' }}>{doc.tieuDe}</h3>
                <div style={{ fontSize: '12px', color: '#64748b', marginTop: '4px' }}>
                  {doc.ngayHieuLuc
                    ? `Ngày hiệu lực: ${new Date(doc.ngayHieuLuc).toLocaleDateString('vi-VN')}`
                    : 'Trạng thái: Bản nháp dự thảo'}
                </div>
              </div>

              <div
                style={{
                  padding: '20px',
                  maxHeight: '440px',
                  overflowY: 'auto',
                  fontSize: '13px',
                  lineHeight: 1.7,
                  color: '#334155',
                  whiteSpace: 'pre-wrap',
                  fontFamily: 'inherit',
                }}
              >
                {doc.noiDung}
              </div>
            </div>
          ) : (
            /* Mobile Screen Simulator */
            <div
              style={{
                display: 'flex',
                justifyContent: 'center',
                padding: '20px',
                backgroundColor: '#f1f5f9',
                borderRadius: '14px',
              }}
            >
              <div
                style={{
                  width: '360px',
                  maxWidth: '100%',
                  backgroundColor: '#ffffff',
                  borderRadius: '28px',
                  border: '8px solid #1e293b',
                  boxShadow: '0 20px 25px -5px rgba(0,0,0,0.2)',
                  overflow: 'hidden',
                  display: 'flex',
                  flexDirection: 'column',
                  height: '540px',
                }}
              >
                {/* Phone Header */}
                <div
                  style={{
                    background: 'linear-gradient(135deg, #fc6011 0%, #ea580c 100%)',
                    color: '#ffffff',
                    padding: '16px',
                    flexShrink: 0,
                  }}
                >
                  <div style={{ fontSize: '11px', textTransform: 'uppercase', opacity: 0.85, fontWeight: 700 }}>
                    Food Route Partner
                  </div>
                  <div style={{ fontSize: '14px', fontWeight: 800, marginTop: '2px' }}>
                    {doc.tieuDe}
                  </div>
                  <div style={{ fontSize: '11px', opacity: 0.9, marginTop: '4px' }}>
                    Phiên bản: v{doc.soPhienBan} • {doc.ngayHieuLuc ? new Date(doc.ngayHieuLuc).toLocaleDateString('vi-VN') : 'Bản nháp'}
                  </div>
                </div>

                {/* Phone Scroll Content */}
                <div
                  style={{
                    flex: 1,
                    padding: '16px',
                    overflowY: 'auto',
                    fontSize: '12px',
                    lineHeight: 1.6,
                    color: '#334155',
                    whiteSpace: 'pre-wrap',
                    backgroundColor: '#ffffff',
                  }}
                >
                  {doc.noiDung}
                </div>

                {/* Bottom Consent simulation */}
                <div
                  style={{
                    padding: '12px 16px',
                    backgroundColor: '#f8fafc',
                    borderTop: '1px solid #e2e8f0',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '8px',
                  }}
                >
                  <input type="checkbox" defaultChecked readOnly style={{ accentColor: '#fc6011' }} />
                  <span style={{ fontSize: '11px', color: '#475569', fontWeight: 600 }}>
                    Tôi đã đọc và đồng ý điều khoản này
                  </span>
                </div>
              </div>
            </div>
          )}

          <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '16px' }}>
            <button
              type="button"
              onClick={onClose}
              style={{
                padding: '9px 20px',
                borderRadius: '8px',
                backgroundColor: '#f1f5f9',
                border: '1px solid #cbd5e1',
                color: '#475569',
                fontWeight: 600,
                fontSize: '13px',
                cursor: 'pointer',
              }}
            >
              Đóng
            </button>
          </div>
        </div>
      ) : null}
    </Modal>
  );
};

