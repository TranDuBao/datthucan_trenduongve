import React, { useState, useEffect } from 'react';
import { Star, EyeOff, Eye, AlertCircle, CheckCircle2, Search, Store, MessageSquare } from 'lucide-react';
import { apiFetch } from '../../api/apiClient';
import { getImageUrl, handleImageError, DEFAULT_IMAGE_PLACEHOLDER } from '../../utils/imageUtils';

interface DishReview {
  id: number;
  dishId: number;
  dishName: string;
  rating: number;
  comment?: string;
}

interface AdminReview {
  maDanhGia: number;
  maDonHang: number;
  maQuan: number;
  tenQuan?: string;
  tenKhachHang: string;
  soLuongSao: number;
  nhanXet: string;
  hinhanh?: string;
  phanHoi?: string;
  ngayNhanXet: string;
  isHidden: boolean;
  lyDoAn?: string;
  dishReviews?: DishReview[];
}

export const AdminReviews: React.FC = () => {
  const [reviews, setReviews] = useState<AdminReview[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedReview, setSelectedReview] = useState<AdminReview | null>(null);
  const [hideReason, setHideReason] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'visible' | 'hidden'>('all');
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const fetchReviews = async () => {
    try {
      setLoading(true);
      const res = await apiFetch<any>('/admin/reviews?limit=1000');
      const data = res.data?.reviews || res.data || res.payload || [];
      setReviews(Array.isArray(data) ? data : []);
    } catch (e: any) {
      console.error(e);
      setNotification({ type: 'error', message: e.message || 'Lỗi khi tải danh sách đánh giá' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReviews();
  }, []);

  const toggleVisibility = async (reviewId: number, isHidden: boolean, reason?: string) => {
    try {
      await apiFetch(`/admin/reviews/${reviewId}/visibility`, {
        method: 'PATCH',
        body: JSON.stringify({ isHidden, reason }),
      });
      setNotification({
        type: 'success',
        message: isHidden ? 'Đã ẩn đánh giá thành công' : 'Đã hiện lại đánh giá thành công',
      });
      setSelectedReview(null);
      setHideReason('');
      fetchReviews();
    } catch (e: any) {
      setNotification({ type: 'error', message: e.message || 'Lỗi thao tác kiểm duyệt' });
    }
  };

  const filteredReviews = reviews.filter((rev) => {
    if (statusFilter === 'visible' && rev.isHidden) return false;
    if (statusFilter === 'hidden' && !rev.isHidden) return false;
    if (search.trim()) {
      const q = search.trim().toLowerCase();
      const matchComment = rev.nhanXet && rev.nhanXet.toLowerCase().includes(q);
      const matchCustomer = rev.tenKhachHang && rev.tenKhachHang.toLowerCase().includes(q);
      const matchStore = rev.tenQuan && rev.tenQuan.toLowerCase().includes(q);
      const matchOrder = rev.maDonHang && String(rev.maDonHang).includes(q);
      return matchComment || matchCustomer || matchStore || matchOrder;
    }
    return true;
  });

  return (
    <div className="page-content" style={{ padding: '24px' }}>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 800, color: '#1e293b' }}>Kiểm Duyệt Đánh Giá (Admin)</h1>
        <p style={{ fontSize: '14px', color: '#64748b' }}>Quản lý và ẩn các đánh giá vi phạm quy chuẩn cộng đồng trên toàn hệ thống</p>
      </div>

      {notification && (
        <div
          style={{
            padding: '12px 16px',
            borderRadius: '8px',
            marginBottom: '16px',
            background: notification.type === 'success' ? '#f0fdf4' : '#fef2f2',
            border: `1px solid ${notification.type === 'success' ? '#bbf7d0' : '#fecaca'}`,
            color: notification.type === 'success' ? '#166534' : '#991b1b',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
          }}
        >
          {notification.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
          <span>{notification.message}</span>
        </div>
      )}

      {/* Toolbar filters */}
      <div style={{ display: 'flex', gap: '12px', marginBottom: '20px', flexWrap: 'wrap' }}>
        <div className="search-input-group" style={{ flex: 1, minWidth: '260px' }}>
          <Search size={16} />
          <input
            type="text"
            placeholder="Tìm theo nội dung đánh giá, khách hàng, tên quán, mã đơn..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <select
          className="form-control"
          style={{ width: '200px', fontWeight: 600 }}
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as any)}
        >
          <option value="all">Tất cả trạng thái ({reviews.length})</option>
          <option value="visible">Đang hiển thị ({reviews.filter((r) => !r.isHidden).length})</option>
          <option value="hidden">Đã ẩn vi phạm ({reviews.filter((r) => r.isHidden).length})</option>
        </select>
      </div>

      {loading ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#64748b' }}>Đang tải danh sách đánh giá...</div>
      ) : filteredReviews.length === 0 ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#64748b', background: '#ffffff', borderRadius: '12px' }}>
          Không có đánh giá nào phù hợp với bộ lọc
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {filteredReviews.map((rev) => (
            <div
              key={rev.maDanhGia}
              style={{
                background: rev.isHidden ? '#fef2f2' : '#ffffff',
                padding: '20px',
                borderRadius: '12px',
                border: `1px solid ${rev.isHidden ? '#fecaca' : '#e2e8f0'}`,
                boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '12px' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', flexWrap: 'wrap' }}>
                    <span style={{ fontWeight: 800, fontSize: '15px', color: '#1e293b' }}>
                      {rev.tenKhachHang || 'Khách hàng'}
                    </span>
                    <span style={{ color: '#64748b', fontSize: '13px' }}>
                      (Đơn #DH{rev.maDonHang})
                    </span>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', background: '#f1f5f9', color: '#334155', padding: '2px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 600 }}>
                      <Store size={12} color="#fc6011" /> {rev.tenQuan || `Nhà hàng #${rev.maQuan}`}
                    </span>
                    {rev.isHidden && (
                      <span
                        style={{
                          padding: '2px 8px',
                          borderRadius: '4px',
                          background: '#ef4444',
                          color: '#ffffff',
                          fontSize: '11px',
                          fontWeight: 700,
                        }}
                      >
                        ĐÃ ẨN
                      </span>
                    )}
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginTop: '6px' }}>
                    <div style={{ display: 'flex', gap: '2px' }}>
                      {[1, 2, 3, 4, 5].map((s) => (
                        <Star
                          key={s}
                          size={16}
                          fill={s <= rev.soLuongSao ? '#eab308' : 'none'}
                          color={s <= rev.soLuongSao ? '#eab308' : '#cbd5e1'}
                        />
                      ))}
                    </div>
                    <span style={{ fontSize: '12px', color: '#64748b' }}>
                      {rev.ngayNhanXet ? new Date(rev.ngayNhanXet).toLocaleString('vi-VN') : ''}
                    </span>
                  </div>
                </div>

                <div>
                  {rev.isHidden ? (
                    <button
                      onClick={() => toggleVisibility(rev.maDanhGia, false)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        padding: '6px 14px',
                        borderRadius: '6px',
                        border: '1px solid #bbf7d0',
                        background: '#f0fdf4',
                        color: '#166534',
                        fontWeight: 700,
                        fontSize: '13px',
                        cursor: 'pointer',
                      }}
                    >
                      <Eye size={14} /> Hiện lại đánh giá
                    </button>
                  ) : (
                    <button
                      onClick={() => setSelectedReview(rev)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        padding: '6px 14px',
                        borderRadius: '6px',
                        border: '1px solid #fecaca',
                        background: '#fef2f2',
                        color: '#991b1b',
                        fontWeight: 700,
                        fontSize: '13px',
                        cursor: 'pointer',
                      }}
                    >
                      <EyeOff size={14} /> Ẩn đánh giá
                    </button>
                  )}
                </div>
              </div>

              {/* Review Comment Text */}
              {rev.nhanXet && (
                <p style={{ fontSize: '14px', color: '#334155', margin: '12px 0 8px 0', lineHeight: 1.5 }}>
                  {rev.nhanXet}
                </p>
              )}

              {/* Attached Review Image */}
              {rev.hinhanh && (
                <div style={{ marginTop: '8px', marginBottom: '8px' }}>
                  <img
                    src={getImageUrl(rev.hinhanh, DEFAULT_IMAGE_PLACEHOLDER)}
                    alt="Review attachment"
                    onError={handleImageError}
                    style={{ maxWidth: '120px', maxHeight: '120px', objectFit: 'cover', borderRadius: '8px', border: '1px solid #e2e8f0' }}
                  />
                </div>
              )}

              {/* Specific Dish Reviews */}
              {rev.dishReviews && rev.dishReviews.length > 0 && (
                <div style={{ marginTop: '10px', background: '#f8fafc', padding: '10px 14px', borderRadius: '8px', border: '1px solid #f1f5f9' }}>
                  <div style={{ fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>Đánh giá từng món:</div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                    {rev.dishReviews.map((dr) => (
                      <div key={dr.id} style={{ fontSize: '12px', color: '#334155', display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ fontWeight: 600 }}>• {dr.dishName || `Món #${dr.dishId}`}:</span>
                        <span style={{ color: '#eab308', fontWeight: 700 }}>{dr.rating}★</span>
                        {dr.comment && <span style={{ color: '#64748b' }}>"{dr.comment}"</span>}
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Restaurant Reply */}
              {rev.phanHoi && (
                <div style={{ marginTop: '10px', background: '#f0fdf4', padding: '10px 14px', borderRadius: '8px', border: '1px solid #bbf7d0', fontSize: '13px', color: '#166534' }}>
                  <div style={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <MessageSquare size={13} /> Phản hồi từ nhà hàng:
                  </div>
                  <div style={{ marginTop: '4px' }}>{rev.phanHoi}</div>
                </div>
              )}

              {rev.lyDoAn && (
                <div style={{ fontSize: '12px', color: '#991b1b', marginTop: '8px', fontStyle: 'italic', background: '#fee2e2', padding: '6px 10px', borderRadius: '6px' }}>
                  <b>Lý do ẩn:</b> {rev.lyDoAn}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Modal Confirm Hide Review */}
      {selectedReview && (
        <div
          style={{
            position: 'fixed',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'rgba(0,0,0,0.5)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 999,
          }}
        >
          <div style={{ background: '#ffffff', padding: '24px', borderRadius: '12px', width: '420px', maxWidth: '90%' }}>
            <h3 style={{ fontSize: '18px', fontWeight: 800, marginBottom: '12px' }}>Xác nhận ẩn đánh giá</h3>
            <p style={{ fontSize: '13px', color: '#64748b', marginBottom: '12px' }}>
              Vui lòng nhập lý do ẩn đánh giá của khách hàng <b>{selectedReview.tenKhachHang}</b>:
            </p>
            <textarea
              value={hideReason}
              onChange={(e) => setHideReason(e.target.value)}
              placeholder="Lý do ẩn (ví dụ: Chứa ngôn từ không phù hợp, spam, bôi nhọ)..."
              rows={3}
              style={{
                width: '100%',
                padding: '10px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                fontFamily: 'inherit',
                boxSizing: 'border-box',
              }}
            />
            <div style={{ display: 'flex', gap: '8px', marginTop: '16px', justifyContent: 'flex-end' }}>
              <button
                className="btn btn-outline"
                onClick={() => setSelectedReview(null)}
              >
                Hủy
              </button>
              <button
                className="btn btn-danger"
                style={{ background: '#ef4444', color: '#ffffff', fontWeight: 700 }}
                onClick={() => toggleVisibility(selectedReview.maDanhGia, true, hideReason)}
              >
                Xác nhận ẩn
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
