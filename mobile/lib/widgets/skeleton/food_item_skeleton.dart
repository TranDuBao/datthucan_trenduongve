import 'package:flutter/material.dart';
import 'skeleton_box.dart';
import 'skeleton_line.dart';
import 'skeleton_shimmer.dart';

class FoodItemSkeleton extends StatelessWidget {
  const FoodItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF171B26)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF232836)
              : const Color(0xFFEFEFEF),
        ),
      ),
      child: Row(
        children: [
          const SkeletonBox(
            width: 75,
            height: 75,
            borderRadius: 10,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonLine(width: 160, height: 16),
                SizedBox(height: 8),
                SkeletonLine(width: 100, height: 12),
                SizedBox(height: 10),
                SkeletonLine(width: 70, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SkeletonBox(
            width: 32,
            height: 32,
            borderRadius: 8,
          ),
        ],
      ),
    );
  }
}

class FoodItemSkeletonList extends StatelessWidget {
  final int itemCount;

  const FoodItemSkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: itemCount,
        itemBuilder: (context, index) => const FoodItemSkeleton(),
      ),
    );
  }
}
