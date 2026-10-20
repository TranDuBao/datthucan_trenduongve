import React, { useState } from 'react';
import { StatusBadge } from '../StatusBadge';
import { ChevronLeft, ChevronRight, Calendar as CalendarIcon, Clock, User, Phone, Users, Utensils } from 'lucide-react';

interface ReservationCalendarViewProps {
  reservations: any[];
  onSelectReservation: (res: any) => void;
  loading: boolean;
}

export const ReservationCalendarView: React.FC<ReservationCalendarViewProps> = ({
  reservations,
  onSelectReservation,
  loading,
}) => {
  const getLocalYMD = (d: Date) => d.toLocaleDateString('sv-SE');

  const [selectedDate, setSelectedDate] = useState<string>(
    getLocalYMD(new Date())
  );

  const changeDateByDays = (days: number) => {
    const current = new Date(selectedDate);
    current.setDate(current.getDate() + days);
    setSelectedDate(getLocalYMD(current));
  };

  const formattedHeaderDate = new Date(selectedDate).toLocaleDateString('vi-VN', {
    weekday: 'long',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });

  // Filter reservations for the selected date
  const dayReservations = reservations.filter((r) => {
    const rDate = getLocalYMD(new Date(r.thoiGianBatDau));
    return rDate === selectedDate;
  });


  // Group reservations by hour slot
  const hours = Array.from({ length: 15 }, (_, i) => i + 8); // 8:00 to 22:00

  const getReservationsForHour = (hour: number) => {
    return dayReservations.filter((r) => {
      const h = new Date(r.thoiGianBatDau).getHours();
      return h === hour;
    });
  };

  return (
    <div style={{ marginTop: '20px' }}>
      {/* Date navigation bar */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          background: '#ffffff',
          borderRadius: '14px',
          padding: '16px 20px',
          border: '1px solid #e2e8f0',
          marginBottom: '20px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <CalendarIcon size={22} color="#fc6011" />
          <div>
            <h4 style={{ margin: 0, fontSize: '16px', fontWeight: 700, color: '#1e293b', textTransform: 'capitalize' }}>
              Lịch Đặt Bàn: {formattedHeaderDate}
            </h4>
            <span style={{ fontSize: '13px', color: '#64748b' }}>
              Có {dayReservations.length} lượt đặt bàn trong ngày
            </span>
          </div>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <button
            onClick={() => changeDateByDays(-1)}
            className="btn"
            style={{ background: '#f1f5f9', color: '#334155', display: 'flex', alignItems: 'center', gap: '4px' }}
          >
            <ChevronLeft size={18} /> Ngày trước
          </button>
          <input
            type="date"
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            style={{
              padding: '7px 12px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '14px',
            }}
          />
          <button
            onClick={() => changeDateByDays(1)}
            className="btn"
            style={{ background: '#f1f5f9', color: '#334155', display: 'flex', alignItems: 'center', gap: '4px' }}
          >
            Ngày sau <ChevronRight size={18} />
          </button>
        </div>
      </div>

      {/* Hourly Timeline View */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: '40px', color: '#64748b' }}>Đang tải lịch đặt bàn...</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          {hours.map((hour) => {
            const slotBookings = getReservationsForHour(hour);
            const timeLabel = `${hour < 10 ? '0' + hour : hour}:00`;

            return (
              <div
                key={hour}
                style={{
                  display: 'grid',
                  gridTemplateColumns: '90px 1fr',
                  gap: '16px',
                  background: slotBookings.length > 0 ? '#ffffff' : '#fafafa',
                  borderRadius: '12px',
                  padding: '14px',
                  border: slotBookings.length > 0 ? '1px solid #cbd5e1' : '1px solid #f1f5f9',
                }}
              >
                {/* Time slot header */}
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '15px', fontWeight: 700, color: slotBookings.length > 0 ? '#fc6011' : '#94a3b8' }}>
                  <Clock size={16} /> {timeLabel}
                </div>

                {/* Bookings in this slot */}
                <div style={{ display: 'flex', flexWrap: 'wrap', gap: '12px' }}>
                  {slotBookings.length === 0 ? (
                    <span style={{ fontSize: '13px', color: '#cbd5e1', fontStyle: 'italic', alignSelf: 'center' }}>
                      Chưa có lượt đặt
                    </span>
                  ) : (
                    slotBookings.map((res) => {
                      const startTime = new Date(res.thoiGianBatDau).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
                      const endTime = new Date(res.thoiGianKetThuc).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
                      const customerName = res.tenKhachHang || res.khachHang?.hoTen || 'Khách vãng lai';

                      return (
                        <div
                          key={res.maDatBan}
                          onClick={() => onSelectReservation(res)}
                          style={{
                            background: '#f8fafc',
                            borderRadius: '10px',
                            padding: '10px 14px',
                            border: '1px solid #e2e8f0',
                            borderLeft: '4px solid #fc6011',
                            cursor: 'pointer',
                            transition: 'all 0.2s',
                            boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
                          }}
                        >
                          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '12px', marginBottom: '4px' }}>
                            <span style={{ fontWeight: 700, fontSize: '14px', color: '#1e293b' }}>
                              {res.ban?.tenBan || `Bàn #${res.maBan}`}
                            </span>
                            <StatusBadge status={res.trangThai} />
                          </div>

                          <div style={{ fontSize: '13px', color: '#475569', display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                              <User size={13} color="#64748b" /> {customerName}
                            </span>
                            <span>•</span>
                            <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                              <Users size={13} color="#64748b" /> {res.soNguoi} khách
                            </span>
                          </div>

                          <div style={{ fontSize: '12px', color: '#0284c7', fontWeight: 600, marginTop: '4px' }}>
                            {startTime} - {endTime}
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
