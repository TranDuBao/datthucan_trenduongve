import React from 'react';
import { StatusBadge } from '../StatusBadge';
import {
  X,
  User,
  Phone,
  Mail,
  Calendar,
  Clock,
  Users,
  Utensils,
  FileText,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  PlayCircle,
  CheckCheck,
} from 'lucide-react';

interface ReservationDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  reservation: any | null;
  onAction: (id: number, actionType: string) => Promise<void>;
  loadingAction: boolean;
}

export const ReservationDetailModal: React.FC<ReservationDetailModalProps> = ({
  isOpen,
  onClose,
  reservation,
  onAction,
  loadingAction,
}) => {
  if (!isOpen || !reservation) return null;

  const status = reservation.trangThai;
  const start = new Date(reservation.thoiGianBatDau);
  const end = new Date(reservation.thoiGianKetThuc);
  const created = new Date(reservation.createdAt);

  const customerName =
    reservation.tenKhachHang ||
    reservation.khachHang?.hoTen ||
    'Khách vãng lai';
  const customerPhone =
    reservation.sdtKhachHang || reservation.khachHang?.sdt || 'Chưa cung cấp';
  const customerEmail =
    reservation.emailKhachHang || reservation.khachHang?.email || 'N/A';

  const formatDateTime = (d: Date) => {
    if (isNaN(d.getTime())) return 'N/A';
    return d.toLocaleString('vi-VN', {
      hour: '2-digit',
      minute: '2-digit',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  };

  const formatTimeOnly = (d: Date) => {
    if (isNaN(d.getTime())) return 'N/A';
    return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
  };

  const formatDateOnly = (d: Date) => {
    if (isNaN(d.getTime())) return 'N/A';
    return d.toLocaleDateString('vi-VN', {
      weekday: 'short',
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  };

  return (
    <div
      className="modal-backdrop"
      onClick={onClose}
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(15, 23, 42, 0.65)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1200,
        backdropFilter: 'blur(3px)',
        padding: '20px',
      }}
    >
      <div
        className="modal-content"
        onClick={(e) => e.stopPropagation()}
        style={{
          maxWidth: '640px',
          width: '100%',
          maxHeight: '90vh',
          overflowY: 'auto',
          borderRadius: '16px',
          padding: '24px',
          background: '#ffffff',
          boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
        }}
      >

        {/* Modal Header */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            borderBottom: '1px solid #e2e8f0',
            paddingBottom: '16px',
            marginBottom: '20px',
          }}
        >
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <h3 style={{ margin: 0, fontSize: '20px', fontWeight: 700, color: '#1e293b' }}>
                Chi Tiết Đặt Bàn #{reservation.maDatBan}
              </h3>
              <StatusBadge status={status} />
            </div>
            <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: '#64748b' }}>
              Ngày tạo: {formatDateTime(created)}
            </p>
          </div>
          <button
            onClick={onClose}
            style={{
              background: '#f1f5f9',
              border: 'none',
              borderRadius: '50%',
              width: '36px',
              height: '36px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'pointer',
              color: '#64748b',
            }}
          >
            <X size={20} />
          </button>
        </div>

        {/* Modal Body */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {/* Customer Info Card */}
          <div
            style={{
              background: '#f8fafc',
              borderRadius: '12px',
              padding: '16px',
              border: '1px solid #e2e8f0',
            }}
          >
            <div
              style={{
                fontSize: '14px',
                fontWeight: 700,
                color: '#334155',
                marginBottom: '12px',
                display: 'flex',
                alignItems: 'center',
                gap: '8px',
              }}
            >
              <User size={16} color="#fc6011" /> Thông tin khách hàng
            </div>
            <div
              style={{
                display: 'grid',
                gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                gap: '12px',
                fontSize: '14px',
              }}
            >
              <div>
                <span style={{ color: '#64748b', fontSize: '12px' }}>Họ tên:</span>
                <div style={{ fontWeight: 600, color: '#1e293b' }}>{customerName}</div>
              </div>
              <div>
                <span style={{ color: '#64748b', fontSize: '12px' }}>Số điện thoại:</span>
                <div style={{ fontWeight: 600, color: '#1e293b', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <Phone size={14} color="#64748b" /> {customerPhone}
                </div>
              </div>
              {customerEmail !== 'N/A' && (
                <div>
                  <span style={{ color: '#64748b', fontSize: '12px' }}>Email:</span>
                  <div style={{ fontWeight: 600, color: '#1e293b', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <Mail size={14} color="#64748b" /> {customerEmail}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Booking & Table Details */}
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: '1fr 1fr',
              gap: '12px',
            }}
          >
            <div
              style={{
                background: '#fff7ed',
                borderRadius: '12px',
                padding: '16px',
                border: '1px solid #ffedd5',
              }}
            >
              <div style={{ fontSize: '13px', color: '#c2410c', fontWeight: 600, marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Utensils size={15} /> Bàn Phục Vụ
              </div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#9a3412' }}>
                {reservation.ban?.tenBan || `Bàn ID #${reservation.maBan}`}
              </div>
              <div style={{ fontSize: '13px', color: '#ea580c', marginTop: '4px' }}>
                Sức chứa: {reservation.ban?.sucChua || 'N/A'} người
              </div>
            </div>

            <div
              style={{
                background: '#f0fdf4',
                borderRadius: '12px',
                padding: '16px',
                border: '1px solid #dcfce7',
              }}
            >
              <div style={{ fontSize: '13px', color: '#15803d', fontWeight: 600, marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Users size={15} /> Số Lượng Khách
              </div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#166534' }}>
                {reservation.soNguoi} người
              </div>
              <div style={{ fontSize: '13px', color: '#16a34a', marginTop: '4px' }}>
                Đến: {formatDateOnly(start)}
              </div>
            </div>
          </div>

          {/* Time Slot */}
          <div
            style={{
              background: '#f8fafc',
              borderRadius: '12px',
              padding: '16px',
              border: '1px solid #e2e8f0',
              display: 'flex',
              flexDirection: 'column',
              gap: '8px',
            }}
          >
            <div style={{ fontSize: '13px', color: '#64748b', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Clock size={16} color="#0284c7" /> Khung giờ dự kiến:
            </div>
            <div style={{ fontSize: '16px', fontWeight: 700, color: '#0369a1' }}>
              {formatTimeOnly(start)} ➔ {formatTimeOnly(end)} ({formatDateOnly(start)})
            </div>
          </div>

          {/* Notes if any */}
          {reservation.ghiChu && (
            <div
              style={{
                background: '#fefce8',
                borderRadius: '12px',
                padding: '14px',
                border: '1px solid #fef08a',
              }}
            >
              <div style={{ fontSize: '13px', fontWeight: 600, color: '#a16207', marginBottom: '4px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <FileText size={15} /> Ghi chú từ khách:
              </div>
              <div style={{ fontSize: '14px', color: '#854d0e', fontStyle: 'italic' }}>
                "{reservation.ghiChu}"
              </div>
            </div>
          )}
        </div>

        {/* Modal Actions */}
        <div
          style={{
            marginTop: '24px',
            paddingTop: '16px',
            borderTop: '1px solid #e2e8f0',
            display: 'flex',
            justifyContent: 'flex-end',
            gap: '10px',
            flexWrap: 'wrap',
          }}
        >
          {status === 'CHO_XAC_NHAN' && (
            <>
              <button
                disabled={loadingAction}
                onClick={() => onAction(reservation.maDatBan, 'confirm')}
                className="btn btn-primary"
                style={{ background: '#16a34a', borderColor: '#16a34a', display: 'flex', alignItems: 'center', gap: '6px' }}
              >
                <CheckCircle2 size={16} /> Xác Nhận Đặt Bàn
              </button>
              <button
                disabled={loadingAction}
                onClick={() => onAction(reservation.maDatBan, 'reject')}
                className="btn"
                style={{ background: '#eab308', color: '#fff', border: 'none', display: 'flex', alignItems: 'center', gap: '6px' }}
              >
                <XCircle size={16} /> Từ Chối
              </button>
              <button
                disabled={loadingAction}
                onClick={() => onAction(reservation.maDatBan, 'cancel')}
                className="btn"
                style={{ background: '#ef4444', color: '#fff', border: 'none', display: 'flex', alignItems: 'center', gap: '6px' }}
              >
                <AlertTriangle size={16} /> Hủy Đặt
              </button>
            </>
          )}

          {status === 'DA_XAC_NHAN' && (
            <>
              <button
                disabled={loadingAction}
                onClick={() => onAction(reservation.maDatBan, 'check-in')}
                className="btn btn-primary"
                style={{ background: '#0284c7', borderColor: '#0284c7', display: 'flex', alignItems: 'center', gap: '6px' }}
              >
                <CheckCircle2 size={16} /> Khách Đã Đến
              </button>
              <button
                disabled={loadingAction}
                onClick={() => onAction(reservation.maDatBan, 'no-show')}
                className="btn"
                style={{ background: '#e11d48', color: '#fff', border: 'none', display: 'flex', alignItems: 'center', gap: '6px' }}
              >
                <XCircle size={16} /> Khách Không Đến
              </button>
              <button
                disabled={loadingAction}
                onClick={() => onAction(reservation.maDatBan, 'cancel')}
                className="btn"
                style={{ background: '#64748b', color: '#fff', border: 'none', display: 'flex', alignItems: 'center', gap: '6px' }}
              >
                <AlertTriangle size={16} /> Khách Hủy
              </button>
            </>
          )}

          {status === 'DA_DEN' && (
            <button
              disabled={loadingAction}
              onClick={() => onAction(reservation.maDatBan, 'start')}
              className="btn btn-primary"
              style={{ background: '#7e22ce', borderColor: '#7e22ce', display: 'flex', alignItems: 'center', gap: '6px' }}
            >
              <PlayCircle size={16} /> Bắt Đầu Sử Dụng Bàn
            </button>
          )}

          {status === 'DANG_SU_DUNG' && (
            <button
              disabled={loadingAction}
              onClick={() => onAction(reservation.maDatBan, 'complete')}
              className="btn btn-primary"
              style={{ background: '#16a34a', borderColor: '#16a34a', display: 'flex', alignItems: 'center', gap: '6px' }}
            >
              <CheckCheck size={16} /> Hoàn Tất Sử Dụng Bàn
            </button>
          )}

          {['DA_HOAN_TAT', 'DA_HUY', 'TU_CHOI', 'KHACH_KHONG_DEN'].includes(status) && (
            <button onClick={onClose} className="btn" style={{ background: '#cbd5e1', color: '#334155' }}>
              Đóng
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
