import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../widgets/skeleton/skeleton_box.dart';
import '../../widgets/skeleton/skeleton_circle.dart';

class RestaurantReviewsSheet extends StatefulWidget {
  final int restaurantId;
  final String restaurantName;
  final double averageRating;
  final int totalReviews;

  const RestaurantReviewsSheet({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  @override
  State<RestaurantReviewsSheet> createState() => _RestaurantReviewsSheetState();
}

class _RestaurantReviewsSheetState extends State<RestaurantReviewsSheet> {
  bool _isLoading = true;
  List<ReviewModel> _reviews = [];
  int _total = 0;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
    });

    final res = await ReviewService.fetchRestaurantReviews(
      widget.restaurantId,
      page: _page,
      limit: 10,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _reviews = res['reviews'] ?? [];
        _total = res['total'] ?? 0;
        _totalPages = res['totalPages'] ?? 1;
      });
    }
  }

  Widget _buildSkeletonLoader() {
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1B1E28)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TColor.borderOf(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonCircle(radius: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 120, height: 14),
                      SizedBox(height: 6),
                      SkeletonBox(width: 80, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const SkeletonBox(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const SkeletonBox(width: 200, height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12141C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Store name & average score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Đánh giá khách hàng",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.restaurantName,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE5A3)),
                ),
                child: Row(
                  children: [
                    if (widget.averageRating > 0 || widget.totalReviews > 0 || _total > 0) ...[
                      const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        widget.averageRating > 0 ? widget.averageRating.toStringAsFixed(1) : "0.0",
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFD97706),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        " (${widget.totalReviews > 0 ? widget.totalReviews : _total})",
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        "Chưa có đánh giá",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFD97706),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Body: Reviews List with Skeleton Loading
          Expanded(
            child: _isLoading
                ? _buildSkeletonLoader()
                : _reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rate_review_outlined,
                              size: 48,
                              color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Chưa có đánh giá nào cho quán này",
                              style: TextStyle(
                                color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B1E28) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: TColor.borderOf(context)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(0xFFFC6011).withOpacity(0.15),
                                          child: Text(
                                            review.customerName.isNotEmpty
                                                ? review.customerName.substring(0, 1).toUpperCase()
                                                : "K",
                                            style: const TextStyle(
                                              color: Color(0xFFFC6011),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              review.customerName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: isDark ? Colors.white : const Color(0xFF101828),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: List.generate(5, (s) {
                                                return Icon(
                                                  s < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                                  color: const Color(0xFFFFB800),
                                                  size: 14,
                                                );
                                              }),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (review.createdAt.isNotEmpty)
                                      Text(
                                        review.createdAt.length > 10 ? review.createdAt.substring(0, 10) : review.createdAt,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF707688) : const Color(0xFF98A2B3),
                                        ),
                                      ),
                                  ],
                                ),
                                if (review.comment != null && review.comment!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    review.comment!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFFD0D4E0) : const Color(0xFF344054),
                                    ),
                                  ),
                                ],
                                if (review.reply != null && review.reply!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF12141C) : const Color(0xFFF7F7F9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFFC6011).withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Phản hồi từ quán:",
                                          style: TextStyle(
                                            color: Color(0xFFFC6011),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          review.reply!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFFD0D4E0) : const Color(0xFF475467),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
