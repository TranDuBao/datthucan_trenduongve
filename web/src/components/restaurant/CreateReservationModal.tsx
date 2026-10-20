import React, { useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { X, Calendar, Clock, User, Phone, Users, FileText, Utensils } from 'lucide-react';

interface CreateReservationModalProps {
  isOpen: boolean;
  onClose: () => void;
  tables: any[];
  onSuccess: () => void;
}

export const CreateReservationModal: React.FC<CreateReservationModalProps> = ({
  isOpen,
  onClose,
  tables,
  onSuccess,
}) => {
  const [maBan, setMaBan] = useState<number | string>('');
  const [date, setDate] = useState<string>('');
  const [startTime, setStartTime] = useState<string>('18:00');
  const [endTime, setEndTime] = useState<string>('19:30');
  const [soNguoi, setSoNguoi] = useState<number>(2);
  const [tenKhachHang, setTenKhachHang] = useState<string>('');
  const [sdtKhachHang, setSdtKhachHang] = useState<string>('');
  const [ghiChu, setGhiChu] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const resetForm = () => {
    setMaBan('');
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    setDate(`${yyyy}-${mm}-${dd}`);
    setStartTime('18:00');
    setEndTime('19:30');
    setSoNguoi(2);
    setTenKhachHang('');
    setSdtKhachHang('');
    setGhiChu('');
    setError(null);
  };

  React.useEffect(() => {
    if (isOpen) {
      resetForm();
    }
  }, [isOpen]);

  if (!isOpen) return null;


  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!maBan) {
      setError('Vui lòng chọn bàn cần đặt');
      return;
    }
    if (!date || !startTime || !endTime) {
      setError('Vui lòng chọn đầy đủ ngày và giờ đặt');
      return;
    }
    if (soNguoi < 1) {
      setError('Số người phải từ 1 trở lên');
      return;
    }
    if (!tenKhachHang.trim() || !sdtKhachHang.trim()) {
      setError('Vui lòng điền tên và số điện thoại khách hàng');
      return;
    }

    const startObj = new Date(`${date}T${startTime}:00`);
    const endObj = new Date(`${date}T${endTime}:00`);

    if (isNaN(startObj.getTime()) || isNaN(endObj.getTime())) {
      setError('Thời gian bắt đầu hoặc kết thúc không hợp lệ');
      return;
    }

    if (startObj >= endObj) {
      setError('Giờ kết thúc phải sau giờ bắt đầu');
      return;
    }

    const thoiGianBatDau = startObj.toISOString();
    const thoiGianKetThuc = endObj.toISOString();

    try {
      setLoading(true);
      await apiFetch('/restaurant/reservations', {
        method: 'POST',
        body: JSON.stringify({
          maBan: Number(maBan),
          thoiGianBatDau,
          thoiGianKetThuc,
          soNguoi,
          tenKhachHang: tenKhachHang.trim(),
          sdtKhachHang: sdtKhachHang.trim(),
          ghiChu: ghiChu.trim(),
        }),
      });

      resetForm();
      onSuccess();
      onClose();
    } catch (err: any) {
      setError(err.message || 'Không thể tạo lượt đặt bàn');
    } finally {
      setLoading(false);
    }
  };


  const activeTables = Array.isArray(tables) ? tables.filter((t) => t?.trangThai !== 'TAM_NGUNG') : [];


  return (
    <div
      className="modal-backdrop"
      onClick={onClose}
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(15, 23, 42, 0.65)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1200,
        backdropFilter: 'blur(3px)',
        padding: '20px',
      }}
    >
      <div
        className="modal-content"
        onClick={(e) => e.stopPropagation()}
        style={{
          maxWidth: '560px',
          width: '100%',
          maxHeight: '90vh',
          overflowY: 'auto',
          borderRadius: '16px',
          padding: '24px',
          background: '#ffffff',
          boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
        }}
      >

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px', borderBottom: '1px solid #e2e8f0', paddingBottom: '12px' }}>
          <h3 style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: '#1e293b' }}>
            Thêm Lượt Đặt Bàn Mới
          </h3>
          <button onClick={onClose} style={{ background: '#f1f5f9', border: 'none', borderRadius: '50%', width: '32px', height: '32px', cursor: 'pointer', color: '#64748b' }}>
            <X size={18} />
          </button>
        </div>

        {error && (
          <div style={{ background: '#fef2f2', color: '#dc2626', border: '1px solid #fecaca', padding: '10px 14px', borderRadius: '8px', fontSize: '14px', marginBottom: '16px' }}>
            ⚠️ {error}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {/* Table Select */}
          <div>
            <label style={{ fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Utensils size={15} color="#fc6011" /> Chọn bàn *
            </label>
            <select
              value={maBan}
              onChange={(e) => setMaBan(e.target.value)}
              className="form-control"
              style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
            >
              <option value="">-- Chọn bàn phục vụ --</option>
              {activeTables.map((t) => (
                <option key={t.maBan} value={t.maBan}>
                  {t.tenBan} (Sức chứa: {t.sucChua} người)
                </option>
              ))}
            </select>
          </div>

          {/* Date & Time */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '10px' }}>
            <div>
              <label style={{ fontSize: '12px', fontWeight: 600, color: '#475569', marginBottom: '4px', display: 'block' }}>Ngày đặt *</label>
              <input
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="form-control"
                style={{ width: '100%', padding: '9px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
              />
            </div>

            <div>
              <label style={{ fontSize: '12px', fontWeight: 600, color: '#475569', marginBottom: '4px', display: 'block' }}>Giờ đến (24h) *</label>
              <select
                value={startTime}
                onChange={(e) => setStartTime(e.target.value)}
                className="form-control"
                style={{ width: '100%', padding: '9px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
              >
                {Array.from({ length: 35 }, (_, i) => {
                  const hour = Math.floor(i / 2) + 6;
                  const min = i % 2 === 0 ? '00' : '30';
                  const hStr = hour < 10 ? `0${hour}` : `${hour}`;
                  const timeVal = `${hStr}:${min}`;
                  return (
                    <option key={timeVal} value={timeVal}>
                      {timeVal}
                    </option>
                  );
                })}
              </select>
            </div>

            <div>
              <label style={{ fontSize: '12px', fontWeight: 600, color: '#475569', marginBottom: '4px', display: 'block' }}>Giờ kết thúc (24h) *</label>
              <select
                value={endTime}
                onChange={(e) => setEndTime(e.target.value)}
                className="form-control"
                style={{ width: '100%', padding: '9px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
              >
                {Array.from({ length: 35 }, (_, i) => {
                  const hour = Math.floor(i / 2) + 6;
                  const min = i % 2 === 0 ? '00' : '30';
                  const hStr = hour < 10 ? `0${hour}` : `${hour}`;
                  const timeVal = `${hStr}:${min}`;
                  return (
                    <option key={timeVal} value={timeVal}>
                      {timeVal}
                    </option>
                  );
                })}
              </select>
            </div>
          </div>


          {/* Guests Count */}
          <div>
            <label style={{ fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '6px', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Users size={15} color="#16a34a" /> Số lượng khách *
            </label>
            <input
              type="number"
              min={1}
              max={50}
              value={soNguoi}
              onChange={(e) => setSoNguoi(Number(e.target.value))}
              className="form-control"
              style={{ width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
            />
          </div>

          {/* Customer Info */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
            <div>
              <label style={{ fontSize: '12px', fontWeight: 600, color: '#475569', marginBottom: '4px', display: 'block' }}>Tên khách hàng *</label>
              <input
                type="text"
                placeholder="Nguyễn Văn A"
                value={tenKhachHang}
                onChange={(e) => setTenKhachHang(e.target.value)}
                className="form-control"
                style={{ width: '100%', padding: '9px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
              />
            </div>
            <div>
              <label style={{ fontSize: '12px', fontWeight: 600, color: '#475569', marginBottom: '4px', display: 'block' }}>Số điện thoại *</label>
              <input
                type="text"
                placeholder="0901234567"
                value={sdtKhachHang}
                onChange={(e) => setSdtKhachHang(e.target.value)}
                className="form-control"
                style={{ width: '100%', padding: '9px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
              />
            </div>
          </div>

          {/* Notes */}
          <div>
            <label style={{ fontSize: '12px', fontWeight: 600, color: '#475569', marginBottom: '4px', display: 'block' }}>Ghi chú (Tùy chọn)</label>
            <textarea
              rows={2}
              placeholder="Ví dụ: Đặt góc gần cửa sổ, ăn mừng sinh nhật..."
              value={ghiChu}
              onChange={(e) => setGhiChu(e.target.value)}
              className="form-control"
              style={{ width: '100%', padding: '8px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '12px' }}>
            <button type="button" onClick={onClose} className="btn" style={{ background: '#f1f5f9', color: '#475569' }}>
              Hủy bỏ
            </button>
            <button type="submit" disabled={loading} className="btn btn-primary" style={{ background: '#fc6011', borderColor: '#fc6011' }}>
              {loading ? 'Đang tạo...' : 'Lưu Đặt Bàn'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
