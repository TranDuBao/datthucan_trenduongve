import 'package:flutter/material.dart';
import 'skeleton_box.dart';
import 'skeleton_line.dart';
import 'skeleton_shimmer.dart';

class CategorySkeletonList extends StatelessWidget {
  final int itemCount;

  const CategorySkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  const SkeletonBox(
                    width: 70,
                    height: 70,
                    borderRadius: 14,
                  ),
                  const SizedBox(height: 8),
                  const SkeletonLine(
                    width: 55,
                    height: 12,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
