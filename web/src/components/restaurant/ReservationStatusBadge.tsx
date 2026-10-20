import React from 'react';

export interface ReservationStatusConfig {
  key: string;
  label: string;
  dotColor: string;
  textColor: string;
  bgColor: string;
  borderColor: string;
  barColor: string;
  pulse?: boolean;
}

export const normalizeReservationStatus = (st?: string): string => {
  if (!st) return 'CHO_XAC_NHAN';
  const s = st.trim().toUpperCase();
  if (
    s === 'CHO_XAC_NHAN' ||
    s === 'PENDING' ||
    s === 'CHỜ XÁC NHẬN' ||
    s === 'CHỜ XỬ LÝ' ||
    s === 'DANG_CHO' ||
    s === 'CHO_PHE_DUYET'
  ) {
    return 'CHO_XAC_NHAN';
  }
  if (
    s === 'DA_XAC_NHAN' ||
    s === 'CONFIRMED' ||
    s === 'ĐÃ XÁC NHẬN' ||
    s === 'CONFIRM'
  ) {
    return 'DA_XAC_NHAN';
  }
  if (
    s === 'DA_DEN' ||
    s === 'KHÁCH ĐÃ ĐẾN' ||
    s === 'KHACH_DA_DEN' ||
    s === 'CUSTOMER_ARRIVED'
  ) {
    return 'DA_DEN';
  }
  if (
    s === 'DANG_SU_DUNG' ||
    s === 'ĐANG SỬ DỤNG' ||
    s === 'IN_PROGRESS'
  ) {
    return 'DANG_SU_DUNG';
  }
  if (
    s === 'DA_HOAN_TAT' ||
    s === 'HOAN_TAT' ||
    s === 'COMPLETED' ||
    s === 'HOAN_THANH' ||
    s === 'ĐÃ HOÀN THÀNH' ||
    s === 'THÀNH CÔNG'
  ) {
    return 'DA_HOAN_TAT';
  }
  if (
    s === 'KHACH_KHONG_DEN' ||
    s === 'KHÁCH KHÔNG ĐẾN' ||
    s === 'NO_SHOW'
  ) {
    return 'KHACH_KHONG_DEN';
  }
  if (
    s === 'TU_CHOI' ||
    s === 'TỪ CHỐI' ||
    s === 'REJECTED'
  ) {
    return 'TU_CHOI';
  }
  if (
    s === 'DA_HUY' ||
    s === 'ĐÃ HỦY' ||
    s === 'CANCELLED' ||
    s === 'CANCELED' ||
    s === 'HỦY'
  ) {
    return 'DA_HUY';
  }
  return s;
};

export const RESERVATION_STATUS_MAP: Record<string, ReservationStatusConfig> = {
  CHO_XAC_NHAN: {
    key: 'CHO_XAC_NHAN',
    label: 'CHỜ XÁC NHẬN',
    dotColor: '#d97706',
    textColor: '#92400e',
    bgColor: '#fef3c7',
    borderColor: '#fcd34d',
    barColor: '#d97706',
    pulse: true,
  },
  DA_XAC_NHAN: {
    key: 'DA_XAC_NHAN',
    label: 'ĐÃ XÁC NHẬN',
    dotColor: '#2563eb',
    textColor: '#1e40af',
    bgColor: '#dbeafe',
    borderColor: '#93c5fd',
    barColor: '#2563eb',
  },
  DA_DEN: {
    key: 'DA_DEN',
    label: 'KHÁCH ĐÃ ĐẾN',
    dotColor: '#0284c7',
    textColor: '#0369a1',
    bgColor: '#e0f2fe',
    borderColor: '#7dd3fc',
    barColor: '#0284c7',
  },
  DANG_SU_DUNG: {
    key: 'DANG_SU_DUNG',
    label: 'ĐANG SỬ DỤNG',
    dotColor: '#7e22ce',
    textColor: '#581c87',
    bgColor: '#f3e8ff',
    borderColor: '#d8b4fe',
    barColor: '#7e22ce',
  },
  DA_HOAN_TAT: {
    key: 'DA_HOAN_TAT',
    label: 'HOÀN TẤT',
    dotColor: '#16a34a',
    textColor: '#14532d',
    bgColor: '#dcfce7',
    borderColor: '#86efac',
    barColor: '#16a34a',
  },
  KHACH_KHONG_DEN: {
    key: 'KHACH_KHONG_DEN',
    label: 'KHÁCH KHÔNG ĐẾN',
    dotColor: '#e11d48',
    textColor: '#9f1239',
    bgColor: '#ffe4e6',
    borderColor: '#fda4af',
    barColor: '#e11d48',
  },
  TU_CHOI: {
    key: 'TU_CHOI',
    label: 'TỪ CHỐI',
    dotColor: '#475569',
    textColor: '#1e293b',
    bgColor: '#f1f5f9',
    borderColor: '#cbd5e1',
    barColor: '#64748b',
  },
  DA_HUY: {
    key: 'DA_HUY',
    label: 'ĐÃ HỦY',
    dotColor: '#dc2626',
    textColor: '#991b1b',
    bgColor: '#fee2e2',
    borderColor: '#fca5a5',
    barColor: '#dc2626',
  },
};

export const getReservationStatusConfig = (rawStatus?: string): ReservationStatusConfig => {
  const norm = normalizeReservationStatus(rawStatus);
  return (
    RESERVATION_STATUS_MAP[norm] || {
      key: norm,
      label: (rawStatus || 'KHÔNG RÕ').toUpperCase(),
      dotColor: '#64748b',
      textColor: '#334155',
      bgColor: '#f1f5f9',
      borderColor: '#cbd5e1',
      barColor: '#94a3b8',
    }
  );
};

interface ReservationStatusBadgeProps {
  status: string;
}

export const ReservationStatusBadge: React.FC<ReservationStatusBadgeProps> = ({ status }) => {
  const config = getReservationStatusConfig(status);

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
        fontSize: '11px',
        fontWeight: 800,
        letterSpacing: '0.4px',
        textTransform: 'uppercase',
        whiteSpace: 'nowrap',
        userSelect: 'none',
      }}
    >
      <style>{`
        @keyframes res-badge-pulse-anim {
          0%, 100% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.4); opacity: 0.45; }
        }
        .res-badge-pulse {
          animation: res-badge-pulse-anim 1.5s ease-in-out infinite;
        }
      `}</style>
      <span
        className={config.pulse ? 'res-badge-pulse' : ''}
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
