import React, { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { getSocket } from '../../api/socketClient';
import { MetricCard } from '../../components/MetricCard';
import {
  Ticket,
  Plus,
  Search,
  Filter,
  RefreshCw,
  Edit2,
  CheckCircle2,
  Clock,
  AlertTriangle,
  X,
  Tag,
  ToggleLeft,
  ToggleRight,
} from 'lucide-react';

export const RestaurantVouchers: React.FC = () => {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('ALL');

  // Modal State
  const [showModal, setShowModal] = useState(false);
  const [editingVoucher, setEditingVoucher] = useState<any>(null);

  // Form State
  const [formData, setFormData] = useState({
    maCode: '',
    tenVoucher: '',
    moTa: '',
    loaiGiam: 'VND', // 'VND' | 'PERCENT'
    giamGia: '',
    giaTriGiamToiDa: '',
    dieuKienDonToiThieu: '0',
    soLuongToiDa: '0',
    ngayBatDau: '',
    ngayHetHan: '',
    trangThai: 'HOAT_DONG',
  });

  const [formError, setFormError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  // Notification Toast
  const [toastMessage, setToastMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToastMessage({ text, type });
    setTimeout(() => setToastMessage(null), 4000);
  };

  const fetchVouchers = async (showLoadingState = true) => {
    if (showLoadingState) setLoading(true);
    setError(null);
    let endpoint = '/restaurant/vouchers';
    const params: string[] = [];
    if (statusFilter && statusFilter !== 'ALL') params.push(`status=${statusFilter}`);
    if (searchQuery.trim()) params.push(`search=${encodeURIComponent(searchQuery.trim())}`);
    if (params.length > 0) endpoint += `?${params.join('&')}`;

    try {
      const res = await apiFetch<any>(endpoint);
      if (res.data) {
        setData(res.data);
      }
    } catch (err: any) {
      setError(err.message || 'Không thể lấy danh sách voucher');
    } finally {
      if (showLoadingState) setLoading(false);
    }
  };

  useEffect(() => {
    fetchVouchers(true);
  }, [statusFilter]);

  // Realtime Socket listener for voucher usage and order events
  useEffect(() => {
    const socket = getSocket();
    if (socket) {
      const handleRealtimeUpdate = (payload: any) => {
        console.log('⚡ Realtime voucher update received:', payload);
        fetchVouchers(false);
      };

      const handleReconnect = () => {
        console.log('⚡ Socket reconnected: sync vouchers');
        fetchVouchers(false);
      };

      socket.on('voucher:updated', handleRealtimeUpdate);
      socket.on('order:created', handleRealtimeUpdate);
      socket.on('order:status_changed', handleRealtimeUpdate);
      socket.on('connect', handleReconnect);

      return () => {
        socket.off('voucher:updated', handleRealtimeUpdate);
        socket.off('order:created', handleRealtimeUpdate);
        socket.off('order:status_changed', handleRealtimeUpdate);
        socket.off('connect', handleReconnect);
      };
    }
  }, [statusFilter, searchQuery]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    fetchVouchers(true);
  };

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  const formatDateTime = (dateStr?: string) => {
    if (!dateStr) return 'Không giới hạn';
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return 'Không xác định';
    return d.toLocaleString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const formatInputDateTime = (dateStr?: string) => {
    if (!dateStr) return '';
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return '';
    const tzOffset = d.getTimezoneOffset() * 60000;
    return new Date(d.getTime() - tzOffset).toISOString().slice(0, 16);
  };

  const openCreateModal = () => {
    setEditingVoucher(null);
    const now = new Date();
    const tzOffset = now.getTimezoneOffset() * 60000;
    const nowStr = new Date(now.getTime() - tzOffset).toISOString().slice(0, 16);

    const nextMonth = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
    const nextMonthStr = new Date(nextMonth.getTime() - tzOffset).toISOString().slice(0, 16);

    setFormData({
      maCode: '',
      tenVoucher: '',
      moTa: '',
      loaiGiam: 'VND',
      giamGia: '',
      giaTriGiamToiDa: '',
      dieuKienDonToiThieu: '0',
      soLuongToiDa: '0',
      ngayBatDau: nowStr,
      ngayHetHan: nextMonthStr,
      trangThai: 'HOAT_DONG',
    });
    setFormError(null);
    setShowModal(true);
  };

  const openEditModal = (v: any) => {
    setEditingVoucher(v);
    setFormData({
      maCode: v.maCode,
      tenVoucher: v.tenVoucher,
      moTa: v.moTa || '',
      loaiGiam: v.loaiGiam || 'VND',
      giamGia: String(v.giamGia || ''),
      giaTriGiamToiDa: v.giaTriGiamToiDa ? String(v.giaTriGiamToiDa) : '',
      dieuKienDonToiThieu: String(v.dieuKienDonToiThieu || 0),
      soLuongToiDa: String(v.soLuongToiDa || 0),
      ngayBatDau: formatInputDateTime(v.ngayBatDau),
      ngayHetHan: formatInputDateTime(v.ngayHetHan),
      trangThai: v.trangThai || 'HOAT_DONG',
    });
    setFormError(null);
    setShowModal(true);
  };

  const handleSaveVoucher = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    const maCode = formData.maCode.trim().toUpperCase();
    if (!maCode) {
      setFormError('Vui lòng nhập Mã Voucher');
      return;
    }
    if (!editingVoucher && !/^[A-Z0-9_-]{3,50}$/.test(maCode)) {
      setFormError('Mã voucher từ 3-50 ký tự, chỉ gồm chữ cái in hoa, số, gạch (-) hoặc (_)');
      return;
    }

    if (!formData.tenVoucher.trim()) {
      setFormError('Vui lòng nhập Tên Voucher');
      return;
    }

    const giamGia = Number(formData.giamGia);
    if (isNaN(giamGia) || giamGia <= 0) {
      setFormError('Mức giảm giá phải lớn hơn 0');
      return;
    }

    if (formData.loaiGiam === 'PERCENT' && (giamGia <= 0 || giamGia > 100)) {
      setFormError('Phần trăm giảm phải từ 1% đến 100%');
      return;
    }

    const giaTriGiamToiDa = formData.giaTriGiamToiDa ? Number(formData.giaTriGiamToiDa) : undefined;
    const dieuKienDonToiThieu = Math.max(Number(formData.dieuKienDonToiThieu || 0), 0);
    const soLuongToiDa = Math.max(Number(formData.soLuongToiDa || 0), 0);

    const ngayBatDau = formData.ngayBatDau ? new Date(formData.ngayBatDau) : undefined;
    const ngayHetHan = formData.ngayHetHan ? new Date(formData.ngayHetHan) : undefined;

    if (ngayHetHan && ngayBatDau && ngayHetHan <= ngayBatDau) {
      setFormError('Thời gian kết thúc phải sau thời gian bắt đầu');
      return;
    }

    setSubmitting(true);
    try {
      if (editingVoucher) {
        // Update
        const payload: any = {
          tenVoucher: formData.tenVoucher.trim(),
          moTa: formData.moTa.trim(),
          giamGia,
          loaiGiam: formData.loaiGiam,
          giaTriGiamToiDa,
          dieuKienDonToiThieu,
          soLuongToiDa,
          ngayBatDau: ngayBatDau ? ngayBatDau.toISOString() : undefined,
          ngayHetHan: ngayHetHan ? ngayHetHan.toISOString() : undefined,
          trangThai: formData.trangThai,
        };
        await apiFetch(`/restaurant/vouchers/${editingVoucher.maVoucher}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
        showToast(`Đã cập nhật voucher ${editingVoucher.maCode} thành công`);
      } else {
        // Create
        const payload: any = {
          maCode,
          tenVoucher: formData.tenVoucher.trim(),
          moTa: formData.moTa.trim(),
          giamGia,
          loaiGiam: formData.loaiGiam,
          giaTriGiamToiDa,
          dieuKienDonToiThieu,
          soLuongToiDa,
          ngayBatDau: ngayBatDau ? ngayBatDau.toISOString() : undefined,
          ngayHetHan: ngayHetHan ? ngayHetHan.toISOString() : undefined,
          trangThai: formData.trangThai,
        };
        await apiFetch('/restaurant/vouchers', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        showToast(`Đã tạo thành công voucher ${maCode}`);
      }

      setShowModal(false);
      fetchVouchers();
    } catch (err: any) {
      setFormError(err.message || 'Lỗi lưu thông tin voucher');
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleStatus = async (v: any) => {
    try {
      const targetStatus = v.trangThai === 'HOAT_DONG' ? 'TAM_TAT' : 'HOAT_DONG';
      await apiFetch(`/restaurant/vouchers/${v.maVoucher}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ trangThai: targetStatus }),
      });
      showToast(`Đã ${targetStatus === 'HOAT_DONG' ? 'bật' : 'tạm tắt'} voucher ${v.maCode}`);
      fetchVouchers();
    } catch (err: any) {
      showToast(err.message || 'Không thể đổi trạng thái voucher', 'error');
    }
  };

  const summary = data?.summary || {};
  const voucherList = data?.vouchers || [];

  // Sort: active/upcoming first, inactive (TAM_TAT, HET_LUOT, HET_HAN) to bottom
  const sortedVouchers = useMemo(() => {
    const INACTIVE = new Set(['TAM_TAT', 'HET_LUOT', 'HET_HAN']);
    const active = voucherList.filter((v: any) => !INACTIVE.has(v.computedStatus));
    const inactive = voucherList.filter((v: any) => INACTIVE.has(v.computedStatus));
    return [...active, ...inactive];
  }, [voucherList]);

  const getStatusBadge = (statusKey: string) => {
    switch (statusKey) {
      case 'DANG_HOAT_DONG':
        return <span style={{ padding: '4px 10px', borderRadius: '12px', background: '#ecfdf5', color: '#10b981', fontSize: '12px', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px' }}><CheckCircle2 size={13} /> Đang hoạt động</span>;
      case 'SAP_DIEN_RA':
        return <span style={{ padding: '4px 10px', borderRadius: '12px', background: '#eff6ff', color: '#3b82f6', fontSize: '12px', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px' }}><Clock size={13} /> Sắp diễn ra</span>;
      case 'TAM_TAT':
        return <span style={{ padding: '4px 10px', borderRadius: '12px', background: '#f1f5f9', color: '#64748b', fontSize: '12px', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px' }}><ToggleLeft size={13} /> Tạm tắt</span>;
      case 'HET_HAN':
        return <span style={{ padding: '4px 10px', borderRadius: '12px', background: '#fef2f2', color: '#ef4444', fontSize: '12px', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px' }}><AlertTriangle size={13} /> Đã hết hạn</span>;
      case 'HET_LUOT':
        return <span style={{ padding: '4px 10px', borderRadius: '12px', background: '#fffbeb', color: '#f59e0b', fontSize: '12px', fontWeight: 700, display: 'inline-flex', alignItems: 'center', gap: '4px' }}><AlertTriangle size={13} /> Hết lượt</span>;
      default:
        return <span style={{ padding: '4px 10px', borderRadius: '12px', background: '#f1f5f9', color: '#64748b', fontSize: '12px', fontWeight: 700 }}>{statusKey}</span>;
    }
  };

  return (
    <div>
      {/* Toast Notification */}
      {toastMessage && (
        <div
          style={{
            position: 'fixed',
            bottom: '24px',
            right: '24px',
            zIndex: 9999,
            background: toastMessage.type === 'success' ? '#10b981' : '#ef4444',
            color: '#ffffff',
            padding: '12px 20px',
            borderRadius: '12px',
            boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
            fontWeight: 700,
            fontSize: '14px',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
          }}
        >
          {toastMessage.text}
        </div>
      )}

      {/* Header */}
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
        <div>
          <h1 className="page-title">Chương Trình Voucher Khuyến Mãi</h1>
          <p className="page-subtitle">Tạo và quản lý các mã giảm giá thu hút khách hàng cho quán</p>
        </div>

        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          <button className="btn" onClick={() => fetchVouchers()} style={{ background: '#ffffff', border: '1px solid #e2e8f0' }} title="Tải lại dữ liệu">
            <RefreshCw size={16} color="#64748b" />
          </button>
          <button className="btn btn-primary" onClick={openCreateModal} style={{ background: '#fc6011', border: 'none', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Plus size={18} /> Tạo Voucher Mới
          </button>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid-metrics" style={{ marginBottom: '24px' }}>
        <MetricCard label="Tổng Voucher" value={summary.totalVouchers || 0} icon={Ticket} color="#fc6011" bgColor="#fff4ee" />
        <MetricCard label="Đang Hoạt Động" value={summary.activeVouchers || 0} icon={CheckCircle2} color="#10b981" bgColor="#ecfdf5" />
        <MetricCard label="Tổng Lượt Đã Dùng" value={`${summary.totalUsedCount || 0} lượt`} icon={Tag} color="#3b82f6" bgColor="#eff6ff" />
        <MetricCard label="Sắp Hết Hạn (7 ngày)" value={summary.expiringSoonCount || 0} icon={Clock} color="#f59e0b" bgColor="#fffbeb" />
      </div>

      {/* Table Section */}
      <div className="card-table">
        <div className="table-toolbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '12px', padding: '16px 20px' }}>
          <form onSubmit={handleSearchSubmit} style={{ display: 'flex', gap: '8px', alignItems: 'center', flex: 1, minWidth: '260px' }}>
            <div style={{ position: 'relative', width: '100%', maxWidth: '320px' }}>
              <Search size={16} color="#94a3b8" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)' }} />
              <input
                type="text"
                className="form-control"
                placeholder="Tìm theo mã voucher hoặc tên..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                style={{ paddingLeft: '36px', fontSize: '13px', borderRadius: '10px' }}
              />
            </div>
            <button type="submit" className="btn btn-secondary" style={{ padding: '8px 14px', fontSize: '13px' }}>Tìm kiếm</button>
          </form>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Filter size={15} color="#64748b" />
            <span style={{ fontSize: '13px', fontWeight: 600, color: '#64748b' }}>Trạng thái:</span>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="form-control"
              style={{ fontSize: '13px', padding: '6px 12px', borderRadius: '10px', background: '#f8fafc' }}
            >
              <option value="ALL">Tất cả voucher</option>
              <option value="DANG_HOAT_DONG">Đang hoạt động</option>
              <option value="SAP_DIEN_RA">Sắp diễn ra</option>
              <option value="HET_HAN">Đã hết hạn</option>
              <option value="TAM_TAT">Tạm tắt</option>
              <option value="HET_LUOT">Hết lượt sử dụng</option>
            </select>
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '60px 0' }}>
            <div className="loading-spinner" />
            <p style={{ marginTop: '14px', color: '#64748b', fontSize: '13px' }}>Đang tải danh sách voucher...</p>
          </div>
        ) : error ? (
          <div style={{ textAlign: 'center', padding: '40px 20px', background: '#fef2f2', margin: '20px', borderRadius: '12px' }}>
            <p style={{ color: '#ef4444', fontWeight: 700 }}>{error}</p>
            <button className="btn btn-primary" onClick={() => fetchVouchers()} style={{ marginTop: '12px' }}>Thử lại</button>
          </div>
        ) : voucherList.length === 0 ? (
          <div className="empty-state" style={{ padding: '60px 20px', textAlign: 'center' }}>
            <Ticket size={48} color="#cbd5e1" style={{ marginBottom: '12px' }} />
            <h3 style={{ fontSize: '16px', fontWeight: 700, color: '#334155' }}>Chưa có voucher nào</h3>
            <p style={{ color: '#64748b', fontSize: '13px', marginTop: '4px', marginBottom: '16px' }}>
              {statusFilter !== 'ALL' || searchQuery ? 'Không tìm thấy voucher phù hợp với bộ lọc' : 'Tạo chương trình voucher đầu tiên để thu hút thêm đơn hàng'}
            </p>
            <button className="btn btn-primary" onClick={openCreateModal} style={{ background: '#fc6011', border: 'none' }}>
              + Tạo Voucher Mới
            </button>
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table className="data-table" style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ background: '#f8fafc', textTransform: 'uppercase', fontSize: '11px', color: '#64748b', letterSpacing: '0.5px' }}>
                  <th style={{ padding: '12px 16px', textAlign: 'center', width: '50px' }}>STT</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left' }}>Mã Voucher</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left' }}>Mức Giảm</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left' }}>Đơn Tối Thiểu</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left' }}>Thời Gian</th>
                  <th style={{ padding: '12px 16px', textAlign: 'left' }}>Đã Dùng / Tổng</th>
                  <th style={{ padding: '12px 16px', textAlign: 'center' }}>Trạng Thái</th>
                  <th style={{ padding: '12px 16px', textAlign: 'center' }}>Bật/Tắt</th>
                  <th style={{ padding: '12px 16px', textAlign: 'right' }}>Thao Tác</th>
                </tr>
              </thead>
              <tbody>
                {sortedVouchers.map((v: any, idx: number) => {
                  const INACTIVE_STATUS = new Set(['TAM_TAT', 'HET_LUOT', 'HET_HAN']);
                  const isInactive = INACTIVE_STATUS.has(v.computedStatus);
                  const isPercent = v.loaiGiam === 'PERCENT';
                  const usedCount = v.soLuongDaSuDung || 0;
                  const totalLimit = v.soLuongToiDa || 0;
                  const usagePercent = totalLimit > 0 ? Math.min(Math.round((usedCount / totalLimit) * 100), 100) : 0;

                  return (
                    <tr
                      key={v.maVoucher}
                      style={{
                        borderBottom: '1px solid #f1f5f9',
                        ...(isInactive ? { background: '#f8f8f8', opacity: 0.7 } : {}),
                      }}
                    >
                      {/* STT */}
                      <td style={{ padding: '14px 16px', textAlign: 'center', fontWeight: 600, color: isInactive ? '#b0b8c1' : '#64748b' }}>
                        {idx + 1}
                      </td>
                      {/* Code & Name */}
                      <td style={{ padding: '14px 16px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                          <span style={{
                            background: isInactive ? '#f1f5f9' : '#fff4ee',
                            color: isInactive ? '#94a3b8' : '#fc6011',
                            border: `1px dashed ${isInactive ? '#cbd5e1' : '#ff8a50'}`,
                            padding: '4px 10px', borderRadius: '8px', fontWeight: 800, fontSize: '13px', letterSpacing: '0.5px',
                            textDecoration: isInactive ? 'line-through' : 'none',
                          }}>
                            {v.maCode}
                          </span>
                        </div>
                        <div style={{ fontWeight: 700, color: isInactive ? '#94a3b8' : '#0f172a', marginTop: '6px', fontSize: '13px' }}>{v.tenVoucher}</div>
                        {v.moTa && <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '2px' }}>{v.moTa}</div>}
                      </td>

                      {/* Discount Amount */}
                      <td style={{ padding: '14px 16px' }}>
                        <div style={{ fontWeight: 800, color: isInactive ? '#94a3b8' : '#10b981', fontSize: '14px' }}>
                          {isPercent ? `Giảm ${v.giamGia}%` : `Giảm ${formatVND(v.giamGia)}`}
                        </div>
                        {isPercent && v.giaTriGiamToiDa > 0 && (
                          <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '2px' }}>Tối đa {formatVND(v.giaTriGiamToiDa)}</div>
                        )}
                      </td>

                      {/* Min Order */}
                      <td style={{ padding: '14px 16px', fontSize: '13px', fontWeight: 600, color: isInactive ? '#94a3b8' : '#334155' }}>
                        {v.dieuKienDonToiThieu > 0 ? formatVND(v.dieuKienDonToiThieu) : '0 ₫ (Mọi đơn)'}
                      </td>

                      {/* Valid Period */}
                      <td style={{ padding: '14px 16px', fontSize: '12px', color: isInactive ? '#94a3b8' : '#475569' }}>
                        <div>Từ: {formatDateTime(v.ngayBatDau)}</div>
                        <div>Đến: {formatDateTime(v.ngayHetHan)}</div>
                      </td>

                      {/* Usage */}
                      <td style={{ padding: '14px 16px', minWidth: '140px' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', fontWeight: 700, marginBottom: '4px' }}>
                          <span style={{ color: isInactive ? '#94a3b8' : undefined }}>{usedCount} lượt dùng</span>
                          <span style={{ color: '#94a3b8' }}>{totalLimit > 0 ? `/ ${totalLimit}` : 'Không giới hạn'}</span>
                        </div>
                        {totalLimit > 0 && (
                          <div style={{ width: '100%', height: '6px', background: '#e2e8f0', borderRadius: '3px', overflow: 'hidden' }}>
                            <div style={{ width: `${usagePercent}%`, height: '100%', background: usagePercent >= 100 ? '#ef4444' : isInactive ? '#cbd5e1' : '#fc6011' }} />
                          </div>
                        )}
                      </td>

                      {/* Status */}
                      <td style={{ padding: '14px 16px', textAlign: 'center' }}>
                        {getStatusBadge(v.computedStatus)}
                      </td>

                      {/* Active Toggle */}
                      <td style={{ padding: '14px 16px', textAlign: 'center' }}>
                        <button
                          onClick={() => handleToggleStatus(v)}
                          style={{ background: 'none', border: 'none', cursor: 'pointer', padding: '4px' }}
                          title={v.trangThai === 'HOAT_DONG' ? 'Đang bật - Bấm để tạm tắt' : 'Đang tắt - Bấm để bật'}
                        >
                          {v.trangThai === 'HOAT_DONG' ? (
                            <ToggleRight size={28} color="#10b981" />
                          ) : (
                            <ToggleLeft size={28} color="#cbd5e1" />
                          )}
                        </button>
                      </td>

                      {/* Actions — edit only, no delete */}
                      <td style={{ padding: '14px 16px', textAlign: 'right' }}>
                        <button
                          className="btn btn-secondary"
                          onClick={() => openEditModal(v)}
                          style={{ padding: '6px 10px', fontSize: '12px', display: 'inline-flex', alignItems: 'center', gap: '4px' }}
                        >
                          <Edit2 size={13} /> Sửa
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Create / Edit Modal */}
      {showModal && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(15,23,42,0.6)', backdropFilter: 'blur(4px)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '16px' }}>
          <div style={{ background: '#ffffff', width: '100%', maxWidth: '600px', borderRadius: '18px', boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1)', overflow: 'hidden', maxHeight: '90vh', display: 'flex', flexDirection: 'column' }}>
            {/* Modal Header */}
            <div style={{ padding: '16px 20px', borderBottom: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#f8fafc' }}>
              <h3 style={{ fontSize: '16px', fontWeight: 800, color: '#0f172a', margin: 0, display: 'flex', alignItems: 'center', gap: '8px' }}>
                <Ticket size={20} color="#fc6011" />
                {editingVoucher ? `Chỉnh Sửa Voucher ${editingVoucher.maCode}` : 'Tạo Chương Trình Voucher Mới'}
              </h3>
              <button onClick={() => setShowModal(false)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#64748b' }}>
                <X size={20} />
              </button>
            </div>

            {/* Modal Body */}
            <form onSubmit={handleSaveVoucher} style={{ overflowY: 'auto', padding: '20px', flex: 1 }}>
              {formError && (
                <div style={{ background: '#fef2f2', border: '1px solid #fecaca', color: '#ef4444', padding: '10px 14px', borderRadius: '10px', fontSize: '13px', fontWeight: 600, marginBottom: '16px' }}>
                  {formError}
                </div>
              )}

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '14px' }}>
                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Mã Voucher *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="VD: KHUYENMAI20K"
                    value={formData.maCode}
                    onChange={(e) => setFormData({ ...formData, maCode: e.target.value.toUpperCase() })}
                    disabled={!!editingVoucher}
                    style={{ textTransform: 'uppercase', fontWeight: 700, letterSpacing: '0.5px' }}
                    required
                  />
                </div>

                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Tên Chương Trình *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="VD: Giảm 20K Đơn Đầu Tiên"
                    value={formData.tenVoucher}
                    onChange={(e) => setFormData({ ...formData, tenVoucher: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div style={{ marginBottom: '14px' }}>
                <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Mô Tả Khuyến Mãi</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="Mô tả điều kiện khuyến mãi ngắn gọn..."
                  value={formData.moTa}
                  onChange={(e) => setFormData({ ...formData, moTa: e.target.value })}
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px', marginBottom: '14px' }}>
                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Loại Giảm Giá</label>
                  <select
                    className="form-control"
                    value={formData.loaiGiam}
                    onChange={(e) => setFormData({ ...formData, loaiGiam: e.target.value })}
                    disabled={editingVoucher && (editingVoucher.soLuongDaSuDung || 0) > 0}
                  >
                    <option value="VND">Cố định (₫)</option>
                    <option value="PERCENT">Phần trăm (%)</option>
                  </select>
                </div>

                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Giá Trị Giảm *</label>
                  <input
                    type="number"
                    className="form-control"
                    placeholder={formData.loaiGiam === 'PERCENT' ? 'VD: 20 (%)' : 'VD: 20000 (₫)'}
                    value={formData.giamGia}
                    onChange={(e) => setFormData({ ...formData, giamGia: e.target.value })}
                    disabled={editingVoucher && (editingVoucher.soLuongDaSuDung || 0) > 0}
                    required
                  />
                </div>

                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Giảm Tối Đa (₫)</label>
                  <input
                    type="number"
                    className="form-control"
                    placeholder="Áp dụng khi giảm %"
                    value={formData.giaTriGiamToiDa}
                    onChange={(e) => setFormData({ ...formData, giaTriGiamToiDa: e.target.value })}
                    disabled={formData.loaiGiam !== 'PERCENT'}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '14px' }}>
                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Đơn Tối Thiểu (₫)</label>
                  <input
                    type="number"
                    className="form-control"
                    placeholder="0 = Không giới hạn"
                    value={formData.dieuKienDonToiThieu}
                    onChange={(e) => setFormData({ ...formData, dieuKienDonToiThieu: e.target.value })}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Tổng Số Lượt Phát Hành</label>
                  <input
                    type="number"
                    className="form-control"
                    placeholder="0 = Không giới hạn lượt"
                    value={formData.soLuongToiDa}
                    onChange={(e) => setFormData({ ...formData, soLuongToiDa: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '16px' }}>
                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Ngày Bắt Đầu</label>
                  <input
                    type="datetime-local"
                    className="form-control"
                    value={formData.ngayBatDau}
                    onChange={(e) => setFormData({ ...formData, ngayBatDau: e.target.value })}
                  />
                </div>

                <div>
                  <label style={{ fontSize: '12px', fontWeight: 700, color: '#334155', display: 'block', marginBottom: '6px' }}>Ngày Kết Thúc</label>
                  <input
                    type="datetime-local"
                    className="form-control"
                    value={formData.ngayHetHan}
                    onChange={(e) => setFormData({ ...formData, ngayHetHan: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ marginBottom: '20px', background: '#f8fafc', padding: '12px', borderRadius: '10px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                  <div style={{ fontSize: '13px', fontWeight: 700, color: '#0f172a' }}>Trạng Thái Hoạt Động</div>
                  <div style={{ fontSize: '11px', color: '#64748b' }}>Cho phép khách hàng áp dụng voucher này khi đặt hàng</div>
                </div>
                <select
                  value={formData.trangThai}
                  onChange={(e) => setFormData({ ...formData, trangThai: e.target.value })}
                  className="form-control"
                  style={{ width: 'auto', fontSize: '13px', fontWeight: 700 }}
                >
                  <option value="HOAT_DONG">HOẠT ĐỘNG</option>
                  <option value="TAM_TAT">TẠM TẮT</option>
                </select>
              </div>

              {/* Modal Actions */}
              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', paddingTop: '10px', borderTop: '1px solid #e2e8f0' }}>
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>Hủy</button>
                <button type="submit" className="btn btn-primary" disabled={submitting} style={{ background: '#fc6011', border: 'none' }}>
                  {submitting ? 'Đang lưu...' : editingVoucher ? 'Cập Nhật Voucher' : 'Tạo Voucher'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
