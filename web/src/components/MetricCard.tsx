import React from 'react';

interface MetricCardProps {
  label: string;
  value: string | number;
  icon: React.ElementType;
  color?: string;
  bgColor?: string;
}

export const MetricCard: React.FC<MetricCardProps> = ({
  label,
  value,
  icon: Icon,
  color = '#fc6011',
  bgColor = '#fff4ee',
}) => {
  return (
    <div className="metric-card">
      <div>
        <div className="metric-label">{label}</div>
        <div className="metric-value">{value}</div>
      </div>
      <div className="metric-icon" style={{ backgroundColor: bgColor, color }}>
        <Icon size={24} />
      </div>
    </div>
  );
};
