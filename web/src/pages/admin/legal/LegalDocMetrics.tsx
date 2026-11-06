import React from 'react';
import { Layers, CheckCircle, Clock, Archive } from 'lucide-react';

interface LegalDocMetricsProps {
  total: number;
  activeCount: number;
  draftCount: number;
  archivedCount: number;
}

export const LegalDocMetrics: React.FC<LegalDocMetricsProps> = ({
  total,
  activeCount,
  draftCount,
  archivedCount,
}) => {
  const cards = [
    {
      label: 'Tổng Phiên Bản',
      value: total,
      color: '#0f172a',
      labelColor: '#64748b',
      bgColor: '#f1f5f9',
      icon: <Layers size={22} color="#475569" />,
    },
    {
      label: 'Đang Hiệu Lực',
      value: activeCount,
      color: '#047857',
      labelColor: '#047857',
      bgColor: '#ecfdf5',
      icon: <CheckCircle size={22} color="#10b981" />,
    },
    {
      label: 'Bản Nháp',
      value: draftCount,
      color: '#b45309',
      labelColor: '#b45309',
      bgColor: '#fffbeb',
      icon: <Clock size={22} color="#f59e0b" />,
    },
    {
      label: 'Đã Lưu Trữ',
      value: archivedCount,
      color: '#475569',
      labelColor: '#64748b',
      bgColor: '#f8fafc',
      icon: <Archive size={22} color="#94a3b8" />,
    },
  ];

  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
        gap: '16px',
        marginBottom: '24px',
      }}
    >
      {cards.map((c, i) => (
        <div
          key={i}
          style={{
            backgroundColor: '#ffffff',
            borderRadius: '14px',
            padding: '18px 20px',
            border: '1px solid #e2e8f0',
            boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}
        >
          <div>
            <div style={{ fontSize: '12px', fontWeight: 700, color: c.labelColor, textTransform: 'uppercase' }}>
              {c.label}
            </div>
            <div style={{ fontSize: '26px', fontWeight: 800, color: c.color, marginTop: '4px' }}>
              {c.value}
            </div>
          </div>
          <div
            style={{
              width: '44px',
              height: '44px',
              borderRadius: '10px',
              backgroundColor: c.bgColor,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            {c.icon}
          </div>
        </div>
      ))}
    </div>
  );
};

