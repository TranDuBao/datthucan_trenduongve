import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import 'skeleton_box.dart';
import 'skeleton_line.dart';
import 'skeleton_shimmer.dart';

class VoucherItemSkeleton extends StatelessWidget {
  const VoucherItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Badge / Discount Box Skeleton
          SkeletonBox(
            width: 50,
            height: 50,
            borderRadius: 14.0,
          ),
          SizedBox(width: 14),

          // Details Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag & Code Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLine(width: 80, height: 11),
                    SkeletonBox(width: 65, height: 20, borderRadius: 6.0),
                  ],
                ),
                SizedBox(height: 8),

                // Discount Title
                SkeletonLine(width: 160, height: 16),
                SizedBox(height: 6),

                // Min spend / Description
                SkeletonLine(width: 130, height: 12),
                SizedBox(height: 12),

                // Expiry and Action Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SkeletonLine(width: 95, height: 11),
                    SkeletonBox(width: 76, height: 30, borderRadius: 15.0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VoucherSkeletonList extends StatelessWidget {
  final int itemCount;

  const VoucherSkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: itemCount,
        itemBuilder: (context, index) => const VoucherItemSkeleton(),
      ),
    );
  }
}
