import React from 'react';
import { Modal } from '../../../components/Modal';
import { StatusBadge } from '../../../components/StatusBadge';
import { getImageUrl, handleImageError, isValidImageUrl } from '../../../utils/imageUtils';
import {
  Edit,
  Lock,
  Mail,
  Phone,
  MapPin,
  Calendar,
  Building,
  FileText,
  AlertTriangle,
} from 'lucide-react';

interface UserDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  targetUser: any;
  userDetailData: any;
  formatLockStatus: (u: any) => React.ReactNode;
  onOpenEdit: (u: any) => void;
  onOpenLock: (u: any) => void;
}

export const UserDetailModal: React.FC<UserDetailModalProps> = ({
  isOpen,
  onClose,
  targetUser,
  userDetailData,
  formatLockStatus,
  onOpenEdit,
  onOpenLock,
}) => {
  if (!isOpen || !targetUser) return null;

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Chi Tiết Thông Tin Người Dùng" maxWidth="680px">
      <div>
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '16px',
            padding: '16px',
            background: '#f8fafc',
            borderRadius: '12px',
            marginBottom: '20px',
            border: '1px solid #e2e8f0',
          }}
        >
          <div
            style={{
              width: '64px',
              height: '64px',
              borderRadius: '50%',
              background: '#cbd5e1',
              overflow: 'hidden',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontSize: '24px',
              fontWeight: 700,
              color: '#334155',
            }}
          >
            {isValidImageUrl(userDetailData?.khachHang?.avatar || userDetailData?.cuaHang?.img) ? (
              <img
                src={getImageUrl(userDetailData.khachHang?.avatar || userDetailData.cuaHang?.img)}
                alt="Avatar"
                onError={(e) => handleImageError(e)}
                style={{ width: '100%', height: '100%', objectFit: 'cover' }}
              />
            ) : (
              (targetUser.khachHang?.hoTen || targetUser.tenDangNhap || 'U')[0].toUpperCase()
            )}
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: '18px', fontWeight: 700, color: '#0f172a' }}>
              {userDetailData?.khachHang?.hoTen || userDetailData?.cuaHang?.hoTenChuQuan || targetUser.tenDangNhap}
            </div>
            <div style={{ fontSize: '13px', color: '#64748b', marginTop: '2px' }}>@{targetUser.tenDangNhap}</div>
            <div style={{ display: 'flex', gap: '8px', marginTop: '8px' }}>
              <StatusBadge status={targetUser.loaiTaiKhoan} />
              {formatLockStatus(targetUser)}
            </div>
          </div>
        </div>

        {/* Thông tin cơ bản */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginBottom: '20px' }}>
          <div style={{ padding: '12px', background: '#fff', borderRadius: '8px', border: '1px solid #f1f5f9' }}>
            <div style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 600 }}>Mã Tài Khoản</div>
            <div style={{ fontSize: '14px', fontWeight: 700, color: '#0f172a', marginTop: '4px' }}>#{targetUser.maTaiKhoan}</div>
          </div>

          <div style={{ padding: '12px', background: '#fff', borderRadius: '8px', border: '1px solid #f1f5f9' }}>
            <div style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Calendar size={12} /> {targetUser.loaiTaiKhoan === 'CUAN_HANG' ? 'Ngày Mở Quán' : 'Ngày Sinh'}
            </div>
            <div style={{ fontSize: '14px', fontWeight: 600, color: '#334155', marginTop: '4px' }}>
              {targetUser.loaiTaiKhoan === 'CUAN_HANG'
                ? (userDetailData?.cuaHang?.ngayTao || targetUser.ngayTao
                    ? new Date(userDetailData?.cuaHang?.ngayTao || targetUser.ngayTao).toLocaleDateString('vi-VN')
                    : 'Chưa cập nhật')
                : (userDetailData?.khachHang?.ngaySinh
                    ? new Date(userDetailData.khachHang.ngaySinh).toLocaleDateString('vi-VN')
                    : 'Chưa cập nhật')}
            </div>
          </div>

          <div style={{ padding: '12px', background: '#fff', borderRadius: '8px', border: '1px solid #f1f5f9' }}>
            <div style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Mail size={12} /> Email
            </div>
            <div style={{ fontSize: '13px', fontWeight: 600, color: '#0f172a', marginTop: '4px' }}>
              {userDetailData?.khachHang?.email || targetUser.tenDangNhap}
            </div>
          </div>

          <div style={{ padding: '12px', background: '#fff', borderRadius: '8px', border: '1px solid #f1f5f9' }}>
            <div style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Phone size={12} /> Số Điện Thoại
            </div>
            <div style={{ fontSize: '13px', fontWeight: 600, color: '#0f172a', marginTop: '4px' }}>
              {userDetailData?.khachHang?.sdt || userDetailData?.cuaHang?.sdt || 'Chưa cập nhật'}
            </div>
          </div>
        </div>

        <div style={{ padding: '12px', background: '#fff', borderRadius: '8px', border: '1px solid #f1f5f9', marginBottom: '20px' }}>
          <div style={{ fontSize: '11px', color: '#94a3b8', textTransform: 'uppercase', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '4px' }}>
            <MapPin size={12} /> Địa Chỉ Giao Hàng / Trụ Sở
          </div>
          <div style={{ fontSize: '13px', color: '#334155', marginTop: '4px' }}>
            {userDetailData?.khachHang?.diaChi || userDetailData?.cuaHang?.diaChi || 'Chưa có thông tin địa chỉ'}
          </div>
        </div>

        {/* Thông tin nhà hàng & Chủ quán nếu là Nhà Hàng */}
        {(targetUser.loaiTaiKhoan === 'CUAN_HANG' || userDetailData?.cuaHang) && (
          <div style={{ padding: '16px', background: '#f0f9ff', borderRadius: '12px', border: '1px solid #bae6fd', marginBottom: '20px' }}>
            <div style={{ fontSize: '14px', fontWeight: 700, color: '#0369a1', marginBottom: '12px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Building size={16} /> Thông Tin Chủ Quán & Ngân Hàng Thanh Toán
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', fontSize: '13px', color: '#0f172a' }}>
              <div><strong>Tên Quán:</strong> {userDetailData?.cuaHang?.tenQuan || 'Chưa cập nhật'}</div>
              <div><strong>Họ Tên Chủ Quán:</strong> {userDetailData?.cuaHang?.hoTenChuQuan || userDetailData?.khachHang?.hoTen || '—'}</div>
              <div><strong>Số CCCD:</strong> {userDetailData?.cuaHang?.soCCCD || '—'}</div>
              <div>
                <strong>Ngày Sinh Chủ Quán:</strong>{' '}
                {userDetailData?.cuaHang?.ngaySinhChuQuan ? new Date(userDetailData.cuaHang.ngaySinhChuQuan).toLocaleDateString('vi-VN') : '—'}
              </div>
              <div style={{ gridColumn: 'span 2' }}>
                <strong>Địa Chỉ Thường Trú:</strong> {userDetailData?.cuaHang?.diaChiThuongTru || userDetailData?.khachHang?.diaChi || '—'}
              </div>
            </div>

            {/* Thông tin ngân hàng */}
            <div style={{ marginTop: '12px', paddingTop: '12px', borderTop: '1px dashed #7dd3fc', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px', fontSize: '13px' }}>
              <div><strong style={{ color: '#0284c7' }}>Ngân Hàng:</strong> {userDetailData?.cuaHang?.tenNganHang || 'Chưa liên kết'}</div>
              <div><strong style={{ color: '#0284c7' }}>Số Tài Khoản:</strong> {userDetailData?.cuaHang?.soTaiKhoanNganHang || '—'}</div>
              <div style={{ gridColumn: 'span 2' }}><strong style={{ color: '#0284c7' }}>Tên Chủ Tài Khoản:</strong> {userDetailData?.cuaHang?.tenChuTaiKhoan || '—'}</div>
            </div>

            {/* Ảnh CCCD 2 Mặt */}
            <div style={{ marginTop: '14px' }}>
              <div style={{ fontSize: '12px', fontWeight: 700, color: '#0369a1', marginBottom: '8px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                <FileText size={14} /> Ảnh CCCD 2 Mặt
              </div>
              <div style={{ display: 'flex', gap: '12px' }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '11px', color: '#64748b', marginBottom: '4px' }}>Mặt Trước CCCD:</div>
                  {getImageUrl(userDetailData?.cuaHang?.cccdMatTruoc) ? (
                    <img
                      src={getImageUrl(userDetailData.cuaHang.cccdMatTruoc)}
                      alt="CCCD Trước"
                      onError={(e) => handleImageError(e)}
                      style={{ width: '100%', height: '120px', objectFit: 'contain', background: '#f8fafc', borderRadius: '8px', border: '1px solid #cbd5e1' }}
                    />
                  ) : (
                    <div style={{ width: '100%', height: '120px', background: '#e2e8f0', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', color: '#94a3b8' }}>Chưa có ảnh</div>
                  )}
                </div>

                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: '11px', color: '#64748b', marginBottom: '4px' }}>Mặt Sau CCCD:</div>
                  {getImageUrl(userDetailData?.cuaHang?.cccdMatSau) ? (
                    <img
                      src={getImageUrl(userDetailData.cuaHang.cccdMatSau)}
                      alt="CCCD Sau"
                      onError={(e) => handleImageError(e)}
                      style={{ width: '100%', height: '120px', objectFit: 'contain', background: '#f8fafc', borderRadius: '8px', border: '1px solid #cbd5e1' }}
                    />
                  ) : (
                    <div style={{ width: '100%', height: '120px', background: '#e2e8f0', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', color: '#94a3b8' }}>Chưa có ảnh</div>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Chi tiết khóa tài khoản nếu có */}
        {(targetUser.trangThai === 'KHOA_VINH_VIEN' || targetUser.trangThai === 'KHOA_TAM_THOI' || targetUser.khoaDenNgay) && (
          <div style={{ padding: '14px', background: '#fef2f2', borderRadius: '10px', border: '1px solid #fecaca', marginBottom: '20px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontWeight: 700, color: '#991b1b', marginBottom: '6px' }}>
              <AlertTriangle size={16} /> Thông Tin Khóa Tài Khoản
            </div>
            <div style={{ fontSize: '13px', color: '#7f1d1d' }}>
              Trạng thái: <strong>{targetUser.trangThai === 'KHOA_VINH_VIEN' ? 'Khóa vĩnh viễn' : 'Tạm khóa'}</strong>
            </div>
            {targetUser.khoaDenNgay && (
              <div style={{ fontSize: '13px', color: '#7f1d1d', marginTop: '2px' }}>
                Thời hạn mở khóa: <strong>{new Date(targetUser.khoaDenNgay).toLocaleString('vi-VN')}</strong>
              </div>
            )}
            {targetUser.lyDoKhoa && (
              <div style={{ fontSize: '13px', color: '#7f1d1d', marginTop: '4px' }}>
                Lý do: <em>"{targetUser.lyDoKhoa}"</em>
              </div>
            )}
          </div>
        )}

        {/* Thống kê đơn hàng nếu có */}
        {userDetailData?.orderStats && (
          <div style={{ display: 'flex', gap: '12px', padding: '12px', background: '#f0fdf4', borderRadius: '10px', border: '1px solid #bbf7d0', marginBottom: '20px' }}>
            <div style={{ flex: 1, textAlign: 'center' }}>
              <div style={{ fontSize: '11px', color: '#166534', fontWeight: 600 }}>TỔNG ĐƠN ĐÃ ĐẶT</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#15803d' }}>{userDetailData.orderStats.totalOrders} đơn</div>
            </div>
            <div style={{ flex: 1, textAlign: 'center', borderLeft: '1px solid #cbd5e1' }}>
              <div style={{ fontSize: '11px', color: '#166534', fontWeight: 600 }}>TỔNG CHI TIÊU</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#15803d' }}>
                {(userDetailData.orderStats.totalSpent || 0).toLocaleString('vi-VN')}đ
              </div>
            </div>
          </div>
        )}

        <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px', gap: '8px' }}>
          <button className="btn btn-outline" onClick={onClose}>Đóng</button>
          <button className="btn btn-outline" onClick={() => { onClose(); onOpenEdit(targetUser); }}>
            <Edit size={14} /> Chỉnh Sửa
          </button>
          <button className="btn btn-primary" onClick={() => { onClose(); onOpenLock(targetUser); }}>
            <Lock size={14} /> Khóa / Mở Khóa
          </button>
        </div>
      </div>
    </Modal>
  );
};
