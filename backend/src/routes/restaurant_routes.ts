import { CustomerReservationController } from '../controllers/customer_reservation_controller';
import { StoreCategoryController } from '../controllers/store_category_controller';
import { Router } from 'express';
import { RestaurantController } from '../controllers/restaurant_controller';

const router = Router();
const restaurantController = new RestaurantController();
const storeCatController = new StoreCategoryController();
const customerReservationController = new CustomerReservationController();


router.get('/store-categories', storeCatController.getActive as any);
router.get('/', restaurantController.getAll);
router.post('/along-route', restaurantController.getAlongRoute);
router.get('/foods-overview', restaurantController.getFoodsOverview);
router.get('/:id/menu', restaurantController.getMenu);
router.get('/:id/reservations/availability', customerReservationController.checkAvailability as any);

export default router;
