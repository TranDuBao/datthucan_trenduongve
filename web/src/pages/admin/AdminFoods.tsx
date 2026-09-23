import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Search, Edit2 } from 'lucide-react';
import { Modal } from '../../components/Modal';
import { ImageCropUpload } from '../../components/ImageCropUpload';

export const AdminFoods: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0 });
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  const [modalOpen, setModalOpen] = useState(false);
  const [editingFood, setEditingFood] = useState<any>(null);
  const [form, setForm] = useState({
    tenMonAn: '',
    maDanhMuc: '',
    giaMonAn: '',
    soLuongMon: '100',
    img: '',
  });

  const fetchFoods = () => {
    setLoading(true);
    Promise.all([
      apiFetch<any>(`/admin/foods?search=${encodeURIComponent(search)}`),
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
  }, [search]);

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
          img: form.img,
        }),
      });
      setModalOpen(false);
      fetchFoods();
    } catch (err: any) {
      alert(err.message || 'Lỗi cập nhật món ăn');
    }
  };

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản Lý Tất Cả Món Ăn</h1>
          <p className="page-subtitle">Danh sách món ăn & thức uống toàn hệ thống (Hỗ trợ phân loại danh mục & cắt upload ảnh)</p>
        </div>
      </div>

      <div className="card-table">
        <div className="table-toolbar">
          <div className="search-input-group">
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm tên món ăn..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : data.items.length === 0 ? (
          <div className="empty-state">Không có món ăn nào</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã Món</th>
                <th>Hình Ảnh</th>
                <th>Tên Món Ăn</th>
                <th>Danh Mục</th>
                <th>Mã Quán</th>
                <th>Giá Bán</th>
                <th>Số Lượng Phục Vụ</th>
                <th>Đánh Giá</th>
                <th>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((f: any) => (
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
                  <td><span className="badge badge-info">{f.tenDanhMuc || 'Chưa phân loại'}</span></td>
                  <td><span className="badge badge-warning">Quán #{f.maQuan || 'Chung'}</span></td>
                  <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(f.giaMonAn)}</td>
                  <td>{f.soLuongMon} phần</td>
                  <td>⭐ {f.diemDanhGiaTB || 5.0} ({f.soLuotDanhGia || 0})</td>
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
    </div>
  );
};
