import React, { useState } from 'react';
import {
  FileText,
  Download,
  FileSpreadsheet,
  Printer,
  X,
  Store,
  UserCheck,
} from 'lucide-react';

interface RevenueExportModalProps {
  isOpen: boolean;
  onClose: () => void;
  storeInfo: any;
  summary: any;
  ordersList: any[];
  periodLabel: string;
  cancelledCount: number;
  formatVND: (amount: number) => string;
}

export const RevenueExportModal: React.FC<RevenueExportModalProps> = ({
  isOpen,
  onClose,
  storeInfo,
  summary,
  ordersList,
  periodLabel,
  cancelledCount,
  formatVND,
}) => {
  const [exportingPDF, setExportingPDF] = useState(false);

  if (!isOpen) return null;

  const getSafeFileName = (extension: string) => {
    const storeName = storeInfo?.tenQuan || 'FoodRoute';
    const cleanName = storeName
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/đ/g, 'd')
      .replace(/Đ/g, 'D')
      .replace(/[^a-zA-Z0-9]/g, '_')
      .replace(/_+/g, '_');
    const dateStr = new Date().toISOString().split('T')[0];
    return `Bao_Cao_Doanh_Thu_${cleanName}_${dateStr}.${extension}`;
  };

  const handleExportCSV = () => {
    const store = storeInfo || {};
    const orders = ordersList || [];

    let csvContent = '\uFEFF';
    csvContent += `BÁO CÁO DOANH THU & KẾT QUẢ KINH DOANH - FOODROUTE\n`;
    csvContent += `Ngày xuất báo cáo:,${new Date().toLocaleString('vi-VN')}\n`;
    csvContent += `Kỳ báo cáo:,${periodLabel}\n\n`;

    csvContent += `THÔNG TIN CỬA HÀNG & CHỦ SỞ HỮU\n`;
    csvContent += `Tên nhà hàng:,${store.tenQuan || ''},Số điện thoại:,${store.sdt || ''}\n`;
    csvContent += `Địa chỉ:,${store.diaChi || ''},Email:,${store.email || ''}\n`;
    csvContent += `Họ tên chủ quán:,${store.hoTenChuQuan || ''},Số CCCD:,${store.soCCCD || ''}\n`;
    csvContent += `Tài khoản ngân hàng:,${store.tenNganHang || ''},Số TK:,${store.soTaiKhoanNganHang || ''},Chủ TK:,${store.tenChuTaiKhoan || ''}\n\n`;

    csvContent += `TỔNG QUAN DOANH THU\n`;
    csvContent += `Tổng doanh thu:,${summary.totalRevenue || 0} VNĐ\n`;
    csvContent += `Tổng số đơn hàng:,${summary.totalOrders || 0} đơn\n`;
    csvContent += `Đơn hoàn thành:,${summary.completedOrders || 0} đơn\n`;
    csvContent += `Đơn đã hủy:,${cancelledCount} đơn\n`;
    csvContent += `Giá trị đơn trung bình:,${Math.round(summary.averageOrderValue || 0)} VNĐ\n\n`;

    csvContent += `DANH SÁCH ĐƠN HÀNG DOANH THU\n`;
    csvContent += `STT,Mã Đơn,Thời Gian Đặt,Khách Hàng,Số Điện Thoại,Loại Đơn,Phương Thức Thanh Toán,Trạng Thái,Doanh Thu (VNĐ)\n`;

    orders.forEach((ord: any, idx: number) => {
      const dateStr = ord.thoiGianDat ? new Date(ord.thoiGianDat).toLocaleString('vi-VN') : '';
      csvContent += `${idx + 1},#${ord.maDonHang},"${dateStr}","${ord.tenKhachHang}","${ord.sdtKhachHang}","${ord.loaiDonHang}","${ord.phuongThucThanhToan}","${ord.trangThai}",${ord.tongTien}\n`;
    });

    const fileName = getSafeFileName('csv');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', fileName);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handleDownloadPDF = async () => {
    const element = document.getElementById('printable-revenue-report');
    if (!element) return;

    setExportingPDF(true);
    try {
      if (!(window as any).html2pdf) {
        await new Promise<void>((resolve, reject) => {
          const script = document.createElement('script');
          script.src = 'https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js';
          script.onload = () => resolve();
          script.onerror = () => reject(new Error('Không thể tải thư viện PDF'));
          document.head.appendChild(script);
        });
      }

      const fileName = getSafeFileName('pdf');
      const opt = {
        margin: [8, 8, 8, 8],
        filename: fileName,
        image: { type: 'jpeg', quality: 0.98 },
        html2canvas: { scale: 2, useCORS: true, logging: false },
        jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
      };

      await (window as any).html2pdf().set(opt).from(element).save();
    } catch (err) {
      console.error('Lỗi xuất PDF:', err);
      window.print();
    } finally {
      setExportingPDF(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

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
        zIndex: 999,
        padding: '20px',
      }}
    >
      <div
        style={{
          background: '#ffffff',
          borderRadius: '20px',
          maxWidth: '850px',
          width: '100%',
          maxHeight: '90vh',
          overflowY: 'auto',
          boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)',
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        {/* Toolbar Action Bar (No Print) */}
        <div
          className="no-print"
          style={{
            padding: '16px 24px',
            borderBottom: '1px solid #e2e8f0',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            background: '#f8fafc',
            borderRadius: '20px 20px 0 0',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 800, color: '#0f172a' }}>
            <FileText color="#fc6011" size={20} />
            Xem Trước Báo Cáo Doanh Thu
          </div>
          <div style={{ display: 'flex', gap: '8px', alignItems: 'center', flexWrap: 'wrap' }}>
            <button
              className="btn btn-primary"
              onClick={handleDownloadPDF}
              disabled={exportingPDF}
              style={{ display: 'inline-flex', alignItems: 'center', gap: '6px', fontSize: '13px', padding: '8px 14px' }}
            >
              <Download size={16} /> {exportingPDF ? 'Đang tạo PDF...' : 'Tải File PDF'}
            </button>
            <button
              className="btn"
              onClick={handleExportCSV}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                fontSize: '13px',
                padding: '8px 14px',
                background: '#10b981',
                color: '#ffffff',
                border: 'none',
                borderRadius: '8px',
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              <FileSpreadsheet size={16} /> Tải Excel (.csv)
            </button>
            <button
              className="btn"
              onClick={handlePrint}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                fontSize: '13px',
                padding: '8px 14px',
                background: '#ffffff',
                border: '1px solid #cbd5e1',
                color: '#334155',
                borderRadius: '8px',
                fontWeight: 700,
                cursor: 'pointer',
              }}
            >
              <Printer size={16} /> In Báo Cáo
            </button>
            <button
              onClick={onClose}
              style={{
                background: 'none',
                border: 'none',
                cursor: 'pointer',
                padding: '4px',
                color: '#64748b',
                borderRadius: '50%',
              }}
            >
              <X size={20} />
            </button>
          </div>
        </div>

        {/* Printable Content Body */}
        <div id="printable-revenue-report" style={{ padding: '32px' }}>
          {/* Report Header */}
          <div style={{ borderBottom: '2px solid #fc6011', paddingBottom: '20px', marginBottom: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <h2 style={{ color: '#fc6011', fontSize: '22px', fontWeight: 900, margin: 0, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                FOODROUTE - BÁO CÁO DOANH THU
              </h2>
              <p style={{ margin: '4px 0 0 0', color: '#64748b', fontSize: '13px' }}>
                Hệ thống Quản lý Bán hàng & Thực đơn Thông minh
              </p>
            </div>
            <div style={{ textAlign: 'right', fontSize: '12px', color: '#64748b' }}>
              <div><strong>Ngày xuất:</strong> {new Date().toLocaleString('vi-VN')}</div>
              <div><strong>Kỳ báo cáo:</strong> {periodLabel}</div>
            </div>
          </div>

          {/* Store & Owner Info */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '24px', background: '#f8fafc', padding: '20px', borderRadius: '12px', border: '1px solid #e2e8f0' }}>
            <div>
              <h4 style={{ margin: '0 0 10px 0', fontSize: '13px', fontWeight: 800, color: '#fc6011', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Store size={15} /> THÔNG TIN CỬA HÀNG
              </h4>
              <div style={{ fontSize: '13px', lineHeight: '1.6', color: '#334155' }}>
                <div><strong>Tên nhà hàng:</strong> {storeInfo?.tenQuan || 'Chưa cập nhật'}</div>
                <div><strong>Địa chỉ:</strong> {storeInfo?.diaChi || 'Chưa cập nhật'}</div>
                <div><strong>Số điện thoại:</strong> {storeInfo?.sdt || 'Chưa cập nhật'}</div>
                <div><strong>Email:</strong> {storeInfo?.email || 'Chưa cập nhật'}</div>
              </div>
            </div>

            <div>
              <h4 style={{ margin: '0 0 10px 0', fontSize: '13px', fontWeight: 800, color: '#fc6011', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <UserCheck size={15} /> CHỦ CỬA HÀNG & THỤ HƯỞNG
              </h4>
              <div style={{ fontSize: '13px', lineHeight: '1.6', color: '#334155' }}>
                <div><strong>Họ tên chủ quán:</strong> {storeInfo?.hoTenChuQuan || 'Chưa cập nhật'}</div>
                <div><strong>Số CCCD:</strong> {storeInfo?.soCCCD || 'Chưa cập nhật'}</div>
                <div><strong>Ngân hàng:</strong> {storeInfo?.tenNganHang || 'Chưa cập nhật'}</div>
                <div><strong>Số tài khoản:</strong> {storeInfo?.soTaiKhoanNganHang || 'Chưa cập nhật'} ({storeInfo?.tenChuTaiKhoan || ''})</div>
              </div>
            </div>
          </div>

          {/* Revenue Summary Banner */}
          <div style={{ background: '#fff4ee', padding: '16px 20px', borderRadius: '12px', border: '1px solid #fdba74', marginBottom: '24px', display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '12px' }}>
            <div>
              <div style={{ fontSize: '11px', color: '#c2410c', fontWeight: 700, textTransform: 'uppercase' }}>TỔNG DOANH THU</div>
              <div style={{ fontSize: '18px', fontWeight: 900, color: '#fc6011', marginTop: '4px' }}>{formatVND(summary.totalRevenue)}</div>
            </div>
            <div>
              <div style={{ fontSize: '11px', color: '#475569', fontWeight: 700, textTransform: 'uppercase' }}>TỔNG SỐ ĐƠN</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginTop: '4px' }}>{summary.totalOrders || 0} đơn</div>
            </div>
            <div>
              <div style={{ fontSize: '11px', color: '#047857', fontWeight: 700, textTransform: 'uppercase' }}>ĐƠN HOÀN THÀNH</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#10b981', marginTop: '4px' }}>{summary.completedOrders || 0} đơn</div>
            </div>
            <div>
              <div style={{ fontSize: '11px', color: '#475569', fontWeight: 700, textTransform: 'uppercase' }}>GIÁ TRỊ ĐƠN TRUNG BÌNH</div>
              <div style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a', marginTop: '4px' }}>{formatVND(summary.averageOrderValue)}</div>
            </div>
          </div>

          {/* Detailed Orders Table */}
          <div style={{ marginBottom: '24px' }}>
            <h4 style={{ margin: '0 0 12px 0', fontSize: '14px', fontWeight: 800, color: '#0f172a' }}>
              DANH SÁCH ĐƠN HÀNG DOANH THU ({ordersList.length} đơn)
            </h4>
            {ordersList.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '24px', background: '#f8fafc', color: '#64748b', fontSize: '13px', borderRadius: '8px' }}>
                Không có đơn hàng nào trong kỳ báo cáo này
              </div>
            ) : (
              <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: '12px' }}>
                <thead>
                  <tr style={{ background: '#f1f5f9', borderBottom: '2px solid #cbd5e1', textAlign: 'left' }}>
                    <th style={{ padding: '8px' }}>#</th>
                    <th style={{ padding: '8px' }}>Mã Đơn</th>
                    <th style={{ padding: '8px' }}>Thời Gian</th>
                    <th style={{ padding: '8px' }}>Khách Hàng</th>
                    <th style={{ padding: '8px' }}>Loại Đơn</th>
                    <th style={{ padding: '8px' }}>PTTT</th>
                    <th style={{ padding: '8px' }}>Trạng Thái</th>
                    <th style={{ padding: '8px', textAlign: 'right' }}>Tổng Tiền</th>
                  </tr>
                </thead>
                <tbody>
                  {ordersList.map((ord: any, idx: number) => (
                    <tr key={ord.maDonHang || idx} style={{ borderBottom: '1px solid #e2e8f0' }}>
                      <td style={{ padding: '8px', fontWeight: 700 }}>{idx + 1}</td>
                      <td style={{ padding: '8px', fontWeight: 700, color: '#fc6011' }}>#{ord.maDonHang}</td>
                      <td style={{ padding: '8px' }}>{ord.thoiGianDat ? new Date(ord.thoiGianDat).toLocaleString('vi-VN') : ''}</td>
                      <td style={{ padding: '8px' }}>{ord.tenKhachHang} {ord.sdtKhachHang ? `(${ord.sdtKhachHang})` : ''}</td>
                      <td style={{ padding: '8px' }}>{ord.loaiDonHang}</td>
                      <td style={{ padding: '8px' }}>{ord.phuongThucThanhToan}</td>
                      <td style={{ padding: '8px', fontWeight: 600 }}>{ord.trangThai}</td>
                      <td style={{ padding: '8px', textAlign: 'right', fontWeight: 800 }}>{formatVND(ord.tongTien)}</td>
                    </tr>
                  ))}
                </tbody>
                <tfoot>
                  <tr style={{ background: '#f8fafc', borderTop: '2px solid #cbd5e1', fontWeight: 800 }}>
                    <td colSpan={7} style={{ padding: '10px 8px', textAlign: 'right' }}>TỔNG CỘNG DOANH THU:</td>
                    <td style={{ padding: '10px 8px', textAlign: 'right', color: '#fc6011', fontSize: '14px' }}>{formatVND(summary.totalRevenue)}</td>
                  </tr>
                </tfoot>
              </table>
            )}
          </div>

          {/* Signatures */}
          <div style={{ marginTop: '40px', display: 'grid', gridTemplateColumns: '1fr 1fr', textAlign: 'center', fontSize: '13px' }}>
            <div>
              <div style={{ fontWeight: 800, textTransform: 'uppercase' }}>ĐẠI DIỆN NHÀ HÀNG</div>
              <div style={{ fontSize: '11px', color: '#64748b', marginTop: '2px' }}>(Ký và ghi rõ họ tên)</div>
              <div style={{ marginTop: '60px', fontWeight: 700 }}>{storeInfo?.hoTenChuQuan || storeInfo?.tenQuan || 'Chủ cơ sở'}</div>
            </div>
            <div>
              <div style={{ fontWeight: 800, textTransform: 'uppercase' }}>BỘ PHẬN BÁO CÁO FOODROUTE</div>
              <div style={{ fontSize: '11px', color: '#64748b', marginTop: '2px' }}>(Xác nhận hệ thống)</div>
              <div style={{ marginTop: '60px', fontWeight: 700 }}>Hệ Thống FoodRoute System</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
