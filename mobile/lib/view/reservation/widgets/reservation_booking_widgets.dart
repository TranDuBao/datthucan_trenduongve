import 'package:flutter/material.dart';
import '../../../common/color_extension.dart';
import '../../../common_widget/smart_network_image.dart';

enum SeatingAreaPreference {
  auto,
  indoor,
  outdoor,
}

class ReservationRestaurantCard extends StatelessWidget {
  final String storeName;
  final String storeAddress;
  final String storeImg;
  final double ratingVal;
  final bool isAccepting;
  final bool isDark;

  const ReservationRestaurantCard({
    super.key,
    required this.storeName,
    required this.storeAddress,
    required this.storeImg,
    required this.ratingVal,
    required this.isAccepting,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: storeImg.isNotEmpty
                      ? SmartNetworkImage(imageUrl: storeImg, width: 68, height: 68, fit: BoxFit.cover)
                      : Container(
                          color: TColor.primary.withOpacity(0.1),
                          child: Icon(Icons.restaurant_rounded, color: TColor.primary, size: 32),
                        ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C853),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAccepting ? const Color(0xFFE8F8F0) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isAccepting ? const Color(0xFF00C853) : const Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isAccepting ? 'Đang nhận bàn' : 'Tạm ngưng nhận bàn',
                            style: TextStyle(
                              color: isAccepting ? const Color(0xFF00A86B) : const Color(0xFFD32F2F),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFA000), size: 16),
                        const SizedBox(width: 3),
                        Text(
                          ratingVal.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: TColor.primaryTextOf(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  storeAddress.isNotEmpty ? storeAddress : 'Đang cập nhật địa chỉ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: TColor.secondaryTextOf(context),
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

class ReservationSectionTitle extends StatelessWidget {
  final String stepNum;
  final String title;
  final String? trailingText;
  final Color? trailingColor;
  final Widget? trailingWidget;

  const ReservationSectionTitle({
    super.key,
    required this.stepNum,
    required this.title,
    this.trailingText,
    this.trailingColor,
    this.trailingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: TColor.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNum,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: TColor.primaryTextOf(context),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        if (trailingWidget != null)
          trailingWidget!
        else if (trailingText != null)
          Text(
            trailingText!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: trailingColor ?? TColor.secondaryTextOf(context),
            ),
          ),
      ],
    );
  }
}

class ReservationDateTimeCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const ReservationDateTimeCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? TColor.primary : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB)),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? TColor.primary : TColor.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : TColor.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: TColor.secondaryTextOf(context)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: TColor.primaryTextOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReservationQuickTimeChips extends StatelessWidget {
  final List<TimeOfDay> slots;
  final TimeOfDay selectedTime;
  final ValueChanged<TimeOfDay> onSelected;
  final bool isDark;

  const ReservationQuickTimeChips({
    super.key,
    required this.slots,
    required this.selectedTime,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final slot = slots[index];
          final isSelected = selectedTime.hour == slot.hour && selectedTime.minute == slot.minute;
          final timeLabel = "${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}";

          return InkWell(
            onTap: () => onSelected(slot),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? TColor.primary : (isDark ? const Color(0xFF1E222D) : Colors.white),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? TColor.primary : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB)),
                ),
              ),
              child: Text(
                isSelected ? '$timeLabel (Đã chọn)' : timeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : TColor.primaryTextOf(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ReservationGuestCounter extends StatelessWidget {
  final int guestCount;
  final ValueChanged<int> onCountChanged;
  final String subtitle;
  final bool isDark;

  const ReservationGuestCounter({
    super.key,
    required this.guestCount,
    required this.onCountChanged,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: TColor.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.people_alt_outlined, color: TColor.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$guestCount người',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: TColor.primaryTextOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: TColor.secondaryTextOf(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              InkWell(
                onTap: guestCount > 1 ? () => onCountChanged(guestCount - 1) : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: guestCount > 1 ? const Color(0xFFFFECE5) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    color: guestCount > 1 ? TColor.primary : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$guestCount',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
              ),
              InkWell(
                onTap: guestCount < 20 ? () => onCountChanged(guestCount + 1) : null,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: TColor.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReservationQuickGuestChips extends StatelessWidget {
  final int guestCount;
  final ValueChanged<int> onSelected;
  final bool isDark;

  const ReservationQuickGuestChips({
    super.key,
    required this.guestCount,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> guestOptions = [
      {'label': '2 khách', 'count': 2},
      {'label': '4 khách', 'count': 4},
      {'label': '6 khách', 'count': 6},
      {'label': 'Tiệc 8+', 'count': 8},
    ];

    return Row(
      children: guestOptions.map((opt) {
        final int count = opt['count'] as int;
        final String label = opt['label'] as String;
        final bool isSelected = (count == 8 && guestCount >= 8) || (guestCount == count);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => onSelected(count),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFFF2EC)
                      : (isDark ? const Color(0xFF1E222D) : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? TColor.primary : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB)),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? TColor.primary : TColor.secondaryTextOf(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ReservationAreaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const ReservationAreaCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E222D) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? TColor.primary : (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? TColor.primary : Colors.grey.withOpacity(0.5),
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TColor.primaryTextOf(context),
                          ),
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2EC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: TColor.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            badgeText!,
                            style: TextStyle(
                              color: TColor.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: TColor.secondaryTextOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReservationContactCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController noteController;
  final bool isDark;

  const ReservationContactCard({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.noteController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222D) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Họ và tên
          Text(
            'Họ và tên',
            style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: nameController,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20, color: TColor.secondaryTextOf(context)),
              suffixIcon: const Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 20),
              filled: true,
              fillColor: isDark ? const Color(0xFF161822) : const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE0E0E0)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ tên';
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Số điện thoại
          Text(
            'Số điện thoại',
            style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined, size: 20, color: TColor.secondaryTextOf(context)),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Đã xác thực',
                        style: TextStyle(
                          color: Color(0xFF00A86B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF161822) : const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE0E0E0)),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
              if (!RegExp(r'^(0|\+84)[3|5|7|8|9][0-9]{8}$').hasMatch(val.trim())) {
                return 'Số điện thoại không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Ghi chú cho quán
          Text(
            'Ghi chú cho quán (không bắt buộc)',
            style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: noteController,
            maxLines: 2,
            style: TextStyle(fontSize: 13, color: TColor.primaryTextOf(context)),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.edit_note_rounded, size: 22, color: TColor.secondaryTextOf(context)),
              hintText: 'Ví dụ: Ghế cho trẻ em, kỷ niệm sinh nhật,...',
              hintStyle: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
              filled: true,
              fillColor: isDark ? const Color(0xFF161822) : const Color(0xFFFAFAFA),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
