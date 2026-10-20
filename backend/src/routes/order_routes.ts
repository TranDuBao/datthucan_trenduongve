import { Router } from 'express';
import { OrderController } from '../controllers/order_controller';
import { authMiddleware } from '../middlewares/auth_middleware';

const router = Router();
const orderController = new OrderController();

router.use(authMiddleware as any);

router.post('/', orderController.createOrder);
router.get('/my-orders', orderController.getMyOrders);
router.get('/:id', orderController.getOrderById);
router.patch('/:id/status', orderController.updateStatus);

export default router;
