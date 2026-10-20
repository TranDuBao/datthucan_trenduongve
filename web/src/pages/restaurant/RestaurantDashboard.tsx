import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { apiFetch } from '../../api/apiClient';
import { getSocket } from '../../api/socketClient';
import { MetricCard } from '../../components/MetricCard';
import { StatusBadge } from '../../components/StatusBadge';
import { AnimatedCounter } from '../../components/AnimatedCounter';
import {
  ShoppingBag,
  Clock,
  Utensils,
  CheckCircle,
  DollarSign,
  Calendar,
  Users,
  AlertCircle,
  ArrowRight,
} from 'lucide-react';

export const RestaurantDashboard: React.FC = () => {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  const loadDashboard = () => {
    apiFetch<any>('/restaurant/dashboard')
      .then((res) => setStats(res.data))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadDashboard();

    const socket = getSocket();
    if (socket) {
      const handleUpdate = () => {
        console.log('⚡ Realtime dashboard update event received');
        loadDashboard();
      };

      socket.on('order:created', handleUpdate);
      socket.on('order:status_changed', handleUpdate);
      socket.on('reservation:created', handleUpdate);
      socket.on('reservation:status_changed', handleUpdate);
      socket.on('payment:confirmed', handleUpdate);
      socket.on('voucher:updated', handleUpdate);

      return () => {
        socket.off('order:created', handleUpdate);
        socket.off('order:status_changed', handleUpdate);
        socket.off('reservation:created', handleUpdate);
        socket.off('reservation:status_changed', handleUpdate);
        socket.off('payment:confirmed', handleUpdate);
        socket.off('voucher:updated', handleUpdate);
      };
    }
  }, []);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  const formatTime = (isoStr: string) => {
    if (!isoStr) return '--:--';
    try {
      const d = new Date(isoStr);
      return d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    } catch (e) {
      return '--:--';
    }
  };

  const formatDate = (isoStr: string) => {
    if (!isoStr) return '';
    try {
      const d = new Date(isoStr);
      return d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' });
    } catch (e) {
      return '';
    }
  };

  if (loading) {
    return (
      <div style={{ textAlign: 'center', padding: '60px' }}>
        <div className="loading-spinner" />
      </div>
    );
  }

  const pendingResCount = stats?.pendingReservationsCount || 0;

  return (
    <div style={{ paddingBottom: '30px' }}>
      {/* Header */}
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 className="page-title">Bảng Điều Khiển Nhà Hàng</h1>
          <p className="page-subtitle">Tổng quan tình hình Đặt Bàn, Phục Vụ & Đơn Hàng hôm nay</p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            className="btn btn-primary"
            onClick={() => navigate('/restaurant/reservations')}
            style={{ display: 'inline-flex', alignItems: 'center', gap: '8px', padding: '9px 16px', fontWeight: 600 }}
          >
            <Calendar size={16} /> Quản Lý Đặt Bàn
          </button>
        </div>
      </div>

      {/* Alert Banner if pending reservations require urgent action */}
      {pendingResCount > 0 && (
        <div
          style={{
            marginBottom: '20px',
            padding: '14px 20px',
            backgroundColor: '#fef3c7',
            border: '1px solid #fde68a',
            borderRadius: '12px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            boxShadow: '0 2px 4px rgba(245, 158, 11, 0.08)',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', color: '#92400e' }}>
            <AlertCircle size={22} color="#d97706" />
            <div>
              <span style={{ fontWeight: 700, fontSize: '15px' }}>
                Có {pendingResCount} yêu cầu đặt bàn mới đang chờ xác nhận!
              </span>
              <span style={{ display: 'block', fontSize: '13px', color: '#b45309' }}>
                Vui lòng duyệt lịch đặt sớm để giữ chỗ phục vụ khách hàng.
              </span>
            </div>
          </div>
          <button
            className="btn btn-secondary"
            onClick={() => navigate('/restaurant/reservations')}
            style={{
              backgroundColor: '#d97706',
              color: '#ffffff',
              border: 'none',
              fontWeight: 600,
              padding: '8px 14px',
              fontSize: '13px',
              borderRadius: '8px',
              cursor: 'pointer',
            }}
          >
            Xử Lý Ngay →
          </button>
        </div>
      )}

      {/* TOP IMPORTANT METRICS CARDS */}
      <div style={{ marginBottom: '24px' }}>
        <div style={{ fontSize: '13px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '10px' }}>
          📌 Chỉ Số Quan Trọng Hàng Đầu
        </div>
        <div className="grid-metrics">
          <div onClick={() => navigate('/restaurant/reservations')} style={{ cursor: 'pointer' }}>
            <MetricCard
              label="Đặt Bàn Chờ Duyệt"
              value={stats?.pendingReservationsCount || 0}
              icon={Clock}
              color="#f59e0b"
              bgColor="#fffbeb"
            />
          </div>
          <div onClick={() => navigate('/restaurant/reservations')} style={{ cursor: 'pointer' }}>
            <MetricCard
              label="Bàn Đang Phục Vụ"
              value={stats?.tablesInUseCount || 0}
              icon={Users}
              color="#10b981"
              bgColor="#ecfdf5"
            />
          </div>
          <div onClick={() => navigate('/restaurant/reservations')} style={{ cursor: 'pointer' }}>
            <MetricCard
              label="Đặt Bàn Hôm Nay"
              value={stats?.todayReservationsCount || 0}
              icon={Calendar}
              color="#8b5cf6"
              bgColor="#f3e8ff"
            />
          </div>
          <div onClick={() => navigate('/restaurant/orders')} style={{ cursor: 'pointer' }}>
            <MetricCard
              label="Đơn Mang Đi Hôm Nay"
              value={stats?.todayOrdersCount || 0}
              icon={ShoppingBag}
              color="#3b82f6"
              bgColor="#eff6ff"
            />
          </div>
          <MetricCard
            label="Doanh Thu Quán"
            value={formatVND(stats?.revenue || 0)}
            icon={DollarSign}
            color="#fc6011"
            bgColor="#fff4ee"
          />
        </div>
      </div>

      {/* SECONDARY OPERATIONAL METRICS */}
      <div style={{ marginBottom: '28px', backgroundColor: '#ffffff', borderRadius: '12px', padding: '16px 20px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
        <div style={{ fontSize: '13px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '12px' }}>
          🛍️ Tiến Độ Đơn Mang Đi (Takeaway Pipeline)
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', backgroundColor: '#f8fafc', borderRadius: '8px', border: '1px solid #f1f5f9' }}>
            <div style={{ width: '40px', height: '40px', borderRadius: '8px', backgroundColor: '#fef3c7', color: '#d97706', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Clock size={20} />
            </div>
            <div>
              <div style={{ fontSize: '12px', color: '#64748b' }}>Đơn Sắp Đến Giờ Lấy</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#1e293b' }}>
                <AnimatedCounter value={stats?.upcomingPickupCount || 0} />
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', backgroundColor: '#f8fafc', borderRadius: '8px', border: '1px solid #f1f5f9' }}>
            <div style={{ width: '40px', height: '40px', borderRadius: '8px', backgroundColor: '#fff4ee', color: '#fc6011', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Utensils size={20} />
            </div>
            <div>
              <div style={{ fontSize: '12px', color: '#64748b' }}>Đơn Đang Chuẩn Bị</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#1e293b' }}>
                <AnimatedCounter value={stats?.preparingCount || 0} />
              </div>
            </div>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', padding: '12px', backgroundColor: '#f8fafc', borderRadius: '8px', border: '1px solid #f1f5f9' }}>
            <div style={{ width: '40px', height: '40px', borderRadius: '8px', backgroundColor: '#ecfdf5', color: '#10b981', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <CheckCircle size={20} />
            </div>
            <div>
              <div style={{ fontSize: '12px', color: '#64748b' }}>Đơn Đã Sẵn Sàng</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#1e293b' }}>
                <AnimatedCounter value={stats?.readyCount || 0} />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* DASHBOARD TABLES GRID (2 COLUMNS) */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(480px, 1fr))', gap: '20px' }}>
        {/* RECENT RESERVATIONS TABLE */}
        <div className="card-table">
          <div className="table-toolbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontWeight: 700, fontSize: '15px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Calendar size={18} color="#8b5cf6" />
              Lịch Đặt Bàn Mới Gần Đây
            </div>
            <button
              onClick={() => navigate('/restaurant/reservations')}
              style={{ background: 'none', border: 'none', color: '#fc6011', fontWeight: 600, fontSize: '13px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
            >
              Xem tất cả <ArrowRight size={14} />
            </button>
          </div>

          {(!stats?.recentReservations || stats.recentReservations.length === 0) ? (
            <div className="empty-state">Chưa có lịch đặt bàn nào</div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '40px', textAlign: 'center' }}>STT</th>
                  <th>Khách Hàng</th>
                  <th>Bàn / Sức Chứa</th>
                  <th>Khung Giờ Đặt</th>
                  <th>Trạng Thái</th>
                </tr>
              </thead>
              <tbody>
                {stats.recentReservations.map((res: any, idx: number) => (
                  <tr key={res.maDatBan}>
                    <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{idx + 1}</td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{res.tenKhachHang}</div>
                      <div style={{ fontSize: '11px', color: '#64748b' }}>{res.sdtKhachHang}</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: 700, color: '#1e293b' }}>{res.tenBan}</div>
                      <div style={{ fontSize: '11px', color: '#64748b' }}>👥 {res.soNguoi} người</div>
                    </td>
                    <td>
                      <div style={{ fontWeight: 700, color: '#8b5cf6' }}>
                        🕒 {formatTime(res.thoiGianBatDau)} - {formatTime(res.thoiGianKetThuc)}
                      </div>
                      <div style={{ fontSize: '11px', color: '#64748b' }}>📅 {formatDate(res.thoiGianBatDau)}</div>
                    </td>
                    <td><StatusBadge status={res.trangThai} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* RECENT ORDERS TABLE */}
        <div className="card-table">
          <div className="table-toolbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontWeight: 700, fontSize: '15px', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <ShoppingBag size={18} color="#3b82f6" />
              Đơn Hàng Ghé Lấy Gần Đây
            </div>
            <button
              onClick={() => navigate('/restaurant/orders')}
              style={{ background: 'none', border: 'none', color: '#fc6011', fontWeight: 600, fontSize: '13px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}
            >
              Xem tất cả <ArrowRight size={14} />
            </button>
          </div>

          {(!stats?.recentOrders || stats.recentOrders.length === 0) ? (
            <div className="empty-state">Chưa có đơn hàng nào cho quán</div>
          ) : (
            <table className="data-table">
              <thead>
                <tr>
                  <th style={{ width: '40px', textAlign: 'center' }}>STT</th>
                  <th>Mã Đơn</th>
                  <th>Khách Hàng</th>
                  <th>Hẹn Lấy</th>
                  <th>Tổng Tiền</th>
                  <th>Trạng Thái</th>
                </tr>
              </thead>
              <tbody>
                {stats.recentOrders.map((ord: any, idx: number) => (
                  <tr key={ord.maDonHang}>
                    <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{idx + 1}</td>
                    <td style={{ fontWeight: 700 }}>#{ord.maDonHang}</td>
                    <td>
                      <div style={{ fontWeight: 600 }}>{ord.tenKhachHang}</div>
                      <div style={{ fontSize: '11px', color: '#64748b' }}>{ord.sdtKhachHang}</div>
                    </td>
                    <td style={{ fontWeight: 700, color: '#f59e0b' }}>
                      ⏰ {ord.thoiGianHenNhan ? formatTime(ord.thoiGianHenNhan) : 'Ghé liền'}
                    </td>
                    <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(ord.tongTien)}</td>
                    <td><StatusBadge status={ord.trangThai} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
};
