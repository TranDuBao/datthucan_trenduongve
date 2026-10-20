import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/color_extension.dart';
import '../../../widgets/custom_toast.dart';
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
        // Offline / Reconnect Banner
        if (!provider.isConnected)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: const Color(0xFFF59E0B),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 8),
                Text(
                  'Đang mất kết nối socket • Đang kết nối lại...',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
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
                    hintText: 'Tìm theo mã đơn (#DH-...), tên khách, SĐT...',
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
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : TColor.primaryTextOf(context),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFFFC6011),
        backgroundColor: TColor.cardOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? const Color(0xFFFC6011) : TColor.borderOf(context),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        onSelected: (_) => provider.setSelectedPeriod(value),
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
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? TColor.cardOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
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
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFFFC6011) : TColor.secondaryTextOf(context),
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFC6011) : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
                Icon(
                  provider.selectedTab == 0 ? Icons.check_circle_outline : Icons.history,
                  size: 56,
                  color: TColor.secondaryTextOf(context).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  provider.selectedTab == 0
                      ? 'Tuyệt vời! Không có đơn nào đang chờ xử lý'
                      : 'Chưa có đơn hàng trong lịch sử',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  provider.selectedTab == 0
                      ? 'Khi khách hàng đặt đơn trên FoodRoute, đơn sẽ xuất hiện tại đây ngay lập tức.'
                      : 'Các đơn đã hoàn thành hoặc đã hủy sẽ được lưu trữ tại đây.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: TColor.secondaryTextOf(context),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (ctx, i) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 130,
        decoration: BoxDecoration(
          color: TColor.cardOf(context).withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TColor.borderOf(context)),
        ),
      ),
    );
  }
}
