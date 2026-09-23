import React, { useEffect, useState } from 'react';
import { apiFetch } from '../../api/apiClient';
import { StatusBadge } from '../../components/StatusBadge';
import { Modal } from '../../components/Modal';
import { Search, Shield } from 'lucide-react';

export const AdminUsers: React.FC = () => {
  const [data, setData] = useState<any>({ items: [], total: 0 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [newRole, setNewRole] = useState('KHACH_HANG');

  const fetchUsers = () => {
    setLoading(true);
    apiFetch<any>(`/admin/users?search=${encodeURIComponent(search)}`)
      .then((res) => setData(res.data))
      .catch((err) => console.error(err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchUsers();
  }, [search]);

  const handleUpdateRole = async () => {
    if (!selectedUser) return;
    try {
      await apiFetch(`/admin/users/${selectedUser.maTaiKhoan}/role`, {
        method: 'PUT',
        body: JSON.stringify({ loaiTaiKhoan: newRole }),
      });
      setSelectedUser(null);
      fetchUsers();
    } catch (err: any) {
      alert(err.message || 'Lỗi cập nhật');
    }
  };

  return (
    <div>
      <div className="page-header">
        <div>
          <h1 className="page-title">Quản Lý Người Dùng</h1>
          <p className="page-subtitle">Danh sách tài khoản & phân quyền trong hệ thống</p>
        </div>
      </div>

      <div className="card-table">
        <div className="table-toolbar">
          <div className="search-input-group">
            <Search size={16} />
            <input
              type="text"
              placeholder="Tìm theo tên đăng nhập, email, số điện thoại..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: '40px' }}><div className="loading-spinner" /></div>
        ) : data.items.length === 0 ? (
          <div className="empty-state">Không tìm thấy tài khoản nào</div>
        ) : (
          <table className="data-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Tên Đăng Nhập</th>
                <th>Họ & Tên</th>
                <th>Email / SĐT</th>
                <th>Vai Trò</th>
                <th>Trạng Thái</th>
                <th>Hành Động</th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((u: any) => (
                <tr key={u.maTaiKhoan}>
                  <td style={{ fontWeight: 700 }}>#{u.maTaiKhoan}</td>
                  <td style={{ fontWeight: 600 }}>{u.tenDangNhap}</td>
                  <td>{u.khachHang?.hoTen || 'Chưa cập nhật'}</td>
                  <td>
                    <div>{u.khachHang?.email || u.tenDangNhap}</div>
                    <div style={{ fontSize: '11px', color: '#64748b' }}>{u.khachHang?.sdt || ''}</div>
                  </td>
                  <td><StatusBadge status={u.loaiTaiKhoan} /></td>
                  <td><span className="badge badge-success">{u.trangThai}</span></td>
                  <td>
                    <button
                      className="btn btn-outline btn-sm"
                      onClick={() => {
                        setSelectedUser(u);
                        setNewRole(u.loaiTaiKhoan);
                      }}
                    >
                      <Shield size={14} /> Phân Quyền
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      <Modal isOpen={!!selectedUser} onClose={() => setSelectedUser(null)} title="Thay Đổi Phân Quyền Tài Khoản">
        {selectedUser && (
          <div>
            <div className="form-group">
              <label className="form-label">Tài khoản</label>
              <input type="text" className="form-control" value={selectedUser.tenDangNhap} disabled />
            </div>
            <div className="form-group">
              <label className="form-label">Chọn Vai Trò Mới</label>
              <select className="form-control" value={newRole} onChange={(e) => setNewRole(e.target.value)}>
                <option value="KHACH_HANG">Khách Hàng (KHACH_HANG)</option>
                <option value="CUAN_HANG">Chủ Nhà Hàng (CUAN_HANG)</option>
                <option value="ADMIN">Quản Trị Viên (ADMIN)</option>
              </select>
            </div>
            <div className="modal-footer" style={{ margin: '-24px', marginTop: '24px' }}>
              <button className="btn btn-outline" onClick={() => setSelectedUser(null)}>Hủy</button>
              <button className="btn btn-primary" onClick={handleUpdateRole}>Lưu Thay Đổi</button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
