import React from 'react';
import {
  Calendar,
  X,
  Clock,
  ShoppingBag,
  UtensilsCrossed,
} from 'lucide-react';

interface DailyRevenueDetailModalProps {
  selectedChartDate: any;
  ordersList: any[];
  onClose: () => void;
  formatVND: (amount: number) => string;
}

export const DailyRevenueDetailModal: React.FC<DailyRevenueDetailModalProps> = ({
  selectedChartDate,
  ordersList,
  onClose,
  formatVND,
}) => {
  if (!selectedChartDate) return null;

  const filteredDateOrders = ordersList.filter((ord: any) => {
    if (!ord.thoiGianDat) return false;
    const ordDate = new Date(ord.thoiGianDat);
    const ordDayStr = `${ordDate.getDate()}/${ordDate.getMonth() + 1}`;
    return (
      ordDayStr === selectedChartDate.label ||
      (selectedChartDate.fullDate && ord.thoiGianDat.includes(selectedChartDate.fullDate))
    );
  });

  const dateDishesMap: Record<string, { tenMonAn: string; img: string; donGia: number; soLuong: number; totalRev: number }> = {};
  filteredDateOrders.forEach((ord: any) => {
    if (ord.items && Array.isArray(ord.items)) {
      ord.items.forEach((it: any) => {
        const key = it.tenMonAn || `Mon_${it.maMonAn}`;
        if (!dateDishesMap[key]) {
          dateDishesMap[key] = {
            tenMonAn: it.tenMonAn || 'Món ăn',
            img: it.img || '',
            donGia: Number(it.donGia || 0),
            soLuong: 0,
            totalRev: 0,
          };
        }
        const qty = Number(it.soLuong || 1);
        dateDishesMap[key].soLuong += qty;
        dateDishesMap[key].totalRev += Number(it.donGia || 0) * qty;
      });
    }
  });
  const dateDishesList = Object.values(dateDishesMap);

  return (
    <div
      style={{
        position: 'fixed',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(15, 23, 42, 0.65)',
        backdropFilter: 'blur(4px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 1000,
        padding: '20px',
      }}
    >
      <div
        style={{
          background: '#ffffff',
          borderRadius: '20px',
          maxWidth: '820px',
          width: '100%',
          maxHeight: '88vh',
          overflowY: 'auto',
          boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)',
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        {/* Modal Header */}
        <div
          style={{
            padding: '18px 24px',
            borderBottom: '1px solid #e2e8f0',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            background: '#f8fafc',
            borderRadius: '20px 20px 0 0',
          }}
        >
          <div>
            <h3 style={{ margin: 0, fontSize: '17px', fontWeight: 800, color: '#0f172a', display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Calendar color="#fc6011" size={20} />
              Chi Tiết Bán Hàng Ngày {selectedChartDate.label} ({selectedChartDate.fullDate || ''})
            </h3>
          </div>
          <button
            onClick={onClose}
            style={{
              background: 'none',
              border: 'none',
              cursor: 'pointer',
              padding: '6px',
              color: '#64748b',
              borderRadius: '50%',
            }}
          >
            <X size={20} />
          </button>
        </div>

        <div style={{ padding: '24px' }}>
          {/* Daily Summary Banner */}
          <div
            style={{
              background: 'linear-gradient(135deg, #fff4ee 0%, #ffedd5 100%)',
              padding: '16px 20px',
              borderRadius: '14px',
              border: '1px solid #fed7aa',
              marginBottom: '24px',
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
            }}
          >
            <div>
              <div style={{ fontSize: '12px', color: '#c2410c', fontWeight: 700, textTransform: 'uppercase' }}>DOANH THU TRONG NGÀY</div>
              <div style={{ fontSize: '22px', fontWeight: 900, color: '#fc6011', marginTop: '2px' }}>
                {formatVND(selectedChartDate.revenue)}
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: '12px', color: '#475569', fontWeight: 700 }}>TỔNG ĐƠN HÀNG</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginTop: '2px' }}>
                {filteredDateOrders.length} đơn hàng
              </div>
            </div>
          </div>

          {/* Section 1: Dishes Sold Breakdown */}
          <div style={{ marginBottom: '28px' }}>
            <h4 style={{ margin: '0 0 12px 0', fontSize: '14px', fontWeight: 800, color: '#0f172a', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <UtensilsCrossed size={16} color="#fc6011" />
              Danh Sách Món Ăn Đã Bán Trong Ngày ({dateDishesList.length} món)
            </h4>
            {dateDishesList.length === 0 ? (
              <div style={{ padding: '20px', textAlign: 'center', background: '#f8fafc', borderRadius: '10px', color: '#64748b', fontSize: '13px' }}>
                Chưa ghi nhận món ăn phát sinh trong ngày này
              </div>
            ) : (
              <table className="data-table" style={{ width: '100%', fontSize: '13px' }}>
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Món Ăn</th>
                    <th>Đơn Giá</th>
                    <th>Số Lượng Bán</th>
                    <th style={{ textAlign: 'right' }}>Thành Tiền</th>
                  </tr>
                </thead>
                <tbody>
                  {dateDishesList.map((d: any, idx: number) => (
                    <tr key={idx}>
                      <td style={{ fontWeight: 700 }}>{idx + 1}</td>
                      <td style={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: '10px' }}>
                        {d.img ? (
                          <img src={d.img} alt={d.tenMonAn} style={{ width: '32px', height: '32px', borderRadius: '6px', objectFit: 'cover' }} />
                        ) : (
                          <div style={{ width: '32px', height: '32px', borderRadius: '6px', background: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            <UtensilsCrossed size={16} color="#94a3b8" />
                          </div>
                        )}
                        {d.tenMonAn}
                      </td>
                      <td>{formatVND(d.donGia)}</td>
                      <td style={{ fontWeight: 800 }}>{d.soLuong} món</td>
                      <td style={{ fontWeight: 800, color: '#fc6011', textAlign: 'right' }}>{formatVND(d.totalRev)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* Section 2: Orders Breakdown */}
          <div>
            <h4 style={{ margin: '0 0 12px 0', fontSize: '14px', fontWeight: 800, color: '#0f172a', display: 'flex', alignItems: 'center', gap: '6px' }}>
              <ShoppingBag size={16} color="#fc6011" />
              Danh Sách Đơn Hàng Ngày {selectedChartDate.label} ({filteredDateOrders.length} đơn)
            </h4>
            {filteredDateOrders.length === 0 ? (
              <div style={{ padding: '20px', textAlign: 'center', background: '#f8fafc', borderRadius: '10px', color: '#64748b', fontSize: '13px' }}>
                Chưa có đơn hàng chi tiết trong ngày này
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                {filteredDateOrders.map((ord: any) => (
                  <div key={ord.maDonHang} style={{ border: '1px solid #e2e8f0', borderRadius: '12px', padding: '16px', background: '#ffffff', boxShadow: '0 1px 3px rgba(0,0,0,0.04)' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
                      <span style={{ fontWeight: 800, color: '#fc6011', fontSize: '15px' }}>Mã Đơn: #{ord.maDonHang}</span>
                      <span style={{ fontSize: '12px', color: '#64748b', fontWeight: 600, display: 'inline-flex', alignItems: 'center', gap: '4px' }}>
                        <Clock size={14} />
                        Giờ đặt: {ord.thoiGianDat ? new Date(ord.thoiGianDat).toLocaleTimeString('vi-VN') : ''} ({new Date(ord.thoiGianDat).toLocaleDateString('vi-VN')})
                      </span>
                    </div>

                    <div style={{ fontSize: '13px', color: '#334155', marginBottom: '8px' }}>
                      <strong>Khách hàng mua:</strong> {ord.tenKhachHang} {ord.sdtKhachHang ? `(SĐT: ${ord.sdtKhachHang})` : ''}
                    </div>

                    <div style={{ fontSize: '12px', color: '#64748b', display: 'flex', gap: '16px', flexWrap: 'wrap', marginBottom: '10px', background: '#f8fafc', padding: '8px 12px', borderRadius: '8px' }}>
                      <span>Loại đơn: <strong style={{ color: '#0f172a' }}>{ord.loaiDonHang}</strong></span>
                      <span>Phương thức: <strong style={{ color: '#0f172a' }}>{ord.phuongThucThanhToan}</strong></span>
                      <span>Trạng thái: <strong style={{ color: ord.trangThai === 'COMPLETED' ? '#10b981' : '#fc6011' }}>{ord.trangThai}</strong></span>
                    </div>

                    {/* Items inside this order */}
                    {ord.items && ord.items.length > 0 && (
                      <div style={{ borderTop: '1px solid #f1f5f9', paddingTop: '8px', fontSize: '12px' }}>
                        <div style={{ fontWeight: 700, marginBottom: '6px', color: '#475569' }}>Chi tiết món ăn trong đơn:</div>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: '4px' }}>
                          {ord.items.map((it: any, idx: number) => (
                            <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', background: '#f8fafc', padding: '6px 10px', borderRadius: '6px' }}>
                              <span>• <strong>{it.soLuong}x</strong> {it.tenMonAn} ({formatVND(it.donGia)}/món)</span>
                              <span style={{ fontWeight: 800, color: '#0f172a' }}>{formatVND((it.donGia || 0) * (it.soLuong || 1))}</span>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    <div style={{ textAlign: 'right', marginTop: '10px', fontWeight: 900, color: '#fc6011', fontSize: '16px' }}>
                      Tổng giá tiền đơn: {formatVND(ord.tongTien)}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
