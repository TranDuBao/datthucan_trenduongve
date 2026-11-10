import React, { useState } from 'react';
import {
  Bell,
  Send,
  History,
  Smartphone,
  Info,
} from 'lucide-react';
import { NotificationComposer } from './notifications/NotificationComposer';
import { NotificationHistoryTable } from './notifications/NotificationHistoryTable';
import { AppVersionManager } from './notifications/AppVersionManager';

export const AdminNotifications: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'compose' | 'history' | 'version'>('compose');
  const [refreshTrigger, setRefreshTrigger] = useState<number>(0);

  const handleNotificationCreated = () => {
    setRefreshTrigger((prev) => prev + 1);
    setActiveTab('history');
  };

  const handleVersionUpdated = () => {
    setRefreshTrigger((prev) => prev + 1);
  };

  return (
    <div style={{ padding: '24px 32px', maxWidth: '1440px', margin: '0 auto' }}>
      {/* Page Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '24px' }}>
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div
              style={{
                width: '40px',
                height: '40px',
                borderRadius: '10px',
                backgroundColor: '#fc6011',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#fff',
                boxShadow: '0 4px 12px rgba(252, 96, 17, 0.25)',
              }}
            >
              <Bell size={22} />
            </div>
            <div>
              <h1 style={{ fontSize: '24px', fontWeight: 800, margin: 0, color: '#0f172a' }}>
                Hệ Thống Thông Báo & Cập Nhật
              </h1>
              <p style={{ fontSize: '13px', color: '#64748b', margin: '4px 0 0 0' }}>
                Soạn phát thông báo màn hình khóa song ngữ, hẹn giờ và quản trị phiên bản ứng dụng
              </p>
            </div>
          </div>
        </div>

        {/* Top Navigation Tabs */}
        <div style={{ display: 'flex', gap: '8px', backgroundColor: '#f1f5f9', padding: '4px', borderRadius: '12px' }}>
          <button
            type="button"
            onClick={() => setActiveTab('compose')}
            style={{
              padding: '8px 18px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: activeTab === 'compose' ? '#fff' : 'transparent',
              color: activeTab === 'compose' ? '#fc6011' : '#64748b',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              boxShadow: activeTab === 'compose' ? '0 2px 4px rgba(0,0,0,0.06)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            <Send size={15} />
            Soạn Thông Báo
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('history')}
            style={{
              padding: '8px 18px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: activeTab === 'history' ? '#fff' : 'transparent',
              color: activeTab === 'history' ? '#fc6011' : '#64748b',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              boxShadow: activeTab === 'history' ? '0 2px 4px rgba(0,0,0,0.06)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            <History size={15} />
            Lịch Sử & Thống Kê
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('version')}
            style={{
              padding: '8px 18px',
              borderRadius: '8px',
              border: 'none',
              backgroundColor: activeTab === 'version' ? '#fff' : 'transparent',
              color: activeTab === 'version' ? '#fc6011' : '#64748b',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
              boxShadow: activeTab === 'version' ? '0 2px 4px rgba(0,0,0,0.06)' : 'none',
              transition: 'all 0.15s ease',
            }}
          >
            <Smartphone size={15} />
            Cấu Hình Phiên Bản App
          </button>
        </div>
      </div>

      {/* Main Tab Content */}
      {activeTab === 'compose' && (
        <NotificationComposer onNotificationCreated={handleNotificationCreated} />
      )}

      {activeTab === 'history' && (
        <NotificationHistoryTable refreshTrigger={refreshTrigger} />
      )}

      {activeTab === 'version' && (
        <AppVersionManager onVersionUpdated={handleVersionUpdated} />
      )}
    </div>
  );
};

