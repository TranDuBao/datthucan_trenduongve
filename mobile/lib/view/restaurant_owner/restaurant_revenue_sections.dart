import 'package:flutter/material.dart';

import '../../common/color_extension.dart';
import '../../common/globs.dart';

String formatRevenueVND(dynamic amount) {
  final val = double.tryParse((amount ?? 0).toString()) ?? 0.0;
  return "${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} ₫";
}

// ── A. Featured Hero Revenue Card ─────────────────────────────────────────
class HeroRevenueCard extends StatelessWidget {
  final Map summary;
  final double growthRate;

  const HeroRevenueCard({
    super.key,
    required this.summary,
    required this.growthRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFC6011), Color(0xFFFF8A50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFC6011).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments_rounded, color: Colors.white70, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "TỔNG DOANH THU",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              if (growthRate != 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: growthRate >= 0 ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        growthRate >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        "${growthRate >= 0 ? '+' : ''}$growthRate%",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            formatRevenueVND(summary['totalRevenue']),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.25), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Đơn hoàn thành: ${summary['completedOrders'] ?? 0}",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                "Giá trị TB: ${formatRevenueVND(summary['averageOrderValue'])}",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── B. Secondary Summary Metrics Grid ─────────────────────────────────────
class SummaryMetricsGrid extends StatelessWidget {
  final Map summary;

  const SummaryMetricsGrid({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RevenueMetricCard(
            title: "Tổng đơn hàng",
            value: "${summary['totalOrders'] ?? 0}",
            unit: "đơn",
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RevenueMetricCard(
            title: "Đơn thành công",
            value: "${summary['completedOrders'] ?? 0}",
            unit: "đơn",
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RevenueMetricCard(
            title: "Giá trị đơn TB",
            value: formatRevenueVND(summary['averageOrderValue']),
            unit: "",
            icon: Icons.shopping_bag_rounded,
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF3E8FF),
          ),
        ),
      ],
    );
  }
}

class RevenueMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const RevenueMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.18) : bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TColor.secondaryTextOf(context)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 10, color: TColor.secondaryTextOf(context)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── C. Interactive Time-Series Bar/Line Chart ─────────────────────────────
class RevenueChartSection extends StatelessWidget {
  final List chartData;
  final int? selectedChartIndex;
  final ValueChanged<int?> onSelectIndex;

  const RevenueChartSection({
    super.key,
    required this.chartData,
    required this.selectedChartIndex,
    required this.onSelectIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double maxRevenue = 1.0;
    for (var item in chartData) {
      final rev = double.tryParse((item['revenue'] ?? 0).toString()) ?? 0.0;
      if (rev > maxRevenue) maxRevenue = rev;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Doanh Thu Theo Thời Gian",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TColor.primaryTextOf(context)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Chạm để xem chi tiết",
                  style: TextStyle(color: TColor.primary, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active Tooltip Bubble Display
          if (selectedChartIndex != null && selectedChartIndex! < chartData.length) ...[
            Builder(builder: (context) {
              final sel = chartData[selectedChartIndex!];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TColor.primary.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "📅 ${sel['label']} (${sel['fullDate']})",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
                    ),
                    Text(
                      "Doanh thu: ${formatRevenueVND(sel['revenue'])} (${sel['orders']} đơn)",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: TColor.primary),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Bar Chart Canvas Body
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(chartData.length, (index) {
                  final item = chartData[index];
                  final rev = double.tryParse((item['revenue'] ?? 0).toString()) ?? 0.0;
                  final ratio = (rev / maxRevenue).clamp(0.06, 1.0);
                  final isSelected = selectedChartIndex == index;

                  return SizedBox(
                    width: chartData.length > 7
                        ? 40.0
                        : ((MediaQuery.of(context).size.width - 64) / chartData.length).clamp(32.0, 60.0),
                    child: GestureDetector(
                      onTap: () {
                        onSelectIndex(isSelected ? null : index);
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              height: 100 * ratio,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isSelected
                                      ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                                      : [const Color(0xFFFC6011), const Color(0xFFFF8A50)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.4), blurRadius: 6)]
                                    : [],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['label'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? TColor.primary : TColor.secondaryTextOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── D. Order Status Breakdown Section ─────────────────────────────────────
class OrderStatusSection extends StatelessWidget {
  final List orderStatusList;

  const OrderStatusSection({super.key, required this.orderStatusList});

  @override
  Widget build(BuildContext context) {
    int totalCount = 0;
    for (var s in orderStatusList) {
      totalCount += (s['count'] as num?)?.toInt() ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tình Trạng Đơn Hàng",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TColor.primaryTextOf(context)),
          ),
          const SizedBox(height: 14),
          Column(
            children: orderStatusList.map<Widget>((item) {
              final label = item['label'] ?? 'Khác';
              final count = (item['count'] as num?)?.toInt() ?? 0;
              final percent = totalCount > 0 ? (count / totalCount) : 0.0;

              Color statusColor = const Color(0xFF3B82F6);
              if (label.contains('hoàn thành') || label.contains('lấy món')) {
                statusColor = const Color(0xFF10B981);
              } else if (label.contains('hủy')) {
                statusColor = const Color(0xFFEF4444);
              } else if (label.contains('chuẩn bị')) {
                statusColor = const Color(0xFFFC6011);
              } else if (label.contains('xác nhận')) {
                statusColor = const Color(0xFF8B5CF6);
              } else if (label.contains('sẵn sàng')) {
                statusColor = const Color(0xFFF59E0B);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context))),
                          ],
                        ),
                        Text(
                          "$count đơn (${(percent * 100).toStringAsFixed(0)}%)",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TColor.secondaryTextOf(context)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 5,
                        backgroundColor: statusColor.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── E. Top Selling Foods Section ──────────────────────────────────────────
class TopFoodsSection extends StatelessWidget {
  final List topFoodsList;

  const TopFoodsSection({super.key, required this.topFoodsList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Món Bán Chạy Top 10",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TColor.primaryTextOf(context)),
              ),
              Text(
                "Xếp theo doanh thu",
                style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topFoodsList.length,
            separatorBuilder: (_, __) => Divider(color: TColor.borderOf(context), height: 16),
            itemBuilder: (context, index) {
              final food = topFoodsList[index];
              final name = food['tenMonAn'] ?? 'Món ăn';
              final qty = food['soLuong'] ?? 0;
              final rev = food['doanhThu'] ?? 0;
              final share = food['sharePercent'] ?? 0;
              final imgUrl = food['img'] ?? '';

              final formattedImg = SVKey.formatImageUrl(imgUrl.toString());

              return Row(
                children: [
                  // Rank badge
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: index < 3 ? const Color(0xFFFC6011) : Colors.grey.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: index < 3 ? Colors.white : Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Image Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: formattedImg.isNotEmpty
                        ? Image.network(
                            formattedImg,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(Icons.fastfood, color: TColor.primary, size: 24),
                          )
                        : Icon(Icons.fastfood, color: TColor.primary, size: 24),
                  ),
                  const SizedBox(width: 10),

                  // Name & Quantity
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$qty món đã bán ($share% doanh thu)",
                          style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context)),
                        ),
                      ],
                    ),
                  ),

                  // Revenue
                  Text(
                    formatRevenueVND(rev),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: TColor.primary),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── F. Order Types Breakdown Section (Take-away vs Eat-in) ────────────────
class OrderTypesSection extends StatelessWidget {
  final List orderTypesList;

  const OrderTypesSection({super.key, required this.orderTypesList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Doanh Thu Theo Loại Đơn",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: TColor.primaryTextOf(context)),
          ),
          const SizedBox(height: 12),
          Row(
            children: orderTypesList.map<Widget>((typeItem) {
              final typeKey = typeItem['typeKey'] ?? 'PRE_ORDER';
              final label = typeItem['label'] ?? 'Tự Đến Lấy';
              final count = typeItem['count'] ?? 0;
              final rev = typeItem['revenue'] ?? 0;

              final isTakeAway = typeKey == 'PRE_ORDER';

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isTakeAway ? const Color(0xFFFFF4EE) : const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isTakeAway
                          ? const Color(0xFFFC6011).withOpacity(0.3)
                          : const Color(0xFF0284C7).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isTakeAway ? Icons.shopping_bag_rounded : Icons.table_restaurant_rounded,
                            color: isTakeAway ? const Color(0xFFFC6011) : const Color(0xFF0284C7),
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isTakeAway ? const Color(0xFFFC6011) : const Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatRevenueVND(rev),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: TColor.primaryTextOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$count đơn hàng",
                        style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context)),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
