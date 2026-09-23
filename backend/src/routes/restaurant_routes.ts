import { Router } from 'express';
import { RestaurantController } from '../controllers/restaurant_controller';

const router = Router();
const restaurantController = new RestaurantController();

router.get('/', restaurantController.getAll);
router.get('/:id/menu', restaurantController.getMenu);

export default router;
