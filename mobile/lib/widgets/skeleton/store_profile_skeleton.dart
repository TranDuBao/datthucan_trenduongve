import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import 'skeleton_shimmer.dart';
import 'skeleton_box.dart';
import 'skeleton_line.dart';

class StoreProfileSkeleton extends StatelessWidget {
  const StoreProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          children: [
            // ── Top Header Card Skeleton ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TColor.cardOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TColor.borderOf(context)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(
                        width: 72,
                        height: 72,
                        borderRadius: 16,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            SkeletonLine(width: 160, height: 16),
                            SizedBox(height: 8),
                            SkeletonLine(width: 210, height: 12),
                            SizedBox(height: 8),
                            SkeletonLine(width: 120, height: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    color: TColor.borderOf(context).withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SkeletonBox(width: 100, height: 28, borderRadius: 14),
                      SkeletonBox(width: 110, height: 28, borderRadius: 14),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Description & Info Card Skeleton ──────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TColor.cardOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TColor.borderOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(width: 130, height: 14),
                  SizedBox(height: 10),
                  SkeletonLine(width: double.infinity, height: 12),
                  SizedBox(height: 6),
                  SkeletonLine(width: 240, height: 12),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── 2 Columns Grid Skeleton ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TColor.cardOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TColor.borderOf(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLine(width: 80, height: 12),
                        SizedBox(height: 8),
                        SkeletonBox(width: 90, height: 24, borderRadius: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TColor.cardOf(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TColor.borderOf(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLine(width: 80, height: 12),
                        SizedBox(height: 8),
                        SkeletonBox(width: 90, height: 24, borderRadius: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Operating Hours Card Skeleton ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TColor.cardOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TColor.borderOf(context)),
              ),
              child: Row(
                children: [
                  const SkeletonBox(width: 38, height: 38, borderRadius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLine(width: 150, height: 14),
                        SizedBox(height: 6),
                        SkeletonLine(width: 110, height: 12),
                      ],
                    ),
                  ),
                  const SkeletonBox(width: 60, height: 20, borderRadius: 6),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── VietQR / Bank Card Skeleton ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TColor.cardOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TColor.borderOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonLine(width: 180, height: 14),
                  SizedBox(height: 12),
                  SkeletonBox(width: double.infinity, height: 70, borderRadius: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

