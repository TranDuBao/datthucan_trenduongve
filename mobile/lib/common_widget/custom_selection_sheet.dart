import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class SelectionOptionItem<T> {
  final T value;
  final String title;
  final String subtitle;
  final Widget iconWidget;

  SelectionOptionItem({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.iconWidget,
  });
}

class CustomSelectionSheet<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<SelectionOptionItem<T>> options;
  final T initialValue;
  final String confirmText;
  final ValueChanged<T> onConfirm;

  const CustomSelectionSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.initialValue,
    required this.confirmText,
    required this.onConfirm,
  });

  static Future<void> show<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<SelectionOptionItem<T>> options,
    required T initialValue,
    required String confirmText,
    required ValueChanged<T> onConfirm,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161920) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return CustomSelectionSheet<T>(
          title: title,
          subtitle: subtitle,
          options: options,
          initialValue: initialValue,
          confirmText: confirmText,
          onConfirm: onConfirm,
        );
      },
    );
  }

  @override
  State<CustomSelectionSheet<T>> createState() => _CustomSelectionSheetState<T>();
}

class _CustomSelectionSheetState<T> extends State<CustomSelectionSheet<T>> {
  late T selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF222222);
    final secondaryTextColor = isDark ? const Color(0xFFA0A5B1) : const Color(0xFF777777);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Drag Handle Bar
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF333846) : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: secondaryTextColor,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option Items List
          ...widget.options.map((item) {
            final isSelected = selectedValue == item.value;
            final borderColor = isSelected
                ? TColor.primary
                : (isDark ? const Color(0xFF282C37) : const Color(0xFFEFEFEF));
            final bgColor = isSelected
                ? (isDark ? TColor.primary.withOpacity(0.12) : const Color(0xFFFFF7F2))
                : (isDark ? const Color(0xFF1E212B) : const Color(0xFFFAFAFA));

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedValue = item.value;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon Widget / Flag Badge
                    item.iconWidget,
                    const SizedBox(width: 14),

                    // Title & Subtitle Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Custom Radio Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? TColor.primary
                              : (isDark ? const Color(0xFF4A5060) : const Color(0xFFCCCCCC)),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isSelected
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: TColor.primary,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                widget.onConfirm(selectedValue);
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.confirmText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
