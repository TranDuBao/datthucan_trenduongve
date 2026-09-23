import { Router } from 'express';
import { OrderController } from '../controllers/order_controller';

const router = Router();
const orderController = new OrderController();

router.post('/', orderController.createOrder);
router.get('/my-orders', orderController.getMyOrders);
router.get('/:id', orderController.getOrderById);
router.patch('/:id/status', orderController.updateStatus);

export default router;
