import 'package:flutter/material.dart';
import 'skeleton_box.dart';
import 'skeleton_line.dart';
import 'skeleton_shimmer.dart';

class RestaurantCardSkeleton extends StatelessWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(
            width: double.infinity,
            height: 180,
            borderRadius: 14,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLine(width: 180, height: 16),
              SkeletonLine(width: 60, height: 14),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              SkeletonBox(width: 14, height: 14, borderRadius: 3),
              SizedBox(width: 6),
              SkeletonLine(width: 40, height: 12),
              SizedBox(width: 12),
              SkeletonLine(width: 120, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

class RestaurantSkeletonList extends StatelessWidget {
  final int itemCount;

  const RestaurantSkeletonList({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: itemCount,
        itemBuilder: (context, index) => const RestaurantCardSkeleton(),
      ),
    );
  }
}
