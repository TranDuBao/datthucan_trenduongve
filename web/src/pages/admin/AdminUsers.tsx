import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { StatusBadge } from '../../components/StatusBadge';
import { Modal } from '../../components/Modal';
import { NotificationModal } from '../../components/NotificationModal';
import { UserDetailModal } from './users/UserDetailModal';
import { UserFormModal } from './users/UserFormModal';
import { UserLockModal } from './users/UserLockModal';
import { parseCCCDImage, formatDateVN, toISODate } from '../../utils/ocrService';
import { getImageUrl, handleImageError, isValidImageUrl } from '../../utils/imageUtils';
import {
  Search,
  Plus,
  Eye,
  Edit,
  Lock,
  Unlock,
  Key,
} from 'lucide-react';

export const AdminUsers: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  // Modals state
  const [detailModalOpen, setDetailModalOpen] = useState(false);
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [lockModalOpen, setLockModalOpen] = useState(false);
  const [passwordModalOpen, setPasswordModalOpen] = useState(false);

  // Active target user & submitting flags
  const [targetUser, setTargetUser] = useState<any>(null);
  const [userDetailData, setUserDetailData] = useState<any>(null);
  const [submitting, setSubmitting] = useState(false);
  const [scanningCCCD, setScanningCCCD] = useState(false);
  const [ocrNotice, setOcrNotice] = useState<string | null>(null);

  // Notification Modal State
  const [notifyModal, setNotifyModal] = useState<{
    isOpen: boolean;
    type: 'success' | 'error' | 'warning' | 'info';
    title: string;
    message: string | string[];
  }>({
    isOpen: false,
    type: 'info',
    title: '',
    message: '',
  });

  const showNotify = (type: 'success' | 'error' | 'warning' | 'info', title: string, message: string | string[]) => {
    setNotifyModal({ isOpen: true, type, title, message });
  };

  // Forms state
  const [addForm, setAddForm] = useState<any>({
    tenDangNhap: '',
    matKhau: '',
    loaiTaiKhoan: 'KHACH_HANG',
    hoTen: '',
    sdt: '',
    email: '',
    diaChi: '',
    avatar: '',
    ngaySinh: '',
    tenQuan: '',
    hoTenChuQuan: '',
    diaChiThuongTru: '',
    ngaySinhChuQuan: '',
    soCCCD: '',
    tenNganHang: 'Vietcombank (VCB)',
    soTaiKhoanNganHang: '',
    tenChuTaiKhoan: '',
    cccdMatTruoc: '',
    cccdMatSau: '',
  });

  const [editForm, setEditForm] = useState<any>({
    loaiTaiKhoan: 'KHACH_HANG',
    hoTen: '',
    sdt: '',
    email: '',
    diaChi: '',
    avatar: '',
    ngaySinh: '',
    trangThai: 'HOAT_DONG',
    tenQuan: '',
    hoTenChuQuan: '',
    diaChiThuongTru: '',
    ngaySinhChuQuan: '',
    soCCCD: '',
    tenNganHang: 'Vietcombank (VCB)',
    soTaiKhoanNganHang: '',
    tenChuTaiKhoan: '',
    cccdMatTruoc: '',
    cccdMatSau: '',
  });

  const [lockForm, setLockForm] = useState({
    lockType: 'TAM_THOI' as 'TAM_THOI' | 'VINH_VIEN' | 'MO_KHOA',
    presetDays: 7,
    customDate: '',
    lyDoKhoa: '',
  });

  const [passwordForm, setPasswordForm] = useState({
    matKhauMoi: '',
    xacNhanMatKhau: '',
  });

  const fetchUsers = () => {
    setLoading(true);
    const query = new URLSearchParams({
      page: '1',
      limit: '500',
      search: search.trim(),
      role: '',
      status: statusFilter,
    }).toString();

    apiFetch<any>(`/admin/users?${query}`)
      .then(async (res) => {
        const rawData = res.data || res;
        const items = rawData.items || [];

        let stores: any[] = [];
        try {
          const storesRes = await apiFetch<any>('/admin/restaurants?limit=100');
          stores = storesRes.items || (storesRes as any).data?.items || (storesRes as any).data || [];
        } catch (_) {}

        const enrichedItems = items.map((u: any) => {
          if (u.loaiTaiKhoan === 'CUAN_HANG' && (!u.cuaHang || !u.cuaHang.img)) {
            const matchedStore = stores.find(
              (s: any) => s.maTaiKhoan === u.maTaiKhoan || (s.taiKhoanLienKet && s.taiKhoanLienKet.maTaiKhoan === u.maTaiKhoan)
            );
            if (matchedStore) {
              return { ...u, cuaHang: { ...u.cuaHang, ...matchedStore } };
            }
          }
          return u;
        });

        setData({ ...rawData, items: enrichedItems });
      })
      .catch((err) => console.error('Lỗi tải danh sách người dùng:', err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchUsers();
  }, [page, search, roleFilter, statusFilter]);

  // View Detailed Info with fallback safety
  const handleOpenDetail = async (u: any) => {
    setTargetUser(u);
    setUserDetailData({
      taiKhoan: u,
      khachHang: u.khachHang || null,
      cuaHang: u.cuaHang || null,
      orderStats: { totalOrders: 0, totalSpent: 0 },
    });
    setDetailModalOpen(true);
    try {
      const res = await apiFetch<any>(`/admin/users/${u.maTaiKhoan}`);
      if (res && (res.data || res.taiKhoan)) {
        setUserDetailData(res.data || res);
      }
    } catch (err: any) {
      console.warn('⚠️ Endpoint /admin/users/:id chưa cập nhật hoặc lỗi, hiển thị dữ liệu có sẵn:', err);
    }
  };

  // AI OCR Scan CCCD Function
  const handleScanCCCD = async (imageSrc: string, side: 'front' | 'back' | 'both', formType: 'add' | 'edit') => {
    if (!imageSrc) {
      showNotify('warning', 'Chưa Chọn Ảnh CCCD', 'Vui lòng upload ảnh CCCD trước khi bấm AI Quét!');
      return;
    }
    setScanningCCCD(true);
    setOcrNotice(null);
    try {
      let ocrData: any = null;

      const endpoints = ['/admin/scan-cccd', '/auth/scan-cccd', '/restaurant/scan-cccd'];
      for (const ep of endpoints) {
        try {
          const res = await apiFetch<any>(ep, {
            method: 'POST',
            body: JSON.stringify({ image: imageSrc, side }),
          });
          const fetched = res?.data || res?.payload || res;
          if (fetched && (fetched.soCCCD || fetched.hoTen || fetched.success)) {
            ocrData = fetched;
            break;
          }
        } catch (_) {
          // Try next endpoint
        }
      }

      if (!ocrData || (!ocrData.soCCCD && !ocrData.hoTen)) {
        ocrData = await parseCCCDImage(imageSrc);
      }
      if (ocrData && (ocrData.success || ocrData.soCCCD || ocrData.hoTen)) {
        if (formType === 'add') {
          setAddForm((prev: any) => ({
            ...prev,
            soCCCD: ocrData.soCCCD || prev.soCCCD,
            hoTenChuQuan: ocrData.hoTen || prev.hoTenChuQuan || prev.hoTen,
            diaChiThuongTru: ocrData.diaChiThuongTru || prev.diaChiThuongTru || prev.diaChi,
            ngaySinhChuQuan: ocrData.ngaySinh || prev.ngaySinhChuQuan,
            tenChuTaiKhoan: ocrData.hoTen || prev.tenChuTaiKhoan,
          }));
        } else {
          setEditForm((prev: any) => ({
            ...prev,
            soCCCD: ocrData.soCCCD || prev.soCCCD,
            hoTenChuQuan: ocrData.hoTen || prev.hoTenChuQuan || prev.hoTen,
            diaChiThuongTru: ocrData.diaChiThuongTru || prev.diaChiThuongTru || prev.diaChi,
            ngaySinhChuQuan: ocrData.ngaySinh ? formatDateVN(ocrData.ngaySinh) : prev.ngaySinhChuQuan,
            tenChuTaiKhoan: ocrData.hoTen || prev.tenChuTaiKhoan,
          }));
        }
        const foundStr = [
          ocrData.soCCCD ? `Số CCCD: ${ocrData.soCCCD}` : '',
          ocrData.hoTen ? `Họ tên: ${ocrData.hoTen}` : '',
        ].filter(Boolean).join(' • ');
        setOcrNotice(`🤖 AI OCR đã trích xuất thành công! ${foundStr}`);
        showNotify('success', 'AI Quét Thành Công', `Đã tự động trích xuất dữ liệu CCCD thành công.`);
      } else {
        showNotify('warning', 'Không Thể Đọc Ảnh CCCD', 'AI không trích xuất được chữ từ ảnh này. Vui lòng tải ảnh CCCD chụp thẳng, rõ nét hơn.');
      }
    } catch (err: any) {
      showNotify('error', 'Lỗi Quét AI CCCD', err.message || 'Lỗi khi quét dữ liệu từ CCCD.');
    } finally {
      setScanningCCCD(false);
    }
  };

  // Create User
  const handleCreateSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const missing: string[] = [];
    if (!addForm.tenDangNhap.trim()) missing.push('Tên Đăng Nhập');
    if (!addForm.matKhau.trim()) missing.push('Mật Khẩu');
    if (!addForm.hoTen.trim()) missing.push('Họ & Tên');

    if (addForm.loaiTaiKhoan === 'CUAN_HANG' && !addForm.tenQuan.trim()) {
      missing.push('Tên Nhà Hàng / Quán');
    }

    if (missing.length > 0) {
      showNotify('warning', 'Thiếu Thông Tin Bắt Buộc', missing);
      return;
    }

    const payload = {
      ...addForm,
      ngaySinh: toISODate(addForm.ngaySinh),
      ngaySinhChuQuan: toISODate(addForm.ngaySinhChuQuan),
    };

    setSubmitting(true);
    try {
      await apiFetch('/admin/users', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      showNotify('success', 'Tạo Thành Công', 'Tự động khởi tạo tài khoản người dùng mới thành công!');
      setCreateModalOpen(false);
      setOcrNotice(null);
      fetchUsers();
    } catch (err: any) {
      showNotify('error', 'Tạo Người Dùng Thất Bại', err.message || 'Lỗi khi tạo người dùng.');
    } finally {
      setSubmitting(false);
    }
  };

  // Edit User Profile
  const handleOpenEdit = (u: any) => {
    setTargetUser(u);
    setOcrNotice(null);
    setEditForm({
      loaiTaiKhoan: u.loaiTaiKhoan || 'KHACH_HANG',
      hoTen: u.khachHang?.hoTen || '',
      sdt: u.khachHang?.sdt || u.cuaHang?.sdt || '',
      email: u.khachHang?.email || u.tenDangNhap || '',
      diaChi: u.khachHang?.diaChi || u.cuaHang?.diaChi || '',
      avatar: u.khachHang?.avatar || u.cuaHang?.img || '',
      ngaySinh: u.khachHang?.ngaySinh ? formatDateVN(String(u.khachHang.ngaySinh)) : '',
      trangThai: u.trangThai || 'HOAT_DONG',
      tenQuan: u.cuaHang?.tenQuan || '',
      hoTenChuQuan: u.cuaHang?.hoTenChuQuan || u.khachHang?.hoTen || '',
      diaChiThuongTru: u.cuaHang?.diaChiThuongTru || u.khachHang?.diaChi || '',
      ngaySinhChuQuan: u.cuaHang?.ngaySinhChuQuan ? formatDateVN(String(u.cuaHang.ngaySinhChuQuan)) : '',
      soCCCD: u.cuaHang?.soCCCD || '',
      tenNganHang: u.cuaHang?.tenNganHang || 'Vietcombank (VCB)',
      soTaiKhoanNganHang: u.cuaHang?.soTaiKhoanNganHang || '',
      tenChuTaiKhoan: u.cuaHang?.tenChuTaiKhoan || u.cuaHang?.hoTenChuQuan || '',
      cccdMatTruoc: u.cuaHang?.cccdMatTruoc || '',
      cccdMatSau: u.cuaHang?.cccdMatSau || '',
    });
    setEditModalOpen(true);
  };

  const handleEditSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!targetUser) return;
    const payload = {
      ...editForm,
      ngaySinh: toISODate(editForm.ngaySinh),
      ngaySinhChuQuan: toISODate(editForm.ngaySinhChuQuan),
    };

    setSubmitting(true);
    try {
      await apiFetch(`/admin/users/${targetUser.maTaiKhoan}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      });
      showNotify('success', 'Lưu Thành Công', 'Cập nhật thông tin người dùng thành công!');
      setEditModalOpen(false);
      fetchUsers();
    } catch (err: any) {
      showNotify('error', 'Cập Nhật Thất Bại', err.message || 'Lỗi khi cập nhật thông tin người dùng.');
    } finally {
      setSubmitting(false);
    }
  };

  // Lock / Unlock Account
  const handleOpenLock = (u: any) => {
    setTargetUser(u);
    const isLocked = u.trangThai === 'KHOA_VINH_VIEN' || u.trangThai === 'KHOA_TAM_THOI';
    setLockForm({
      lockType: isLocked ? 'MO_KHOA' : 'TAM_THOI',
      presetDays: 7,
      customDate: '',
      lyDoKhoa: u.lyDoKhoa || '',
    });
    setLockModalOpen(true);
  };

  const handleLockSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!targetUser) return;
    setSubmitting(true);
    try {
      await apiFetch(`/admin/users/${targetUser.maTaiKhoan}/lock`, {
        method: 'PUT',
        body: JSON.stringify({
          lockType: lockForm.lockType,
          days: lockForm.presetDays,
          endDate: lockForm.customDate || undefined,
          lyDoKhoa: lockForm.lyDoKhoa,
        }),
      });
      showNotify('success', 'Khóa/Mở Khóa Thành Công', lockForm.lockType === 'MO_KHOA' ? 'Đã mở khóa tài khoản!' : 'Đã khóa tài khoản thành công!');
      setLockModalOpen(false);
      fetchUsers();
    } catch (err: any) {
      showNotify('error', 'Thất Bại', err.message || 'Lỗi cập nhật khóa tài khoản');
    } finally {
      setSubmitting(false);
    }
  };

  // Change Password
  const handleOpenPassword = (u: any) => {
    setTargetUser(u);
    setPasswordForm({ matKhauMoi: '', xacNhanMatKhau: '' });
    setPasswordModalOpen(true);
  };

  const handlePasswordSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!passwordForm.matKhauMoi || passwordForm.matKhauMoi.length < 6) {
      showNotify('warning', 'Mật Khẩu Không Hợp Lệ', 'Mật khẩu mới phải có từ 6 ký tự trở lên!');
      return;
    }
    if (passwordForm.matKhauMoi !== passwordForm.xacNhanMatKhau) {
      showNotify('warning', 'Mật Khẩu Không Khớp', 'Mật khẩu mới và mật khẩu xác nhận không trùng khớp!');
      return;
    }
    setSubmitting(true);
    try {
      await apiFetch(`/admin/users/${targetUser.maTaiKhoan}/password`, {
        method: 'PUT',
        body: JSON.stringify({ matKhauMoi: passwordForm.matKhauMoi }),
      });
      showNotify('success', 'Đổi Mật Khẩu Thành Công', 'Mật khẩu tài khoản đã được thay đổi thành công!');
      setPasswordModalOpen(false);
    } catch (err: any) {
      showNotify('error', 'Đổi Mật Khẩu Thất Bại', err.message || 'Lỗi khi đổi mật khẩu.');
    } finally {
      setSubmitting(false);
    }
  };

  const formatLockStatus = (u: any) => {
    if (u.trangThai === 'HOAT_DONG') {
      return <span className="badge badge-success">● Đang Hoạt Động</span>;
    }
    if (u.trangThai === 'KHOA_VINH_VIEN') {
      return <span className="badge badge-danger">🔒 Khóa Vĩnh Viễn</span>;
    }
    if (u.trangThai === 'KHOA_TAM_THOI' || u.khoaDenNgay) {
      const dateStr = u.khoaDenNgay ? new Date(u.khoaDenNgay).toLocaleDateString('vi-VN') : '';
      return <span className="badge badge-warning">⏳ Khóa đến {dateStr || 'tạm thời'}</span>;
    }
    return <span className="badge badge-warning">{u.trangThai}</span>;
  };

  const allItems = data.items || [];
  const countAll = allItems.length;
  const countCustomers = allItems.filter((u: any) => u.loaiTaiKhoan === 'KHACH_HANG').length;
  const countMerchants = allItems.filter((u: any) => u.loaiTaiKhoan === 'CUAN_HANG').length;
  const countStaff = allItems.filter((u: any) => u.loaiTaiKhoan === 'NHAN_VIEN').length;
  const countAdmins = allItems.filter((u: any) => u.loaiTaiKhoan === 'ADMIN').length;

  const filteredUsers = allItems.filter((u: any) => {
    if (roleFilter && u.loaiTaiKhoan !== roleFilter) return false;
    return true;
  });

  return (
    <div>
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 className="page-title">Quản Lý Người Dùng ({countAll} Tài Khoản)</h1>
          <p className="page-subtitle">Danh sách đầy đủ tất cả tài khoản hệ thống (Khách hàng, Cửa hàng / Chủ quán, Nhân viên, Admin)</p>
        </div>
        <button className="btn btn-primary" onClick={() => { setOcrNotice(null); setCreateModalOpen(true); }}>
          <Plus size={16} /> Thêm Người Dùng Mới
        </button>
      </div>

      {/* Role Navigation Tabs */}
      <div style={{ display: 'flex', gap: '10px', marginBottom: '16px', flexWrap: 'wrap' }}>
        <button
          className={`btn btn-sm ${roleFilter === '' ? 'btn-primary' : 'btn-outline'}`}
          onClick={() => setRoleFilter('')}
          style={{
            borderRadius: '20px',
            padding: '8px 18px',
            fontWeight: 700,
            fontSize: '13px',
            boxShadow: roleFilter === '' ? '0 3px 10px rgba(252,96,17,0.25)' : 'none',
          }}
        >
          👥 Tất Cả ({countAll})
        </button>
        <button
          className={`btn btn-sm ${roleFilter === 'KHACH_HANG' ? 'btn-primary' : 'btn-outline'}`}
          onClick={() => setRoleFilter('KHACH_HANG')}
          style={{
            borderRadius: '20px',
            padding: '8px 18px',
            fontWeight: 700,
            fontSize: '13px',
            boxShadow: roleFilter === 'KHACH_HANG' ? '0 3px 10px rgba(252,96,17,0.25)' : 'none',
          }}
        >
          👤 Khách Hàng ({countCustomers})
        </button>
        <button
          className={`btn btn-sm ${roleFilter === 'CUAN_HANG' ? 'btn-primary' : 'btn-outline'}`}
          onClick={() => setRoleFilter('CUAN_HANG')}
          style={{
            borderRadius: '20px',
            padding: '8px 18px',
            fontWeight: 700,
            fontSize: '13px',
            boxShadow: roleFilter === 'CUAN_HANG' ? '0 3px 10px rgba(252,96,17,0.25)' : 'none',
          }}
        >
          🏪 Cửa Hàng / Chủ Quán ({countMerchants})
        </button>
        <button
          className={`btn btn-sm ${roleFilter === 'NHAN_VIEN' ? 'btn-primary' : 'btn-outline'}`}
          onClick={() => setRoleFilter('NHAN_VIEN')}
          style={{
            borderRadius: '20px',
            padding: '8px 18px',
            fontWeight: 700,
            fontSize: '13px',
            boxShadow: roleFilter === 'NHAN_VIEN' ? '0 3px 10px rgba(252,96,17,0.25)' : 'none',
          }}
        >
          👔 Nhân Viên ({countStaff})
        </button>
        <button
          className={`btn btn-sm ${roleFilter === 'ADMIN' ? 'btn-primary' : 'btn-outline'}`}
          onClick={() => setRoleFilter('ADMIN')}
          style={{
            borderRadius: '20px',
            padding: '8px 18px',
            fontWeight: 700,
            fontSize: '13px',
            boxShadow: roleFilter === 'ADMIN' ? '0 3px 10px rgba(252,96,17,0.25)' : 'none',
          }}
        >
          🛡️ Quản Trị Viên ({countAdmins})
        </button>
      </div>

      <div className="card-table">
        {/* Toolbar Lọc & Tìm kiếm */}
        <div className="table-toolbar" style={{ display: 'flex', gap: '12px', flexWrap: 'wrap' }}>
          <div className="search-input-group" style={{ flex: 1, minWidth: '260px' }}>
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm theo tên đăng nhập, họ tên, email, SĐT..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <select
            className="form-control"
            style={{ width: '180px' }}
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
          >
            <option value="">Tất cả Trạng Thái</option>
            <option value="HOAT_DONG">Đang Hoạt Động</option>
            <option value="KHOA_TAM_THOI">Tạm Khóa</option>
            <option value="KHOA_VINH_VIEN">Khóa Vĩnh Viễn</option>
          </select>
        </div>

        {/* Bảng Danh Sách */}
        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}>
            <div className="loading-spinner" />
          </div>
        ) : filteredUsers.length === 0 ? (
          <div className="empty-state">Không tìm thấy người dùng nào thuộc nhóm này</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                <th>Người Dùng</th>
                <th>Họ & Tên</th>
                <th>Email / Số Điện Thoại</th>
                <th>Vai Trò</th>
                <th>Trạng Thái</th>
                <th style={{ textAlign: 'right' }}>Hành Động</th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map((u: any, index: number) => (
                <tr key={u.maTaiKhoan} style={{ cursor: 'pointer' }} onClick={() => handleOpenDetail(u)}>
                  <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{index + 1}</td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      <div
                        style={{
                          width: '36px',
                          height: '36px',
                          borderRadius: '50%',
                          background: '#e2e8f0',
                          overflow: 'hidden',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          fontWeight: 700,
                          color: '#475569',
                        }}
                      >
                        {isValidImageUrl(u.khachHang?.avatar || u.cuaHang?.img) ? (
                          <img
                            src={getImageUrl(u.khachHang?.avatar || u.cuaHang?.img)}
                            alt="Avatar"
                            onError={(e) => handleImageError(e)}
                            style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                          />
                        ) : (
                          (u.cuaHang?.tenQuan || u.khachHang?.hoTen || u.tenDangNhap || 'U')[0].toUpperCase()
                        )}
                      </div>
                      <div>
                        <div style={{ fontWeight: 600, color: '#0f172a' }}>{u.tenDangNhap}</div>
                        <div style={{ fontSize: '11px', color: '#94a3b8' }}>
                          Tạo ngày: {u.ngayTao ? new Date(u.ngayTao).toLocaleDateString('vi-VN') : '—'}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td style={{ fontWeight: 500 }}>
                    {u.khachHang?.hoTen || u.cuaHang?.tenQuan || u.cuaHang?.hoTenChuQuan || <span style={{ color: '#94a3b8' }}>Chưa cập nhật</span>}
                  </td>
                  <td>
                    <div style={{ fontSize: '13px' }}>{u.khachHang?.email || u.tenDangNhap}</div>
                    <div style={{ fontSize: '11px', color: '#64748b' }}>{u.khachHang?.sdt || u.cuaHang?.sdt || '—'}</div>
                  </td>
                  <td>
                    <StatusBadge status={u.loaiTaiKhoan} />
                  </td>
                  <td>{formatLockStatus(u)}</td>
                  <td style={{ textAlign: 'right' }} onClick={(e) => e.stopPropagation()}>
                    <div style={{ display: 'flex', gap: '6px', justifyContent: 'flex-end' }}>
                      <button className="btn btn-outline btn-sm" title="Xem Chi Tiết" onClick={() => handleOpenDetail(u)}>
                        <Eye size={14} />
                      </button>

                      <button className="btn btn-outline btn-sm" title="Chỉnh Sửa Thông Tin" onClick={() => handleOpenEdit(u)}>
                        <Edit size={14} />
                      </button>

                      <button
                        className={`btn btn-sm ${u.trangThai === 'HOAT_DONG' ? 'btn-outline' : 'btn-primary'}`}
                        title={u.trangThai === 'HOAT_DONG' ? 'Khóa Tài Khoản' : 'Mở Khóa Tài Khoản'}
                        onClick={() => handleOpenLock(u)}
                        style={u.trangThai !== 'HOAT_DONG' ? { background: '#dc2626', borderColor: '#dc2626', color: '#fff' } : {}}
                      >
                        {u.trangThai === 'HOAT_DONG' ? <Lock size={14} /> : <Unlock size={14} />}
                      </button>

                      <button className="btn btn-outline btn-sm" title="Đổi Mật Khẩu" onClick={() => handleOpenPassword(u)}>
                        <Key size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* MODAL 1: XEM CHI TIẾT */}
      <UserDetailModal
        isOpen={detailModalOpen}
        onClose={() => setDetailModalOpen(false)}
        targetUser={targetUser}
        userDetailData={userDetailData}
        formatLockStatus={formatLockStatus}
        onOpenEdit={handleOpenEdit}
        onOpenLock={handleOpenLock}
      />

      {/* MODAL 2: THÊM NGƯỜI DÙNG MỚI */}
      <UserFormModal
        isOpen={createModalOpen}
        onClose={() => setCreateModalOpen(false)}
        title="Thêm Người Dùng Mới"
        isEdit={false}
        form={addForm}
        setForm={setAddForm}
        onSubmit={handleCreateSubmit}
        submitting={submitting}
        ocrNotice={ocrNotice}
        scanningCCCD={scanningCCCD}
        handleScanCCCD={(img, side) => handleScanCCCD(img, side, 'add')}
      />

      {/* MODAL 3: CHỈNH SỬA NGƯỜI DÙNG */}
      <UserFormModal
        isOpen={editModalOpen}
        onClose={() => setEditModalOpen(false)}
        title="Chỉnh Sửa Thông Tin Người Dùng"
        isEdit={true}
        form={editForm}
        setForm={setEditForm}
        onSubmit={handleEditSubmit}
        submitting={submitting}
        ocrNotice={ocrNotice}
        scanningCCCD={scanningCCCD}
        handleScanCCCD={(img, side) => handleScanCCCD(img, side, 'edit')}
      />

      {/* MODAL 4: KHÓA TÀI KHOẢN */}
      <UserLockModal
        isOpen={lockModalOpen}
        onClose={() => setLockModalOpen(false)}
        targetUser={targetUser}
        lockForm={lockForm}
        setLockForm={setLockForm}
        onSubmit={handleLockSubmit}
        submitting={submitting}
      />

      {/* MODAL 5: ĐỔI MẬT KHẨU */}
      <Modal isOpen={passwordModalOpen} onClose={() => setPasswordModalOpen(false)} title="Đổi Mật Khẩu Tài Khoản">
        {targetUser && (
          <form onSubmit={handlePasswordSubmit}>
            <div style={{ fontSize: '13px', color: '#64748b', marginBottom: '16px' }}>
              Đặt lại mật khẩu mới cho tài khoản: <strong>@{targetUser.tenDangNhap}</strong>
            </div>

            <div className="form-group">
              <label className="form-label">Mật Khẩu Mới *</label>
              <input
                type="password"
                className="form-control"
                placeholder="Ít nhất 6 ký tự..."
                value={passwordForm.matKhauMoi}
                onChange={(e) => setPasswordForm({ ...passwordForm, matKhauMoi: e.target.value })}
                required
              />
            </div>

            <div className="form-group">
              <label className="form-label">Xác Nhận Mật Khẩu Mới *</label>
              <input
                type="password"
                className="form-control"
                placeholder="Nhập lại mật khẩu mới..."
                value={passwordForm.xacNhanMatKhau}
                onChange={(e) => setPasswordForm({ ...passwordForm, xacNhanMatKhau: e.target.value })}
                required
              />
            </div>

            <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
              <button type="button" className="btn btn-outline" onClick={() => setPasswordModalOpen(false)}>Hủy</button>
              <button type="submit" className="btn btn-primary" disabled={submitting}>
                {submitting ? <div className="loading-spinner" /> : 'Cập Nhật Mật Khẩu'}
              </button>
            </div>
          </form>
        )}
      </Modal>

      <NotificationModal
        isOpen={notifyModal.isOpen}
        type={notifyModal.type}
        title={notifyModal.title}
        message={notifyModal.message}
        onClose={() => setNotifyModal((prev) => ({ ...prev, isOpen: false }))}
      />
    </div>
  );
};
