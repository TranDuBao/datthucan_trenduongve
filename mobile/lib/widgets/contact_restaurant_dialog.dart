import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'custom_toast.dart';

/// Hộp thoại liên hệ nhà hàng với thiết kế hiện đại, tinh tế.
Future<void> showContactRestaurantDialog({
  required BuildContext context,
  required String restaurantName,
  required String phone,
  required bool isDark,
}) {
  final displayPhone = phone.trim().isNotEmpty ? phone.trim() : '0909998877';
  final displayName = restaurantName.trim().isNotEmpty ? restaurantName.trim() : 'Nhà hàng';

  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2230) : Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon huy hiệu bo tròn nổi bật
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFFFC6011).withValues(alpha: 0.28),
                          const Color(0xFFFC6011).withValues(alpha: 0.10),
                        ]
                      : [
                          const Color(0xFFFC6011).withValues(alpha: 0.14),
                          const Color(0xFFFC6011).withValues(alpha: 0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFC6011).withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.phone_in_talk_rounded,
                  color: Color(0xFFFC6011),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tiêu đề
            Text(
              'Liên hệ nhà hàng',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Gọi trực tiếp để quán hỗ trợ nhanh nhất về đơn của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),

            // Hộp thông tin quán & số điện thoại
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141722) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2D3548) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 16,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayPhone,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Color(0xFFFC6011),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: displayPhone));
                            CustomToast.showSuccess(context, 'Đã sao chép số $displayPhone');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(5),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 16,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Hai nút bấm: Đóng & Gọi ngay
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? const Color(0xFF333A4D) : const Color(0xFFE2E8F0),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: isDark ? const Color(0xFF232838) : const Color(0xFFF1F5F9),
                      ),
                      child: Text(
                        'Đóng',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6011),
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: const Color(0xFFFC6011).withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final cleanPhone = displayPhone.replaceAll(RegExp(r'\s+'), '');
                        final uri = Uri.parse('tel:$cleanPhone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else if (context.mounted) {
                          CustomToast.showSuccess(context, 'Đang kết nối cuộc gọi tới $displayPhone...');
                        }
                      },
                      icon: const Icon(Icons.phone_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        'Gọi ngay',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
    ),
  );
}
