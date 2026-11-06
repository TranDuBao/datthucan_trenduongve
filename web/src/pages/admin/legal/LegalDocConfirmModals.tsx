import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { Modal } from '../../../components/Modal';
import { LegalDocument } from '../AdminLegalDocuments';

interface PublishModalProps {
  isOpen: boolean;
  onClose: () => void;
  target: LegalDocument | null;
  publishing: boolean;
  onConfirm: () => void;
}

export const LegalDocPublishModal: React.FC<PublishModalProps> = ({
  isOpen,
  onClose,
  target,
  publishing,
  onConfirm,
}) => {
  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Xác Nhận Xuất Bản Phiên Bản"
      maxWidth="540px"
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <div
          style={{
            padding: '14px 16px',
            borderRadius: '10px',
            backgroundColor: '#fffbeb',
            border: '1px solid #fde68a',
            color: '#92400e',
            display: 'flex',
            gap: '12px',
            alignItems: 'flex-start',
          }}
        >
          <AlertTriangle size={24} color="#d97706" style={{ flexShrink: 0, marginTop: '2px' }} />
          <div style={{ fontSize: '13px', lineHeight: 1.5 }}>
            <strong style={{ display: 'block', marginBottom: '4px', color: '#78350f' }}>
              Quy tắc phiên bản và hiệu lực trong Transaction:
            </strong>
            Khi xuất bản <strong>v{target?.soPhienBan}</strong>, phiên bản đang hiệu lực cũ (nếu có) sẽ tự động chuyển sang <strong>Đã lưu trữ</strong>.
            Phiên bản này sẽ <strong>KHÔNG</strong> thể sửa hoặc xóa sau khi xuất bản để làm bằng chứng pháp lý.
          </div>
        </div>

        <div
          style={{
            padding: '14px',
            borderRadius: '8px',
            backgroundColor: '#f8fafc',
            border: '1px solid #e2e8f0',
            fontSize: '13px',
            color: '#334155',
            display: 'flex',
            flexDirection: 'column',
            gap: '6px',
          }}
        >
          <div>
            <span style={{ fontWeight: 700, color: '#0f172a' }}>Tài liệu:</span> {target?.tieuDe}
          </div>
          <div>
            <span style={{ fontWeight: 700, color: '#0f172a' }}>Phiên bản:</span> v{target?.soPhienBan}
          </div>
          <div>
            <span style={{ fontWeight: 700, color: '#0f172a' }}>Loại:</span> {target?.loaiTaiLieu}
          </div>
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', paddingTop: '10px', borderTop: '1px solid #e2e8f0' }}>
          <button
            onClick={onClose}
            style={{
              padding: '9px 18px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              backgroundColor: '#ffffff',
              fontSize: '13px',
              fontWeight: 600,
              color: '#475569',
              cursor: 'pointer',
            }}
          >
            Hủy bỏ
          </button>
          <button
            onClick={onConfirm}
            disabled={publishing}
            style={{
              padding: '9px 22px',
              borderRadius: '8px',
              backgroundColor: '#059669',
              color: '#ffffff',
              fontSize: '13px',
              fontWeight: 700,
              cursor: publishing ? 'not-allowed' : 'pointer',
              border: 'none',
              boxShadow: '0 2px 8px rgba(5, 150, 105, 0.25)',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '8px',
            }}
          >
            {publishing ? 'Đang xuất bản...' : 'Xác Nhận Xuất Bản'}
          </button>
        </div>
      </div>
    </Modal>
  );
};

interface DeleteModalProps {
  isOpen: boolean;
  onClose: () => void;
  target: LegalDocument | null;
  deleting: boolean;
  onConfirm: () => void;
}

export const LegalDocDeleteModal: React.FC<DeleteModalProps> = ({
  isOpen,
  onClose,
  target,
  deleting,
  onConfirm,
}) => {
  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Xác Nhận Xóa Bản Nháp"
      maxWidth="480px"
    >
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <p style={{ fontSize: '13px', color: '#475569', lineHeight: 1.6 }}>
          Bạn có chắc chắn muốn xóa bản nháp <strong>v{target?.soPhienBan}</strong>: "{target?.tieuDe}"? Hành động này không thể hoàn tác.
        </p>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', paddingTop: '10px', borderTop: '1px solid #e2e8f0' }}>
          <button
            onClick={onClose}
            style={{
              padding: '9px 18px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              backgroundColor: '#ffffff',
              fontSize: '13px',
              fontWeight: 600,
              color: '#475569',
              cursor: 'pointer',
            }}
          >
            Hủy
          </button>
          <button
            onClick={onConfirm}
            disabled={deleting}
            style={{
              padding: '9px 22px',
              borderRadius: '8px',
              backgroundColor: '#dc2626',
              color: '#ffffff',
              fontSize: '13px',
              fontWeight: 700,
              cursor: deleting ? 'not-allowed' : 'pointer',
              border: 'none',
              boxShadow: '0 2px 8px rgba(220, 38, 38, 0.25)',
            }}
          >
            {deleting ? 'Đang xóa...' : 'Xác Nhận Xóa'}
          </button>
        </div>
      </div>
    </Modal>
  );
};

