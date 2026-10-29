import { Router } from 'express';
import { RefundController } from '../controllers/refund_controller';
import { authMiddleware } from '../middlewares/auth_middleware';

const router = Router();
const refundController = new RefundController();

router.use(authMiddleware as any);

router.get('/', refundController.getRefunds);
router.get('/:id', refundController.getRefundById);
router.patch('/:id/status', refundController.updateRefundStatus);
router.patch('/:id/bank-info', refundController.updateBankInfo);

export default router;
