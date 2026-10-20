import React, { useEffect, useState } from 'react';
import { Modal } from '../../../components/Modal';
import { ImageCropUpload } from '../../../components/ImageCropUpload';
import { LocationSelector } from '../../../components/LocationSelector';
import { BankSelector } from '../../../components/BankSelector';
import { DatePickerInput } from '../../../components/DatePickerInput';
import { Building, Bot, CheckCircle } from 'lucide-react';
import { fetchVietQRBanks, BankItem } from '../../../utils/bankService';

export const VIETNAM_BANKS = [
  'Vietcombank (VCB)',
  'Techcombank (TCB)',
  'MBBank (MB)',
  'VPBank',
  'ACB (Á Châu)',
  'BIDV',
  'VietinBank',
  'Agribank',
  'TPBank',
  'Sacombank',
  'HDBank',
  'VIB',
  'MSB (Hàng Hải)',
  'SHB',
  'MoMo Wallet',
  'ZaloPay',
  'PayOS / Khác',
];

interface UserFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  isEdit?: boolean;
  form: any;
  setForm: (form: any) => void;
  onSubmit: (e: React.FormEvent) => void;
  submitting: boolean;
  ocrNotice: string | null;
  scanningCCCD: boolean;
  handleScanCCCD: (imageSrc: string, side: 'front' | 'back' | 'both') => void;
}

export const UserFormModal: React.FC<UserFormModalProps> = ({
  isOpen,
  onClose,
  title,
  isEdit = false,
  form,
  setForm,
  onSubmit,
  submitting,
  ocrNotice,
  scanningCCCD,
  handleScanCCCD,
}) => {
  const [banks, setBanks] = useState<BankItem[]>([]);

  useEffect(() => {
    fetchVietQRBanks().then((data) => setBanks(data));
  }, []);

  if (!isOpen) return null;

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} maxWidth="680px">
      <form onSubmit={onSubmit}>
        {ocrNotice && (
          <div
            style={{
              padding: '10px 14px',
              background: '#f0fdf4',
              border: '1px solid #86efac',
              borderRadius: '8px',
              color: '#166534',
              fontSize: '13px',
              marginBottom: '16px',
              display: 'flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <CheckCircle size={16} color="#16a34a" /> {ocrNotice}
          </div>
        )}

        {/* Tên Đăng Nhập & Mật Khẩu (nếu thêm mới) */}
        {!isEdit ? (
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div className="form-group">
              <label className="form-label">Tên Đăng Nhập *</label>
              <input
                type="text"
                className="form-control"
                placeholder="VD: user123 hoặc email"
                value={form.tenDangNhap}
                onChange={(e) => setForm({ ...form, tenDangNhap: e.target.value })}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Mật Khẩu *</label>
              <input
                type="password"
                className="form-control"
                placeholder="Nhập mật khẩu..."
                value={form.matKhau}
                onChange={(e) => setForm({ ...form, matKhau: e.target.value })}
                required
              />
            </div>
          </div>
        ) : (
          <div className="form-group">
            <label className="form-label">Tên Đăng Nhập (Không thay đổi)</label>
            <input type="text" className="form-control" value={form.tenDangNhap || ''} disabled />
          </div>
        )}

        {/* Họ tên & Vai trò */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
          <div className="form-group">
            <label className="form-label">Họ & Tên *</label>
            <input
              type="text"
              className="form-control"
              placeholder="VD: Nguyễn Văn A"
              value={form.hoTen}
              onChange={(e) => setForm({ ...form, hoTen: e.target.value })}
              required
            />
          </div>
          <div className="form-group">
            <label className="form-label">Vai Trò Hệ Thống</label>
            <select
              className="form-control"
              value={form.loaiTaiKhoan}
              onChange={(e) => setForm({ ...form, loaiTaiKhoan: e.target.value })}
            >
              <option value="KHACH_HANG">Khách Hàng (KHACH_HANG)</option>
              <option value="CUAN_HANG">Chủ Nhà Hàng (CUAN_HANG)</option>
              <option value="NHAN_VIEN">Nhân Viên (NHAN_VIEN)</option>
              <option value="ADMIN">Quản Trị Viên (ADMIN)</option>
            </select>
          </div>
        </div>

        {/* SĐT, Email, Ngày Sinh */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
          <div className="form-group">
            <label className="form-label">Số Điện Thoại</label>
            <input
              type="text"
              className="form-control"
              placeholder="0901234567"
              value={form.sdt}
              onChange={(e) => setForm({ ...form, sdt: e.target.value })}
            />
          </div>
          <div className="form-group">
            <label className="form-label">Email</label>
            <input
              type="email"
              className="form-control"
              placeholder="user@example.com"
              value={form.email}
              onChange={(e) => setForm({ ...form, email: e.target.value })}
            />
          </div>
          <DatePickerInput
            label="Ngày Sinh KH"
            value={form.ngaySinh}
            onChange={(val) => setForm({ ...form, ngaySinh: val })}
          />
        </div>

        <LocationSelector
          label="Địa Chỉ Liên Hệ / Giao Hàng (Phân Cấp / Cascading Dropdown)"
          value={form.diaChi}
          onChange={(val) => setForm({ ...form, diaChi: val })}
        />

        {/* THÔNG TIN CHỦ QUÁN & NGÂN HÀNG & CCCD KHI CHỌN VAI TRÒ CHỦ NHÀ HÀNG */}
        {form.loaiTaiKhoan === 'CUAN_HANG' && (
          <div
            style={{
              background: '#f8fafc',
              padding: '16px',
              borderRadius: '12px',
              border: '1px solid #e2e8f0',
              marginTop: '16px',
              marginBottom: '16px',
            }}
          >
            <div
              style={{
                fontSize: '14px',
                fontWeight: 700,
                color: '#fc6011',
                marginBottom: '12px',
                display: 'flex',
                alignItems: 'center',
                gap: '6px',
              }}
            >
              <Building size={16} /> Thông Tin Chủ Quán, Ngân Hàng & CCCD 2 Mặt
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div className="form-group">
                <label className="form-label">Tên Nhà Hàng / Quán</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="VD: Phở Bò Gia Truyền"
                  value={form.tenQuan}
                  onChange={(e) => setForm({ ...form, tenQuan: e.target.value })}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Họ Tên Chủ Quán</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="VD: Nguyễn Văn A"
                  value={form.hoTenChuQuan}
                  onChange={(e) => setForm({ ...form, hoTenChuQuan: e.target.value })}
                />
              </div>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div className="form-group">
                <label className="form-label">Số CCCD (12 Số)</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="079201000..."
                  value={form.soCCCD}
                  onChange={(e) => setForm({ ...form, soCCCD: e.target.value })}
                />
              </div>
              <DatePickerInput
                label="Ngày Sinh Chủ Quán"
                value={form.ngaySinhChuQuan}
                onChange={(val) => setForm({ ...form, ngaySinhChuQuan: val })}
              />
            </div>

            <LocationSelector
              label="Địa Chỉ Thường Trú (Theo CCCD)"
              value={form.diaChiThuongTru}
              onChange={(val) => setForm({ ...form, diaChiThuongTru: val })}
            />

            {/* Ngân Hàng Selector với Logo VietQR */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '12px' }}>
              <BankSelector
                label="Tên Ngân Hàng"
                value={form.tenNganHang}
                onChange={(bankName) => setForm({ ...form, tenNganHang: bankName })}
              />
              <div className="form-group">
                <label className="form-label">Số Tài Khoản</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="101010..."
                  value={form.soTaiKhoanNganHang}
                  onChange={(e) => setForm({ ...form, soTaiKhoanNganHang: e.target.value })}
                />
              </div>
              <div className="form-group">
                <label className="form-label">Chủ Tài Khoản</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="CHỦ TÀI KHOẢN"
                  value={form.tenChuTaiKhoan}
                  onChange={(e) => setForm({ ...form, tenChuTaiKhoan: e.target.value })}
                />
              </div>
            </div>

            {/* Upload CCCD 2 Mặt & AI Quét */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px', marginTop: '12px' }}>
              <div>
                <ImageCropUpload
                  label="CCCD Mặt Trước"
                  value={form.cccdMatTruoc}
                  onChange={(url) => setForm({ ...form, cccdMatTruoc: url })}
                  aspectRatio={1.58}
                />
              </div>

              <div>
                <ImageCropUpload
                  label="CCCD Mặt Sau"
                  value={form.cccdMatSau}
                  onChange={(url) => setForm({ ...form, cccdMatSau: url })}
                  aspectRatio={1.58}
                />
              </div>
            </div>

            <button
              type="button"
              className="btn btn-primary"
              style={{
                width: '100%',
                marginTop: '14px',
                background: 'linear-gradient(135deg, #fc6011, #ff7e40)',
                border: 'none',
                fontWeight: 700,
                padding: '10px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: '8px',
                boxShadow: '0 4px 12px rgba(252, 96, 17, 0.25)',
              }}
              onClick={() => handleScanCCCD(form.cccdMatTruoc || form.cccdMatSau, 'both')}
              disabled={scanningCCCD}
            >
              <Bot size={18} /> {scanningCCCD ? 'Đang Quét AI...' : '🤖 AI Quét'}
            </button>
          </div>
        )}

        <ImageCropUpload
          label="Ảnh Đại Diện (Avatar)"
          value={form.avatar}
          onChange={(url) => setForm({ ...form, avatar: url })}
          aspectRatio={1}
        />

        <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
          <button type="button" className="btn btn-outline" onClick={onClose}>Hủy</button>
          <button type="submit" className="btn btn-primary" disabled={submitting}>
            {submitting ? <div className="loading-spinner" /> : isEdit ? 'Lưu Thay Đổi' : 'Tạo Người Dùng'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
