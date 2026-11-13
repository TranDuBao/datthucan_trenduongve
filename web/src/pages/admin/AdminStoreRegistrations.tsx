import React, { useState, useEffect, useCallback } from 'react';
import {
  Store,
  Search,
  RefreshCw,
  Eye,
  CheckCircle,
  XCircle,
  Clock,
  AlertCircle,
  MapPin,
  Phone,
  User,
  CreditCard,
  Building,
  Calendar,
  ShieldCheck,
} from 'lucide-react';
import { apiFetch } from '../../api/apiClient';
import { getSocket } from '../../api/socketClient';
import { Modal } from '../../components/Modal';

interface StoreRegistration {
  maDon: number;
  maTaiKhoan: number;
  tenQuan: string;
  danhMuc?: string;
  diaChi: string;
  lat?: number;
  lng?: number;
  sdt: string;
  hoTenChuQuan: string;
  ngaySinhChuQuan?: string;
  soCCCD: string;
  diaChiThuongTru?: string;
  tenNganHang: string;
  soTaiKhoanNganHang: string;
  tenChuTaiKhoan: string;
  loaiHinhPhapLy?: string | null;
  maSoThue?: string | null;
  soGiayPhepKinhDoanh?: string | null;
  soGiayAttp?: string | null;
  maPhienBanDieuKhoan?: number | null;
  phienBanDieuKhoan?: {
    maPhienBan: number;
    soPhienBan: string;
    tieuDe: string;
    noiDung?: string;
  } | null;
  maPhienBanChinhSach?: number | null;
  phienBanChinhSach?: {
    maPhienBan: number;
    soPhienBan: string;
    tieuDe: string;
    noiDung?: string;
  } | null;
  thoiGianDongY?: string | null;
  dongYDieuKhoan?: boolean;
  dongYChinhSachDuLieu?: boolean;
  trangThai: 'CHO_DUYET' | 'DA_DUYET' | 'TU_CHOI';
  lyDoTuChoi?: string | null;
  ngayTao: string;
  ngayDuyet?: string | null;
  taiKhoan?: {
    maTaiKhoan: number;
    tenDangNhap: string;
    loaiTaiKhoan: string;
  };
}

export const AdminStoreRegistrations: React.FC = () => {
  const [registrations, setRegistrations] = useState<StoreRegistration[]>([]);
  const [total, setTotal] = useState<number>(0);
  const [page, setPage] = useState<number>(1);
  const [limit] = useState<number>(10);
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);

  // Detail Modal State
  const [detailModalOpen, setDetailModalOpen] = useState<boolean>(false);
  const [selectedReg, setSelectedReg] = useState<StoreRegistration | null>(null);
  const [loadingDetail, setLoadingDetail] = useState<boolean>(false);

  // Approve Confirm Modal
  const [approveConfirmOpen, setApproveConfirmOpen] = useState<boolean>(false);
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  // Reject Modal
  const [rejectModalOpen, setRejectModalOpen] = useState<boolean>(false);
  const [rejectReason, setRejectReason] = useState<string>('');
  const [rejectError, setRejectError] = useState<string>('');

  // Toast / Feedback message
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // View Agreed Document Modal
  const [viewDocModalOpen, setViewDocModalOpen] = useState<boolean>(false);
  const [viewDocData, setViewDocData] = useState<{ tieuDe: string; soPhienBan: string; noiDung: string } | null>(null);
  const [loadingDoc, setLoadingDoc] = useState<boolean>(false);

  const handleViewAgreedDocument = async (docId?: number | null, fallback?: any) => {
    if (!docId && !fallback) return;
    setViewDocModalOpen(true);
    setLoadingDoc(true);
    try {
      if (docId) {
        const res = await apiFetch<any>(`/admin/legal-documents/${docId}`);
        if (res && res.data) {
          setViewDocData({
            tieuDe: res.data.tieuDe,
            soPhienBan: res.data.soPhienBan,
            noiDung: res.data.noiDung || '',
          });
          return;
        }
      }
      setViewDocData(fallback || null);
    } catch (e) {
      setViewDocData(fallback || null);
    } finally {
      setLoadingDoc(false);
    }
  };

  const fetchRegistrations = useCallback(async () => {
    try {
      setLoading(true);
      const queryParams = new URLSearchParams({
        page: String(page),
        limit: String(limit),
      });
      if (statusFilter !== 'ALL') {
        queryParams.set('status', statusFilter);
      }

      const res = await apiFetch<any>(`/admin/store-registrations?${queryParams.toString()}`);
      if (res && res.data) {
        setRegistrations(res.data);
        setTotal(res.total || 0);
      }
    } catch (err: any) {
      console.error('Fetch store registrations error:', err);
    } finally {
      setLoading(false);
    }
  }, [page, limit, statusFilter]);

  useEffect(() => {
    fetchRegistrations();
  }, [fetchRegistrations]);

  // Realtime Socket listener
  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const handleNewRegistration = () => {
      fetchRegistrations();
      setFeedback({
        type: 'success',
        message: 'Có đơn đăng ký cửa hàng mới vừa được gửi!',
      });
      setTimeout(() => setFeedback(null), 5000);
    };

    socket.on('new_store_registration', handleNewRegistration);

    return () => {
      socket.off('new_store_registration', handleNewRegistration);
    };
  }, [fetchRegistrations]);

  const openDetail = async (item: StoreRegistration) => {
    try {
      setDetailModalOpen(true);
      setLoadingDetail(true);
      const res = await apiFetch<StoreRegistration>(`/admin/store-registrations/${item.maDon}`);
      if (res && res.data) {
        setSelectedReg(res.data);
      } else {
        setSelectedReg(item);
      }
    } catch (err) {
      setSelectedReg(item);
    } finally {
      setLoadingDetail(false);
    }
  };

  const handleApprove = async () => {
    if (!selectedReg) return;
    try {
      setActionLoading(true);
      const res = await apiFetch<any>(`/admin/store-registrations/${selectedReg.maDon}/approve`, {
        method: 'POST',
      });
      if (res && (res.success || res.status === '1' || res.statusCode === 200)) {
        setApproveConfirmOpen(false);
        setDetailModalOpen(false);
        setSelectedReg(null);
        setFeedback({ type: 'success', message: 'Duyệt đơn đăng ký thành công! Cửa hàng đã được tạo.' });
        fetchRegistrations();
      } else {
        setApproveConfirmOpen(false);
        setFeedback({ type: 'error', message: res?.message || 'Lỗi khi duyệt đơn' });
      }
    } catch (err: any) {
      setApproveConfirmOpen(false);
      setFeedback({ type: 'error', message: err.message || 'Lỗi hệ thống khi duyệt đơn' });
    } finally {
      setActionLoading(false);
      setTimeout(() => setFeedback(null), 5000);
    }
  };

  const handleReject = async () => {
    if (!selectedReg) return;
    if (!rejectReason.trim()) {
      setRejectError('Vui lòng nhập lý do từ chối');
      return;
    }
    try {
      setActionLoading(true);
      const res = await apiFetch<any>(`/admin/store-registrations/${selectedReg.maDon}/reject`, {
        method: 'POST',
        body: JSON.stringify({ lyDoTuChoi: rejectReason.trim() }),
      });
      if (res && (res.success || res.status === '1' || res.statusCode === 200)) {
        setRejectModalOpen(false);
        setDetailModalOpen(false);
        setSelectedReg(null);
        setRejectReason('');
        setRejectError('');
        setFeedback({ type: 'success', message: 'Đã từ chối đơn đăng ký thành công' });
        fetchRegistrations();
      } else {
        setRejectModalOpen(false);
        setFeedback({ type: 'error', message: res?.message || 'Lỗi khi từ chối đơn' });
      }
    } catch (err: any) {
      setRejectModalOpen(false);
      setFeedback({ type: 'error', message: err.message || 'Lỗi hệ thống khi từ chối đơn' });
    } finally {
      setActionLoading(false);
      setTimeout(() => setFeedback(null), 5000);
    }
  };

  const filteredRegistrations = registrations.filter((r) => {
    if (!searchTerm.trim()) return true;
    const s = searchTerm.toLowerCase();
    return (
      r.tenQuan.toLowerCase().includes(s) ||
      (r.hoTenChuQuan && r.hoTenChuQuan.toLowerCase().includes(s)) ||
      r.sdt.includes(s)
    );
  });

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'CHO_DUYET':
        return (
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '4px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600, backgroundColor: '#fef3c7', color: '#b45309' }}>
            <Clock size={12} /> Chờ duyệt
          </span>
        );
      case 'DA_DUYET':
        return (
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '4px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600, backgroundColor: '#dcfce7', color: '#15803d' }}>
            <CheckCircle size={12} /> Đã duyệt
          </span>
        );
      case 'TU_CHOI':
        return (
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '4px 8px', borderRadius: '12px', fontSize: '12px', fontWeight: 600, backgroundColor: '#fee2e2', color: '#b91c1c' }}>
            <XCircle size={12} /> Bị từ chối
          </span>
        );
      default:
        return <span>{status}</span>;
    }
  };

  return (
    <div style={{ padding: '24px', maxWidth: '1400px', margin: '0 auto' }}>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 700, color: '#0f172a', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <Store color="#fc6011" size={28} /> Quản Lý Đơn Đăng Ký Cửa Hàng
          </h1>
          <p style={{ fontSize: '14px', color: '#64748b', marginTop: '4px' }}>
            Kiểm duyệt hồ sơ đăng ký trở thành đối tác kinh doanh Food Route
          </p>
        </div>
        <button
          onClick={fetchRegistrations}
          disabled={loading}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            padding: '10px 16px',
            borderRadius: '8px',
            backgroundColor: '#ffffff',
            border: '1px solid #e2e8f0',
            color: '#334155',
            fontWeight: 600,
            cursor: 'pointer',
          }}
        >
          <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
          Làm mới
        </button>
      </div>

      {/* Feedback Toast */}
      {feedback && (
        <div
          style={{
            marginBottom: '16px',
            padding: '12px 16px',
            borderRadius: '8px',
            backgroundColor: feedback.type === 'success' ? '#f0fdf4' : '#fef2f2',
            border: `1px solid ${feedback.type === 'success' ? '#86efac' : '#fca5a5'}`,
            color: feedback.type === 'success' ? '#166534' : '#991b1b',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            fontWeight: 500,
          }}
        >
          {feedback.type === 'success' ? <CheckCircle size={18} /> : <AlertCircle size={18} />}
          {feedback.message}
        </div>
      )}

      {/* Filter and Search Bar */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '12px',
          padding: '16px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
          border: '1px solid #e2e8f0',
          marginBottom: '20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        {/* Status Filter Tabs */}
        <div style={{ display: 'flex', gap: '8px' }}>
          {[
            { key: 'ALL', label: 'Tất cả' },
            { key: 'CHO_DUYET', label: 'Chờ duyệt' },
            { key: 'DA_DUYET', label: 'Đã duyệt' },
            { key: 'TU_CHOI', label: 'Bị từ chối' },
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => {
                setStatusFilter(tab.key);
                setPage(1);
              }}
              style={{
                padding: '8px 16px',
                borderRadius: '8px',
                fontSize: '13px',
                fontWeight: 600,
                border: 'none',
                cursor: 'pointer',
                backgroundColor: statusFilter === tab.key ? '#fc6011' : '#f1f5f9',
                color: statusFilter === tab.key ? '#ffffff' : '#475569',
                transition: 'all 0.2s',
              }}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Search Input */}
        <div style={{ position: 'relative', width: '280px' }}>
          <Search size={16} color="#94a3b8" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
          <input
            type="text"
            placeholder="Tìm theo tên quán, chủ quán, SĐT..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{
              width: '100%',
              padding: '8px 12px 8px 36px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '13px',
              outline: 'none',
            }}
          />
        </div>
      </div>

      {/* Table */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '12px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
          border: '1px solid #e2e8f0',
          overflow: 'hidden',
        }}
      >
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '14px' }}>
            <thead>
              <tr style={{ backgroundColor: '#f8fafc', borderBottom: '1px solid #e2e8f0', color: '#475569', fontWeight: 600 }}>
                <th style={{ padding: '14px 16px' }}>Mã đơn</th>
                <th style={{ padding: '14px 16px' }}>Tên thương hiệu</th>
                <th style={{ padding: '14px 16px' }}>Chủ quán</th>
                <th style={{ padding: '14px 16px' }}>Số điện thoại</th>
                <th style={{ padding: '14px 16px' }}>CCCD</th>
                <th style={{ padding: '14px 16px' }}>Ngân hàng</th>
                <th style={{ padding: '14px 16px' }}>Ngày nộp</th>
                <th style={{ padding: '14px 16px' }}>Trạng thái</th>
                <th style={{ padding: '14px 16px', textAlign: 'center' }}>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={9} style={{ padding: '32px', textAlign: 'center', color: '#64748b' }}>
                    <RefreshCw size={24} className="animate-spin" style={{ margin: '0 auto 8px' }} />
                    Đang tải dữ liệu...
                  </td>
                </tr>
              ) : filteredRegistrations.length === 0 ? (
                <tr>
                  <td colSpan={9} style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
                    <Store size={36} style={{ margin: '0 auto 12px', opacity: 0.4 }} />
                    <p style={{ fontWeight: 500 }}>Không tìm thấy đơn đăng ký nào</p>
                  </td>
                </tr>
              ) : (
                filteredRegistrations.map((item) => (
                  <tr key={item.maDon} style={{ borderBottom: '1px solid #f1f5f9', transition: 'background-color 0.15s' }}>
                    <td style={{ padding: '14px 16px', fontWeight: 600, color: '#fc6011' }}>#{item.maDon}</td>
                    <td style={{ padding: '14px 16px' }}>
                      <div style={{ fontWeight: 600, color: '#0f172a' }}>{item.tenQuan}</div>
                      <div style={{ fontSize: '12px', color: '#64748b' }}>{item.danhMuc || 'Cửa hàng'}</div>
                    </td>
                    <td style={{ padding: '14px 16px', color: '#1e293b' }}>{item.hoTenChuQuan}</td>
                    <td style={{ padding: '14px 16px', color: '#1e293b' }}>{item.sdt}</td>
                    <td style={{ padding: '14px 16px', fontFamily: 'monospace', color: '#475569' }}>
                      {item.soCCCD}
                    </td>
                    <td style={{ padding: '14px 16px', color: '#334155' }}>
                      <div>{item.tenNganHang}</div>
                      <div style={{ fontSize: '12px', color: '#64748b', fontFamily: 'monospace' }}>{item.soTaiKhoanNganHang}</div>
                    </td>
                    <td style={{ padding: '14px 16px', color: '#64748b', fontSize: '13px' }}>
                      {new Date(item.ngayTao).toLocaleString('vi-VN', { dateStyle: 'short', timeStyle: 'short' })}
                    </td>
                    <td style={{ padding: '14px 16px' }}>{getStatusBadge(item.trangThai)}</td>
                    <td style={{ padding: '14px 16px', textAlign: 'center' }}>
                      <button
                        onClick={() => openDetail(item)}
                        style={{
                          display: 'inline-flex',
                          alignItems: 'center',
                          gap: '6px',
                          padding: '6px 12px',
                          borderRadius: '6px',
                          border: '1px solid #e2e8f0',
                          backgroundColor: '#f8fafc',
                          color: '#334155',
                          fontSize: '12px',
                          fontWeight: 600,
                          cursor: 'pointer',
                        }}
                      >
                        <Eye size={14} /> Chi tiết
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px', borderTop: '1px solid #e2e8f0', fontSize: '13px', color: '#64748b' }}>
          <div>Tổng số đơn: <strong>{total}</strong></div>
          <div style={{ display: 'flex', gap: '8px' }}>
            <button
              disabled={page <= 1}
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              style={{
                padding: '6px 12px',
                borderRadius: '6px',
                border: '1px solid #cbd5e1',
                backgroundColor: page <= 1 ? '#f8fafc' : '#ffffff',
                cursor: page <= 1 ? 'not-allowed' : 'pointer',
              }}
            >
              Trang trước
            </button>
            <span style={{ display: 'flex', alignItems: 'center', padding: '0 8px', fontWeight: 600 }}>
              Trang {page} / {Math.max(1, Math.ceil(total / limit))}
            </span>
            <button
              disabled={page >= Math.ceil(total / limit)}
              onClick={() => setPage((p) => p + 1)}
              style={{
                padding: '6px 12px',
                borderRadius: '6px',
                border: '1px solid #cbd5e1',
                backgroundColor: page >= Math.ceil(total / limit) ? '#f8fafc' : '#ffffff',
                cursor: page >= Math.ceil(total / limit) ? 'not-allowed' : 'pointer',
              }}
            >
              Trang sau
            </button>
          </div>
        </div>
      </div>

      {/* Detail Modal */}
      {detailModalOpen && selectedReg && (
        <Modal
          isOpen={detailModalOpen}
          onClose={() => setDetailModalOpen(false)}
          title={`Hồ Sơ Đăng Ký Cửa Hàng #${selectedReg.maDon}`}
        >
          {loadingDetail ? (
            <div style={{ padding: '32px', textAlign: 'center' }}>
              <RefreshCw size={24} className="animate-spin" />
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {/* Status Header */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px', backgroundColor: '#f8fafc', borderRadius: '8px' }}>
                <div>
                  <span style={{ fontSize: '13px', color: '#64748b' }}>Trạng thái: </span>
                  {getStatusBadge(selectedReg.trangThai)}
                </div>
                <div style={{ fontSize: '12px', color: '#64748b' }}>
                  Ngày nộp: {new Date(selectedReg.ngayTao).toLocaleString('vi-VN')}
                </div>
              </div>

              {selectedReg.lyDoTuChoi && (
                <div style={{ padding: '12px', backgroundColor: '#fef2f2', border: '1px solid #fca5a5', borderRadius: '8px', color: '#991b1b', fontSize: '13px' }}>
                  <strong>Lý do từ chối trước đó:</strong> {selectedReg.lyDoTuChoi}
                </div>
              )}

              {/* Store Information */}
              <div style={{ border: '1px solid #e2e8f0', borderRadius: '8px', padding: '16px' }}>
                <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#0f172a', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Store size={18} color="#fc6011" /> Thông Tin Cửa Hàng
                </h3>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', fontSize: '13px' }}>
                  <div>
                    <span style={{ color: '#64748b' }}>Tên thương hiệu: </span>
                    <strong style={{ color: '#0f172a' }}>{selectedReg.tenQuan}</strong>
                  </div>
                  <div>
                    <span style={{ color: '#64748b' }}>Loại hình: </span>
                    <strong style={{ color: '#0f172a' }}>{selectedReg.danhMuc || 'Cửa hàng'}</strong>
                  </div>
                  <div style={{ gridColumn: '1 / -1' }}>
                    <span style={{ color: '#64748b', display: 'flex', alignItems: 'center', gap: '4px' }}>
                      <MapPin size={14} /> Địa chỉ vị trí quán:
                    </span>
                    <div style={{ fontWeight: 500, color: '#0f172a', marginTop: '2px' }}>{selectedReg.diaChi}</div>
                  </div>
                  {selectedReg.lat && selectedReg.lng && (
                    <div style={{ gridColumn: '1 / -1', fontSize: '12px', color: '#475569' }}>
                      Tọa độ GPS: <code>{selectedReg.lat.toFixed(6)}, {selectedReg.lng.toFixed(6)}</code>
                    </div>
                  )}
                </div>
              </div>

              {/* Owner / Personal Information */}
              <div style={{ border: '1px solid #e2e8f0', borderRadius: '8px', padding: '16px' }}>
                <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#0f172a', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <User size={18} color="#3b82f6" /> Thông Tin Chủ Quán & Xác Thực CCCD
                </h3>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', fontSize: '13px' }}>
                  <div>
                    <span style={{ color: '#64748b' }}>Họ tên chủ quán: </span>
                    <strong style={{ color: '#0f172a' }}>{selectedReg.hoTenChuQuan}</strong>
                  </div>
                  <div>
                    <span style={{ color: '#64748b' }}>Số điện thoại: </span>
                    <strong style={{ color: '#0f172a' }}>{selectedReg.sdt}</strong>
                  </div>
                  <div>
                    <span style={{ color: '#64748b' }}>Ngày sinh: </span>
                    <strong style={{ color: '#0f172a' }}>
                      {selectedReg.ngaySinhChuQuan
                        ? new Date(selectedReg.ngaySinhChuQuan).toLocaleDateString('vi-VN')
                        : 'Chưa cập nhật'}
                    </strong>
                  </div>
                  <div>
                    <span style={{ color: '#64748b' }}>Số CCCD (12 số): </span>
                    <strong style={{ color: '#0f172a', fontFamily: 'monospace' }}>{selectedReg.soCCCD}</strong>
                  </div>
                  <div style={{ gridColumn: '1 / -1' }}>
                    <span style={{ color: '#64748b' }}>Địa chỉ thường trú: </span>
                    <div style={{ fontWeight: 500, color: '#0f172a', marginTop: '2px' }}>
                      {selectedReg.diaChiThuongTru || 'Chưa cung cấp'}
                    </div>
                  </div>
                </div>
              </div>

              {/* Bank Information */}
              <div style={{ border: '1px solid #e2e8f0', borderRadius: '8px', padding: '16px' }}>
                <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#0f172a', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <CreditCard size={18} color="#10b981" /> Tài Khoản Ngân Hàng Thanh Toán
                </h3>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', fontSize: '13px' }}>
                  <div>
                    <span style={{ color: '#64748b' }}>Ngân hàng thụ hưởng: </span>
                    <strong style={{ color: '#0f172a' }}>{selectedReg.tenNganHang}</strong>
                  </div>
                  <div>
                    <span style={{ color: '#64748b' }}>Số tài khoản: </span>
                    <strong style={{ color: '#0f172a', fontFamily: 'monospace' }}>{selectedReg.soTaiKhoanNganHang}</strong>
                  </div>
                  <div style={{ gridColumn: '1 / -1' }}>
                    <span style={{ color: '#64748b' }}>Tên chủ tài khoản: </span>
                    <strong style={{ color: '#0f172a' }}>{selectedReg.tenChuTaiKhoan}</strong>
                  </div>
                </div>
              </div>

              {/* Legal Information & Tax */}
              <div style={{ border: '1px solid #e2e8f0', borderRadius: '8px', padding: '16px' }}>
                <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#0f172a', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <Building size={18} color="#8b5cf6" /> Thông Tin Pháp Lý & Nghĩa Vụ Thuế
                </h3>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', fontSize: '13px' }}>
                  <div>
                    <span style={{ color: '#64748b' }}>Loại hình pháp lý: </span>
                    <strong style={{ color: '#0f172a' }}>
                      {selectedReg.loaiHinhPhapLy === 'DOANH_NGHIEP'
                        ? 'Doanh nghiệp / Công ty'
                        : selectedReg.loaiHinhPhapLy === 'HO_KINH_DOANH'
                        ? 'Hộ kinh doanh cá thể'
                        : selectedReg.loaiHinhPhapLy === 'CA_NHAN'
                        ? 'Cá nhân kinh doanh'
                        : 'Cá nhân kinh doanh'}
                    </strong>
                  </div>
                  <div>
                    <span style={{ color: '#64748b' }}>Mã số thuế (MST): </span>
                    <strong style={{ color: '#0f172a', fontFamily: 'monospace' }}>
                      {selectedReg.maSoThue || 'Chưa cung cấp'}
                    </strong>
                  </div>
                  <div>
                    <span style={{ color: '#64748b' }}>Số Giấy phép ĐKKD: </span>
                    <strong style={{ color: '#0f172a', fontFamily: 'monospace' }}>
                      {selectedReg.soGiayPhepKinhDoanh || 'Không yêu cầu / Chưa có'}
                    </strong>
                  </div>
                  <div>
                    <span style={{ color: '#64748b' }}>Số Giấy chứng nhận ATTP: </span>
                    <strong style={{ color: '#0f172a', fontFamily: 'monospace' }}>
                      {selectedReg.soGiayAttp || 'Không yêu cầu / Chưa có'}
                    </strong>
                  </div>
                </div>
              </div>

              {/* Proof of Consent */}
              <div style={{ border: '1px solid #c7d2fe', backgroundColor: '#f5f3ff', borderRadius: '8px', padding: '16px' }}>
                <h3 style={{ fontSize: '14px', fontWeight: 700, color: '#4338ca', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <ShieldCheck size={18} color="#4f46e5" /> Bằng Chứng Đồng Ý Điều Khoản & Chính Sách
                </h3>
                <p style={{ fontSize: '12px', color: '#4b5563', marginBottom: '10px' }}>
                  Hệ thống đã ghi nhận chữ ký đồng ý điện tử bắt buộc của chủ tài khoản tại thời điểm nộp đơn.
                </p>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '13px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#ffffff', padding: '10px 12px', borderRadius: '6px', border: '1px solid #e0e7ff' }}>
                    <div>
                      <div style={{ fontWeight: 600, color: '#1e1b4b' }}>
                        1. Điều khoản đối tác: v{selectedReg.phienBanDieuKhoan?.soPhienBan || '1.0'}
                      </div>
                      <div style={{ fontSize: '11px', color: '#6b7280' }}>
                        Thời gian ký: {new Date(selectedReg.thoiGianDongY || selectedReg.ngayTao).toLocaleString('vi-VN')}
                      </div>
                    </div>
                    <button
                      onClick={() => handleViewAgreedDocument(selectedReg.maPhienBanDieuKhoan, selectedReg.phienBanDieuKhoan)}
                      style={{
                        padding: '5px 10px',
                        fontSize: '12px',
                        fontWeight: 600,
                        backgroundColor: '#e0e7ff',
                        color: '#4338ca',
                        borderRadius: '6px',
                        border: 'none',
                        cursor: 'pointer',
                      }}
                    >
                      Xem toàn văn
                    </button>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', backgroundColor: '#ffffff', padding: '10px 12px', borderRadius: '6px', border: '1px solid #e0e7ff' }}>
                    <div>
                      <div style={{ fontWeight: 600, color: '#1e1b4b' }}>
                        2. Chính sách thu thập dữ liệu: v{selectedReg.phienBanChinhSach?.soPhienBan || '1.0'}
                      </div>
                      <div style={{ fontSize: '11px', color: '#6b7280' }}>
                        Thời gian ký: {new Date(selectedReg.thoiGianDongY || selectedReg.ngayTao).toLocaleString('vi-VN')}
                      </div>
                    </div>
                    <button
                      onClick={() => handleViewAgreedDocument(selectedReg.maPhienBanChinhSach, selectedReg.phienBanChinhSach)}
                      style={{
                        padding: '5px 10px',
                        fontSize: '12px',
                        fontWeight: 600,
                        backgroundColor: '#e0e7ff',
                        color: '#4338ca',
                        borderRadius: '6px',
                        border: 'none',
                        cursor: 'pointer',
                      }}
                    >
                      Xem toàn văn
                    </button>
                  </div>
                </div>
              </div>

              {/* Action Buttons for Pending Requests */}
              {selectedReg.trangThai === 'CHO_DUYET' && (
                <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px', paddingTop: '16px', borderTop: '1px solid #e2e8f0' }}>
                  <button
                    onClick={() => {
                      setRejectReason('');
                      setRejectError('');
                      setRejectModalOpen(true);
                    }}
                    style={{
                      padding: '10px 18px',
                      borderRadius: '8px',
                      border: '1px solid #ef4444',
                      backgroundColor: '#ffffff',
                      color: '#ef4444',
                      fontWeight: 600,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '6px',
                    }}
                  >
                    <XCircle size={16} /> Từ chối
                  </button>
                  <button
                    onClick={() => setApproveConfirmOpen(true)}
                    style={{
                      padding: '10px 22px',
                      borderRadius: '8px',
                      border: 'none',
                      backgroundColor: '#10b981',
                      color: '#ffffff',
                      fontWeight: 600,
                      cursor: 'pointer',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '6px',
                    }}
                  >
                    <CheckCircle size={16} /> Duyệt đơn này
                  </button>
                </div>
              )}
            </div>
          )}
        </Modal>
      )}

      {/* Confirm Approve Modal */}
      {approveConfirmOpen && selectedReg && (
        <Modal
          isOpen={approveConfirmOpen}
          onClose={() => setApproveConfirmOpen(false)}
          title="Xác Nhận Duyệt Đơn Đăng Ký"
        >
          <div style={{ padding: '8px 0' }}>
            <p style={{ fontSize: '14px', color: '#334155', lineHeight: 1.6 }}>
              Bạn có chắc chắn muốn duyệt đơn đăng ký của thương hiệu{' '}
              <strong>"{selectedReg.tenQuan}"</strong>?
            </p>
            <div style={{ marginTop: '12px', padding: '12px', backgroundColor: '#f0fdf4', border: '1px solid #bbf7d0', borderRadius: '8px', fontSize: '13px', color: '#166534' }}>
              ✓ Hệ thống sẽ tự động cập nhật tài khoản người dùng thành <strong>Cửa Hàng (CUAN_HANG)</strong>.<br />
              ✓ Tạo bản ghi cửa hàng chính thức trên hệ thống Food Route.<br />
              ✓ Gửi thông báo Realtime và cấp quyền quản lý cho chủ quán ngay lập tức.
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '20px' }}>
              <button
                onClick={() => setApproveConfirmOpen(false)}
                disabled={actionLoading}
                style={{ padding: '8px 16px', borderRadius: '6px', border: '1px solid #cbd5e1', backgroundColor: '#fff', cursor: 'pointer' }}
              >
                Hủy
              </button>
              <button
                onClick={handleApprove}
                disabled={actionLoading}
                style={{ padding: '8px 20px', borderRadius: '6px', border: 'none', backgroundColor: '#10b981', color: '#fff', fontWeight: 600, cursor: 'pointer' }}
              >
                {actionLoading ? 'Đang xử lý...' : 'Xác nhận duyệt'}
              </button>
            </div>
          </div>
        </Modal>
      )}

      {/* Reject Modal */}
      {rejectModalOpen && selectedReg && (
        <Modal
          isOpen={rejectModalOpen}
          onClose={() => setRejectModalOpen(false)}
          title="Từ Chối Đơn Đăng Ký Cửa Hàng"
        >
          <div style={{ padding: '8px 0' }}>
            <p style={{ fontSize: '14px', color: '#334155', marginBottom: '12px' }}>
              Vui lòng nhập lý do từ chối đơn của quán <strong>"{selectedReg.tenQuan}"</strong> để phản hồi cho người dùng:
            </p>
            <textarea
              rows={4}
              value={rejectReason}
              onChange={(e) => {
                setRejectReason(e.target.value);
                if (rejectError) setRejectError('');
              }}
              placeholder="Ví dụ: Hình ảnh CCCD không rõ nét, địa chỉ quán chưa đầy đủ hoặc số điện thoại không liên lạc được..."
              style={{
                width: '100%',
                padding: '10px',
                borderRadius: '8px',
                border: `1px solid ${rejectError ? '#ef4444' : '#cbd5e1'}`,
                fontSize: '13px',
                outline: 'none',
              }}
            />
            {rejectError && (
              <div style={{ color: '#ef4444', fontSize: '12px', marginTop: '6px' }}>{rejectError}</div>
            )}
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
              <button
                onClick={() => setRejectModalOpen(false)}
                disabled={actionLoading}
                style={{ padding: '8px 16px', borderRadius: '6px', border: '1px solid #cbd5e1', backgroundColor: '#fff', cursor: 'pointer' }}
              >
                Hủy
              </button>
              <button
                onClick={handleReject}
                disabled={actionLoading}
                style={{ padding: '8px 20px', borderRadius: '6px', border: 'none', backgroundColor: '#ef4444', color: '#fff', fontWeight: 600, cursor: 'pointer' }}
              >
                {actionLoading ? 'Đang gửi...' : 'Gửi từ chối'}
              </button>
            </div>
          </div>
        </Modal>
      )}

      {/* View Agreed Document Modal */}
      {viewDocModalOpen && (
        <Modal
          isOpen={viewDocModalOpen}
          onClose={() => setViewDocModalOpen(false)}
          title={`Văn Bản Thỏa Thuận: ${viewDocData?.tieuDe || 'Chi tiết điều khoản'}`}
        >
          {loadingDoc ? (
            <div style={{ padding: '32px', textAlign: 'center', color: '#64748b' }}>
              <RefreshCw size={24} className="animate-spin" />
              <div style={{ marginTop: '8px', fontSize: '13px' }}>Đang tải nội dung văn bản...</div>
            </div>
          ) : viewDocData ? (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ padding: '10px 14px', backgroundColor: '#f8fafc', borderRadius: '8px', border: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <span style={{ fontSize: '13px', fontWeight: 600, color: '#334155' }}>Phiên bản: v{viewDocData.soPhienBan}</span>
                <span style={{ fontSize: '12px', color: '#059669', fontWeight: 600, backgroundColor: '#ecfdf5', padding: '3px 8px', borderRadius: '12px', border: '1px solid #a7f3d0' }}>
                  ✓ Bằng chứng ký kết hợp lệ
                </span>
              </div>
              <div
                style={{
                  maxHeight: '380px',
                  overflowY: 'auto',
                  padding: '16px',
                  backgroundColor: '#ffffff',
                  border: '1px solid #e2e8f0',
                  borderRadius: '8px',
                  fontSize: '12.5px',
                  lineHeight: '1.6',
                  color: '#334155',
                  whiteSpace: 'pre-wrap',
                  fontFamily: 'sans-serif',
                }}
              >
                {viewDocData.noiDung}
              </div>
              <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                <button
                  onClick={() => setViewDocModalOpen(false)}
                  style={{
                    padding: '8px 18px',
                    borderRadius: '8px',
                    border: '1px solid #cbd5e1',
                    backgroundColor: '#ffffff',
                    color: '#334155',
                    fontWeight: 600,
                    cursor: 'pointer',
                  }}
                >
                  Đóng
                </button>
              </div>
            </div>
          ) : (
            <div style={{ padding: '24px', textAlign: 'center', color: '#64748b' }}>
              Không tìm thấy nội dung văn bản phiên bản này
            </div>
          )}
        </Modal>
      )}
    </div>
  );
};

