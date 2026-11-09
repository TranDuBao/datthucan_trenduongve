import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/locator.dart';
import '../../common/format_utils.dart';
import '../../providers/language_provider.dart';
import '../../providers/map_provider.dart';
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
import '../main_tabview/main_tabview.dart';
import '../../widgets/order_cancel_confirm_dialog.dart';

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
        debugPrint('[OrderHistory] [Info] Socket reconnected -> Refetching orders silently...');
        _fetchOrdersHistory(silent: true);
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
      debugPrint('[OrderHistory] [Warn] Socket listener error: $e');
    }
  }

  // ───────────────────────── Data loading ───────────────────────────────────
  Future<void> _fetchOrdersHistory({bool silent = false}) async {
    if (!silent && ordersList.isEmpty) {
      setState(() => isLoadingOrders = true);
    }
    final list = await OrderService.fetchMyOrders();
    final Set<int> reviewedSet = {};
    
    // Tải song song đánh giá các đơn đã hoàn tất thay vì tuần tự
    final completedOrders = list.where((o) => OrderProgressStepper.getStepFromStatus(o.status) == 5).toList();
    if (completedOrders.isNotEmpty) {
      final reviews = await Future.wait(
        completedOrders.map((order) => ReviewService.getReviewByOrder(order.orderId).catchError((_) => null)),
      );
      for (int i = 0; i < completedOrders.length; i++) {
        if (reviews[i] != null) {
          reviewedSet.add(completedOrders[i].orderId);
        }
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
      ordersList.where((o) => !isCompletedOrder(o.status) && !isCancelledOrder(o.status) && !isUnpaidOrder(o.status)).toList();

  List<OrderServiceModel> get _unpaidOrders =>
      ordersList.where((o) => isUnpaidOrder(o.status)).toList();

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
          content: Text(context.l10n.orderCancelNotAllowed(stepNum)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final confirm = await OrderCancelConfirmDialog.show(context, order);

    if (confirm == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.orderCancellingProgress),
          duration: const Duration(seconds: 1),
        ),
      );

      final res = await OrderService.cancelOrder(order.orderId);
      final success = res['success'] == true;
      final serverMsg = res['message'];

      if (!mounted) return;

      if (success) {
        // Cập nhật trạng thái tức thì tại chỗ không reload lại toàn bộ màn hình
        setState(() {
          order.status = 'DA_HUY';
        });
        _activeSheetSetState?.call(() {});

        // Nếu đơn đang hủy là đơn ghé quán trên bản đồ thì giải phóng lộ trình
        try {
          final mapProvider = Provider.of<MapProvider>(context, listen: false);
          if (mapProvider.activeStopoverOrder != null) {
            final activeId = mapProvider.activeStopoverOrder!['id'] ??
                mapProvider.activeStopoverOrder!['maDonHang'] ??
                mapProvider.activeStopoverOrder!['orderId'];
            if (activeId != null && activeId.toString() == order.orderId.toString()) {
              mapProvider.cancelStopoverOrder();
            }
          }
        } catch (_) {}

        // Hiển thị thông báo thành công đẹp mắt
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.orderCancelSuccessMsg(order.orderId.toString()),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              serverMsg ?? context.l10n.orderCancelFailedMsg(order.orderId.toString()),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
    ).then((_) => _fetchOrdersHistory(silent: true));
  }

  // ───────────────────────── Build ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>(); // rebuild on locale change
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void handleBack() {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainTabView(initialTab: 2)),
          (route) => false,
        );
      }
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainTabView(initialTab: 2)),
            (route) => false,
          );
        }
      },
      child: Scaffold(
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
                      onTap: handleBack,
                      isDark: isDark,
                    ),
                  Text(
                    context.l10n.moreMyOrder,
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
                                // Unpaid section (Chờ thanh toán)
                                if ((selectedTabIndex == 0 || selectedTabIndex == 1) && _unpaidOrders.isNotEmpty) ...[
                                  OrderSectionHeader(
                                    title: context.l10n.orderUnpaidSectionTitle(_unpaidOrders.length),
                                    subtitle: context.l10n.orderUnpaidSectionSub,
                                    iconDot: true,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  ..._unpaidOrders.map((order) => UnpaidOrderCard(
                                        order: order,
                                        isDark: isDark,
                                        onCancel: () => _handleCancelOrder(order),
                                        onShowDetail: () => _openDetailSheet(order, isDark),
                                        onNavigateToItem: _navigateToItemDetails,
                                      )),
                                  const SizedBox(height: 24),
                                ],

                                // Active section
                                if (selectedTabIndex == 0 || selectedTabIndex == 1) ...[
                                  if (_activeOrders.isNotEmpty) ...[
                                    OrderSectionHeader(
                                      title: context.l10n.orderPreparingSectionTitle(_activeOrders.length),
                                      subtitle: context.l10n.orderPreparingSectionSub,
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
                                    OrderEmptyFilterState(message: context.l10n.orderEmptyProcessing),
                                  ],
                                ],

                                // Completed section
                                if (selectedTabIndex == 0 || selectedTabIndex == 2) ...[
                                  if (_completedOrders.isNotEmpty) ...[
                                    OrderSectionHeader(
                                      title: context.l10n.orderCompletedSectionTitle,
                                      badgeText: context.l10n.orderCompletedCountBadge(_completedOrders.length),
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
                                      title: context.l10n.orderCancelledSectionTitle,
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
      ),
    );
  }
}
