import { In } from 'typeorm';
import { AppDataSource } from '../config/database';
import { SupportTicketModel, TicketStatus } from '../models/support_ticket_model';
import { SupportTicketMessageModel, MessageSenderRole } from '../models/support_ticket_message_model';
import { TaiKhoanModel } from '../models/tai_khoan_model';
import { KhachHangModel } from '../models/khach_hang_model';
import { CuaHangModel } from '../models/cua_hang_model';
import { DonHangModel } from '../models/don_hang_model';
import { RealtimeService } from './realtime_service';
import { NotificationService } from './notification_service';

export interface CreateTicketDTO {
  loaiSuCo: string;
  moTa: string;
  tieuDe?: string;
  maDonHang?: number;
  danhSachAnh?: string[];
}

export interface SendMessageDTO {
  noiDung: string;
  danhSachAnh?: string[];
}

export class SupportTicketService {
  private ticketRepo = AppDataSource.getRepository(SupportTicketModel);
  private messageRepo = AppDataSource.getRepository(SupportTicketMessageModel);
  private accountRepo = AppDataSource.getRepository(TaiKhoanModel);
  private customerRepo = AppDataSource.getRepository(KhachHangModel);
  private storeRepo = AppDataSource.getRepository(CuaHangModel);
  private orderRepo = AppDataSource.getRepository(DonHangModel);

  /**
   * Tạo phiếu hỗ trợ mới từ người dùng (kèm tin nhắn đầu tiên)
   */
  async createTicket(userId: number, dto: CreateTicketDTO): Promise<SupportTicketModel> {
    if (!dto.loaiSuCo || !dto.moTa || dto.moTa.trim().length === 0) {
      throw new Error('Loại sự cố và nội dung mô tả không được để trống.');
    }

    // Verify order if provided
    if (dto.maDonHang) {
      const order = await this.orderRepo.findOne({ where: { maDonHang: dto.maDonHang } });
      if (!order) {
        dto.maDonHang = undefined;
      }
    }

    // Auto title if not provided
    const tieuDe = dto.tieuDe?.trim() || `Hỗ trợ: ${dto.loaiSuCo}`;

    const newTicket = this.ticketRepo.create({
      maTaiKhoan: userId,
      tieuDe,
      loaiSuCo: dto.loaiSuCo.trim(),
      moTa: dto.moTa.trim(),
      maDonHang: dto.maDonHang,
      danhSachAnh: dto.danhSachAnh || [],
      trangThai: 'MOI',
      soTinChuaDocAdmin: 1,
      soTinChuaDocUser: 0,
      tinNhanCuoi: dto.moTa.trim(),
      thoiGianTinCuoi: new Date(),
    });

    const savedTicket = await this.ticketRepo.save(newTicket);

    // Initial message
    const initialMsg = this.messageRepo.create({
      maPhieu: savedTicket.maPhieu,
      maTaiKhoanGui: userId,
      vaiTroGui: 'USER',
      noiDung: dto.moTa.trim(),
      danhSachAnh: dto.danhSachAnh || [],
      daXem: false,
    });
    await this.messageRepo.save(initialMsg);

    // Fetch sender info for richer realtime payload
    const sender = await this.getSenderInfo(userId);

    const payload = {
      maPhieu: savedTicket.maPhieu,
      tieuDe: savedTicket.tieuDe,
      loaiSuCo: savedTicket.loaiSuCo,
      moTa: savedTicket.moTa,
      maDonHang: savedTicket.maDonHang,
      trangThai: savedTicket.trangThai,
      danhSachAnh: savedTicket.danhSachAnh,
      ngayTao: savedTicket.ngayTao,
      sender,
    };

    // Realtime events
    try {
      const io = RealtimeService.getInstance().getIO();
      if (io) {
        io.to('support:admin').to('admin').emit('ticket:created', payload);
        io.to(`user:${userId}`).emit('ticket:created', payload);
      }
    } catch (e) {
      console.warn('[SupportTicketService] Realtime emit error (ticket:created):', e);
    }

    // System Notification to Admin
    try {
      await NotificationService.getInstance().sendNotification({
        recipientId: 1,
        recipientRole: 'admin',
        type: 'SUPPORT_TICKET_NEW',
        title: 'Yêu cầu hỗ trợ mới',
        body: `${sender.displayName} vừa gửi phiếu hỗ trợ #${savedTicket.maPhieu}: ${savedTicket.loaiSuCo}`,
        data: { maPhieu: savedTicket.maPhieu },
      });
    } catch (e) {
      console.warn('[SupportTicketService] Notification error:', e);
    }

    return savedTicket;
  }

  /**
   * Người dùng lấy danh sách phiếu của chính mình
   */
  async getMyTickets(userId: number, page: number = 1, limit: number = 20, status?: string) {
    const qb = this.ticketRepo
      .createQueryBuilder('ticket')
      .where('ticket.maTaiKhoan = :userId', { userId })
      .orderBy('ticket.thoiGianTinCuoi', 'DESC');

    if (status && status !== 'ALL') {
      qb.andWhere('ticket.trangThai = :status', { status });
    }

    const skip = (page - 1) * limit;
    qb.skip(skip).take(limit);

    const [items, total] = await qb.getManyAndCount();

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Chi tiết phiếu hỗ trợ kèm thông tin người dùng và đơn hàng
   */
  async getTicketDetail(ticketId: number, requesterId: number, isAdmin: boolean = false) {
    const ticket = await this.ticketRepo.findOne({
      where: { maPhieu: ticketId },
      relations: ['donHang'],
    });

    if (!ticket) {
      throw new Error('Phiếu hỗ trợ không tồn tại.');
    }

    if (!isAdmin && ticket.maTaiKhoan !== requesterId) {
      throw new Error('Bạn không có quyền truy cập phiếu hỗ trợ này.');
    }

    const sender = await this.getSenderInfo(ticket.maTaiKhoan);

    return {
      ...ticket,
      sender,
    };
  }

  /**
   * Lấy lịch sử tin nhắn trong phiếu (phân trang cũ dần / cursor)
   */
  async getTicketMessages(
    ticketId: number,
    requesterId: number,
    isAdmin: boolean = false,
    page: number = 1,
    limit: number = 30,
    beforeId?: number
  ) {
    const ticket = await this.ticketRepo.findOne({ where: { maPhieu: ticketId } });
    if (!ticket) {
      throw new Error('Phiếu hỗ trợ không tồn tại.');
    }

    if (!isAdmin && ticket.maTaiKhoan !== requesterId) {
      throw new Error('Bạn không có quyền xem tin nhắn của phiếu này.');
    }

    const qb = this.messageRepo
      .createQueryBuilder('msg')
      .where('msg.maPhieu = :ticketId', { ticketId });

    if (beforeId) {
      qb.andWhere('msg.maTinNhan < :beforeId', { beforeId });
    }

    qb.orderBy('msg.maTinNhan', 'DESC').take(limit);

    const messages = await qb.getMany();

    // Reverse to chronological order (oldest to newest) for UI
    return messages.reverse();
  }

  /**
   * Gửi tin nhắn mới vào cuộc hội thoại
   */
  async sendMessage(
    ticketId: number,
    senderId: number,
    senderRole: 'ADMIN' | 'USER',
    dto: SendMessageDTO
  ): Promise<SupportTicketMessageModel> {
    if ((!dto.noiDung || dto.noiDung.trim().length === 0) && (!dto.danhSachAnh || dto.danhSachAnh.length === 0)) {
      throw new Error('Nội dung tin nhắn hoặc hình ảnh không được để trống.');
    }

    const ticket = await this.ticketRepo.findOne({ where: { maPhieu: ticketId } });
    if (!ticket) {
      throw new Error('Phiếu hỗ trợ không tồn tại.');
    }

    if (senderRole !== 'ADMIN' && ticket.maTaiKhoan !== senderId) {
      throw new Error('Bạn không có quyền gửi tin nhắn trong phiếu này.');
    }

    const newMsg = this.messageRepo.create({
      maPhieu: ticketId,
      maTaiKhoanGui: senderId,
      vaiTroGui: senderRole === 'ADMIN' ? 'ADMIN' : 'USER',
      noiDung: dto.noiDung?.trim() || '(Đã gửi ảnh)',
      danhSachAnh: dto.danhSachAnh || [],
      daXem: false,
    });

    const savedMsg = await this.messageRepo.save(newMsg);

    // Update ticket metadata
    ticket.tinNhanCuoi = newMsg.noiDung;
    ticket.thoiGianTinCuoi = savedMsg.ngayTao;
    if (senderRole === 'ADMIN') {
      ticket.soTinChuaDocUser = (ticket.soTinChuaDocUser || 0) + 1;
      // If ticket was MOI, auto switch to DANG_XU_LY when Admin replies
      if (ticket.trangThai === 'MOI') {
        ticket.trangThai = 'DANG_XU_LY';
      }
    } else {
      ticket.soTinChuaDocAdmin = (ticket.soTinChuaDocAdmin || 0) + 1;
      // If ticket was DA_GIAI_QUYET, user reply reopens to DANG_XU_LY
      if (ticket.trangThai === 'DA_GIAI_QUYET') {
        ticket.trangThai = 'DANG_XU_LY';
      }
    }

    await this.ticketRepo.save(ticket);

    // Realtime broadcast to room: ticket:<id>, user:<id>, support:admin
    try {
      const io = RealtimeService.getInstance().getIO();
      if (io) {
        const msgPayload = {
          maTinNhan: savedMsg.maTinNhan,
          maPhieu: savedMsg.maPhieu,
          maTaiKhoanGui: savedMsg.maTaiKhoanGui,
          vaiTroGui: savedMsg.vaiTroGui,
          noiDung: savedMsg.noiDung,
          danhSachAnh: savedMsg.danhSachAnh,
          daXem: savedMsg.daXem,
          ngayTao: savedMsg.ngayTao,
          ticketStatus: ticket.trangThai,
        };

        io.to(`ticket:${ticketId}`).emit('ticket:message_new', msgPayload);
        io.to(`user:${ticket.maTaiKhoan}`).emit('ticket:message_new', msgPayload);
        io.to('support:admin').to('admin').emit('ticket:message_new', msgPayload);
      }
    } catch (e) {
      console.warn('[SupportTicketService] Realtime emit error (ticket:message_new):', e);
    }

    // In-app Notification
    try {
      if (senderRole === 'ADMIN') {
        await NotificationService.getInstance().sendNotification({
          recipientId: ticket.maTaiKhoan,
          recipientRole: 'user',
          type: 'SUPPORT_TICKET_REPLY',
          title: 'Hỗ trợ Food Route',
          body: `Admin đã trả lời phiếu hỗ trợ #${ticketId}: ${savedMsg.noiDung.substring(0, 80)}`,
          data: { maPhieu: ticketId },
        });
      }
    } catch (e) {
      console.warn('[SupportTicketService] In-app notification error:', e);
    }

    return savedMsg;
  }

  /**
   * Đánh dấu các tin nhắn trong phiếu là đã xem
   */
  async markMessagesAsRead(ticketId: number, readerId: number, readerRole: 'ADMIN' | 'USER') {
    const ticket = await this.ticketRepo.findOne({ where: { maPhieu: ticketId } });
    if (!ticket) return;

    if (readerRole !== 'ADMIN' && ticket.maTaiKhoan !== readerId) {
      return;
    }

    const now = new Date();

    if (readerRole === 'ADMIN') {
      await this.messageRepo
        .createQueryBuilder()
        .update(SupportTicketMessageModel)
        .set({ daXem: true, thoiGianXem: now })
        .where('maPhieu = :ticketId AND vaiTroGui = :role AND daXem = false', { ticketId, role: 'USER' })
        .execute();

      ticket.soTinChuaDocAdmin = 0;
      await this.ticketRepo.save(ticket);
    } else {
      await this.messageRepo
        .createQueryBuilder()
        .update(SupportTicketMessageModel)
        .set({ daXem: true, thoiGianXem: now })
        .where('maPhieu = :ticketId AND vaiTroGui = :role AND daXem = false', { ticketId, role: 'ADMIN' })
        .execute();

      ticket.soTinChuaDocUser = 0;
      await this.ticketRepo.save(ticket);
    }

    try {
      const io = RealtimeService.getInstance().getIO();
      if (io) {
        io.to(`ticket:${ticketId}`).emit('ticket:message_read', {
          maPhieu: ticketId,
          readerRole,
          thoiGianXem: now,
        });
      }
    } catch (e) {
      console.warn('[SupportTicketService] Realtime emit error (ticket:message_read):', e);
    }
  }

  /**
   * Admin: Danh sách tất cả phiếu có lọc và tìm kiếm
   */
  async adminGetTickets(page: number = 1, limit: number = 20, status?: string, loaiSuCo?: string, search?: string) {
    const qb = this.ticketRepo
      .createQueryBuilder('ticket')
      .leftJoinAndSelect('ticket.taiKhoan', 'taiKhoan')
      .leftJoinAndSelect('ticket.donHang', 'donHang')
      .orderBy('ticket.thoiGianTinCuoi', 'DESC');

    if (status && status !== 'ALL') {
      qb.andWhere('ticket.trangThai = :status', { status });
    }

    if (loaiSuCo && loaiSuCo !== 'ALL') {
      qb.andWhere('ticket.loaiSuCo = :loaiSuCo', { loaiSuCo });
    }

    if (search && search.trim().length > 0) {
      const term = `%${search.trim().toLowerCase()}%`;
      qb.andWhere(
        '(LOWER(ticket.tieuDe) LIKE :term OR LOWER(ticket.moTa) LIKE :term OR CAST(ticket.maPhieu AS TEXT) LIKE :term OR LOWER(taiKhoan.tenDangNhap) LIKE :term)',
        { term }
      );
    }

    const skip = (page - 1) * limit;
    qb.skip(skip).take(limit);

    const [items, total] = await qb.getManyAndCount();

    // Enrich sender profile
    const enrichedItems = await Promise.all(
      items.map(async (t) => {
        const sender = await this.getSenderInfo(t.maTaiKhoan);
        return {
          ...t,
          sender,
        };
      })
    );

    return {
      items: enrichedItems,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /**
   * Admin: Thay đổi trạng thái phiếu (MOI / DANG_XU_LY / DA_GIAI_QUYET / DA_DONG)
   */
  async adminUpdateTicketStatus(ticketId: number, newStatus: TicketStatus): Promise<SupportTicketModel> {
    const ticket = await this.ticketRepo.findOne({ where: { maPhieu: ticketId } });
    if (!ticket) {
      throw new Error('Phiếu hỗ trợ không tồn tại.');
    }

    ticket.trangThai = newStatus;
    ticket.ngayCapNhat = new Date();
    const updated = await this.ticketRepo.save(ticket);

    // Realtime notification
    try {
      const io = RealtimeService.getInstance().getIO();
      if (io) {
        const payload = {
          maPhieu: ticket.maPhieu,
          trangThai: ticket.trangThai,
          ngayCapNhat: ticket.ngayCapNhat,
        };
        io.to(`ticket:${ticketId}`).emit('ticket:status_changed', payload);
        io.to(`user:${ticket.maTaiKhoan}`).emit('ticket:status_changed', payload);
        io.to('support:admin').to('admin').emit('ticket:status_changed', payload);
      }
    } catch (e) {
      console.warn('[SupportTicketService] Realtime emit error (ticket:status_changed):', e);
    }

    // In-app Notification to User
    try {
      const statusText =
        newStatus === 'DA_GIAI_QUYET'
          ? 'đã được giải quyết'
          : newStatus === 'DA_DONG'
          ? 'đã được đóng'
          : 'đang được xử lý';

      await NotificationService.getInstance().sendNotification({
        recipientId: ticket.maTaiKhoan,
        recipientRole: 'user',
        type: 'SUPPORT_TICKET_STATUS',
        title: 'Trạng thái phiếu hỗ trợ',
        body: `Phiếu hỗ trợ #${ticket.maPhieu} ${statusText}.`,
        data: { maPhieu: ticket.maPhieu, trangThai: newStatus },
      });
    } catch (e) {
      console.warn('[SupportTicketService] Notification error:', e);
    }

    return updated;
  }

  /**
   * Helper: Trích xuất thông tin người gửi (Họ tên, SĐT, loại tài khoản)
   */
  private async getSenderInfo(maTaiKhoan: number) {
    const account = await this.accountRepo.findOne({ where: { maTaiKhoan } });
    const kh = await this.customerRepo.findOne({ where: { maTaiKhoan } });
    const store = await this.storeRepo.findOne({ where: { maTaiKhoan } });

    let displayName = kh?.hoTen || account?.tenDangNhap || `Khách hàng #${maTaiKhoan}`;
    let phone = kh?.sdt || '';
    let role = account?.loaiTaiKhoan || 'USER';
    let storeName = store?.tenQuan;

    return {
      maTaiKhoan,
      displayName,
      phone,
      role,
      storeName,
    };
  }
}
