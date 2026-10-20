import { Router } from 'express';
import { CustomerVoucherController } from '../controllers/customer_voucher_controller';
import { authMiddleware } from '../middlewares/auth_middleware';

const router = Router();
const controller = new CustomerVoucherController();

router.get('/', controller.getActiveVouchers);
router.get('/my-vouchers', authMiddleware as any, controller.getMyVouchers as any);
router.post('/apply', controller.validateVoucher);
router.post('/collect', authMiddleware as any, controller.collectVoucher as any);

export default router;
