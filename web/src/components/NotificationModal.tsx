import React from 'react';
import { Modal } from './Modal';
import { CheckCircle2, AlertCircle, AlertTriangle, Info } from 'lucide-react';

export interface NotificationModalProps {
  isOpen: boolean;
  onClose: () => void;
  type?: 'success' | 'error' | 'warning' | 'info';
  title?: string;
  message?: string | string[];
}

export const NotificationModal: React.FC<NotificationModalProps> = ({
  isOpen,
  onClose,
  type = 'info',
  title,
  message,
}) => {
  if (!isOpen) return null;

  const getConfig = () => {
    switch (type) {
      case 'success':
        return {
          icon: <CheckCircle2 size={44} color="#10b981" />,
          bgColor: '#ecfdf5',
          borderColor: '#a7f3d0',
          titleColor: '#065f46',
          defaultTitle: 'Thành Công!',
        };
      case 'error':
        return {
          icon: <AlertCircle size={44} color="#ef4444" />,
          bgColor: '#fef2f2',
          borderColor: '#fca5a5',
          titleColor: '#991b1b',
          defaultTitle: 'Đã Xảy Ra Lỗi!',
        };
      case 'warning':
        return {
          icon: <AlertTriangle size={44} color="#f59e0b" />,
          bgColor: '#fffbe8',
          borderColor: '#fde68a',
          titleColor: '#92400e',
          defaultTitle: 'Thông Báo Cần Chú Ý!',
        };
      default:
        return {
          icon: <Info size={44} color="#3b82f6" />,
          bgColor: '#eff6ff',
          borderColor: '#bfdbfe',
          titleColor: '#1e40af',
          defaultTitle: 'Thông Báo',
        };
    }
  };

  const config = getConfig();

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="" maxWidth="440px">
      <div style={{ textAlign: 'center', padding: '12px 8px' }}>
        <div style={{ marginBottom: '14px', display: 'flex', justifyContent: 'center' }}>
          {config.icon}
        </div>

        <h3 style={{ fontSize: '18px', fontWeight: 800, color: config.titleColor, marginBottom: '10px' }}>
          {title || config.defaultTitle}
        </h3>

        <div style={{ fontSize: '14px', color: '#475569', lineHeight: '1.6', marginBottom: '22px' }}>
          {Array.isArray(message) ? (
            <div style={{ background: '#f8fafc', padding: '12px 16px', borderRadius: '8px', border: '1px solid #e2e8f0', textAlign: 'left' }}>
              <div style={{ fontWeight: 600, marginBottom: '6px', color: '#334155' }}>Vui lòng kiểm tra lại:</div>
              <ul style={{ margin: 0, paddingLeft: '18px', color: '#dc2626' }}>
                {message.map((msg, i) => (
                  <li key={i} style={{ marginBottom: '4px' }}>{msg}</li>
                ))}
              </ul>
            </div>
          ) : (
            message
          )}
        </div>

        <button
          className="btn btn-primary"
          style={{ width: '100%', justifyContent: 'center', padding: '10px 16px', fontSize: '14px', fontWeight: 700 }}
          onClick={onClose}
        >
          Xác Nhận
        </button>
      </div>
    </Modal>
  );
};
