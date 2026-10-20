import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class CustomTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final DateTime selectedDate;
  final ValueChanged<TimeOfDay> onTimeSelected;

  const CustomTimePickerSheet({
    super.key,
    required this.initialTime,
    required this.selectedDate,
    required this.onTimeSelected,
  });

  static void show({
    required BuildContext context,
    required TimeOfDay initialTime,
    required DateTime selectedDate,
    required ValueChanged<TimeOfDay> onTimeSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomTimePickerSheet(
        initialTime: initialTime,
        selectedDate: selectedDate,
        onTimeSelected: onTimeSelected,
      ),
    );
  }

  @override
  State<CustomTimePickerSheet> createState() => _CustomTimePickerSheetState();
}

class _CustomTimePickerSheetState extends State<CustomTimePickerSheet> {
  late TimeOfDay _tempTime;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _tempTime = widget.initialTime;
    _hourController = FixedExtentScrollController(initialItem: _tempTime.hour);
    _minuteController = FixedExtentScrollController(initialItem: _tempTime.minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _updateTempTime(TimeOfDay newTime) {
    setState(() {
      _tempTime = newTime;
    });
    if (_hourController.hasClients && _hourController.selectedItem != newTime.hour) {
      _hourController.animateToItem(
        newTime.hour,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
    if (_minuteController.hasClients && _minuteController.selectedItem != newTime.minute) {
      _minuteController.animateToItem(
        newTime.minute,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatTimeLabel(TimeOfDay tod) {
    final hourStr = tod.hour.toString().padLeft(2, '0');
    final minStr = tod.minute.toString().padLeft(2, '0');
    final periodTag = tod.hour < 12 ? 'sáng' : (tod.hour < 18 ? 'chiều' : 'tối');
    return "$hourStr:$minStr ($periodTag)";
  }

  String _formatQuickTime(TimeOfDay tod) {
    return "${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}";
  }

  bool _isSameTime(TimeOfDay a, TimeOfDay b) {
    return a.hour == b.hour && a.minute == b.minute;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // Quick time presets
    final nowTime = TimeOfDay.fromDateTime(now);
    final plus30Min = TimeOfDay.fromDateTime(now.add(const Duration(minutes: 30)));
    const time1900 = TimeOfDay(hour: 19, minute: 0);
    const time1930 = TimeOfDay(hour: 19, minute: 30);

    final dateStr =
        "${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}";

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: TColor.bgOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
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
          // Header Bar
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
                    "Chọn giờ lấy",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Ngày $dateStr",
                    style: TextStyle(
                      color: TColor.secondaryTextOf(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  widget.onTimeSelected(_tempTime);
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

          const SizedBox(height: 16),

          // Quick Preset Time Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip(
                  label: "⚡ +30 phút",
                  isSelected: _isSameTime(_tempTime, plus30Min),
                  onTap: () => _updateTempTime(plus30Min),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  label: "${_formatQuickTime(nowTime)} (Bây giờ)",
                  isSelected: _isSameTime(_tempTime, nowTime),
                  onTap: () => _updateTempTime(nowTime),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  label: "19:00",
                  isSelected: _isSameTime(_tempTime, time1900),
                  onTap: () => _updateTempTime(time1900),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  label: "19:30",
                  isSelected: _isSameTime(_tempTime, time1930),
                  onTap: () => _updateTempTime(time1930),
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Hour and Minute Picker Wheels with ":" Separator in Middle
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection Highlight Bar behind wheels & colon
                Container(
                  height: 44,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2B303E) : const Color(0xFFEFEFF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hour Wheel
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _hourController,
                        itemExtent: 40,
                        magnification: 1.15,
                        squeeze: 1.1,
                        selectionOverlay: const SizedBox(),
                        onSelectedItemChanged: (hourIndex) {
                          setState(() {
                            _tempTime = TimeOfDay(hour: hourIndex, minute: _tempTime.minute);
                          });
                        },
                        children: List.generate(24, (index) {
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Colon Separator Widget ":"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        ":",
                        style: TextStyle(
                          color: TColor.primaryTextOf(context),
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    // Minute Wheel
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _minuteController,
                        itemExtent: 40,
                        magnification: 1.15,
                        squeeze: 1.1,
                        selectionOverlay: const SizedBox(),
                        onSelectedItemChanged: (minuteIndex) {
                          setState(() {
                            _tempTime = TimeOfDay(hour: _tempTime.hour, minute: minuteIndex);
                          });
                        },
                        children: List.generate(60, (index) {
                          return Center(
                            child: Text(
                              index.toString().padLeft(2, '0'),
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Bottom Action Button: Full-width Confirm Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                widget.onTimeSelected(_tempTime);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFC6011),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFFFC6011).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Xác nhận giờ lấy (${_formatTimeLabel(_tempTime)})",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
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
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFC0C4D0) : const Color(0xFF333333)),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
