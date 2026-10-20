import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Search, Edit2, UtensilsCrossed } from 'lucide-react';
import { Modal } from '../../components/Modal';
import { NotificationModal } from '../../components/NotificationModal';
import { ImageCropUpload } from '../../components/ImageCropUpload';
import { AnimatedCounter } from '../../components/AnimatedCounter';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../utils/imageUtils';

export const AdminFoods: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0 });
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('');

  const [modalOpen, setModalOpen] = useState(false);
  const [editingFood, setEditingFood] = useState<any>(null);

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

  const [form, setForm] = useState({
    tenMonAn: '',
    maDanhMuc: '',
    giaMonAn: '',
    soLuongMon: '100',
    trangThaiMon: 'DANG_BAN',
    img: '',
  });

  const fetchFoods = () => {
    setLoading(true);
    const catQuery = selectedCategory ? `&maDanhMuc=${selectedCategory}` : '';
    Promise.all([
      apiFetch<any>(`/admin/foods?limit=1000&search=${encodeURIComponent(search)}${catQuery}`),
      apiFetch<any>('/admin/categories').catch(() => ({ data: [] })),
    ])
      .then(([foodRes, catRes]) => {
        setData(foodRes.data || { items: [], total: 0 });
        setCategories(catRes.data || []);
      })
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchFoods();
  }, [search, selectedCategory]);

  const handleOpenEdit = (food: any) => {
    setEditingFood(food);
    setForm({
      tenMonAn: food.tenMonAn || '',
      maDanhMuc: food.maDanhMuc ? String(food.maDanhMuc) : '',
      giaMonAn: String(food.giaMonAn || 0),
      soLuongMon: String(food.soLuongMon ?? 100),
      trangThaiMon: food.trangThaiMon || ((Number(food.soLuongMon) > 0) ? 'DANG_BAN' : 'HET_HANG'),
      img: food.img || '',
    });
    setModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await apiFetch(`/admin/foods/${editingFood.maMonAn}`, {
        method: 'PUT',
        body: JSON.stringify({
          tenMonAn: form.tenMonAn,
          maDanhMuc: form.maDanhMuc
            ? Number(form.maDanhMuc)
            : categories.length > 0
            ? categories[0].maDanhMuc
            : undefined,
          giaMonAn: Number(form.giaMonAn),
          soLuongMon: Number(form.soLuongMon),
          trangThaiMon: form.trangThaiMon,
          img: form.img,
        }),
      });
      setModalOpen(false);
      fetchFoods();
      showNotify('success', 'Cập Nhật Thành Công', 'Thông tin món ăn & hình ảnh mới đã được lưu thành công vào hệ thống!');
    } catch (err: any) {
      showNotify('error', 'Lỗi Cập Nhật', err.message || 'Lỗi cập nhật món ăn');
    }
  };

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  const getCategoryName = (food: any) => {
    if (food.tenDanhMuc && food.tenDanhMuc !== 'Chưa phân loại') return food.tenDanhMuc;
    const cat = categories.find((c) => Number(c.maDanhMuc) === Number(food.maDanhMuc));
    return cat ? cat.tenDanhMuc : 'Chưa phân loại';
  };

  const filteredItems = (data.items || []).filter((f: any) => {
    if (!selectedCategory) return true;
    if (Number(f.maDanhMuc) === Number(selectedCategory)) return true;
    const targetCat = categories.find((c) => Number(c.maDanhMuc) === Number(selectedCategory));
    if (targetCat) {
      const itemCatName = getCategoryName(f);
      if (itemCatName.trim().toLowerCase() === targetCat.tenDanhMuc.trim().toLowerCase()) return true;
    }
    return false;
  });

  const selectedCategoryObj = categories.find((c: any) => Number(c.maDanhMuc) === Number(selectedCategory));

  return (
    <div>
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 className="page-title">Quản Lý Tất Cả Món Ăn</h1>
          <p className="page-subtitle">Danh sách món ăn & thức uống toàn hệ thống (Hỗ trợ phân loại danh mục & cắt upload ảnh)</p>
        </div>

        <div style={{
          background: 'linear-gradient(135deg, #fff5f0 0%, #ffede5 100%)',
          border: '1px solid #ffd8cc',
          padding: '10px 20px',
          borderRadius: '12px',
          display: 'flex',
          alignItems: 'center',
          gap: '12px',
          boxShadow: '0 2px 8px rgba(252, 96, 17, 0.08)'
        }}>
          <div style={{
            width: '40px',
            height: '40px',
            borderRadius: '10px',
            backgroundColor: '#fc6011',
            color: '#fff',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}>
            <UtensilsCrossed size={20} />
          </div>
          <div>
            <div style={{ fontSize: '12px', color: '#64748b', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
              {selectedCategoryObj ? `Món (${selectedCategoryObj.tenDanhMuc})` : 'Tổng Số Lượng Món'}
            </div>
            <div style={{ fontSize: '24px', fontWeight: 800, color: '#fc6011', lineHeight: '1.2' }}>
              <AnimatedCounter value={filteredItems.length} /> <span style={{ fontSize: '14px', fontWeight: 600 }}>món</span>
            </div>
          </div>
        </div>
      </div>

      <div className="card-table">
        <div className="table-toolbar" style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
          <div className="search-input-group" style={{ flex: 1 }}>
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm tên món ăn..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <select
              className="form-control"
              style={{
                width: '240px',
                padding: '9px 14px',
                fontSize: '14px',
                fontWeight: 600,
                borderRadius: '8px',
                borderColor: '#cbd5e1',
                backgroundColor: '#ffffff',
                color: '#334155',
                cursor: 'pointer',
              }}
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
            >
              <option value="">📂 Tất Cả Danh Mục</option>
              {categories.map((c: any) => (
                <option key={c.maDanhMuc} value={c.maDanhMuc}>
                  🏷️ {c.tenDanhMuc}
                </option>
              ))}
            </select>
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : filteredItems.length === 0 ? (
          <div className="empty-state">Không tìm thấy món ăn nào thuộc danh mục đã chọn</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                <th>Mã Món</th>
                <th>Hình Ảnh</th>
                <th>Tên Món Ăn</th>
                <th>Danh Mục</th>
                <th>Mã Quán</th>
                <th>Giá Bán</th>
                <th>Số Lượng Phục Vụ</th>
                <th>Trạng Thái</th>
                <th>Đánh Giá</th>
                <th>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.map((f: any, idx: number) => (
                <tr key={f.maMonAn}>
                  <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{idx + 1}</td>
                  <td style={{ fontWeight: 700 }}>#{f.maMonAn}</td>
                  <td>
                    <img
                      src={getImageUrl(f.img, DEFAULT_IMAGE_PLACEHOLDER)}
                      alt={f.tenMonAn}
                      onError={handleImageError}
                      style={{ width: '44px', height: '44px', borderRadius: '8px', objectFit: 'cover' }}
                    />
                  </td>
                  <td style={{ fontWeight: 700, color: '#0f172a' }}>{f.tenMonAn}</td>
                  <td><span className="badge badge-info">{getCategoryName(f)}</span></td>
                  <td><span className="badge badge-warning">Quán #{f.maQuan || 'Chung'}</span></td>
                  <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(f.giaMonAn)}</td>
                  <td>{f.soLuongMon} phần</td>
                  <td>
                    {f.trangThaiMon === 'TAM_NGUNG' ? (
                      <span className="badge" style={{ background: '#fef3c7', color: '#d97706', border: '1px solid #fde68a' }}>Tạm ngưng</span>
                    ) : Number(f.soLuongMon) <= 0 || f.trangThaiMon === 'HET_HANG' ? (
                      <span className="badge" style={{ background: '#fee2e2', color: '#ef4444', border: '1px solid #fecaca' }}>Hết món</span>
                    ) : (
                      <span className="badge" style={{ background: '#dcfce7', color: '#16a34a', border: '1px solid #bbf7d0' }}>Đang bán</span>
                    )}
                  </td>
                  <td>⭐ {f.diemDanhGiaTB && Number(f.diemDanhGiaTB) > 0 ? Number(f.diemDanhGiaTB).toFixed(1) : 'Chưa có'} ({f.soLuotDanhGia || 0})</td>
                  <td>
                    <button className="btn btn-outline btn-sm" onClick={() => handleOpenEdit(f)}>
                      <Edit2 size={14} /> Chỉnh Sửa
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={`Chỉnh Sửa Món Ăn #${editingFood?.maMonAn}`}>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Tên Món Ăn</label>
            <input
              type="text"
              className="form-control"
              value={form.tenMonAn}
              onChange={(e) => setForm({ ...form, tenMonAn: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Loại Món Ăn (Danh Mục)</label>
            <select
              className="form-control"
              value={form.maDanhMuc}
              onChange={(e) => setForm({ ...form, maDanhMuc: e.target.value })}
            >
              <option value="">-- Chọn danh mục --</option>
              {categories.map((c: any) => (
                <option key={c.maDanhMuc} value={c.maDanhMuc}>
                  {c.tenDanhMuc}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Giá Bán (VNĐ)</label>
            <input
              type="number"
              className="form-control"
              value={form.giaMonAn}
              onChange={(e) => setForm({ ...form, giaMonAn: e.target.value })}
              required
            />
          </div>
          <div className="form-group">
            <label className="form-label">Số Lượng Phục Vụ</label>
            <input
              type="number"
              className="form-control"
              value={form.soLuongMon}
              onChange={(e) => setForm({ ...form, soLuongMon: e.target.value })}
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">Trạng Thái Kinh Doanh</label>
            <select
              className="form-control"
              value={form.trangThaiMon}
              onChange={(e) => setForm({ ...form, trangThaiMon: e.target.value })}
            >
              <option value="DANG_BAN">Đang kinh doanh (Mở bán)</option>
              <option value="TAM_NGUNG">Tạm ngưng phục vụ</option>
              <option value="HET_HANG">Hết nguyên liệu / Hết món</option>
            </select>
          </div>

          <ImageCropUpload
            label="Hình Ảnh Món Ăn (Upload & Cắt Khung 1:1)"
            value={form.img}
            onChange={(url) => setForm({ ...form, img: url })}
            aspectRatio={1}
          />

          <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setModalOpen(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">Lưu Thay Đổi</button>
          </div>
        </form>
      </Modal>

      <NotificationModal
        isOpen={notifyModal.isOpen}
        onClose={() => setNotifyModal((prev) => ({ ...prev, isOpen: false }))}
        type={notifyModal.type}
        title={notifyModal.title}
        message={notifyModal.message}
      />
    </div>
  );
};
