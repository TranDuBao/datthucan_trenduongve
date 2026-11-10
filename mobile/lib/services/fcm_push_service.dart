import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../common/color_extension.dart';
import '../common/globs.dart';
import '../common/locator.dart';
import '../common/sound_helper.dart';
import '../view/more/notification_view.dart';
import '../view/more/order_history_view.dart';
import '../providers/notification_provider.dart';
import 'package:provider/provider.dart';
import 'notification_service.dart';

/// Top-level background message handler required by FirebaseMessaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM Background] Message received: ${message.messageId}, type: ${message.data['type']}');
}

class FcmPushService {
  static final FcmPushService instance = FcmPushService._internal();
  FcmPushService._internal();

  static const String currentAppVersion = "1.0.0";

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// High importance notification channel for order status & refunds
  static const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
    'food_route_orders',
    'Thông báo đơn hàng & hoàn tiền',
    description: 'Nhận thông báo khi món sẵn sàng, giao hàng hoặc hoàn tiền',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Default importance channel for system notices & updates
  static const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
    'food_route_system',
    'Thông báo hệ thống & cập nhật',
    description: 'Tin tức bảo trì và cập nhật phiên bản mới',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  /// 1. Initialize Firebase & Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _initLocalNotifications();
      _setupMessageListeners();

      // Automatically request Android 13+ / iOS notification permission
      await requestNotificationPermission();

      _isInitialized = true;
      debugPrint('[FcmPushService] Firebase & Push Notification initialized successfully');
    } catch (e) {
      debugPrint('[FcmPushService] Firebase initialization warning: $e');
    }
  }

  /// Initialize flutter_local_notifications for foreground display
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = json.decode(response.payload!) as Map<String, dynamic>;
            handleNotificationRouting(data);
          } catch (e) {
            debugPrint('[FcmPushService] Payload parse error: $e');
          }
        }
      },
    );

    // Create Android Channels
    final androidImpl = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(orderChannel);
      await androidImpl.createNotificationChannel(systemChannel);
    }
  }

  /// 2. Setup Foreground & Opened App Listeners
  void _setupMessageListeners() {
    // A. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM Foreground] Got message: ${message.notification?.title}');
      SoundHelper.playNotificationSound();

      final notification = message.notification;
      final data = message.data;

      final title = notification?.title ?? data['title'] ?? 'Food Route';
      final body = notification?.body ?? data['body'] ?? '';
      final notifType = data['type'] ?? 'system';

      final isOrderType = notifType.toString().startsWith('order') || notifType == 'refund';
      final channel = isOrderType ? orderChannel : systemChannel;

      _localNotifications.show(
        message.messageId.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: channel.importance,
            priority: isOrderType ? Priority.high : Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFFF5A0E),
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(data),
      );

      // Trigger realtime refresh for in-app bell counter
      try {
        final ctx = locator<NavigationService>().navigatorKey.currentContext;
        if (ctx != null) {
          ctx.read<NotificationProvider>().fetchUnreadCount();
        }
      } catch (_) {}
    });

    // B. App opened from background notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM Background Tap] Opened app via notif: ${message.data}');
      handleNotificationRouting(message.data);
    });

    // C. Token refresh listener
    _fcm.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      Globs.udStringSet(newToken, KKey.fcmDeviceToken);
      registerTokenWithBackend();
    });
  }

  /// Hiển thị thông báo ngay lập tức trên thanh thông báo Android/iOS (Notification tray / lockscreen)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String type = 'system',
    Map<String, dynamic>? data,
    int? id,
  }) async {
    try {
      final isOrderType = type.toString().startsWith('order') || type == 'refund';
      final channel = isOrderType ? orderChannel : systemChannel;
      final notifId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _localNotifications.show(
        notifId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFFF5A0E),
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data != null ? json.encode(data) : null,
      );
      debugPrint('[FcmPushService] Displayed notification on system tray: #$notifId - $title');
    } catch (e) {
      debugPrint('[FcmPushService] Error displaying system tray notification: $e');
    }
  }

  /// 3. Request Permission for Android 13+ and iOS
  Future<bool> requestNotificationPermission({BuildContext? context}) async {
    try {
      // A. Android 13+ (API 33+) Local Notification Runtime Permission
      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final androidGranted = await androidImpl.requestNotificationsPermission();
        debugPrint('[FcmPushService] Android POST_NOTIFICATIONS permission result: $androidGranted');
      }

      // B. FCM notification settings (iOS & Android)
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        await registerTokenWithBackend();
      }
      return granted;
    } catch (e) {
      debugPrint('[FcmPushService] Request permission error: $e');
      return false;
    }
  }

  /// Shows polite explanation sheet if user has never been prompted before
  Future<void> showPermissionPromptIfNeeded(BuildContext context) async {
    final alreadyPrompted = Globs.udValueBool(KKey.hasPromptedNotificationPermission);
    if (alreadyPrompted) return;

    // Check if permission already granted
    final currentSettings = await _fcm.getNotificationSettings();
    if (currentSettings.authorizationStatus == AuthorizationStatus.authorized) {
      Globs.udBoolSet(true, KKey.hasPromptedNotificationPermission);
      await registerTokenWithBackend();
      return;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: BoxDecoration(
            color: TColor.bgOf(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: TColor.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(LucideIcons.bellRing, size: 32, color: TColor.primary),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nhận thông báo đơn hàng',
                style: TextStyle(
                  color: TColor.primaryTextOf(ctx),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bật thông báo để biết ngay khi món của bạn đã sẵn sàng, quán tiếp nhận hoặc thông tin hoàn tiền tiện lợi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: TColor.secondaryTextOf(ctx),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      ),
                      onPressed: () {
                        Globs.udBoolSet(true, KKey.hasPromptedNotificationPermission);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Để sau',
                        style: TextStyle(color: TColor.secondaryTextOf(ctx), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        Globs.udBoolSet(true, KKey.hasPromptedNotificationPermission);
                        Navigator.pop(ctx);
                        await requestNotificationPermission();
                      },
                      child: const Text(
                        'Bật thông báo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// 4. Register Device Token with Backend
  Future<void> registerTokenWithBackend({String? overrideToken}) async {
    try {
      final token = overrideToken ?? await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      _fcmToken = token;
      Globs.udStringSet(token, KKey.fcmDeviceToken);

      final platform = Platform.isIOS ? 'ios' : 'android';
      final lang = Globs.udValueString('selected_language').isNotEmpty
          ? Globs.udValueString('selected_language')
          : 'vi';

      await NotificationService.registerDeviceToken(
        token: token,
        platform: platform,
        language: lang,
        appVersion: currentAppVersion,
      );
      debugPrint('[FcmPushService] Device token registered with backend successfully');
    } catch (e) {
      debugPrint('[FcmPushService] registerTokenWithBackend note: $e');
    }
  }

  /// 5. Unregister Token upon Logout
  Future<void> unregisterToken() async {
    try {
      final token = _fcmToken ?? Globs.udValueString(KKey.fcmDeviceToken);
      if (token.isNotEmpty) {
        await NotificationService.unregisterDeviceToken(token);
        Globs.udRemove(KKey.fcmDeviceToken);
        _fcmToken = null;
      }
    } catch (e) {
      debugPrint('[FcmPushService] unregisterToken error: $e');
    }
  }

  /// 6. Update preferred language of device token
  Future<void> updateLanguage(String langCode) async {
    try {
      await NotificationService.updateNotificationSettings(language: langCode);
    } catch (_) {}
  }

  /// 7. Cold Start Handler (Terminated App State)
  Future<void> handleInitialMessage() async {
    try {
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('[FcmPushService] Cold start from notif: ${initialMessage.data}');
        // Wait briefly for app UI tree / navigation service to mount
        Future.delayed(const Duration(milliseconds: 600), () {
          handleNotificationRouting(initialMessage.data);
        });
      }
    } catch (e) {
      debugPrint('[FcmPushService] handleInitialMessage error: $e');
    }
  }

  /// 8. Centralized Routing Handler
  void handleNotificationRouting(Map<String, dynamic> data) {
    try {
      final nav = locator<NavigationService>();
      final notifType = data['type']?.toString().toLowerCase() ?? '';
      final rawOrderId = data['orderId'] ?? data['maDonHang'];

      if (rawOrderId != null || notifType.startsWith('order') || notifType == 'refund') {
        // Navigate to Order History view
        nav.navigatePush(MaterialPageRoute(builder: (_) => const OrderHistoryView()));
      } else {
        // Navigate to Inbox / Notifications view
        nav.navigatePush(MaterialPageRoute(builder: (_) => const NotificationsView()));
      }
    } catch (e) {
      debugPrint('[FcmPushService] Routing failed: $e');
    }
  }

  /// 9. Check App Version & Display Required / Recommended Update Dialog
  Future<void> checkAppVersion(BuildContext context) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final config = await NotificationService.fetchAppVersionConfig(platform: platform);
      if (config == null || !context.mounted) return;

      final latestVer = config['latestVersion']?.toString() ?? currentAppVersion;
      final minRequiredVer = config['minRequiredVersion']?.toString() ?? currentAppVersion;
      final storeUrl = config['storeUrl']?.toString() ?? '';
      final changelogVi = config['changelogVi']?.toString() ?? 'Đã có phiên bản mới với nhiều cải tiến.';

      final isLowerThanMin = _isVersionLower(currentAppVersion, minRequiredVer);
      final isLowerThanLatest = _isVersionLower(currentAppVersion, latestVer);

      if (isLowerThanMin) {
        // Mandatory update: user cannot dismiss
        _showUpdateDialog(
          context: context,
          isMandatory: true,
          latestVersion: latestVer,
          changelog: changelogVi,
          storeUrl: storeUrl,
        );
      } else if (isLowerThanLatest) {
        // Optional update: check 24h snooze
        final lastSnooze = Globs.udValueInt(KKey.snoozeVersionCheckTime);
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastSnooze > 24 * 60 * 60 * 1000) {
          _showUpdateDialog(
            context: context,
            isMandatory: false,
            latestVersion: latestVer,
            changelog: changelogVi,
            storeUrl: storeUrl,
          );
        }
      }
    } catch (e) {
      debugPrint('[FcmPushService] checkAppVersion note: $e');
    }
  }

  bool _isVersionLower(String current, String target) {
    try {
      final currParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final targetParts = target.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < targetParts.length; i++) {
        final c = i < currParts.length ? currParts[i] : 0;
        final t = targetParts[i];
        if (c < t) return true;
        if (c > t) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _showUpdateDialog({
    required BuildContext context,
    required bool isMandatory,
    required String latestVersion,
    required String changelog,
    required String storeUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (ctx) {
        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Icon(
                  isMandatory ? LucideIcons.alertTriangle : LucideIcons.arrowUpCircle,
                  color: isMandatory ? const Color(0xFFD32F2F) : TColor.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMandatory ? 'Cập nhật bắt buộc' : 'Đã có phiên bản mới',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phiên bản $latestVersion đã sẵn sàng để tải về.',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  changelog,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                ),
              ],
            ),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () {
                    Globs.udIntSet(DateTime.now().millisecondsSinceEpoch, KKey.snoozeVersionCheckTime);
                    Navigator.pop(ctx);
                  },
                  child: Text('Để sau', style: TextStyle(color: Colors.grey.shade600)),
                ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (storeUrl.isNotEmpty) {
                    final uri = Uri.tryParse(storeUrl);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: const Text('Cập nhật ngay', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
    );
  }
}
