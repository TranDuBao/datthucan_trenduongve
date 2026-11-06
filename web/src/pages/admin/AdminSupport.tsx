import React, { useState } from 'react';
import { Headphones, Inbox, HelpCircle, PhoneCall, MessageSquare } from 'lucide-react';
import { SupportInboxTab } from './support/SupportInboxTab';
import { SupportFaqTab } from './support/SupportFaqTab';
import { SupportConfigTab } from './support/SupportConfigTab';
import { SupportFeedbackTab } from './support/SupportFeedbackTab';

type TabKey = 'inbox' | 'faq' | 'config' | 'feedback';

export const AdminSupport: React.FC = () => {
  const [activeTab, setActiveTab] = useState<TabKey>('inbox');

  const tabs: { key: TabKey; label: string; icon: React.ReactNode }[] = [
    { key: 'inbox', label: 'Hộp Thư Hỗ Trợ', icon: <Inbox size={17} /> },
    { key: 'faq', label: 'Câu Hỏi FAQ', icon: <HelpCircle size={17} /> },
    { key: 'config', label: 'Cấu Hình Liên Hệ', icon: <PhoneCall size={17} /> },
    { key: 'feedback', label: 'Góp Ý & Phản Hồi', icon: <MessageSquare size={17} /> },
  ];

  return (
    <div style={{ maxWidth: '1440px', margin: '0 auto', paddingBottom: '40px' }}>
      {/* Header Card */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '16px',
          padding: '22px 24px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
          border: '1px solid #e2e8f0',
          marginBottom: '20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div
            style={{
              width: '46px',
              height: '46px',
              borderRadius: '13px',
              backgroundColor: 'rgba(252, 96, 17, 0.12)',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#fc6011',
              flexShrink: 0,
            }}
          >
            <Headphones size={24} />
          </div>
          <div>
            <h1
              style={{
                fontSize: '22px',
                fontWeight: 800,
                color: '#0f172a',
                letterSpacing: '-0.3px',
                margin: 0,
              }}
            >
              Trung Tâm Hỗ Trợ
            </h1>
            <p style={{ fontSize: '13.5px', color: '#64748b', marginTop: '4px', margin: 0 }}>
              Hộp thư hội thoại trực tuyến, câu hỏi thường gặp (FAQ), cấu hình liên hệ & góp ý người dùng
            </p>
          </div>
        </div>

        {/* Tab Switcher Pills */}
        <div
          style={{
            display: 'inline-flex',
            backgroundColor: '#f1f5f9',
            padding: '5px',
            borderRadius: '14px',
            gap: '6px',
            border: '1px solid #e2e8f0',
            flexWrap: 'wrap',
          }}
        >
          {tabs.map((tab) => {
            const isActive = activeTab === tab.key;
            return (
              <button
                key={tab.key}
                onClick={() => setActiveTab(tab.key)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '9px 18px',
                  borderRadius: '10px',
                  fontSize: '13px',
                  fontWeight: isActive ? 700 : 600,
                  backgroundColor: isActive ? '#fc6011' : 'transparent',
                  color: isActive ? '#ffffff' : '#64748b',
                  border: 'none',
                  cursor: 'pointer',
                  boxShadow: isActive ? '0 4px 12px rgba(252,96,17,0.28)' : 'none',
                  transition: 'all 0.15s ease',
                }}
              >
                {tab.icon}
                <span>{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Tab Content */}
      <div>
        {activeTab === 'inbox' && <SupportInboxTab />}
        {activeTab === 'faq' && <SupportFaqTab />}
        {activeTab === 'config' && <SupportConfigTab />}
        {activeTab === 'feedback' && <SupportFeedbackTab />}
      </div>
    </div>
  );
};
