import React from 'react';
import { AnimatedCounter } from './AnimatedCounter';

interface MetricCardProps {
  label: string;
  value: string | number;
  icon: React.ElementType;
  color?: string;
  bgColor?: string;
  duration?: number;
}

export const MetricCard: React.FC<MetricCardProps> = ({
  label,
  value,
  icon: Icon,
  color = '#fc6011',
  bgColor = '#fff4ee',
  duration = 800,
}) => {
  const strVal = String(value || '');
  const isCurrency =
    typeof value === 'string' &&
    (strVal.includes('₫') || strVal.includes('đ') || strVal.includes('Đ') || strVal.toLowerCase().includes('vnd'));

  // Strip thousand-separator dots before extracting numbers so "813.000 ₫" -> "813000" -> 813000
  const cleanStr = isCurrency ? strVal.replace(/\./g, '') : strVal;
  const numericValue =
    typeof value === 'number'
      ? value
      : parseFloat(cleanStr.replace(/[^0-9-]/g, '')) || 0;

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  const renderAnimatedValue = () => {
    if (numericValue === 0) {
      return typeof value === 'string' ? value : 0;
    }

    if (isCurrency) {
      return (
        <AnimatedCounter
          value={numericValue}
          duration={duration}
          formatter={(val) => formatVND(val)}
        />
      );
    }

    return (
      <AnimatedCounter
        value={numericValue}
        duration={duration}
        formatter={(val) => Math.round(val).toLocaleString('vi-VN')}
      />
    );
  };

  return (
    <div className="metric-card">
      <div>
        <div className="metric-label">{label}</div>
        <div className="metric-value">{renderAnimatedValue()}</div>
      </div>
      <div className="metric-icon" style={{ backgroundColor: bgColor, color }}>
        <Icon size={24} />
      </div>
    </div>
  );
};
