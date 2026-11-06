import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import 'skeleton_box.dart';
import 'skeleton_line.dart';
import 'skeleton_shimmer.dart';

class NotificationItemSkeleton extends StatelessWidget {
  const NotificationItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TColor.borderOf(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box Skeleton
          SkeletonBox(
            width: 44,
            height: 44,
            borderRadius: 14.0,
          ),
          SizedBox(width: 12),

          // Content Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Time Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 80, height: 18, borderRadius: 6.0),
                    SkeletonLine(width: 50, height: 11),
                  ],
                ),
                SizedBox(height: 10),

                // Title
                SkeletonLine(width: 170, height: 15),
                SizedBox(height: 7),

                // Body Line 1
                SkeletonLine(width: double.infinity, height: 12),
                SizedBox(height: 5),

                // Body Line 2
                SkeletonLine(width: 140, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationSkeletonList extends StatelessWidget {
  final int itemCount;

  const NotificationSkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          // Group Header Skeleton
          const Row(
            children: [
              SkeletonBox(width: 4, height: 14, borderRadius: 2.0),
              SizedBox(width: 8),
              SkeletonLine(width: 80, height: 12),
            ],
          ),
          const SizedBox(height: 10),

          // Cards
          for (int i = 0; i < itemCount; i++) ...[
            const NotificationItemSkeleton(),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
