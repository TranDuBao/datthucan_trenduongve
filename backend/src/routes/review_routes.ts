import { Router } from 'express';
import { ReviewController } from '../controllers/review_controller';
import { authMiddleware } from '../middlewares/auth_middleware';
import { requireRole } from '../middlewares/role_middleware';

const router = Router();
const controller = new ReviewController();

// Customer endpoints
router.post('/orders/:id/review', authMiddleware as any, controller.createReview as any);
router.get('/orders/:id/review', authMiddleware as any, controller.getReviewByOrder as any);
router.patch('/reviews/:id', authMiddleware as any, controller.updateReview as any);
router.get('/reviews/my-reviews', authMiddleware as any, controller.getMyReviews as any);

// Store reply endpoint (requires CUAN_HANG or ADMIN)
router.post('/reviews/:id/reply', authMiddleware as any, requireRole(['CUAN_HANG', 'ADMIN']) as any, controller.replyReview as any);

// Admin moderation endpoint (strictly requires ADMIN)
router.patch('/reviews/:id/visibility', authMiddleware as any, requireRole(['ADMIN']) as any, controller.updateVisibility as any);

// Public restaurant reviews endpoint
router.get('/restaurants/:id/reviews', controller.getRestaurantReviews as any);
router.get('/foods/:id/reviews', controller.getDishReviews as any);

export default router;
