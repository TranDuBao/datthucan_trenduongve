import React, { useState, useEffect } from 'react';
import { Plus, Edit, Trash2, FolderPlus, HelpCircle, CheckCircle, AlertCircle, RefreshCw, Eye, EyeOff } from 'lucide-react';
import { apiFetch } from '../../../api/apiClient';
import { Modal } from '../../../components/Modal';

interface FaqQuestion {
  maFaq: number;
  maNhom: number;
  cauHoi: string;
  cauTraLoi: string;
  thuTu: number;
  kichHoat: boolean;
  ngayTao: string;
}

interface FaqGroup {
  maNhom: number;
  tenNhom: string;
  thuTu: number;
  kichHoat: boolean;
  cauHoi?: FaqQuestion[];
}

export const SupportFaqTab: React.FC = () => {
  const [groups, setGroups] = useState<FaqGroup[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [toast, setToast] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Group Modal
  const [groupModalOpen, setGroupModalOpen] = useState<boolean>(false);
  const [editingGroup, setEditingGroup] = useState<FaqGroup | null>(null);
  const [groupForm, setGroupForm] = useState<{ tenNhom: string; thuTu: number; kichHoat: boolean }>({
    tenNhom: '',
    thuTu: 1,
    kichHoat: true,
  });

  // Question Modal
  const [questionModalOpen, setQuestionModalOpen] = useState<boolean>(false);
  const [editingQuestion, setEditingQuestion] = useState<FaqQuestion | null>(null);
  const [questionForm, setQuestionForm] = useState<{
    maNhom: number;
    cauHoi: string;
    cauTraLoi: string;
    thuTu: number;
    kichHoat: boolean;
  }>({
    maNhom: 0,
    cauHoi: '',
    cauTraLoi: '',
    thuTu: 1,
    kichHoat: true,
  });

  // Delete Confirm
  const [deleteTarget, setDeleteTarget] = useState<{ type: 'group' | 'question'; id: number; title: string } | null>(null);
  const [submitting, setSubmitting] = useState<boolean>(false);

  const showToast = (type: 'success' | 'error', message: string) => {
    setToast({ type, message });
    setTimeout(() => setToast(null), 4000);
  };

  const fetchFaq = async () => {
    try {
      setLoading(true);
      const res = await apiFetch<any>('/admin/support/faq');
      if (res && res.data) {
        setGroups(res.data);
      }
    } catch (err: any) {
      showToast('error', err.message || 'Lỗi tải danh sách FAQ');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFaq();
  }, []);

  // Save Group
  const handleSaveGroup = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!groupForm.tenNhom.trim()) {
      showToast('error', 'Vui lòng nhập tên nhóm câu hỏi');
      return;
    }
    try {
      setSubmitting(true);
      if (editingGroup) {
        await apiFetch(`/admin/support/faq/groups/${editingGroup.maNhom}`, {
          method: 'PUT',
          body: JSON.stringify(groupForm),
        });
        showToast('success', 'Đã cập nhật nhóm câu hỏi FAQ!');
      } else {
        await apiFetch(`/admin/support/faq/groups`, {
          method: 'POST',
          body: JSON.stringify(groupForm),
        });
        showToast('success', 'Đã tạo nhóm câu hỏi FAQ mới!');
      }
      setGroupModalOpen(false);
      fetchFaq();
    } catch (err: any) {
      showToast('error', err.message || 'Lỗi lưu nhóm FAQ');
    } finally {
      setSubmitting(false);
    }
  };

  // Save Question
  const handleSaveQuestion = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!questionForm.cauHoi.trim() || !questionForm.cauTraLoi.trim()) {
      showToast('error', 'Vui lòng điền đủ câu hỏi và câu trả lời');
      return;
    }
    try {
      setSubmitting(true);
      if (editingQuestion) {
        await apiFetch(`/admin/support/faq/questions/${editingQuestion.maFaq}`, {
          method: 'PUT',
          body: JSON.stringify(questionForm),
        });
        showToast('success', 'Đã cập nhật câu hỏi FAQ!');
      } else {
        await apiFetch(`/admin/support/faq/questions`, {
          method: 'POST',
          body: JSON.stringify(questionForm),
        });
        showToast('success', 'Đã thêm câu hỏi FAQ mới!');
      }
      setQuestionModalOpen(false);
      fetchFaq();
    } catch (err: any) {
      showToast('error', err.message || 'Lỗi lưu câu hỏi FAQ');
    } finally {
      setSubmitting(false);
    }
  };

  // Delete Action
  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    try {
      setSubmitting(true);
      if (deleteTarget.type === 'group') {
        await apiFetch(`/admin/support/faq/groups/${deleteTarget.id}`, { method: 'DELETE' });
        showToast('success', 'Đã xóa nhóm câu hỏi!');
      } else {
        await apiFetch(`/admin/support/faq/questions/${deleteTarget.id}`, { method: 'DELETE' });
        showToast('success', 'Đã xóa câu hỏi FAQ!');
      }
      setDeleteTarget(null);
      fetchFaq();
    } catch (err: any) {
      showToast('error', err.message || 'Lỗi xóa dữ liệu');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      {toast && (
        <div
          style={{
            marginBottom: '16px',
            padding: '12px 16px',
            borderRadius: '10px',
            backgroundColor: toast.type === 'success' ? '#ecfdf5' : '#fef2f2',
            border: `1px solid ${toast.type === 'success' ? '#86efac' : '#fca5a5'}`,
            color: toast.type === 'success' ? '#166534' : '#991b1b',
            display: 'flex',
            alignItems: 'center',
            gap: '8px',
            fontSize: '13px',
            fontWeight: 600,
          }}
        >
          {toast.type === 'success' ? <CheckCircle size={18} /> : <AlertCircle size={18} />}
          {toast.message}
        </div>
      )}

      {/* Header bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h3 style={{ fontSize: '18px', fontWeight: 800, color: '#0f172a' }}>Danh Sách Câu Hỏi Thường Gặp (FAQ)</h3>
          <p style={{ fontSize: '13px', color: '#64748b', marginTop: '2px' }}>
            Mỗi thay đổi tại đây được tự động phát Realtime qua Socket tới các ứng dụng khách
          </p>
        </div>

        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={fetchFaq}
            disabled={loading}
            style={{
              padding: '8px 14px',
              borderRadius: '8px',
              border: '1px solid #e2e8f0',
              backgroundColor: '#ffffff',
              color: '#475569',
              fontSize: '12px',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} /> Làm mới
          </button>
          <button
            onClick={() => {
              setEditingGroup(null);
              setGroupForm({ tenNhom: '', thuTu: groups.length + 1, kichHoat: true });
              setGroupModalOpen(true);
            }}
            style={{
              padding: '8px 16px',
              borderRadius: '8px',
              border: '1px solid #e2e8f0',
              backgroundColor: '#ffffff',
              color: '#0f172a',
              fontSize: '13px',
              fontWeight: 700,
              cursor: 'pointer',
              display: 'inline-flex',
              alignItems: 'center',
              gap: '6px',
            }}
          >
            <FolderPlus size={15} color="#fc6011" /> Thêm Nhóm Mới
          </button>
        </div>
      </div>

      {loading ? (
        <div style={{ padding: '60px', textAlign: 'center', color: '#94a3b8' }}>
          <RefreshCw className="animate-spin inline mr-2" size={22} />
          Đang tải dữ liệu FAQ...
        </div>
      ) : groups.length === 0 ? (
        <div style={{ padding: '60px', textAlign: 'center', color: '#94a3b8', backgroundColor: '#ffffff', borderRadius: '14px', border: '1px solid #e2e8f0' }}>
          Chưa có nhóm FAQ nào. Bấm "Thêm Nhóm Mới" để bắt đầu.
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          {groups.map((g) => (
            <div
              key={g.maNhom}
              style={{
                backgroundColor: '#ffffff',
                borderRadius: '14px',
                border: '1px solid #e2e8f0',
                boxShadow: '0 1px 3px rgba(0,0,0,0.04)',
                overflow: 'hidden',
              }}
            >
              {/* Group Header */}
              <div
                style={{
                  padding: '16px 20px',
                  backgroundColor: '#f8fafc',
                  borderBottom: '1px solid #e2e8f0',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                }}
              >
                <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                  <span
                    style={{
                      width: '28px',
                      height: '28px',
                      borderRadius: '6px',
                      backgroundColor: '#fc6011',
                      color: '#ffffff',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontSize: '12px',
                      fontWeight: 700,
                    }}
                  >
                    {g.thuTu}
                  </span>
                  <div>
                    <h4 style={{ fontSize: '15px', fontWeight: 800, color: '#0f172a' }}>{g.tenNhom}</h4>
                    <span style={{ fontSize: '11px', color: '#64748b' }}>
                      {g.cauHoi?.length || 0} câu hỏi • {g.kichHoat ? 'Đang hiển thị' : 'Đã ẩn'}
                    </span>
                  </div>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                  <button
                    onClick={() => {
                      setEditingQuestion(null);
                      setQuestionForm({
                        maNhom: g.maNhom,
                        cauHoi: '',
                        cauTraLoi: '',
                        thuTu: (g.cauHoi?.length || 0) + 1,
                        kichHoat: true,
                      });
                      setQuestionModalOpen(true);
                    }}
                    style={{
                      padding: '6px 12px',
                      borderRadius: '6px',
                      backgroundColor: '#fc6011',
                      color: '#ffffff',
                      fontSize: '12px',
                      fontWeight: 700,
                      border: 'none',
                      cursor: 'pointer',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '4px',
                    }}
                  >
                    <Plus size={14} /> Thêm Câu Hỏi
                  </button>
                  <button
                    onClick={() => {
                      setEditingGroup(g);
                      setGroupForm({ tenNhom: g.tenNhom, thuTu: g.thuTu, kichHoat: g.kichHoat });
                      setGroupModalOpen(true);
                    }}
                    title="Sửa nhóm"
                    style={{ padding: '6px', borderRadius: '6px', border: '1px solid #e2e8f0', backgroundColor: '#ffffff', cursor: 'pointer' }}
                  >
                    <Edit size={14} color="#475569" />
                  </button>
                  <button
                    onClick={() => setDeleteTarget({ type: 'group', id: g.maNhom, title: g.tenNhom })}
                    title="Xóa nhóm"
                    style={{ padding: '6px', borderRadius: '6px', border: '1px solid #fecaca', backgroundColor: '#fef2f2', cursor: 'pointer' }}
                  >
                    <Trash2 size={14} color="#dc2626" />
                  </button>
                </div>
              </div>

              {/* Questions List */}
              <div style={{ padding: '12px 20px' }}>
                {!g.cauHoi || g.cauHoi.length === 0 ? (
                  <div style={{ padding: '16px', textAlign: 'center', color: '#94a3b8', fontSize: '13px' }}>
                    Chưa có câu hỏi nào trong nhóm này.
                  </div>
                ) : (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                    {g.cauHoi.map((q) => (
                      <div
                        key={q.maFaq}
                        style={{
                          padding: '12px 16px',
                          borderRadius: '8px',
                          border: '1px solid #f1f5f9',
                          backgroundColor: q.kichHoat ? '#ffffff' : '#f8fafc',
                          display: 'flex',
                          justifyContent: 'space-between',
                          alignItems: 'flex-start',
                          gap: '12px',
                        }}
                      >
                        <div style={{ flex: 1 }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '4px' }}>
                            <span style={{ fontSize: '11px', fontWeight: 700, color: '#fc6011', backgroundColor: '#fff7ed', padding: '2px 6px', borderRadius: '4px' }}>
                              #{q.thuTu}
                            </span>
                            <span style={{ fontSize: '14px', fontWeight: 700, color: '#0f172a' }}>{q.cauHoi}</span>
                            {!q.kichHoat && (
                              <span style={{ fontSize: '10px', color: '#94a3b8', backgroundColor: '#f1f5f9', padding: '2px 6px', borderRadius: '4px' }}>
                                Đã ẩn
                              </span>
                            )}
                          </div>
                          <p style={{ fontSize: '13px', color: '#475569', lineHeight: 1.6, whiteSpace: 'pre-wrap', marginTop: '4px' }}>
                            {q.cauTraLoi}
                          </p>
                        </div>

                        <div style={{ display: 'flex', gap: '6px', flexShrink: 0 }}>
                          <button
                            onClick={() => {
                              setEditingQuestion(q);
                              setQuestionForm({
                                maNhom: q.maNhom,
                                cauHoi: q.cauHoi,
                                cauTraLoi: q.cauTraLoi,
                                thuTu: q.thuTu,
                                kichHoat: q.kichHoat,
                              });
                              setQuestionModalOpen(true);
                            }}
                            title="Sửa câu hỏi"
                            style={{ padding: '6px', borderRadius: '6px', border: '1px solid #e2e8f0', backgroundColor: '#ffffff', cursor: 'pointer' }}
                          >
                            <Edit size={13} color="#475569" />
                          </button>
                          <button
                            onClick={() => setDeleteTarget({ type: 'question', id: q.maFaq, title: q.cauHoi })}
                            title="Xóa câu hỏi"
                            style={{ padding: '6px', borderRadius: '6px', border: '1px solid #fecaca', backgroundColor: '#fef2f2', cursor: 'pointer' }}
                          >
                            <Trash2 size={13} color="#dc2626" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal 1: Group Form */}
      <Modal
        isOpen={groupModalOpen}
        onClose={() => setGroupModalOpen(false)}
        title={editingGroup ? 'Chỉnh Sửa Nhóm FAQ' : 'Thêm Nhóm FAQ Mới'}
        maxWidth="500px"
      >
        <form onSubmit={handleSaveGroup} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
              Tên nhóm câu hỏi *
            </label>
            <input
              type="text"
              placeholder="Ví dụ: Đơn hàng & Lộ trình ghé lấy"
              value={groupForm.tenNhom}
              onChange={(e) => setGroupForm({ ...groupForm, tenNhom: e.target.value })}
              style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
                Thứ tự hiển thị
              </label>
              <input
                type="number"
                value={groupForm.thuTu}
                onChange={(e) => setGroupForm({ ...groupForm, thuTu: Number(e.target.value) })}
                style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
                Trạng thái
              </label>
              <select
                value={groupForm.kichHoat ? '1' : '0'}
                onChange={(e) => setGroupForm({ ...groupForm, kichHoat: e.target.value === '1' })}
                style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
              >
                <option value="1">Hiển thị (Kích hoạt)</option>
                <option value="0">Tạm ẩn</option>
              </select>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', paddingTop: '10px', borderTop: '1px solid #f1f5f9' }}>
            <button type="button" onClick={() => setGroupModalOpen(false)} style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #cbd5e1', backgroundColor: '#fff', cursor: 'pointer', fontSize: '13px' }}>
              Hủy
            </button>
            <button type="submit" disabled={submitting} style={{ padding: '8px 20px', borderRadius: '8px', backgroundColor: '#fc6011', color: '#fff', fontWeight: 700, border: 'none', cursor: 'pointer', fontSize: '13px' }}>
              {submitting ? 'Đang lưu...' : 'Lưu Nhóm'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Modal 2: Question Form */}
      <Modal
        isOpen={questionModalOpen}
        onClose={() => setQuestionModalOpen(false)}
        title={editingQuestion ? 'Chỉnh Sửa Câu Hỏi FAQ' : 'Thêm Câu Hỏi FAQ Mới'}
        maxWidth="650px"
      >
        <form onSubmit={handleSaveQuestion} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <div>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
              Nhóm FAQ *
            </label>
            <select
              value={questionForm.maNhom}
              onChange={(e) => setQuestionForm({ ...questionForm, maNhom: Number(e.target.value) })}
              style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
            >
              {groups.map((g) => (
                <option key={g.maNhom} value={g.maNhom}>{g.tenNhom}</option>
              ))}
            </select>
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
              Câu hỏi *
            </label>
            <input
              type="text"
              placeholder="Ví dụ: Làm sao để hủy đơn hàng đã đặt?"
              value={questionForm.cauHoi}
              onChange={(e) => setQuestionForm({ ...questionForm, cauHoi: e.target.value })}
              style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
            />
          </div>

          <div>
            <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
              Câu trả lời chi tiết *
            </label>
            <textarea
              rows={6}
              placeholder="Nhập nội dung giải đáp cho khách hàng..."
              value={questionForm.cauTraLoi}
              onChange={(e) => setQuestionForm({ ...questionForm, cauTraLoi: e.target.value })}
              style={{ width: '100%', padding: '10px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px', lineHeight: 1.6 }}
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
                Thứ tự
              </label>
              <input
                type="number"
                value={questionForm.thuTu}
                onChange={(e) => setQuestionForm({ ...questionForm, thuTu: Number(e.target.value) })}
                style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
              />
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '12px', fontWeight: 700, color: '#475569', marginBottom: '6px' }}>
                Trạng thái
              </label>
              <select
                value={questionForm.kichHoat ? '1' : '0'}
                onChange={(e) => setQuestionForm({ ...questionForm, kichHoat: e.target.value === '1' })}
                style={{ width: '100%', padding: '9px 12px', borderRadius: '8px', border: '1px solid #cbd5e1', fontSize: '13px' }}
              >
                <option value="1">Hiển thị (Kích hoạt)</option>
                <option value="0">Tạm ẩn</option>
              </select>
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', paddingTop: '10px', borderTop: '1px solid #f1f5f9' }}>
            <button type="button" onClick={() => setQuestionModalOpen(false)} style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #cbd5e1', backgroundColor: '#fff', cursor: 'pointer', fontSize: '13px' }}>
              Hủy
            </button>
            <button type="submit" disabled={submitting} style={{ padding: '8px 20px', borderRadius: '8px', backgroundColor: '#fc6011', color: '#fff', fontWeight: 700, border: 'none', cursor: 'pointer', fontSize: '13px' }}>
              {submitting ? 'Đang lưu...' : 'Lưu Câu Hỏi'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Modal 3: Delete Confirm */}
      <Modal
        isOpen={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        title="Xác Nhận Xóa"
        maxWidth="450px"
      >
        <div style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          <p style={{ fontSize: '13px', color: '#475569', lineHeight: 1.5 }}>
            Bạn có chắc chắn muốn xóa {deleteTarget?.type === 'group' ? 'nhóm' : 'câu hỏi'}: <strong>"{deleteTarget?.title}"</strong>?
            {deleteTarget?.type === 'group' && ' Toàn bộ các câu hỏi thuộc nhóm này cũng sẽ bị xóa.'}
          </p>
          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', paddingTop: '10px', borderTop: '1px solid #f1f5f9' }}>
            <button onClick={() => setDeleteTarget(null)} style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #cbd5e1', backgroundColor: '#fff', cursor: 'pointer', fontSize: '13px' }}>
              Hủy
            </button>
            <button onClick={handleDeleteConfirm} disabled={submitting} style={{ padding: '8px 20px', borderRadius: '8px', backgroundColor: '#dc2626', color: '#fff', fontWeight: 700, border: 'none', cursor: 'pointer', fontSize: '13px' }}>
              {submitting ? 'Đang xóa...' : 'Xác Nhận Xóa'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
};

