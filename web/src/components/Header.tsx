import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { Shield, Store, Menu } from 'lucide-react';
import { apiFetch } from '../api/apiClient';
import { NotificationBell } from './NotificationBell';

interface HeaderProps {
  onToggleSidebar?: () => void;
}

export const Header: React.FC<HeaderProps> = ({ onToggleSidebar }) => {
  const { user } = useAuth();
  const isAdmin = user?.role === 'ADMIN';
  const [storeName, setStoreName] = useState<string>('');

  useEffect(() => {
    if (!isAdmin && user) {
      apiFetch<any>('/restaurant/profile')
        .then((res) => {
          if (res?.data?.tenQuan) {
            setStoreName(res.data.tenQuan);
          }
        })
        .catch(() => {});
    }
  }, [isAdmin, user]);

  const displayName = storeName || user?.fullName || user?.username || 'Nhà hàng';

  return (
    <header className="top-navbar">
      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
        <button
          onClick={onToggleSidebar}
          className="touch-target mobile-menu-btn"
          aria-label="Mở menu quản trị"
          style={{
            border: 'none',
            background: 'transparent',
            cursor: 'pointer',
            padding: '6px',
            color: '#0f172a',
            display: 'none',
          }}
        >
          <Menu size={24} />
        </button>
        <div className="header-system-title" style={{ fontSize: '13px', fontWeight: 600, color: '#64748b' }}>
          Hệ Thống Quản Lý Đặt Thức Ăn Tiện Đường Ghé Lấy
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', background: '#f1f5f9', padding: '5px 10px', borderRadius: '20px' }}>
          {isAdmin ? <Shield size={15} color="#fc6011" /> : <Store size={15} color="#3b82f6" />}
          <span className={`badge ${isAdmin ? 'badge-primary' : 'badge-info'}`} style={{ padding: '2px 6px', fontSize: '10px' }}>
            {user?.role}
          </span>
        </div>

        <div className="header-user-info" style={{ textAlign: 'right' }}>
          <div style={{ fontSize: '12px', fontWeight: 700, color: '#0f172a', maxWidth: '140px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{displayName}</div>
          <div style={{ fontSize: '10px', color: '#64748b', maxWidth: '140px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{user?.username || user?.email}</div>
        </div>

        <NotificationBell />
      </div>
    </header>
  );
};
