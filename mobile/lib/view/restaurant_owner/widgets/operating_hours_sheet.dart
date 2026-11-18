import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../common/format_utils.dart';
import '../../../common/color_extension.dart';
import '../../../widgets/custom_toast.dart';

class OperatingHoursDialog extends StatefulWidget {
  final dynamic rawOperatingHours;
  final Future<void> Function(String newScheduleJson) onSave;

  const OperatingHoursDialog({
    super.key,
    required this.rawOperatingHours,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required dynamic rawOperatingHours,
    required Future<void> Function(String newScheduleJson) onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OperatingHoursDialog(
        rawOperatingHours: rawOperatingHours,
        onSave: onSave,
      ),
    );
  }

  @override
  State<OperatingHoursDialog> createState() => _OperatingHoursDialogState();
}

class _DaySchedule {
  final String key;
  final String label;
  bool isOpen;
  String from;
  String to;

  _DaySchedule({
    required this.key,
    required this.label,
    required this.isOpen,
    required this.from,
    required this.to,
  });

  Map<String, dynamic> toJson() => {
        'open': isOpen,
        'from': from,
        'to': to,
      };
}

class _OperatingHoursDialogState extends State<OperatingHoursDialog> {
  late List<_DaySchedule> _days;
  bool _isSaving = false;

  static const List<Map<String, String>> _defaultDayDefs = [
    {'key': 'mon', 'label': 'Thứ Hai'},
    {'key': 'tue', 'label': 'Thứ Ba'},
    {'key': 'wed', 'label': 'Thứ Tư'},
    {'key': 'thu', 'label': 'Thứ Năm'},
    {'key': 'fri', 'label': 'Thứ Sáu'},
    {'key': 'sat', 'label': 'Thứ Bảy'},
    {'key': 'sun', 'label': 'Chủ Nhật'},
  ];

  @override
  void initState() {
    super.initState();
    _initSchedule();
  }

  void _initSchedule() {
    _days = [];
    Map<String, dynamic> parsedMap = {};

    final raw = widget.rawOperatingHours;
    if (raw != null) {
      if (raw is Map) {
        parsedMap = Map<String, dynamic>.from(raw);
      } else {
        final str = raw.toString().trim();
        if (str.startsWith('{')) {
          try {
            final decoded = jsonDecode(str);
            if (decoded is Map) {
              parsedMap = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {}
        }
      }
    }

    for (final def in _defaultDayDefs) {
      final key = def['key']!;
      final label = def['label']!;
      final dayData = parsedMap[key];

      bool isOpen = true;
      String from = '07:00';
      String to = '22:00';

      if (dayData is Map) {
        isOpen = dayData['open'] != false;
        from = (dayData['from'] ?? '07:00').toString();
        to = (dayData['to'] ?? '22:00').toString();
      }

      _days.add(_DaySchedule(
        key: key,
        label: label,
        isOpen: isOpen,
        from: from,
        to: to,
      ));
    }
  }

  Future<void> _selectTime(int index, bool isFrom) async {
    final day = _days[index];
    final currentTimeStr = isFrom ? day.from : day.to;
    final parts = currentTimeStr.split(':');
    final initialHour = int.tryParse(parts.isNotEmpty ? parts[0] : '07') ?? 7;
    final initialMin = int.tryParse(parts.length > 1 ? parts[1] : '00') ?? 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
      helpText: isFrom ? 'Chọn giờ mở cửa (${day.label})' : 'Chọn giờ đóng cửa (${day.label})',
      confirmText: 'Xác nhận',
      cancelText: 'Hủy',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFFC6011),
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E2430) : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isFrom) {
          day.from = formatted;
        } else {
          day.to = formatted;
        }
      });
    }
  }

  String _getDayLabel(BuildContext context, String key, String fallback) {
    switch (key.toLowerCase()) {
      case 'mon': return context.l10n.dayMonday;
      case 'tue': return context.l10n.dayTuesday;
      case 'wed': return context.l10n.dayWednesday;
      case 'thu': return context.l10n.dayThursday;
      case 'fri': return context.l10n.dayFriday;
      case 'sat': return context.l10n.daySaturday;
      case 'sun': return context.l10n.daySunday;
      default: return fallback;
    }
  }

  void _applyMondayToAll() {
    if (_days.isEmpty) return;
    final mon = _days.first;
    setState(() {
      for (int i = 1; i < _days.length; i++) {
        _days[i].isOpen = mon.isOpen;
        _days[i].from = mon.from;
        _days[i].to = mon.to;
      }
    });
    CustomToast.showSuccess(context, 'Đã áp dụng giờ của Thứ Hai cho cả tuần!');
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final map = <String, dynamic>{};
    for (final d in _days) {
      map[d.key] = d.toJson();
    }
    final jsonStr = jsonEncode(map);

    try {
      await widget.onSave(jsonStr);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Lỗi lưu lịch hoạt động: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2430) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final rowBg = isDark ? const Color(0xFF242C3A) : const Color(0xFFF8FAFC);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: cardBg,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Row ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFFFC6011),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.storeHoursModalTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: TColor.primaryTextOf(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Localizations.localeOf(context).languageCode == 'en'
                              ? 'Tap time to edit directly'
                              : 'Chạm vào giờ để chỉnh sửa trực tiếp',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: TColor.secondaryTextOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: TColor.secondaryTextOf(context),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Quick Action: Copy Monday to All ─────────────────────────
              InkWell(
                onTap: _applyMondayToAll,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6011).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFFC6011).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.copy_all_rounded, size: 16, color: Color(0xFFFC6011)),
                      const SizedBox(width: 6),
                      Text(
                        Localizations.localeOf(context).languageCode == 'en'
                            ? 'Apply Monday hours to all days'
                            : 'Áp dụng giờ của Thứ Hai cho cả tuần',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── 7 Days List ──────────────────────────────────────────────
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _days.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final day = _days[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: rowBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          // Day Label
                          SizedBox(
                            width: 84,
                            child: Text(
                              _getDayLabel(context, day.key, day.label),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: day.isOpen
                                    ? TColor.primaryTextOf(context)
                                    : TColor.secondaryTextOf(context),
                              ),
                            ),
                          ),

                          // Time Pickers or Closed Badge
                          Expanded(
                            child: day.isOpen
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // From time button
                                      _buildTimeButton(
                                        context,
                                        time: day.from,
                                        onTap: () => _selectTime(index, true),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Text(
                                          '–',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: TColor.secondaryTextOf(context),
                                          ),
                                        ),
                                      ),
                                      // To time button
                                      _buildTimeButton(
                                        context,
                                        time: day.to,
                                        onTap: () => _selectTime(index, false),
                                      ),
                                    ],
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFECACA)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        Localizations.localeOf(context).languageCode == 'en' ? 'Closed' : 'Nghỉ / Đóng cửa',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),

                          const SizedBox(width: 8),

                          // Open / Closed Switch
                          Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: day.isOpen,
                              activeColor: const Color(0xFFFC6011),
                              activeTrackColor: const Color(0xFFFED7AA),
                              inactiveThumbColor: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              onChanged: (val) {
                                setState(() => day.isOpen = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // ── Bottom Action Buttons ────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'en' ? 'Cancel' : 'Hủy',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TColor.primaryTextOf(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6011),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  Localizations.localeOf(context).languageCode == 'en' ? 'Save Schedule' : 'Lưu lịch hoạt động',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
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

  Widget _buildTimeButton(
    BuildContext context, {
    required String time,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFC6011).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFFFC6011)),
            const SizedBox(width: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

