import React from 'react';

export interface OrderStatusConfig {
  key: string;
  label: string;
  dotColor: string;
  textColor: string;
  bgColor: string;
  borderColor: string;
  barColor: string;
  pulse?: boolean;
  spin?: boolean;
}

export const normalizeOrderStatus = (st?: string): string => {
  if (!st) return 'PENDING';
  const s = st.trim().toUpperCase();
  if (s === 'CHO_XAC_NHAN' || s === 'PENDING' || s.includes('CHỜ') || s === 'CHỜ XÁC NHẬN' || s === 'CHỜ XỬ LÝ') {
    return 'PENDING';
  }
  if (s === 'DA_XAC_NHAN' || s === 'CONFIRMED' || s.includes('XÁC NHẬN')) {
    return 'CONFIRMED';
  }
  if (s === 'DANG_CHUAN_BI' || s === 'PREPARING' || s.includes('CHUẨN BỊ') || s.includes('CHƯA LÀM')) {
    return 'PREPARING';
  }
  if (s === 'SAN_SANG' || s === 'READY' || s === 'READY_FOR_PICKUP' || s.includes('SẴN SÀNG')) {
    return 'READY_FOR_PICKUP';
  }
  if (s === 'HOAN_TAT' || s === 'HOAN_THANH' || s === 'COMPLETED' || s === 'PICKED_UP' || s.includes('HOÀN')) {
    return 'COMPLETED';
  }
  if (s === 'DA_HUY' || s === 'CANCELLED' || s.includes('HỦY')) {
    return 'CANCELLED';
  }
  return s;
};

export const ORDER_STATUS_MAP: Record<string, OrderStatusConfig> = {
  PENDING: {
    key: 'PENDING',
    label: 'CHỜ XÁC NHẬN',
    dotColor: '#b45309',
    textColor: '#78350f',
    bgColor: '#fef08a',
    borderColor: '#fde047',
    barColor: '#eab308',
    pulse: true,
  },
  CONFIRMED: {
    key: 'CONFIRMED',
    label: 'ĐÃ XÁC NHẬN',
    dotColor: '#2563eb',
    textColor: '#1e40af',
    bgColor: '#dbeafe',
    borderColor: '#bfdbfe',
    barColor: '#3b82f6',
  },
  PREPARING: {
    key: 'PREPARING',
    label: 'ĐANG CHUẨN BỊ',
    dotColor: '#7c3aed',
    textColor: '#5b21b6',
    bgColor: '#ede9fe',
    borderColor: '#ddd6fe',
    barColor: '#8b5cf6',
    spin: true,
  },
  READY_FOR_PICKUP: {
    key: 'READY_FOR_PICKUP',
    label: 'SẴN SÀNG',
    dotColor: '#0d9488',
    textColor: '#115e59',
    bgColor: '#ccfbf1',
    borderColor: '#99f6e4',
    barColor: '#14b8a6',
  },
  COMPLETED: {
    key: 'COMPLETED',
    label: 'HOÀN TẤT',
    dotColor: '#15803d',
    textColor: '#14532d',
    bgColor: '#dcfce7',
    borderColor: '#bbf7d0',
    barColor: '#16a34a',
  },
  CANCELLED: {
    key: 'CANCELLED',
    label: 'ĐÃ HỦY',
    dotColor: '#dc2626',
    textColor: '#991b1b',
    bgColor: '#fee2e2',
    borderColor: '#fecaca',
    barColor: '#ef4444',
  },
};

export const getOrderStatusConfig = (rawStatus?: string): OrderStatusConfig => {
  const norm = normalizeOrderStatus(rawStatus);
  return (
    ORDER_STATUS_MAP[norm] || {
      key: norm,
      label: rawStatus || 'KHÔNG RÕ',
      dotColor: '#64748b',
      textColor: '#334155',
      bgColor: '#f1f5f9',
      borderColor: '#e2e8f0',
      barColor: '#94a3b8',
    }
  );
};

interface OrderStatusBadgeProps {
  status: string;
}

export const OrderStatusBadge: React.FC<OrderStatusBadgeProps> = ({ status }) => {
  const config = getOrderStatusConfig(status);

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '6px',
        padding: '5px 10px',
        borderRadius: '8px',
        backgroundColor: config.bgColor,
        color: config.textColor,
        border: `1px solid ${config.borderColor}`,
        fontSize: '12px',
        fontWeight: 600,
        letterSpacing: '0.3px',
        textTransform: 'uppercase',
        whiteSpace: 'nowrap',
        userSelect: 'none',
      }}
    >
      <style>{`
        @keyframes order-badge-pulse-anim {
          0%, 100% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.4); opacity: 0.45; }
        }
        @keyframes order-badge-spin-anim {
          0% { transform: scale(1); opacity: 0.9; }
          50% { transform: scale(1.3); opacity: 0.5; }
          100% { transform: scale(1); opacity: 0.9; }
        }
        .order-badge-pulse {
          animation: order-badge-pulse-anim 1.5s ease-in-out infinite;
        }
        .order-badge-spin {
          animation: order-badge-spin-anim 1.8s ease-in-out infinite;
        }
      `}</style>
      <span
        className={config.pulse ? 'order-badge-pulse' : config.spin ? 'order-badge-spin' : ''}
        style={{
          width: '7px',
          height: '7px',
          borderRadius: '50%',
          backgroundColor: config.dotColor,
          display: 'inline-block',
          flexShrink: 0,
        }}
      />
      <span>{config.label}</span>
    </span>
  );
};
