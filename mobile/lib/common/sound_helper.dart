import 'package:flutter/services.dart';

class SoundHelper {
  /// Phát âm thanh chuông cảnh báo thông báo và rung nhẹ của hệ điều hành
  static Future<void> playNotificationSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Bỏ qua lỗi nếu thiết bị ở chế độ im lặng hoặc không hỗ trợ
    }
  }
}
