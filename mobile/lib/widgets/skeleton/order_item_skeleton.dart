import 'package:flutter/material.dart';
import 'skeleton_box.dart';
import 'skeleton_line.dart';
import 'skeleton_shimmer.dart';

class OrderItemSkeleton extends StatelessWidget {
  const OrderItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF171B26)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF232836)
              : const Color(0xFFEFEFEF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLine(width: 140, height: 16),
              SkeletonBox(width: 90, height: 24, borderRadius: 12),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const SkeletonBox(width: 60, height: 60, borderRadius: 10),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLine(width: 160, height: 15),
                    SizedBox(height: 6),
                    SkeletonLine(width: 90, height: 12),
                    SizedBox(height: 6),
                    SkeletonLine(width: 70, height: 12),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              SkeletonLine(width: 80, height: 14),
              SkeletonLine(width: 100, height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class OrderSkeletonList extends StatelessWidget {
  final int itemCount;

  const OrderSkeletonList({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: itemCount,
        itemBuilder: (context, index) => const OrderItemSkeleton(),
      ),
    );
  }
}
