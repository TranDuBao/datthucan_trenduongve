import { Router } from 'express';
import { PaymentController } from '../controllers/payment_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { requireRole } from '../middlewares/role_middleware';

const router = Router();
const paymentController = new PaymentController();

// Read-only payment status check for FE
router.get('/status/:id', authMiddleware as any, paymentController.getPaymentStatus);
router.post('/verify', authMiddleware as any, paymentController.getPaymentStatus); // Backward compatible read-only alias

// Server-to-server Payment Webhook (PayOS / VietQR / MoMo)
router.post('/webhook', paymentController.handleWebhook);

// Store owner manual payment confirmation for COD
router.post(
  '/store-confirm',
  authMiddleware as any,
  requireRole(['CUAN_HANG', 'ADMIN']) as any,
  paymentController.confirmStorePayment
);

export default router;
