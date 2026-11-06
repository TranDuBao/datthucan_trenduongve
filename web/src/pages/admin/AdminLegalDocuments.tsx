import React, { useState, useEffect, useCallback } from 'react';
import { FileText, RefreshCw, Plus, CheckCircle, AlertTriangle } from 'lucide-react';
import { apiFetch } from '../../api/apiClient';
import { LegalDocMetrics } from './legal/LegalDocMetrics';
import { LegalDocTable, renderStatusBadge, renderTypeBadge } from './legal/LegalDocTable';
import { LegalDocPreviewModal } from './legal/LegalDocPreviewModal';
import { LegalDocFormModal } from './legal/LegalDocFormModal';
import { LegalDocPublishModal, LegalDocDeleteModal } from './legal/LegalDocConfirmModals';

export interface LegalDocument {
  maPhienBan: number;
  loaiTaiLieu: 'DIEU_KHOAN_DOI_TAC' | 'CHINH_SACH_DU_LIEU';
  soPhienBan: string;
  tieuDe: string;
  noiDung?: string;
  trangThai: 'NHAP' | 'DANG_HIEU_LUC' | 'DA_LUU_TRU';
  ngayHieuLuc?: string | null;
  maTaiKhoanTao?: number | null;
  ngayTao: string;
  ngayCapNhat: string;
  nguoiTao?: {
    maTaiKhoan: number;
    tenDangNhap: string;
  };
}

export const AdminLegalDocuments: React.FC = () => {
  const [documents, setDocuments] = useState<LegalDocument[]>([]);
  const [total, setTotal] = useState<number>(0);
  const [page, setPage] = useState<number>(1);
  const [limit] = useState<number>(10);
  const [typeFilter, setTypeFilter] = useState<string>('ALL');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);

  // Detail / Preview Modal
  const [previewDoc, setPreviewDoc] = useState<LegalDocument | null>(null);
  const [previewModalOpen, setPreviewModalOpen] = useState<boolean>(false);
  const [loadingPreview, setLoadingPreview] = useState<boolean>(false);

  // Form Modal (Create / Edit)
  const [formModalOpen, setFormModalOpen] = useState<boolean>(false);
  const [editingDocId, setEditingDocId] = useState<number | null>(null);
  const [formData, setFormData] = useState<{
    loaiTaiLieu: string;
    soPhienBan: string;
    tieuDe: string;
    noiDung: string;
  }>({
    loaiTaiLieu: 'DIEU_KHOAN_DOI_TAC',
    soPhienBan: '',
    tieuDe: '',
    noiDung: '',
  });
  const [formError, setFormError] = useState<string>('');
  const [saving, setSaving] = useState<boolean>(false);

  // Publish Confirm Modal
  const [publishTarget, setPublishTarget] = useState<LegalDocument | null>(null);
  const [publishModalOpen, setPublishModalOpen] = useState<boolean>(false);
  const [publishing, setPublishing] = useState<boolean>(false);

  // Delete Confirm Modal
  const [deleteTarget, setDeleteTarget] = useState<LegalDocument | null>(null);
  const [deleteModalOpen, setDeleteModalOpen] = useState<boolean>(false);
  const [deleting, setDeleting] = useState<boolean>(false);

  // Toast feedback
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchDocuments = useCallback(async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: String(page),
        limit: String(limit),
      });
      if (typeFilter !== 'ALL') params.set('loaiTaiLieu', typeFilter);
      if (statusFilter !== 'ALL') params.set('trangThai', statusFilter);
      if (searchTerm.trim()) params.set('search', searchTerm.trim());

      const res = await apiFetch<any>(`/admin/legal-documents?${params.toString()}`);
      if (res && res.data) {
        setDocuments(res.data.items || []);
        setTotal(res.data.total || 0);
      }
    } catch (err: any) {
      console.error('Fetch legal documents error:', err);
      showToast('error', err.message || 'Lỗi tải danh sách điều khoản');
    } finally {
      setLoading(false);
    }
  }, [page, limit, typeFilter, statusFilter, searchTerm]);

  useEffect(() => {
    fetchDocuments();
  }, [fetchDocuments]);

  // Metrics calculation
  const activeCount = documents.filter((d) => d.trangThai === 'DANG_HIEU_LUC').length;
  const draftCount = documents.filter((d) => d.trangThai === 'NHAP').length;
  const archivedCount = documents.filter((d) => d.trangThai === 'DA_LUU_TRU').length;

  const handleOpenPreview = async (doc: LegalDocument) => {
    try {
      setLoadingPreview(true);
      setPreviewModalOpen(true);
      const full = await apiFetch<any>(`/admin/legal-documents/${doc.maPhienBan}`);
      setPreviewDoc(full.data || doc);
    } catch (err: any) {
      showToast('error', 'Lỗi tải chi tiết nội dung');
    } finally {
      setLoadingPreview(false);
    }
  };

  const handleOpenCreate = (cloneSource?: LegalDocument) => {
    setEditingDocId(null);
    setFormError('');
    if (cloneSource) {
      const parts = cloneSource.soPhienBan.split('.');
      let nextVer = '1.1';
      if (parts.length === 2 && !isNaN(Number(parts[1]))) {
        nextVer = `${parts[0]}.${Number(parts[1]) + 1}`;
      }
      setFormData({
        loaiTaiLieu: cloneSource.loaiTaiLieu,
        soPhienBan: nextVer,
        tieuDe: `${cloneSource.tieuDe} (bản nháp)`,
        noiDung: cloneSource.noiDung || '',
      });
      if (!cloneSource.noiDung) {
        apiFetch<any>(`/admin/legal-documents/${cloneSource.maPhienBan}`).then((res) => {
          if (res?.data?.noiDung) {
            setFormData((prev) => ({ ...prev, noiDung: res.data.noiDung }));
          }
        });
      }
    } else {
      setFormData({
        loaiTaiLieu: 'DIEU_KHOAN_DOI_TAC',
        soPhienBan: '1.1',
        tieuDe: '',
        noiDung: '',
      });
    }
    setFormModalOpen(true);
  };

  const handleOpenEdit = async (doc: LegalDocument) => {
    if (doc.trangThai !== 'NHAP') {
      showToast('error', 'Chỉ có thể chỉnh sửa các phiên bản ở trạng thái Bản nháp');
      return;
    }
    setEditingDocId(doc.maPhienBan);
    setFormError('');
    try {
      const full = await apiFetch<any>(`/admin/legal-documents/${doc.maPhienBan}`);
      const data = full.data || doc;
      setFormData({
        loaiTaiLieu: data.loaiTaiLieu,
        soPhienBan: data.soPhienBan,
        tieuDe: data.tieuDe,
        noiDung: data.noiDung || '',
      });
      setFormModalOpen(true);
    } catch (err: any) {
      showToast('error', 'Lỗi tải nội dung bản nháp');
    }
  };

  const handleSaveForm = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError('');
    if (!formData.soPhienBan.trim()) {
      setFormError('Vui lòng nhập số phiên bản (ví dụ: 1.1)');
      return;
    }
    if (!formData.tieuDe.trim()) {
      setFormError('Vui lòng nhập tiêu đề tài liệu');
      return;
    }
    if (!formData.noiDung.trim()) {
      setFormError('Vui lòng nhập nội dung điều khoản');
      return;
    }

    try {
      setSaving(true);
      if (editingDocId) {
        await apiFetch(`/admin/legal-documents/${editingDocId}`, {
          method: 'PUT',
          body: JSON.stringify(formData),
        });
        showToast('success', 'Đã cập nhật bản nháp thành công');
      } else {
        await apiFetch(`/admin/legal-documents`, {
          method: 'POST',
          body: JSON.stringify(formData),
        });
        showToast('success', 'Đã tạo bản nháp mới thành công');
      }
      setFormModalOpen(false);
      fetchDocuments();
    } catch (err: any) {
      setFormError(err.message || 'Lỗi khi lưu bản nháp');
    } finally {
      setSaving(false);
    }
  };

  const handlePublishConfirm = async () => {
    if (!publishTarget) return;
    try {
      setPublishing(true);
      await apiFetch(`/admin/legal-documents/${publishTarget.maPhienBan}/publish`, {
        method: 'POST',
      });
      showToast('success', `Đã xuất bản thành công phiên bản v${publishTarget.soPhienBan}!`);
      setPublishModalOpen(false);
      setPublishTarget(null);
      fetchDocuments();
    } catch (err: any) {
      showToast('error', err.message || 'Lỗi xuất bản phiên bản');
    } finally {
      setPublishing(false);
    }
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    try {
      setDeleting(true);
      await apiFetch(`/admin/legal-documents/${deleteTarget.maPhienBan}`, {
        method: 'DELETE',
      });
      showToast('success', 'Đã xóa bản nháp thành công');
      setDeleteModalOpen(false);
      setDeleteTarget(null);
      fetchDocuments();
    } catch (err: any) {
      showToast('error', err.message || 'Lỗi xóa bản nháp');
    } finally {
      setDeleting(false);
    }
  };

  return (
    <div style={{ padding: '24px', maxWidth: '1400px', margin: '0 auto' }}>
      {/* Toast Notification */}
      {toast && (
        <div
          style={{
            position: 'fixed',
            top: '20px',
            right: '24px',
            zIndex: 9999,
            padding: '12px 18px',
            borderRadius: '10px',
            backgroundColor: toast.type === 'success' ? '#ecfdf5' : '#fef2f2',
            border: `1px solid ${toast.type === 'success' ? '#86efac' : '#fca5a5'}`,
            color: toast.type === 'success' ? '#166534' : '#991b1b',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            boxShadow: '0 8px 16px rgba(0,0,0,0.1)',
            fontWeight: 600,
            fontSize: '14px',
          }}
        >
          {toast.type === 'success' ? <CheckCircle size={18} /> : <AlertTriangle size={18} />}
          {toast.message}
        </div>
      )}

      {/* Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: '24px',
          flexWrap: 'wrap',
          gap: '16px',
        }}
      >
        <div>
          <h1
            style={{
              fontSize: '24px',
              fontWeight: 800,
              color: '#0f172a',
              display: 'flex',
              alignItems: 'center',
              gap: '12px',
              letterSpacing: '-0.3px',
            }}
          >
            <div
              style={{
                width: '42px',
                height: '42px',
                borderRadius: '12px',
                backgroundColor: 'rgba(252, 96, 17, 0.12)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <FileText color="#fc6011" size={24} />
            </div>
            Điều Khoản & Chính Sách
          </h1>
          <p style={{ fontSize: '14px', color: '#64748b', marginTop: '4px' }}>
            Quản lý các phiên bản Điều khoản đối tác và Chính sách dữ liệu bảo mật Food Route
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
          <button
            onClick={() => fetchDocuments()}
            disabled={loading}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              padding: '10px 16px',
              borderRadius: '10px',
              backgroundColor: '#ffffff',
              border: '1px solid #e2e8f0',
              color: '#334155',
              fontWeight: 600,
              fontSize: '13px',
              cursor: 'pointer',
              boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
            }}
          >
            <RefreshCw size={15} className={loading ? 'animate-spin' : ''} />
            Làm mới
          </button>
          <button
            onClick={() => handleOpenCreate()}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '8px',
              padding: '10px 18px',
              borderRadius: '10px',
              backgroundColor: '#fc6011',
              color: '#ffffff',
              fontWeight: 700,
              fontSize: '13px',
              cursor: 'pointer',
              border: 'none',
              boxShadow: '0 4px 12px rgba(252, 96, 17, 0.3)',
            }}
          >
            <Plus size={16} />
            Tạo Bản Nháp Mới
          </button>
        </div>
      </div>

      {/* Metrics */}
      <LegalDocMetrics
        total={total}
        activeCount={activeCount}
        draftCount={draftCount}
        archivedCount={archivedCount}
      />

      {/* Main Table and Filters */}
      <LegalDocTable
        documents={documents}
        total={total}
        page={page}
        limit={limit}
        loading={loading}
        typeFilter={typeFilter}
        statusFilter={statusFilter}
        searchTerm={searchTerm}
        onTypeFilterChange={(val) => {
          setTypeFilter(val);
          setPage(1);
        }}
        onStatusFilterChange={(val) => {
          setStatusFilter(val);
          setPage(1);
        }}
        onSearchChange={(val) => {
          setSearchTerm(val);
          setPage(1);
        }}
        onPageChange={setPage}
        onPreview={handleOpenPreview}
        onEdit={handleOpenEdit}
        onClone={handleOpenCreate}
        onPublish={(doc) => {
          setPublishTarget(doc);
          setPublishModalOpen(true);
        }}
        onDelete={(doc) => {
          setDeleteTarget(doc);
          setDeleteModalOpen(true);
        }}
      />

      {/* Create / Edit Form Modal */}
      <LegalDocFormModal
        isOpen={formModalOpen}
        onClose={() => setFormModalOpen(false)}
        editingDocId={editingDocId}
        formData={formData}
        setFormData={setFormData}
        formError={formError}
        saving={saving}
        onSave={handleSaveForm}
      />

      {/* Preview Modal */}
      <LegalDocPreviewModal
        isOpen={previewModalOpen}
        onClose={() => setPreviewModalOpen(false)}
        loading={loadingPreview}
        doc={previewDoc}
        renderStatusBadge={renderStatusBadge}
        renderTypeBadge={renderTypeBadge}
      />

      {/* Publish Confirm Modal */}
      <LegalDocPublishModal
        isOpen={publishModalOpen}
        onClose={() => setPublishModalOpen(false)}
        target={publishTarget}
        publishing={publishing}
        onConfirm={handlePublishConfirm}
      />

      {/* Delete Confirm Modal */}
      <LegalDocDeleteModal
        isOpen={deleteModalOpen}
        onClose={() => setDeleteModalOpen(false)}
        target={deleteTarget}
        deleting={deleting}
        onConfirm={handleDeleteConfirm}
      />
    </div>
  );
};
