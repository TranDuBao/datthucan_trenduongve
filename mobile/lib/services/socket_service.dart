import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../common/globs.dart';

class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    final token = Globs.udValueString(KKey.authToken);
    if (token.isEmpty) {
      disconnect();
      return;
    }

    if (_socket != null && _socket!.connected) {
      return;
    }

    try {
      _socket = io.io(
        SVKey.mainUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _setupSocketListeners();
    } catch (e) {
      debugPrint('⚠️ Mobile Socket initialization error: $e');
    }
  }

  final Map<String, List<void Function(dynamic)>> _scopedListeners = {};
  final List<VoidCallback> _reconnectCallbacks = [];

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      debugPrint('⚡ Mobile Socket connected: ${_socket?.id}');
    });

    _socket?.onConnectError((err) {
      debugPrint('⚠️ Mobile Socket connect error: $err');
    });

    _socket?.onDisconnect((reason) {
      debugPrint('⚡ Mobile Socket disconnected: $reason');
    });

    _socket?.onReconnect((_) {
      debugPrint('⚡ Mobile Socket reconnected');
      for (final cb in List<VoidCallback>.from(_reconnectCallbacks)) {
        try {
          cb();
        } catch (e) {
          debugPrint('⚠️ Reconnect callback error: $e');
        }
      }
    });

    // Re-attach all registered scoped event listeners
    for (final event in _scopedListeners.keys) {
      _attachSocketEvent(event);
    }
  }

  void _attachSocketEvent(String event) {
    _socket?.off(event);
    _socket?.on(event, (data) {
      final listeners = _scopedListeners[event];
      if (listeners != null) {
        for (final cb in List<void Function(dynamic)>.from(listeners)) {
          try {
            cb(data);
          } catch (e) {
            debugPrint('⚠️ Socket listener error for [$event]: $e');
          }
        }
      }
    });
  }

  void onReconnect(VoidCallback onReconnectCallback) {
    if (!_reconnectCallbacks.contains(onReconnectCallback)) {
      _reconnectCallbacks.add(onReconnectCallback);
    }
  }

  void offReconnect(VoidCallback onReconnectCallback) {
    _reconnectCallbacks.remove(onReconnectCallback);
  }

  /// Subscribe a specific callback to an event (Scoped listener)
  void subscribe(String event, void Function(dynamic data) listener) {
    final list = _scopedListeners.putIfAbsent(event, () => []);
    if (!list.contains(listener)) {
      list.add(listener);
      if (list.length == 1) {
        _attachSocketEvent(event);
      }
    }
  }

  /// Unsubscribe a specific callback (or all if listener is null)
  void unsubscribe(String event, [void Function(dynamic data)? listener]) {
    if (listener != null) {
      _scopedListeners[event]?.remove(listener);
      if (_scopedListeners[event]?.isEmpty ?? true) {
        _scopedListeners.remove(event);
        _socket?.off(event);
      }
    } else {
      _scopedListeners.remove(event);
      _socket?.off(event);
    }
  }

  void listenToOrderCreated(void Function(dynamic data) onOrderCreated) {
    subscribe('order:created', onOrderCreated);
  }

  void listenToOrderUpdates(void Function(dynamic data) onOrderUpdate) {
    subscribe('order:status_changed', onOrderUpdate);
    subscribe('payment:confirmed', onOrderUpdate);
  }

  void listenToReservationUpdates(void Function(dynamic data) onReservationUpdate) {
    subscribe('reservation:status_changed', onReservationUpdate);
    subscribe('reservation:created', onReservationUpdate);
  }

  void listenToNotifications(void Function(dynamic data) onNotification) {
    subscribe('notification:new', onNotification);
  }

  void listenToVoucherUpdates(void Function(dynamic data) onVoucherUpdate) {
    subscribe('voucher:updated', onVoucherUpdate);
  }

  void listenToStoreProfileUpdates(void Function(dynamic data) onProfileUpdate) {
    subscribe('restaurant:profile_updated', onProfileUpdate);
  }

  void offNotifications([void Function(dynamic data)? listener]) {
    unsubscribe('notification:new', listener);
  }

  void offVoucherUpdates([void Function(dynamic data)? listener]) {
    unsubscribe('voucher:updated', listener);
  }

  void offOrderUpdates([void Function(dynamic data)? listener]) {
    unsubscribe('order:status_changed', listener);
    unsubscribe('payment:confirmed', listener);
    unsubscribe('order:created', listener);
  }

  void offReservationUpdates([void Function(dynamic data)? listener]) {
    unsubscribe('reservation:status_changed', listener);
    unsubscribe('reservation:created', listener);
  }

  void offStoreProfileUpdates([void Function(dynamic data)? listener]) {
    unsubscribe('restaurant:profile_updated', listener);
  }

  void joinRestaurantRoom(int maQuan) {
    if (isConnected && maQuan > 0) {
      _socket?.emit('room:join', {'roomType': 'restaurant', 'id': maQuan});
    }
  }

  void leaveRestaurantRoom(int maQuan) {
    if (isConnected && maQuan > 0) {
      _socket?.emit('room:leave', {'roomType': 'restaurant', 'id': maQuan});
    }
  }

  void joinOrderRoom(int orderId) {
    if (isConnected && orderId > 0) {
      _socket?.emit('room:join', {'roomType': 'order', 'id': orderId});
    }
  }

  void leaveOrderRoom(int orderId) {
    if (isConnected && orderId > 0) {
      _socket?.emit('room:leave', {'roomType': 'order', 'id': orderId});
    }
  }

  void joinReservationRoom(int reservationId) {
    if (isConnected && reservationId > 0) {
      _socket?.emit('room:join', {'roomType': 'reservation', 'id': reservationId});
    }
  }

  void leaveReservationRoom(int reservationId) {
    if (isConnected && reservationId > 0) {
      _socket?.emit('room:leave', {'roomType': 'reservation', 'id': reservationId});
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }
  }
}
