import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../common/color_extension.dart';

/// Modal thông báo khi người dùng đã di chuyển đến quán để nhận hàng
class StoreArrivalModal extends StatelessWidget {
  final String storeName;
  final String? orderCode;
  final VoidCallback onConfirmPickedUp;

  const StoreArrivalModal({
    super.key,
    required this.storeName,
    this.orderCode,
    required this.onConfirmPickedUp,
  });

  static Future<void> show({
    required BuildContext context,
    required String storeName,
    String? orderCode,
    required VoidCallback onConfirmPickedUp,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StoreArrivalModal(
        storeName: storeName,
        orderCode: orderCode,
        onConfirmPickedUp: onConfirmPickedUp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon huy hiệu cửa hàng nổi bật
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFC6011), Color(0xFFFF7A3D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.store,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Tiêu đề
            const Text(
              'Đã Đến Quán Nhận Hàng!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2022),
              ),
            ),
            const SizedBox(height: 8),

            // Tên quán & mã đơn
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF4B5563),
                ),
                children: [
                  const TextSpan(text: 'Bạn đã tới '),
                  TextSpan(
                    text: storeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFC6011),
                    ),
                  ),
                  if (orderCode != null && orderCode!.isNotEmpty) ...[
                    const TextSpan(text: ' (Đơn '),
                    TextSpan(
                      text: '#$orderCode',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ')'),
                  ],
                  const TextSpan(text: '.\nVui lòng ghé lấy món và chúc quý khách ngon miệng!'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nút xác nhận đã lấy món
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirmPickedUp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.check, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Đã lấy món • Tiếp tục đi',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Animation chúc mừng hoàn thành toàn bộ lộ trình
class RouteCompletedModal extends StatefulWidget {
  final VoidCallback onFinish;

  const RouteCompletedModal({
    super.key,
    required this.onFinish,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onFinish,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RouteCompletedModal(onFinish: onFinish),
    );
  }

  @override
  State<RouteCompletedModal> createState() => _RouteCompletedModalState();
}

class _RouteCompletedModalState extends State<RouteCompletedModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation dấu tích thành công
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x4010B981),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.flag,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Tiêu đề
            const Text(
              'Đã Đến Điểm Đích!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),

            // Lời nhắn kết thúc lộ trình
            const Text(
              'Chúc mừng bạn đã hoàn thành chuyến đi an toàn.\nCảm ơn bạn đã lựa chọn FoodRoute!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 26),

            // Nút hoàn tất chuyến đi
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onFinish();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Hoàn tất lộ trình',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

