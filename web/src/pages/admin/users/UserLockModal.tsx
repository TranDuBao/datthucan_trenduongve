import React from 'react';
import { Modal } from '../../../components/Modal';

interface UserLockModalProps {
  isOpen: boolean;
  onClose: () => void;
  targetUser: any;
  lockForm: {
    lockType: 'TAM_THOI' | 'VINH_VIEN' | 'MO_KHOA';
    presetDays: number;
    customDate: string;
    lyDoKhoa: string;
  };
  setLockForm: (form: any) => void;
  onSubmit: (e: React.FormEvent) => void;
  submitting: boolean;
}

export const UserLockModal: React.FC<UserLockModalProps> = ({
  isOpen,
  onClose,
  targetUser,
  lockForm,
  setLockForm,
  onSubmit,
  submitting,
}) => {
  if (!isOpen || !targetUser) return null;

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Khóa / Mở Khóa Tài Khoản">
      <form onSubmit={onSubmit}>
        <div style={{ fontSize: '14px', marginBottom: '16px', color: '#475569' }}>
          Đang chỉnh sửa trạng thái khóa cho tài khoản: <strong>@{targetUser.tenDangNhap}</strong>
        </div>

        <div className="form-group">
          <label className="form-label">Hành Động Khóa</label>
          <div style={{ display: 'flex', gap: '12px', marginTop: '6px' }}>
            <label
              style={{
                flex: 1,
                padding: '10px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                cursor: 'pointer',
                background: lockForm.lockType === 'MO_KHOA' ? '#f0fdf4' : '#fff',
                borderColor: lockForm.lockType === 'MO_KHOA' ? '#22c55e' : '#cbd5e1',
              }}
            >
              <input
                type="radio"
                name="lockType"
                checked={lockForm.lockType === 'MO_KHOA'}
                onChange={() => setLockForm({ ...lockForm, lockType: 'MO_KHOA' })}
              />{' '}
              <strong style={{ color: '#15803d' }}>🟢 Mở Khóa</strong>
            </label>

            <label
              style={{
                flex: 1,
                padding: '10px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                cursor: 'pointer',
                background: lockForm.lockType === 'TAM_THOI' ? '#fffbeb' : '#fff',
                borderColor: lockForm.lockType === 'TAM_THOI' ? '#f59e0b' : '#cbd5e1',
              }}
            >
              <input
                type="radio"
                name="lockType"
                checked={lockForm.lockType === 'TAM_THOI'}
                onChange={() => setLockForm({ ...lockForm, lockType: 'TAM_THOI' })}
              />{' '}
              <strong style={{ color: '#b45309' }}>⏳ Tạm Khóa</strong>
            </label>

            <label
              style={{
                flex: 1,
                padding: '10px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                cursor: 'pointer',
                background: lockForm.lockType === 'VINH_VIEN' ? '#fef2f2' : '#fff',
                borderColor: lockForm.lockType === 'VINH_VIEN' ? '#ef4444' : '#cbd5e1',
              }}
            >
              <input
                type="radio"
                name="lockType"
                checked={lockForm.lockType === 'VINH_VIEN'}
                onChange={() => setLockForm({ ...lockForm, lockType: 'VINH_VIEN' })}
              />{' '}
              <strong style={{ color: '#b91c1c' }}>🔒 Khóa Vĩnh Viễn</strong>
            </label>
          </div>
        </div>

        {lockForm.lockType === 'TAM_THOI' && (
          <div
            style={{
              background: '#fffbeb',
              padding: '14px',
              borderRadius: '10px',
              border: '1px solid #fef3c7',
              marginBottom: '16px',
            }}
          >
            <label className="form-label" style={{ color: '#92400e' }}>Thời Gian Tạm Khóa</label>
            <div style={{ display: 'flex', gap: '8px', marginBottom: '12px' }}>
              {[3, 7, 14, 30].map((d) => (
                <button
                  key={d}
                  type="button"
                  className={`btn btn-sm ${lockForm.presetDays === d && !lockForm.customDate ? 'btn-primary' : 'btn-outline'}`}
                  onClick={() => setLockForm({ ...lockForm, presetDays: d, customDate: '' })}
                >
                  {d} ngày
                </button>
              ))}
            </div>
            <div>
              <label className="form-label" style={{ fontSize: '12px', color: '#78350f' }}>
                Hoặc chọn Ngày hết hạn khóa cụ thể:
              </label>
              <input
                type="date"
                className="form-control"
                value={lockForm.customDate}
                onChange={(e) => setLockForm({ ...lockForm, customDate: e.target.value })}
              />
            </div>
          </div>
        )}

        {(lockForm.lockType === 'TAM_THOI' || lockForm.lockType === 'VINH_VIEN') && (
          <div className="form-group">
            <label className="form-label">Lý Do Khóa Tài Khoản</label>
            <textarea
              className="form-control"
              rows={3}
              placeholder="VD: Vi phạm chính sách đặt hàng, spam đơn, yêu cầu chủ tài khoản..."
              value={lockForm.lyDoKhoa}
              onChange={(e) => setLockForm({ ...lockForm, lyDoKhoa: e.target.value })}
            />
          </div>
        )}

        <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
          <button type="button" className="btn btn-outline" onClick={onClose}>Hủy</button>
          <button type="submit" className="btn btn-primary" disabled={submitting}>
            {submitting ? <div className="loading-spinner" /> : 'Xác Nhận Khóa'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
