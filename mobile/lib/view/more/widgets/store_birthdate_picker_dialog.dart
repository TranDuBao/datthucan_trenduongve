import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';

class StoreBirthdatePickerDialog extends StatefulWidget {
  final DateTime? initialDate;

  const StoreBirthdatePickerDialog({super.key, this.initialDate});

  static Future<DateTime?> show(BuildContext context, {DateTime? initialDate}) {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StoreBirthdatePickerDialog(initialDate: initialDate),
    );
  }

  @override
  State<StoreBirthdatePickerDialog> createState() => _StoreBirthdatePickerDialogState();
}

class _StoreBirthdatePickerDialogState extends State<StoreBirthdatePickerDialog> {
  late DateTime _selectedDate;
  late int _displayMonth;
  late int _displayYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final defaultEligible = DateTime(now.year - 23, 1, 1);
    _selectedDate = widget.initialDate ?? defaultEligible;
    _displayMonth = _selectedDate.month;
    _displayYear = _selectedDate.year;
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  bool get _isEligible => _calculateAge(_selectedDate) >= 18;

  String _getDayOfWeekName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  void _prevMonth() {
    setState(() {
      if (_displayMonth == 1) {
        _displayMonth = 12;
        _displayYear--;
      } else {
        _displayMonth--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_displayMonth == 12) {
        _displayMonth = 1;
        _displayYear++;
      } else {
        _displayMonth++;
      }
    });
  }

  void _showMonthPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Chọn Tháng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, i) {
                    final m = i + 1;
                    final isSel = m == _displayMonth;
                    return InkWell(
                      onTap: () {
                        setState(() => _displayMonth = m);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel ? TColor.primary : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Tháng $m",
                          style: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF1E293B),
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showYearPickerSheet() {
    final now = DateTime.now();
    final maxYear = now.year - 18;
    final years = List.generate(maxYear - 1945 + 1, (i) => maxYear - i);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Chọn Năm Sinh", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: years.length,
                  itemBuilder: (context, idx) {
                    final y = years[idx];
                    final isSel = y == _displayYear;
                    return ListTile(
                      title: Text(
                        "Năm $y",
                        style: TextStyle(
                          color: isSel ? TColor.primary : null,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSel ? Icon(Icons.check, color: TColor.primary) : null,
                      onTap: () {
                        setState(() {
                          _displayYear = y;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final age = _calculateAge(_selectedDate);
    final isEligible = _isEligible;
    final dayStr = _selectedDate.day.toString().padLeft(2, '0');
    final monthStr = _selectedDate.month.toString().padLeft(2, '0');

    // Quick years list (e.g. around selected year and eligible age)
    final now = DateTime.now();
    final maxYear = now.year - 18;
    final quickYears = [
      maxYear - 5, // 2001
      maxYear - 6, // 2000
      maxYear - 7, // 1999
      maxYear - 8, // 1998
      maxYear - 9, // 1997
      maxYear - 10, // 1996
    ];
    if (!quickYears.contains(_displayYear)) {
      quickYears.insert(0, _displayYear);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E232E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Orange Gradient Header (Exact design from user mockup)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF5722), Color(0xFFE64A19)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.shield_rounded, color: Colors.white, size: 15),
                          SizedBox(width: 6),
                          Text(
                            "XÁC THỰC ĐỘ TUỔI ĐỐI TÁC",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Big Date + Eligibility Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "${_getDayOfWeekName(_selectedDate)}, $dayStr/$monthStr",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isEligible
                              ? const Color(0xFF2E7D32).withOpacity(0.55)
                              : Colors.red.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEligible ? Icons.check_rounded : Icons.close_rounded,
                              color: isEligible ? const Color(0xFF86EFAC) : Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isEligible ? "Đủ điều kiện (18+)" : "Chưa đủ 18 tuổi",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Năm ${_selectedDate.year} ($age tuổi)",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Body controls (Month/Year dropdowns + Quick years + Grid)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                children: [
                  // Month/Year pickers & Nav arrows
                  Row(
                    children: [
                      // Month pill
                      InkWell(
                        onTap: _showMonthPickerSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "Tháng $_displayMonth",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Year pill
                      InkWell(
                        onTap: _showYearPickerSheet,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Row(
                            children: [
                              Text(
                                "$_displayYear",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Prev / Next month buttons
                      InkWell(
                        onTap: _prevMonth,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF475569)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _nextMonth,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick year chips bar
                  Row(
                    children: [
                      const Text(
                        "Năm sinh: ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: quickYears.map((y) {
                              final isSel = y == _displayYear;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _displayYear = y;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSel ? TColor.primary : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "$y",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSel ? Colors.white : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Days of week header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDayOfWeekHeader("CN", isSunday: true),
                      _buildDayOfWeekHeader("T2"),
                      _buildDayOfWeekHeader("T3"),
                      _buildDayOfWeekHeader("T4"),
                      _buildDayOfWeekHeader("T5"),
                      _buildDayOfWeekHeader("T6"),
                      _buildDayOfWeekHeader("T7"),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Calendar Days Matrix
                  _buildCalendarMatrix(),
                  const SizedBox(height: 14),

                  // 3. Information Callout Note (Yellow box from user mockup)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEF3C7)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Chủ cửa hàng cần đủ 18 tuổi trở lên theo quy định pháp luật thương mại hiện hành.",
                            style: TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 11.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Action buttons (Hủy bỏ / Xác nhận)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Hủy bỏ",
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: isEligible
                                ? () {
                                    Navigator.pop(context, _selectedDate);
                                  }
                                : null,
                            icon: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            label: const Text(
                              "Xác nhận",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColor.primary,
                              disabledBackgroundColor: const Color(0xFFCBD5E1),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayOfWeekHeader(String text, {bool isSunday = false}) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isSunday ? const Color(0xFFEF4444) : const Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCalendarMatrix() {
    final firstDayOfMonth = DateTime(_displayYear, _displayMonth, 1);
    final daysInMonth = DateTime(_displayYear, _displayMonth + 1, 0).day;
    final prevMonthDays = DateTime(_displayYear, _displayMonth, 0).day;

    // weekday in dart: Monday=1 ... Sunday=7
    // Header order: CN(7), T2(1), T3(2), T4(3), T5(4), T6(5), T7(6)
    int leadingBlanks = firstDayOfMonth.weekday % 7; // Sunday=0, Monday=1, ...

    const totalCells = 42; // 6 rows * 7 columns
    final List<Widget> dayWidgets = [];

    // Leading days from previous month
    for (int i = leadingBlanks - 1; i >= 0; i--) {
      final day = prevMonthDays - i;
      dayWidgets.add(
        _buildDayCell(
          day: day,
          isCurrentMonth: false,
          isSunday: (leadingBlanks - 1 - i) % 7 == 0,
        ),
      );
    }

    // Days in current month
    for (int d = 1; d <= daysInMonth; d++) {
      final cellDate = DateTime(_displayYear, _displayMonth, d);
      final isSelected = cellDate.year == _selectedDate.year &&
          cellDate.month == _selectedDate.month &&
          cellDate.day == _selectedDate.day;
      final isSunday = cellDate.weekday == DateTime.sunday;

      dayWidgets.add(
        _buildDayCell(
          day: d,
          isCurrentMonth: true,
          isSelected: isSelected,
          isSunday: isSunday,
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
          },
        ),
      );
    }

    // Trailing days from next month
    int remaining = totalCells - dayWidgets.length;
    for (int d = 1; d <= remaining; d++) {
      final colIndex = (dayWidgets.length) % 7;
      dayWidgets.add(
        _buildDayCell(
          day: d,
          isCurrentMonth: false,
          isSunday: colIndex == 0,
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      mainAxisSpacing: 4,
      crossAxisSpacing: 2,
      childAspectRatio: 1.15,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell({
    required int day,
    required bool isCurrentMonth,
    bool isSelected = false,
    bool isSunday = false,
    VoidCallback? onTap,
  }) {
    Color textColor;
    if (!isCurrentMonth) {
      textColor = const Color(0xFFCBD5E1);
    } else if (isSelected) {
      textColor = Colors.white;
    } else if (isSunday) {
      textColor = const Color(0xFFEF4444);
    } else {
      textColor = const Color(0xFF1E293B);
    }

    return InkWell(
      onTap: isCurrentMonth ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? TColor.primary : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: TColor.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            "$day",
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : (isCurrentMonth ? FontWeight.w600 : FontWeight.normal),
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
