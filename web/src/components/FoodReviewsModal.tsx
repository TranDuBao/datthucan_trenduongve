import React from 'react';
import { X, Star, ChevronLeft, ChevronRight } from 'lucide-react';
import { getImageUrl, handleImageError } from '../utils/imageUtils';

interface FoodReviewsModalProps {
  isOpen: boolean;
  foodName: string;
  maMonAn: number | null;
  reviewsData: any;
  reviewsLoading: boolean;
  reviewsPage: number;
  onClose: () => void;
  onChangePage: (maMonAn: number, foodName: string, newPage: number) => void;
}

export const FoodReviewsModal: React.FC<FoodReviewsModalProps> = ({
  isOpen,
  foodName,
  maMonAn,
  reviewsData,
  reviewsLoading,
  reviewsPage,
  onClose,
  onChangePage,
}) => {
  if (!isOpen) return null;

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        background: 'rgba(0,0,0,0.45)',
        zIndex: 9999,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '16px',
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div
        style={{
          background: '#fff',
          borderRadius: '16px',
          width: '100%',
          maxWidth: '640px',
          maxHeight: '90vh',
          display: 'flex',
          flexDirection: 'column',
          overflow: 'hidden',
          boxShadow: '0 20px 60px rgba(0,0,0,0.2)',
        }}
      >
        {/* Header */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            padding: '20px 24px',
            borderBottom: '1px solid #e2e8f0',
          }}
        >
          <div>
            <h3 style={{ margin: 0, fontSize: '17px', fontWeight: 700, color: '#0f172a' }}>
              Đánh Giá Món Ăn
            </h3>
            <p style={{ margin: '2px 0 0', fontSize: '13px', color: '#64748b' }}>{foodName}</p>
          </div>
          <button
            onClick={onClose}
            style={{
              background: '#f1f5f9',
              border: 'none',
              borderRadius: '50%',
              width: '34px',
              height: '34px',
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <X size={16} color="#64748b" />
          </button>
        </div>

        {/* Body */}
        <div style={{ overflowY: 'auto', flex: 1, padding: '20px 24px' }}>
          {reviewsLoading ? (
            <div style={{ textAlign: 'center', padding: '40px', color: '#94a3b8' }}>
              Đang tải đánh giá...
            </div>
          ) : !reviewsData ? (
            <div style={{ textAlign: 'center', padding: '40px', color: '#94a3b8' }}>
              Không thể tải đánh giá.
            </div>
          ) : (
            <>
              {/* Summary */}
              <div
                style={{
                  display: 'flex',
                  gap: '24px',
                  alignItems: 'center',
                  padding: '16px',
                  background: '#fef9ee',
                  borderRadius: '12px',
                  marginBottom: '20px',
                }}
              >
                <div style={{ textAlign: 'center', minWidth: '70px' }}>
                  <div style={{ fontSize: '36px', fontWeight: 800, color: '#f59e0b', lineHeight: 1 }}>
                    {reviewsData.summary.avg > 0 ? reviewsData.summary.avg.toFixed(1) : '—'}
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'center', gap: '2px', marginTop: '4px' }}>
                    {[1, 2, 3, 4, 5].map((s) => (
                      <Star
                        key={s}
                        size={14}
                        style={{
                          display: 'inline-block',
                          verticalAlign: '-1px',
                          color: s <= Math.round(reviewsData.summary.avg) ? '#f59e0b' : '#d1d5db',
                          fill: s <= Math.round(reviewsData.summary.avg) ? '#f59e0b' : 'none',
                        }}
                      />
                    ))}
                  </div>
                  <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '4px' }}>
                    {reviewsData.summary.total} đánh giá
                  </div>
                </div>
                <div style={{ flex: 1 }}>
                  {[5, 4, 3, 2, 1].map((star) => {
                    const count = reviewsData.summary.breakdown[star] || 0;
                    const pct =
                      reviewsData.summary.total > 0
                        ? (count / reviewsData.summary.total) * 100
                        : 0;
                    return (
                      <div
                        key={star}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '8px',
                          marginBottom: '5px',
                        }}
                      >
                        <span style={{ fontSize: '12px', color: '#64748b', width: '12px', textAlign: 'right' }}>
                          {star}
                        </span>
                        <Star
                          size={12}
                          style={{
                            display: 'inline-block',
                            verticalAlign: '-1px',
                            color: '#f59e0b',
                            fill: '#f59e0b',
                          }}
                        />
                        <div
                          style={{
                            flex: 1,
                            background: '#e2e8f0',
                            borderRadius: '4px',
                            height: '8px',
                            overflow: 'hidden',
                          }}
                        >
                          <div
                            style={{
                              width: `${pct}%`,
                              background: '#f59e0b',
                              height: '100%',
                              borderRadius: '4px',
                              transition: 'width 0.4s',
                            }}
                          />
                        </div>
                        <span style={{ fontSize: '11px', color: '#94a3b8', width: '24px' }}>
                          {count}
                        </span>
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
                    <div
                      key={rv.maDanhGia}
                      style={{ border: '1px solid #e2e8f0', borderRadius: '10px', padding: '14px' }}
                    >
                      <div
                        style={{
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'flex-start',
                          marginBottom: '8px',
                        }}
                      >
                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                          <div
                            style={{
                              width: '36px',
                              height: '36px',
                              borderRadius: '50%',
                              background: '#f1f5f9',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              fontSize: '15px',
                              fontWeight: 700,
                              color: '#fc6011',
                              overflow: 'hidden',
                              flexShrink: 0,
                            }}
                          >
                            {rv.customerAvatar ? (
                              <img
                                src={rv.customerAvatar}
                                alt=""
                                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
                              />
                            ) : (
                              rv.customerName?.charAt(0).toUpperCase() || 'U'
                            )}
                          </div>
                          <div>
                            <div style={{ fontWeight: 700, fontSize: '13px', color: '#0f172a' }}>
                              {rv.customerName}
                            </div>
                            <div style={{ display: 'flex', gap: '2px' }}>
                              {[1, 2, 3, 4, 5].map((s) => (
                                <Star
                                  key={s}
                                  size={13}
                                  style={{
                                    display: 'inline-block',
                                    verticalAlign: '-1px',
                                    color: s <= rv.soLuongSao ? '#f59e0b' : '#d1d5db',
                                    fill: s <= rv.soLuongSao ? '#f59e0b' : 'none',
                                  }}
                                />
                              ))}
                            </div>
                          </div>
                        </div>
                        <span style={{ fontSize: '11px', color: '#94a3b8' }}>
                          {new Date(rv.ngayNhanXet).toLocaleDateString('vi-VN')}
                        </span>
                      </div>
                      {rv.nhanXet && (
                        <p style={{ margin: '0 0 8px', fontSize: '13px', color: '#334155', lineHeight: 1.5 }}>
                          {rv.nhanXet}
                        </p>
                      )}
                      {rv.hinhAnh && (
                        <img
                          src={getImageUrl(rv.hinhAnh)}
                          alt=""
                          style={{ maxWidth: '120px', borderRadius: '8px', marginBottom: '8px' }}
                          onError={handleImageError}
                        />
                      )}
                      {rv.phanHoi && (
                        <div
                          style={{
                            background: '#f8fafc',
                            border: '1px solid #e2e8f0',
                            borderRadius: '8px',
                            padding: '10px 12px',
                            marginTop: '8px',
                          }}
                        >
                          <div
                            style={{
                              fontSize: '11px',
                              fontWeight: 700,
                              color: '#fc6011',
                              marginBottom: '4px',
                            }}
                          >
                            Phản hồi của quán:
                          </div>
                          <p style={{ margin: 0, fontSize: '13px', color: '#475569' }}>
                            {rv.phanHoi}
                          </p>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              )}

              {/* Pagination */}
              {reviewsData.totalPages > 1 && (
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'center',
                    alignItems: 'center',
                    gap: '12px',
                    marginTop: '20px',
                  }}
                >
                  <button
                    onClick={() =>
                      onChangePage(maMonAn!, foodName, reviewsPage - 1)
                    }
                    disabled={reviewsPage <= 1}
                    style={{
                      background: '#f1f5f9',
                      border: 'none',
                      borderRadius: '8px',
                      padding: '6px 12px',
                      cursor: reviewsPage <= 1 ? 'not-allowed' : 'pointer',
                      opacity: reviewsPage <= 1 ? 0.5 : 1,
                    }}
                  >
                    <ChevronLeft size={16} />
                  </button>
                  <span style={{ fontSize: '13px', color: '#64748b' }}>
                    {reviewsPage} / {reviewsData.totalPages}
                  </span>
                  <button
                    onClick={() =>
                      onChangePage(maMonAn!, foodName, reviewsPage + 1)
                    }
                    disabled={reviewsPage >= reviewsData.totalPages}
                    style={{
                      background: '#f1f5f9',
                      border: 'none',
                      borderRadius: '8px',
                      padding: '6px 12px',
                      cursor: reviewsPage >= reviewsData.totalPages ? 'not-allowed' : 'pointer',
                      opacity: reviewsPage >= reviewsData.totalPages ? 0.5 : 1,
                    }}
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
  );
};
