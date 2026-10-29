import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Plus, Edit2, Eye, AlertTriangle, Search, Trash2, PlusCircle, Check, Utensils, Store } from 'lucide-react';
import { Modal } from '../../components/Modal';
import { ImageCropUpload } from '../../components/ImageCropUpload';
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
  const [newHinhAnh, setNewHinhAnh] = useState('');

  // Modal 2: Edit Category
  const [editModalOpen, setEditModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<any>(null);
  const [editTenDanhMuc, setEditTenDanhMuc] = useState('');
  const [editHinhAnh, setEditHinhAnh] = useState('');

  // Modal 3: View & Assign Foods in Category
  const [foodsModalOpen, setFoodsModalOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<any>(null);
  const [categoryFoods, setCategoryFoods] = useState<any[]>([]);
  const [loadingFoods, setLoadingFoods] = useState(false);
  const [foodTab, setFoodTab] = useState<'current' | 'assign'>('current');

  // Search & all foods for assignment
  const [allFoods, setAllFoods] = useState<any[]>([]);
  const [loadingAllFoods, setLoadingAllFoods] = useState(false);
  const [assignSearch, setAssignSearch] = useState('');
  const [assigningId, setAssigningId] = useState<number | null>(null);

  // Modal 4: Delete Category
  const [deleteModalOpen, setDeleteModalOpen] = useState(false);
  const [deletingCategory, setDeletingCategory] = useState<any>(null);

  // Modal 5: Custom Error / Success Notification Modal
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
        'Trùng Tên Danh Mục',
        `Tên danh mục "${dup.tenDanhMuc}" đã tồn tại trong hệ thống (không phân biệt chữ hoa/thường)!`
      );
      return;
    }

    try {
      await apiFetch('/admin/categories', {
        method: 'POST',
        body: JSON.stringify({ tenDanhMuc: trimmed, hinhAnh: newHinhAnh.trim() || undefined }),
      });
      setNewTenDanhMuc('');
      setNewHinhAnh('');
      setCreateModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      showError('Lỗi Thêm Danh Mục', err.message || 'Không thể thêm danh mục mới');
    }
  };

  const handleOpenEdit = (category: any) => {
    setEditingCategory(category);
    setEditTenDanhMuc(category.tenDanhMuc || '');
    setEditHinhAnh(category.hinhAnh || '');
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
        'Trùng Tên Danh Mục',
        `Tên danh mục "${dup.tenDanhMuc}" đã tồn tại trong hệ thống (không phân biệt chữ hoa/thường)!`
      );
      return;
    }

    try {
      await apiFetch(`/admin/categories/${editingCategory.maDanhMuc}`, {
        method: 'PUT',
        body: JSON.stringify({ tenDanhMuc: trimmed, hinhAnh: editHinhAnh.trim() }),
      });
      setEditModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      showError('Lỗi Cập Nhật Danh Mục', err.message || 'Không thể cập nhật danh mục');
    }
  };

  const handleDeleteCategory = async () => {
    if (!deletingCategory) return;
    try {
      await apiFetch(`/admin/categories/${deletingCategory.maDanhMuc}`, { method: 'DELETE' });
      setDeleteModalOpen(false);
      fetchCategories();
    } catch (err: any) {
      showError('Lỗi Xóa Danh Mục', err.message || 'Không thể xóa danh mục');
    }
  };

  const getStoreNameForFood = (food: any) => {
    if (food.tenQuan && food.tenQuan !== 'Chưa gán quán') return food.tenQuan;
    const store = stores.find((s) => Number(s.maQuan) === Number(food.maQuan));
    if (store) return store.tenQuan;
    return food.maQuan ? `Nhà Hàng #${food.maQuan}` : 'Chưa gán nhà hàng';
  };

  const loadCategoryFoods = async (catId: number) => {
    setLoadingFoods(true);
    try {
      const res = await apiFetch<any>(`/admin/categories/${catId}/foods`);
      setCategoryFoods(res.data?.foods || []);
    } catch {
      setCategoryFoods([]);
    } finally {
      setLoadingFoods(false);
    }
  };

  const loadAllFoods = async () => {
    if (allFoods.length > 0) return;
    setLoadingAllFoods(true);
    try {
      const res = await apiFetch<any>('/admin/foods?limit=500');
      setAllFoods(res.data?.items || res.items || []);
    } catch {
      setAllFoods([]);
    } finally {
      setLoadingAllFoods(false);
    }
  };

  const handleOpenFoodsModal = (category: any) => {
    setSelectedCategory(category);
    setCategoryFoods([]);
    setFoodTab('current');
    setFoodsModalOpen(true);
    loadCategoryFoods(category.maDanhMuc);
    loadAllFoods();
  };

  const handleAssignFood = async (food: any) => {
    if (!selectedCategory) return;
    setAssigningId(food.maMonAn);
    try {
      await apiFetch('/admin/categories/assign-food', {
        method: 'POST',
        body: JSON.stringify({ maMonAn: food.maMonAn, maDanhMuc: selectedCategory.maDanhMuc }),
      });
      // Update local state
      food.maDanhMuc = selectedCategory.maDanhMuc;
      await loadCategoryFoods(selectedCategory.maDanhMuc);
    } catch (err: any) {
      showError('Lỗi Phân Món', err.message || 'Không thể phân món vào danh mục');
    } finally {
      setAssigningId(null);
    }
  };

  const handleRemoveFood = async (foodId: number) => {
    try {
      await apiFetch(`/admin/categories/foods/${foodId}`, { method: 'DELETE' });
      if (selectedCategory) {
        await loadCategoryFoods(selectedCategory.maDanhMuc);
      }
      setAllFoods((prev) =>
        prev.map((f) => (f.maMonAn === foodId ? { ...f, maDanhMuc: null } : f))
      );
    } catch (err: any) {
      showError('Lỗi Gỡ Món', err.message || 'Không thể gỡ món khỏi danh mục');
    }
  };

  const filteredCategories = categories.filter((c: any) =>
    matchesVietnameseSearch(c.tenDanhMuc, search)
  );

  const filteredAllFoods = allFoods.filter((f: any) => {
    if (!assignSearch.trim()) return true;
    const storeName = getStoreNameForFood(f);
    return matchesVietnameseSearch(f.tenMonAn, assignSearch) || matchesVietnameseSearch(storeName, assignSearch);
  });

  return (
    <div>
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 className="page-title">Thực Đơn Tuyển Chọn & Danh Mục</h1>
          <p className="page-subtitle">Quản lý hình ảnh đại diện danh mục tuyển chọn, xem chi tiết món ăn và phân món từ các nhà hàng vào danh mục.</p>
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
                <th style={{ width: '90px' }}>Hình Ảnh</th>
                <th style={{ width: '80px' }}>ID</th>
                <th>Tên Danh Mục Tuyển Chọn</th>
                <th style={{ width: '220px', textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {filteredCategories.map((c: any, index: number) => (
                <tr key={c.maDanhMuc}>
                  <td style={{ textAlign: 'center', fontWeight: 600, color: '#64748b' }}>{index + 1}</td>
                  <td>
                    {c.hinhAnh ? (
                      <img
                        src={getImageUrl(c.hinhAnh, DEFAULT_IMAGE_PLACEHOLDER)}
                        alt={c.tenDanhMuc}
                        onError={handleImageError}
                        style={{ width: '48px', height: '48px', borderRadius: '10px', objectFit: 'cover', border: '1px solid #e2e8f0' }}
                      />
                    ) : (
                      <div style={{ width: '48px', height: '48px', borderRadius: '10px', background: '#fff7ed', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fc6011' }}>
                        <Utensils size={20} />
                      </div>
                    )}
                  </td>
                  <td style={{ fontWeight: 700 }}>#{c.maDanhMuc}</td>
                  <td style={{ fontWeight: 700, color: '#0f172a', fontSize: '15px' }}>{c.tenDanhMuc}</td>
                  <td style={{ textAlign: 'center' }}>
                    <div style={{ display: 'flex', justifyContent: 'center', gap: '8px' }}>
                      <button
                        className="btn btn-outline btn-sm"
                        onClick={() => handleOpenFoodsModal(c)}
                        style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', padding: '5px 10px' }}
                      >
                        <Eye size={14} color="#0284c7" /> Phân Món ({c.soLuongMon || 'Xem'})
                      </button>
                      <button
                        className="btn btn-outline btn-sm"
                        onClick={() => handleOpenEdit(c)}
                        style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', padding: '5px 10px' }}
                      >
                        <Edit2 size={14} color="#fc6011" /> Sửa
                      </button>
                      <button
                        className="btn btn-outline btn-sm"
                        onClick={() => {
                          setDeletingCategory(c);
                          setDeleteModalOpen(true);
                        }}
                        style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '12px', padding: '5px 10px', color: '#ef4444' }}
                      >
                        <Trash2 size={14} /> Xóa
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
      <Modal isOpen={createModalOpen} onClose={() => setCreateModalOpen(false)} title="Thêm Danh Mục Tuyển Chọn Mới">
        <form onSubmit={handleCreate}>
          <div className="form-group" style={{ marginBottom: '14px' }}>
            <label className="form-label">Tên Danh Mục <span style={{ color: '#ef4444' }}>*</span></label>
            <input
              type="text"
              className="form-control"
              placeholder="Ví dụ: Phở Nóng, Trà Sữa / Cà Phê, Món Giảm 50%..."
              value={newTenDanhMuc}
              onChange={(e) => setNewTenDanhMuc(e.target.value)}
              required
            />
          </div>
          <div className="form-group" style={{ marginBottom: '14px' }}>
            <ImageCropUpload
              label="Hình Ảnh Đại Diện Danh Mục (Icon / Ảnh vuông)"
              value={newHinhAnh}
              onChange={(url) => setNewHinhAnh(url)}
              aspectRatio={1}
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
          <div className="form-group" style={{ marginBottom: '14px' }}>
            <label className="form-label">Tên Danh Mục <span style={{ color: '#ef4444' }}>*</span></label>
            <input
              type="text"
              className="form-control"
              placeholder="Nhập tên danh mục..."
              value={editTenDanhMuc}
              onChange={(e) => setEditTenDanhMuc(e.target.value)}
              required
            />
          </div>
          <div className="form-group" style={{ marginBottom: '14px' }}>
            <ImageCropUpload
              label="Hình Ảnh Đại Diện Danh Mục"
              value={editHinhAnh}
              onChange={(url) => setEditHinhAnh(url)}
              aspectRatio={1}
            />
          </div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setEditModalOpen(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">Lưu Thay Đổi</button>
          </div>
        </form>
      </Modal>

      {/* Modal 3: View & Assign Foods in Category */}
      <Modal
        isOpen={foodsModalOpen}
        onClose={() => setFoodsModalOpen(false)}
        title={`Quản Lý Món Ăn & Phân Món: "${selectedCategory?.tenDanhMuc || ''}"`}
        maxWidth="950px"
      >
        <div style={{ padding: '4px' }}>
          {/* Sub tabs */}
          <div style={{ display: 'flex', gap: '10px', borderBottom: '2px solid #e2e8f0', marginBottom: '16px' }}>
            <button
              onClick={() => setFoodTab('current')}
              style={{
                padding: '8px 16px',
                fontWeight: 700,
                fontSize: '14px',
                border: 'none',
                background: 'none',
                cursor: 'pointer',
                borderBottom: foodTab === 'current' ? '3px solid #fc6011' : '3px solid transparent',
                color: foodTab === 'current' ? '#fc6011' : '#64748b',
              }}
            >
              Món Đang Thuộc Danh Mục ({categoryFoods.length})
            </button>
            <button
              onClick={() => setFoodTab('assign')}
              style={{
                padding: '8px 16px',
                fontWeight: 700,
                fontSize: '14px',
                border: 'none',
                background: 'none',
                cursor: 'pointer',
                borderBottom: foodTab === 'assign' ? '3px solid #fc6011' : '3px solid transparent',
                color: foodTab === 'assign' ? '#fc6011' : '#64748b',
              }}
            >
              + Phân Thêm Món Vào Danh Mục Này
            </button>
          </div>

          {foodTab === 'current' ? (
            <div>
              {loadingFoods ? (
                <div style={{ textAlign: 'center', padding: '50px' }}><div className="loading-spinner" /></div>
              ) : categoryFoods.length === 0 ? (
                <div className="empty-state" style={{ padding: '40px', textAlign: 'center' }}>
                  <div style={{ marginBottom: '12px', color: '#64748b' }}>Chưa có món ăn nào thuộc danh mục này.</div>
                  <button className="btn btn-primary btn-sm" onClick={() => setFoodTab('assign')}>
                    + Bấm vào đây để chọn món từ các quán phân vào danh mục này
                  </button>
                </div>
              ) : (
                <div style={{ maxHeight: '450px', overflowY: 'auto' }}>
                  <table className="data-table" style={{ width: '100%' }}>
                    <thead>
                      <tr>
                        <th style={{ width: '70px' }}>Mã Món</th>
                        <th style={{ width: '70px' }}>Hình Ảnh</th>
                        <th>Tên Món Ăn</th>
                        <th>Nhà Hàng Cung Cấp</th>
                        <th style={{ width: '120px' }}>Giá Bán</th>
                        <th style={{ width: '110px', textAlign: 'center' }}>Thao Tác</th>
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
                            <span className="badge badge-warning" style={{ fontWeight: 700, fontSize: '12px', padding: '4px 8px' }}>
                              <Store size={13} style={{ display: 'inline-block', verticalAlign: '-1px', marginRight: '4px' }} /> {getStoreNameForFood(f)}
                            </span>
                          </td>
                          <td style={{ fontWeight: 700, color: '#fc6011', fontSize: '14px' }}>{formatVND(f.giaMonAn)}</td>
                          <td style={{ textAlign: 'center' }}>
                            <button
                              className="btn btn-outline btn-sm"
                              onClick={() => handleRemoveFood(f.maMonAn)}
                              style={{ color: '#ef4444', fontSize: '12px', padding: '4px 8px' }}
                              title="Gỡ món khỏi danh mục này"
                            >
                              Gỡ Món
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          ) : (
            <div>
              <div style={{ display: 'flex', gap: '10px', marginBottom: '14px' }}>
                <div className="search-input-group" style={{ flex: 1 }}>
                  <Search size={16} />
                  <input
                    type="text"
                    placeholder="Tìm món ăn hoặc tên quán để phân vào danh mục..."
                    value={assignSearch}
                    onChange={(e) => setAssignSearch(e.target.value)}
                  />
                </div>
              </div>

              {loadingAllFoods ? (
                <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
              ) : (
                <div style={{ maxHeight: '420px', overflowY: 'auto' }}>
                  <table className="data-table" style={{ width: '100%' }}>
                    <thead>
                      <tr>
                        <th style={{ width: '60px' }}>Ảnh</th>
                        <th>Tên Món Ăn</th>
                        <th>Nhà Hàng</th>
                        <th style={{ width: '110px' }}>Giá</th>
                        <th style={{ width: '130px', textAlign: 'center' }}>Hành Động</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredAllFoods.slice(0, 100).map((f: any) => {
                        const isCurrent = Number(f.maDanhMuc) === Number(selectedCategory?.maDanhMuc);
                        return (
                          <tr key={f.maMonAn} style={{ background: isCurrent ? '#f0fdf4' : 'transparent' }}>
                            <td>
                              <img
                                src={getImageUrl(f.img, DEFAULT_IMAGE_PLACEHOLDER)}
                                alt={f.tenMonAn}
                                onError={handleImageError}
                                style={{ width: '40px', height: '40px', borderRadius: '8px', objectFit: 'cover' }}
                              />
                            </td>
                            <td style={{ fontWeight: 700, color: '#0f172a' }}>{f.tenMonAn}</td>
                            <td>
                              <span style={{ fontSize: '12px', color: '#475569', fontWeight: 600 }}>
                                <Store size={13} style={{ display: 'inline-block', verticalAlign: '-1px', marginRight: '4px' }} /> {getStoreNameForFood(f)}
                              </span>
                            </td>
                            <td style={{ fontWeight: 700, color: '#fc6011' }}>{formatVND(f.giaMonAn)}</td>
                            <td style={{ textAlign: 'center' }}>
                              {isCurrent ? (
                                <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', color: '#16a34a', fontWeight: 700, fontSize: '12px' }}>
                                  <Check size={14} /> Đang thuộc
                                </span>
                              ) : (
                                <button
                                  className="btn btn-primary btn-sm"
                                  onClick={() => handleAssignFood(f)}
                                  disabled={assigningId === f.maMonAn}
                                  style={{ fontSize: '12px', padding: '4px 10px' }}
                                >
                                  {assigningId === f.maMonAn ? 'Đang thêm...' : '+ Phân Vào Đây'}
                                </button>
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </div>
      </Modal>

      {/* Modal 4: Delete Category Confirmation */}
      <Modal isOpen={deleteModalOpen} onClose={() => setDeleteModalOpen(false)} title="Xác Nhận Xóa Danh Mục">
        <div style={{ textAlign: 'center', padding: '10px 0' }}>
          <div style={{ fontSize: '15px', color: '#1e293b', marginBottom: '20px' }}>
            Bạn có chắc chắn muốn xóa danh mục tuyển chọn <b>"{deletingCategory?.tenDanhMuc}"</b> không?
            <div style={{ fontSize: '13px', color: '#64748b', marginTop: '8px' }}>
              (Các món ăn thuộc danh mục này sẽ không bị xóa mà chỉ được gỡ phân loại)
            </div>
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: '12px' }}>
            <button className="btn btn-outline" onClick={() => setDeleteModalOpen(false)}>Hủy</button>
            <button className="btn btn-danger" onClick={handleDeleteCategory} style={{ background: '#ef4444', color: '#fff' }}>
              Xác Nhận Xóa
            </button>
          </div>
        </div>
      </Modal>

      {/* Modal 5: Notification / Error Dialog Modal */}
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
