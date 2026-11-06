import 'package:flutter/material.dart';
import 'skeleton_shimmer.dart';
import 'skeleton_box.dart';
import 'skeleton_line.dart';

class AboutUsSkeleton extends StatelessWidget {
  const AboutUsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card skeleton
            const SkeletonBox(
              height: 180,
              borderRadius: 20,
            ),
            const SizedBox(height: 16),

            // Stats row skeleton (3 boxes)
            Row(
              children: List.generate(
                3,
                (index) => const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: SkeletonBox(
                      height: 65,
                      borderRadius: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mission & Vision card skeleton
            const SkeletonBox(
              height: 140,
              borderRadius: 20,
            ),
            const SizedBox(height: 20),

            // Section title: Core values
            const Row(
              children: [
                SkeletonBox(
                  width: 4,
                  height: 18,
                  borderRadius: 2,
                ),
                SizedBox(width: 8),
                SkeletonLine(width: 120, height: 18),
              ],
            ),
            const SizedBox(height: 12),

            // Core values 2x2 grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const SkeletonBox(
                borderRadius: 18,
              ),
            ),
            const SizedBox(height: 20),

            // Contact footer skeleton
            const SkeletonBox(
              height: 160,
              borderRadius: 20,
            ),
            const SizedBox(height: 24),

            // Footer version skeleton
            const Center(
              child: Column(
                children: [
                  SkeletonLine(width: 180, height: 12),
                  SizedBox(height: 6),
                  SkeletonLine(width: 220, height: 10),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
