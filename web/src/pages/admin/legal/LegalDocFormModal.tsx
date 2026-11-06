import React from 'react';
import { Modal } from '../../../components/Modal';

interface FormData {
  loaiTaiLieu: string;
  soPhienBan: string;
  tieuDe: string;
  noiDung: string;
}

interface LegalDocFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingDocId: number | null;
  formData: FormData;
  setFormData: React.Dispatch<React.SetStateAction<FormData>>;
  formError: string;
  saving: boolean;
  onSave: (e: React.FormEvent) => void;
}

export const LegalDocFormModal: React.FC<LegalDocFormModalProps> = ({
  isOpen,
  onClose,
  editingDocId,
  formData,
  setFormData,
  formError,
  saving,
  onSave,
}) => {
  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editingDocId ? `Chỉnh Sửa Bản Nháp v${formData.soPhienBan}` : 'Tạo Bản Nháp Điều Khoản / Chính Sách'}
      maxWidth="760px"
    >
      <form onSubmit={onSave} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        {formError && (
          <div
            style={{
              padding: '10px 14px',
              borderRadius: '8px',
              backgroundColor: '#fef2f2',
              border: '1px solid #fecaca',
              color: '#b91c1c',
              fontSize: '13px',
              fontWeight: 500,
            }}
          >
            {formError}
          </div>
        )}

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px' }}>
          <div>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
              Loại tài liệu *
            </label>
            <select
              disabled={!!editingDocId}
              value={formData.loaiTaiLieu}
              onChange={(e) => setFormData({ ...formData, loaiTaiLieu: e.target.value })}
              style={{
                width: '100%',
                padding: '9px 12px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                backgroundColor: editingDocId ? '#f1f5f9' : '#ffffff',
                color: '#0f172a',
              }}
            >
              <option value="DIEU_KHOAN_DOI_TAC">Điều khoản đối tác cửa hàng</option>
              <option value="CHINH_SACH_DU_LIEU">Chính sách dữ liệu cá nhân</option>
            </select>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
              Số phiên bản * (ví dụ: 1.0, 1.1)
            </label>
            <input
              type="text"
              placeholder="vd: 1.1"
              value={formData.soPhienBan}
              onChange={(e) => setFormData({ ...formData, soPhienBan: e.target.value })}
              style={{
                width: '100%',
                padding: '9px 12px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                backgroundColor: '#ffffff',
                color: '#0f172a',
              }}
            />
          </div>
        </div>

        <div>
          <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
            Tiêu đề tài liệu *
          </label>
          <input
            type="text"
            placeholder="vd: Điều khoản & Điều kiện Dịch vụ Đối tác Cửa hàng Food Route"
            value={formData.tieuDe}
            onChange={(e) => setFormData({ ...formData, tieuDe: e.target.value })}
            style={{
              width: '100%',
              padding: '9px 12px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '13px',
              backgroundColor: '#ffffff',
              color: '#0f172a',
            }}
          />
        </div>

        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
            <label style={{ fontSize: '12px', fontWeight: 700, color: '#475569' }}>
              Nội dung toàn văn (Văn bản thuần, chống chèn mã XSS) *
            </label>
            <span style={{ fontSize: '12px', color: '#94a3b8' }}>
              {formData.noiDung.length} ký tự
            </span>
          </div>
          <textarea
            rows={12}
            placeholder="Nhập nội dung các điều khoản cam kết, trách nhiệm, mức phí, xử lý vi phạm..."
            value={formData.noiDung}
            onChange={(e) => setFormData({ ...formData, noiDung: e.target.value })}
            style={{
              width: '100%',
              padding: '12px',
              fontFamily: 'monospace',
              fontSize: '12px',
              lineHeight: 1.6,
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              backgroundColor: '#f8fafc',
              color: '#0f172a',
              resize: 'vertical',
            }}
          />
        </div>

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', paddingTop: '12px', borderTop: '1px solid #e2e8f0' }}>
          <button
            type="button"
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
            type="submit"
            disabled={saving}
            style={{
              padding: '9px 22px',
              borderRadius: '8px',
              backgroundColor: '#fc6011',
              color: '#ffffff',
              fontSize: '13px',
              fontWeight: 700,
              cursor: saving ? 'not-allowed' : 'pointer',
              border: 'none',
              boxShadow: '0 2px 8px rgba(252, 96, 17, 0.25)',
            }}
          >
            {saving ? 'Đang lưu...' : editingDocId ? 'Cập Nhật Bản Nháp' : 'Lưu Bản Nháp'}
          </button>
        </div>
      </form>
    </Modal>
  );
};

