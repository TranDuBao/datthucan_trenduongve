import React, { useState, useEffect } from 'react';
import { Star, MessageSquare, Search, Filter, CheckCircle2, AlertCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { API_BASE_URL } from '../../api/apiClient';
import { getImageUrl, handleImageError } from '../../utils/imageUtils';

interface Review {
  maDanhGia: number;
  maDonHang: number;
  maKhachHang: number;
  tenKhachHang: string;
  soLuongSao: number;
  nhanXet: string;
  phanHoi?: string;
  ngayPhanHoi?: string;
  ngayNhanXet: string;
  hinhAnh?: string;
}

export const RestaurantReviews: React.FC = () => {
  const { token, user } = useAuth();
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [starFilter, setStarFilter] = useState<number | 'ALL'>('ALL');
  const [replyingReviewId, setReplyingReviewId] = useState<number | null>(null);
  const [replyText, setReplyText] = useState('');
  const [submittingReply, setSubmittingReply] = useState(false);
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const fetchReviews = async () => {
    try {
      setLoading(true);
      // Fetch store profile to get maQuan
      const profileRes = await fetch(`${API_BASE_URL}/restaurant/profile`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const profileJson = await profileRes.json();
      const storeId = profileJson.data?.maQuan;

      if (!storeId) {
        setReviews([]);
        return;
      }

      const res = await fetch(`${API_BASE_URL}/restaurants/${storeId}/reviews?limit=50`, {
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

  const handleSendReply = async (reviewId: number) => {
    if (!replyText.trim()) return;
    try {
      setSubmittingReply(true);
      const res = await fetch(`${API_BASE_URL}/reviews/${reviewId}/reply`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ reply: replyText.trim() }),
      });
      const json = await res.json();
      if (json.status === 'success') {
        setNotification({ type: 'success', message: 'Phản hồi đánh giá thành công!' });
        setReplyingReviewId(null);
        setReplyText('');
        fetchReviews();
      } else {
        setNotification({ type: 'error', message: json.message || 'Lỗi khi gửi phản hồi' });
      }
    } catch (e) {
      setNotification({ type: 'error', message: 'Lỗi mạng khi kết nối máy chủ' });
    } finally {
      setSubmittingReply(false);
    }
  };

  const filteredReviews = reviews.filter((r) => {
    if (starFilter === 'ALL') return true;
    return r.soLuongSao === starFilter;
  });

  return (
    <div className="page-content" style={{ padding: '24px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 800, color: '#1e293b' }}>Đánh Giá Từ Khách Hàng</h1>
          <p style={{ fontSize: '14px', color: '#64748b' }}>Xem và phản hồi ý kiến đánh giá của khách sau khi nhận món</p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          {['ALL', 5, 4, 3, 2, 1].map((star) => (
            <button
              key={String(star)}
              onClick={() => setStarFilter(star as any)}
              style={{
                padding: '6px 12px',
                borderRadius: '8px',
                border: '1px solid #e2e8f0',
                background: starFilter === star ? '#fc6011' : '#ffffff',
                color: starFilter === star ? '#ffffff' : '#475467',
                fontWeight: 600,
                fontSize: '13px',
                cursor: 'pointer',
              }}
            >
              {star === 'ALL' ? 'Tất cả' : `${star}★`}
            </button>
          ))}
        </div>
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
        <div style={{ padding: '40px', textAlign: 'center', color: '#64748b' }}>Đang tải đánh giá...</div>
      ) : filteredReviews.length === 0 ? (
        <div style={{ padding: '40px', textAlign: 'center', color: '#64748b', background: '#ffffff', borderRadius: '12px' }}>
          Chưa có đánh giá nào phù hợp
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {filteredReviews.map((rev) => (
            <div
              key={rev.maDanhGia}
              style={{
                background: '#ffffff',
                padding: '20px',
                borderRadius: '12px',
                border: '1px solid #e2e8f0',
                boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
              }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
                <div>
                  <div style={{ fontWeight: 700, fontSize: '15px', color: '#1e293b' }}>
                    {rev.tenKhachHang || 'Khách hàng'} <span style={{ color: '#94a3b8', fontSize: '13px', fontWeight: 400 }}>(Đơn #DH{rev.maDonHang})</span>
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
                <div style={{ fontSize: '12px', color: '#94a3b8' }}>
                  {rev.ngayNhanXet ? new Date(rev.ngayNhanXet).toLocaleDateString('vi-VN') : ''}
                </div>
              </div>

              {rev.nhanXet && (
                <p style={{ fontSize: '14px', color: '#334155', margin: '8px 0 12px 0' }}>{rev.nhanXet}</p>
              )}

              {rev.hinhAnh && (
                <div style={{ marginBottom: '12px' }}>
                  <img
                    src={getImageUrl(rev.hinhAnh)}
                    alt="Hình ảnh đánh giá"
                    style={{ maxWidth: '140px', maxHeight: '140px', objectFit: 'cover', borderRadius: '8px', border: '1px solid #e2e8f0' }}
                    onError={handleImageError}
                  />
                </div>
              )}

              {rev.phanHoi ? (
                <div
                  style={{
                    background: '#f8fafc',
                    padding: '12px',
                    borderRadius: '8px',
                    borderLeft: '4px solid #fc6011',
                    marginTop: '12px',
                  }}
                >
                  <div style={{ fontSize: '12px', fontWeight: 700, color: '#fc6011' }}>Phản hồi của quán:</div>
                  <div style={{ fontSize: '13px', color: '#475569', marginTop: '2px' }}>{rev.phanHoi}</div>
                </div>
              ) : replyingReviewId === rev.maDanhGia ? (
                <div style={{ marginTop: '12px' }}>
                  <textarea
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    placeholder="Nhập nội dung phản hồi tới khách hàng..."
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
                  <div style={{ display: 'flex', gap: '8px', marginTop: '8px', justifyContent: 'flex-end' }}>
                    <button
                      onClick={() => setReplyingReviewId(null)}
                      style={{ padding: '6px 12px', borderRadius: '6px', border: '1px solid #cbd5e1', background: '#ffffff', cursor: 'pointer' }}
                    >
                      Hủy
                    </button>
                    <button
                      onClick={() => handleSendReply(rev.maDanhGia)}
                      disabled={submittingReply}
                      style={{ padding: '6px 16px', borderRadius: '6px', border: 'none', background: '#fc6011', color: '#ffffff', fontWeight: 600, cursor: 'pointer' }}
                    >
                      {submittingReply ? 'Đang gửi...' : 'Gửi phản hồi'}
                    </button>
                  </div>
                </div>
              ) : (
                <button
                  onClick={() => {
                    setReplyingReviewId(rev.maDanhGia);
                    setReplyText('');
                  }}
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    padding: '6px 12px',
                    borderRadius: '6px',
                    border: '1px solid #e2e8f0',
                    background: '#f8fafc',
                    color: '#fc6011',
                    fontWeight: 600,
                    fontSize: '13px',
                    cursor: 'pointer',
                    marginTop: '8px',
                  }}
                >
                  <MessageSquare size={14} /> Phản hồi
                </button>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
