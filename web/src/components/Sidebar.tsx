import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  Store,
  FolderTree,
  UtensilsCrossed,
  ShoppingBag,
  CreditCard,
  Ticket,
  LogOut,
  Sliders,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const Sidebar: React.FC = () => {
  const { user, logout } = useAuth();
  const isAdmin = user?.role === 'ADMIN';

  const adminNav = [
    { title: 'Dashboard', path: '/admin/dashboard', icon: LayoutDashboard },
    { title: 'Người Dùng', path: '/admin/users', icon: Users },
    { title: 'Nhà Hàng', path: '/admin/restaurants', icon: Store },
    { title: 'Danh Mục Món', path: '/admin/categories', icon: FolderTree },
    { title: 'Món Ăn', path: '/admin/foods', icon: UtensilsCrossed },
    { title: 'Đơn Hàng', path: '/admin/orders', icon: ShoppingBag },
    { title: 'Thanh Toán', path: '/admin/payments', icon: CreditCard },
  ];

  const restaurantNav = [
    { title: 'Dashboard', path: '/restaurant/dashboard', icon: LayoutDashboard },
    { title: 'Quản Lý Đơn Hàng', path: '/restaurant/orders', icon: ShoppingBag },
    { title: 'Thực Đơn Quán', path: '/restaurant/menu', icon: UtensilsCrossed },
    { title: 'Thông Tin Nhà Hàng', path: '/restaurant/profile', icon: Store },
  ];

  const navItems = isAdmin ? adminNav : restaurantNav;

  return (
    <aside className="sidebar">
      <div className="sidebar-header">
        <UtensilsCrossed size={28} color="#fc6011" />
        <div>
          <div className="sidebar-brand">
            Food<span>Route</span>
          </div>
          <div style={{ fontSize: '11px', color: '#64748b', fontWeight: 600 }}>
            {isAdmin ? 'ADMIN SYSTEM' : 'RESTAURANT PORTAL'}
          </div>
        </div>
      </div>

      <nav className="sidebar-nav">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.path}
              to={item.path}
              className={({ isActive }) => `sidebar-link ${isActive ? 'active' : ''}`}
            >
              <Icon size={18} />
              <span>{item.title}</span>
            </NavLink>
          );
        })}
      </nav>

      <div className="sidebar-footer">
        <button
          onClick={logout}
          className="sidebar-link"
          style={{ width: '100%', color: '#ef4444', justifyContent: 'flex-start' }}
        >
          <LogOut size={18} />
          <span>Đăng xuất</span>
        </button>
      </div>
    </aside>
  );
};
