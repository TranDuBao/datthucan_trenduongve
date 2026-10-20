import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { Shield, Store } from 'lucide-react';
import { apiFetch } from '../api/apiClient';
import { NotificationBell } from './NotificationBell';

export const Header: React.FC = () => {
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
      <div style={{ fontSize: '13px', fontWeight: 600, color: '#64748b' }}>
        Hệ Thống Quản Lý Đặt Thức Ăn Tiện Đường Ghé Lấy
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: '#f1f5f9', padding: '6px 12px', borderRadius: '20px' }}>
          {isAdmin ? <Shield size={16} color="#fc6011" /> : <Store size={16} color="#3b82f6" />}
          <span className={`badge ${isAdmin ? 'badge-primary' : 'badge-info'}`}>
            {user?.role}
          </span>
        </div>

        <div style={{ textAlign: 'right' }}>
          <div style={{ fontSize: '13px', fontWeight: 700, color: '#0f172a' }}>{displayName}</div>
          <div style={{ fontSize: '11px', color: '#64748b' }}>{user?.username || user?.email}</div>
        </div>

        <NotificationBell />
      </div>
    </header>
  );
};
