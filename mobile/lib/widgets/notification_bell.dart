import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../view/more/notification_view.dart';

class NotificationBell extends StatelessWidget {
  final Color? iconColor;
  final Color? backgroundColor;
  final BoxBorder? border;
  final double size;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const NotificationBell({
    super.key,
    this.iconColor,
    this.backgroundColor,
    this.border,
    this.size = 20,
    this.width = 44,
    this.height = 44,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, child) {
        final unreadCount = notifProvider.unreadCount;
        final String? badgeText = unreadCount > 99
            ? '99+'
            : unreadCount > 0
                ? '$unreadCount'
                : null;

        return InkWell(
          onTap: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsView()),
                );
              },
          borderRadius: BorderRadius.circular(width / 2),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              shape: BoxShape.circle,
              border: border,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  color: iconColor ?? const Color(0xFF1C1C1E),
                  size: size,
                ),
                if (badgeText != null)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
