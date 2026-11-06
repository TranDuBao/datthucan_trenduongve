import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import 'skeleton_shimmer.dart';
import 'skeleton_box.dart';
import 'skeleton_circle.dart';
import 'skeleton_line.dart';

class StoreRegistrationSkeleton extends StatelessWidget {
  const StoreRegistrationSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        backgroundColor: TColor.bgOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: TColor.primaryTextOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Trở Thành Cửa Hàng",
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SkeletonShimmer(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner Skeleton
              const SkeletonBox(
                height: 76,
                borderRadius: 16.0,
              ),
              const SizedBox(height: 24),

              // Section 1 Header
              const Row(
                children: [
                  SkeletonCircle(radius: 12),
                  SizedBox(width: 10),
                  SkeletonLine(width: 180, height: 16),
                ],
              ),
              const SizedBox(height: 14),

              // Fields in Section 1
              _buildFieldSkeleton(),
              const SizedBox(height: 14),
              _buildFieldSkeleton(),
              const SizedBox(height: 14),
              _buildFieldSkeleton(),
              const SizedBox(height: 24),

              // Section 2 Header
              const Row(
                children: [
                  SkeletonCircle(radius: 12),
                  SizedBox(width: 10),
                  SkeletonLine(width: 200, height: 16),
                ],
              ),
              const SizedBox(height: 14),

              // Fields in Section 2
              _buildFieldSkeleton(),
              const SizedBox(height: 14),
              _buildFieldSkeleton(),
              const SizedBox(height: 14),
              _buildFieldSkeleton(),
              const SizedBox(height: 24),

              // Button Skeleton
              const SkeletonBox(
                height: 52,
                borderRadius: 16.0,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildFieldSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLine(width: 120, height: 13),
        SizedBox(height: 8),
        SkeletonBox(
          height: 48,
          borderRadius: 12.0,
        ),
      ],
    );
  }
}
