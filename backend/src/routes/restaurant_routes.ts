import { Router } from 'express';
import { RestaurantController } from '../controllers/restaurant_controller';

const router = Router();
const restaurantController = new RestaurantController();

router.get('/', restaurantController.getAll);
router.post('/along-route', restaurantController.getAlongRoute);
router.get('/foods-overview', restaurantController.getFoodsOverview);
router.get('/:id/menu', restaurantController.getMenu);

export default router;
