import { Router } from 'express';
import { CustomerReservationController } from '../controllers/customer_reservation_controller';
import { authMiddleware } from '../middlewares/auth_middleware';

const router = Router();
const controller = new CustomerReservationController();

router.use(authMiddleware as any);

router.post('/', controller.createReservation as any);
router.get('/my-reservations', controller.getMyReservations as any);
router.get('/:id', controller.getReservationById as any);
router.patch('/:id/cancel', controller.cancelReservation as any);

export default router;
