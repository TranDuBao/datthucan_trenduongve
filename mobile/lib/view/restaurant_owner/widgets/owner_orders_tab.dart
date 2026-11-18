import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/color_extension.dart';
import '../../../widgets/custom_toast.dart';
import '../../../widgets/skeleton/order_item_skeleton.dart';
import '../../../providers/restaurant_orders_provider.dart';
import 'owner_order_card.dart';

class OwnerOrdersTab extends StatelessWidget {
  const OwnerOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RestaurantOrdersProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Offline / Reconnect Status Pill
        if (!provider.isConnected)
          Center(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2415) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF785415) : const Color(0xFFFDE68A),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang đồng bộ trực tiếp với máy chủ...',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Search Bar & Filter Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Search Field
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: TColor.cardOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TColor.borderOf(context)),
                ),
                child: TextField(
                  onChanged: provider.setSearchQuery,
                  style: TextStyle(fontSize: 13, color: TColor.primaryTextOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã đơn (#61...), tên khách, SĐT...',
                    hintStyle: TextStyle(fontSize: 13, color: TColor.placeholder),
                    prefixIcon: Icon(Icons.search, size: 20, color: TColor.secondaryTextOf(context)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Period Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(context, 'Tất cả', 'ALL', provider),
                    _buildFilterChip(context, 'Hôm nay', 'TODAY', provider),
                    _buildFilterChip(context, '7 ngày qua', '7DAYS', provider),
                    _buildFilterChip(context, '30 ngày qua', '30DAYS', provider),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2 Main Tabs: "Cần xử lý" & "Lịch sử / Đã xong"
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF171B26) : const Color(0xFFE2E8F0).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSegmentButton(
                  context: context,
                  label: 'Cần xử lý',
                  badgeCount: provider.activeOrders.length,
                  isSelected: provider.selectedTab == 0,
                  onTap: () => provider.setSelectedTab(0),
                ),
              ),
              Expanded(
                child: _buildSegmentButton(
                  context: context,
                  label: 'Lịch sử / Đã xong',
                  badgeCount: provider.historyOrders.length,
                  isSelected: provider.selectedTab == 1,
                  onTap: () => provider.setSelectedTab(1),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Orders List
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFC6011),
            onRefresh: provider.fetchOrders,
            child: _buildContent(context, provider),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String value, RestaurantOrdersProvider provider) {
    final isSelected = provider.selectedPeriod == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => provider.setSelectedPeriod(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFC6011)
                : (isDark ? const Color(0xFF28303D) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFC6011)
                  : (isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFC6011).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : TColor.primaryTextOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required BuildContext context,
    required String label,
    required int badgeCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF28303D) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFFFC6011) : TColor.secondaryTextOf(context),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFC6011) : (isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : TColor.primaryTextOf(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RestaurantOrdersProvider provider) {
    if (provider.isLoading && provider.orders.isEmpty) {
      return _buildSkeletonLoading(context);
    }

    final currentList = provider.selectedTab == 0 ? provider.activeOrders : provider.historyOrders;

    if (currentList.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: provider.selectedTab == 0
                        ? const Color(0xFF10B981).withOpacity(0.12)
                        : TColor.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    provider.selectedTab == 0 ? Icons.task_alt_rounded : Icons.history_rounded,
                    size: 42,
                    color: provider.selectedTab == 0 ? const Color(0xFF10B981) : TColor.primary,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  provider.selectedTab == 0
                      ? 'Tuyệt vời! Không có đơn nào đang chờ xử lý'
                      : 'Chưa có đơn hàng trong lịch sử',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    provider.selectedTab == 0
                        ? 'Khi khách hàng đặt đơn trên FoodRoute, đơn sẽ xuất hiện tại đây ngay lập tức kèm chuông báo.'
                        : 'Các đơn đã hoàn thành hoặc đã hủy sẽ được lưu trữ tại đây để bạn tiện theo dõi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: TColor.secondaryTextOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: currentList.length,
      itemBuilder: (ctx, i) {
        final order = currentList[i];
        final orderId = order['maDonHang'] ?? order['id'] ?? 0;
        return OwnerOrderCard(
          key: ValueKey('order_$orderId'),
          order: order,
          onUpdateStatus: (newStatus, {lyDo}) async {
            final success = await provider.updateStatus(orderId, newStatus, lyDo: lyDo);
            if (success) {
              if (ctx.mounted) {
                CustomToast.showSuccess(ctx, 'Đã cập nhật trạng thái đơn #$orderId');
              }
            } else {
              if (ctx.mounted) {
                CustomToast.showError(ctx, 'Không thể cập nhật trạng thái');
              }
            }
          },
        );
      },
    );
  }

  Widget _buildSkeletonLoading(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: OrderSkeletonList(itemCount: 4),
    );
  }
}
