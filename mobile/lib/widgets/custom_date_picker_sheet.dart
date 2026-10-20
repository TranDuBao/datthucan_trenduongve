import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class CustomDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  const CustomDatePickerSheet({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  static void show({
    required BuildContext context,
    required DateTime initialDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomDatePickerSheet(
        initialDate: initialDate,
        onDateSelected: onDateSelected,
      ),
    );
  }

  @override
  State<CustomDatePickerSheet> createState() => _CustomDatePickerSheetState();
}

class _CustomDatePickerSheetState extends State<CustomDatePickerSheet> {
  late DateTime _tempSelectedDate;

  final List<String> _weekdays = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật'
  ];

  @override
  void initState() {
    super.initState();
    _tempSelectedDate = widget.initialDate;
  }

  String _formatDatePreview(DateTime dt) {
    final weekdayStr = _weekdays[dt.weekday - 1];
    final dayStr = dt.day.toString().padLeft(2, '0');
    final monthStr = dt.month.toString().padLeft(2, '0');
    return "$weekdayStr, $dayStr Tháng $monthStr, ${dt.year}";
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    // Find next Sunday date for quick chip
    DateTime sunday = today;
    while (sunday.weekday != DateTime.sunday) {
      sunday = sunday.add(const Duration(days: 1));
    }

    final isTodaySelected = _isSameDate(_tempSelectedDate, today);
    final isTomorrowSelected = _isSameDate(_tempSelectedDate, tomorrow);
    final isSundaySelected = _isSameDate(_tempSelectedDate, sunday);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: TColor.bgOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Drag Indicator & Header Bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Hủy",
                  style: TextStyle(
                    color: isDark ? const Color(0xFFA0A5B5) : const Color(0xFF777777),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    "Chọn ngày hẹn",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Giờ mở cửa: 08:00 - 21:30",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  widget.onDateSelected(_tempSelectedDate);
                  Navigator.pop(context);
                },
                child: const Text(
                  "Xong",
                  style: TextStyle(
                    color: Color(0xFFFC6011),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Selected Date Box Preview (No restaurant name as requested)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1E28) : const Color(0xFFFFF4EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF2C3240) : const Color(0xFFFFE5D6),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6011),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDatePreview(_tempSelectedDate),
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFC6011), width: 1),
                  ),
                  child: const Text(
                    "Đã chọn",
                    style: TextStyle(
                      color: Color(0xFFFC6011),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cupertino Wheel Date Picker
          SizedBox(
            height: 180,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: isDark ? Brightness.dark : Brightness.light,
                textTheme: CupertinoTextThemeData(
                  dateTimePickerTextStyle: TextStyle(
                    color: TColor.primaryTextOf(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _tempSelectedDate,
                minimumDate: today,
                maximumDate: today.add(const Duration(days: 30)),
                onDateTimeChanged: (newDate) {
                  setState(() {
                    _tempSelectedDate = newDate;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Date Chips Row
          Row(
            children: [
              Expanded(
                child: _buildQuickChip(
                  label: "Hôm nay (${today.day}/${today.month})",
                  isSelected: isTodaySelected,
                  onTap: () => setState(() => _tempSelectedDate = today),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickChip(
                  label: "Ngày mai (${tomorrow.day}/${tomorrow.month})",
                  isSelected: isTomorrowSelected,
                  onTap: () => setState(() => _tempSelectedDate = tomorrow),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickChip(
                  label: "Chủ Nhật này",
                  isSelected: isSundaySelected,
                  onTap: () => setState(() => _tempSelectedDate = sunday),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bottom Buttons: Đóng & Xác nhận
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF2C3240)
                          : const Color(0xFFF5F5F7),
                      foregroundColor: TColor.primaryTextOf(context),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Đóng",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onDateSelected(_tempSelectedDate);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6011),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFFFC6011).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Xác nhận",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFC6011)
              : (isDark ? const Color(0xFF1B1E28) : const Color(0xFFF5F5F7)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFC6011)
                : (isDark ? const Color(0xFF2C3240) : const Color(0xFFE5E5EA)),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFC0C4D0) : const Color(0xFF333333)),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
