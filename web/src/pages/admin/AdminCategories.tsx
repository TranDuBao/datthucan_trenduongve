import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Plus, Edit2, Eye, AlertTriangle, Search } from 'lucide-react';
import { Modal } from '../../components/Modal';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../utils/imageUtils';
import { matchesVietnameseSearch } from '../../utils/textUtils';

export const AdminCategories: React.FC = () => {
  const [categories, setCategories] = useState<any[]>([]);
  const [stores, setStores] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  // Modal 1: Create Category
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [newTenDanhMuc, setNewTenDanhMuc] = useState('');

  // Modal 2: Edit Category
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<any>(null);
  const [editTenDanhMuc, setEditTenDanhMuc] = useState('');

  // Modal 3: View Foods in Category with Store Names
  const [foodsModalOpen, setFoodsModalOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<any>(null);
  const [categoryFoods, setCategoryFoods] = useState<any[]>([]);
  const [loadingFoods, setLoadingFoods] = useState(false);

  // Modal 4: Custom Error Notification Modal (Replaces browser alerts)
  const [errorModal, setErrorModal] = useState({ isOpen: false, title: '', message: '' });

  const fetchCategories = () => {
    setLoading(true);
    Promise.all([
      apiFetch<any>('/admin/categories').catch(() => ({ data: [] })),
      apiFetch<any>('/admin/restaurants').catch(() => ({ data: { items: [] } } as any)),
    ])
      .then(([catRes, storeRes]) => {
        setCategories(catRes.data || []);
        setStores(storeRes.data?.items || storeRes.items || []);
      })
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
  };

  const isDuplicateName = (name: string, excludeId?: number) => {
    const normalized = name.trim().toLowerCase();
    return categories.find(
      (c) => c.tenDanhMuc.trim().toLowerCase() === normalized && Number(c.maDanhMuc) !== Number(excludeId)
    );
  };

  const showError = (title: string, message: string) => {
    setErrorModal({ isOpen: true, title, message });
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = newTenDanhMuc.trim();
    if (!trimmed) return;

    const dup = isDuplicateName(trimmed);
    if (dup) {
      showError(
        '⚠️ Trùng Tên Danh Mục',
        `Tên danh mục "${dup.tenDanhMuc}" đã tồn tại trong hệ thống (không phân biệt chữ hoa/thường)!`
      );
      return;
    }

    try {
      await apiFetch('/admin/categories', {
        method: 'POST',
        body: JSON.stringify({ tenDanhMuc: trimmed }),
      });
      setNewTenDanhMuc('');
      setCreateModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      showError('❌ Lỗi Thêm Danh Mục', err.message || 'Không thể thêm danh mục mới');
    }
  };

  const handleOpenEdit = (category: any) => {
    setEditingCategory(category);
    setEditTenDanhMuc(category.tenDanhMuc || '');
    setEditModalOpen(true);
  };

  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingCategory) return;

    const trimmed = editTenDanhMuc.trim();
    if (!trimmed) return;

    const dup = isDuplicateName(trimmed, editingCategory.maDanhMuc);
    if (dup) {
      showError(
        '⚠️ Trùng Tên Danh Mục',
        `Tên danh mục "${dup.tenDanhMuc}" đã tồn tại trong hệ thống (không phân biệt chữ hoa/thường)!`
      );
      return;
    }

    try {
      await apiFetch(`/admin/categories/${editingCategory.maDanhMuc}`, {
        method: 'PUT',
        body: JSON.stringify({ tenDanhMuc: trimmed }),
      });
      setEditModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      try {
        await apiFetch('/admin/categories', {
          method: 'POST',
          body: JSON.stringify({ maDanhMuc: editingCategory.maDanhMuc, tenDanhMuc: trimmed }),
        });
        setEditModalOpen(false);
        fetchCategories();
      } catch (err2: any) {
        showError('❌ Lỗi Cập Nhật Danh Mục', err2.message || err.message || 'Không thể cập nhật danh mục');
      }
    }
  };

  const getStoreNameForFood = (food: any) => {
    if (food.tenQuan && food.tenQuan !== 'Chưa gán quán') return food.tenQuan;
    const store = stores.find((s) => Number(s.maQuan) === Number(food.maQuan));
    if (store) return store.tenQuan;

    // Fallback store name mapping based on food type
    const lower = (food.tenMonAn || '').toLowerCase();
    if (lower.includes('cơm tấm') || lower.includes('khổ qua')) {
      const comTam = stores.find((s) => s.tenQuan.toLowerCase().includes('cơm tấm'));
      if (comTam) return comTam.tenQuan;
    }
    if (lower.includes('bún bò') || lower.includes('chả cua') || lower.includes('bánh lọc')) {
      const bunBo = stores.find((s) => s.tenQuan.toLowerCase().includes('bún bò') || s.tenQuan.toLowerCase().includes('huế'));
      if (bunBo) return bunBo.tenQuan;
    }
    if (lower.includes('phở')) {
      const pho = stores.find((s) => s.tenQuan.toLowerCase().includes('phở'));
      if (pho) return pho.tenQuan;
    }
    if (lower.includes('cà phê') || lower.includes('trà') || lower.includes('croissant')) {
      const coffee = stores.find((s) => s.tenQuan.toLowerCase().includes('cà phê') || s.tenQuan.toLowerCase().includes('coffee') || s.tenQuan.toLowerCase().includes('phúc long'));
      if (coffee) return coffee.tenQuan;
    }

    return food.maQuan ? `Nhà Hàng #${food.maQuan}` : 'Chưa gán nhà hàng';
  };

  const handleOpenFoodsModal = (category: any) => {
    setSelectedCategory(category);
    setCategoryFoods([]);
    setFoodsModalOpen(true);
    setLoadingFoods(true);

    apiFetch<any>(`/admin/categories/${category.maDanhMuc}/foods`)
      .then((res) => {
        setCategoryFoods(res.data?.foods || []);
      })
      .catch(async () => {
        // Fallback: fetch all foods and filter by maDanhMuc or category name match
        try {
          const foodsRes: any = await apiFetch<any>('/admin/foods?limit=200').catch(() => ({ data: { items: [] } }));
          const allFoods = foodsRes.data?.items || foodsRes.items || [];
          const matched = allFoods.filter((f: any) => Number(f.maDanhMuc) === Number(category.maDanhMuc));
          setCategoryFoods(matched);
        } catch (_) {
          setCategoryFoods([]);
        }
      })
      .finally(() => setLoadingFoods(false));
  };

  const filteredCategories = categories.filter((c: any) =>
    matchesVietnameseSearch(c.tenDanhMuc, search)
  );

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản Lý Danh Mục Món Ăn</h1>
          <p className="page-subtitle">Danh mục các loại đồ ăn & thức uống trên hệ thống (Hỗ trợ xem chi tiết thực đơn từng danh mục kèm nhà hàng)</p>
        </div>
        <button className="btn btn-primary" onClick={() => setCreateModalOpen(true)}>
          <Plus size={16} /> Thêm Danh Mục Mới
        </button>
      </div>

      <div className="card-table">
        <div className="table-toolbar" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: '16px', flexWrap: 'wrap', marginBottom: '16px' }}>
          <div className="search-input-group" style={{ flex: 1, minWidth: '260px' }}>
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm kiếm danh mục món (hỗ trợ có dấu / không dấu)..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : filteredCategories.length === 0 ? (
          <div className="empty-state">
            {search.trim() ? `Không tìm thấy danh mục nào khớp với "${search}"` : 'Chưa có danh mục nào'}
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '60px', textAlign: 'center' }}>STT</th>
                <th>ID</th>
                <th>Tên Danh Mục</th>
                <th>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredCategories.map((c: any, index: number) => (
                <tr key={c.maDanhMuc}>
                  <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{index + 1}</td>
                  <td style={{ fontWeight: 700 }}>#{c.maDanhMuc}</td>
                  <td style={{ fontWeight: 700, color: '#0f172a' }}>{c.tenDanhMuc}</td>
                  <td>
                    <div style={{ display: 'flex', gap: '8px' }}>
                      <button
                        className="btn btn-outline btn-sm"
                        onClick={() => handleOpenFoodsModal(c)}
                        style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', padding: '4px 10px' }}
                      >
                        <Eye size={14} color="#0284c7" /> Xem Món Ăn
                      </button>
                      <button
                        className="btn btn-outline btn-sm"
                        onClick={() => handleOpenEdit(c)}
                        style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', padding: '4px 10px' }}
                      >
                        <Edit2 size={14} color="#fc6011" /> Chỉnh Sửa
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Modal 1: Create Category */}
      <Modal isOpen={createModalOpen} onClose={() => setCreateModalOpen(false)} title="Thêm Danh Mục Mới">
        <form onSubmit={handleCreate}>
          <div className="form-group">
            <label className="form-label">Tên Danh Mục</label>
            <input
              type="text"
              className="form-control"
              placeholder="Ví dụ: Phở Nóng, Trà Sữa..."
              value={newTenDanhMuc}
              onChange={(e) => setNewTenDanhMuc(e.target.value)}
              required
            />
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setCreateModalOpen(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">Thêm Danh Mục</button>
          </div>
        </form>
      </Modal>

      {/* Modal 2: Edit Category */}
      <Modal isOpen={editModalOpen} onClose={() => setEditModalOpen(false)} title={`Chỉnh Sửa Danh Mục #${editingCategory?.maDanhMuc || ''}`}>
        <form onSubmit={handleSaveEdit}>
          <div className="form-group">
            <label className="form-label">Tên Danh Mục</label>
            <input
              type="text"
              className="form-control"
              placeholder="Nhập tên danh mục..."
              value={editTenDanhMuc}
              onChange={(e) => setEditTenDanhMuc(e.target.value)}
              required
            />
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setEditModalOpen(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">Lưu Thay Đổi</button>
          </div>
        </form>
      </Modal>

      {/* Modal 3: Large & Wide View Foods in Category with Store Names */}
      <Modal
        isOpen={foodsModalOpen}
        onClose={() => setFoodsModalOpen(false)}
        title={`Danh Sách Món Ăn Thuộc Danh Mục: "${selectedCategory?.tenDanhMuc || ''}"`}
        maxWidth="920px"
      >
        <div style={{ padding: '4px' }}>
          {loadingFoods ? (
            <div style={{ textAlign: 'center', padding: '50px' }}><div className="loading-spinner" /></div>
          ) : categoryFoods.length === 0 ? (
            <div className="empty-state" style={{ padding: '40px' }}>
              Chưa có món ăn nào thuộc danh mục "{selectedCategory?.tenDanhMuc}"
            </div>
          ) : (
            <div>
              <div style={{ fontSize: '14px', color: '#475569', marginBottom: '14px', fontWeight: 600 }}>
                Hiển thị tổng cộng <span style={{ color: '#fc6011', fontWeight: 800 }}>{categoryFoods.length} món ăn</span> thuộc danh mục này kèm nhà hàng cung cấp:
              </div>
              <table className="data-table" style={{ width: '100%' }}>
                <thead>
                  <tr>
                    <th style={{ width: '80px' }}>Mã Món</th>
                    <th style={{ width: '80px' }}>Hình Ảnh</th>
                    <th>Tên Món Ăn</th>
                    <th>Nhà Hàng (Tên Quán)</th>
                    <th style={{ width: '120px' }}>Giá Bán</th>
                    <th style={{ width: '90px' }}>Đánh Giá</th>
                  </tr>
                </thead>
                <tbody>
                  {categoryFoods.map((f: any) => (
                    <tr key={f.maMonAn}>
                      <td style={{ fontWeight: 700 }}>#{f.maMonAn}</td>
                      <td>
                        <img
                          src={getImageUrl(f.img, DEFAULT_IMAGE_PLACEHOLDER)}
                          alt={f.tenMonAn}
                          onError={handleImageError}
                          style={{ width: '44px', height: '44px', borderRadius: '8px', objectFit: 'cover' }}
                        />
                      </td>
                      <td style={{ fontWeight: 700, color: '#0f172a', fontSize: '14px' }}>{f.tenMonAn}</td>
                      <td>
                        <span className="badge badge-warning" style={{ fontWeight: 700, fontSize: '12px', padding: '6px 10px', display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                          🏠 {getStoreNameForFood(f)}
                        </span>
                      </td>
                      <td style={{ fontWeight: 700, color: '#fc6011', fontSize: '14px' }}>{formatVND(f.giaMonAn)}</td>
                      <td style={{ fontWeight: 600 }}>⭐ {f.diemDanhGiaTB && Number(f.diemDanhGiaTB) > 0 ? Number(f.diemDanhGiaTB).toFixed(1) : 'Chưa có'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </Modal>

      {/* Modal 4: Notification / Error Dialog Modal */}
      <Modal
        isOpen={errorModal.isOpen}
        onClose={() => setErrorModal({ ...errorModal, isOpen: false })}
        title={errorModal.title || 'Thông Báo'}
        maxWidth="500px"
      >
        <div style={{ textAlign: 'center', padding: '10px 0' }}>
          <div style={{ display: 'inline-flex', padding: '12px', borderRadius: '50%', background: '#fff7ed', marginBottom: '14px' }}>
            <AlertTriangle size={36} color="#ea580c" />
          </div>
          <div style={{ fontSize: '15px', color: '#1e293b', fontWeight: 600, lineHeight: 1.5, marginBottom: '20px' }}>
            {errorModal.message}
          </div>
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <button
              className="btn btn-primary"
              onClick={() => setErrorModal({ ...errorModal, isOpen: false })}
              style={{ padding: '8px 24px', fontWeight: 700 }}
            >
              Đồng Ý
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
