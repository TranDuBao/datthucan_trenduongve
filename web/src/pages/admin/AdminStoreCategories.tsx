import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import {
  Plus,
  Edit2,
  Trash2,
  Search,
  Store,
  Utensils,
  UtensilsCrossed,
  Coffee,
  CupSoda,
  Cookie,
  Sandwich,
  Flame,
  Sparkles,
  Pizza,
  Cake,
  IceCream,
  Beef,
  Fish,
  Salad,
  Croissant,
  Beer,
  Wine,
  Layers,
  Check,
  AlertCircle,
  Eye,
  Image as ImageIcon,
} from 'lucide-react';
import { Modal } from '../../components/Modal';
import { StatusBadge } from '../../components/StatusBadge';
import { ImageCropUpload } from '../../components/ImageCropUpload';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../utils/imageUtils';

export interface StoreCategoryItem {
  maLoai: number;
  tenLoai: string;
  moTa?: string;
  hinhAnh?: string;
  icon?: string;
  thuTu: number;
  trangThai: string;
  soLuongQuan?: number;
  createdAt?: string;
}

const AVAILABLE_ICONS: Record<string, React.FC<any>> = {
  Utensils,
  UtensilsCrossed,
  Coffee,
  CupSoda,
  Cookie,
  Sandwich,
  Flame,
  Sparkles,
  Pizza,
  Cake,
  IceCream,
  Beef,
  Fish,
  Salad,
  Croissant,
  Beer,
  Wine,
  Store,
  Layers,
};

const ICON_PRESETS = [
  { key: 'Utensils', name: 'Đồ ăn', icon: Utensils },
  { key: 'UtensilsCrossed', name: 'Cơm / Món mặn', icon: UtensilsCrossed },
  { key: 'Coffee', name: 'Cà phê', icon: Coffee },
  { key: 'CupSoda', name: 'Trà sữa / Đồ uống', icon: CupSoda },
  { key: 'Cookie', name: 'Ăn vặt', icon: Cookie },
  { key: 'Sandwich', name: 'Bánh mì / Fastfood', icon: Sandwich },
  { key: 'Pizza', name: 'Pizza / Đồ Tây', icon: Pizza },
  { key: 'Flame', name: 'Lẩu & Nướng', icon: Flame },
  { key: 'Beef', name: 'Bún bò / Phở', icon: Beef },
  { key: 'Fish', name: 'Hải sản / Cá', icon: Fish },
  { key: 'Salad', name: 'Healthy / Rau', icon: Salad },
  { key: 'Cake', name: 'Bánh ngọt', icon: Cake },
  { key: 'IceCream', name: 'Kem / Tráng miệng', icon: IceCream },
  { key: 'Croissant', name: 'Tiệm bánh', icon: Croissant },
  { key: 'Beer', name: 'Bia / Quán nhậu', icon: Beer },
  { key: 'Wine', name: 'Rượu / Bar', icon: Wine },
  { key: 'Sparkles', name: 'Đặc sản', icon: Sparkles },
  { key: 'Store', name: 'Cửa hàng', icon: Store },
  { key: 'Layers', name: 'Tổng hợp', icon: Layers },
];

interface AdminStoreCategoriesProps {
  onSelectCategoryFilter?: (categoryName: string) => void;
}

export const AdminStoreCategories: React.FC<AdminStoreCategoriesProps> = ({ onSelectCategoryFilter }) => {
  const [categories, setCategories] = useState<StoreCategoryItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  // Modal 1: Create / Edit Category
  const [modalOpen, setModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<StoreCategoryItem | null>(null);
  const [iconMode, setIconMode] = useState<'preset' | 'upload'>('preset');
  const [form, setForm] = useState({
    tenLoai: '',
    moTa: '',
    icon: 'Store',
    hinhAnh: '',
    thuTu: 0,
    trangThai: 'ACTIVE',
  });

  // Modal 2: View Stores in Category
  const [storesModalOpen, setStoresModalOpen] = useState(false);
  const [selectedCat, setSelectedCat] = useState<StoreCategoryItem | null>(null);
  const [categoryStores, setCategoryStores] = useState<any[]>([]);
  const [loadingStores, setLoadingStores] = useState(false);

  // Modal 3: Delete Confirmation
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [deletingCat, setDeletingCat] = useState<StoreCategoryItem | null>(null);

  // Notification Modal
  const [notify, setNotify] = useState<{ isOpen: boolean; title: string; message: string; type: 'success' | 'error' }>({
    isOpen: false,
    title: '',
    message: '',
    type: 'success',
  });

  const showNotify = (type: 'success' | 'error', title: string, message: string) => {
    setNotify({ isOpen: true, title, message, type });
  };

  const fetchCategories = () => {
    setLoading(true);
    apiFetch<any>(`/admin/store-categories?search=${encodeURIComponent(search)}`)
      .then((res) => {
        setCategories(res.data || []);
      })
      .catch((err) => {
        console.error('Lỗi tải danh mục loại hình:', err);
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchCategories();
  }, [search]);

  const handleOpenAdd = () => {
    setEditingItem(null);
    setIconMode('preset');
    setForm({
      tenLoai: '',
      moTa: '',
      icon: 'Store',
      hinhAnh: '',
      thuTu: categories.length + 1,
      trangThai: 'ACTIVE',
    });
    setModalOpen(true);
  };

  const handleOpenEdit = (item: StoreCategoryItem) => {
    setEditingItem(item);
    setIconMode(item.hinhAnh ? 'upload' : 'preset');
    setForm({
      tenLoai: item.tenLoai || '',
      moTa: item.moTa || '',
      icon: item.icon || 'Store',
      hinhAnh: item.hinhAnh || '',
      thuTu: item.thuTu || 0,
      trangThai: item.trangThai || 'ACTIVE',
    });
    setModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = form.tenLoai.trim();
    if (!trimmed) {
      showNotify('error', 'Thiếu Dữ Liệu', 'Vui lòng nhập tên loại hình quán');
      return;
    }

    try {
      const payload = {
        ...form,
        hinhAnh: iconMode === 'upload' ? form.hinhAnh?.trim() : undefined,
      };

      if (editingItem) {
        await apiFetch(`/admin/store-categories/${editingItem.maLoai}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
        showNotify('success', 'Cập Nhật Thành Công', `Đã cập nhật loại hình "${trimmed}"`);
      } else {
        await apiFetch('/admin/store-categories', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        showNotify('success', 'Tạo Mới Thành Công', `Đã thêm loại hình quán "${trimmed}"`);
      }
      setModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      showNotify('error', 'Lỗi Lưu Loại Hình', err.message || 'Không thể lưu loại hình quán');
    }
  };

  const handleOpenDelete = (item: StoreCategoryItem) => {
    setDeletingCat(item);
    setDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!deletingCat) return;
    try {
      await apiFetch(`/admin/store-categories/${deletingCat.maLoai}`, { method: 'DELETE' });
      showNotify('success', 'Xóa Thành Công', `Đã xóa loại hình "${deletingCat.tenLoai}"`);
      setDeleteModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      showNotify('error', 'Không Thể Xóa', err.message || 'Lỗi khi xóa loại hình quán');
    }
  };

  const handleViewStores = async (item: StoreCategoryItem) => {
    setSelectedCat(item);
    setStoresModalOpen(true);
    setLoadingStores(true);
    try {
      const res = await apiFetch<any>(`/admin/store-categories/${item.maLoai}/restaurants`);
      setCategoryStores(res.data?.stores || []);
    } catch (err) {
      console.error(err);
      setCategoryStores([]);
    } finally {
      setLoadingStores(false);
    }
  };

  const renderIconOrImage = (cat: StoreCategoryItem) => {
    if (cat.hinhAnh) {
      return (
        <img
          src={getImageUrl(cat.hinhAnh, DEFAULT_IMAGE_PLACEHOLDER)}
          alt=""
          onError={handleImageError}
          style={{ width: '38px', height: '38px', borderRadius: '10px', objectFit: 'cover', margin: '0 auto' }}
        />
      );
    }
    const IconComp = (cat.icon && AVAILABLE_ICONS[cat.icon]) || Store;
    return (
      <div
        style={{
          width: '38px',
          height: '38px',
          borderRadius: '10px',
          background: '#fff3e8',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          margin: '0 auto',
        }}
      >
        <IconComp size={20} color="#fc6011" />
      </div>
    );
  };

  const totalStores = categories.reduce((acc, c) => acc + (c.soLuongQuan || 0), 0);

  return (
    <div style={{ paddingBottom: '30px' }}>
      {/* Top Header */}
      <div className="page-header" style={{ marginBottom: '20px' }}>
        <div>
          <h1 className="page-title" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <Store size={24} color="#fc6011" /> Quản Lý Loại Hình / Danh Mục Quán
          </h1>
          <p className="page-subtitle">
            Phân loại mô hình ẩm thực, thiết lập biểu tượng và kiểm soát danh sách nhà hàng theo từng nhóm loại hình
          </p>
        </div>
        <button className="btn btn-primary" onClick={handleOpenAdd}>
          <Plus size={16} /> Thêm Loại Hình Quán Mới
        </button>
      </div>

      {/* KPI Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '16px', marginBottom: '20px' }}>
        <div style={{ background: '#ffffff', borderRadius: '14px', padding: '16px 20px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ fontSize: '12px', color: '#64748b', fontWeight: 600, textTransform: 'uppercase' }}>Tổng Loại Hình Quán</div>
          <div style={{ fontSize: '26px', fontWeight: 800, color: '#0f172a', marginTop: '6px' }}>{categories.length}</div>
          <div style={{ fontSize: '12px', color: '#10b981', marginTop: '4px', fontWeight: 600 }}>Phân loại chuẩn hóa</div>
        </div>

        <div style={{ background: '#ffffff', borderRadius: '14px', padding: '16px 20px', border: '1px solid #e2e8f0', boxShadow: '0 1px 3px rgba(0,0,0,0.05)' }}>
          <div style={{ fontSize: '12px', color: '#64748b', fontWeight: 600, textTransform: 'uppercase' }}>Tổng Nhà Hàng Đã Phân Loại</div>
          <div style={{ fontSize: '26px', fontWeight: 800, color: '#fc6011', marginTop: '6px' }}>{totalStores}</div>
          <div style={{ fontSize: '12px', color: '#64748b', marginTop: '4px' }}>Đang hoạt động trong các nhóm</div>
        </div>
      </div>

      {/* Toolbar & Categories Table */}
      <div className="card-table">
        <div className="table-toolbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '16px', flexWrap: 'wrap' }}>
          <div className="search-input-group" style={{ flex: 1, minWidth: '280px' }}>
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm kiếm loại hình quán, mô tả..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <div style={{ fontSize: '13px', color: '#64748b', fontWeight: 600 }}>
            Hiển thị {categories.length} loại hình
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : categories.length === 0 ? (
          <div className="empty-state">Không có loại hình quán nào</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                <th style={{ width: '70px', textAlign: 'center' }}>Icon / Ảnh</th>
                <th>Tên Loại Hình Quán</th>
                <th>Mô Tả Chi Tiết</th>
                <th style={{ textAlign: 'center' }}>Số Quán Trực Thuộc</th>
                <th style={{ textAlign: 'center' }}>Trạng Thái</th>
                <th style={{ textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {categories.map((cat, idx) => (
                <tr key={cat.maLoai}>
                  <td style={{ textAlign: 'center', fontWeight: 700, color: '#64748b' }}>
                    {idx + 1}
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    {renderIconOrImage(cat)}
                  </td>
                  <td>
                    <div style={{ fontWeight: 700, color: '#0f172a', fontSize: '14.5px' }}>
                      {cat.tenLoai}
                    </div>
                  </td>
                  <td style={{ maxWidth: '300px', color: '#64748b', fontSize: '13px' }}>
                    {cat.moTa || '—'}
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <button
                      type="button"
                      onClick={() => handleViewStores(cat)}
                      style={{
                        padding: '4px 12px',
                        borderRadius: '16px',
                        background: (cat.soLuongQuan || 0) > 0 ? '#eff6ff' : '#f1f5f9',
                        color: (cat.soLuongQuan || 0) > 0 ? '#1d4ed8' : '#64748b',
                        border: '1px solid',
                        borderColor: (cat.soLuongQuan || 0) > 0 ? '#bfdbfe' : '#e2e8f0',
                        fontSize: '12.5px',
                        fontWeight: 700,
                        cursor: 'pointer',
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '6px',
                        transition: 'all 0.15s ease',
                      }}
                      title="Bấm để xem danh sách quán thuộc loại hình này"
                    >
                      <Eye size={13} />
                      {cat.soLuongQuan || 0} Quán
                    </button>
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <span
                      style={{
                        padding: '3px 10px',
                        borderRadius: '12px',
                        fontSize: '12px',
                        fontWeight: 700,
                        background: cat.trangThai === 'ACTIVE' ? '#dcfce7' : '#f1f5f9',
                        color: cat.trangThai === 'ACTIVE' ? '#15803d' : '#64748b',
                      }}
                    >
                      {cat.trangThai === 'ACTIVE' ? 'Kích hoạt' : 'Tạm ẩn'}
                    </span>
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <div style={{ display: 'flex', gap: '8px', justifyContent: 'center' }}>
                      <button
                        className="btn btn-outline btn-sm"
                        onClick={() => handleOpenEdit(cat)}
                        title="Chỉnh sửa loại hình"
                        style={{ padding: '6px 10px' }}
                      >
                        <Edit2 size={14} /> Sửa
                      </button>
                      <button
                        className="btn btn-danger btn-sm"
                        onClick={() => handleOpenDelete(cat)}
                        title="Xóa loại hình"
                        style={{ padding: '6px 10px' }}
                      >
                        <Trash2 size={14} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Modal 1: Create / Edit Category Modal with Rich Visual Icon Picker */}
      <Modal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingItem ? `Chỉnh Sửa Loại Hình: ${editingItem.tenLoai}` : 'Thêm Loại Hình Quán Mới'}
        maxWidth="620px"
      >
        <form onSubmit={handleSubmit}>
          <div className="form-group" style={{ marginBottom: '14px' }}>
            <label className="form-label">
              Tên Loại Hình / Danh Mục Quán <span style={{ color: '#ef4444' }}>*</span>
            </label>
            <input
              type="text"
              className="form-control"
              placeholder="VD: Cơm & Món Mặn, Trà Sữa & Đồ Uống..."
              value={form.tenLoai}
              onChange={(e) => setForm({ ...form, tenLoai: e.target.value })}
              required
            />
          </div>

          <div className="form-group" style={{ marginBottom: '14px' }}>
            <label className="form-label">Mô Tả Loại Hình</label>
            <textarea
              className="form-control"
              rows={2}
              placeholder="Mô tả đặc trưng thực đơn hoặc nhóm đối tượng của quán..."
              value={form.moTa}
              onChange={(e) => setForm({ ...form, moTa: e.target.value })}
            />
          </div>

          {/* Mode switch: Pick Preset Icon or Upload Image */}
          <div style={{ marginBottom: '14px' }}>
            <label className="form-label" style={{ marginBottom: '8px', display: 'block' }}>
              Biểu Tượng / Hình Ảnh Đại Diện
            </label>
            <div style={{ display: 'flex', gap: '8px', marginBottom: '12px' }}>
              <button
                type="button"
                onClick={() => setIconMode('preset')}
                style={{
                  padding: '6px 14px',
                  borderRadius: '8px',
                  border: '1px solid',
                  borderColor: iconMode === 'preset' ? '#fc6011' : '#cbd5e1',
                  background: iconMode === 'preset' ? '#fff3e8' : '#ffffff',
                  color: iconMode === 'preset' ? '#c2410c' : '#64748b',
                  fontSize: '13px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                }}
              >
                <Store size={15} /> Chọn Biểu Tượng Icon Có Sẵn
              </button>
              <button
                type="button"
                onClick={() => setIconMode('upload')}
                style={{
                  padding: '6px 14px',
                  borderRadius: '8px',
                  border: '1px solid',
                  borderColor: iconMode === 'upload' ? '#fc6011' : '#cbd5e1',
                  background: iconMode === 'upload' ? '#fff3e8' : '#ffffff',
                  color: iconMode === 'upload' ? '#c2410c' : '#64748b',
                  fontSize: '13px',
                  fontWeight: 600,
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                }}
              >
                <ImageIcon size={15} /> Hoặc Tải Ảnh / Logo Riêng (1:1)
              </button>
            </div>

            {iconMode === 'preset' ? (
              <div
                style={{
                  border: '1px solid #e2e8f0',
                  borderRadius: '12px',
                  padding: '12px',
                  background: '#f8fafc',
                  maxHeight: '180px',
                  overflowY: 'auto',
                }}
              >
                <div
                  style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fill, minmax(110px, 1fr))',
                    gap: '8px',
                  }}
                >
                  {ICON_PRESETS.map((item) => {
                    const IconComp = item.icon;
                    const isSelected = form.icon === item.key;
                    return (
                      <button
                        type="button"
                        key={item.key}
                        onClick={() => setForm({ ...form, icon: item.key })}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '8px',
                          padding: '8px 10px',
                          borderRadius: '10px',
                          border: isSelected ? '2px solid #fc6011' : '1px solid #e2e8f0',
                          background: isSelected ? '#ffffff' : '#ffffff',
                          cursor: 'pointer',
                          boxShadow: isSelected ? '0 2px 6px rgba(252,96,17,0.2)' : 'none',
                          transition: 'all 0.15s ease',
                          textAlign: 'left',
                        }}
                      >
                        <div
                          style={{
                            width: '28px',
                            height: '28px',
                            borderRadius: '8px',
                            background: isSelected ? '#fff3e8' : '#f1f5f9',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            flexShrink: 0,
                          }}
                        >
                          <IconComp size={16} color={isSelected ? '#fc6011' : '#64748b'} />
                        </div>
                        <span
                          style={{
                            fontSize: '12px',
                            fontWeight: isSelected ? 700 : 500,
                            color: isSelected ? '#c2410c' : '#334155',
                            whiteSpace: 'nowrap',
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                          }}
                        >
                          {item.name}
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            ) : (
              <div style={{ background: '#f8fafc', padding: '12px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
                <ImageCropUpload
                  label="Tải Ảnh / Icon Riêng (Vuông 1:1)"
                  value={form.hinhAnh}
                  onChange={(url) => setForm({ ...form, hinhAnh: url })}
                  aspectRatio={1}
                />
              </div>
            )}
          </div>

          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label className="form-label">Trạng Thái Hoạt Động</label>
            <select
              className="form-control"
              value={form.trangThai}
              onChange={(e) => setForm({ ...form, trangThai: e.target.value })}
            >
              <option value="ACTIVE">Kích hoạt (Hiển thị cho quán chọn)</option>
              <option value="INACTIVE">Tạm ẩn</option>
            </select>
          </div>

          <div className="modal-footer" style={{ margin: '-24px', marginTop: '20px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setModalOpen(false)}>
              Hủy
            </button>
            <button type="submit" className="btn btn-primary">
              {editingItem ? 'Lưu Cập Nhật' : 'Tạo Loại Hình Mới'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Modal 2: View Restaurants in Category Modal */}
      <Modal
        isOpen={storesModalOpen}
        onClose={() => setStoresModalOpen(false)}
        title={`Danh Sách Quán: ${selectedCat?.tenLoai || ''}`}
        maxWidth="720px"
      >
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '14px' }}>
            <div style={{ fontSize: '13px', color: '#64748b' }}>
              Tìm thấy <strong style={{ color: '#0f172a' }}>{categoryStores.length}</strong> nhà hàng thuộc loại hình này
            </div>
            {onSelectCategoryFilter && selectedCat && (
              <button
                type="button"
                className="btn btn-primary btn-sm"
                onClick={() => {
                  setStoresModalOpen(false);
                  onSelectCategoryFilter(selectedCat.tenLoai);
                }}
              >
                Mở Bộ Lọc Quán Này Trong Tab Nhà Hàng
              </button>
            )}
          </div>

          {loadingStores ? (
            <div style={{ textAlign: 'center', padding: '30px' }}><div className="loading-spinner" /></div>
          ) : categoryStores.length === 0 ? (
            <div className="empty-state" style={{ padding: '30px' }}>
              Hiện chưa có nhà hàng nào thuộc loại hình này.
            </div>
          ) : (
            <div style={{ maxHeight: '420px', overflowY: 'auto' }}>
              <table className="data-table" style={{ fontSize: '13px' }}>
                <thead>
                  <tr>
                    <th>Nhà Hàng</th>
                    <th>Địa Chỉ</th>
                    <th>Số Điện Thoại</th>
                    <th>Trạng Thái</th>
                  </tr>
                </thead>
                <tbody>
                  {categoryStores.map((s) => (
                    <tr key={s.maQuan}>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <img
                            src={getImageUrl(s.img, DEFAULT_IMAGE_PLACEHOLDER)}
                            alt=""
                            onError={handleImageError}
                            style={{ width: '36px', height: '36px', borderRadius: '8px', objectFit: 'cover' }}
                          />
                          <div>
                            <div style={{ fontWeight: 700, color: '#0f172a' }}>{s.tenQuan}</div>
                            <div style={{ fontSize: '11px', color: '#64748b' }}>#{s.maQuan}</div>
                          </div>
                        </div>
                      </td>
                      <td style={{ color: '#475569', maxWidth: '240px' }}>{s.diaChi}</td>
                      <td style={{ color: '#64748b' }}>{s.sdt || '—'}</td>
                      <td><StatusBadge status={s.trangThai} /></td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </Modal>

      {/* Modal 3: Delete Confirmation Modal */}
      <Modal
        isOpen={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        title="Xác Nhận Xóa Loại Hình Quán"
        maxWidth="440px"
      >
        <div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '50%',
                background: '#fee2e2',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                flexShrink: 0,
              }}
            >
              <AlertCircle size={22} color="#dc2626" />
            </div>
            <div>
              <div style={{ fontWeight: 700, fontSize: '15px', color: '#0f172a' }}>
                Xóa loại hình "{deletingCat?.tenLoai}"?
              </div>
              <div style={{ fontSize: '13px', color: '#64748b', marginTop: '2px' }}>
                Thao tác này sẽ loại bỏ hoàn toàn loại hình khỏi hệ thống.
              </div>
            </div>
          </div>

          <div className="modal-footer" style={{ margin: '-24px', marginTop: '20px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setDeleteModalOpen(false)}>
              Hủy
            </button>
            <button type="button" className="btn btn-danger" onClick={handleConfirmDelete}>
              Xác Nhận Xóa
            </button>
          </div>
        </div>
      </Modal>

      {/* Notification Modal */}
      <Modal
        isOpen={notify.isOpen}
        onClose={() => setNotify({ ...notify, isOpen: false })}
        title={notify.title}
        maxWidth="440px"
      >
        <div style={{ padding: '10px 0' }}>
          <p style={{ color: notify.type === 'error' ? '#dc2626' : '#15803d', fontSize: '14px', lineHeight: 1.5 }}>
            {notify.message}
          </p>
          <div className="modal-footer" style={{ margin: '-24px', marginTop: '20px' }}>
            <button
              type="button"
              className="btn btn-primary"
              onClick={() => setNotify({ ...notify, isOpen: false })}
            >
              Đã Hiểu
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
