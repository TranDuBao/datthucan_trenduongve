import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../common/color_extension.dart';

// ── 1. Period Filter Bar ──────────────────────────────────────────────────
class RevenuePeriodFilterBar extends StatelessWidget {
  final List<Map<String, String>> periodOptions;
  final String selectedPeriod;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final VoidCallback onSelectCustomRange;
  final ValueChanged<String> onSelectPeriod;

  const RevenuePeriodFilterBar({
    super.key,
    required this.periodOptions,
    required this.selectedPeriod,
    required this.customStartDate,
    required this.customEndDate,
    required this.onSelectCustomRange,
    required this.onSelectPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periodOptions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = periodOptions[index];
          final isSelected = selectedPeriod == option['key'];

          String displayLabel = option['label']!;
          if (option['key'] == 'custom' && customStartDate != null && customEndDate != null) {
            displayLabel = "${DateFormat('dd/MM').format(customStartDate!)} - ${DateFormat('dd/MM').format(customEndDate!)}";
          }

          return InkWell(
            onTap: () {
              if (option['key'] == 'custom') {
                onSelectCustomRange();
              } else if (selectedPeriod != option['key']) {
                onSelectPeriod(option['key']!);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? TColor.primary : TColor.cardOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? TColor.primary : TColor.borderOf(context),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: TColor.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                displayLabel,
                style: TextStyle(
                  color: isSelected ? Colors.white : TColor.primaryTextOf(context),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Skeleton Loading State ────────────────────────────────────────────────
class RevenueSkeletonLoading extends StatelessWidget {
  const RevenueSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.withOpacity(0.2),
      highlightColor: Colors.grey.withOpacity(0.08),
      child: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 70,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────
class RevenueEmptyState extends StatelessWidget {
  const RevenueEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: TColor.primary.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.bar_chart_rounded, size: 48, color: TColor.primary),
          ),
          const SizedBox(height: 16),
          Text(
            "Chưa có dữ liệu doanh thu",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: TColor.primaryTextOf(context)),
          ),
          const SizedBox(height: 6),
          Text(
            "Doanh thu sẽ xuất hiện khi cửa hàng phát sinh đơn hàng hoàn thành.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
          ),
        ],
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────
class RevenueErrorState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const RevenueErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFEF4444)),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? "Đã xảy ra lỗi khi tải dữ liệu",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF991B1B)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Thử lại", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
