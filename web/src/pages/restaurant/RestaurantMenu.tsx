import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Plus, Edit2, Trash2 } from 'lucide-react';
import { Modal } from '../../components/Modal';
import { ImageCropUpload } from '../../components/ImageCropUpload';

export const RestaurantMenu: React.FC = () => {
  const [foods, setFoods] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingFood, setEditingFood] = useState<any>(null);

  const [form, setForm] = useState({
    tenMonAn: '',
    maDanhMuc: '',
    giaMonAn: '',
    soLuongMon: '100',
    img: '',
  });

  const fetchData = () => {
    setLoading(true);
    Promise.all([
      apiFetch<any>('/restaurant/menu'),
      apiFetch<any>('/restaurant/categories').catch(() => ({ data: [] })),
    ])
      .then(([menuRes, catRes]) => {
        setFoods(menuRes.data || []);
        setCategories(catRes.data || []);
      })
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleOpenAdd = () => {
    setEditingFood(null);
    const defaultCat = categories.length > 0 ? String(categories[0].maDanhMuc) : '';
    setForm({ tenMonAn: '', maDanhMuc: defaultCat, giaMonAn: '', soLuongMon: '100', img: '' });
    setModalOpen(true);
  };

  const handleOpenEdit = (food: any) => {
    setEditingFood(food);
    setForm({
      tenMonAn: food.tenMonAn || '',
      maDanhMuc: food.maDanhMuc ? String(food.maDanhMuc) : '',
      giaMonAn: String(food.giaMonAn || 0),
      soLuongMon: String(food.soLuongMon || 100),
      img: food.img || '',
    });
    setModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const selectedCatId = form.maDanhMuc
        ? Number(form.maDanhMuc)
        : categories.length > 0
        ? categories[0].maDanhMuc
        : undefined;

      const payload = {
        tenMonAn: form.tenMonAn,
        maDanhMuc: selectedCatId,
        giaMonAn: Number(form.giaMonAn),
        soLuongMon: Number(form.soLuongMon),
        img: form.img,
      };

      if (editingFood) {
        await apiFetch(`/restaurant/menu/${editingFood.maMonAn}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
      } else {
        await apiFetch('/restaurant/menu', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
      }
      setModalOpen(false);
      fetchData();
    } catch (err: any) {
      alert(err.message || 'Lỗi lưu món ăn');
    }
  };

  const handleDelete = async (id: number) => {
    if (!window.confirm('Bạn có chắc muốn xóa món ăn này khỏi thực đơn?')) return;
    try {
      await apiFetch(`/restaurant/menu/${id}`, { method: 'DELETE' });
      fetchData();
    } catch (err: any) {
      alert(err.message || 'Lỗi xóa món');
    }
  };

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản Lý Thực Đơn Nhà Hàng</h1>
          <p className="page-subtitle">Thêm, sửa, chọn loại món ăn, đổi giá và hình ảnh của quán</p>
        </div>
        <button className="btn btn-primary" onClick={handleOpenAdd}>
          <Plus size={16} /> Thêm Món Ăn Mới
        </button>
      </div>

      <div className="card-table">
        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : foods.length === 0 ? (
          <div className="empty-state">Chưa có món ăn nào trong thực đơn của quán</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã Món</th>
                <th>Hình Ảnh</th>
                <th>Tên Món Ăn</th>
                <th>Loại Món (Danh Mục)</th>
                <th>Giá Bán</th>
                <th>Số Lượng Phục Vụ</th>
                <th>Đánh Giá</th>
                <th>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {foods.map((f) => (
                <tr key={f.maMonAn}>
                  <td style={{ fontWeight: 700 }}>#{f.maMonAn}</td>
                  <td>
                    <img
                      src={f.img || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=100'}
                      alt=""
                      style={{ width: '44px', height: '44px', borderRadius: '8px', objectFit: 'cover' }}
                    />
                  </td>
                  <td style={{ fontWeight: 700, color: '#0f172a' }}>{f.tenMonAn}</td>
                  <td>
                    <span className="badge badge-info">{f.tenDanhMuc || 'Chưa phân loại'}</span>
                  </td>
                  <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(f.giaMonAn)}</td>
                  <td><span className="badge badge-info">{f.soLuongMon || 100} phần</span></td>
                  <td>⭐ {f.diemDanhGiaTB || 5.0}</td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button className="btn btn-outline btn-sm" onClick={() => handleOpenEdit(f)}><Edit2 size={14} /> Sửa</button>
                      <button className="btn btn-outline btn-sm" style={{ color: '#ef4444' }} onClick={() => handleDelete(f.maMonAn)}><Trash2 size={14} /> Xóa</button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editingFood ? 'Chỉnh Sửa Món Ăn' : 'Thêm Món Ăn Mới'}>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Tên Món Ăn</label>
            <input type="text" className="form-control" value={form.tenMonAn} onChange={(e) => setForm({ ...form, tenMonAn: e.target.value })} required />
          </div>

          <div className="form-group">
            <label className="form-label">Loại Món Ăn (Danh Mục)</label>
            <select
              className="form-control"
              value={form.maDanhMuc}
              onChange={(e) => setForm({ ...form, maDanhMuc: e.target.value })}
            >
              <option value="">-- Chọn danh mục --</option>
              {categories.map((c) => (
                <option key={c.maDanhMuc} value={c.maDanhMuc}>
                  {c.tenDanhMuc}
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Giá Bán (VNĐ)</label>
            <input type="number" className="form-control" value={form.giaMonAn} onChange={(e) => setForm({ ...form, giaMonAn: e.target.value })} required />
          </div>
          <div className="form-group">
            <label className="form-label">Số Lượng Phục Vụ Hôm Nay</label>
            <input type="number" className="form-control" value={form.soLuongMon} onChange={(e) => setForm({ ...form, soLuongMon: e.target.value })} required />
          </div>
          <ImageCropUpload
            label="Hình Ảnh Món Ăn (Upload & Cắt Khung 1:1)"
            value={form.img}
            onChange={(url) => setForm({ ...form, img: url })}
            aspectRatio={1}
          />

          <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setModalOpen(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">Lưu Món Ăn</button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
