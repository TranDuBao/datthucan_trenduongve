import 'package:flutter/material.dart';
import '../common/color_extension.dart';
import '../common/format_utils.dart';

class DishCustomizationSection extends StatelessWidget {
  final List<Map<String, dynamic>> sizeOptions;
  final int selectedOptionIndex;
  final ValueChanged<int> onSelectSize;

  final List<Map<String, dynamic>> toppingOptions;
  final void Function(int index, bool selected) onToggleTopping;

  final TextEditingController noteController;
  final bool isSoldOut;
  final String Function(num amount) formatCurrency;

  const DishCustomizationSection({
    super.key,
    required this.sizeOptions,
    required this.selectedOptionIndex,
    required this.onSelectSize,
    required this.toppingOptions,
    required this.onToggleTopping,
    required this.noteController,
    required this.isSoldOut,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Lựa chọn khẩu phần
        if (sizeOptions.isNotEmpty) ...[
          Row(
            children: [
              Text(
                context.l10n.dishCustomizationPortion,
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2EC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  context.l10n.dishCustomizationRequired,
                  style: const TextStyle(
                    color: Color(0xFFFF4D00),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.dishCustomizationChooseOne,
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(sizeOptions.length, (index) {
              final opt = sizeOptions[index];
              final isSelected = selectedOptionIndex == index;
              return GestureDetector(
                onTap: isSoldOut ? null : () => onSelectSize(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: TColor.cardOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected && !isSoldOut ? const Color(0xFFFF4D00) : TColor.borderOf(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected && !isSoldOut
                                ? const Color(0xFFFF4D00)
                                : TColor.secondaryTextOf(context),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            opt["name"]?.toString() ?? '',
                            style: TextStyle(
                              color: TColor.primaryTextOf(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        opt["extra"] == 0 ? context.l10n.dishCustomizationFree : "+${formatCurrency(opt['extra'] ?? 0)}",
                        style: TextStyle(
                          color: isSelected && !isSoldOut
                              ? const Color(0xFFFF4D00)
                              : TColor.secondaryTextOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],

        // Section 2: Topping thêm
        if (toppingOptions.isNotEmpty) ...[
          Row(
            children: [
              Text(
                context.l10n.dishCustomizationToppings,
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2E3B) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  context.l10n.dishCustomizationOptional,
                  style: TextStyle(
                    color: TColor.secondaryTextOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                context.l10n.dishCustomizationChooseMultiple,
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(toppingOptions.length, (index) {
              final top = toppingOptions[index];
              final isSelected = top["selected"] == true;
              return GestureDetector(
                onTap: isSoldOut ? null : () => onToggleTopping(index, !isSelected),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: TColor.cardOf(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected && !isSoldOut ? const Color(0xFFFF4D00) : TColor.borderOf(context),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: isSelected && !isSoldOut
                                ? const Color(0xFFFF4D00)
                                : TColor.secondaryTextOf(context),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            top["name"]?.toString() ?? '',
                            style: TextStyle(
                              color: TColor.primaryTextOf(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "+${formatCurrency(top['extra'] ?? 0)}",
                        style: TextStyle(
                          color: isSelected && !isSoldOut
                              ? const Color(0xFFFF4D00)
                              : TColor.secondaryTextOf(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
        ],

        // Section 3: Ghi chú cho quán
        Text(
          context.l10n.dishNoteForStore,
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: noteController,
          enabled: !isSoldOut,
          style: TextStyle(color: TColor.primaryTextOf(context), fontSize: 13),
          decoration: InputDecoration(
            hintText: context.l10n.dishNoteForStoreHint,
            hintStyle: TextStyle(
              color: TColor.secondaryTextOf(context).withOpacity(0.6),
              fontSize: 12,
            ),
            filled: true,
            fillColor: TColor.cardOf(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: TColor.borderOf(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: TColor.borderOf(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF4D00)),
            ),
          ),
        ),
      ],
    );
  }
}

