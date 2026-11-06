import { Router } from 'express';
import { SupportController } from '../controllers/support_controller';
import { SupportTicketController } from '../controllers/support_ticket_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { requireRole } from '../middlewares/role_middleware';

const router = Router();
const controller = new SupportController();

// ==================== PUBLIC / USER APP ENDPOINTS ====================
// Cấu hình liên hệ (hotline, email, giờ làm)
router.get('/support/config', controller.getConfig);

// FAQ công khai cho app (hỗ trợ search)
router.get('/support/faq', controller.getPublicFaq);

// Gửi góp ý phản hồi (người dùng đã đăng nhập hoặc khách)
router.post('/support/feedback', controller.submitFeedback);

// ==================== USER TICKETS & LIVE CHAT ====================
const userGuard = [authMiddleware as any];

// Tạo phiếu hỗ trợ sự cố
router.post('/support/tickets', ...userGuard, SupportTicketController.createTicket);

// Danh sách phiếu của tôi
router.get('/support/tickets/my', ...userGuard, SupportTicketController.getMyTickets);

// Chi tiết phiếu
router.get('/support/tickets/:id', ...userGuard, SupportTicketController.getTicketDetail);

// Lịch sử tin nhắn trong phiếu
router.get('/support/tickets/:id/messages', ...userGuard, SupportTicketController.getTicketMessages);

// Gửi tin nhắn mới trong phiếu
router.post('/support/tickets/:id/messages', ...userGuard, SupportTicketController.sendMessage);

// Đánh dấu đã xem
router.post('/support/tickets/:id/read', ...userGuard, SupportTicketController.markAsRead);

// ==================== ADMIN ENDPOINTS ====================
const adminGuard = [authMiddleware as any, requireRole(['ADMIN']) as any];

// Cấu hình liên hệ
router.get('/admin/support/config', ...adminGuard, controller.getConfig);
router.put('/admin/support/config', ...adminGuard, controller.updateConfig);

// Quản lý nhóm FAQ
router.get('/admin/support/faq', ...adminGuard, controller.getAdminFaq);
router.post('/admin/support/faq/groups', ...adminGuard, controller.createFaqGroup);
router.put('/admin/support/faq/groups/:id', ...adminGuard, controller.updateFaqGroup);
router.delete('/admin/support/faq/groups/:id', ...adminGuard, controller.deleteFaqGroup);

// Quản lý câu hỏi FAQ
router.post('/admin/support/faq/questions', ...adminGuard, controller.createFaqQuestion);
router.put('/admin/support/faq/questions/:id', ...adminGuard, controller.updateFaqQuestion);
router.delete('/admin/support/faq/questions/:id', ...adminGuard, controller.deleteFaqQuestion);

// Quản lý danh sách góp ý & phản hồi
router.get('/admin/support/feedbacks', ...adminGuard, controller.getAdminFeedbacks);
router.put('/admin/support/feedbacks/:id/status', ...adminGuard, controller.updateFeedbackStatus);

// Quản lý phiếu hỗ trợ & Live Chat Admin
router.get('/admin/support/tickets', ...adminGuard, SupportTicketController.adminGetTickets);
router.get('/admin/support/tickets/:id', ...adminGuard, SupportTicketController.getTicketDetail);
router.get('/admin/support/tickets/:id/messages', ...adminGuard, SupportTicketController.getTicketMessages);
router.post('/admin/support/tickets/:id/messages', ...adminGuard, SupportTicketController.sendMessage);
router.put('/admin/support/tickets/:id/status', ...adminGuard, SupportTicketController.adminUpdateStatus);
router.post('/admin/support/tickets/:id/read', ...adminGuard, SupportTicketController.markAsRead);

export default router;

