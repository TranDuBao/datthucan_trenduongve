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
  X,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

interface SidebarProps {
  isOpen?: boolean;
  onClose?: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ isOpen = false, onClose }) => {
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
    <aside className={`sidebar ${isOpen ? 'open' : ''}`}>
      <div className="sidebar-header" style={{ justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
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
        <button
          onClick={onClose}
          className="touch-target mobile-close-btn"
          aria-label="Đóng menu"
          style={{
            border: 'none',
            background: 'transparent',
            color: '#94a3b8',
            cursor: 'pointer',
            padding: '6px',
            display: 'none',
          }}
        >
          <X size={22} />
        </button>
      </div>

      <nav className="sidebar-nav">
        {navItems.map((item) => {
          const Icon = item.icon;
          return (
            <NavLink
              key={item.path}
              to={item.path}
              onClick={onClose}
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
          onClick={() => {
            onClose?.();
            logout();
          }}
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
