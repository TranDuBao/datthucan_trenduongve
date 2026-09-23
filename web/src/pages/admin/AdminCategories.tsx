import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Plus, FolderTree } from 'lucide-react';
import { Modal } from '../../components/Modal';

export const AdminCategories: React.FC = () => {
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [tenDanhMuc, setTenDanhMuc] = useState('');

  const fetchCategories = () => {
    setLoading(true);
    apiFetch<any>('/admin/categories')
      .then((res) => setCategories(res.data || []))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!tenDanhMuc.trim()) return;
    try {
      await apiFetch('/admin/categories', {
        method: 'POST',
        body: JSON.stringify({ tenDanhMuc: tenDanhMuc.trim() }),
      });
      setTenDanhMuc('');
      setModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      alert(err.message || 'Lỗi thêm danh mục');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản Lý Danh Mục Món Ăn</h1>
          <p className="page-subtitle">Danh mục các loại đồ ăn & thức uống trên hệ thống</p>
        </div>
        <button className="btn btn-primary" onClick={() => setModalOpen(true)}>
          <Plus size={16} /> Thêm Danh Mục Mới
        </button>
      </div>

      <div className="card-table">
        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : categories.length === 0 ? (
          <div className="empty-state">Chưa có danh mục nào</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Tên Danh Mục</th>
              </tr>
            </thead>
            <tbody>
              {categories.map((c: any) => (
                <tr key={c.maDanhMuc}>
                  <td style={{ fontWeight: 700 }}>#{c.maDanhMuc}</td>
                  <td style={{ fontWeight: 700, color: '#0f172a' }}>{c.tenDanhMuc}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title="Thêm Danh Mục Mới">
        <form onSubmit={handleCreate}>
          <div className="form-group">
            <label className="form-label">Tên Danh Mục</label>
            <input
              type="text"
              className="form-control"
              placeholder="Ví dụ: Phở Nóng, Trà Sữa..."
              value={tenDanhMuc}
              onChange={(e) => setTenDanhMuc(e.target.value)}
              required
            />
          </div>
          <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setModalOpen(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">Thêm Danh Mục</button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
