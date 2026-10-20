import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../common/color_extension.dart';
import '../../common/globs.dart';
import 'restaurant_revenue_sections.dart';
import 'restaurant_revenue_states.dart';

class RestaurantRevenueView extends StatefulWidget {
  const RestaurantRevenueView({super.key});

  @override
  State<RestaurantRevenueView> createState() => _RestaurantRevenueViewState();
}

class _RestaurantRevenueViewState extends State<RestaurantRevenueView> {
  String _selectedPeriod = '7days';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  bool _loading = true;
  String? _errorMessage;

  Map<String, dynamic>? _revenueData;
  int? _selectedChartIndex;

  final List<Map<String, String>> _periodOptions = const [
    {'key': 'today', 'label': 'Hôm nay'},
    {'key': '7days', 'label': '7 ngày'},
    {'key': '30days', 'label': '30 ngày'},
    {'key': 'this_month', 'label': 'Tháng này'},
    {'key': 'last_month', 'label': 'Tháng trước'},
    {'key': 'custom', 'label': 'Tùy chọn'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchRevenueAnalytics();
  }

  Future<void> _fetchRevenueAnalytics() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _selectedChartIndex = null;
    });

    final token = Globs.udValueString(KKey.authToken);
    final headers = {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    String url = '${SVKey.mainUrl}/api/v1/restaurant/revenue?period=$_selectedPeriod';
    if (_selectedPeriod == 'custom' && _customStartDate != null && _customEndDate != null) {
      final fromStr = _customStartDate!.toIso8601String();
      final toStr = _customEndDate!.toIso8601String();
      url += '&from=$fromStr&to=$toStr';
    }

    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == '1' && body['data'] is Map) {
          if (mounted) {
            setState(() {
              _revenueData = Map<String, dynamic>.from(body['data']);
              _loading = false;
            });
          }
          return;
        }
      } else if (response.statusCode == 404) {
        // Fallback: If backend route /revenue is 404, try /dashboard endpoint
        final dashRes = await http.get(Uri.parse('${SVKey.mainUrl}/api/v1/restaurant/dashboard'), headers: headers).timeout(const Duration(seconds: 5));
        if (dashRes.statusCode == 200) {
          final dashBody = json.decode(dashRes.body);
          final dashData = dashBody['data'] as Map? ?? {};
          final rev = double.tryParse((dashData['revenue'] ?? 0).toString()) ?? 0.0;
          final todayCount = (dashData['todayOrdersCount'] as num?)?.toInt() ?? 0;

          if (mounted) {
            setState(() {
              _revenueData = {
                'period': _selectedPeriod,
                'summary': {
                  'totalRevenue': rev,
                  'previousPeriodRevenue': 0,
                  'growthRate': 0,
                  'totalOrders': todayCount,
                  'completedOrders': rev > 0 ? 1 : 0,
                  'averageOrderValue': rev > 0 ? rev : 0,
                },
                'chart': [],
                'orderStatus': [],
                'topFoods': [],
                'orderTypes': [],
              };
              _loading = false;
            });
          }
          return;
        }
      } else if (response.statusCode == 401) {
        if (mounted) {
          setState(() {
            _errorMessage = "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.";
            _loading = false;
          });
        }
        return;
      }

      String msg = "Không thể lấy dữ liệu thống kê doanh thu";
      try {
        final errJson = json.decode(response.body);
        if (errJson['message'] != null) msg = errJson['message'];
      } catch (_) {}

      if (mounted) {
        setState(() {
          _errorMessage = msg;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Lỗi kết nối máy chủ. Vui lòng kiểm tra lại mạng!";
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? now.subtract(const Duration(days: 7)),
        end: _customEndDate ?? now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _selectedPeriod = 'custom';
        _customStartDate = pickedRange.start;
        _customEndDate = pickedRange.end;
      });
      _fetchRevenueAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E232A) : Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TColor.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.bar_chart_rounded, color: TColor.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Doanh Thu & Báo Cáo",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "Theo dõi hiệu quả kinh doanh thực tế",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: TColor.primary),
            onPressed: _fetchRevenueAnalytics,
            tooltip: "Làm mới dữ liệu",
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRevenueAnalytics,
        color: TColor.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Filter Bar
              RevenuePeriodFilterBar(
                periodOptions: _periodOptions,
                selectedPeriod: _selectedPeriod,
                customStartDate: _customStartDate,
                customEndDate: _customEndDate,
                onSelectCustomRange: _selectCustomDateRange,
                onSelectPeriod: (period) {
                  setState(() => _selectedPeriod = period);
                  _fetchRevenueAnalytics();
                },
              ),
              const SizedBox(height: 16),

              // 2. Main Content States (Loading / Error / Data)
              if (_loading)
                const RevenueSkeletonLoading()
              else if (_errorMessage != null)
                RevenueErrorState(
                  errorMessage: _errorMessage,
                  onRetry: _fetchRevenueAnalytics,
                )
              else if (_revenueData == null ||
                  ((_revenueData!['summary']?['totalOrders'] ?? 0) == 0 &&
                      (_revenueData!['summary']?['totalRevenue'] ?? 0) == 0))
                const RevenueEmptyState()
              else
                _buildDashboardContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final summary = _revenueData!['summary'] ?? {};
    final chartData = (_revenueData!['chart'] as List?) ?? [];
    final orderStatusList = (_revenueData!['orderStatus'] as List?) ?? [];
    final topFoodsList = (_revenueData!['topFoods'] as List?) ?? [];
    final orderTypesList = (_revenueData!['orderTypes'] as List?) ?? [];

    final double growthRate = double.tryParse((summary['growthRate'] ?? 0).toString()) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Primary Revenue Card (Featured Hero Metric)
        HeroRevenueCard(
          summary: summary,
          growthRate: growthRate,
        ),
        const SizedBox(height: 14),

        // B. Secondary Summary Metrics Grid
        SummaryMetricsGrid(summary: summary),
        const SizedBox(height: 20),

        // C. Interactive Time-Series Chart
        if (chartData.isNotEmpty) ...[
          RevenueChartSection(
            chartData: chartData,
            selectedChartIndex: _selectedChartIndex,
            onSelectIndex: (idx) {
              setState(() => _selectedChartIndex = idx);
            },
          ),
          const SizedBox(height: 20),
        ],

        // D. Order Status Breakdown
        if (orderStatusList.isNotEmpty) ...[
          OrderStatusSection(orderStatusList: orderStatusList),
          const SizedBox(height: 20),
        ],

        // E. Top Selling Foods
        if (topFoodsList.isNotEmpty) ...[
          TopFoodsSection(topFoodsList: topFoodsList),
          const SizedBox(height: 20),
        ],

        // F. Order Types Breakdown (Take-away vs Eat-in)
        if (orderTypesList.isNotEmpty) ...[
          OrderTypesSection(orderTypesList: orderTypesList),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
