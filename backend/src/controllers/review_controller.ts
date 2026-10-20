import { Request, Response } from 'express';
import { ReviewService } from '../services/review_service';

export class ReviewController {
  private reviewService = new ReviewService();

  createReview = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn cần đăng nhập để thực hiện thao tác này' });
      }

      const orderId = Number(req.params.id || req.body.orderId);
      if (!orderId || isNaN(orderId)) {
        return res.status(400).json({ status: 'error', message: 'Mã đơn hàng không hợp lệ' });
      }

      const { rating, comment, image, dishRatings } = req.body;
      if (!rating || Number(rating) < 1 || Number(rating) > 5) {
        return res.status(400).json({ status: 'error', message: 'Số sao đánh giá phải từ 1 đến 5' });
      }

      const review = await this.reviewService.createReview({
        userId: Number(user.sub),
        orderId,
        rating: Number(rating),
        comment,
        image,
        dishRatings,
      });

      return res.status(201).json({
        status: 'success',
        message: 'Gửi đánh giá thành công',
        data: review,
      });
    } catch (error: any) {
      if (error.code === '23505' || error.message?.includes('đã được đánh giá')) {
        return res.status(409).json({
          status: 'error',
          message: error.message || 'Đơn hàng này đã được đánh giá trước đó',
        });
      }
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Lỗi khi gửi đánh giá',
      });
    }
  };

  updateReview = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn cần đăng nhập để thực hiện thao tác này' });
      }

      const reviewId = Number(req.params.id);
      if (!reviewId || isNaN(reviewId)) {
        return res.status(400).json({ status: 'error', message: 'Mã đánh giá không hợp lệ' });
      }

      const { rating, comment, image } = req.body;

      const updated = await this.reviewService.updateReview(reviewId, Number(user.sub), {
        rating: rating !== undefined ? Number(rating) : undefined,
        comment,
        image,
      });

      return res.status(200).json({
        status: 'success',
        message: 'Cập nhật đánh giá thành công',
        data: updated,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Lỗi khi cập nhật đánh giá',
      });
    }
  };

  getRestaurantReviews = async (req: Request, res: Response) => {
    try {
      const restaurantId = Number(req.params.id);
      if (!restaurantId || isNaN(restaurantId)) {
        return res.status(400).json({ status: 'error', message: 'Mã cửa hàng không hợp lệ' });
      }

      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;

      const data = await this.reviewService.getRestaurantReviews(restaurantId, page, limit);

      return res.status(200).json({
        status: 'success',
        data,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi lấy danh sách đánh giá',
      });
    }
  };

  getDishReviews = async (req: Request, res: Response) => {
    try {
      const dishId = Number(req.params.id);
      if (!dishId || isNaN(dishId)) {
        return res.status(400).json({ status: 'error', message: 'Mã món ăn không hợp lệ' });
      }

      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;

      const data = await this.reviewService.getDishReviews(dishId, page, limit);

      return res.status(200).json({
        status: 'success',
        data,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi lấy danh sách đánh giá món ăn',
      });
    }
  };

  replyReview = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn cần đăng nhập để thực hiện thao tác này' });
      }

      const reviewId = Number(req.params.id);
      if (!reviewId || isNaN(reviewId)) {
        return res.status(400).json({ status: 'error', message: 'Mã đánh giá không hợp lệ' });
      }

      const { reply } = req.body;
      if (!reply || !String(reply).trim()) {
        return res.status(400).json({ status: 'error', message: 'Nội dung phản hồi không được để trống' });
      }

      const updated = await this.reviewService.replyReview(reviewId, Number(user.sub), reply);

      return res.status(200).json({
        status: 'success',
        message: 'Phản hồi đánh giá thành công',
        data: updated,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Lỗi khi phản hồi đánh giá',
      });
    }
  };

  updateVisibility = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || String(user.role).toUpperCase() !== 'ADMIN') {
        return res.status(403).json({ status: 'error', message: 'Chỉ Admin mới có quyền kiểm duyệt đánh giá' });
      }

      const reviewId = Number(req.params.id);
      if (!reviewId || isNaN(reviewId)) {
        return res.status(400).json({ status: 'error', message: 'Mã đánh giá không hợp lệ' });
      }

      const { isHidden, reason } = req.body;

      const updated = await this.reviewService.updateVisibility(reviewId, Boolean(isHidden), reason);

      return res.status(200).json({
        status: 'success',
        message: isHidden ? 'Đã ẩn đánh giá' : 'Đã hiện lại đánh giá',
        data: updated,
      });
    } catch (error: any) {
      return res.status(400).json({
        status: 'error',
        message: error.message || 'Lỗi khi cập nhật trạng thái hiển thị đánh giá',
      });
    }
  };

  getMyReviews = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn cần đăng nhập để thực hiện thao tác này' });
      }

      const page = Number(req.query.page) || 1;
      const limit = Number(req.query.limit) || 10;

      const data = await this.reviewService.getMyReviews(Number(user.sub), page, limit);

      return res.status(200).json({
        status: 'success',
        data,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi lấy danh sách đánh giá của bạn',
      });
    }
  };

  getReviewByOrder = async (req: Request, res: Response) => {
    try {
      const user = (req as any).user;
      if (!user || !user.sub) {
        return res.status(401).json({ status: 'error', message: 'Bạn cần đăng nhập để thực hiện thao tác này' });
      }

      const orderId = Number(req.params.id);
      if (!orderId || isNaN(orderId)) {
        return res.status(400).json({ status: 'error', message: 'Mã đơn hàng không hợp lệ' });
      }

      const review = await this.reviewService.getReviewByOrder(orderId, Number(user.sub));

      return res.status(200).json({
        status: 'success',
        data: review,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: 'error',
        message: error.message || 'Lỗi khi lấy đánh giá của đơn hàng',
      });
    }
  };
}
