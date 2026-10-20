import 'package:flutter/material.dart';
import '../common/locator.dart';
import '../common/sound_helper.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';

class NotificationProvider extends ChangeNotifier {
  final SocketService _socketService = locator<SocketService>();

  int _unreadCount = 0;
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  NotificationModel? _latestBannerNotification;

  int get unreadCount => _unreadCount;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  NotificationModel? get latestBannerNotification => _latestBannerNotification;

  bool _isInitialized = false;

  void initialize() {
    if (!_isInitialized) {
      _isInitialized = true;

      // Connect socket
      _socketService.connect();

      // Subscribe to notification events
      _socketService.listenToNotifications(_handleNewNotification);
      _socketService.listenToOrderUpdates(_handleOrderOrPaymentEvent);
      _socketService.listenToReservationUpdates(_handleReservationEvent);

      // Resync on reconnect
      _socketService.onReconnect(() {
        refreshAll();
      });
    }

    // Always refresh data on initialize
    refreshAll();
  }

  Future<void> refreshAll() async {
    await fetchUnreadCount();
    await fetchNotifications(refresh: true);
  }

  Future<void> fetchUnreadCount() async {
    try {
      final count = await NotificationService.fetchUnreadCount();
      if (count > 0 || _unreadCount == 0) {
        _unreadCount = count;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await NotificationService.fetchNotificationsFromDB(page: 1, limit: 30);
      _notifications = items;
      final unreadFromList = items.where((n) => n.isUnread).length;
      if (unreadFromList > 0 || _unreadCount == 0) {
        _unreadCount = unreadFromList;
      }
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách thông báo';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleNewNotification(dynamic data) {
    SoundHelper.playNotificationSound();
    if (data is Map<String, dynamic>) {
      final newNotif = NotificationModel.fromJson(data);
      _unreadCount += 1;
      _notifications.insert(0, newNotif);
      _latestBannerNotification = newNotif;
      notifyListeners();
    } else {
      fetchUnreadCount();
    }
  }

  void _handleOrderOrPaymentEvent(dynamic data) {
    // When order status or payment updates, play sound & refresh
    SoundHelper.playNotificationSound();
    fetchUnreadCount();
    fetchNotifications(refresh: true);
  }

  void _handleReservationEvent(dynamic data) {
    SoundHelper.playNotificationSound();
    fetchUnreadCount();
    fetchNotifications(refresh: true);
  }

  void clearBanner() {
    _latestBannerNotification = null;
    notifyListeners();
  }

  Future<void> markAsRead(NotificationModel item) async {
    if (item.isUnread) {
      item.isUnread = false;
      if (_unreadCount > 0) _unreadCount -= 1;
      notifyListeners();
      await NotificationService.markAsRead(item.id);
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n.isUnread = false;
    }
    _unreadCount = 0;
    notifyListeners();
    await NotificationService.markAllAsReadApi();
  }

  @override
  void dispose() {
    _socketService.offNotifications();
    _socketService.offOrderUpdates();
    _socketService.offReservationUpdates();
    super.dispose();
  }
}
