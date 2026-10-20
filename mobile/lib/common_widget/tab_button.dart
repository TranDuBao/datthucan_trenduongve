import 'package:flutter/material.dart';

import '../common/color_extension.dart';

class TabButton extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String icon;
  final IconData? iconData;
  final bool isSelected;
  final int badgeCount;

  const TabButton({
    super.key,
    required this.title,
    this.icon = "",
    this.iconData,
    required this.onTap,
    required this.isSelected,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final unselectedColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff6C727F)
        : TColor.placeholder;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              iconData != null
                  ? Icon(
                      iconData,
                      size: 20,
                      color: isSelected ? TColor.primary : unselectedColor,
                    )
                  : Image.asset(
                      icon,
                      width: 18,
                      height: 18,
                      color: isSelected ? TColor.primary : unselectedColor,
                    ),
              if (badgeCount > 0)
                Positioned(
                  top: -5,
                  right: -9,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1B1E28)
                            : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? TColor.primary : unselectedColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: TColor.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}