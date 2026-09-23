import React from 'react';
import { useAuth } from '../context/AuthContext';
import { User, Shield, Store } from 'lucide-react';

export const Header: React.FC = () => {
  const { user } = useAuth();
  const isAdmin = user?.role === 'ADMIN';

  return (
    <header className="top-navbar">
      <div style={{ fontSize: '13px', fontWeight: 600, color: '#64748b' }}>
        Hệ Thống Quản Lý Đặt Thức Ăn Tiện Đường Ghé Lấy
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: '#f1f5f9', padding: '6px 12px', borderRadius: '20px' }}>
          {isAdmin ? <Shield size={16} color="#fc6011" /> : <Store size={16} color="#3b82f6" />}
          <span className={`badge ${isAdmin ? 'badge-primary' : 'badge-info'}`}>
            {user?.role}
          </span>
        </div>

        <div style={{ textAlign: 'right' }}>
          <div style={{ fontSize: '13px', fontWeight: 700, color: '#0f172a' }}>{user?.fullName || user?.username}</div>
          <div style={{ fontSize: '11px', color: '#64748b' }}>{user?.email}</div>
        </div>
      </div>
    </header>
  );
};
