import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  Inbox,
  Search,
  RefreshCw,
  Send,
  Image as ImageIcon,
  CheckCheck,
  Check,
  Clock,
  User,
  Phone,
  Store,
  Receipt,
  X,
  ChevronRight,
  Filter,
} from 'lucide-react';
import { apiFetch, API_HOST } from '../../../api/apiClient';
import { getSocket, joinTicketRoom, leaveTicketRoom } from '../../../api/socketClient';
import { getImageUrl } from '../../../utils/imageUtils';
import { Modal } from '../../../components/Modal';

export interface TicketItem {
  maPhieu: number;
  maTaiKhoan: number;
  tieuDe?: string;
  loaiSuCo: string;
  moTa: string;
  maDonHang?: number;
  danhSachAnh?: string[];
  trangThai: 'MOI' | 'DANG_XU_LY' | 'DA_GIAI_QUYET' | 'DA_DONG';
  soTinChuaDocAdmin: number;
  soTinChuaDocUser: number;
  tinNhanCuoi?: string;
  thoiGianTinCuoi?: string;
  ngayTao: string;
  sender?: {
    maTaiKhoan: number;
    displayName: string;
    phone: string;
    role: string;
    storeName?: string;
  };
}

export interface TicketMessage {
  maTinNhan: number;
  maPhieu: number;
  maTaiKhoanGui: number;
  vaiTroGui: 'USER' | 'ADMIN' | 'STORE';
  noiDung: string;
  danhSachAnh?: string[];
  daXem: boolean;
  thoiGianXem?: string | null;
  ngayTao: string;
}

const STATUS_STYLE: Record<string, { label: string; bg: string; text: string; border: string }> = {
  MOI: { label: 'Mới', bg: '#eff6ff', text: '#1d4ed8', border: '#bfdbfe' },
  DANG_XU_LY: { label: 'Đang xử lý', bg: '#fffbeb', text: '#b45309', border: '#fde68a' },
  DA_GIAI_QUYET: { label: 'Đã giải quyết', bg: '#ecfdf5', text: '#047857', border: '#a7f3d0' },
  DA_DONG: { label: 'Đã đóng', bg: '#f1f5f9', text: '#475569', border: '#cbd5e1' },
};

const ISSUE_TYPE_MAP: Record<string, string> = {
  DON_HANG: 'Đơn hàng',
  THANH_TOAN: 'Thanh toán',
  QUAN_AN: 'Quán ăn',
  LOI_UNG_DUNG: 'Lỗi ứng dụng',
  KHAC: 'Khác',
};

export const SupportInboxTab: React.FC = () => {
  const [tickets, setTickets] = useState<TicketItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedTicket, setSelectedTicket] = useState<TicketItem | null>(null);

  // Filters
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [typeFilter, setTypeFilter] = useState<string>('ALL');
  const [searchTerm, setSearchTerm] = useState<string>('');

  // Messages in active chat
  const [messages, setMessages] = useState<TicketMessage[]>([]);
  const [loadingMessages, setLoadingMessages] = useState<boolean>(false);
  const [inputText, setInputText] = useState<string>('');
  const [sending, setSending] = useState<boolean>(false);
  const [uploadingImage, setUploadingImage] = useState<boolean>(false);
  const [pendingImages, setPendingImages] = useState<string[]>([]);

  // Preview Image Modal
  const [previewImage, setPreviewImage] = useState<string | null>(null);

  const messagesEndRef = useRef<HTMLDivElement | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const scrollToBottom = (smooth = true) => {
    messagesEndRef.current?.scrollIntoView({ behavior: smooth ? 'smooth' : 'auto' });
  };

  const fetchTickets = useCallback(async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams();
      if (statusFilter !== 'ALL') params.append('status', statusFilter);
      if (typeFilter !== 'ALL') params.append('loaiSuCo', typeFilter);
      if (searchTerm.trim()) params.append('search', searchTerm.trim());

      const res = await apiFetch<any>(`/admin/support/tickets?${params.toString()}`);
      if (res && res.items) {
        setTickets(res.items);
      }
    } catch (e) {
      console.error('Error fetching tickets:', e);
    } finally {
      setLoading(false);
    }
  }, [statusFilter, typeFilter, searchTerm]);

  useEffect(() => {
    fetchTickets();
  }, [fetchTickets]);

  const loadMessages = useCallback(async (ticketId: number) => {
    try {
      setLoadingMessages(true);
      const res = await apiFetch<any>(`/admin/support/tickets/${ticketId}/messages?limit=50`);
      if (res && res.data) {
        setMessages(res.data);
        setTimeout(() => scrollToBottom(false), 80);
      }
      await apiFetch(`/admin/support/tickets/${ticketId}/read`, { method: 'POST' }).catch(() => {});
      setTickets((prev) =>
        prev.map((t) => (t.maPhieu === ticketId ? { ...t, soTinChuaDocAdmin: 0 } : t))
      );
    } catch (e) {
      console.error('Error loading messages:', e);
    } finally {
      setLoadingMessages(false);
    }
  }, []);

  const handleSelectTicket = (ticket: TicketItem) => {
    if (selectedTicket?.maPhieu) {
      leaveTicketRoom(selectedTicket.maPhieu);
    }
    setSelectedTicket(ticket);
    joinTicketRoom(ticket.maPhieu);
    loadMessages(ticket.maPhieu);
  };

  // Realtime Socket
  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const handleNewTicket = (ticket: any) => {
      setTickets((prev) => [ticket, ...prev.filter((t) => t.maPhieu !== ticket.maPhieu)]);
    };

    const handleNewMessage = (msg: any) => {
      if (selectedTicket && Number(msg.maPhieu) === selectedTicket.maPhieu) {
        setMessages((prev) => {
          if (prev.some((m) => m.maTinNhan === msg.maTinNhan)) return prev;
          return [...prev, msg];
        });
        setTimeout(() => scrollToBottom(true), 50);

        if (msg.vaiTroGui === 'USER') {
          apiFetch(`/admin/support/tickets/${selectedTicket.maPhieu}/read`, { method: 'POST' }).catch(() => {});
        }
      }

      setTickets((prev) => {
        const found = prev.find((t) => t.maPhieu === Number(msg.maPhieu));
        if (!found) return prev;
        const updated: TicketItem = {
          ...found,
          tinNhanCuoi: msg.noiDung,
          thoiGianTinCuoi: msg.ngayTao,
          trangThai: msg.ticketStatus || found.trangThai,
          soTinChuaDocAdmin:
            selectedTicket && selectedTicket.maPhieu === found.maPhieu
              ? 0
              : msg.vaiTroGui === 'USER'
              ? (found.soTinChuaDocAdmin || 0) + 1
              : found.soTinChuaDocAdmin,
        };
        return [updated, ...prev.filter((t) => t.maPhieu !== found.maPhieu)];
      });
    };

    const handleStatusChanged = (data: { maPhieu: number; trangThai: any }) => {
      setTickets((prev) =>
        prev.map((t) => (t.maPhieu === Number(data.maPhieu) ? { ...t, trangThai: data.trangThai } : t))
      );
      if (selectedTicket && selectedTicket.maPhieu === Number(data.maPhieu)) {
        setSelectedTicket((prev) => (prev ? { ...prev, trangThai: data.trangThai } : null));
      }
    };

    const handleMessageRead = (data: { maPhieu: number; readerRole: string }) => {
      if (selectedTicket && selectedTicket.maPhieu === Number(data.maPhieu)) {
        if (data.readerRole === 'USER') {
          setMessages((prev) =>
            prev.map((m) => (m.vaiTroGui === 'ADMIN' ? { ...m, daXem: true } : m))
          );
        }
      }
    };

    socket.on('ticket:created', handleNewTicket);
    socket.on('ticket:message_new', handleNewMessage);
    socket.on('ticket:status_changed', handleStatusChanged);
    socket.on('ticket:message_read', handleMessageRead);

    return () => {
      socket.off('ticket:created', handleNewTicket);
      socket.off('ticket:message_new', handleNewMessage);
      socket.off('ticket:status_changed', handleStatusChanged);
      socket.off('ticket:message_read', handleMessageRead);
    };
  }, [selectedTicket]);

  useEffect(() => {
    return () => {
      if (selectedTicket?.maPhieu) {
        leaveTicketRoom(selectedTicket.maPhieu);
      }
    };
  }, [selectedTicket]);

  const handleUpdateStatus = async (newStatus: TicketItem['trangThai']) => {
    if (!selectedTicket) return;
    try {
      const res = await apiFetch<any>(`/admin/support/tickets/${selectedTicket.maPhieu}/status`, {
        method: 'PUT',
        body: JSON.stringify({ trangThai: newStatus }),
      });
      if (res && res.success) {
        setSelectedTicket((prev) => (prev ? { ...prev, trangThai: newStatus } : null));
        setTickets((prev) =>
          prev.map((t) => (t.maPhieu === selectedTicket.maPhieu ? { ...t, trangThai: newStatus } : t))
        );
      }
    } catch (e: any) {
      alert(`Lỗi đổi trạng thái: ${e.message}`);
    }
  };

  const handleUploadImage = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (pendingImages.length >= 3) {
      alert('Tối đa đính kèm 3 ảnh mỗi tin nhắn');
      return;
    }

    try {
      setUploadingImage(true);
      const formData = new FormData();
      formData.append('file', file);
      const res = await apiFetch<{ url: string }>('/upload', {
        method: 'POST',
        body: formData,
      });

      if (res && res.url) {
        setPendingImages((prev) => [...prev, res.url]);
      }
    } catch (err: any) {
      alert(`Lỗi upload ảnh: ${err.message || 'Thử lại sau'}`);
    } finally {
      setUploadingImage(false);
      if (fileInputRef.current) fileInputRef.current.value = '';
    }
  };

  const handleSendMessage = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!selectedTicket || (!inputText.trim() && pendingImages.length === 0)) return;

    const textToSend = inputText.trim();
    const imagesToSend = [...pendingImages];
    setInputText('');
    setPendingImages([]);

    try {
      setSending(true);
      const res = await apiFetch<any>(`/admin/support/tickets/${selectedTicket.maPhieu}/messages`, {
        method: 'POST',
        body: JSON.stringify({
          noiDung: textToSend,
          danhSachAnh: imagesToSend,
        }),
      });

      if (res && res.data) {
        setMessages((prev) => {
          if (prev.some((m) => m.maTinNhan === res.data.maTinNhan)) return prev;
          return [...prev, res.data];
        });
        setTimeout(() => scrollToBottom(true), 50);
      }
    } catch (err: any) {
      alert(`Gửi tin nhắn thất bại: ${err.message}`);
      setInputText(textToSend);
      setPendingImages(imagesToSend);
    } finally {
      setSending(false);
    }
  };

  return (
    <div
      style={{
        backgroundColor: '#ffffff',
        borderRadius: '16px',
        border: '1px solid #e2e8f0',
        overflow: 'hidden',
        display: 'flex',
        height: '740px',
        boxShadow: '0 2px 8px rgba(0,0,0,0.03)',
      }}
    >
      {/* LEFT PANEL: Ticket List */}
      <div
        style={{
          width: '390px',
          borderRight: '1px solid #e2e8f0',
          display: 'flex',
          flexDirection: 'column',
          backgroundColor: '#f8fafc',
          flexShrink: 0,
        }}
      >
        {/* Search & Filters */}
        <div style={{ padding: '14px 16px', borderBottom: '1px solid #e2e8f0', backgroundColor: '#ffffff' }}>
          <div style={{ position: 'relative', marginBottom: '10px' }}>
            <Search
              size={15}
              style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }}
            />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Tìm theo người gửi, SĐT, mã #..."
              style={{
                width: '100%',
                padding: '8px 12px 8px 32px',
                borderRadius: '10px',
                border: '1px solid #cbd5e1',
                fontSize: '13px',
                outline: 'none',
                backgroundColor: '#f8fafc',
                boxSizing: 'border-box',
              }}
            />
          </div>

          <div style={{ display: 'flex', gap: '8px' }}>
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              style={{
                flex: 1,
                padding: '6px 8px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '12px',
                fontWeight: 600,
                color: '#334155',
                backgroundColor: '#ffffff',
                outline: 'none',
              }}
            >
              <option value="ALL">Mọi trạng thái</option>
              <option value="MOI">Mới</option>
              <option value="DANG_XU_LY">Đang xử lý</option>
              <option value="DA_GIAI_QUYET">Đã giải quyết</option>
              <option value="DA_DONG">Đã đóng</option>
            </select>

            <select
              value={typeFilter}
              onChange={(e) => setTypeFilter(e.target.value)}
              style={{
                flex: 1,
                padding: '6px 8px',
                borderRadius: '8px',
                border: '1px solid #cbd5e1',
                fontSize: '12px',
                fontWeight: 600,
                color: '#334155',
                backgroundColor: '#ffffff',
                outline: 'none',
              }}
            >
              <option value="ALL">Mọi sự cố</option>
              <option value="DON_HANG">Đơn hàng</option>
              <option value="THANH_TOAN">Thanh toán</option>
              <option value="QUAN_AN">Quán ăn</option>
              <option value="LOI_UNG_DUNG">Lỗi ứng dụng</option>
              <option value="KHAC">Khác</option>
            </select>
          </div>
        </div>

        {/* Tickets Scrollable List */}
        <div style={{ flex: 1, overflowY: 'auto' }}>
          {loading ? (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '60px 20px', color: '#94a3b8', fontSize: '13px' }}>
              <RefreshCw size={22} className="animate-spin" style={{ color: '#fc6011', marginBottom: '8px' }} />
              <span>Đang tải danh sách phiếu...</span>
            </div>
          ) : tickets.length === 0 ? (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '60px 20px', color: '#94a3b8', textAlign: 'center' }}>
              <Inbox size={42} style={{ color: '#cbd5e1', marginBottom: '10px' }} />
              <p style={{ fontWeight: 600, color: '#475569', fontSize: '14px', margin: 0 }}>Không có phiếu hỗ trợ nào</p>
              <p style={{ fontSize: '12px', color: '#94a3b8', marginTop: '4px', margin: 0 }}>Khi có yêu cầu, phiếu sẽ xuất hiện tại đây</p>
            </div>
          ) : (
            tickets.map((t) => {
              const isSelected = selectedTicket?.maPhieu === t.maPhieu;
              const statusCfg = STATUS_STYLE[t.trangThai] || STATUS_STYLE.MOI;
              const hasUnread = (t.soTinChuaDocAdmin || 0) > 0;

              return (
                <div
                  key={t.maPhieu}
                  onClick={() => handleSelectTicket(t)}
                  style={{
                    padding: '14px 16px',
                    cursor: 'pointer',
                    borderBottom: '1px solid #f1f5f9',
                    backgroundColor: isSelected ? '#ffffff' : 'transparent',
                    borderLeft: isSelected ? '4px solid #fc6011' : '4px solid transparent',
                    boxShadow: isSelected ? '0 1px 3px rgba(0,0,0,0.05)' : 'none',
                    transition: 'all 0.1s ease',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '4px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ fontSize: '12.5px', fontWeight: 800, color: '#0f172a' }}>#{t.maPhieu}</span>
                      <span style={{ fontSize: '11px', fontWeight: 600, color: '#475569', backgroundColor: '#e2e8f0', padding: '2px 6px', borderRadius: '6px' }}>
                        {ISSUE_TYPE_MAP[t.loaiSuCo] || t.loaiSuCo}
                      </span>
                    </div>

                    <span
                      style={{
                        fontSize: '11px',
                        fontWeight: 700,
                        padding: '2px 8px',
                        borderRadius: '12px',
                        backgroundColor: statusCfg.bg,
                        color: statusCfg.text,
                        border: `1px solid ${statusCfg.border}`,
                      }}
                    >
                      {statusCfg.label}
                    </span>
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: '4px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '13px', fontWeight: 600, color: '#1e293b' }}>
                      <User size={13} style={{ color: '#94a3b8' }} />
                      <span style={{ maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {t.sender?.displayName || `User #${t.maTaiKhoan}`}
                      </span>
                      {t.sender?.role === 'CUA_HANG' && (
                        <span style={{ fontSize: '10px', backgroundColor: '#fef3c7', color: '#92400e', padding: '1px 5px', borderRadius: '4px' }}>Chủ quán</span>
                      )}
                    </div>

                    {hasUnread && (
                      <span
                        style={{
                          width: '18px',
                          height: '18px',
                          backgroundColor: '#fc6011',
                          color: '#ffffff',
                          fontSize: '10px',
                          fontWeight: 800,
                          borderRadius: '50%',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        {t.soTinChuaDocAdmin}
                      </span>
                    )}
                  </div>

                  <p
                    style={{
                      fontSize: '12px',
                      color: '#64748b',
                      marginTop: '4px',
                      marginBottom: '4px',
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                    }}
                  >
                    {t.tinNhanCuoi || t.moTa}
                  </p>

                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: '11px', color: '#94a3b8' }}>
                    <span>
                      {t.thoiGianTinCuoi
                        ? new Date(t.thoiGianTinCuoi).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
                        : ''}
                    </span>
                    {t.maDonHang && (
                      <span style={{ fontSize: '10px', color: '#2563eb', backgroundColor: '#eff6ff', padding: '1px 6px', borderRadius: '4px', fontWeight: 600 }}>
                        Đơn #{t.maDonHang}
                      </span>
                    )}
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* RIGHT PANEL: Live Chat Conversation */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', backgroundColor: '#ffffff' }}>
        {selectedTicket ? (
          <>
            {/* Chat Header */}
            <div
              style={{
                padding: '16px 20px',
                borderBottom: '1px solid #e2e8f0',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                backgroundColor: '#ffffff',
              }}
            >
              <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                <div
                  style={{
                    width: '40px',
                    height: '40px',
                    borderRadius: '50%',
                    backgroundColor: 'rgba(252, 96, 17, 0.1)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: '#fc6011',
                    fontWeight: 800,
                    fontSize: '15px',
                  }}
                >
                  {selectedTicket.sender?.displayName?.[0]?.toUpperCase() || 'U'}
                </div>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{ fontSize: '14.5px', fontWeight: 700, color: '#0f172a' }}>
                      {selectedTicket.sender?.displayName}
                    </span>
                    {selectedTicket.sender?.phone && (
                      <span style={{ fontSize: '12px', color: '#64748b', display: 'flex', alignItems: 'center', gap: '3px' }}>
                        <Phone size={12} /> {selectedTicket.sender.phone}
                      </span>
                    )}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '12px', color: '#64748b', marginTop: '2px' }}>
                    <span>Phiếu #{selectedTicket.maPhieu}</span>
                    <span>•</span>
                    <span style={{ color: '#fc6011', fontWeight: 600 }}>
                      {ISSUE_TYPE_MAP[selectedTicket.loaiSuCo] || selectedTicket.loaiSuCo}
                    </span>
                    {selectedTicket.maDonHang && (
                      <>
                        <span>•</span>
                        <span style={{ color: '#2563eb', fontWeight: 600 }}>Đơn hàng #{selectedTicket.maDonHang}</span>
                      </>
                    )}
                  </div>
                </div>
              </div>

              {/* Status Switcher */}
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                <span style={{ fontSize: '12.5px', color: '#64748b', fontWeight: 600 }}>Trạng thái:</span>
                <select
                  value={selectedTicket.trangThai}
                  onChange={(e) => handleUpdateStatus(e.target.value as any)}
                  style={{
                    padding: '6px 12px',
                    borderRadius: '8px',
                    border: `1px solid ${STATUS_STYLE[selectedTicket.trangThai]?.border || '#cbd5e1'}`,
                    backgroundColor: STATUS_STYLE[selectedTicket.trangThai]?.bg || '#ffffff',
                    color: STATUS_STYLE[selectedTicket.trangThai]?.text || '#0f172a',
                    fontWeight: 700,
                    fontSize: '12.5px',
                    cursor: 'pointer',
                    outline: 'none',
                  }}
                >
                  <option value="MOI">Mới</option>
                  <option value="DANG_XU_LY">Đang xử lý</option>
                  <option value="DA_GIAI_QUYET">Đã giải quyết</option>
                  <option value="DA_DONG">Đã đóng</option>
                </select>
              </div>
            </div>

            {/* Chat Messages Stream */}
            <div style={{ flex: 1, padding: '20px', overflowY: 'auto', backgroundColor: '#f8fafc', display: 'flex', flexDirection: 'column', gap: '14px' }}>
              {loadingMessages ? (
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '60px 0', color: '#94a3b8', fontSize: '13px' }}>
                  <RefreshCw size={20} className="animate-spin" style={{ color: '#fc6011', marginRight: '8px' }} />
                  <span>Đang tải tin nhắn...</span>
                </div>
              ) : messages.length === 0 ? (
                <div style={{ textAlign: 'center', padding: '60px 0', color: '#94a3b8', fontSize: '13px' }}>
                  Chưa có tin nhắn trong phiếu này.
                </div>
              ) : (
                messages.map((m) => {
                  const isAdmin = m.vaiTroGui === 'ADMIN';

                  return (
                    <div
                      key={m.maTinNhan}
                      style={{
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: isAdmin ? 'flex-end' : 'flex-start',
                      }}
                    >
                      <div style={{ fontSize: '11px', color: '#94a3b8', marginBottom: '3px', padding: '0 4px' }}>
                        <span>{isAdmin ? 'Quản Trị Viên (Admin)' : selectedTicket.sender?.displayName}</span>
                        <span> • </span>
                        <span>{new Date(m.ngayTao).toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}</span>
                      </div>

                      <div
                        style={{
                          maxWidth: '70%',
                          borderRadius: isAdmin ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                          padding: '11px 16px',
                          fontSize: '13.5px',
                          backgroundColor: isAdmin ? '#fc6011' : '#ffffff',
                          color: isAdmin ? '#ffffff' : '#0f172a',
                          border: isAdmin ? 'none' : '1px solid #e2e8f0',
                          boxShadow: '0 1px 3px rgba(0,0,0,0.05)',
                          wordBreak: 'break-word',
                        }}
                      >
                        <p style={{ margin: 0, whiteSpace: 'pre-wrap', lineHeight: 1.45 }}>{m.noiDung}</p>

                        {m.danhSachAnh && m.danhSachAnh.length > 0 && (
                          <div style={{ marginTop: '8px', display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
                            {m.danhSachAnh.map((imgUrl, idx) => (
                              <img
                                key={idx}
                                src={getImageUrl(imgUrl)}
                                alt="attachment"
                                onClick={() => setPreviewImage(getImageUrl(imgUrl))}
                                style={{
                                  width: '84px',
                                  height: '84px',
                                  objectFit: 'cover',
                                  borderRadius: '8px',
                                  cursor: 'pointer',
                                  border: '1px solid rgba(255,255,255,0.3)',
                                }}
                              />
                            ))}
                          </div>
                        )}
                      </div>

                      {isAdmin && (
                        <div style={{ display: 'flex', alignItems: 'center', gap: '3px', marginTop: '3px', fontSize: '10px', color: '#94a3b8', padding: '0 4px' }}>
                          {m.daXem ? (
                            <span style={{ color: '#2563eb', fontWeight: 600, display: 'flex', alignItems: 'center', gap: '2px' }}>
                              <CheckCheck size={12} /> Đã xem
                            </span>
                          ) : (
                            <span style={{ display: 'flex', alignItems: 'center', gap: '2px' }}>
                              <Check size={12} /> Đã gửi
                            </span>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Chat Input Bar */}
            <div style={{ padding: '14px 20px', borderTop: '1px solid #e2e8f0', backgroundColor: '#ffffff' }}>
              {pendingImages.length > 0 && (
                <div style={{ display: 'flex', gap: '8px', marginBottom: '10px' }}>
                  {pendingImages.map((img, idx) => (
                    <div key={idx} style={{ position: 'relative', width: '56px', height: '56px', borderRadius: '8px', overflow: 'hidden', border: '1px solid #cbd5e1' }}>
                      <img src={getImageUrl(img)} alt="preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                      <button
                        type="button"
                        onClick={() => setPendingImages((prev) => prev.filter((_, i) => i !== idx))}
                        style={{
                          position: 'absolute',
                          top: '2px',
                          right: '2px',
                          backgroundColor: 'rgba(0,0,0,0.6)',
                          color: '#ffffff',
                          border: 'none',
                          borderRadius: '50%',
                          width: '18px',
                          height: '18px',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          cursor: 'pointer',
                        }}
                      >
                        <X size={11} />
                      </button>
                    </div>
                  ))}
                </div>
              )}

              <form onSubmit={handleSendMessage} style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                <input
                  type="file"
                  ref={fileInputRef}
                  onChange={handleUploadImage}
                  accept="image/*"
                  style={{ display: 'none' }}
                />

                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploadingImage || pendingImages.length >= 3}
                  style={{
                    padding: '8px 10px',
                    color: '#64748b',
                    backgroundColor: '#f1f5f9',
                    border: '1px solid #e2e8f0',
                    borderRadius: '10px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                  title="Đính kèm ảnh"
                >
                  <ImageIcon size={18} />
                </button>

                <input
                  type="text"
                  value={inputText}
                  onChange={(e) => setInputText(e.target.value)}
                  placeholder="Nhập câu trả lời hỗ trợ..."
                  style={{
                    flex: 1,
                    padding: '10px 16px',
                    backgroundColor: '#f8fafc',
                    border: '1px solid #cbd5e1',
                    borderRadius: '10px',
                    fontSize: '13.5px',
                    outline: 'none',
                  }}
                />

                <button
                  type="submit"
                  disabled={sending || (!inputText.trim() && pendingImages.length === 0)}
                  style={{
                    padding: '10px 20px',
                    backgroundColor: '#fc6011',
                    color: '#ffffff',
                    border: 'none',
                    borderRadius: '10px',
                    fontWeight: 700,
                    fontSize: '13.5px',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '6px',
                    boxShadow: '0 3px 10px rgba(252,96,17,0.25)',
                    opacity: sending || (!inputText.trim() && pendingImages.length === 0) ? 0.5 : 1,
                  }}
                >
                  <Send size={15} />
                  <span>Gửi</span>
                </button>
              </form>
            </div>
          </>
        ) : (
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '40px', textAlign: 'center', color: '#94a3b8' }}>
            <div
              style={{
                width: '60px',
                height: '60px',
                borderRadius: '18px',
                backgroundColor: 'rgba(252, 96, 17, 0.1)',
                color: '#fc6011',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                marginBottom: '14px',
              }}
            >
              <Inbox size={28} />
            </div>
            <h4 style={{ fontSize: '16px', fontWeight: 700, color: '#334155', margin: 0 }}>Chọn một phiếu hỗ trợ</h4>
            <p style={{ fontSize: '13px', color: '#94a3b8', marginTop: '6px', maxWidth: '340px', lineHeight: 1.45 }}>
              Chọn bất kỳ phiếu hỗ trợ nào từ danh sách bên trái để xem nội dung sự cố và phản hồi trực tuyến với người dùng.
            </p>
          </div>
        )}
      </div>

      {/* Image Preview Modal */}
      {previewImage && (
        <Modal isOpen={!!previewImage} onClose={() => setPreviewImage(null)} title="Xem Ảnh Đính Kèm" maxWidth="800px">
          <div style={{ display: 'flex', justifyContent: 'center', padding: '8px' }}>
            <img src={previewImage} alt="fullscreen preview" style={{ maxHeight: '80vh', maxWidth: '100%', borderRadius: '12px', objectFit: 'contain' }} />
          </div>
        </Modal>
      )}
    </div>
  );
};
