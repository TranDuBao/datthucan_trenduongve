import React, { useEffect, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { apiFetch } from '../../api/apiClient';
import { Search, Plus, Store, Building, RotateCcw, Trash2, Edit3, Filter, UtensilsCrossed } from 'lucide-react';
import { StatusBadge } from '../../components/StatusBadge';
import { Modal } from '../../components/Modal';
import { NotificationModal } from '../../components/NotificationModal';
import { ImageCropUpload } from '../../components/ImageCropUpload';
import { LocationSelector } from '../../components/LocationSelector';
import { parseCCCDImage, formatDateVN, toISODate } from '../../utils/ocrService';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../utils/imageUtils';
import { VIETNAM_BANKS } from './users/UserFormModal';
import { RestaurantDetailView } from './restaurants/RestaurantDetailView';
import { AdminCategories } from './AdminCategories';
import { UnderlineTabs, TabItem } from '../../components/UnderlineTabs';

export const AdminRestaurants: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'DELETED'>('ALL');

  const [modalOpen, setModalOpen] = useState(false);
  const [editingStore, setEditingStore] = useState<any>(null);

  // State for Content Area Restaurant Detail view
  const [selectedRestaurantId, setSelectedRestaurantId] = useState<number | null>(null);
  const [merchantUsers, setMerchantUsers] = useState<any[]>([]);

  // Sub-tabs navigation: Danh Sách Nhà Hàng & Quản Lý Danh Mục Món
  const [searchParams, setSearchParams] = useSearchParams();
  const currentTab = (searchParams.get('tab') as 'stores' | 'categories') || 'stores';

  const handleTabChange = (key: 'stores' | 'categories') => {
    setSearchParams((prev) => {
      const next = new URLSearchParams(prev);
      if (key === 'stores') {
        next.delete('tab');
      } else {
        next.set('tab', key);
      }
      return next;
    });
  };

  const isDeletedStore = (s: any) =>
    Boolean(s.isDeleted) || ['ĐÃ XÓA', 'DA_XOA', 'DELETED'].includes((s.trangThai || '').toUpperCase());

  const activeStores = (data.items || []).filter((s: any) => !isDeletedStore(s));
  const deletedStores = (data.items || []).filter((s: any) => isDeletedStore(s));

  const filteredStores =
    statusFilter === 'ACTIVE'
      ? activeStores
      : statusFilter === 'DELETED'
      ? deletedStores
      : [...activeStores, ...deletedStores];


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

  const [confirmDeleteStore, setConfirmDeleteStore] = useState<any>(null);

  const handleDeleteStore = async (s: any) => {
    try {
      await apiFetch(`/admin/restaurants/${s.maQuan}`, { method: 'DELETE' });
      showNotify('success', 'Xóa Mềm Thành Công', `Đã xóa mềm nhà hàng "${s.tenQuan}". Nhà hàng sẽ không hiển thị trên App Khách Hàng.`);
      setConfirmDeleteStore(null);
      fetchStores();
    } catch (err: any) {
      showNotify('error', 'Lỗi Xóa Nhà Hàng', err.message || 'Không thể xóa nhà hàng');
    }
  };

  const handleRestoreStore = async (s: any) => {
    try {
      await apiFetch(`/admin/restaurants/${s.maQuan}/restore`, { method: 'POST' });
      showNotify('success', 'Khôi Phục Thành Công', `Đã khôi phục nhà hàng "${s.tenQuan}". Nhà hàng đã có thể hoạt động trở lại.`);
      fetchStores();
    } catch (err: any) {
      showNotify('error', 'Lỗi Khôi Phục', err.message || 'Không thể khôi phục nhà hàng');
    }
  };

  const [form, setForm] = useState({
    tenQuan: '',
    diaChi: '',
    sdt: '',
    img: '',
    trangThai: 'mở cửa',
    maTaiKhoan: '',
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

  const fetchStores = () => {
    setLoading(true);
    apiFetch<any>(`/admin/restaurants?limit=1000&search=${encodeURIComponent(search)}`)
      .then((res) => setData(res.data))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));

    apiFetch<any>('/admin/users?roleFilter=CUAN_HANG&limit=1000')
      .then((res) => setMerchantUsers(res.data?.items || res.items || []))
      .catch(() => {});
  };

  useEffect(() => {
    fetchStores();
  }, [search]);

  const handleOpenAdd = () => {
    setEditingStore(null);
    setForm({
      tenQuan: '',
      diaChi: '',
      sdt: '',
      img: '',
      trangThai: 'mở cửa',
      maTaiKhoan: '',
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
    setModalOpen(true);
  };

  const handleOpenEdit = (s: any) => {
    setEditingStore(s);
    setForm({
      tenQuan: s.tenQuan || '',
      diaChi: s.diaChi || '',
      sdt: s.sdt || '',
      img: s.img || '',
      trangThai: s.trangThai || 'mở cửa',
      maTaiKhoan: s.maTaiKhoan ? String(s.maTaiKhoan) : '',
      hoTenChuQuan: s.hoTenChuQuan || '',
      diaChiThuongTru: s.diaChiThuongTru || '',
      ngaySinhChuQuan: s.ngaySinhChuQuan ? formatDateVN(String(s.ngaySinhChuQuan)) : '',
      soCCCD: s.soCCCD || '',
      tenNganHang: s.tenNganHang || 'Vietcombank (VCB)',
      soTaiKhoanNganHang: s.soTaiKhoanNganHang || '',
      tenChuTaiKhoan: s.tenChuTaiKhoan || '',
      cccdMatTruoc: s.cccdMatTruoc || '',
      cccdMatSau: s.cccdMatSau || '',
    });
    setModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const payload = {
        ...form,
        maTaiKhoan: form.maTaiKhoan ? Number(form.maTaiKhoan) : undefined,
        ngaySinhChuQuan: toISODate(form.ngaySinhChuQuan),
      };

      if (editingStore) {
        await apiFetch(`/admin/restaurants/${editingStore.maQuan}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
      } else {
        await apiFetch('/admin/restaurants', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
      }
      setModalOpen(false);
      fetchStores();
      showNotify('success', editingStore ? 'Cập Nhật Thành Công' : 'Thêm Thành Công', editingStore ? 'Đã lưu thông tin nhà hàng thành công!' : 'Đã tạo nhà hàng mới thành công!');
    } catch (err: any) {
      showNotify('error', 'Lỗi Lưu Nhà Hàng', err.message || 'Lỗi lưu nhà hàng');
    }
  };

  // If a restaurant is selected, display detail view directly inside the Content Area
  if (selectedRestaurantId !== null) {
    return (
      <RestaurantDetailView
        restaurantId={selectedRestaurantId}
        onBack={() => setSelectedRestaurantId(null)}
      />
    );
  }

  const tabs: TabItem<'stores' | 'categories'>[] = [
    { key: 'stores', label: 'Danh Sách Nhà Hàng', icon: <Store size={18} />, count: activeStores.length },
    { key: 'categories', label: 'Quản Lý Danh Mục Món', icon: <UtensilsCrossed size={18} /> },
  ];

  return (
    <div>
      <UnderlineTabs<'stores' | 'categories'>
        tabs={tabs}
        activeTab={currentTab}
        onChange={handleTabChange}
      />

      {currentTab === 'categories' ? (
        <AdminCategories />
      ) : (
        <>
          <div className="page-header">
            <div>
              <h1 className="page-title">Quản Lý Nhà Hàng</h1>
              <p className="page-subtitle">Danh sách quán ăn & tài khoản quản lý nhà hàng</p>
            </div>
            <button className="btn btn-primary" onClick={handleOpenAdd}>
              <Plus size={16} /> Thêm Nhà Hàng Mới
            </button>
          </div>

      <div className="card-table">
        <div className="table-toolbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
          <div className="search-input-group" style={{ flex: 1, minWidth: '260px' }}>
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm tên nhà hàng, địa chỉ, SĐT..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <div style={{ display: 'flex', gap: '6px', background: '#f1f5f9', padding: '4px', borderRadius: '10px' }}>
            <button
              type="button"
              onClick={() => setStatusFilter('ALL')}
              style={{
                padding: '6px 14px',
                borderRadius: '8px',
                border: 'none',
                fontSize: '13px',
                fontWeight: 600,
                cursor: 'pointer',
                background: statusFilter === 'ALL' ? '#ffffff' : 'transparent',
                color: statusFilter === 'ALL' ? '#0f172a' : '#64748b',
                boxShadow: statusFilter === 'ALL' ? '0 1px 3px rgba(0,0,0,0.1)' : 'none',
                transition: 'all 0.15s ease',
              }}
            >
              Tất Cả ({data.items?.length || 0})
            </button>

            <button
              type="button"
              onClick={() => setStatusFilter('ACTIVE')}
              style={{
                padding: '6px 14px',
                borderRadius: '8px',
                border: 'none',
                fontSize: '13px',
                fontWeight: 600,
                cursor: 'pointer',
                background: statusFilter === 'ACTIVE' ? '#ffffff' : 'transparent',
                color: statusFilter === 'ACTIVE' ? '#059669' : '#64748b',
                boxShadow: statusFilter === 'ACTIVE' ? '0 1px 3px rgba(0,0,0,0.1)' : 'none',
                transition: 'all 0.15s ease',
              }}
            >
              ● Hoạt Động ({activeStores.length})
            </button>

            <button
              type="button"
              onClick={() => setStatusFilter('DELETED')}
              style={{
                padding: '6px 14px',
                borderRadius: '8px',
                border: 'none',
                fontSize: '13px',
                fontWeight: 600,
                cursor: 'pointer',
                background: statusFilter === 'DELETED' ? '#ffffff' : 'transparent',
                color: statusFilter === 'DELETED' ? '#dc2626' : '#64748b',
                boxShadow: statusFilter === 'DELETED' ? '0 1px 3px rgba(0,0,0,0.1)' : 'none',
                transition: 'all 0.15s ease',
              }}
            >
              🗑️ Đã Xóa Mềm ({deletedStores.length})
            </button>
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : filteredStores.length === 0 ? (
          <div className="empty-state">Không có nhà hàng nào khớp với điều kiện lọc</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                <th>Hình Ảnh</th>
                <th>Tên Nhà Hàng</th>
                <th>Địa Chỉ</th>
                <th>Số Điện Thoại</th>
                <th>Trạng Thái</th>
                <th>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredStores.map((s: any, idx: number) => {
                const deleted = isDeletedStore(s);
                return (
                  <tr
                    key={s.maQuan}
                    onClick={() => setSelectedRestaurantId(s.maQuan)}
                    style={{
                      cursor: 'pointer',
                      background: deleted ? '#f8fafc' : '#ffffff',
                      opacity: deleted ? 0.8 : 1,
                      transition: 'background 0.15s ease',
                      borderLeft: deleted ? '4px solid #cbd5e1' : '4px solid transparent',
                    }}
                    title={deleted ? 'Nhà hàng đã xóa mềm (Hoàn toàn ẩn trên App Khách Hàng)' : 'Click để xem chi tiết thực đơn & thống kê'}
                  >
                    <td style={{ textAlign: 'center', fontWeight: 600, color: deleted ? '#94a3b8' : '#64748b' }}>{idx + 1}</td>
                    <td>
                      <img
                        src={getImageUrl(s.img, DEFAULT_IMAGE_PLACEHOLDER)}
                        alt=""
                        onError={handleImageError}
                        style={{
                          width: '40px',
                          height: '40px',
                          borderRadius: '8px',
                          objectFit: 'cover',
                          filter: deleted ? 'grayscale(80%)' : 'none',
                        }}
                      />
                    </td>
                    <td style={{ fontWeight: 700, color: deleted ? '#64748b' : '#0f172a', textDecoration: deleted ? 'line-through' : 'none' }}>
                      {s.tenQuan}
                    </td>
                    <td style={{ maxWidth: '240px', color: deleted ? '#94a3b8' : '#475569' }}>{s.diaChi}</td>
                    <td style={{ color: deleted ? '#94a3b8' : '#475569' }}>{s.sdt || 'Chưa có'}</td>
                    <td><StatusBadge status={s.trangThai} /></td>
                    <td onClick={(e) => e.stopPropagation()}>
                      <div style={{ display: 'flex', gap: '6px', alignItems: 'center' }}>
                        <button
                          className="btn btn-outline btn-sm"
                          style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', padding: '4px 10px' }}
                          onClick={(e) => {
                            e.stopPropagation();
                            handleOpenEdit(s);
                          }}
                        >
                          <Edit3 size={13} /> Sửa
                        </button>

                        {deleted ? (
                          <button
                            className="btn btn-sm"
                            style={{
                              background: '#16a34a',
                              color: '#fff',
                              border: 'none',
                              display: 'flex',
                              alignItems: 'center',
                              gap: '4px',
                              fontSize: '12px',
                              padding: '4px 10px',
                              borderRadius: '6px',
                            }}
                            onClick={(e) => {
                              e.stopPropagation();
                              handleRestoreStore(s);
                            }}
                          >
                            <RotateCcw size={13} /> Khôi Phục
                          </button>
                        ) : (
                          <button
                            className="btn btn-sm"
                            style={{
                              background: '#fff1f2',
                              color: '#e11d48',
                              border: '1px solid #fecdd3',
                              display: 'flex',
                              alignItems: 'center',
                              gap: '4px',
                              fontSize: '12px',
                              padding: '4px 10px',
                              borderRadius: '6px',
                              fontWeight: 600,
                            }}
                            onClick={(e) => {
                              e.stopPropagation();
                              setConfirmDeleteStore(s);
                            }}
                          >
                            <Trash2 size={13} /> Xóa Mềm
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editingStore ? 'Chỉnh Sửa Nhà Hàng & Chủ Quán' : 'Thêm Nhà Hàng Mới'} maxWidth="680px">
        <form onSubmit={handleSubmit}>
          <div style={{ fontSize: '14px', fontWeight: 700, color: '#fc6011', marginBottom: '10px' }}>
            🏪 1. Thông Tin Nhà Hàng
          </div>

          <div className="form-group">
            <label className="form-label">Tên Nhà Hàng *</label>
            <input type="text" className="form-control" value={form.tenQuan} onChange={(e) => setForm({ ...form, tenQuan: e.target.value })} required />
          </div>
          <LocationSelector
            label="Địa Chỉ Nhà Hàng (Phân Cấp / Cascading Dropdown)"
            value={form.diaChi}
            onChange={(val) => setForm({ ...form, diaChi: val })}
            required
          />
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">Số Điện Thoại</label>
              <input type="text" className="form-control" value={form.sdt} onChange={(e) => setForm({ ...form, sdt: e.target.value })} />
            </div>
            <div className="form-group">
              <label className="form-label">Tài Khoản Quản Lý (Mã Tài Khoản)</label>
              <input
                type="text"
                className="form-control"
                value={form.maTaiKhoan ? `Mã Tài Khoản #${form.maTaiKhoan}` : 'Tự Động Khởi Tạo (Auto-Generated)'}
                disabled
                style={{ backgroundColor: '#f1f5f9', color: '#64748b', cursor: 'not-allowed', fontWeight: 600 }}
              />
            </div>
          </div>
          <ImageCropUpload
            label="Hình Ảnh Banner/Logo Nhà Hàng"
            value={form.img}
            onChange={(url) => setForm({ ...form, img: url })}
            aspectRatio={1.77}
          />

          {/* Owner details */}
          <div style={{ background: '#f8fafc', padding: '16px', borderRadius: '12px', border: '1px solid #e2e8f0', marginTop: '16px', marginBottom: '16px' }}>
            <div style={{ fontSize: '14px', fontWeight: 700, color: '#0369a1', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Building size={16} /> 2. Thông Tin Chủ Quán & Ngân Hàng
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div className="form-group">
                <label className="form-label">Họ Tên Chủ Quán</label>
                <input type="text" className="form-control" value={form.hoTenChuQuan} onChange={(e) => setForm({ ...form, hoTenChuQuan: e.target.value })} />
              </div>
              <div className="form-group">
                <label className="form-label">Ngày Sinh Chủ Quán (dd/mm/yyyy)</label>
                <input type="text" className="form-control" placeholder="dd/mm/yyyy" value={form.ngaySinhChuQuan} onChange={(e) => setForm({ ...form, ngaySinhChuQuan: e.target.value })} />
              </div>
            </div>
            <div className="form-group">
              <label className="form-label">Số CCCD (12 Số)</label>
              <input type="text" className="form-control" value={form.soCCCD} onChange={(e) => setForm({ ...form, soCCCD: e.target.value })} />
            </div>
            <LocationSelector
              label="Địa Chỉ Thường Trú (Theo CCCD)"
              value={form.diaChiThuongTru}
              onChange={(val) => setForm({ ...form, diaChiThuongTru: val })}
            />
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
              <div className="form-group">
                <label className="form-label">Tên Ngân Hàng</label>
                <select className="form-control" value={form.tenNganHang} onChange={(e) => setForm({ ...form, tenNganHang: e.target.value })}>
                  {VIETNAM_BANKS.map((b) => (<option key={b} value={b}>{b}</option>))}
                </select>
              </div>
              <div className="form-group">
                <label className="form-label">Số Tài Khoản</label>
                <input type="text" className="form-control" value={form.soTaiKhoanNganHang} onChange={(e) => setForm({ ...form, soTaiKhoanNganHang: e.target.value })} />
              </div>
              <div className="form-group">
                <label className="form-label">Chủ Tài Khoản</label>
                <input type="text" className="form-control" value={form.tenChuTaiKhoan} onChange={(e) => setForm({ ...form, tenChuTaiKhoan: e.target.value })} />
              </div>
            </div>
          </div>

          <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setModalOpen(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">Lưu Thông Tin Đồng Bộ</button>
          </div>
        </form>
      </Modal>

      {confirmDeleteStore && (
        <Modal
          isOpen={!!confirmDeleteStore}
          onClose={() => setConfirmDeleteStore(null)}
          title="⚠️ Xác Nhận Xóa Mềm Nhà Hàng"
          maxWidth="460px"
        >
          <div style={{ padding: '8px 0' }}>
            <p style={{ fontSize: '14px', color: '#334155', marginBottom: '14px' }}>
              Bạn có chắc chắn muốn <strong>xóa mềm</strong> nhà hàng <strong>{confirmDeleteStore.tenQuan}</strong>?
            </p>
            <div style={{ fontSize: '13px', color: '#64748b', background: '#f8fafc', padding: '12px', borderRadius: '8px', borderLeft: '4px solid #f59e0b', marginBottom: '20px' }}>
              ℹ️ Khi xóa mềm:
              <ul style={{ margin: '6px 0 0 16px', padding: 0 }}>
                <li>Nhà hàng sẽ **hoàn toàn ẩn** khỏi App Khách Hàng.</li>
                <li>Dữ liệu vẫn được giữ trên hệ thống Admin để có thể khôi phục lại bất cứ lúc nào.</li>
              </ul>
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button className="btn btn-outline" onClick={() => setConfirmDeleteStore(null)}>
                Hủy
              </button>
              <button
                className="btn"
                style={{ background: '#ef4444', color: '#fff', border: 'none' }}
                onClick={() => handleDeleteStore(confirmDeleteStore)}
              >
                Xác Nhận Xóa Mềm
              </button>
            </div>
          </div>
        </Modal>
      )}

      <NotificationModal
        isOpen={notifyModal.isOpen}
        onClose={() => setNotifyModal((prev) => ({ ...prev, isOpen: false }))}
        type={notifyModal.type}
        title={notifyModal.title}
        message={notifyModal.message}
      />
        </>
      )}
    </div>
  );
};
