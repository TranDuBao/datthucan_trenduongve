import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { UtensilsCrossed, Lock, Mail } from 'lucide-react';

export const Login: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { login, isLoading } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    try {
      await login(email, password);
      const savedUser = JSON.parse(localStorage.getItem('auth_user') || '{}');
      if (savedUser.role === 'ADMIN') {
        navigate('/admin/dashboard');
      } else {
        navigate('/restaurant/dashboard');
      }
    } catch (err: any) {
      setError(err.message || 'Đăng nhập thất bại!');
    }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#0f172a' }}>
      <div style={{ background: '#ffffff', width: '100%', maxWidth: '420px', padding: '36px', borderRadius: '16px', boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' }}>
        <div style={{ textAlign: 'center', marginBottom: '28px' }}>
          <div style={{ width: '56px', height: '56px', background: '#fff4ee', color: '#fc6011', borderRadius: '16px', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', marginBottom: '12px' }}>
            <UtensilsCrossed size={30} />
          </div>
          <h2 style={{ fontSize: '22px', fontWeight: 800, color: '#0f172a' }}>Hệ Thống Quản Trị Web</h2>
          <p style={{ fontSize: '13px', color: '#64748b', marginTop: '4px' }}>Dành cho Admin & Quản lý Nhà hàng</p>
        </div>

        {error && (
          <div style={{ background: '#fef2f2', color: '#ef4444', padding: '10px 14px', borderRadius: '8px', fontSize: '13px', fontWeight: 600, marginBottom: '20px' }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Email hoặc Tên đăng nhập</label>
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                className="form-control"
                style={{ paddingLeft: '38px' }}
                placeholder="admin@smartcity.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
              <Mail size={18} color="#94a3b8" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
            </div>
          </div>

          <div className="form-group" style={{ marginBottom: '24px' }}>
            <label className="form-label">Mật khẩu</label>
            <div style={{ position: 'relative' }}>
              <input
                type="password"
                className="form-control"
                style={{ paddingLeft: '38px' }}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <Lock size={18} color="#94a3b8" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
            </div>
          </div>

          <button type="submit" className="btn btn-primary" style={{ width: '100%', justifyContent: 'center', padding: '12px' }} disabled={isLoading}>
            {isLoading ? <div className="loading-spinner" /> : 'Đăng Nhập'}
          </button>
        </form>
      </div>
    </div>
  );
};
