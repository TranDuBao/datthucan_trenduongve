import { Router } from 'express';
import { RestaurantMgmtController } from '../controllers/restaurant_mgmt_controller';
import { VoucherController } from '../controllers/voucher_controller';
import { ReservationController } from '../controllers/reservation_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { requireRole, requireStoreOwner } from '../middlewares/role_middleware';

const router = Router();
const controller = new RestaurantMgmtController();
const voucherController = new VoucherController();
const reservationController = new ReservationController();

// All Restaurant Management routes require Auth & CUAN_HANG Role (ADMIN is not allowed)
router.use(authMiddleware as any);
router.use(requireRole(['CUAN_HANG']) as any);

// Scan CCCD does NOT require existing store ownership record (allows scanning during initial store setup)
router.post('/scan-cccd', controller.scanCCCD as any);

// Store Ownership validation for management actions
router.use(requireStoreOwner as any);

router.get('/dashboard', controller.getDashboardStats as any);
router.get('/revenue', controller.getRevenueAnalytics as any);
router.get('/orders', controller.getOrders as any);
router.put('/orders/:id/status', controller.updateOrderStatus as any);

router.get('/categories', controller.getCategories as any);
router.post('/categories', controller.createCategory as any);
router.get('/menu', controller.getMenu as any);
router.get('/menu/:id/reviews', controller.getFoodReviews as any);
router.post('/menu', controller.createFoodItem as any);
router.put('/menu/:id', controller.updateFoodItem as any);
router.delete('/menu/:id', controller.deleteFoodItem as any);

router.get('/profile', controller.getStoreProfile as any);
router.put('/profile', controller.updateStoreProfile as any);

// Store Voucher Management Endpoints
router.get('/vouchers', voucherController.getStoreVouchers as any);
router.get('/vouchers/:id', voucherController.getVoucherById as any);
router.post('/vouchers', voucherController.createVoucher as any);
router.put('/vouchers/:id', voucherController.updateVoucher as any);
router.patch('/vouchers/:id/status', voucherController.toggleVoucherStatus as any);
router.delete('/vouchers/:id', voucherController.deleteVoucher as any);

// Store Reservation Management Endpoints
router.get('/reservations/stats', reservationController.getDashboardStats as any);
router.get('/reservations', reservationController.getReservations as any);
router.post('/reservations', reservationController.createReservation as any);
router.get('/reservations/:id', reservationController.getReservationById as any);
router.put('/reservations/:id', reservationController.updateReservation as any);

router.post('/reservations/:id/confirm', reservationController.confirmReservation as any);
router.post('/reservations/:id/reject', reservationController.rejectReservation as any);
router.post('/reservations/:id/check-in', reservationController.checkInReservation as any);
router.post('/reservations/:id/start', reservationController.startReservation as any);
router.post('/reservations/:id/complete', reservationController.completeReservation as any);
router.post('/reservations/:id/cancel', reservationController.cancelReservation as any);
router.post('/reservations/:id/no-show', reservationController.noShowReservation as any);
router.patch('/reservations/:id/action', reservationController.handleAction as any);
router.post('/reservations/:id/action', reservationController.handleAction as any);


// Store Table Management Endpoints
router.get('/tables', reservationController.getTables as any);
router.post('/tables', reservationController.createTable as any);
router.put('/tables/:id', reservationController.updateTable as any);
router.patch('/tables/:id/status', reservationController.toggleTableStatus as any);

export default router;

