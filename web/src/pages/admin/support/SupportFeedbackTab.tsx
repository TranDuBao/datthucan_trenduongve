import React, { useState, useEffect } from 'react';
import { MessageSquare, Star, RefreshCw, CheckCircle, Clock, Image as ImageIcon, User, Phone, Tag } from 'lucide-react';
import { apiFetch } from '../../../api/apiClient';
import { Modal } from '../../../components/Modal';

interface FeedbackItem {
  maGopY: number;
  maTaiKhoan?: number;
  hoTen?: string;
  sdt?: string;
  loaiGopY: string;
  noiDung: string;
  danhGiaSao?: number;
  danhSachAnh?: string[];
  trangThai: 'CHUA_XEM' | 'DA_XEM' | 'DA_XU_LY';
  ghiChuAdmin?: string;
  ngayTao: string;
  taiKhoan?: {
    tenDangNhap: string;
    loaiTaiKhoan: string;
  };
}

export const SupportFeedbackTab: React.FC = () => {
  const [feedbacks, setFeedbacks] = useState<FeedbackItem[]>([]);
  const [total, setTotal] = useState<number>(0);
  const [page, setPage] = useState<number>(1);
  const [limit] = useState<number>(10);
  const [typeFilter, setTypeFilter] = useState<string>('ALL');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [loading, setLoading] = useState<boolean>(true);

  // Detail Modal
  const [selectedItem, setSelectedItem] = useState<FeedbackItem | null>(null);
  const [updatingStatus, setUpdatingStatus] = useState<boolean>(false);
  const [adminNote, setAdminNote] = useState<string>('');

  // Image Preview Modal
  const [previewImage, setPreviewImage] = useState<string | null>(null);

  const fetchFeedbacks = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({ page: String(page), limit: String(limit) });
      if (typeFilter !== 'ALL') params.set('loaiGopY', typeFilter);
      if (statusFilter !== 'ALL') params.set('trangThai', statusFilter);

      const res = await apiFetch<any>(`/admin/support/feedbacks?${params.toString()}`);
      if (res && res.data) {
        setFeedbacks(res.data.items || []);
        setTotal(res.data.total || 0);
      }
    } catch (err: any) {
      console.error('Fetch feedbacks error:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFeedbacks();
  }, [page, typeFilter, statusFilter]);

  const handleUpdateStatus = async (status: 'CHUA_XEM' | 'DA_XEM' | 'DA_XU_LY') => {
    if (!selectedItem) return;
    try {
      setUpdatingStatus(true);
      await apiFetch(`/admin/support/feedbacks/${selectedItem.maGopY}/status`, {
        method: 'PUT',
        body: JSON.stringify({ trangThai: status, ghiChuAdmin: adminNote }),
      });
      setSelectedItem(null);
      fetchFeedbacks();
    } catch (err: any) {
      alert(err.message || 'Lỗi cập nhật');
    } finally {
      setUpdatingStatus(false);
    }
  };

  const renderTypeLabel = (type: string) => {
    switch (type) {
      case 'TINH_NANG': return 'Đề xuất tính năng';
      case 'CHAT_LUONG_MON': return 'Chất lượng món ăn';
      case 'DICH_VU': return 'Dịch vụ & Thái độ';
      case 'LOI_APP': return 'Báo lỗi ứng dụng';
      default: return 'Khác';
    }
  };

  const renderStatusBadge = (status: string) => {
    switch (status) {
      case 'DA_XU_LY':
        return (
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '3px 8px', borderRadius: '12px', fontSize: '11px', fontWeight: 700, backgroundColor: '#ecfdf5', color: '#047857' }}>
            <CheckCircle size={12} /> Đã xử lý
          </span>
        );
      case 'DA_XEM':
        return (
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '3px 8px', borderRadius: '12px', fontSize: '11px', fontWeight: 700, backgroundColor: '#eff6ff', color: '#1d4ed8' }}>
            Đã xem
          </span>
        );
      default:
        return (
          <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', padding: '3px 8px', borderRadius: '12px', fontSize: '11px', fontWeight: 700, backgroundColor: '#fffbeb', color: '#b45309' }}>
            <Clock size={12} /> Chưa xem
          </span>
        );
    }
  };

  const totalPages = Math.ceil(total / limit) || 1;

  return (
    <div>
      {/* Filters bar */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '14px',
          padding: '16px 20px',
          border: '1px solid #e2e8f0',
          marginBottom: '20px',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: '12px',
        }}
      >
        <div style={{ display: 'flex', gap: '12px', flexWrap: 'wrap', alignItems: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b' }}>Loại góp ý:</span>
            <select
              value={typeFilter}
              onChange={(e) => { setTypeFilter(e.target.value); setPage(1); }}
              style={{ padding: '6px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
            >
              <option value="ALL">Tất cả loại</option>
              <option value="TINH_NANG">Đề xuất tính năng</option>
              <option value="CHAT_LUONG_MON">Chất lượng món</option>
              <option value="DICH_VU">Dịch vụ</option>
              <option value="LOI_APP">Báo lỗi app</option>
              <option value="KHAC">Khác</option>
            </select>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b' }}>Trạng thái:</span>
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }}
              style={{ padding: '6px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
            >
              <option value="ALL">Tất cả trạng thái</option>
              <option value="CHUA_XEM">Chưa xem</option>
              <option value="DA_XEM">Đã xem</option>
              <option value="DA_XU_LY">Đã xử lý</option>
            </select>
          </div>
        </div>

        <button
          onClick={fetchFeedbacks}
          disabled={loading}
          style={{
            padding: '8px 14px',
            borderRadius: '8px',
            border: '1px solid #e2e8f0',
            backgroundColor: '#ffffff',
            color: '#475569',
            fontSize: '12px',
            fontWeight: 600,
            cursor: 'pointer',
            display: 'inline-flex',
            alignItems: 'center',
            gap: '6px',
          }}
        >
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} /> Làm mới
        </button>
      </div>

      {/* Table Card */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '14px',
          border: '1px solid #e2e8f0',
          boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
          overflow: 'hidden',
        }}
      >
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
          <thead>
            <tr style={{ backgroundColor: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
              <th style={{ padding: '12px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase' }}>Người gửi</th>
              <th style={{ padding: '12px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase' }}>Phân loại</th>
              <th style={{ padding: '12px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase' }}>Đánh giá</th>
              <th style={{ padding: '12px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase' }}>Nội dung góp ý</th>
              <th style={{ padding: '12px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase' }}>Trạng thái</th>
              <th style={{ padding: '12px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase' }}>Ngày gửi</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan={6} style={{ padding: '48px 18px', textAlign: 'center', color: '#94a3b8' }}>
                  <RefreshCw className="animate-spin inline mr-2" size={18} /> Đang tải danh sách góp ý...
                </td>
              </tr>
            ) : feedbacks.length === 0 ? (
              <tr>
                <td colSpan={6} style={{ padding: '56px 18px', textAlign: 'center' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
                    <div
                      style={{
                        width: '48px',
                        height: '48px',
                        borderRadius: '14px',
                        backgroundColor: '#f1f5f9',
                        color: '#94a3b8',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        marginBottom: '10px',
                      }}
                    >
                      <MessageSquare size={24} />
                    </div>
                    <div style={{ fontWeight: 700, color: '#334155', fontSize: '14px' }}>Chưa có ý kiến góp ý nào</div>
                    <div style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px' }}>
                      Các ý kiến đóng góp và đánh giá từ khách hàng trên ứng dụng sẽ hiển thị tại đây.
                    </div>
                  </div>
                </td>
              </tr>
            ) : (
              feedbacks.map((fb) => (
                <tr
                  key={fb.maGopY}
                  onClick={() => { setSelectedItem(fb); setAdminNote(fb.ghiChuAdmin || ''); }}
                  style={{ borderBottom: '1px solid #f1f5f9', cursor: 'pointer', transition: 'background 0.15s' }}
                  onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f8fafc')}
                  onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                >
                  <td style={{ padding: '14px 18px', verticalAlign: 'middle' }}>
                    <div style={{ fontWeight: 700, color: '#0f172a' }}>{fb.hoTen || 'Khách hàng'}</div>
                    <div style={{ fontSize: '11px', color: '#94a3b8' }}>{fb.sdt || fb.taiKhoan?.tenDangNhap || 'Không có SĐT'}</div>
                  </td>
                  <td style={{ padding: '14px 18px', verticalAlign: 'middle' }}>
                    <span style={{ fontSize: '12px', fontWeight: 600, color: '#475569', backgroundColor: '#f1f5f9', padding: '3px 8px', borderRadius: '6px' }}>
                      {renderTypeLabel(fb.loaiGopY)}
                    </span>
                  </td>
                  <td style={{ padding: '14px 18px', verticalAlign: 'middle' }}>
                    {fb.danhGiaSao ? (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '2px', color: '#f59e0b', fontWeight: 700 }}>
                        <Star size={14} fill="#f59e0b" color="#f59e0b" />
                        <span>{fb.danhGiaSao}/5</span>
                      </div>
                    ) : (
                      <span style={{ color: '#cbd5e1' }}>—</span>
                    )}
                  </td>
                  <td style={{ padding: '14px 18px', verticalAlign: 'middle', maxWidth: '300px' }}>
                    <div style={{ color: '#334155', fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                      {fb.noiDung}
                    </div>
                    {fb.danhSachAnh && fb.danhSachAnh.length > 0 && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '11px', color: '#fc6011', marginTop: '2px' }}>
                        <ImageIcon size={12} /> {fb.danhSachAnh.length} ảnh đính kèm
                      </div>
                    )}
                  </td>
                  <td style={{ padding: '14px 18px', verticalAlign: 'middle' }}>
                    {renderStatusBadge(fb.trangThai)}
                  </td>
                  <td style={{ padding: '14px 18px', verticalAlign: 'middle', fontSize: '12px', color: '#64748b' }}>
                    {new Date(fb.ngayTao).toLocaleString('vi-VN')}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>

        {/* Pagination */}
        <div style={{ padding: '12px 20px', borderTop: '1px solid #f1f5f9', display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '13px', color: '#64748b' }}>
          <div>Hiển thị {feedbacks.length} / {total} góp ý</div>
          <div style={{ display: 'flex', gap: '8px' }}>
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1}
              style={{ padding: '5px 12px', borderRadius: '6px', border: '1px solid #e2e8f0', backgroundColor: page <= 1 ? '#f8fafc' : '#ffffff', cursor: page <= 1 ? 'not-allowed' : 'pointer', fontSize: '12px' }}
            >
              Trang trước
            </button>
            <span style={{ padding: '5px 10px', fontWeight: 700, color: '#0f172a' }}>{page} / {totalPages}</span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages}
              style={{ padding: '5px 12px', borderRadius: '6px', border: '1px solid #e2e8f0', backgroundColor: page >= totalPages ? '#f8fafc' : '#ffffff', cursor: page >= totalPages ? 'not-allowed' : 'pointer', fontSize: '12px' }}
            >
              Trang sau
            </button>
          </div>
        </div>
      </div>

      {/* Detail Modal */}
      <Modal
        isOpen={!!selectedItem}
        onClose={() => setSelectedItem(null)}
        title="Chi Tiết Ý Kiến Đóng Góp"
        maxWidth="600px"
      >
        {selectedItem && (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div style={{ padding: '14px', borderRadius: '10px', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between' }}>
              <div>
                <div style={{ fontSize: '15px', fontWeight: 800, color: '#0f172a' }}>{selectedItem.hoTen || 'Khách hàng ẩn danh'}</div>
                <div style={{ fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
                  SĐT: {selectedItem.sdt || 'Không có'} • Ngày gửi: {new Date(selectedItem.ngayTao).toLocaleString('vi-VN')}
                </div>
              </div>
              <div>{renderStatusBadge(selectedItem.trangThai)}</div>
            </div>

            <div>
              <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>Phân loại & Đánh giá</span>
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginTop: '4px' }}>
                <span style={{ fontSize: '13px', fontWeight: 700, color: '#fc6011' }}>{renderTypeLabel(selectedItem.loaiGopY)}</span>
                {selectedItem.danhGiaSao && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '2px', color: '#f59e0b', fontWeight: 700 }}>
                    <Star size={14} fill="#f59e0b" color="#f59e0b" />
                    <span>{selectedItem.danhGiaSao} sao</span>
                  </div>
                )}
              </div>
            </div>

            <div>
              <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>Nội dung phản hồi</span>
              <div style={{ padding: '12px 14px', borderRadius: '8px', backgroundColor: '#f8fafc', border: '1px solid #e2e8f0', fontSize: '13px', lineHeight: 1.6, color: '#1e293b', marginTop: '6px', whiteSpace: 'pre-wrap' }}>
                {selectedItem.noiDung}
              </div>
            </div>

            {selectedItem.danhSachAnh && selectedItem.danhSachAnh.length > 0 && (
              <div>
                <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>Hình ảnh đính kèm ({selectedItem.danhSachAnh.length})</span>
                <div style={{ display: 'flex', gap: '10px', marginTop: '6px', flexWrap: 'wrap' }}>
                  {selectedItem.danhSachAnh.map((imgUrl, i) => (
                    <img
                      key={i}
                      src={imgUrl.startsWith('http') ? imgUrl : `http://localhost:3000${imgUrl}`}
                      alt={`Ảnh góp ý ${i + 1}`}
                      onClick={() => setPreviewImage(imgUrl.startsWith('http') ? imgUrl : `http://localhost:3000${imgUrl}`)}
                      style={{ width: '80px', height: '80px', objectFit: 'cover', borderRadius: '8px', border: '1px solid #cbd5e1', cursor: 'pointer' }}
                    />
                  ))}
                </div>
              </div>
            )}

            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#64748b', marginBottom: '6px' }}>
                Ghi chú nội bộ của Admin
              </label>
              <textarea
                rows={3}
                placeholder="Nhập ghi chú xử lý nội bộ..."
                value={adminNote}
                onChange={(e) => setAdminNote(e.target.value)}
                style={{ width: '100%', padding: '8px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
              />
            </div>

            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingTop: '12px', borderTop: '1px solid #f1f5f9' }}>
              <button
                type="button"
                onClick={() => setSelectedItem(null)}
                style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #cbd5e1', backgroundColor: '#ffffff', fontSize: '13px', cursor: 'pointer' }}
              >
                Đóng
              </button>

              <div style={{ display: 'flex', gap: '8px' }}>
                <button
                  type="button"
                  disabled={updatingStatus}
                  onClick={() => handleUpdateStatus('DA_XEM')}
                  style={{ padding: '8px 14px', borderRadius: '8px', border: '1px solid #bfdbfe', backgroundColor: '#eff6ff', color: '#1d4ed8', fontWeight: 700, fontSize: '12px', cursor: 'pointer' }}
                >
                  Đánh Dấu Đã Xem
                </button>
                <button
                  type="button"
                  disabled={updatingStatus}
                  onClick={() => handleUpdateStatus('DA_XU_LY')}
                  style={{ padding: '8px 16px', borderRadius: '8px', backgroundColor: '#059669', color: '#ffffff', fontWeight: 700, fontSize: '12px', border: 'none', cursor: 'pointer' }}
                >
                  Đã Xử Lý Xong
                </button>
              </div>
            </div>
          </div>
        )}
      </Modal>

      {/* Image Preview */}
      <Modal
        isOpen={!!previewImage}
        onClose={() => setPreviewImage(null)}
        title="Xem Ảnh Đính Kèm"
        maxWidth="700px"
      >
        {previewImage && (
          <div style={{ textAlign: 'center' }}>
            <img src={previewImage} alt="Preview" style={{ maxWidth: '100%', maxHeight: '550px', borderRadius: '10px' }} />
          </div>
        )}
      </Modal>
    </div>
  );
};

