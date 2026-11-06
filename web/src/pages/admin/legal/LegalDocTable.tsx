import React from 'react';
import {
  FileText,
  Shield,
  Clock,
  Archive,
  Calendar,
  User,
  Edit,
  Copy,
  CheckCircle,
  Trash2,
  RefreshCw,
  Search,
  Layers,
} from 'lucide-react';
import { LegalDocument } from '../AdminLegalDocuments';

interface LegalDocTableProps {
  documents: LegalDocument[];
  total: number;
  page: number;
  limit: number;
  loading: boolean;
  typeFilter: string;
  statusFilter: string;
  searchTerm: string;
  onTypeFilterChange: (type: string) => void;
  onStatusFilterChange: (status: string) => void;
  onSearchChange: (search: string) => void;
  onPageChange: (newPage: number) => void;
  onPreview: (doc: LegalDocument) => void;
  onEdit: (doc: LegalDocument) => void;
  onClone: (doc: LegalDocument) => void;
  onPublish: (doc: LegalDocument) => void;
  onDelete: (doc: LegalDocument) => void;
}

export const renderStatusBadge = (status: string) => {
  switch (status) {
    case 'DANG_HIEU_LUC':
      return (
        <span
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '6px',
            padding: '4px 10px',
            borderRadius: '20px',
            fontSize: '12px',
            fontWeight: 600,
            backgroundColor: '#ecfdf5',
            color: '#047857',
            border: '1px solid #a7f3d0',
          }}
        >
          <span
            style={{
              width: '7px',
              height: '7px',
              borderRadius: '50%',
              backgroundColor: '#10b981',
              boxShadow: '0 0 6px rgba(16, 185, 129, 0.6)',
            }}
          />
          Đang hiệu lực
        </span>
      );
    case 'NHAP':
      return (
        <span
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '5px',
            padding: '4px 10px',
            borderRadius: '20px',
            fontSize: '12px',
            fontWeight: 600,
            backgroundColor: '#fffbeb',
            color: '#b45309',
            border: '1px solid #fde68a',
          }}
        >
          <Clock size={12} />
          Bản nháp
        </span>
      );
    case 'DA_LUU_TRU':
      return (
        <span
          style={{
            display: 'inline-flex',
            alignItems: 'center',
            gap: '5px',
            padding: '4px 10px',
            borderRadius: '20px',
            fontSize: '12px',
            fontWeight: 600,
            backgroundColor: '#f1f5f9',
            color: '#64748b',
            border: '1px solid #e2e8f0',
          }}
        >
          <Archive size={12} />
          Đã lưu trữ
        </span>
      );
    default:
      return <span>{status}</span>;
  }
};

export const renderTypeBadge = (type: string) => {
  if (type === 'DIEU_KHOAN_DOI_TAC') {
    return (
      <span
        style={{
          display: 'inline-flex',
          alignItems: 'center',
          gap: '6px',
          padding: '4px 10px',
          borderRadius: '8px',
          fontSize: '12px',
          fontWeight: 600,
          backgroundColor: '#fff7ed',
          color: '#c2410c',
          border: '1px solid #fed7aa',
        }}
      >
        <FileText size={13} color="#c2410c" />
        Điều khoản đối tác
      </span>
    );
  }
  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: '6px',
        padding: '4px 10px',
        borderRadius: '8px',
        fontSize: '12px',
        fontWeight: 600,
        backgroundColor: '#eff6ff',
        color: '#1d4ed8',
        border: '1px solid #bfdbfe',
      }}
    >
      <Shield size={13} color="#1d4ed8" />
      Chính sách dữ liệu
    </span>
  );
};

export const LegalDocTable: React.FC<LegalDocTableProps> = ({
  documents,
  total,
  page,
  limit,
  loading,
  typeFilter,
  statusFilter,
  searchTerm,
  onTypeFilterChange,
  onStatusFilterChange,
  onSearchChange,
  onPageChange,
  onPreview,
  onEdit,
  onClone,
  onPublish,
  onDelete,
}) => {
  const totalPages = Math.ceil(total / limit) || 1;

  return (
    <div>
      {/* Filter and Tab Section */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '14px',
          padding: '16px 20px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
          border: '1px solid #e2e8f0',
          marginBottom: '20px',
          display: 'flex',
          flexDirection: 'column',
          gap: '14px',
        }}
      >
        {/* Document Type Tabs */}
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap', borderBottom: '1px solid #f1f5f9', paddingBottom: '12px' }}>
          {[
            { id: 'ALL', label: 'Tất Cả Tài Liệu', icon: Layers },
            { id: 'DIEU_KHOAN_DOI_TAC', label: 'Điều Khoản Đối Tác Cửa Hàng', icon: FileText },
            { id: 'CHINH_SACH_DU_LIEU', label: 'Chính Sách Dữ Liệu Cá Nhân', icon: Shield },
          ].map((tab) => {
            const IconComp = tab.icon;
            const isSelected = typeFilter === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => onTypeFilterChange(tab.id)}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '8px',
                  padding: '8px 16px',
                  borderRadius: '20px',
                  fontSize: '13px',
                  fontWeight: 700,
                  cursor: 'pointer',
                  border: isSelected ? '1px solid #fc6011' : '1px solid #e2e8f0',
                  backgroundColor: isSelected ? '#fc6011' : '#f8fafc',
                  color: isSelected ? '#ffffff' : '#475569',
                  boxShadow: isSelected ? '0 3px 8px rgba(252,96,17,0.25)' : 'none',
                  transition: 'all 0.15s ease',
                }}
              >
                <IconComp size={15} />
                {tab.label}
              </button>
            );
          })}
        </div>

        {/* Status Filter & Search Input */}
        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            flexWrap: 'wrap',
            gap: '12px',
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <span style={{ fontSize: '12px', fontWeight: 700, color: '#64748b', textTransform: 'uppercase' }}>
              Trạng thái:
            </span>
            <select
              value={statusFilter}
              onChange={(e) => onStatusFilterChange(e.target.value)}
              style={{
                padding: '8px 12px',
                borderRadius: '8px',
                border: '1px solid #e2e8f0',
                fontSize: '13px',
                color: '#334155',
                backgroundColor: '#ffffff',
                fontWeight: 500,
                cursor: 'pointer',
              }}
            >
              <option value="ALL">Tất cả trạng thái</option>
              <option value="DANG_HIEU_LUC">Đang hiệu lực</option>
              <option value="NHAP">Bản nháp</option>
              <option value="DA_LUU_TRU">Đã lưu trữ</option>
            </select>
          </div>

          <div style={{ position: 'relative', width: '320px', maxWidth: '100%' }}>
            <Search
              size={16}
              style={{
                position: 'absolute',
                left: '12px',
                top: '50%',
                transform: 'translateY(-50%)',
                color: '#94a3b8',
              }}
            />
            <input
              type="text"
              placeholder="Tìm theo tiêu đề hoặc phiên bản..."
              value={searchTerm}
              onChange={(e) => onSearchChange(e.target.value)}
              style={{
                width: '100%',
                padding: '8px 14px 8px 36px',
                borderRadius: '8px',
                border: '1px solid #e2e8f0',
                fontSize: '13px',
                color: '#1e293b',
                backgroundColor: '#f8fafc',
              }}
            />
          </div>
        </div>
      </div>

      {/* Main Table Card */}
      <div
        style={{
          backgroundColor: '#ffffff',
          borderRadius: '14px',
          boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
          border: '1px solid #e2e8f0',
          overflow: 'hidden',
        }}
      >
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', fontSize: '13px' }}>
            <thead>
              <tr style={{ backgroundColor: '#f8fafc', borderBottom: '1px solid #e2e8f0' }}>
                <th style={{ padding: '14px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Loại tài liệu
                </th>
                <th style={{ padding: '14px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Phiên bản
                </th>
                <th style={{ padding: '14px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Tiêu đề tài liệu
                </th>
                <th style={{ padding: '14px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Trạng thái
                </th>
                <th style={{ padding: '14px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Hiệu lực / Ngày tạo
                </th>
                <th style={{ padding: '14px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                  Người tạo
                </th>
                <th style={{ padding: '14px 18px', fontWeight: 700, color: '#475569', fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.5px', textAlign: 'right' }}>
                  Thao tác
                </th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan={7} style={{ padding: '48px 18px', textAlign: 'center', color: '#94a3b8' }}>
                    <RefreshCw className="animate-spin inline mr-2" size={20} />
                    Đang tải danh sách phiên bản...
                  </td>
                </tr>
              ) : documents.length === 0 ? (
                <tr>
                  <td colSpan={7} style={{ padding: '48px 18px', textAlign: 'center', color: '#94a3b8' }}>
                    Không có tài liệu nào phù hợp với bộ lọc hiện tại.
                  </td>
                </tr>
              ) : (
                documents.map((doc) => {
                  const isDraft = doc.trangThai === 'NHAP';
                  return (
                    <tr
                      key={doc.maPhienBan}
                      onClick={() => onPreview(doc)}
                      style={{
                        borderBottom: '1px solid #f1f5f9',
                        transition: 'background 0.15s ease',
                        cursor: 'pointer',
                      }}
                      onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f8fafc')}
                      onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                      title="Bấm vào dòng để xem chi tiết & mô phỏng nội dung điều khoản"
                    >
                      <td style={{ padding: '14px 18px', verticalAlign: 'middle' }}>
                        {renderTypeBadge(doc.loaiTaiLieu)}
                      </td>
                      <td style={{ padding: '14px 18px', verticalAlign: 'middle' }}>
                        <span
                          style={{
                            fontFamily: 'monospace',
                            fontWeight: 700,
                            fontSize: '12px',
                            backgroundColor: '#f1f5f9',
                            padding: '3px 8px',
                            borderRadius: '6px',
                            color: '#0f172a',
                            border: '1px solid #cbd5e1',
                          }}
                        >
                          v{doc.soPhienBan}
                        </span>
                      </td>
                      <td style={{ padding: '14px 18px', verticalAlign: 'middle' }}>
                        <div style={{ fontWeight: 600, color: '#0f172a', fontSize: '13px' }}>
                          {doc.tieuDe}
                        </div>
                        <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '2px' }}>
                          Mã phiên bản: #{doc.maPhienBan} • <span style={{ color: '#fc6011' }}>Bấm để xem</span>
                        </div>
                      </td>
                      <td style={{ padding: '14px 18px', verticalAlign: 'middle' }}>
                        {renderStatusBadge(doc.trangThai)}
                      </td>
                      <td style={{ padding: '14px 18px', verticalAlign: 'middle', fontSize: '12px', color: '#475569' }}>
                        {doc.ngayHieuLuc ? (
                          <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#047857', fontWeight: 600 }}>
                            <Calendar size={13} />
                            Hiệu lực: {new Date(doc.ngayHieuLuc).toLocaleDateString('vi-VN')}
                          </div>
                        ) : (
                          <div style={{ color: '#94a3b8' }}>Chưa xuất bản</div>
                        )}
                        <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '2px' }}>
                          Tạo: {new Date(doc.ngayTao).toLocaleString('vi-VN')}
                        </div>
                      </td>
                      <td style={{ padding: '14px 18px', verticalAlign: 'middle', fontSize: '12px', color: '#475569' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '5px' }}>
                          <User size={13} color="#94a3b8" />
                          <span>{doc.nguoiTao?.tenDangNhap || 'Hệ thống'}</span>
                        </div>
                      </td>
                      <td style={{ padding: '14px 18px', verticalAlign: 'middle', textAlign: 'right' }}>
                        <div
                          style={{ display: 'inline-flex', alignItems: 'center', gap: '6px' }}
                          onClick={(e) => e.stopPropagation()}
                        >
                          {isDraft && (
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                onEdit(doc);
                              }}
                              title="Chỉnh sửa bản nháp"
                              style={{
                                padding: '6px',
                                borderRadius: '6px',
                                border: '1px solid #fed7aa',
                                backgroundColor: '#fff7ed',
                                color: '#ea580c',
                                cursor: 'pointer',
                              }}
                            >
                              <Edit size={15} />
                            </button>
                          )}

                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              onClone(doc);
                            }}
                            title="Nhân bản sang bản nháp mới"
                            style={{
                              padding: '6px',
                              borderRadius: '6px',
                              border: '1px solid #e2e8f0',
                              backgroundColor: '#ffffff',
                              color: '#3b82f6',
                              cursor: 'pointer',
                            }}
                          >
                            <Copy size={15} />
                          </button>

                          {isDraft && (
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                onPublish(doc);
                              }}
                              title="Xuất bản để có hiệu lực"
                              style={{
                                padding: '6px',
                                borderRadius: '6px',
                                border: '1px solid #a7f3d0',
                                backgroundColor: '#ecfdf5',
                                color: '#047857',
                                cursor: 'pointer',
                              }}
                            >
                              <CheckCircle size={15} />
                            </button>
                          )}

                          {isDraft && (
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                onDelete(doc);
                              }}
                              title="Xóa bản nháp này"
                              style={{
                                padding: '6px',
                                borderRadius: '6px',
                                border: '1px solid #fecaca',
                                backgroundColor: '#fef2f2',
                                color: '#dc2626',
                                cursor: 'pointer',
                              }}
                            >
                              <Trash2 size={15} />
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Bar */}
        <div
          style={{
            padding: '14px 20px',
            borderTop: '1px solid #f1f5f9',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            backgroundColor: '#ffffff',
            fontSize: '13px',
            color: '#64748b',
          }}
        >
          <div>
            Hiển thị <strong>{documents.length}</strong> / <strong>{total}</strong> phiên bản
          </div>
          <div style={{ display: 'flex', gap: '8px' }}>
            <button
              onClick={() => onPageChange(Math.max(1, page - 1))}
              disabled={page <= 1}
              style={{
                padding: '6px 12px',
                borderRadius: '6px',
                border: '1px solid #e2e8f0',
                backgroundColor: page <= 1 ? '#f8fafc' : '#ffffff',
                color: page <= 1 ? '#cbd5e1' : '#334155',
                cursor: page <= 1 ? 'not-allowed' : 'pointer',
                fontWeight: 600,
                fontSize: '12px',
              }}
            >
              Trang trước
            </button>
            <span style={{ padding: '6px 12px', fontWeight: 600, color: '#0f172a' }}>
              {page} / {totalPages}
            </span>
            <button
              onClick={() => onPageChange(Math.min(totalPages, page + 1))}
              disabled={page >= totalPages}
              style={{
                padding: '6px 12px',
                borderRadius: '6px',
                border: '1px solid #e2e8f0',
                backgroundColor: page >= totalPages ? '#f8fafc' : '#ffffff',
                color: page >= totalPages ? '#cbd5e1' : '#334155',
                cursor: page >= totalPages ? 'not-allowed' : 'pointer',
                fontWeight: 600,
                fontSize: '12px',
              }}
            >
              Trang sau
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

