import 'package:flutter/material.dart';
import '../common/color_extension.dart';
import '../common_widget/smart_network_image.dart';
import '../models/review_model.dart';
import 'skeleton/skeleton_box.dart';
import 'skeleton/skeleton_circle.dart';

class DishReviewsSection extends StatelessWidget {
  final bool isLoading;
  final List<ReviewModel> reviewsList;
  final double avgRating;
  final int totalReviewsCount;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const DishReviewsSection({
    super.key,
    required this.isLoading,
    required this.reviewsList,
    required this.avgRating,
    required this.totalReviewsCount,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  int get _imageReviewsCount =>
      reviewsList.where((r) => r.image != null && r.image!.isNotEmpty).length;

  int get _fiveStarReviewsCount =>
      reviewsList.where((r) => r.rating == 5).length;

  List<ReviewModel> get _filteredReviews {
    switch (selectedFilter) {
      case "image":
        return reviewsList.where((r) => r.image != null && r.image!.isNotEmpty).toList();
      case "5star":
        return reviewsList.where((r) => r.rating == 5).toList();
      case "latest":
        final sorted = List<ReviewModel>.from(reviewsList);
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted;
      case "all":
      default:
        return reviewsList;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "KH";
    final parts = name.trim().split(" ");
    if (parts.length >= 2) {
      return "${parts.first[0]}${parts.last[0]}".toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatTimeAgo(dynamic rawDate) {
    DateTime? dt;
    if (rawDate is DateTime) {
      dt = rawDate;
    } else if (rawDate is String && rawDate.isNotEmpty) {
      dt = DateTime.tryParse(rawDate);
    }
    if (dt == null) return "Vừa xong";

    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) {
      return "${dt.day}/${dt.month}/${dt.year}";
    } else if (diff.inDays > 0) {
      return "${diff.inDays} ngày trước";
    } else if (diff.inHours > 0) {
      return "${diff.inHours} giờ trước";
    } else if (diff.inMinutes > 0) {
      return "${diff.inMinutes} phút trước";
    }
    return "Vừa xong";
  }

  Widget _buildSkeletonReviews() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SkeletonCircle(size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 100, height: 14, borderRadius: 4.0),
                        SizedBox(height: 6),
                        SkeletonBox(width: 80, height: 10, borderRadius: 4.0),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const SkeletonBox(width: double.infinity, height: 12, borderRadius: 4.0),
              const SizedBox(height: 6),
              const SkeletonBox(width: 200, height: 12, borderRadius: 4.0),
            ],
          ),
        );
      }),
    );
  }

  Widget _filterChip(BuildContext context, String filterKey, String label) {
    final isSelected = selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => onFilterChanged(filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4D00) : TColor.cardOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4D00) : TColor.borderOf(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : TColor.primaryTextOf(context),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Đánh giá & Nhận xét",
              style: TextStyle(
                color: TColor.primaryTextOf(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              "$totalReviewsCount nhận xét",
              style: const TextStyle(
                color: Color(0xFFFF4D00),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Rating Summary Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1E28) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TColor.borderOf(context)),
          ),
          child: Row(
            children: [
              Text(
                totalReviewsCount > 0 && avgRating > 0 ? avgRating.toStringAsFixed(1) : "--",
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (s) {
                        return Icon(
                          totalReviewsCount > 0 && s < avgRating.round()
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: const Color(0xFFFFB800),
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalReviewsCount > 0
                          ? "Dựa trên $totalReviewsCount đánh giá thực tế"
                          : "Chưa có đánh giá nào",
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalReviewsCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${(reviewsList.where((r) => r.rating >= 4).length * 100 / (reviewsList.isNotEmpty ? reviewsList.length : 1)).round()}% Hài lòng",
                    style: const TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(context, "all", "Tất cả ($totalReviewsCount)"),
              const SizedBox(width: 8),
              _filterChip(context, "image", "📷 Có hình ảnh ($_imageReviewsCount)"),
              const SizedBox(width: 8),
              _filterChip(context, "5star", "5 ★ ($_fiveStarReviewsCount)"),
              const SizedBox(width: 8),
              _filterChip(context, "latest", "Mới nhất"),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Review Cards List
        if (isLoading)
          _buildSkeletonReviews()
        else if (_filteredReviews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TColor.cardOf(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TColor.borderOf(context)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 36,
                  color: TColor.secondaryTextOf(context).withOpacity(0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  "Chưa có đánh giá phù hợp",
                  style: TextStyle(
                    color: TColor.secondaryTextOf(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _filteredReviews.map((review) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: TColor.cardOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TColor.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: isDark
                              ? const Color(0xFF2A2E3B)
                              : const Color(0xFFE5E7EB),
                          child: Text(
                            _getInitials(review.customerName),
                            style: TextStyle(
                              color: TColor.primaryTextOf(context),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    review.customerName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: TColor.primaryTextOf(context),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      "Đã mua món",
                                      style: TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(5, (s) {
                                      return Icon(
                                        s < review.rating ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: const Color(0xFFFFB800),
                                        size: 13,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "•  ${_formatTimeAgo(review.createdAt)}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: TColor.secondaryTextOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Comment
                    if (review.comment != null && review.comment!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        review.comment!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: TColor.primaryTextOf(context),
                        ),
                      ),
                    ],

                    // Review Image Thumbnail
                    if (review.image != null && review.image!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SmartNetworkImage(
                          imageUrl: review.image!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    // Restaurant Reply
                    if (review.reply != null && review.reply!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B1E28) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFF4D00).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Phản hồi từ quán:",
                              style: TextStyle(
                                color: Color(0xFFFF4D00),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review.reply!,
                              style: TextStyle(
                                fontSize: 12,
                                color: TColor.primaryTextOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 10),

        // Bottom "Xem tất cả X đánh giá" Button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: TColor.borderOf(context)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            onPressed: () {},
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Xem tất cả $totalReviewsCount đánh giá",
                  style: TextStyle(
                    color: TColor.primaryTextOf(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: TColor.secondaryTextOf(context)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
