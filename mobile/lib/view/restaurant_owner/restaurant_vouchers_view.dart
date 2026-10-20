import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../widgets/custom_toast.dart';
import '../../providers/restaurant_vouchers_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _provider = RestaurantVouchersProvider()..init(widget.maQuan);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, int voucherId, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa voucher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Bạn có chắc chắn muốn xóa voucher "$code" không? Nếu voucher đã có lượt dùng, hệ thống sẽ tự động chuyển sang tạm dừng để bảo vệ lịch sử dữ liệu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<RestaurantVouchersProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: TColor.bgOf(context),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFC6011),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tạo Voucher', style: TextStyle(fontWeight: FontWeight.bold)),
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
                // Top Search and Statistics
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      // Search field
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
                            hintText: 'Tìm theo mã hoặc tên voucher...',
                            hintStyle: TextStyle(fontSize: 13, color: TColor.placeholder),
                            prefixIcon: Icon(Icons.search, size: 20, color: TColor.secondaryTextOf(context)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Status filters
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip(context, 'Tất cả', 'ALL', provider),
                            _buildFilterChip(context, 'Đang bật', 'HOAT_DONG', provider),
                            _buildFilterChip(context, 'Tạm dừng', 'TAM_TAT', provider),
                            _buildFilterChip(context, 'Hết hạn/lượt', 'HET_HAN', provider),
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildFilterChip(BuildContext context, String label, String value, RestaurantVouchersProvider provider) {
    final isSelected = provider.statusFilter == value;
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
        onSelected: (_) => provider.setStatusFilter(value),
      ),
    );
  }

  Widget _buildList(BuildContext context, RestaurantVouchersProvider provider) {
    if (provider.isLoading && provider.vouchers.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (ctx, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 120,
          decoration: BoxDecoration(
            color: TColor.cardOf(context).withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TColor.borderOf(context)),
          ),
        ),
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
                  color: TColor.secondaryTextOf(context).withOpacity(0.5),
                ),
                const SizedBox(height: 16),
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
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
