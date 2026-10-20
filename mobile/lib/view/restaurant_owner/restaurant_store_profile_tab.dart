import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/locator.dart';
import '../../common/user_role_helper.dart';
import '../../services/restaurant_owner_service.dart';
import '../../services/socket_service.dart';
import '../../services/upload_service.dart';
import '../../widgets/custom_toast.dart';
import 'widgets/restaurant_format_utils.dart';
import 'widgets/store_basic_info_card.dart';
import 'widgets/store_profile_edit_sheet.dart';
import 'widgets/store_vietqr_card.dart';

class RestaurantStoreProfileTab extends StatefulWidget {
  final Map<String, dynamic> storeProfile;
  final VoidCallback onProfileUpdated;

  const RestaurantStoreProfileTab({
    super.key,
    required this.storeProfile,
    required this.onProfileUpdated,
  });

  @override
  State<RestaurantStoreProfileTab> createState() => _RestaurantStoreProfileTabState();
}

class _RestaurantStoreProfileTabState extends State<RestaurantStoreProfileTab> {
  final RestaurantOwnerService _service = locator<RestaurantOwnerService>();
  final SocketService _socketService = locator<SocketService>();
  void Function(dynamic)? _profileUpdatedCallback;

  @override
  void initState() {
    super.initState();
    _profileUpdatedCallback = (data) {
      debugPrint('⚡ [RestaurantStoreProfileTab] Realtime profile updated received');
      if (mounted) {
        widget.onProfileUpdated();
      }
    };
    _socketService.listenToStoreProfileUpdates(_profileUpdatedCallback!);
  }

  @override
  void dispose() {
    if (_profileUpdatedCallback != null) {
      _socketService.offStoreProfileUpdates(_profileUpdatedCallback);
    }
    super.dispose();
  }

  Future<void> _saveStoreProfile(Map<String, dynamic> updateData) async {
    final success = await _service.updateProfile(updateData);

    if (mounted) {
      if (success) {
        CustomToast.showSuccess(context, 'Đã cập nhật hồ sơ quán thành công!');
        widget.onProfileUpdated();
      } else {
        CustomToast.showError(context, 'Không thể cập nhật hồ sơ quán');
      }
    }
  }

  Future<void> _pickStoreAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        if (mounted) {
          CustomToast.showSuccess(context, 'Đang tải ảnh quán lên...');
        }
        final uploadedUrl = await UploadService.uploadImageBase64(base64Image);
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          await _saveStoreProfile({'img': uploadedUrl});
        } else {
          if (mounted) CustomToast.showError(context, 'Không thể tải ảnh lên máy chủ');
        }
      }
    } catch (e) {
      if (mounted) CustomToast.showError(context, 'Không thể chọn ảnh: $e');
    }
  }

  Widget _buildStoreAvatar(String imgUrl) {
    if (imgUrl.isEmpty) {
      return Icon(Icons.storefront_rounded, color: TColor.primary, size: 36);
    }
    if (imgUrl.startsWith('data:image')) {
      try {
        final base64Str = imgUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.storefront_rounded, color: TColor.primary, size: 36),
        );
      } catch (_) {
        return Icon(Icons.storefront_rounded, color: TColor.primary, size: 36);
      }
    }
    String fullUrl = imgUrl;
    if (!imgUrl.startsWith('http')) {
      fullUrl = '${SVKey.mainUrl}${imgUrl.startsWith('/') ? '' : '/'}$imgUrl';
    }
    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(Icons.storefront_rounded, color: TColor.primary, size: 36),
    );
  }

  void _showEditProfileModal(BuildContext context) {
    StoreProfileEditSheet.show(
      context,
      storeProfile: widget.storeProfile,
      onSave: _saveStoreProfile,
    );
  }

  void _showOperatingHoursDialog(BuildContext context, dynamic rawHours) {
    final weekly = RestaurantFormatUtils.parseWeeklyOperatingHours(rawHours);
    final todayHours = RestaurantFormatUtils.formatOperatingHours(rawHours);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        title: const Row(
          children: [
            Icon(Icons.schedule_rounded, color: Color(0xFFFC6011), size: 22),
            SizedBox(width: 8),
            Text(
              'Lịch Hoạt Động Quán',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hôm nay: $todayHours',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                    ),
                  ),
                ],
              ),
            ),
            if (weekly.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('07:00 – 22:00 (Mỗi ngày)', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              )
            else
              ...weekly.map((item) {
                final isOpen = item['isOpen'] == 'true';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['day'] ?? '',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOpen ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isOpen ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Text(
                          item['time'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOpen ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 12),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFC6011),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showEditProfileModal(context);
            },
            child: const Text('Sửa hồ sơ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = widget.storeProfile;
    final name = p['tenQuan'] ?? UserRoleHelper.userName;
    final address = p['diaChi'] ?? 'Chưa cập nhật địa chỉ';
    final phone = p['sdt'] ?? '';
    final desc = p['moTa'] ?? 'Chuyên cung cấp món ngon chất lượng';
    final category = p['danhMuc'] ?? 'Ăn vặt';
    final prepTime = p['thoiGianChuanBi'] ?? 20;
    final ownerName = p['hoTenChuQuan'] ?? 'Chưa cập nhật';
    final bankName = p['tenNganHang'] ?? 'VietinBank (ICB)';
    final bankAcc = p['soTaiKhoanNganHang'] ?? '';
    final bankHolder = p['tenChuTaiKhoan'] ?? '';
    final imgUrl = p['img'] ?? p['avatar'] ?? '';
    final ratingVal = p['danhGia'] ?? p['rating'] ?? p['danhGiaTrungBinh'];
    final double rating = (ratingVal is num)
        ? ratingVal.toDouble()
        : (double.tryParse(ratingVal?.toString() ?? '') ?? 0.0);

    final ordersVal = p['tongDonHang'] ?? p['totalOrders'];
    final int totalOrders = (ordersVal is num)
        ? ordersVal.toInt()
        : (int.tryParse(ordersVal?.toString() ?? '') ?? 0);

    final String ordersText = totalOrders >= 1000
        ? '${(totalOrders / 1000).toStringAsFixed(1)}k đơn hàng'
        : '$totalOrders đơn hàng';

    final rawOperatingHours = p['gioHoatDong'];
    final operatingHours = RestaurantFormatUtils.formatOperatingHours(rawOperatingHours);

    // Parse categories into chips
    final categoryList = category.toString().split(RegExp(r'[,;]')).map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
    if (categoryList.isEmpty) categoryList.add('Ăn vặt');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        children: [
          // ── TOP HEADER CARD: Tên quán, Rating, Hotline & Sửa hồ sơ ─────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TColor.cardOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TColor.borderOf(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store Avatar with Camera Badge
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFC6011).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TColor.borderOf(context)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildStoreAvatar(imgUrl),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: InkWell(
                            onTap: _pickStoreAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFC6011),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // Title, rating and phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: TColor.primaryTextOf(context),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 3),
                              Text(
                                rating > 0 ? rating.toStringAsFixed(1) : 'Chưa có đánh giá',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '• $ordersText',
                                style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.phone_outlined, size: 14, color: Color(0xFFEF4444)),
                              const SizedBox(width: 4),
                              Text(
                                phone.isNotEmpty ? phone : 'Chưa có hotline',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bottom row: Trạng thái nhận đơn + Nút Sửa hồ sơ
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Trạng thái nhận đơn: ',
                          style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Text(
                            'Tự động nhận',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFC6011),
                        side: const BorderSide(color: Color(0xFFFC6011)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => _showEditProfileModal(context),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Sửa hồ sơ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── CARD 1: THÔNG TIN CƠ BẢN ───────────────────────────────────────
          StoreBasicInfoCard(
            address: address,
            desc: desc,
            categoryList: categoryList,
            prepTime: prepTime,
            onEdit: () => _showEditProfileModal(context),
          ),
          const SizedBox(height: 14),

          // ── CARD 2: TÀI KHOẢN NHẬN TIỀN & VIETQR PRO CARD ─────────────────
          StoreVietQRCard(
            bankName: bankName,
            bankAcc: bankAcc,
            bankHolder: bankHolder,
            ownerName: ownerName,
            onUpdateBank: (newBank) => _saveStoreProfile({'tenNganHang': newBank}),
          ),
          const SizedBox(height: 14),

          // ── CARD 3: TIỆN ÍCH MÁY IN & GIỜ HOẠT ĐỘNG ────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TColor.cardOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TColor.borderOf(context)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.print_outlined, color: Color(0xFF475569), size: 18),
                    ),
                    title: Text(
                      'Cài đặt máy in hoá đơn (LAN / Bluetooth)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TColor.primaryTextOf(context)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                    onTap: () {
                      CustomToast.showSuccess(context, 'Hệ thống đã sẵn sàng kết nối máy in nhiệt');
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.access_time_rounded, color: Color(0xFFEA580C), size: 18),
                    ),
                    title: const Text(
                      'Thời gian mở cửa quán',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Hôm nay: $operatingHours',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFFC6011), fontWeight: FontWeight.w600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem tuần',
                          style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                      ],
                    ),
                    onTap: () => _showOperatingHoursDialog(context, rawOperatingHours),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
