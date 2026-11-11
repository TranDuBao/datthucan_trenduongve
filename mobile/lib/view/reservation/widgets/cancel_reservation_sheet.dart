import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../common/color_extension.dart';
import '../../../common_widget/custom_modal_alert.dart';
import '../../../widgets/custom_toast.dart';
import '../../../models/reservation_model.dart';
import '../../../providers/reservation_provider.dart';

class CancelReservationSheet extends StatefulWidget {
  final ReservationModel reservation;

  const CancelReservationSheet({
    super.key,
    required this.reservation,
  });

  static Future<bool?> show({
    required BuildContext context,
    required ReservationModel reservation,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CancelReservationSheet(reservation: reservation),
    );
  }

  @override
  State<CancelReservationSheet> createState() => _CancelReservationSheetState();
}

class _CancelReservationSheetState extends State<CancelReservationSheet> {
  final TextEditingController _txtReason = TextEditingController();
  String? _selectedQuickReason;
  bool _isLoading = false;

  final List<String> _quickReasons = const [
    'Bận việc đột xuất',
    'Thay đổi kế hoạch',
    'Đặt nhầm ngày/giờ',
    'Lý do khác',
  ];

  @override
  void dispose() {
    _txtReason.dispose();
    super.dispose();
  }

  String get _finalReason {
    final note = _txtReason.text.trim();
    if (_selectedQuickReason != null && note.isNotEmpty) {
      return '$_selectedQuickReason: $note';
    }
    if (_selectedQuickReason != null) {
      return _selectedQuickReason!;
    }
    return note.isNotEmpty ? note : 'Khách hàng tự hủy';
  }

  Future<void> _handleConfirmCancel() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final provider = context.read<ReservationProvider>();
    final resv = widget.reservation;
    final storeName = resv.cuaHang?.tenQuan ?? 'Quán ăn';

    final res = await provider.cancelReservation(
      resv.maDatBan,
      reason: _finalReason,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      // Pop the bottom sheet first
      Navigator.of(context).pop(true);

      // Show modern success modal alert
      await CustomModalAlert.show(
        context: context,
        title: 'Hủy đặt bàn thành công',
        message: 'Lịch hẹn #DB${resv.maDatBan} tại $storeName đã được hủy hoàn tất. Quán ăn đã nhận được thông báo cập nhật.',
        buttonTitle: 'Đã hiểu',
        isError: false,
      );
    } else {
      CustomToast.showError(
        context,
        res['message'] ?? 'Không thể hủy đặt bàn. Vui lòng thử lại!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resv = widget.reservation;
    final storeName = resv.cuaHang?.tenQuan ?? 'Quán ăn';
    final timeStr = DateFormat('HH:mm • dd/MM/yyyy').format(resv.thoiGianBatDau.toLocal());
    final tableName = resv.ban?.tenBan ?? 'Quán tự xếp bàn';

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row: Icon + Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: Color(0xFFE53935),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hủy lượt đặt bàn?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: TColor.primaryTextOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bạn có chắc chắn muốn hủy lịch hẹn tại $storeName?',
                        style: TextStyle(
                          fontSize: 13,
                          color: TColor.secondaryTextOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2E3547) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: TColor.secondaryTextOf(context),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Reservation Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2330) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF2E3547) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: TColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#DB${resv.maDatBan}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TColor.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TColor.primaryTextOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded, size: 14, color: TColor.primary),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TColor.primaryTextOf(context),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.people_alt_rounded, size: 14, color: TColor.secondaryTextOf(context)),
                      const SizedBox(width: 4),
                      Text(
                        '${resv.soNguoi} khách ($tableName)',
                        style: TextStyle(
                          fontSize: 12,
                          color: TColor.secondaryTextOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Quick Reasons Selector
            Text(
              'Chọn lý do hủy:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: TColor.primaryTextOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReasons.map((reason) {
                final isSelected = _selectedQuickReason == reason;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedQuickReason = isSelected ? null : reason;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE53935).withValues(alpha: 0.1)
                          : isDark
                              ? const Color(0xFF1E2330)
                              : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : isDark
                                ? const Color(0xFF2E3547)
                                : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFE53935)
                            : TColor.primaryTextOf(context),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Note TextField
            TextField(
              controller: _txtReason,
              maxLines: 2,
              style: TextStyle(fontSize: 13, color: TColor.primaryTextOf(context)),
              decoration: InputDecoration(
                hintText: 'Nhập thêm ghi chú lý do (không bắt buộc)...',
                hintStyle: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E2330) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2E3547) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF2E3547) : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE53935)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),

            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF2E3547) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'Giữ lại lịch',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TColor.primaryTextOf(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleConfirmCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Xác nhận hủy',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
