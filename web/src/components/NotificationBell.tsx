import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Bell,
  CheckCheck,
  ShoppingBag,
  Calendar,
  CreditCard,
  Tag,
  AlertCircle,
  X,
  ExternalLink,
} from 'lucide-react';
import { apiFetch } from '../api/apiClient';
import { getSocket } from '../api/socketClient';
import { useAuth } from '../context/AuthContext';

export interface NotificationItem {
  id: number;
  recipientId: number;
  recipientRole: string;
  type: string;
  title: string;
  body: string;
  data?: Record<string, any> | null;
  isRead: boolean;
  createdAt: string;
}

import { playNotificationSound } from '../utils/soundUtils';

// Relative time formatting in Vietnamese
const formatRelativeTime = (dateStr: string): string => {
  try {
    const diff = (Date.now() - new Date(dateStr).getTime()) / 1000;
    if (diff < 60) return 'Vừa xong';
    if (diff < 3600) return `${Math.floor(diff / 60)} phút trước`;
    if (diff < 86400) return `${Math.floor(diff / 3600)} giờ trước`;
    if (diff < 604800) return `${Math.floor(diff / 86400)} ngày trước`;
    return new Date(dateStr).toLocaleDateString('vi-VN');
  } catch {
    return '';
  }
};

export const NotificationBell: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [unreadCount, setUnreadCount] = useState<number>(0);
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [isOpen, setIsOpen] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [page, setPage] = useState<number>(1);
  const [hasMore, setHasMore] = useState<boolean>(false);
  const [isRinging, setIsRinging] = useState<boolean>(false);
  const [toast, setToast] = useState<{ id: number; title: string; body: string } | null>(null);

  const dropdownRef = useRef<HTMLDivElement>(null);
  const toastTimeoutRef = useRef<any>(null);

  const fetchUnreadCount = useCallback(async () => {
    try {
      const res = await apiFetch<{ unreadCount: number }>('/notifications/unread-count');
      if (res?.data?.unreadCount !== undefined) {
        setUnreadCount(res.data.unreadCount);
      }
    } catch (_) {}
  }, []);

  const fetchNotifications = useCallback(async (targetPage = 1, append = false) => {
    setIsLoading(true);
    try {
      const res = await apiFetch<{
        notifications: NotificationItem[];
        total: number;
        unreadCount: number;
        totalPages: number;
      }>(`/notifications?page=${targetPage}&limit=15`);

      if (res?.data) {
        const items = res.data.notifications || [];
        setNotifications((prev) => (append ? [...prev, ...items] : items));
        setUnreadCount(res.data.unreadCount ?? 0);
        setHasMore(targetPage < (res.data.totalPages || 1));
        setPage(targetPage);
      }
    } catch (_) {
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Listen to Socket.io events
  useEffect(() => {
    fetchUnreadCount();

    const socket = getSocket();
    if (!socket) return;

    const handleNewNotification = (data: any) => {
      // Trigger chime and ring animation
      playNotificationSound();
      setIsRinging(true);
      setTimeout(() => setIsRinging(false), 800);

      // Increment badge
      setUnreadCount((prev) => prev + 1);

      // Prepend to current notification list
      if (data && data.id) {
        const item: NotificationItem = {
          id: data.id,
          recipientId: data.recipientId,
          recipientRole: data.recipientRole,
          type: data.type || 'SYSTEM',
          title: data.title || 'Thông báo mới',
          body: data.body || '',
          data: data.data || null,
          isRead: false,
          createdAt: data.createdAt || new Date().toISOString(),
        };

        setNotifications((prev) => [item, ...prev]);

        // Show brief Toast
        if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
        setToast({ id: item.id, title: item.title, body: item.body });
        toastTimeoutRef.current = setTimeout(() => {
          setToast(null);
        }, 5000);
      }
    };

    socket.on('notification:new', handleNewNotification);

    // Sync state on reconnection
    const handleReconnect = () => {
      fetchUnreadCount();
      if (isOpen) fetchNotifications(1, false);
    };
    socket.on('connect', handleReconnect);

    return () => {
      socket.off('notification:new', handleNewNotification);
      socket.off('connect', handleReconnect);
      if (toastTimeoutRef.current) clearTimeout(toastTimeoutRef.current);
    };
  }, [fetchUnreadCount, fetchNotifications, isOpen]);

  // Click outside listener to close dropdown
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const handleToggleDropdown = () => {
    if (!isOpen) {
      setIsOpen(true);
      fetchNotifications(1, false);
    } else {
      setIsOpen(false);
    }
  };

  const handleMarkAllAsRead = async () => {
    try {
      await apiFetch('/notifications/read-all', { method: 'PATCH' });
      setUnreadCount(0);
      setNotifications((prev) => prev.map((n) => ({ ...n, isRead: true })));
    } catch (_) {}
  };

  const handleItemClick = async (item: NotificationItem) => {
    if (!item.isRead) {
      try {
        await apiFetch(`/notifications/${item.id}/read`, { method: 'PATCH' });
        setUnreadCount((prev) => Math.max(0, prev - 1));
        setNotifications((prev) =>
          prev.map((n) => (n.id === item.id ? { ...n, isRead: true } : n))
        );
      } catch (_) {}
    }

    setIsOpen(false);

    // Deep routing based on payload
    const isAdmin = user?.role === 'ADMIN';
    if (item.data?.orderId) {
      navigate(isAdmin ? '/admin/orders' : '/restaurant/orders');
    } else if (item.data?.reservationId) {
      navigate('/restaurant/reservations');
    } else if (item.type.includes('review')) {
      navigate(isAdmin ? '/admin/reviews' : '/restaurant/reviews');
    } else if (item.type.includes('voucher')) {
      navigate(isAdmin ? '/admin/dashboard' : '/restaurant/vouchers');
    } else if (item.type.includes('restaurant')) {
      navigate(isAdmin ? '/admin/restaurants' : '/restaurant/profile');
    }
  };

  const renderTypeIcon = (type: string) => {
    const t = String(type || '').toLowerCase();
    if (t.includes('order')) {
      return <ShoppingBag size={18} color="#fc6011" />;
    }
    if (t.includes('reservation')) {
      return <Calendar size={18} color="#3b82f6" />;
    }
    if (t.includes('payment')) {
      return <CreditCard size={18} color="#10b981" />;
    }
    if (t.includes('voucher')) {
      return <Tag size={18} color="#8b5cf6" />;
    }
    return <AlertCircle size={18} color="#f59e0b" />;
  };

  const displayBadge = unreadCount > 99 ? '99+' : unreadCount > 0 ? String(unreadCount) : null;

  return (
    <div style={{ position: 'relative' }} ref={dropdownRef}>
      {/* Bell Button */}
      <button
        type="button"
        onClick={handleToggleDropdown}
        title="Thông báo"
        style={{
          position: 'relative',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          width: '38px',
          height: '38px',
          borderRadius: '50%',
          backgroundColor: isOpen ? '#fee2d2' : '#f1f5f9',
          color: isOpen ? '#fc6011' : '#334155',
          border: '1px solid #e2e8f0',
          cursor: 'pointer',
          transition: 'all 0.2s ease',
          transform: isRinging ? 'rotate(15deg) scale(1.1)' : 'none',
        }}
      >
        <Bell size={19} />
        {displayBadge && (
          <span
            style={{
              position: 'absolute',
              top: '-3px',
              right: '-3px',
              backgroundColor: '#ef4444',
              color: '#ffffff',
              fontSize: '10px',
              fontWeight: 800,
              lineHeight: '1',
              padding: '2px 5px',
              borderRadius: '10px',
              border: '2px solid #ffffff',
              boxShadow: '0 2px 4px rgba(239, 68, 68, 0.4)',
            }}
          >
            {displayBadge}
          </span>
        )}
      </button>

      {/* Floating In-App Toast Popup */}
      {toast && (
        <div
          style={{
            position: 'fixed',
            top: '70px',
            right: '24px',
            maxWidth: '360px',
            backgroundColor: '#ffffff',
            borderRadius: '12px',
            padding: '14px 16px',
            boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.15), 0 8px 10px -6px rgba(0, 0, 0, 0.1)',
            borderLeft: '5px solid #fc6011',
            borderTop: '1px solid #f1f5f9',
            borderRight: '1px solid #f1f5f9',
            borderBottom: '1px solid #f1f5f9',
            zIndex: 9999,
            display: 'flex',
            alignItems: 'flex-start',
            gap: '12px',
            animation: 'fadeIn 0.3s ease',
          }}
        >
          <div style={{ marginTop: '2px', flexShrink: 0 }}>
            <Bell size={20} color="#fc6011" />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: '13px', fontWeight: 700, color: '#0f172a', marginBottom: '2px' }}>
              {toast.title}
            </div>
            <div style={{ fontSize: '12px', color: '#475569', lineHeight: 1.4 }}>
              {toast.body}
            </div>
          </div>
          <button
            type="button"
            onClick={() => setToast(null)}
            style={{ color: '#94a3b8', padding: '2px' }}
          >
            <X size={15} />
          </button>
        </div>
      )}

      {/* Notifications Dropdown Panel */}
      {isOpen && (
        <div
          style={{
            position: 'absolute',
            top: '46px',
            right: '0',
            width: '380px',
            maxHeight: '520px',
            backgroundColor: '#ffffff',
            borderRadius: '14px',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.12), 0 8px 10px -6px rgba(0, 0, 0, 0.08)',
            border: '1px solid #e2e8f0',
            zIndex: 1000,
            display: 'flex',
            flexDirection: 'column',
            overflow: 'hidden',
          }}
        >
          {/* Header */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '12px 16px',
              borderBottom: '1px solid #f1f5f9',
              backgroundColor: '#fafaf9',
            }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <span style={{ fontSize: '14px', fontWeight: 800, color: '#0f172a' }}>
                Thông báo
              </span>
              {unreadCount > 0 && (
                <span
                  style={{
                    backgroundColor: '#fee2d2',
                    color: '#fc6011',
                    fontSize: '11px',
                    fontWeight: 700,
                    padding: '2px 8px',
                    borderRadius: '12px',
                  }}
                >
                  {unreadCount} mới
                </span>
              )}
            </div>

            {unreadCount > 0 && (
              <button
                type="button"
                onClick={handleMarkAllAsRead}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '4px',
                  fontSize: '12px',
                  fontWeight: 600,
                  color: '#fc6011',
                  cursor: 'pointer',
                }}
              >
                <CheckCheck size={14} />
                Đọc tất cả
              </button>
            )}
          </div>

          {/* Notification List */}
          <div style={{ flex: 1, overflowY: 'auto', maxHeight: '420px' }}>
            {isLoading && notifications.length === 0 ? (
              <div style={{ padding: '36px', textAlign: 'center', color: '#94a3b8', fontSize: '13px' }}>
                Đang tải thông báo...
              </div>
            ) : notifications.length === 0 ? (
              <div style={{ padding: '48px 24px', textAlign: 'center', color: '#94a3b8' }}>
                <Bell size={36} color="#cbd5e1" style={{ margin: '0 auto 10px auto' }} />
                <div style={{ fontSize: '14px', fontWeight: 600, color: '#64748b' }}>
                  Chưa có thông báo nào
                </div>
                <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>
                  Các cập nhật đơn hàng & đặt bàn sẽ xuất hiện tại đây.
                </div>
              </div>
            ) : (
              notifications.map((item) => (
                <div
                  key={item.id}
                  onClick={() => handleItemClick(item)}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    gap: '12px',
                    padding: '12px 16px',
                    borderBottom: '1px solid #f8fafc',
                    backgroundColor: item.isRead ? '#ffffff' : '#fffbf7',
                    cursor: 'pointer',
                    transition: 'background-color 0.15s ease',
                  }}
                  onMouseEnter={(e) => {
                    e.currentTarget.style.backgroundColor = item.isRead ? '#f8fafc' : '#fff4ee';
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.style.backgroundColor = item.isRead ? '#ffffff' : '#fffbf7';
                  }}
                >
                  {/* Icon */}
                  <div
                    style={{
                      width: '34px',
                      height: '34px',
                      borderRadius: '50%',
                      backgroundColor: item.isRead ? '#f1f5f9' : '#fee2d2',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      flexShrink: 0,
                      marginTop: '2px',
                    }}
                  >
                    {renderTypeIcon(item.type)}
                  </div>

                  {/* Content */}
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '8px' }}>
                      <div
                        style={{
                          fontSize: '13px',
                          fontWeight: item.isRead ? 600 : 700,
                          color: '#0f172a',
                          whiteSpace: 'nowrap',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                        }}
                      >
                        {item.title}
                      </div>
                      {!item.isRead && (
                        <span
                          style={{
                            width: '7px',
                            height: '7px',
                            borderRadius: '50%',
                            backgroundColor: '#fc6011',
                            flexShrink: 0,
                          }}
                        />
                      )}
                    </div>

                    <div
                      style={{
                        fontSize: '12px',
                        color: '#475569',
                        marginTop: '3px',
                        lineHeight: 1.4,
                        display: '-webkit-box',
                        WebkitLineClamp: 2,
                        WebkitBoxOrient: 'vertical',
                        overflow: 'hidden',
                      }}
                    >
                      {item.body}
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: '6px' }}>
                      <span style={{ fontSize: '11px', color: '#94a3b8' }}>
                        {formatRelativeTime(item.createdAt)}
                      </span>
                      <ExternalLink size={12} color="#cbd5e1" />
                    </div>
                  </div>
                </div>
              ))
            )}

            {/* Load More Button */}
            {hasMore && (
              <div style={{ padding: '10px', textAlign: 'center', borderTop: '1px solid #f1f5f9' }}>
                <button
                  type="button"
                  onClick={() => fetchNotifications(page + 1, true)}
                  disabled={isLoading}
                  style={{
                    fontSize: '12px',
                    fontWeight: 700,
                    color: '#fc6011',
                    padding: '6px 14px',
                    borderRadius: '6px',
                    backgroundColor: '#fff4ee',
                  }}
                >
                  {isLoading ? 'Đang tải...' : 'Tải thêm thông báo'}
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};
