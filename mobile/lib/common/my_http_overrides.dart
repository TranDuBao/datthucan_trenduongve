import 'dart:io';
import 'package:flutter/foundation.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Only bypass invalid/self-signed certificates in local debug mode.
        // In release mode, strict SSL verification is strictly enforced.
        return kDebugMode;
      };
  }
}