import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/globs.dart';
import 'common/locator.dart';
import 'common/my_http_overrides.dart';
import 'common/service_call.dart';
import 'providers/cart_provider.dart';
import 'providers/language_provider.dart';
import 'providers/map_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/support_provider.dart';
import 'l10n/app_localizations.dart';
import 'view/login/welcome_view.dart';
import 'view/main_tabview/main_tabview.dart';
import 'view/on_boarding/startup_view.dart';
import 'services/fcm_push_service.dart';

SharedPreferences? prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configLoading();
  setUpLocator();

  // Initialize Firebase and Push notification services
  await FcmPushService.instance.initialize();

  // Only bypass self-signed / local certificates in debug mode
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("dotenv load warning: $e");
  }

  prefs = await SharedPreferences.getInstance();

  if (Globs.udValueBool(Globs.userLogin)) {
    ServiceCall.userPayload = Globs.udValue(Globs.userPayload);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => SupportProvider()),
      ],
      child: const MyApp(defaultHome: StartupView()),
    ),
  );
}

void configLoading() {
  EasyLoading.instance
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..indicatorSize = 44.0
    ..radius = 20.0
    ..progressColor = const Color(0xFFFF5216)
    ..backgroundColor = Colors.white
    ..indicatorColor = const Color(0xFFFF5216)
    ..textColor = const Color(0xFF1F2937)
    ..maskColor = const Color.fromRGBO(0, 0, 0, 0.35)
    ..maskType = EasyLoadingMaskType.custom
    ..userInteractions = false
    ..dismissOnTap = false
    ..animationStyle = EasyLoadingAnimationStyle.scale
    ..contentPadding = const EdgeInsets.symmetric(vertical: 22, horizontal: 28)
    ..textPadding = const EdgeInsets.only(top: 14)
    ..textStyle = const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1F2937),
      letterSpacing: -0.2,
      fontFamily: 'Metropolis',
    )
    ..boxShadow = [
      const BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.12),
        blurRadius: 28,
        spreadRadius: 2,
        offset: Offset(0, 8),
      ),
    ]
    ..indicatorWidget = Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(4),
      child: const CircularProgressIndicator(
        strokeWidth: 3.5,
        strokeCap: StrokeCap.round,
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5216)),
        backgroundColor: Color(0xFFFFECE5),
      ),
    );
}

class MyApp extends StatefulWidget {
  final Widget defaultHome;
  const MyApp({super.key, required this.defaultHome});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return MaterialApp(
      title: 'Food Route',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: widget.defaultHome,
      navigatorKey: locator<NavigationService>().navigatorKey,
      onGenerateRoute: (routeSettings) {
        switch (routeSettings.name) {
          case "welcome":
            return MaterialPageRoute(builder: (context) => const WelcomeView());
          case "Home":
            return MaterialPageRoute(builder: (context) => const MainTabView());
          default:
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(
                  child: Text("No path for ${routeSettings.name}"),
                ),
              ),
            );
        }
      },
      builder: (context, child) {
        return FlutterEasyLoading(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: child,
          ),
        );
      },
    );
  }
}
