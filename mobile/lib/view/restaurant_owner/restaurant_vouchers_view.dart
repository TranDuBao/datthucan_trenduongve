import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../widgets/custom_toast.dart';
import '../../providers/restaurant_vouchers_provider.dart';
import '../../widgets/skeleton/voucher_skeleton.dart';
import 'widgets/voucher_card_widget.dart';
import 'widgets/voucher_form_sheet.dart';

class RestaurantVouchersView extends StatefulWidget {
  final int? maQuan;
  const RestaurantVouchersView({super.key, this.maQuan});

  @override
  State<RestaurantVouchersView> createState() => _RestaurantVouchersViewState();
}

class _RestaurantVouchersViewState extends State<RestaurantVouchersView> {
  late RestaurantVouchersProvider _provider;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = RestaurantVouchersProvider()..init(widget.maQuan);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, int voucherId, String code) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: TColor.cardOf(context),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  size: 28,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'Xác nhận xóa voucher',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TColor.primaryTextOf(context),
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Bạn có chắc chắn muốn xóa voucher "$code" không?\nNếu voucher đã có khách áp dụng, hệ thống sẽ tự động chuyển sang tạm dừng để bảo vệ lịch sử dữ liệu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: TColor.secondaryTextOf(context),
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Hủy bỏ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: TColor.primaryTextOf(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await _provider.deleteVoucher(voucherId);
                        if (!mounted || !context.mounted) return;
                        if (success) {
                          CustomToast.showSuccess(context, 'Đã xóa / tạm dừng voucher thành công');
                        } else {
                          CustomToast.showError(context, 'Không thể xóa voucher');
                        }
                      },
                      child: const Text(
                        'Xóa voucher',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSummarySheet(BuildContext context, RestaurantVouchersProvider provider) {
    final vouchers = provider.vouchers;
    final total = vouchers.length;
    final active = vouchers.where((v) => (v['computedStatus'] ?? v['trangThai']) == 'HOAT_DONG').length;
    final paused = vouchers.where((v) => (v['computedStatus'] ?? v['trangThai']) == 'TAM_TAT').length;
    final expired = vouchers.where((v) {
      final s = v['computedStatus'] ?? v['trangThai'];
      return s == 'HET_HAN' || s == 'HET_LUOT';
    }).length;
    final totalUsed = vouchers.fold<int>(0, (sum, v) => sum + ((v['soLuongDaSuDung'] as num?)?.toInt() ?? 0));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TColor.cardOf(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thống kê khuyến mãi (Đã dùng $totalUsed lượt)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TColor.primaryTextOf(context),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildStatBox(context, 'Tổng cộng', total.toString(), const Color(0xFFFC6011)),
                const SizedBox(width: 6),
                _buildStatBox(context, 'Đang chạy', active.toString(), const Color(0xFF059669)),
                const SizedBox(width: 6),
                _buildStatBox(context, 'Tạm dừng', paused.toString(), const Color(0xFF64748B)),
                const SizedBox(width: 6),
                _buildStatBox(context, 'Hết hạn', expired.toString(), const Color(0xFFDC2626)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: TColor.secondaryTextOf(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<RestaurantVouchersProvider>(
        builder: (context, provider, _) {
          final vouchers = provider.vouchers;
          final totalCount = vouchers.length;
          final activeCount = vouchers.where((v) => (v['computedStatus'] ?? v['trangThai']) == 'HOAT_DONG').length;
          final pausedCount = vouchers.where((v) => (v['computedStatus'] ?? v['trangThai']) == 'TAM_TAT').length;
          final expiredCount = vouchers.where((v) {
            final s = v['computedStatus'] ?? v['trangThai'];
            return s == 'HET_HAN' || s == 'HET_LUOT';
          }).length;
          final totalUsed = vouchers.fold<int>(0, (sum, v) => sum + ((v['soLuongDaSuDung'] as num?)?.toInt() ?? 0));

          return Scaffold(
            backgroundColor: TColor.bgOf(context),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFC6011),
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo Voucher', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              onPressed: () {
                VoucherFormSheet.show(
                  context,
                  onSave: (input) async {
                    final ok = await provider.saveVoucher(input);
                    if (context.mounted) {
                      if (ok) {
                        CustomToast.showSuccess(context, 'Đã tạo voucher mới thành công');
                      } else {
                        CustomToast.showError(context, 'Không thể tạo voucher');
                      }
                    }
                  },
                );
              },
            ),
            body: Column(
              children: [
                // Top Search and Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Column(
                    children: [
                      // Search field
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: TColor.cardOf(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: provider.setSearchQuery,
                          style: TextStyle(fontSize: 13, color: TColor.primaryTextOf(context)),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo mã hoặc tên voucher...',
                            hintStyle: TextStyle(fontSize: 13, color: TColor.placeholder),
                            prefixIcon: Icon(Icons.search_rounded, size: 20, color: TColor.secondaryTextOf(context)),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      provider.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterPill(
                              context,
                              label: 'Tất cả',
                              count: totalCount,
                              value: 'ALL',
                              provider: provider,
                            ),
                            _buildFilterPill(
                              context,
                              label: 'Đang bật',
                              count: activeCount,
                              dotColor: const Color(0xFF10B981),
                              value: 'HOAT_DONG',
                              provider: provider,
                            ),
                            _buildFilterPill(
                              context,
                              label: 'Tạm dừng',
                              count: pausedCount,
                              dotColor: const Color(0xFFF59E0B),
                              value: 'TAM_TAT',
                              provider: provider,
                            ),
                            _buildFilterPill(
                              context,
                              label: 'Hết hạn/lượt',
                              count: expiredCount,
                              dotColor: const Color(0xFF94A3B8),
                              value: 'HET_HAN',
                              provider: provider,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Promotional summary banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A1C14) : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFED7AA),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC6011),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.confirmation_number_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chương trình khuyến mãi tháng này',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: TColor.primaryTextOf(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                totalUsed > 0
                                    ? 'Đã phân phối $totalUsed lượt ưu đãi cho khách quen'
                                    : 'Đang có $activeCount chương trình khuyến mãi hoạt động',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: TColor.secondaryTextOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => _showSummarySheet(context, provider),
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Báo cáo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFC6011),
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: Color(0xFFFC6011),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Vouchers list
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFFC6011),
                    onRefresh: provider.fetchVouchers,
                    child: _buildList(context, provider),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(
    BuildContext context, {
    required String label,
    required int count,
    Color? dotColor,
    required String value,
    required RestaurantVouchersProvider provider,
  }) {
    final isSelected = provider.statusFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => provider.setStatusFilter(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFC6011)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFC6011)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFC6011).withOpacity(0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ] else if (dotColor != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : TColor.primaryTextOf(context),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : TColor.secondaryTextOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, RestaurantVouchersProvider provider) {
    if (provider.isLoading && provider.vouchers.isEmpty) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: VoucherSkeletonList(itemCount: 4),
      );
    }

    final list = provider.filteredVouchers;

    if (list.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.confirmation_number_outlined,
                  size: 56,
                  color: TColor.secondaryTextOf(context).withOpacity(0.4),
                ),
                const SizedBox(height: 14),
                Text(
                  'Chưa có voucher nào',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bấm nút "Tạo Voucher" bên dưới để thêm chương trình khuyến mãi thu hút khách hàng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final v = list[i];
        final id = v['maVoucher'] ?? v['id'] ?? 0;
        final code = v['maCode'] ?? '';
        final currentStatus = v['trangThai'] ?? 'HOAT_DONG';
        return VoucherCardWidget(
          key: ValueKey('voucher_$id'),
          voucher: v,
          onToggle: (val) async {
            final ok = await provider.toggleVoucherStatus(id, currentStatus);
            if (ctx.mounted && !ok) {
              CustomToast.showError(ctx, 'Không thể cập nhật trạng thái voucher');
            }
          },
          onEdit: () {
            VoucherFormSheet.show(
              context,
              initialData: v,
              onSave: (input) async {
                final ok = await provider.saveVoucher(input, voucherId: id);
                if (ctx.mounted) {
                  if (ok) {
                    CustomToast.showSuccess(ctx, 'Đã cập nhật voucher thành công');
                  } else {
                    CustomToast.showError(ctx, 'Không thể cập nhật voucher');
                  }
                }
              },
            );
          },
          onDelete: () => _confirmDelete(context, id, code),
        );
      },
    );
  }
}
