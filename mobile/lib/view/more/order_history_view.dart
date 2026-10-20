import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/locator.dart';
import '../../providers/language_provider.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/order_progress_stepper.dart';
import '../../widgets/skeleton/order_item_skeleton.dart';
import '../menu/item_details_view.dart';
import 'order_detail_sheet.dart';
import 'order_history_cards.dart';
import 'order_history_widgets.dart';
import 'order_review_view.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  List<OrderServiceModel> ordersList = [];
  Set<int> reviewedOrderIds = {};
  bool isLoadingOrders = true;
  int selectedTabIndex = 0;
  void Function(void Function())? _activeSheetSetState;

  // ───────────────────────── Lifecycle ──────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchOrdersHistory();
    _setupSocketRealtime();
  }

  @override
  void dispose() {
    try {
      locator<SocketService>().offOrderUpdates();
    } catch (_) {}
    super.dispose();
  }

  // ───────────────────────── Socket ─────────────────────────────────────────
  void _setupSocketRealtime() {
    try {
      final socketService = locator<SocketService>();
      socketService.connect();
      socketService.onReconnect(() {
        debugPrint('⚡ Socket reconnected -> Refetching orders...');
        _fetchOrdersHistory();
      });
      socketService.listenToOrderUpdates((data) {
        if (!mounted || data == null) return;
        final rawId = data['id'] ?? data['orderId'] ?? data['maDonHang'];
        final newStatus = data['status'] ?? data['trangThai'];
        if (rawId != null && newStatus != null) {
          final orderId = int.tryParse(rawId.toString()) ?? 0;
          setState(() {
            for (var order in ordersList) {
              if (order.orderId == orderId) {
                order.status = newStatus.toString();
              }
            }
          });
          _activeSheetSetState?.call(() {});
        }
      });
    } catch (e) {
      debugPrint('⚠️ Socket listener error: $e');
    }
  }

  // ───────────────────────── Data loading ───────────────────────────────────
  Future<void> _fetchOrdersHistory() async {
    setState(() => isLoadingOrders = true);
    final list = await OrderService.fetchMyOrders();
    final Set<int> reviewedSet = {};
    for (var order in list) {
      if (OrderProgressStepper.getStepFromStatus(order.status) == 5) {
        final review = await ReviewService.getReviewByOrder(order.orderId);
        if (review != null) reviewedSet.add(order.orderId);
      }
    }
    if (mounted) {
      setState(() {
        ordersList = list;
        reviewedOrderIds = reviewedSet;
        isLoadingOrders = false;
      });
      try {
        final socketService = locator<SocketService>();
        for (var order in list) {
          if (!isCompletedOrder(order.status) && !isCancelledOrder(order.status)) {
            socketService.joinOrderRoom(order.orderId);
          }
        }
      } catch (_) {}
    }
  }

  // ───────────────────────── Filtered lists ─────────────────────────────────
  List<OrderServiceModel> get _activeOrders =>
      ordersList.where((o) => !isCompletedOrder(o.status) && !isCancelledOrder(o.status)).toList();

  List<OrderServiceModel> get _completedOrders =>
      ordersList.where((o) => isCompletedOrder(o.status)).toList();

  List<OrderServiceModel> get _cancelledOrders =>
      ordersList.where((o) => isCancelledOrder(o.status)).toList();

  // ───────────────────────── Navigation helpers ──────────────────────────────
  void _navigateToItemDetails(dynamic item, OrderServiceModel order) {
    final Map<String, dynamic> itemObj = {
      'maMonAn': item != null ? (item['maMonAn'] ?? item['foodId'] ?? item['id'] ?? 1) : 1,
      'id': item != null ? (item['maMonAn'] ?? item['foodId'] ?? item['id'] ?? 1) : 1,
      'tenMonAn': item != null ? (item['tenMonAn'] ?? item['name'] ?? item['foodName'] ?? 'Món ăn') : 'Món ăn',
      'name': item != null ? (item['tenMonAn'] ?? item['name'] ?? item['foodName'] ?? 'Món ăn') : 'Món ăn',
      'giaMonAn': item != null ? (item['gia'] ?? item['price'] ?? order.totalAmount) : order.totalAmount,
      'price': item != null ? (item['gia'] ?? item['price'] ?? order.totalAmount) : order.totalAmount,
      'hinhAnh': item != null ? (item['hinhAnh'] ?? item['image'] ?? item['img'] ?? '') : '',
      'image': item != null ? (item['hinhAnh'] ?? item['image'] ?? item['img'] ?? '') : '',
      'maQuan': order.restaurantId ?? (item != null ? (item['maQuan'] ?? item['restaurantId']) : null) ?? 1,
      'restaurantId': order.restaurantId ?? (item != null ? (item['maQuan'] ?? item['restaurantId']) : null) ?? 1,
      'tenQuan': order.restaurantName,
      'trangThaiMon': 'DANG_BAN',
      'soLuongMon': 99,
      'danhGiaTrungBinh': 0.0,
      'soLuongDanhGia': 0,
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailsView(itemObj: itemObj)));
  }

  // ───────────────────────── Order actions ──────────────────────────────────
  Future<void> _handleCancelOrder(OrderServiceModel order) async {
    final stepNum = OrderProgressStepper.getStepFromStatus(order.status);
    if (stepNum >= 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đơn hàng đang ở Bước $stepNum (Bếp đang chuẩn bị). Không thể hủy đơn lúc này!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận hủy đơn hàng'),
        content: Text(
            'Bạn có chắc chắn muốn hủy đơn hàng #DH${order.orderId} tại ${order.restaurantName} không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD92D20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hủy đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đang xử lý hủy đơn...'), duration: Duration(seconds: 1)),
      );
      final success = await OrderService.cancelOrder(order.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Đã hủy đơn hàng thành công!' : 'Không thể hủy đơn hàng. Vui lòng thử lại sau!'),
          backgroundColor: success ? const Color(0xFFFC6011) : Colors.redAccent,
        ),
      );
      if (success) _fetchOrdersHistory();
    }
  }

  void _openDetailSheet(OrderServiceModel order, bool isDark) {
    showOrderDetailSheet(
      context: context,
      order: order,
      ordersList: ordersList,
      isDark: isDark,
      setActiveSheetState: (setter) => _activeSheetSetState = setter,
      clearActiveSheetState: () => _activeSheetSetState = null,
      onCancelOrder: _handleCancelOrder,
      onNavigateToItem: _navigateToItemDetails,
    );
  }

  void _openReviewSheet(OrderServiceModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderReviewView(order: order)),
    ).then((_) => _fetchOrdersHistory());
  }

  // ───────────────────────── Build ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>(); // rebuild on locale change
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12141C) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OrderHistoryRoundIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                    isDark: isDark,
                  ),
                  Text(
                    'Đơn hàng của tôi',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF101828),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  OrderHistoryRoundIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: _fetchOrdersHistory,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Filter tabs
            OrderFilterTabBar(
              selectedIndex: selectedTabIndex,
              allOrders: ordersList,
              activeOrders: _activeOrders,
              completedOrders: _completedOrders,
              cancelledOrders: _cancelledOrders,
              onTabSelected: (idx) => setState(() => selectedTabIndex = idx),
            ),

            const SizedBox(height: 10),

            // Body
            Expanded(
              child: isLoadingOrders
                  ? const OrderSkeletonList(itemCount: 4)
                  : ordersList.isEmpty
                      ? const OrderHistoryEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchOrdersHistory,
                          color: const Color(0xFFFC6011),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Active section
                                if (selectedTabIndex == 0 || selectedTabIndex == 1) ...[
                                  if (_activeOrders.isNotEmpty) ...[
                                    OrderSectionHeader(
                                      title: 'ĐANG CHUẨN BỊ & GIAO (${_activeOrders.length} ĐƠN)',
                                      subtitle: 'Cập nhật tức thì',
                                      iconDot: true,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 12),
                                    ..._activeOrders.map((order) => ActiveOrderCard(
                                          order: order,
                                          isDark: isDark,
                                          onCancel: () => _handleCancelOrder(order),
                                          onShowDetail: () => _openDetailSheet(order, isDark),
                                          onNavigateToItem: _navigateToItemDetails,
                                        )),
                                    const SizedBox(height: 16),
                                  ] else if (selectedTabIndex == 1) ...[
                                    const OrderEmptyFilterState(message: 'Chưa có đơn hàng đang xử lý'),
                                  ],
                                ],

                                // Completed section
                                if (selectedTabIndex == 0 || selectedTabIndex == 2) ...[
                                  if (_completedOrders.isNotEmpty) ...[
                                    OrderSectionHeader(
                                      title: 'Lịch sử đã lấy hàng',
                                      badgeText: '${_completedOrders.length} đơn hoàn tất',
                                      iconCheck: true,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 12),
                                    ..._completedOrders.map((order) => CompletedOrderCard(
                                          order: order,
                                          isDark: isDark,
                                          isReviewed: reviewedOrderIds.contains(order.orderId),
                                          onReview: () => _openReviewSheet(order),
                                          onShowDetail: () => _openDetailSheet(order, isDark),
                                          onNavigateToItem: _navigateToItemDetails,
                                        )),
                                    const SizedBox(height: 16),
                                  ] else if (selectedTabIndex == 2) ...[
                                    const OrderEmptyFilterState(message: 'Chưa có đơn hàng hoàn thành'),
                                  ],
                                ],

                                // Cancelled section
                                if (selectedTabIndex == 0 || selectedTabIndex == 3) ...[
                                  if (_cancelledOrders.isNotEmpty) ...[
                                    OrderSectionHeader(
                                      title: 'Đơn hàng đã hủy',
                                      badgeText: '${_cancelledOrders.length} đơn đã hủy',
                                      iconClose: true,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 12),
                                    ..._cancelledOrders.map((order) => CancelledOrderCard(
                                          order: order,
                                          isDark: isDark,
                                          onShowDetail: () => _openDetailSheet(order, isDark),
                                          onNavigateToItem: _navigateToItemDetails,
                                        )),
                                    const SizedBox(height: 16),
                                  ] else if (selectedTabIndex == 3) ...[
                                    const OrderEmptyFilterState(message: 'Chưa có đơn hàng nào bị hủy'),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
