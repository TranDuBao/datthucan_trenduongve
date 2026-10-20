import React, { useState } from 'react';
import { X } from 'lucide-react';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  maxWidth?: string;
  children: React.ReactNode;
}

export const Modal: React.FC<ModalProps> = ({ isOpen, onClose, title, maxWidth, children }) => {
  const [mouseDownTarget, setMouseDownTarget] = useState<EventTarget | null>(null);

  if (!isOpen) return null;

  return (
    <div
      className="modal-backdrop"
      onMouseDown={(e) => setMouseDownTarget(e.target)}
      onClick={(e) => {
        if (e.target === e.currentTarget && mouseDownTarget === e.currentTarget) {
          onClose();
        }
      }}
    >
      <div
        className="modal-content"
        onClick={(e) => e.stopPropagation()}
        style={maxWidth ? { maxWidth } : undefined}
      >
        <div className="modal-header">
          <div style={{ fontSize: '16px', fontWeight: 700, color: '#0f172a' }}>{title}</div>
          <button onClick={onClose} style={{ color: '#64748b', background: 'none', border: 'none', cursor: 'pointer', padding: '4px' }}>
            <X size={20} />
          </button>
        </div>
        <div className="modal-body">{children}</div>
      </div>
    </div>
  );
};
