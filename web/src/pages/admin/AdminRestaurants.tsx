import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Search, Plus, Store, Link as LinkIcon } from 'lucide-react';
import { Modal } from '../../components/Modal';
import { ImageCropUpload } from '../../components/ImageCropUpload';

export const AdminRestaurants: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  const [modalOpen, setModalOpen] = useState(false);
  const [editingStore, setEditingStore] = useState<any>(null);
  const [form, setForm] = useState({ tenQuan: '', diaChi: '', sdt: '', img: '', trangThai: 'mở cửa', maTaiKhoan: '' });

  const fetchStores = () => {
    setLoading(true);
    apiFetch<any>(`/admin/restaurants?search=${encodeURIComponent(search)}`)
      .then((res) => setData(res.data))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchStores();
  }, [search]);

  const handleOpenAdd = () => {
    setEditingStore(null);
    setForm({ tenQuan: '', diaChi: '', sdt: '', img: '', trangThai: 'mở cửa', maTaiKhoan: '' });
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
    });
    setModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const payload = {
        ...form,
        maTaiKhoan: form.maTaiKhoan ? Number(form.maTaiKhoan) : undefined,
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
    } catch (err: any) {
      alert(err.message || 'Lỗi lưu nhà hàng');
    }
  };

  return (
    <div>
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
        <div className="table-toolbar">
          <div className="search-input-group">
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm tên nhà hàng, địa chỉ, SĐT..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : data.items.length === 0 ? (
          <div className="empty-state">Không có nhà hàng nào</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>Mã Quán</th>
                <th>Hình Ảnh</th>
                <th>Tên Nhà Hàng</th>
                <th>Địa Chỉ</th>
                <th>Số Điện Thoại</th>
                <th>Tài Khoản Quản Lý</th>
                <th>Trạng Thái</th>
                <th>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((s: any) => (
                <tr key={s.maQuan}>
                  <td style={{ fontWeight: 700 }}>#{s.maQuan}</td>
                  <td>
                    <img
                      src={s.img || 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=100'}
                      alt=""
                      style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover' }}
                    />
                  </td>
                  <td style={{ fontWeight: 700, color: '#0f172a' }}>{s.tenQuan}</td>
                  <td style={{ maxWidth: '240px' }}>{s.diaChi}</td>
                  <td>{s.sdt || 'Chưa có'}</td>
                  <td>
                    {s.taiKhoanLienKet ? (
                      <span className="badge badge-info"><LinkIcon size={12} /> {s.taiKhoanLienKet.tenDangNhap} (#{s.taiKhoanLienKet.maTaiKhoan})</span>
                    ) : (
                      <span className="badge badge-warning">Chưa gán</span>
                    )}
                  </td>
                  <td><span className="badge badge-success">{s.trangThai}</span></td>
                  <td>
                    <button className="btn btn-outline btn-sm" onClick={() => handleOpenEdit(s)}>Chỉnh Sửa</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editingStore ? 'Chỉnh Sửa Nhà Hàng' : 'Thêm Nhà Hàng Mới'}>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Tên Nhà Hàng</label>
            <input type="text" className="form-control" value={form.tenQuan} onChange={(e) => setForm({ ...form, tenQuan: e.target.value })} required />
          </div>
          <div className="form-group">
            <label className="form-label">Địa Chỉ</label>
            <input type="text" className="form-control" value={form.diaChi} onChange={(e) => setForm({ ...form, diaChi: e.target.value })} required />
          </div>
          <div className="form-group">
            <label className="form-label">Số Điện Thoại</label>
            <input type="text" className="form-control" value={form.sdt} onChange={(e) => setForm({ ...form, sdt: e.target.value })} />
          </div>
          <ImageCropUpload
            label="Hình Ảnh Banner/Logo Nhà Hàng"
            value={form.img}
            onChange={(url) => setForm({ ...form, img: url })}
            aspectRatio={1.77}
          />
          <div className="form-group">
            <label className="form-label">ID Tài Khoản Chủ Quán (maTaiKhoan)</label>
            <input type="number" className="form-control" placeholder="Ví dụ: 5" value={form.maTaiKhoan} onChange={(e) => setForm({ ...form, maTaiKhoan: e.target.value })} />
          </div>

          <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setModalOpen(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">Lưu Thông Tin</button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
