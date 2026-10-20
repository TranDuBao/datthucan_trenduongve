import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:food_delivery/main.dart';

class Globs {
  static const appName = "Food Delivery";

  static const userPayload = "user_payload";
  static const userLogin = "user_login";

  static void showHUD({String status = "loading ....."}) async {
    await Future.delayed(const Duration(milliseconds: 1));
    EasyLoading.show(status: status);
  }

  static void hideHUD() {
    EasyLoading.dismiss();
  }

  static void udSet(dynamic data, String key) {
    var jsonStr = json.encode(data);
    prefs?.setString(key, jsonStr);
  }

  static void udStringSet(String data, String key) {
    prefs?.setString(key, data);
  }

  static void udBoolSet(bool data, String key) {
    prefs?.setBool(key, data);
  }

  static void udIntSet(int data, String key) {
    prefs?.setInt(key, data);
  }

  static void udDoubleSet(double data, String key) {
    prefs?.setDouble(key, data);
  }

  static dynamic udValue(String key) {
    return json.decode(prefs?.get(key) as String? ?? "{}");
  }

  static String udValueString(String key) {
    return prefs?.get(key) as String? ?? "";
  }

  static bool udValueBool(String key) {
    return prefs?.get(key) as bool? ?? false;
  }

  static bool udValueTrueBool(String key) {
    return prefs?.get(key) as bool? ?? true;
  }

  static int udValueInt(String key) {
    return prefs?.get(key) as int? ?? 0;
  }

  static double udValueDouble(String key) {
    return prefs?.get(key) as double? ?? 0.0;
  }

  static void udRemove(String key) {
    prefs?.remove(key);
  }

  static Future<String> timeZone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } on PlatformException {
      return "";
    }
  }
}

class SVKey {
  // Support custom API_URL passed at build time via --dart-define=API_URL=...
  // Fallback to 10.0.2.2 for Android Emulator, or localhost for Web/Desktop/iOS Sim
  static String get mainUrl {
    const customUrl = String.fromEnvironment('API_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return "http://10.0.2.2:3000";
    }
    return "http://localhost:3000";
  }

  static String get baseUrl => '${mainUrl}/api/v1/auth/';
  static String get nodeUrl => mainUrl;

  static String get svLogin => '${baseUrl}login';
  static String get svSignUp => '${baseUrl}register';
  static String get svGoogleAuth => '${baseUrl}google';
  static String get svLogout => '${baseUrl}logout';
  static String get svGetProfile => '${baseUrl}me';

  static String get svForgotPasswordRequest => '${baseUrl}forgot_password_request';
  static String get svForgotPasswordVerify => '${baseUrl}forgot_password_verify';
  static String get svForgotPasswordSetNew => '${baseUrl}forgot_password_set_new';
  static String get svUpdateProfile => '${baseUrl}update_profile';
  static String get svChangePassword => '${baseUrl}change_password';

  static String get svRestaurants => '${mainUrl}/api/v1/restaurants';
  static String svRestaurantMenu(int id) => '${mainUrl}/api/v1/restaurants/$id/menu';
  static String get svOrders => '${mainUrl}/api/v1/orders';
  static String get svVerifyPayment => '${mainUrl}/api/v1/payments/verify';

  static String formatImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('data:image')) {
      return trimmed;
    }
    // Handle uploaded images containing /uploads/
    if (trimmed.contains('/uploads/')) {
      final fileName = trimmed.split('/uploads/').last;
      return '${mainUrl}/uploads/$fileName';
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final cleanPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '${mainUrl}$cleanPath';
  }
}

class KKey {
  static const payload = "payload";
  static const status = "status";
  static const message = "message";
  static const authToken = "auth_token";
  static const name = "name";
  static const email = "email";
  static const userId = "user_id";
  static const resetCode = "reset_code";
}

class MSG {
  static const enterEmail = "Vui lòng nhập email hợp lệ";
  static const enterPassword = "Mật khẩu phải chứa ít nhất 6 ký tự";
  static const enterName = "Vui lòng nhập họ và tên";
  static const enterMobile = "Vui lòng nhập số điện thoại";
  static const enterAddress = "Vui lòng nhập địa chỉ";
  static const enterPasswordNotMatch = "Mật khẩu xác nhận không khớp";
  static const enterCode = "Vui lòng nhập mã OTP hợp lệ";
  static const success = "Thành công!";
  static const fail = "Đã xảy ra lỗi, vui lòng thử lại!";
}
