import React, { useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { TableDetailModal } from './TableDetailModal';
import { Plus, Edit3, Power, Utensils, Users, CheckCircle, AlertCircle, RefreshCw, Eye, Calendar } from 'lucide-react';

interface TableManagementViewProps {
  tables: any[];
  reservations: any[];
  onRefresh: () => void;
  loading: boolean;
  onSelectReservation: (res: any) => void;
}

export const TableManagementView: React.FC<TableManagementViewProps> = ({
  tables,
  reservations,
  onRefresh,
  loading,
  onSelectReservation,
}) => {
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingTable, setEditingTable] = useState<any | null>(null);
  const [selectedTableForDetail, setSelectedTableForDetail] = useState<any | null>(null);

  const [tenBan, setTenBan] = useState('');
  const [sucChua, setSucChua] = useState(4);
  const [actionLoading, setActionLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);


  const handleOpenAdd = () => {
    setTenBan('');
    setSucChua(4);
    setError(null);
    setShowAddModal(true);
  };

  const handleOpenEdit = (table: any) => {
    setEditingTable(table);
    setTenBan(table.tenBan);
    setSucChua(table.sucChua);
    setError(null);
  };

  const handleSaveTable = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!tenBan.trim()) {
      setError('Tên bàn không được để trống');
      return;
    }
    if (sucChua < 1) {
      setError('Sức chứa tối thiểu 1 người');
      return;
    }

    try {
      setActionLoading(true);
      if (editingTable) {
        await apiFetch(`/restaurant/tables/${editingTable.maBan}`, {
          method: 'PUT',
          body: JSON.stringify({ tenBan: tenBan.trim(), sucChua }),
        });
        setEditingTable(null);
      } else {
        await apiFetch('/restaurant/tables', {
          method: 'POST',
          body: JSON.stringify({ tenBan: tenBan.trim(), sucChua }),
        });
        setShowAddModal(false);
      }
      onRefresh();
    } catch (err: any) {
      setError(err.message || 'Không thể lưu thông tin bàn');
    } finally {
      setActionLoading(false);
    }
  };

  const handleToggleStatus = async (table: any) => {
    const nextStatus = table.trangThai === 'TAM_NGUNG' ? 'TRONG' : 'TAM_NGUNG';
    try {
      setActionLoading(true);
      await apiFetch(`/restaurant/tables/${table.maBan}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ trangThai: nextStatus }),
      });
      onRefresh();
    } catch (err: any) {
      alert(err.message || 'Lỗi cập nhật trạng thái bàn');
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div style={{ marginTop: '20px' }}>
      {/* Top action bar */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h3 style={{ margin: 0, fontSize: '18px', fontWeight: 700, color: '#1e293b' }}>
            Danh Sách Bàn Phục Vụ ({tables.length} bàn)
          </h3>
          <p style={{ margin: '4px 0 0 0', fontSize: '13px', color: '#64748b' }}>
            Quản lý tên bàn, sức chứa và trạng thái hoạt động của từng bàn
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <button
            onClick={onRefresh}
            className="btn"
            style={{ background: '#f1f5f9', color: '#475569', display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <RefreshCw size={16} className={loading ? 'spin' : ''} /> Làm mới
          </button>
          <button
            onClick={handleOpenAdd}
            className="btn btn-primary"
            style={{ background: '#fc6011', borderColor: '#fc6011', display: 'flex', alignItems: 'center', gap: '6px' }}
          >
            <Plus size={18} /> Thêm Bàn Mới
          </button>
        </div>
      </div>

      {/* Grid of Tables */}
      {tables.length === 0 ? (
        <div
          style={{
            background: '#fff',
            borderRadius: '16px',
            padding: '48px 24px',
            textAlign: 'center',
            border: '1px dashed #cbd5e1',
          }}
        >
          <Utensils size={48} color="#cbd5e1" style={{ marginBottom: '12px' }} />
          <h4 style={{ margin: '0 0 6px 0', fontSize: '16px', color: '#334155' }}>Chưa có bàn nào được khai báo</h4>
          <p style={{ margin: 0, fontSize: '14px', color: '#94a3b8' }}>
            Bấm "Thêm Bàn Mới" ở trên để khởi tạo danh sách bàn phục vụ tại nhà hàng.
          </p>
        </div>
      ) : (
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))',
            gap: '16px',
          }}
        >
          {tables.map((table) => {
            const isInactive = table.trangThai === 'TAM_NGUNG';
            const isOccupied = table.trangThai === 'DANG_SU_DUNG';
            const isArrived = table.trangThai === 'DA_DEN';
            const isBooked = table.trangThai === 'DA_DAT';

            let statusBg = '#f0fdf4';
            let statusColor = '#16a34a';
            let statusText = 'Bàn trống';

            if (isInactive) {
              statusBg = '#f1f5f9';
              statusColor = '#64748b';
              statusText = 'Tạm ngưng';
            } else if (isOccupied) {
              statusBg = '#f3e8ff';
              statusColor = '#7e22ce';
              statusText = 'Đang phục vụ';
            } else if (isArrived) {
              statusBg = '#e0f2fe';
              statusColor = '#0284c7';
              statusText = 'Khách đã đến';
            } else if (isBooked) {
              statusBg = '#fff7ed';
              statusColor = '#ea580c';
              statusText = 'Đang đặt';
            }



            return (
              <div
                key={table.maBan}
                style={{
                  background: isInactive ? '#fafafa' : '#ffffff',
                  borderRadius: '14px',
                  padding: '18px',
                  border: isInactive ? '1px solid #e2e8f0' : '1px solid #cbd5e1',
                  boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
                  opacity: isInactive ? 0.75 : 1,
                  display: 'flex',
                  flexDirection: 'column',
                  justifyContent: 'space-between',
                  gap: '16px',
                }}
              >
                <div
                  onClick={() => setSelectedTableForDetail(table)}
                  style={{ cursor: 'pointer' }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '8px' }}>
                    <div style={{ fontSize: '18px', fontWeight: 800, color: isInactive ? '#64748b' : '#1e293b' }}>
                      {table.tenBan}
                    </div>
                    <span
                      style={{
                        fontSize: '12px',
                        fontWeight: 700,
                        padding: '4px 10px',
                        borderRadius: '20px',
                        background: statusBg,
                        color: statusColor,
                      }}
                    >
                      {statusText}
                    </span>
                  </div>

                  <div style={{ fontSize: '13px', color: '#64748b', display: 'flex', alignItems: 'center', gap: '6px' }}>
                    <Users size={15} color="#94a3b8" /> Sức chứa: <strong style={{ color: '#334155' }}>{table.sucChua} người</strong>
                  </div>
                </div>

                <div
                  style={{
                    display: 'flex',
                    gap: '6px',
                    borderTop: '1px solid #f1f5f9',
                    paddingTop: '12px',
                  }}
                >
                  <button
                    onClick={() => setSelectedTableForDetail(table)}
                    className="btn"
                    style={{ flex: 1, background: '#f0f9ff', color: '#0284c7', border: '1px solid #bae6fd', fontSize: '12px', padding: '6px 8px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px', fontWeight: 600 }}
                  >
                    <Eye size={13} /> Xem lịch
                  </button>
                  <button
                    onClick={() => handleOpenEdit(table)}
                    className="btn"
                    style={{ background: '#f8fafc', color: '#334155', border: '1px solid #e2e8f0', fontSize: '12px', padding: '6px 8px', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '4px' }}
                  >
                    <Edit3 size={13} /> Sửa
                  </button>
                  <button
                    onClick={() => handleToggleStatus(table)}
                    disabled={isOccupied}
                    className="btn"
                    style={{
                      background: isInactive ? '#ecfdf5' : '#fef2f2',
                      color: isInactive ? '#059669' : '#dc2626',
                      border: 'none',
                      fontSize: '12px',
                      padding: '6px 8px',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '4px',
                    }}
                  >
                    <Power size={13} /> {isInactive ? 'Bật' : 'Khóa'}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Table Detail & Matching Reservations Modal */}
      <TableDetailModal
        isOpen={!!selectedTableForDetail}
        onClose={() => setSelectedTableForDetail(null)}
        table={selectedTableForDetail}
        reservations={reservations}
        onSelectReservation={onSelectReservation}
      />


      {/* Add / Edit Table Modal */}
      {(showAddModal || editingTable) && (
        <div
          className="modal-backdrop"
          onClick={() => { setShowAddModal(false); setEditingTable(null); }}
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
              maxWidth: '420px',
              width: '100%',
              borderRadius: '16px',
              padding: '24px',
              background: '#ffffff',
              boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
            }}
          >

            <h3 style={{ margin: '0 0 16px 0', fontSize: '18px', fontWeight: 700, color: '#1e293b' }}>
              {editingTable ? `Chỉnh Sửa ${editingTable.tenBan}` : 'Thêm Bàn Mới'}
            </h3>

            {error && (
              <div style={{ background: '#fef2f2', color: '#dc2626', padding: '8px 12px', borderRadius: '8px', fontSize: '13px', marginBottom: '12px' }}>
                ⚠️ {error}
              </div>
            )}

            <form onSubmit={handleSaveTable} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
              <div>
                <label style={{ fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '4px', display: 'block' }}>Tên bàn *</label>
                <input
                  type="text"
                  placeholder="Ví dụ: Bàn 01, VIP 02..."
                  value={tenBan}
                  onChange={(e) => setTenBan(e.target.value)}
                  className="form-control"
                  style={{ width: '100%', padding: '9px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
                />
              </div>

              <div>
                <label style={{ fontSize: '13px', fontWeight: 600, color: '#475569', marginBottom: '4px', display: 'block' }}>Sức chứa (số người) *</label>
                <input
                  type="number"
                  min={1}
                  max={100}
                  value={sucChua}
                  onChange={(e) => setSucChua(Number(e.target.value))}
                  className="form-control"
                  style={{ width: '100%', padding: '9px', borderRadius: '8px', border: '1px solid #cbd5e1' }}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '12px' }}>
                <button
                  type="button"
                  onClick={() => { setShowAddModal(false); setEditingTable(null); }}
                  className="btn"
                  style={{ background: '#f1f5f9', color: '#475569' }}
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  disabled={actionLoading}
                  className="btn btn-primary"
                  style={{ background: '#fc6011', borderColor: '#fc6011' }}
                >
                  {actionLoading ? 'Đang lưu...' : 'Lưu lại'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
