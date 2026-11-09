import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:food_route/common/format_utils.dart';
import 'package:food_route/common/globs.dart';
import 'package:food_route/common/locator.dart';
import 'package:food_route/providers/cart_provider.dart';
import 'package:food_route/providers/map_provider.dart';
import 'package:food_route/providers/notification_provider.dart';
import 'package:food_route/services/fcm_push_service.dart';
import 'package:food_route/services/socket_service.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

typedef ResSuccess = Future<void> Function(Map<String, dynamic>);
typedef ResFailure = Future<void> Function(dynamic);

class ServiceCall {
  static final NavigationService navigationService = locator<NavigationService>();
  static Map userPayload = {};
  static bool _isRefreshing = false;

  static Future<bool> refreshToken() async {
    final currentRefreshToken = Globs.udValueString(KKey.refreshToken);
    if (currentRefreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse(SVKey.svRefreshToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': currentRefreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>? ?? {};
        if (data[KKey.status] == "1") {
          final payload = data[KKey.payload] as Map<String, dynamic>? ?? {};
          final newAccess = (payload['accessToken'] ?? payload[KKey.authToken] ?? '').toString();
          final newRefresh = (payload['refreshToken'] ?? payload['refresh_token'] ?? '').toString();

          if (newAccess.isNotEmpty) {
            Globs.udStringSet(newAccess, KKey.authToken);
          }
          if (newRefresh.isNotEmpty) {
            Globs.udStringSet(newRefresh, KKey.refreshToken);
          }
          return true;
        }
      }
    } catch (e) {
      debugPrint("[ServiceCall] Token refresh failed: $e");
    }
    return false;
  }

  static void post(Map<String, dynamic> parameter, String path,
      {bool isToken = false, ResSuccess? withSuccess, ResFailure? failure}) {
    Future(() async {
      try {
        var headers = <String, String>{'Content-Type': 'application/json'};
        var token = Globs.udValueString(KKey.authToken);
        if (token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }

        var response = await http.post(
          Uri.parse(path),
          body: jsonEncode(parameter),
          headers: headers,
        );

        if (kDebugMode) {
          print("[$path] Status: ${response.statusCode}, Body: ${response.body}");
        }

        // Tự động làm mới token nếu 401 Unauthorized
        if (response.statusCode == 401 && path != SVKey.svLogin && path != SVKey.svRefreshToken) {
          if (!_isRefreshing) {
            _isRefreshing = true;
            final refreshed = await refreshToken();
            _isRefreshing = false;

            if (refreshed) {
              token = Globs.udValueString(KKey.authToken);
              headers['Authorization'] = 'Bearer $token';
              response = await http.post(
                Uri.parse(path),
                body: jsonEncode(parameter),
                headers: headers,
              );
            } else {
              logout(isExpired: true);
              if (failure != null) failure("Session expired");
              return;
            }
          }
        }

        try {
          var jsonObj =
              json.decode(response.body) as Map<String, dynamic>? ?? {};

          if (withSuccess != null) withSuccess(jsonObj);
        } catch (err) {
          if (failure != null) failure(err.toString());
        }
      } catch (err) {
        if (failure != null) failure(err.toString());
      }
    });
  }

  static void logout({bool isExpired = false}) {
    final token = Globs.udValueString(KKey.authToken);
    final rToken = Globs.udValueString(KKey.refreshToken);

    // Thu hồi token trên backend nếu có
    if (token.isNotEmpty || rToken.isNotEmpty) {
      try {
        http.post(
          Uri.parse(SVKey.svLogout),
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'refreshToken': rToken}),
        ).catchError((_) => http.Response('', 500));
      } catch (_) {}
    }

    // Unregister FCM push token from backend
    FcmPushService.instance.unregisterToken();

    // Ngắt kết nối Socket.IO realtime
    try {
      locator<SocketService>().disconnect();
    } catch (_) {}

    // Dọn sạch toàn bộ trạng thái trong bộ nhớ (Map, Giỏ hàng, Thông báo) để tránh rò rỉ dữ liệu sang tài khoản khác
    final ctx = navigationService.navigatorKey.currentContext;
    if (ctx != null) {
      try {
        ctx.read<MapProvider>().clearAll();
      } catch (_) {}
      try {
        ctx.read<CartProvider>().clearCart();
      } catch (_) {}
      try {
        ctx.read<NotificationProvider>().clearAllData();
      } catch (_) {}
    }

    Globs.udBoolSet(false, Globs.userLogin);
    Globs.udRemove(Globs.userPayload);
    Globs.udRemove(KKey.authToken);
    Globs.udRemove(KKey.refreshToken);
    userPayload = {};

    // Chỉ giữ lại email đã nhớ nếu người dùng từng tick ghi nhớ
    if (!Globs.udValueBool(KKey.rememberMe)) {
      Globs.udRemove(KKey.savedEmail);
    }

    navigationService.navigateTo("welcome");

    if (isExpired) {
      Future.delayed(const Duration(milliseconds: 300), () {
        EasyLoading.showInfo(
          "Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại.",
          duration: const Duration(seconds: 3),
        );
      });
    }
  }

  static void showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161920) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333846) : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.authLogoutConfirmTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.authLogoutConfirmMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFA0A5B1) : const Color(0xFF777777),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF333846) : const Color(0xFFDDDDDD),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        context.l10n.commonCancel,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        logout();
                      },
                      child: Text(
                        context.l10n.commonConfirm,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
}
