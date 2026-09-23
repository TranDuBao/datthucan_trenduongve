import { Router } from 'express';
import { PaymentController } from '../controllers/payment_controller';

const router = Router();
const paymentController = new PaymentController();

router.post('/verify', paymentController.verifyPayment);

export default router;
