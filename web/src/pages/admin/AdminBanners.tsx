import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { Plus, Edit2, Trash2, Sparkles, ChevronLeft, ChevronRight, CheckCircle2, XCircle, LayoutTemplate, Image as ImageIcon } from 'lucide-react';
import { Modal } from '../../components/Modal';
import { NotificationModal } from '../../components/NotificationModal';
import { ImageCropUpload } from '../../components/ImageCropUpload';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../utils/imageUtils';

interface Banner {
  maBanner: number;
  tieuDe: string;
  phuDe?: string;
  hinhAnh: string;
  lienKet?: string;
  mauSac: string;
  thuTu: number;
  trangThai: string;
  loaiBanner?: string;
  ngayTao: string;
}

const PRESET_COLORS = [
  { name: 'Cam Năng Động (Mặc định)', color: '#FC6011', gradient: 'linear-gradient(135deg, #FC6011 0%, #10B981 100%)' },
  { name: 'Xanh Lá Tươi Mát', color: '#10B981', gradient: 'linear-gradient(135deg, #059669 0%, #34D399 100%)' },
  { name: 'Xanh Biển Hiện Đại', color: '#2563EB', gradient: 'linear-gradient(135deg, #1D4ED8 0%, #60A5FA 100%)' },
  { name: 'Tím Quyến Rũ', color: '#7C3AED', gradient: 'linear-gradient(135deg, #6D28D9 0%, #A78BFA 100%)' },
  { name: 'Đỏ Nóng Bỏng (Flash Sale)', color: '#EF4444', gradient: 'linear-gradient(135deg, #DC2626 0%, #F87171 100%)' },
  { name: 'Vàng Hoàng Kim', color: '#D97706', gradient: 'linear-gradient(135deg, #B45309 0%, #FBBF24 100%)' },
];

export const AdminBanners: React.FC = () => {
  const [banners, setBanners] = useState<Banner[]>([]);
  const [loading, setLoading] = useState(true);
  const [previewIndex, setPreviewIndex] = useState(0);

  // Modal create/edit
  const [modalOpen, setModalOpen] = useState(false);
  const [editingBanner, setEditingBanner] = useState<Banner | null>(null);

  // Form fields
  const [tieuDe, setTieuDe] = useState('');
  const [phuDe, setPhuDe] = useState('');
  const [hinhAnh, setHinhAnh] = useState('');
  const [mauSac, setMauSac] = useState('#FC6011');
  const [thuTu, setThuTu] = useState<number>(1);
  const [trangThai, setTrangThai] = useState('HOAT_DONG');
  const [loaiBanner, setLoaiBanner] = useState<'TRAN_VIEN' | 'THE_CHUAN'>('TRAN_VIEN');
  const [aspectRatio, setAspectRatio] = useState<number>(2.4);
  const [lienKet, setLienKet] = useState('');

  // Delete modal
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [deletingBanner, setDeletingBanner] = useState<Banner | null>(null);

  // Notification modal
  const [notice, setNotice] = useState<{ isOpen: boolean; title: string; message: string; type?: 'success' | 'error' | 'warning' }>({
    isOpen: false,
    title: '',
    message: '',
  });

  const fetchBanners = async () => {
    setLoading(true);
    try {
      const res = await apiFetch<any>('/admin/banners');
      setBanners(res.data || []);
    } catch (err: any) {
      console.error(err);
      setNotice({ isOpen: true, title: 'Lỗi Tải Banner', message: err.message || 'Không thể tải danh sách banner', type: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBanners();
  }, []);

  // Auto-slide live preview
  useEffect(() => {
    const activeBanners = banners.filter((b) => b.trangThai === 'HOAT_DONG');
    if (activeBanners.length <= 1) return;
    const interval = setInterval(() => {
      setPreviewIndex((prev) => (prev + 1) % activeBanners.length);
    }, 4000);
    return () => clearInterval(interval);
  }, [banners]);

  const handleOpenCreate = () => {
    setEditingBanner(null);
    setTieuDe('');
    setPhuDe('');
    setHinhAnh('');
    setMauSac('#FC6011');
    setThuTu(banners.length + 1);
    setTrangThai('HOAT_DONG');
    setLoaiBanner('TRAN_VIEN');
    setAspectRatio(2.4);
    setLienKet('');
    setModalOpen(true);
  };

  const handleOpenEdit = (b: Banner) => {
    setEditingBanner(b);
    setTieuDe(b.tieuDe || '');
    setPhuDe(b.phuDe || '');
    setHinhAnh(b.hinhAnh || '');
    setMauSac(b.mauSac || '#FC6011');
    setThuTu(b.thuTu || 1);
    setTrangThai(b.trangThai || 'HOAT_DONG');
    const isFullCover = (b.loaiBanner || 'TRAN_VIEN') === 'TRAN_VIEN';
    setLoaiBanner(isFullCover ? 'TRAN_VIEN' : 'THE_CHUAN');
    setAspectRatio(isFullCover ? 2.4 : 1.0);
    setLienKet(b.lienKet || '');
    setModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!hinhAnh.trim()) {
      setNotice({ isOpen: true, title: 'Thiếu Thông Tin', message: 'Vui lòng tải lên hoặc dán đường dẫn hình ảnh cho banner', type: 'warning' });
      return;
    }

    const payload = {
      tieuDe: tieuDe.trim() || 'Banner Quảng Cáo',
      phuDe: phuDe.trim(),
      hinhAnh: hinhAnh.trim(),
      mauSac,
      thuTu: Number(thuTu) || 0,
      trangThai,
      loaiBanner,
      lienKet: lienKet.trim(),
    };

    try {
      if (editingBanner) {
        await apiFetch(`/admin/banners/${editingBanner.maBanner}`, {
          method: 'PUT',
          body: JSON.stringify(payload),
        });
        setNotice({ isOpen: true, title: 'Thành Công', message: 'Cập nhật banner thành công!', type: 'success' });
      } else {
        await apiFetch('/admin/banners', {
          method: 'POST',
          body: JSON.stringify(payload),
        });
        setNotice({ isOpen: true, title: 'Thành Công', message: 'Tạo banner mới thành công!', type: 'success' });
      }
      setModalOpen(false);
      fetchBanners();
    } catch (err: any) {
      setNotice({ isOpen: true, title: 'Lỗi', message: err.message || 'Không thể lưu banner', type: 'error' });
    }
  };

  const handleDelete = async () => {
    if (!deletingBanner) return;
    try {
      await apiFetch(`/admin/banners/${deletingBanner.maBanner}`, { method: 'DELETE' });
      setDeleteConfirmOpen(false);
      setNotice({ isOpen: true, title: 'Đã Xóa', message: 'Đã xóa banner thành công', type: 'success' });
      fetchBanners();
    } catch (err: any) {
      setNotice({ isOpen: true, title: 'Lỗi', message: err.message || 'Không thể xóa banner', type: 'error' });
    }
  };

  const handleToggleStatus = async (b: Banner) => {
    const nextStatus = b.trangThai === 'HOAT_DONG' ? 'TAM_DUNG' : 'HOAT_DONG';
    try {
      await apiFetch(`/admin/banners/${b.maBanner}`, {
        method: 'PUT',
        body: JSON.stringify({ trangThai: nextStatus }),
      });
      fetchBanners();
    } catch (err: any) {
      setNotice({ isOpen: true, title: 'Lỗi', message: err.message || 'Không thể cập nhật trạng thái', type: 'error' });
    }
  };

  const activeBanners = banners.filter((b) => b.trangThai === 'HOAT_DONG');
  const currentPreviewBanner = activeBanners[previewIndex] || activeBanners[0];
  const isPreviewFullCover = (currentPreviewBanner?.loaiBanner || 'TRAN_VIEN') === 'TRAN_VIEN';

  return (
    <div>
      <div className="page-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h1 className="page-title">Quản Lý Giao Diện Banner Quảng Cáo</h1>
          <p className="page-subtitle">Tải ảnh poster quảng cáo tràn viền chuẩn khung App (2.4:1) hoặc thẻ ưu đãi. Tự động chuyển trang và vuốt ngang.</p>
        </div>
        <button className="btn btn-primary" onClick={handleOpenCreate}>
          <Plus size={16} /> Thêm Banner Mới
        </button>
      </div>

      {/* Live Preview Carousel on Mobile Mockup */}
      {activeBanners.length > 0 && currentPreviewBanner && (
        <div style={{ background: '#fff', borderRadius: '16px', padding: '20px', marginBottom: '24px', boxShadow: '0 4px 12px rgba(0,0,0,0.05)' }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '14px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 700, color: '#1e293b' }}>
              <Sparkles size={18} color="#FC6011" /> Xem Trước Giao Diện Thực Tế Trên Mobile App ({activeBanners.length} banner đang kích hoạt)
            </div>
            <div style={{ display: 'flex', gap: '6px' }}>
              <button
                className="btn btn-outline btn-sm"
                onClick={() => setPreviewIndex((prev) => (prev === 0 ? activeBanners.length - 1 : prev - 1))}
              >
                <ChevronLeft size={16} />
              </button>
              <button
                className="btn btn-outline btn-sm"
                onClick={() => setPreviewIndex((prev) => (prev + 1) % activeBanners.length)}
              >
                <ChevronRight size={16} />
              </button>
            </div>
          </div>

          {/* Mobile frame mockup */}
          <div
            style={{
              maxWidth: '420px',
              height: '175px',
              margin: '0 auto',
              borderRadius: '20px',
              position: 'relative',
              overflow: 'hidden',
              boxShadow: '0 8px 24px rgba(0,0,0,0.15)',
              transition: 'all 0.4s ease',
            }}
          >
            {isPreviewFullCover ? (
              // Full cover banner (Tràn toàn khung)
              <div style={{ width: '100%', height: '100%', position: 'relative' }}>
                <img
                  src={getImageUrl(currentPreviewBanner.hinhAnh, DEFAULT_IMAGE_PLACEHOLDER)}
                  alt="Banner"
                  onError={handleImageError}
                  style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                />
              </div>
            ) : (
              // Split card banner (Nền gradient + chữ trái + ảnh tròn phải)
              <div
                style={{
                  width: '100%',
                  height: '100%',
                  background: currentPreviewBanner.mauSac.includes('gradient')
                    ? currentPreviewBanner.mauSac
                    : `linear-gradient(135deg, ${currentPreviewBanner.mauSac} 0%, #10B981 100%)`,
                  padding: '20px 24px',
                  color: '#fff',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  boxSizing: 'border-box',
                }}
              >
                <div style={{ zIndex: 2, flex: 1, paddingRight: '12px' }}>
                  {currentPreviewBanner.phuDe && (
                    <div style={{ display: 'inline-block', background: 'rgba(255,255,255,0.25)', padding: '4px 10px', borderRadius: '12px', fontSize: '11px', fontWeight: 800, marginBottom: '8px', backdropFilter: 'blur(4px)' }}>
                      {currentPreviewBanner.phuDe}
                    </div>
                  )}
                  <div style={{ fontSize: '18px', fontWeight: 900, lineHeight: 1.25, textTransform: 'uppercase', textShadow: '0 2px 4px rgba(0,0,0,0.15)' }}>
                    {currentPreviewBanner.tieuDe}
                  </div>
                </div>

                <div style={{ zIndex: 2, position: 'relative' }}>
                  <div style={{ width: '84px', height: '84px', borderRadius: '50%', background: '#fff', padding: '3px', boxShadow: '0 4px 12px rgba(0,0,0,0.2)' }}>
                    <img
                      src={getImageUrl(currentPreviewBanner.hinhAnh, DEFAULT_IMAGE_PLACEHOLDER)}
                      alt="Banner"
                      onError={handleImageError}
                      style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }}
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Pagination indicator dots */}
            <div style={{ position: 'absolute', bottom: '8px', left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: '6px', zIndex: 3 }}>
              {activeBanners.map((_, idx) => (
                <div
                  key={idx}
                  onClick={() => setPreviewIndex(idx)}
                  style={{
                    width: idx === previewIndex ? '18px' : '6px',
                    height: '6px',
                    borderRadius: '3px',
                    background: idx === previewIndex ? '#fff' : 'rgba(255,255,255,0.5)',
                    cursor: 'pointer',
                    transition: 'all 0.3s ease',
                    boxShadow: '0 1px 3px rgba(0,0,0,0.4)',
                  }}
                />
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Banners Data Table */}
      <div className="card-table">
        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : banners.length === 0 ? (
          <div className="empty-state" style={{ padding: '50px' }}>
            Chưa có banner nào. Hãy bấm "Thêm Banner Mới" để thiết lập banner ưu đãi cho ứng dụng khách hàng!
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '50px', textAlign: 'center' }}>Thứ Tự</th>
                <th style={{ width: '120px' }}>Hình Ảnh</th>
                <th>Tiêu Đề & Phụ Đề</th>
                <th style={{ width: '140px' }}>Kiểu Banner</th>
                <th style={{ width: '120px' }}>Màu Theme</th>
                <th style={{ width: '120px', textAlign: 'center' }}>Trạng Thái</th>
                <th style={{ width: '140px', textAlign: 'center' }}>Thao Tác</th>
              </tr>
            </thead>
            <tbody>
              {banners.map((b) => (
                <tr key={b.maBanner}>
                  <td style={{ textAlign: 'center', fontWeight: 800, fontSize: '15px', color: '#fc6011' }}>
                    #{b.thuTu}
                  </td>
                  <td>
                    <img
                      src={getImageUrl(b.hinhAnh, DEFAULT_IMAGE_PLACEHOLDER)}
                      alt={b.tieuDe}
                      onError={handleImageError}
                      style={{
                        width: b.loaiBanner === 'THE_CHUAN' ? '56px' : '96px',
                        height: '48px',
                        borderRadius: '8px',
                        objectFit: 'cover',
                        border: '1px solid #e2e8f0',
                      }}
                    />
                  </td>
                  <td>
                    <div style={{ fontWeight: 800, color: '#0f172a', fontSize: '14px', marginBottom: '4px' }}>
                      {b.tieuDe}
                    </div>
                    {b.phuDe && (
                      <div style={{ fontSize: '12px', color: '#64748b' }}>
                        {b.phuDe}
                      </div>
                    )}
                  </td>
                  <td>
                    {b.loaiBanner === 'THE_CHUAN' ? (
                      <span className="badge badge-secondary" style={{ fontSize: '11px', fontWeight: 700 }}>
                        Thẻ Chữ + Ảnh Tròn
                      </span>
                    ) : (
                      <span className="badge badge-success" style={{ fontSize: '11px', fontWeight: 700, background: '#ecfdf5', color: '#059669' }}>
                        Ảnh Tràn Khung (2.4:1)
                      </span>
                    )}
                  </td>
                  <td>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <div
                        style={{
                          width: '20px',
                          height: '20px',
                          borderRadius: '6px',
                          background: b.mauSac,
                          border: '1px solid rgba(0,0,0,0.1)',
                        }}
                      />
                      <span style={{ fontSize: '11px', fontWeight: 600, color: '#475569' }}>{b.mauSac}</span>
                    </div>
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <button
                      onClick={() => handleToggleStatus(b)}
                      style={{
                        background: 'none',
                        border: 'none',
                        cursor: 'pointer',
                        padding: '4px 8px',
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '6px',
                      }}
                    >
                      {b.trangThai === 'HOAT_DONG' ? (
                        <span className="badge badge-success" style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '6px 10px' }}>
                          <CheckCircle2 size={13} /> Hoạt Động
                        </span>
                      ) : (
                        <span className="badge badge-secondary" style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '6px 10px', background: '#cbd5e1', color: '#475569' }}>
                          <XCircle size={13} /> Tạm Dừng
                        </span>
                      )}
                    </button>
                  </td>
                  <td style={{ textAlign: 'center' }}>
                    <div style={{ display: 'flex', justifyContent: 'center', gap: '8px' }}>
                      <button
                        className="btn btn-outline btn-sm"
                        onClick={() => handleOpenEdit(b)}
                        style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', fontSize: '12px' }}
                      >
                        <Edit2 size={14} color="#fc6011" /> Sửa
                      </button>
                      <button
                        className="btn btn-outline btn-sm"
                        onClick={() => {
                          setDeletingBanner(b);
                          setDeleteConfirmOpen(true);
                        }}
                        style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', fontSize: '12px', color: '#ef4444' }}
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

      {/* Modal Add / Edit */}
      <Modal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingBanner ? `Chỉnh Sửa Banner #${editingBanner.maBanner}` : 'Thêm Banner Ưu Đãi Mới'}
        maxWidth="680px"
      >
        <form onSubmit={handleSubmit}>
          {/* Kiểu hiển thị Banner */}
          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label className="form-label" style={{ fontWeight: 800 }}>Kiểu Hiển Thị Banner Khớp Với App</label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginTop: '6px' }}>
              <div
                onClick={() => {
                  setLoaiBanner('TRAN_VIEN');
                  setAspectRatio(2.4);
                }}
                style={{
                  border: loaiBanner === 'TRAN_VIEN' ? '2px solid #fc6011' : '1px solid #cbd5e1',
                  background: loaiBanner === 'TRAN_VIEN' ? '#fff7ed' : '#f8fafc',
                  padding: '12px',
                  borderRadius: '12px',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                }}
              >
                <div style={{ padding: '8px', borderRadius: '8px', background: loaiBanner === 'TRAN_VIEN' ? '#fc6011' : '#e2e8f0', color: '#fff' }}>
                  <ImageIcon size={20} />
                </div>
                <div>
                  <div style={{ fontWeight: 800, fontSize: '13px', color: loaiBanner === 'TRAN_VIEN' ? '#fc6011' : '#1e293b' }}>
                    Ảnh Tràn Toàn Khung (2.4 : 1)
                  </div>
                  <div style={{ fontSize: '11px', color: '#64748b' }}>
                    Phù hợp cho ảnh Poster / Quảng cáo như Phúc Long, Flash Sale...
                  </div>
                </div>
              </div>

              <div
                onClick={() => {
                  setLoaiBanner('THE_CHUAN');
                  setAspectRatio(1.0);
                }}
                style={{
                  border: loaiBanner === 'THE_CHUAN' ? '2px solid #fc6011' : '1px solid #cbd5e1',
                  background: loaiBanner === 'THE_CHUAN' ? '#fff7ed' : '#f8fafc',
                  padding: '12px',
                  borderRadius: '12px',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '10px',
                }}
              >
                <div style={{ padding: '8px', borderRadius: '8px', background: loaiBanner === 'THE_CHUAN' ? '#fc6011' : '#e2e8f0', color: '#fff' }}>
                  <LayoutTemplate size={20} />
                </div>
                <div>
                  <div style={{ fontWeight: 800, fontSize: '13px', color: loaiBanner === 'THE_CHUAN' ? '#fc6011' : '#1e293b' }}>
                    Thẻ Chữ + Ảnh Tròn (1 : 1)
                  </div>
                  <div style={{ fontSize: '11px', color: '#64748b' }}>
                    Tiêu đề bên trái, ảnh món ăn tròn bo viền bên phải
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Chọn tỷ lệ cắt ảnh */}
          <div className="form-group" style={{ marginBottom: '14px' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
              <label className="form-label" style={{ margin: 0 }}>Tỷ Lệ Khung Cắt Ảnh</label>
              <div style={{ display: 'flex', gap: '6px' }}>
                <button
                  type="button"
                  className="btn btn-sm"
                  style={{
                    padding: '3px 8px',
                    fontSize: '11px',
                    fontWeight: 700,
                    background: aspectRatio === 2.4 ? '#fc6011' : '#f1f5f9',
                    color: aspectRatio === 2.4 ? '#fff' : '#475569',
                    border: 'none',
                    borderRadius: '6px',
                  }}
                  onClick={() => setAspectRatio(2.4)}
                >
                  2.4 : 1 (Chuẩn App Mobile)
                </button>
                <button
                  type="button"
                  className="btn btn-sm"
                  style={{
                    padding: '3px 8px',
                    fontSize: '11px',
                    fontWeight: 700,
                    background: aspectRatio === 1.77 ? '#fc6011' : '#f1f5f9',
                    color: aspectRatio === 1.77 ? '#fff' : '#475569',
                    border: 'none',
                    borderRadius: '6px',
                  }}
                  onClick={() => setAspectRatio(1.77)}
                >
                  16 : 9 (Rộng)
                </button>
                <button
                  type="button"
                  className="btn btn-sm"
                  style={{
                    padding: '3px 8px',
                    fontSize: '11px',
                    fontWeight: 700,
                    background: aspectRatio === 1.0 ? '#fc6011' : '#f1f5f9',
                    color: aspectRatio === 1.0 ? '#fff' : '#475569',
                    border: 'none',
                    borderRadius: '6px',
                  }}
                  onClick={() => setAspectRatio(1.0)}
                >
                  1 : 1 (Vuông)
                </button>
              </div>
            </div>

            <ImageCropUpload
              label="Tải Lên Hoặc Cắt Ảnh Banner Đúng Khung"
              value={hinhAnh}
              onChange={(url) => setHinhAnh(url)}
              aspectRatio={aspectRatio}
            />
          </div>

          <div className="form-group" style={{ marginBottom: '14px' }}>
            <label className="form-label">Tên Gợi Nhớ Banner (Chỉ dùng quản lý trong Admin)</label>
            <input
              type="text"
              className="form-control"
              placeholder="VD: Flash Sale 20/10, Ưu đãi Phúc Long..."
              value={tieuDe}
              onChange={(e) => setTieuDe(e.target.value)}
            />
          </div>

          {loaiBanner === 'THE_CHUAN' && (
            <div className="form-group" style={{ marginBottom: '14px' }}>
              <label className="form-label">Màu Nền Thẻ / Gradient Theme</label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '8px', marginBottom: '8px' }}>
                {PRESET_COLORS.map((p) => (
                  <div
                    key={p.name}
                    onClick={() => setMauSac(p.color)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '8px',
                      padding: '8px 12px',
                      borderRadius: '8px',
                      border: mauSac === p.color ? '2px solid #fc6011' : '1px solid #e2e8f0',
                      cursor: 'pointer',
                      background: mauSac === p.color ? '#fff7ed' : '#f8fafc',
                    }}
                  >
                    <div style={{ width: '20px', height: '20px', borderRadius: '50%', background: p.gradient }} />
                    <span style={{ fontSize: '12px', fontWeight: 600 }}>{p.name}</span>
                  </div>
                ))}
              </div>
              <input
                type="text"
                className="form-control"
                placeholder="Mã màu HEX (VD: #FC6011)"
                value={mauSac}
                onChange={(e) => setMauSac(e.target.value)}
              />
            </div>
          )}

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '14px', marginBottom: '14px' }}>
            <div className="form-group">
              <label className="form-label">Thứ Tự Ưu Tiên (Hiển thị đầu tiên = 1)</label>
              <input
                type="number"
                min={1}
                max={99}
                className="form-control"
                value={thuTu}
                onChange={(e) => setThuTu(Number(e.target.value))}
              />
            </div>
            <div className="form-group">
              <label className="form-label">Trạng Thái</label>
              <select className="form-control" value={trangThai} onChange={(e) => setTrangThai(e.target.value)}>
                <option value="HOAT_DONG">Hoạt Động (Hiển thị trên App)</option>
                <option value="TAM_DUNG">Tạm Dừng (Ẩn khỏi App)</option>
              </select>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '20px' }}>
            <button type="button" className="btn btn-outline" onClick={() => setModalOpen(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">{editingBanner ? 'Lưu Thay Đổi' : 'Thêm Banner'}</button>
          </div>
        </form>
      </Modal>

      {/* Delete confirmation modal */}
      <Modal isOpen={deleteConfirmOpen} onClose={() => setDeleteConfirmOpen(false)} title="Xác Nhận Xóa Banner">
        <div style={{ padding: '10px 0', textAlign: 'center' }}>
          <div style={{ fontSize: '15px', color: '#1e293b', marginBottom: '20px' }}>
            Bạn có chắc chắn muốn xóa banner <b>"{deletingBanner?.tieuDe}"</b> không?
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', gap: '12px' }}>
            <button className="btn btn-outline" onClick={() => setDeleteConfirmOpen(false)}>Hủy</button>
            <button className="btn btn-danger" onClick={handleDelete} style={{ background: '#ef4444', color: '#fff' }}>Xác Nhận Xóa</button>
          </div>
        </div>
      </Modal>

      <NotificationModal
        isOpen={notice.isOpen}
        onClose={() => setNotice({ ...notice, isOpen: false })}
        title={notice.title}
        message={notice.message}
        type={notice.type}
      />
    </div>
  );
};
