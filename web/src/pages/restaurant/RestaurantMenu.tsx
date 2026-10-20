import React, { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Plus, Edit2, Trash2, UtensilsCrossed, Star, X, ChevronLeft, ChevronRight, Search, Sparkles } from 'lucide-react';
import { Modal } from '../../components/Modal';
import { NotificationModal } from '../../components/NotificationModal';
import { ImageCropUpload } from '../../components/ImageCropUpload';
import { AnimatedCounter } from '../../components/AnimatedCounter';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../utils/imageUtils';
import { suggestCategoryForDish, AISuggestionResult } from '../../utils/aiCategorySuggester';

export const RestaurantMenu: React.FC = () => {
  const [foods, setFoods] = useState<any[]>([]);
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingFood, setEditingFood] = useState<any>(null);
  const [deleteModal, setDeleteModal] = useState<{ isOpen: boolean; food: any | null }>({
    isOpen: false,
    food: null,
  });
  const [searchInput, setSearchInput] = useState('');

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

  // Reviews Modal State
  const [reviewsModal, setReviewsModal] = useState<{
    isOpen: boolean;
    foodName: string;
    maMonAn: number | null;
  }>({ isOpen: false, foodName: '', maMonAn: null });
  const [reviewsData, setReviewsData] = useState<any>(null);
  const [reviewsLoading, setReviewsLoading] = useState(false);
  const [reviewsPage, setReviewsPage] = useState(1);

  const openReviews = async (food: any, page = 1) => {
    setReviewsModal({ isOpen: true, foodName: food.tenMonAn, maMonAn: food.maMonAn });
    setReviewsPage(page);
    setReviewsLoading(true);
    setReviewsData(null);
    try {
      const res = await apiFetch<any>(`/restaurant/menu/${food.maMonAn}/reviews?page=${page}&limit=8`);
      setReviewsData(res.data);
    } catch {
      setReviewsData(null);
    } finally {
      setReviewsLoading(false);
    }
  };

  const changePage = async (maMonAn: number, foodName: string, newPage: number) => {
    setReviewsPage(newPage);
    setReviewsLoading(true);
    try {
      const res = await apiFetch<any>(`/restaurant/menu/${maMonAn}/reviews?page=${newPage}&limit=8`);
      setReviewsData(res.data);
    } catch {
      // keep existing data
    } finally {
      setReviewsLoading(false);
    }
  };


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
    setForm({ tenMonAn: '', maDanhMuc: defaultCat, giaMonAn: '', soLuongMon: '100', trangThaiMon: 'DANG_BAN', img: '' });
    setModalOpen(true);
  };

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

  const [aiSuggestion, setAiSuggestion] = useState<AISuggestionResult | null>(null);
  const [creatingCategory, setCreatingCategory] = useState(false);

  // Auto-detect category via AI whenever tenMonAn changes
  useEffect(() => {
    if (form.tenMonAn && form.tenMonAn.trim().length >= 2) {
      const suggestion = suggestCategoryForDish(form.tenMonAn, categories);
      setAiSuggestion(suggestion);
    } else {
      setAiSuggestion(null);
    }
  }, [form.tenMonAn, categories]);

  const handleApplyAISuggestion = () => {
    if (!aiSuggestion) return;
    if (aiSuggestion.isExistingCategory && aiSuggestion.suggestedCategoryId) {
      setForm((prev) => ({ ...prev, maDanhMuc: String(aiSuggestion.suggestedCategoryId) }));
    }
  };

  const handleCreateAndApplyCategory = async (catName: string) => {
    try {
      setCreatingCategory(true);
      const res = await apiFetch<any>('/restaurant/categories', {
        method: 'POST',
        body: JSON.stringify({ tenDanhMuc: catName }),
      });
      const newCat = res.data;
      if (newCat) {
        setCategories((prev) => {
          if (prev.some((c) => Number(c.maDanhMuc) === Number(newCat.maDanhMuc))) return prev;
          return [...prev, newCat];
        });
        setForm((prev) => ({ ...prev, maDanhMuc: String(newCat.maDanhMuc) }));
        setAiSuggestion(null);
        showNotify('success', 'Tạo Danh Mục Thành Công', `Đã thêm loại món "${newCat.tenDanhMuc}" và tự động chọn cho món ăn!`);
      }
    } catch (err: any) {
      showNotify('error', 'Lỗi Tạo Danh Mục', err.message || 'Không thể tạo danh mục mới');
    } finally {
      setCreatingCategory(false);
    }
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
        trangThaiMon: form.trangThaiMon,
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
      showNotify('success', editingFood ? 'Cập Nhật Thành Công' : 'Thêm Món Thành Công', editingFood ? 'Đã cập nhật món ăn!' : 'Đã thêm món mới vào thực đơn!');
    } catch (err: any) {
      showNotify('error', 'Lỗi Lưu Món', err.message || 'Lỗi lưu món ăn');
    }
  };

  const handleDeleteFood = async () => {
    if (!deleteModal.food) return;
    try {
      await apiFetch(`/restaurant/menu/${deleteModal.food.maMonAn}`, {
        method: 'DELETE',
      });
      const deletedName = deleteModal.food.tenMonAn;
      setDeleteModal({ isOpen: false, food: null });
      fetchData();
      showNotify('success', 'Xóa Món Thành Công', `Đã xóa món "${deletedName}" khỏi thực đơn quán!`);
    } catch (err: any) {
      showNotify('error', 'Lỗi Xóa Món', err.message || 'Không thể xóa món ăn');
    }
  };

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  // Sort: out-of-stock (qty=0) to bottom; within each group, keep original order
  const sortedFoods = useMemo(() => {
    const q = searchInput.trim().toLowerCase();
    const filtered = q
      ? foods.filter((f) => f.tenMonAn?.toLowerCase().includes(q))
      : foods;
    const inStock = filtered.filter((f) => (Number(f.soLuongMon) ?? 1) > 0);
    const outOfStock = filtered.filter((f) => (Number(f.soLuongMon) ?? 1) <= 0);
    return [...inStock, ...outOfStock];
  }, [foods, searchInput]);

  return (
    <div>
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 className="page-title">Quản Lý Thực Đơn Nhà Hàng</h1>
          <p className="page-subtitle">Thêm, sửa, chọn loại món ăn, đổi giá và hình ảnh của quán</p>
        </div>
        
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{
            background: 'linear-gradient(135deg, #fff5f0 0%, #ffede5 100%)',
            border: '1px solid #ffd8cc',
            padding: '9px 18px',
            borderRadius: '12px',
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            boxShadow: '0 2px 8px rgba(252, 96, 17, 0.08)'
          }}>
            <div style={{
              width: '38px',
              height: '38px',
              borderRadius: '10px',
              backgroundColor: '#fc6011',
              color: '#fff',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}>
              <UtensilsCrossed size={18} />
            </div>
            <div>
              <div style={{ fontSize: '11px', color: '#64748b', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                Tổng Số Lượng Món
              </div>
              <div style={{ fontSize: '20px', fontWeight: 800, color: '#fc6011', lineHeight: '1.2' }}>
                <AnimatedCounter value={foods.length} /> <span style={{ fontSize: '13px', fontWeight: 600 }}>món</span>
              </div>
            </div>
          </div>

          <button className="btn btn-primary" onClick={handleOpenAdd}>
            <Plus size={16} /> Thêm Món Ăn Mới
          </button>
        </div>
      </div>

      {/* Search bar */}
      <div style={{ marginBottom: '12px' }}>
        <div style={{ position: 'relative', maxWidth: '360px' }}>
          <Search size={15} color="#94a3b8" style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none' }} />
          <input
            type="text"
            className="form-control"
            placeholder="Tìm tên món ăn..."
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            style={{ paddingLeft: '36px', paddingRight: searchInput ? '34px' : '12px', fontSize: '13px', borderRadius: '10px', background: '#f8fafc' }}
          />
          {searchInput && (
            <button
              type="button"
              onClick={() => setSearchInput('')}
              style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', background: 'none', border: 'none', cursor: 'pointer', color: '#94a3b8', display: 'flex', alignItems: 'center' }}
            >
              <X size={13} />
            </button>
          )}
        </div>
      </div>

      <div className="card-table">
        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : sortedFoods.length === 0 ? (
          <div className="empty-state">
            {searchInput ? `Không tìm thấy món nào khớp "${searchInput}"` : 'Chưa có món ăn nào trong thực đơn của quán'}
          </div>
        ) : (
          <table className="data-table">

            <thead>
              <tr>
                <th style={{ width: '50px', textAlign: 'center' }}>STT</th>
                <th>Hình Ảnh</th>
                <th>Tên Món Ăn</th>
                <th>Giá Bán</th>
                <th>Số Lượng Phục Vụ</th>
                <th style={{ textAlign: 'center' }}>Đánh Giá</th>
                <th>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {sortedFoods.map((f, idx: number) => {
                const qty = Number(f.soLuongMon ?? 1);
                const outOfStock = qty <= 0;
                const score = Number(f.diemDanhGiaTB || 0);
                const fullStars = Math.floor(score);
                const hasHalf = score - fullStars >= 0.5;
                const emptyStars = 5 - fullStars - (hasHalf ? 1 : 0);

                return (
                  <tr
                    key={f.maMonAn}
                    style={outOfStock ? { background: '#f8f8f8', opacity: 0.72 } : undefined}
                  >
                    <td style={{ textAlign: 'center', fontWeight: 600, color: outOfStock ? '#b0b8c1' : '#64748b' }}>{idx + 1}</td>
                    <td>
                      <div style={{ position: 'relative', display: 'inline-block' }}>
                        <img
                          src={getImageUrl(f.img, DEFAULT_IMAGE_PLACEHOLDER)}
                          alt={f.tenMonAn}
                          onError={handleImageError}
                          style={{
                            width: '44px', height: '44px', borderRadius: '8px', objectFit: 'cover',
                            filter: outOfStock ? 'grayscale(70%)' : 'none',
                          }}
                        />
                        {outOfStock && (
                          <div style={{
                            position: 'absolute', inset: 0, borderRadius: '8px',
                            background: 'rgba(0,0,0,0.35)', display: 'flex', alignItems: 'center', justifyContent: 'center',
                          }}>
                            <span style={{ fontSize: '8px', fontWeight: 800, color: '#fff', textTransform: 'uppercase', lineHeight: 1, textAlign: 'center' }}>Hết<br />món</span>
                          </div>
                        )}
                      </div>
                    </td>
                    <td>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontWeight: 700, color: outOfStock ? '#9ca3af' : '#0f172a', textDecoration: outOfStock ? 'line-through' : 'none' }}>
                          {f.tenMonAn}
                        </span>
                        {outOfStock && (
                          <span style={{
                            fontSize: '10px', fontWeight: 700, color: '#ef4444',
                            background: '#fef2f2', border: '1px solid #fecaca',
                            borderRadius: '6px', padding: '2px 7px', whiteSpace: 'nowrap',
                          }}>Hết món</span>
                        )}
                      </div>
                    </td>
                    <td style={{ fontWeight: 700, color: outOfStock ? '#9ca3af' : '#fc6011' }}>{formatVND(f.giaMonAn)}</td>
                    <td>
                      <span className="badge" style={{
                        background: outOfStock ? '#fee2e2' : undefined,
                        color: outOfStock ? '#ef4444' : undefined,
                      }}>
                        {qty} phần
                      </span>
                    </td>
                    <td style={{ textAlign: 'center' }}>
                      <button
                        type="button"
                        onClick={() => openReviews(f)}
                        style={{
                          background: 'none', border: 'none', cursor: 'pointer',
                          padding: '4px 8px', borderRadius: '8px', transition: 'background 0.15s',
                        }}
                        onMouseEnter={e => (e.currentTarget.style.background = '#fef3c7')}
                        onMouseLeave={e => (e.currentTarget.style.background = 'none')}
                        title="Xem chi tiết đánh giá"
                      >
                        {score > 0 ? (
                          <div style={{ display: 'inline-flex', flexDirection: 'column', alignItems: 'center', gap: '2px' }}>
                            <div style={{ display: 'flex', gap: '2px' }}>
                              {Array.from({ length: fullStars }).map((_, i) => (
                                <span key={`full-${i}`} style={{ color: '#f59e0b', fontSize: '15px' }}>★</span>
                              ))}
                              {hasHalf && <span style={{ color: '#f59e0b', fontSize: '15px' }}>⯨</span>}
                              {Array.from({ length: emptyStars }).map((_, i) => (
                                <span key={`empty-${i}`} style={{ color: '#d1d5db', fontSize: '15px' }}>★</span>
                              ))}
                            </div>
                            <span style={{ fontSize: '11px', fontWeight: 700, color: '#f59e0b' }}>
                              {score.toFixed(1)} / 5.0
                            </span>
                          </div>
                        ) : (
                          <span style={{ fontSize: '12px', color: '#94a3b8' }}>Chưa có đánh giá</span>
                        )}
                      </button>
                    </td>
                    <td>
                      <div style={{ display: 'flex', gap: '6px' }}>
                        <button className="btn btn-outline btn-sm" onClick={() => handleOpenEdit(f)} title="Chỉnh sửa món">
                          <Edit2 size={14} /> Sửa
                        </button>
                        <button
                          className="btn btn-outline btn-sm"
                          onClick={() => setDeleteModal({ isOpen: true, food: f })}
                          style={{ color: '#ef4444', borderColor: '#fca5a5' }}
                          title="Xóa món ăn"
                        >
                          <Trash2 size={14} /> Xóa
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      <Modal isOpen={modalOpen} onClose={() => setModalOpen(false)} title={editingFood ? 'Chỉnh Sửa Món Ăn' : 'Thêm Món Ăn Mới'}>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label">Tên Món Ăn</label>
            <input
              type="text"
              className="form-control"
              placeholder="Ví dụ: Hồng Trà Sữa, Cà Phê Trứng Muối, Bánh Croissant..."
              value={form.tenMonAn}
              onChange={(e) => setForm({ ...form, tenMonAn: e.target.value })}
              required
            />
          </div>

          {/* AI Smart Category Suggestion Banner */}
          {aiSuggestion && (
            <div
              style={{
                background: 'linear-gradient(135deg, #fdf4ff 0%, #fae8ff 50%, #f5d0fe 100%)',
                border: '1px solid #e879f9',
                borderRadius: '12px',
                padding: '12px 14px',
                marginBottom: '16px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: '12px',
                boxShadow: '0 2px 8px rgba(217, 70, 239, 0.12)',
              }}
            >
              <div style={{ display: 'flex', gap: '10px', alignItems: 'flex-start' }}>
                <div
                  style={{
                    background: 'linear-gradient(135deg, #d946ef, #a855f7)',
                    borderRadius: '8px',
                    padding: '6px',
                    color: '#fff',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    marginTop: '2px',
                  }}
                >
                  <Sparkles size={16} />
                </div>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                    <span style={{ fontSize: '13px', fontWeight: 800, color: '#86198f' }}>
                      AI Gợi Ý Loại Món:
                    </span>
                    <span
                      style={{
                        background: '#86198f',
                        color: '#ffffff',
                        fontSize: '12px',
                        fontWeight: 700,
                        padding: '2px 8px',
                        borderRadius: '6px',
                      }}
                    >
                      {aiSuggestion.suggestedCategoryName}
                    </span>
                    <span style={{ fontSize: '11px', color: '#a21caf', fontWeight: 700 }}>
                      ⚡ Độ khớp {aiSuggestion.confidence}%
                    </span>
                  </div>
                  <div style={{ fontSize: '12px', color: '#701a75', marginTop: '3px' }}>
                    {aiSuggestion.reason}
                  </div>
                </div>
              </div>

              {aiSuggestion.isExistingCategory ? (
                <button
                  type="button"
                  onClick={handleApplyAISuggestion}
                  disabled={String(form.maDanhMuc) === String(aiSuggestion.suggestedCategoryId)}
                  style={{
                    padding: '6px 12px',
                    borderRadius: '8px',
                    background: String(form.maDanhMuc) === String(aiSuggestion.suggestedCategoryId) ? '#e2e8f0' : 'linear-gradient(135deg, #c026d3, #9333ea)',
                    color: String(form.maDanhMuc) === String(aiSuggestion.suggestedCategoryId) ? '#64748b' : '#ffffff',
                    border: 'none',
                    fontWeight: 700,
                    fontSize: '12px',
                    cursor: String(form.maDanhMuc) === String(aiSuggestion.suggestedCategoryId) ? 'default' : 'pointer',
                    whiteSpace: 'nowrap',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                    transition: 'all 0.2s',
                  }}
                >
                  {String(form.maDanhMuc) === String(aiSuggestion.suggestedCategoryId) ? '✓ Đã chọn' : 'Áp dụng ngay'}
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() => handleCreateAndApplyCategory(aiSuggestion.suggestedCategoryName)}
                  disabled={creatingCategory}
                  style={{
                    padding: '6px 12px',
                    borderRadius: '8px',
                    background: 'linear-gradient(135deg, #059669, #10b981)',
                    color: '#ffffff',
                    border: 'none',
                    fontWeight: 700,
                    fontSize: '12px',
                    cursor: 'pointer',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {creatingCategory ? 'Đang tạo...' : `+ Tạo & Áp dụng`}
                </button>
              )}
            </div>
          )}

          <div className="form-group">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
              <label className="form-label" style={{ marginBottom: 0 }}>Loại Món Ăn (Danh Mục)</label>
              {form.tenMonAn && (
                <button
                  type="button"
                  onClick={() => {
                    const s = suggestCategoryForDish(form.tenMonAn, categories);
                    if (s) {
                      setAiSuggestion(s);
                      if (s.isExistingCategory && s.suggestedCategoryId) {
                        setForm((prev) => ({ ...prev, maDanhMuc: String(s.suggestedCategoryId) }));
                      }
                    }
                  }}
                  style={{
                    border: 'none',
                    background: 'transparent',
                    color: '#a855f7',
                    fontWeight: 700,
                    fontSize: '12px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '4px',
                  }}
                >
                  <Sparkles size={13} /> AI tự động chọn
                </button>
              )}
            </div>
            <select
              className="form-control"
              value={form.maDanhMuc}
              onChange={(e) => setForm({ ...form, maDanhMuc: e.target.value })}
              required
            >
              <option value="">-- Chọn danh mục ({categories.length} loại món sẵn có) --</option>
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
            <button type="submit" className="btn btn-primary">Lưu Món Ăn</button>
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

      {/* ── Modal Xác Nhận Xóa Món Ăn ── */}
      <Modal
        isOpen={deleteModal.isOpen}
        onClose={() => setDeleteModal({ isOpen: false, food: null })}
        title="Xác Nhận Xóa Món Ăn"
      >
        <div style={{ padding: '8px 0' }}>
          <p style={{ fontSize: '14px', color: '#334155', lineHeight: '1.6' }}>
            Bạn có chắc chắn muốn xóa món <b style={{ color: '#0f172a' }}>"{deleteModal.food?.tenMonAn}"</b> khỏi thực đơn quán?
          </p>
          <div style={{ marginTop: '10px', padding: '10px 14px', background: '#fef2f2', border: '1px solid #fee2e2', borderRadius: '8px', fontSize: '12px', color: '#dc2626' }}>
            ⚠️ Thao tác này sẽ xóa vĩnh viễn món ăn và tệp hình ảnh liên quan khỏi máy chủ.
          </div>
          <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setDeleteModal({ isOpen: false, food: null })}>
              Hủy Bỏ
            </button>
            <button
              type="button"
              className="btn btn-primary"
              style={{ background: '#ef4444', borderColor: '#ef4444' }}
              onClick={handleDeleteFood}
            >
              Xác Nhận Xóa
            </button>
          </div>
        </div>
      </Modal>

      {/* ── Food Reviews Modal ─────────────────────────────────────────────── */}
      {reviewsModal.isOpen && (
        <div
          style={{
            position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.45)',
            zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '16px',
          }}
          onClick={(e) => { if (e.target === e.currentTarget) setReviewsModal(m => ({ ...m, isOpen: false })); }}
        >
          <div style={{
            background: '#fff', borderRadius: '16px', width: '100%', maxWidth: '640px',
            maxHeight: '90vh', display: 'flex', flexDirection: 'column', overflow: 'hidden',
            boxShadow: '0 20px 60px rgba(0,0,0,0.2)',
          }}>
            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '20px 24px', borderBottom: '1px solid #e2e8f0' }}>
              <div>
                <h3 style={{ margin: 0, fontSize: '17px', fontWeight: 700, color: '#0f172a' }}>Đánh Giá Món Ăn</h3>
                <p style={{ margin: '2px 0 0', fontSize: '13px', color: '#64748b' }}>{reviewsModal.foodName}</p>
              </div>
              <button
                onClick={() => setReviewsModal(m => ({ ...m, isOpen: false }))}
                style={{ background: '#f1f5f9', border: 'none', borderRadius: '50%', width: '34px', height: '34px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center' }}
              >
                <X size={16} color="#64748b" />
              </button>
            </div>

            {/* Body */}
            <div style={{ overflowY: 'auto', flex: 1, padding: '20px 24px' }}>
              {reviewsLoading ? (
                <div style={{ textAlign: 'center', padding: '40px', color: '#94a3b8' }}>Đang tải đánh giá...</div>
              ) : !reviewsData ? (
                <div style={{ textAlign: 'center', padding: '40px', color: '#94a3b8' }}>Không thể tải đánh giá.</div>
              ) : (
                <>
                  {/* Summary */}
                  <div style={{ display: 'flex', gap: '24px', alignItems: 'center', padding: '16px', background: '#fef9ee', borderRadius: '12px', marginBottom: '20px' }}>
                    <div style={{ textAlign: 'center', minWidth: '70px' }}>
                      <div style={{ fontSize: '36px', fontWeight: 800, color: '#f59e0b', lineHeight: 1 }}>
                        {reviewsData.summary.avg > 0 ? reviewsData.summary.avg.toFixed(1) : '—'}
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'center', gap: '2px', marginTop: '4px' }}>
                        {[1,2,3,4,5].map(s => (
                          <span key={s} style={{ color: s <= Math.round(reviewsData.summary.avg) ? '#f59e0b' : '#d1d5db', fontSize: '14px' }}>★</span>
                        ))}
                      </div>
                      <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '4px' }}>{reviewsData.summary.total} đánh giá</div>
                    </div>
                    <div style={{ flex: 1 }}>
                      {[5,4,3,2,1].map(star => {
                        const count = reviewsData.summary.breakdown[star] || 0;
                        const pct = reviewsData.summary.total > 0 ? (count / reviewsData.summary.total) * 100 : 0;
                        return (
                          <div key={star} style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '5px' }}>
                            <span style={{ fontSize: '12px', color: '#64748b', width: '12px', textAlign: 'right' }}>{star}</span>
                            <span style={{ color: '#f59e0b', fontSize: '12px' }}>★</span>
                            <div style={{ flex: 1, background: '#e2e8f0', borderRadius: '4px', height: '8px', overflow: 'hidden' }}>
                              <div style={{ width: `${pct}%`, background: '#f59e0b', height: '100%', borderRadius: '4px', transition: 'width 0.4s' }} />
                            </div>
                            <span style={{ fontSize: '11px', color: '#94a3b8', width: '24px' }}>{count}</span>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  {/* Review list */}
                  {reviewsData.reviews.length === 0 ? (
                    <div style={{ textAlign: 'center', padding: '32px', color: '#94a3b8' }}>
                      <Star size={32} color="#d1d5db" style={{ marginBottom: '8px' }} />
                      <p style={{ margin: 0 }}>Chưa có đánh giá nào cho món này.</p>
                    </div>
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                      {reviewsData.reviews.map((rv: any) => (
                        <div key={rv.maDanhGia} style={{ border: '1px solid #e2e8f0', borderRadius: '10px', padding: '14px' }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                              <div style={{
                                width: '36px', height: '36px', borderRadius: '50%',
                                background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center',
                                fontSize: '15px', fontWeight: 700, color: '#fc6011', overflow: 'hidden', flexShrink: 0,
                              }}>
                                {rv.customerAvatar
                                  ? <img src={rv.customerAvatar} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                                  : rv.customerName.charAt(0).toUpperCase()}
                              </div>
                              <div>
                                <div style={{ fontWeight: 700, fontSize: '13px', color: '#0f172a' }}>{rv.customerName}</div>
                                <div style={{ display: 'flex', gap: '2px' }}>
                                  {[1,2,3,4,5].map(s => (
                                    <span key={s} style={{ color: s <= rv.soLuongSao ? '#f59e0b' : '#d1d5db', fontSize: '13px' }}>★</span>
                                  ))}
                                </div>
                              </div>
                            </div>
                            <span style={{ fontSize: '11px', color: '#94a3b8' }}>
                              {new Date(rv.ngayNhanXet).toLocaleDateString('vi-VN')}
                            </span>
                          </div>
                          {rv.nhanXet && (
                            <p style={{ margin: '0 0 8px', fontSize: '13px', color: '#334155', lineHeight: 1.5 }}>{rv.nhanXet}</p>
                          )}
                          {rv.hinhAnh && (
                            <img src={getImageUrl(rv.hinhAnh)} alt="" style={{ maxWidth: '120px', borderRadius: '8px', marginBottom: '8px' }} onError={handleImageError} />
                          )}
                          {rv.phanHoi && (
                            <div style={{ background: '#f8fafc', border: '1px solid #e2e8f0', borderRadius: '8px', padding: '10px 12px', marginTop: '8px' }}>
                              <div style={{ fontSize: '11px', fontWeight: 700, color: '#fc6011', marginBottom: '4px' }}>Phản hồi của quán:</div>
                              <p style={{ margin: 0, fontSize: '13px', color: '#475569' }}>{rv.phanHoi}</p>
                            </div>
                          )}
                        </div>
                      ))}
                    </div>
                  )}

                  {/* Pagination */}
                  {reviewsData.totalPages > 1 && (
                    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '12px', marginTop: '20px' }}>
                      <button
                        onClick={() => changePage(reviewsModal.maMonAn!, reviewsModal.foodName, reviewsPage - 1)}
                        disabled={reviewsPage <= 1}
                        style={{ background: '#f1f5f9', border: 'none', borderRadius: '8px', padding: '6px 12px', cursor: reviewsPage <= 1 ? 'not-allowed' : 'pointer', opacity: reviewsPage <= 1 ? 0.5 : 1 }}
                      >
                        <ChevronLeft size={16} />
                      </button>
                      <span style={{ fontSize: '13px', color: '#64748b' }}>{reviewsPage} / {reviewsData.totalPages}</span>
                      <button
                        onClick={() => changePage(reviewsModal.maMonAn!, reviewsModal.foodName, reviewsPage + 1)}
                        disabled={reviewsPage >= reviewsData.totalPages}
                        style={{ background: '#f1f5f9', border: 'none', borderRadius: '8px', padding: '6px 12px', cursor: reviewsPage >= reviewsData.totalPages ? 'not-allowed' : 'pointer', opacity: reviewsPage >= reviewsData.totalPages ? 0.5 : 1 }}
                      >
                        <ChevronRight size={16} />
                      </button>
                    </div>
                  )}
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
