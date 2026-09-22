import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'user_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_prefKey);
    if (savedMode != null) {
      switch (savedMode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String value = 'system';
    if (mode == ThemeMode.light) value = 'light';
    if (mode == ThemeMode.dark) value = 'dark';
    await prefs.setString(_prefKey, value);
  }

  static ThemeData get lightTheme {
    const primaryColor = Color(0xFFFC6011);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: "Metropolis",
      scaffoldBackgroundColor: const Color(0xFFF6F6F6),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4A4B4D),
        elevation: 0,
      ),
      cardColor: Colors.white,
    );
  }

  static ThemeData get darkTheme {
    const primaryColor = Color(0xFFFC6011);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: "Metropolis",
      scaffoldBackgroundColor: const Color(0xFF0D0F14),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        surface: const Color(0xFF171B26),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF171B26),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: const Color(0xFF171B26),
    );
  }
}
