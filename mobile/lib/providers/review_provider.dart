import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<ReviewModel> _restaurantReviews = [];
  int _restaurantTotal = 0;
  int _restaurantTotalPages = 1;
  int _currentRestaurantPage = 1;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  List<ReviewModel> get restaurantReviews => _restaurantReviews;
  int get restaurantTotal => _restaurantTotal;
  int get restaurantTotalPages => _restaurantTotalPages;

  Future<void> fetchRestaurantReviews(int storeId, {bool refresh = false}) async {
    if (refresh) {
      _currentRestaurantPage = 1;
      _restaurantReviews = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ReviewService.fetchRestaurantReviews(
      storeId,
      page: _currentRestaurantPage,
      limit: 10,
    );

    _isLoading = false;
    if (result['success'] == true) {
      final List<ReviewModel> newReviews = result['reviews'];
      if (refresh) {
        _restaurantReviews = newReviews;
      } else {
        _restaurantReviews.addAll(newReviews);
      }
      _restaurantTotal = result['total'] ?? 0;
      _restaurantTotalPages = result['totalPages'] ?? 1;
    } else {
      _errorMessage = 'Không thể tải danh sách đánh giá';
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>> submitReview({
    required int orderId,
    required int rating,
    String? comment,
    String? image,
    List<Map<String, dynamic>>? dishRatings,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final res = await ReviewService.submitReview(
      orderId: orderId,
      rating: rating,
      comment: comment,
      image: image,
      dishRatings: dishRatings,
    );

    _isSubmitting = false;
    notifyListeners();
    return res;
  }

  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    int? rating,
    String? comment,
    String? image,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final res = await ReviewService.updateReview(
      reviewId: reviewId,
      rating: rating,
      comment: comment,
      image: image,
    );

    _isSubmitting = false;
    notifyListeners();
    return res;
  }

  Future<ReviewModel?> getReviewByOrder(int orderId) async {
    return await ReviewService.getReviewByOrder(orderId);
  }
}
