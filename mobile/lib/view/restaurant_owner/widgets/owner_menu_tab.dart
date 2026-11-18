import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../widgets/custom_toast.dart';
import '../../../services/restaurant_owner_service.dart';
import '../../../common/locator.dart';
import '../../../widgets/skeleton/food_item_skeleton.dart';
import '../../menu/item_details_view.dart';
import 'food_form_sheet.dart';
import 'restaurant_format_utils.dart';

class OwnerMenuTab extends StatefulWidget {
  final List<dynamic> menu;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onRefresh;
  final bool isLoading;

  const OwnerMenuTab({
    super.key,
    required this.menu,
    required this.categories,
    required this.onRefresh,
    this.isLoading = false,
  });

  @override
  State<OwnerMenuTab> createState() => _OwnerMenuTabState();
}

class _OwnerMenuTabState extends State<OwnerMenuTab> {
  final RestaurantOwnerService _service = locator<RestaurantOwnerService>();
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // 'ALL', 'DANG_BAN', 'HET_HANG', 'TAM_NGUNG', 'THUNG_RAC'

  void _openAddFoodSheet() {
    FoodFormSheet.show(
      context,
      categories: widget.categories,
      onSave: (payload) async {
        final success = await _service.createFoodItem(payload);
        if (success) {
          if (mounted) CustomToast.showSuccess(context, 'Thêm món ăn mới thành công');
          widget.onRefresh();
        } else {
          if (mounted) CustomToast.showError(context, 'Không thể tạo món ăn');
        }
      },
    );
  }

  void _openEditFoodSheet(Map<String, dynamic> food) {
    final foodId = food['maMonAn'] is int
        ? food['maMonAn'] as int
        : int.tryParse((food['maMonAn'] ?? food['id']).toString()) ?? 0;

    FoodFormSheet.show(
      context,
      initialData: food,
      categories: widget.categories,
      onSave: (payload) async {
        final success = await _service.updateFoodItem(foodId, payload);
        if (success) {
          if (mounted) CustomToast.showSuccess(context, 'Cập nhật món ăn thành công');
          widget.onRefresh();
        } else {
          if (mounted) CustomToast.showError(context, 'Không thể cập nhật món ăn');
        }
      },
    );
  }

  void _openDishReviews(Map<String, dynamic> food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ItemDetailsView(itemObj: food),
      ),
    ).then((_) => widget.onRefresh());
  }

  void _confirmDeleteFood(Map<String, dynamic> food) {
    final foodId = food['maMonAn'] is int
        ? food['maMonAn'] as int
        : int.tryParse((food['maMonAn'] ?? food['id']).toString()) ?? 0;
    final foodName = (food['tenMonAn'] ?? 'món ăn này').toString();
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
              Text(
                'Xóa món ăn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TColor.primaryTextOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn có chắc chắn muốn xóa món "$foodName" khỏi thực đơn không?\nMón ăn sẽ được chuyển vào mục "Thùng rác" và bạn có thể khôi phục lại bất kỳ lúc nào.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: TColor.secondaryTextOf(context),
                ),
              ),
              const SizedBox(height: 20),
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
                        'Hủy',
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
                        final success = await _service.deleteFoodItem(foodId);
                        if (success) {
                          if (mounted) {
                            setState(() {
                              food['trangThaiMon'] = 'DA_XOA';
                            });
                            CustomToast.showSuccess(context, 'Đã chuyển món vào thùng rác');
                          }
                          widget.onRefresh();
                        } else {
                          if (mounted) CustomToast.showError(context, 'Không thể xóa món ăn');
                        }
                      },
                      child: const Text(
                        'Xóa món',
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

  void _confirmRestoreFood(Map<String, dynamic> food) {
    final foodId = food['maMonAn'] is int
        ? food['maMonAn'] as int
        : int.tryParse((food['maMonAn'] ?? food['id']).toString()) ?? 0;
    final foodName = (food['tenMonAn'] ?? 'món ăn này').toString();
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(
                  Icons.restore_rounded,
                  size: 28,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Khôi phục món ăn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TColor.primaryTextOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn có muốn khôi phục món "$foodName" về danh sách thực đơn đang bán không?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: TColor.secondaryTextOf(context),
                ),
              ),
              const SizedBox(height: 20),
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
                        'Hủy',
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
                        backgroundColor: const Color(0xFFFC6011),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await _service.restoreFoodItem(foodId);
                        if (success) {
                          if (mounted) {
                            setState(() {
                              food['trangThaiMon'] = 'DANG_BAN';
                            });
                            CustomToast.showSuccess(context, 'Đã khôi phục món "$foodName" về thực đơn');
                          }
                          widget.onRefresh();
                        } else {
                          if (mounted) CustomToast.showError(context, 'Không thể khôi phục món ăn');
                        }
                      },
                      child: const Text(
                        'Khôi phục',
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

  Future<void> _quickToggleStatus(Map<String, dynamic> food, String newStatus) async {
    final foodId = food['maMonAn'] is int
        ? food['maMonAn'] as int
        : int.tryParse((food['maMonAn'] ?? food['id']).toString()) ?? 0;
    final success = await _service.updateFoodItem(foodId, {'trangThaiMon': newStatus});
    if (success) {
      if (mounted) {
        setState(() {
          food['trangThaiMon'] = newStatus;
        });
        CustomToast.showSuccess(context, 'Cập nhật trạng thái thành công');
      }
      widget.onRefresh();
    } else {
      if (mounted) CustomToast.showError(context, 'Không thể cập nhật trạng thái');
    }
  }

  Widget _buildFoodThumbnail(String imgUrl) {
    if (imgUrl.isEmpty) {
      return const Center(child: Icon(Icons.fastfood_rounded, color: Color(0xFFFC6011), size: 28));
    }
    if (imgUrl.startsWith('data:image')) {
      try {
        final base64Str = imgUrl.split(',').last;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded, color: Color(0xFFFC6011), size: 28),
        );
      } catch (_) {
        return const Icon(Icons.fastfood_rounded, color: Color(0xFFFC6011), size: 28);
      }
    }
    final formatted = SVKey.formatImageUrl(imgUrl);
    return Image.network(
      formatted,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Icon(Icons.fastfood_rounded, color: Color(0xFFFC6011), size: 28),
    );
  }

  Widget _buildFilterChip(String value, String label, {IconData? icon, Color? activeColor}) {
    final isSelected = _statusFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryActiveColor = activeColor ?? const Color(0xFFFC6011);

    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryActiveColor
              : (isDark ? const Color(0xFF28303D) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryActiveColor : TColor.borderOf(context),
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryActiveColor.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : TColor.secondaryTextOf(context),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : TColor.secondaryTextOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.menu.isEmpty) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(14, 14, 14, 24),
        child: FoodItemSkeletonList(itemCount: 6),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Counts
    int activeCount = 0;
    int dangBanCount = 0;
    int hetMonCount = 0;
    int tamNgungCount = 0;
    int trashCount = 0;

    for (final item in widget.menu) {
      final f = item is Map ? item : {};
      final rawStatus = (f['trangThaiMon'] ?? 'DANG_BAN').toString().toUpperCase();
      if (rawStatus == 'DA_XOA') {
        trashCount++;
      } else {
        activeCount++;
        if (rawStatus == 'DANG_BAN') dangBanCount++;
        if (rawStatus == 'HET_HANG' || rawStatus == 'HET_MON') hetMonCount++;
        if (rawStatus == 'TAM_NGUNG') tamNgungCount++;
      }
    }

    final filtered = widget.menu.where((item) {
      final food = item is Map<String, dynamic> ? item : Map<String, dynamic>.from(item as Map);
      final name = (food['tenMonAn'] ?? '').toString().toLowerCase();
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }
      final rawStatus = (food['trangThaiMon'] ?? 'DANG_BAN').toString().toUpperCase();

      if (_statusFilter == 'THUNG_RAC') {
        return rawStatus == 'DA_XOA';
      }

      // Hide soft-deleted items from normal tabs
      if (rawStatus == 'DA_XOA') return false;

      if (_statusFilter == 'DANG_BAN' && rawStatus != 'DANG_BAN') return false;
      if (_statusFilter == 'HET_HANG' && rawStatus != 'HET_HANG' && rawStatus != 'HET_MON') return false;
      if (_statusFilter == 'TAM_NGUNG' && rawStatus != 'TAM_NGUNG') return false;
      return true;
    }).toList();

    return Column(
      children: [
        // Top Toolbar: Search & Add button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: TColor.cardOf(context),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF28303D) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: TColor.borderOf(context), width: 0.8),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên món ăn...',
                          hintStyle: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: TColor.secondaryTextOf(context)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: TextStyle(fontSize: 13, color: TColor.primaryTextOf(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6011),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: _openAddFoodSheet,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm Món', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'Tất cả ($activeCount)'),
                    const SizedBox(width: 6),
                    _buildFilterChip('DANG_BAN', 'Đang bán ($dangBanCount)'),
                    const SizedBox(width: 6),
                    _buildFilterChip('HET_HANG', 'Hết món ($hetMonCount)'),
                    const SizedBox(width: 6),
                    _buildFilterChip('TAM_NGUNG', 'Tạm ngưng ($tamNgungCount)'),
                    const SizedBox(width: 6),
                    _buildFilterChip(
                      'THUNG_RAC',
                      'Thùng rác ($trashCount)',
                      icon: Icons.delete_outline_rounded,
                      activeColor: const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List View of Dishes
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            color: const Color(0xFFFC6011),
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              _statusFilter == 'THUNG_RAC'
                                  ? Icons.delete_sweep_rounded
                                  : Icons.restaurant_menu_rounded,
                              size: 56,
                              color: TColor.secondaryTextOf(context).withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _statusFilter == 'THUNG_RAC'
                                  ? 'Thùng rác đang trống'
                                  : (widget.menu.isEmpty
                                      ? 'Quán chưa có món ăn nào'
                                      : 'Không tìm thấy món ăn phù hợp'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: TColor.secondaryTextOf(context),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _statusFilter == 'THUNG_RAC'
                                  ? 'Các món bị xóa sẽ nằm ở đây và có thể khôi phục lại'
                                  : (widget.menu.isEmpty
                                      ? 'Bấm nút "Thêm Món" phía trên để tạo món đầu tiên'
                                      : 'Thử đổi từ khóa hoặc bộ lọc trạng thái'),
                              style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final rawFood = filtered[index];
                      final food = rawFood is Map<String, dynamic> ? rawFood : Map<String, dynamic>.from(rawFood as Map);

                      final name = (food['tenMonAn'] ?? 'Món ăn').toString();
                      final price = RestaurantFormatUtils.formatVND(food['giaMonAn'] ?? food['gia']);
                      final img = (food['img'] ?? food['image'] ?? '').toString();
                      final qty = int.tryParse((food['soLuongMon'] ?? food['quantity'] ?? 0).toString()) ?? 0;
                      final rawStatus = (food['trangThaiMon'] ?? 'DANG_BAN').toString().toUpperCase();

                      final bool isDeleted = rawStatus == 'DA_XOA';
                      final bool isOutOfStock = qty <= 0 || rawStatus == 'HET_HANG' || rawStatus == 'HET_MON';
                      final bool isPaused = rawStatus == 'TAM_NGUNG';

                      final rawRate = food['danhGiaTrungBinh'] ?? food['diemDanhGiaTB'] ?? food['rating'] ?? food['rate'];
                      final double rating = double.tryParse((rawRate ?? 0).toString()) ?? 0.0;
                      final rawCount = food['soLuotDanhGia'] ?? food['soLuongDanhGia'] ?? food['ratingCount'];
                      final int reviewCount = int.tryParse((rawCount ?? 0).toString()) ?? 0;

                      Color statusColor = const Color(0xFF10B981);
                      String statusLabel = 'Còn Hàng';
                      if (isDeleted) {
                        statusColor = const Color(0xFFEF4444);
                        statusLabel = 'Đã Xóa';
                      } else if (isPaused) {
                        statusColor = const Color(0xFFF59E0B);
                        statusLabel = 'Tạm Ngưng';
                      } else if (isOutOfStock) {
                        statusColor = const Color(0xFFEF4444);
                        statusLabel = 'Hết Món';
                      }

                      final catName = food['danhMuc'] is Map ? (food['danhMuc']['tenDanhMuc'] ?? '') : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: TColor.cardOf(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDeleted ? const Color(0xFFFECACA) : TColor.borderOf(context),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                if (isDeleted) {
                                  _confirmRestoreFood(food);
                                } else {
                                  _openEditFoodSheet(food);
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 68,
                                      height: 68,
                                      color: isDark ? const Color(0xFF28303D) : const Color(0xFFF1F5F9),
                                      child: _buildFoodThumbnail(img),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Food Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                            color: TColor.primaryTextOf(context),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              price,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                color: Color(0xFFFC6011),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '• $qty phần',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isOutOfStock ? const Color(0xFFEF4444) : TColor.secondaryTextOf(context),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Rating badge row
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                                            const SizedBox(width: 3),
                                            Text(
                                              rating > 0 ? rating.toStringAsFixed(1) : 'Chưa có',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: rating > 0 ? const Color(0xFFF59E0B) : TColor.secondaryTextOf(context),
                                              ),
                                            ),
                                            if (reviewCount > 0) ...[
                                              const SizedBox(width: 4),
                                              Text(
                                                '($reviewCount đánh giá)',
                                                style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context)),
                                              ),
                                            ],
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () => _openDishReviews(food),
                                              child: Text(
                                                '• Phản hồi ›',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: TColor.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (catName.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: TColor.primary.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              catName,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: TColor.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor.withOpacity(0.3), width: 0.8),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),
                            Divider(height: 1, color: TColor.borderOf(context).withOpacity(0.6)),
                            const SizedBox(height: 6),

                            // Action Bar
                            if (isDeleted)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Món ăn đang trong thùng rác',
                                        style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context)),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFC6011),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    onPressed: () => _confirmRestoreFood(food),
                                    icon: const Icon(Icons.restore_rounded, size: 15),
                                    label: const Text('Khôi phục món', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Quick Status Menu (Modernized Theme)
                                  PopupMenuButton<String>(
                                    tooltip: 'Chuyển trạng thái nhanh',
                                    padding: EdgeInsets.zero,
                                    color: isDark ? const Color(0xFF1E2430) : Colors.white,
                                    surfaceTintColor: Colors.transparent,
                                    elevation: 4,
                                    shadowColor: Colors.black.withOpacity(0.12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                        width: 1,
                                      ),
                                    ),
                                    onSelected: (val) => _quickToggleStatus(food, val),
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'DANG_BAN',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                                            SizedBox(width: 8),
                                            Text('Còn hàng / Đang bán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'HET_HANG',
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel_rounded, size: 16, color: Color(0xFFEF4444)),
                                            SizedBox(width: 8),
                                            Text('Hết món', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'TAM_NGUNG',
                                        child: Row(
                                          children: [
                                            Icon(Icons.pause_circle_rounded, size: 16, color: Color(0xFFF59E0B)),
                                            SizedBox(width: 8),
                                            Text('Tạm ngưng phục vụ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF28303D) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.swap_vert_rounded, size: 14, color: TColor.secondaryTextOf(context)),
                                          const SizedBox(width: 4),
                                          Text('Đổi trạng thái', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TColor.secondaryTextOf(context))),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Row(
                                    children: [
                                      // Reviews & Reply Button
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () => _openDishReviews(food),
                                        icon: const Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                                        label: Text(
                                          'Đánh giá ($reviewCount)',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      // Edit Button
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () => _openEditFoodSheet(food),
                                        icon: const Icon(Icons.edit_rounded, size: 15, color: Color(0xFF0284C7)),
                                        label: const Text('Sửa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                                      ),
                                      const SizedBox(width: 6),

                                      // Delete Button
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () => _confirmDeleteFood(food),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Colors.redAccent),
                                        label: const Text('Xóa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
