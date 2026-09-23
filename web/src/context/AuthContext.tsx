import React, { createContext, useContext, useState, useEffect } from 'react';
import { apiFetch } from '../api/apiClient';

export interface User {
  id: number;
  username: string;
  fullName: string;
  email: string;
  role: 'ADMIN' | 'CUAN_HANG' | 'KHACH_HANG' | string;
}

interface AuthContextType {
  user: User | null;
  token: string | null;
  login: (email: string, pass: string) => Promise<void>;
  logout: () => void;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(() => {
    const saved = localStorage.getItem('auth_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('auth_token'));
  const [isLoading, setIsLoading] = useState(false);

  const login = async (email: string, pass: string) => {
    setIsLoading(true);
    try {
      const res = await apiFetch<any>('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password: pass }),
      });

      const payload = res.payload || res.data;
      const accessToken = payload.accessToken;
      const userInfo = payload.user;

      localStorage.setItem('auth_token', accessToken);
      localStorage.setItem('auth_user', JSON.stringify(userInfo));

      setToken(accessToken);
      setUser(userInfo);
    } finally {
      setIsLoading(false);
    }
  };

  const logout = () => {
    localStorage.removeItem('auth_token');
    localStorage.removeItem('auth_user');
    setToken(null);
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, token, login, logout, isLoading }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
};
