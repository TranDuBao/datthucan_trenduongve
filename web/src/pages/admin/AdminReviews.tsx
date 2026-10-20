import React, { useState, useEffect } from 'react';
import { Star, EyeOff, Eye, AlertCircle, CheckCircle2, ShieldAlert } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { API_BASE_URL } from '../../api/apiClient';

interface AdminReview {
  maDanhGia: number;
  maDonHang: number;
  maQuan: number;
  tenKhachHang: string;
  soLuongSao: number;
  nhanXet: string;
  phanHoi?: string;
  ngayNhanXet: string;
  isHidden: boolean;
  lyDoAn?: string;
}

export const AdminReviews: React.FC = () => {
  const { token } = useAuth();
  const [reviews, setReviews] = useState<AdminReview[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedReview, setSelectedReview] = useState<AdminReview | null>(null);
  const [hideReason, setHideReason] = useState('');
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const fetchReviews = async () => {
    try {
      setLoading(true);
      // Fetch reviews for restaurant ID 1 or list
      const res = await fetch(`${API_BASE_URL}/restaurants/1/reviews?limit=100`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const json = await res.json();
      if (json.status === 'success') {
        setReviews(json.data.reviews || []);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchReviews();
  }, [token]);

  const toggleVisibility = async (reviewId: number, isHidden: boolean, reason?: string) => {
    try {
      const res = await fetch(`${API_BASE_URL}/reviews/${reviewId}/visibility`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ isHidden, reason }),
      });
      const json = await res.json();
      if (json.status === 'success') {
        setNotification({
          type: 'success',
          message: isHidden ? 'Đã ẩn đánh giá thành công' : 'Đã hiện lại đánh giá thành công',
        });
        setSelectedReview(null);
        setHideReason('');
        fetchReviews();
      } else {
        setNotification({ type: 'error', message: json.message || 'Lỗi thao tác' });
      }
    } catch (e) {
      setNotification({ type: 'error', message: 'Lỗi mạng khi kết nối' });
    }
  };

  return (
    <div className="page-content" style={{ padding: '24px' }}>
      <div style={{ marginBottom: '24px' }}>
        <h1 style={{ fontSize: '24px', fontWeight: 800, color: '#1e293b' }}>Kiểm Duyệt Đánh Giá (Admin)</h1>
        <p style={{ fontSize: '14px', color: '#64748b' }}>Quản lý và ẩn các đánh giá vi phạm quy chuẩn cộng đồng</p>
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

      {loading ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#64748b' }}>Đang tải danh sách đánh giá...</div>
      ) : reviews.length === 0 ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#64748b', background: '#ffffff', borderRadius: '12px' }}>
          Chưa có đánh giá nào trong hệ thống
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {reviews.map((rev) => (
            <div
              key={rev.maDanhGia}
              style={{
                background: rev.isHidden ? '#fef2f2' : '#ffffff',
                padding: '20px',
                borderRadius: '12px',
                border: `1px solid ${rev.isHidden ? '#fecaca' : '#e2e8f0'}`,
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: '15px', color: '#1e293b' }}>
                    {rev.tenKhachHang || 'Khách hàng'} <span style={{ color: '#64748b', fontSize: '13px' }}>(Đơn #DH{rev.maDonHang})</span>
                    {rev.isHidden && (
                      <span
                        style={{
                          marginLeft: '8px',
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
                  <div style={{ display: 'flex', gap: '2px', marginTop: '4px' }}>
                    {[1, 2, 3, 4, 5].map((s) => (
                      <Star
                        key={s}
                        size={16}
                        fill={s <= rev.soLuongSao ? '#eab308' : 'none'}
                        color={s <= rev.soLuongSao ? '#eab308' : '#cbd5e1'}
                      />
                    ))}
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
                        padding: '6px 12px',
                        borderRadius: '6px',
                        border: '1px solid #bbf7d0',
                        background: '#f0fdf4',
                        color: '#166534',
                        fontWeight: 600,
                        fontSize: '13px',
                        cursor: 'pointer',
                      }}
                    >
                      <Eye size={14} /> Hiện lại
                    </button>
                  ) : (
                    <button
                      onClick={() => setSelectedReview(rev)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '6px',
                        padding: '6px 12px',
                        borderRadius: '6px',
                        border: '1px solid #fecaca',
                        background: '#fef2f2',
                        color: '#991b1b',
                        fontWeight: 600,
                        fontSize: '13px',
                        cursor: 'pointer',
                      }}
                    >
                      <EyeOff size={14} /> Ẩn đánh giá
                    </button>
                  )}
                </div>
              </div>

              {rev.nhanXet && <p style={{ fontSize: '14px', color: '#334155', margin: '8px 0' }}>{rev.nhanXet}</p>}

              {rev.lyDoAn && (
                <div style={{ fontSize: '12px', color: '#991b1b', marginTop: '6px', fontStyle: 'italic' }}>
                  Lý do ẩn: {rev.lyDoAn}
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
          <div style={{ background: '#ffffff', padding: '24px', borderRadius: '12px', width: '400px' }}>
            <h3 style={{ fontSize: '18px', fontWeight: 800, marginBottom: '12px' }}>Xác nhận ẩn đánh giá</h3>
            <p style={{ fontSize: '13px', color: '#64748b', marginBottom: '12px' }}>
              Vui lòng nhập lý do ẩn đánh giá của khách hàng {selectedReview.tenKhachHang}:
            </p>
            <textarea
              value={hideReason}
              onChange={(e) => setHideReason(e.target.value)}
              placeholder="Lý do ẩn (ví dụ: Chứa ngôn từ không phù hợp)..."
              rows={3}
              style={{
                width: '100%',
                padding: '10px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                fontFamily: 'inherit',
              }}
            />
            <div style={{ display: 'flex', gap: '8px', marginTop: '16px', justifyContent: 'flex-end' }}>
              <button
                onClick={() => setSelectedReview(null)}
                style={{ padding: '8px 16px', borderRadius: '6px', border: '1px solid #cbd5e1', background: '#ffffff', cursor: 'pointer' }}
              >
                Hủy
              </button>
              <button
                onClick={() => toggleVisibility(selectedReview.maDanhGia, true, hideReason)}
                style={{ padding: '8px 16px', borderRadius: '6px', border: 'none', background: '#ef4444', color: '#ffffff', fontWeight: 700, cursor: 'pointer' }}
              >
                Ẩn đánh giá
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
