import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  ClipboardCheck,
  Users,
  Store,
  FolderTree,
  UtensilsCrossed,
  ShoppingBag,
  CreditCard,
  Ticket,
  LogOut,
  Sliders,
  DollarSign,
  ShieldAlert,
  CalendarDays,
  Star,
  Info,
  Layers,
  FileText,
  Headphones,
  Bell,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const Sidebar: React.FC = () => {
  const { user, logout } = useAuth();
  const isAdmin = user?.role === 'ADMIN';

  const adminNav = [
    { title: 'Dashboard', path: '/admin/dashboard', icon: LayoutDashboard },
    { title: 'Người Dùng', path: '/admin/users', icon: Users },
    { title: 'Duyệt Đăng Ký Quán', path: '/admin/store-registrations', icon: ClipboardCheck },
    { title: 'Nhà Hàng', path: '/admin/restaurants', icon: Store },
    { title: 'Loại Hình Quán', path: '/admin/store-categories', icon: Layers },
    { title: 'Thực Đơn Tuyển Chọn', path: '/admin/categories', icon: FolderTree },
    { title: 'Quản Lý Banner', path: '/admin/banners', icon: Sliders },
    { title: 'Đơn Hàng', path: '/admin/orders', icon: ShoppingBag },
    { title: 'Đánh Giá & Kiểm Duyệt', path: '/admin/reviews', icon: Star },
    { title: 'Về Chúng Tôi', path: '/admin/about-us', icon: Info },
    { title: 'Điều Khoản & Chính Sách', path: '/admin/legal-documents', icon: FileText },
    { title: 'Thông Báo Hệ Thống', path: '/admin/notifications', icon: Bell },
    { title: 'Hỗ Trợ', path: '/admin/support', icon: Headphones },
    { title: 'Nhật Ký', path: '/admin/logs', icon: ShieldAlert },
  ];

  const restaurantNav = [
    { title: 'Dashboard', path: '/restaurant/dashboard', icon: LayoutDashboard },
    { title: 'Quản Lý Đơn Hàng', path: '/restaurant/orders', icon: ShoppingBag },
    { title: 'Thực Đơn Quán', path: '/restaurant/menu', icon: UtensilsCrossed },
    { title: 'Đặt Bàn', path: '/restaurant/reservations', icon: CalendarDays },
    { title: 'Voucher Khuyến Mãi', path: '/restaurant/vouchers', icon: Ticket },
    { title: 'Doanh Thu & Báo Cáo', path: '/restaurant/revenue', icon: DollarSign },
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
