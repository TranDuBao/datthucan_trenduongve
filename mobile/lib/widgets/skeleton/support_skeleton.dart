import 'package:flutter/material.dart';
import 'skeleton_shimmer.dart';
import 'skeleton_box.dart';
import 'skeleton_circle.dart';
import 'skeleton_line.dart';

class SupportCenterSkeleton extends StatelessWidget {
  const SupportCenterSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero banner skeleton
            const SkeletonBox(
              height: 110,
              borderRadius: 20,
            ),
            const SizedBox(height: 20),

            // Section 1 Card Skeleton
            _buildSectionCardSkeleton(isDark, childCount: 2),
            const SizedBox(height: 20),

            // Section 2 Card Skeleton
            _buildSectionCardSkeleton(isDark, childCount: 2),
            const SizedBox(height: 20),

            // Section 3 Card Skeleton
            _buildSectionCardSkeleton(isDark, childCount: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCardSkeleton(bool isDark, {required int childCount}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SkeletonCircle(radius: 17),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(width: 140, height: 14),
                  SizedBox(height: 6),
                  SkeletonLine(width: 200, height: 11),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < childCount; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            const SkeletonBox(height: 64, borderRadius: 14),
          ],
        ],
      ),
    );
  }
}

class SupportFaqSkeleton extends StatelessWidget {
  const SupportFaqSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const SkeletonBox(height: 44, borderRadius: 12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: const [
                SkeletonBox(width: 70, height: 32, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 110, height: 32, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 95, height: 32, borderRadius: 20),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, __) => const SkeletonBox(height: 68, borderRadius: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class SupportTicketListSkeleton extends StatelessWidget {
  const SupportTicketListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: const [
                SkeletonBox(width: 70, height: 32, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 60, height: 32, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 90, height: 32, borderRadius: 20),
                SizedBox(width: 8),
                SkeletonBox(width: 100, height: 32, borderRadius: 20),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, __) => const SkeletonBox(height: 105, borderRadius: 16),
            ),
          ),
        ],
      ),
    );
  }
}
