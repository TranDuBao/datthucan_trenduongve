import React from 'react';

export interface TabItem<T extends string = string> {
  key: T;
  label: string;
  icon?: React.ReactNode;
  count?: number;
  highlightCount?: boolean;
}

interface UnderlineTabsProps<T extends string = string> {
  tabs: TabItem<T>[];
  activeTab: T;
  onChange: (key: T) => void;
  rightExtra?: React.ReactNode;
  style?: React.CSSProperties;
}

export const UnderlineTabs = <T extends string = string>({
  tabs,
  activeTab,
  onChange,
  rightExtra,
  style,
}: UnderlineTabsProps<T>) => {
  return (
    <div
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        borderBottom: '2px solid #e2e8f0',
        marginBottom: '20px',
        flexWrap: 'wrap',
        gap: '12px',
        ...style,
      }}
    >
      <div
        style={{
          display: 'flex',
          gap: '8px',
          overflowX: 'auto',
          maxWidth: '100%',
          scrollbarWidth: 'none',
        }}
      >
        {tabs.map((tab) => {
          const isActive = activeTab === tab.key;
          return (
            <button
              key={tab.key}
              type="button"
              onClick={() => onChange(tab.key)}
              style={{
                padding: '12px 20px',
                fontWeight: 700,
                fontSize: '15px',
                background: 'transparent',
                border: 'none',
                borderBottom: isActive ? '3px solid #fc6011' : '3px solid transparent',
                color: isActive ? '#fc6011' : '#64748b',
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
                whiteSpace: 'nowrap',
                transition: 'all 0.15s ease',
              }}
            >
              {tab.icon}
              <span>{tab.label}</span>
              {typeof tab.count === 'number' && (
                <span
                  style={{
                    background: tab.highlightCount
                      ? '#ea580c'
                      : isActive
                      ? '#fff4ee'
                      : '#f1f5f9',
                    color: tab.highlightCount
                      ? '#ffffff'
                      : isActive
                      ? '#fc6011'
                      : '#64748b',
                    fontSize: '11px',
                    fontWeight: 800,
                    padding: '2px 8px',
                    borderRadius: '12px',
                    transition: 'all 0.15s ease',
                  }}
                >
                  {tab.count}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {rightExtra && <div>{rightExtra}</div>}
    </div>
  );
};
