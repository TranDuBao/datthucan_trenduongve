import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'user_language_code';
  Locale _locale = const Locale('vi');

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  LanguageProvider() {
    _loadLanguage();
  }

  static LanguageProvider of(BuildContext context, {bool listen = true}) {
    return listen
        ? (context.dependOnInheritedWidgetOfExactType<_LanguageProviderScope>()?.provider ??
            _fallbackOf(context))
        : _fallbackOf(context);
  }

  static LanguageProvider _fallbackOf(BuildContext context) {
    return context.read<LanguageProvider>();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey);
    if (savedCode != null && (savedCode == 'vi' || savedCode == 'en')) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String code) async {
    if (code != 'vi' && code != 'en') return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }

  String tr(String key) {
    final dict = _translations[_locale.languageCode] ?? _translations['vi']!;
    return dict[key] ?? _translations['en']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'vi': {
      // Navigation & Tabs
      'menu': 'Thực đơn',
      'offer': 'Cửa hàng',
      'profile': 'Hồ sơ',
      'more': 'Khác',
      'home': 'Trang chủ',
      'search': 'Tìm kiếm món ăn',
      'cart': 'Giỏ hàng',
      'my_order': 'Đơn hàng của tôi',

      // Auth & Welcome
      'welcome': 'Chào mừng',
      'login': 'Đăng nhập',
      'sign_up': 'Đăng ký',
      'logout': 'Đăng xuất',
      'login_title': 'Đăng nhập',
      'login_subtitle': 'Nhập thông tin của bạn để đăng nhập',
      'your_email': 'Email của bạn',
      'password': 'Mật khẩu',
      'forgot_password': 'Quên mật khẩu?',
      'or_login_with': 'Hoặc đăng nhập với',
      'login_google': 'Đăng nhập bằng Google',
      'dont_have_account': 'Chưa có tài khoản?',
      'already_have_account': 'Đã có tài khoản?',

      // Menu Categories
      'food': 'Món ăn',
      'beverages': 'Thức uống',
      'desserts': 'Món tráng miệng',
      'promotions': 'Khuyến mãi',
      'items': 'món',

      // Settings & Theme
      'settings': 'Cài đặt',
      'language': 'Ngôn ngữ',
      'theme_mode': 'Giao diện',
      'select_language': 'Chọn ngôn ngữ',
      'select_theme': 'Chọn chế độ giao diện',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'light_mode': 'Chế độ Sáng',
      'dark_mode': 'Chế độ Tối',
      'system_mode': 'Theo hệ thống',

      // Profile & More Options
      'payment_details': 'Chi tiết thanh toán',
      'notifications': 'Thông báo',
      'inbox': 'Voucher',
      'about_us': 'Về chúng tôi',
      'change_address': 'Đổi địa chỉ',
      'confirm': 'Xác nhận',
      'cancel': 'Hủy',
      'save': 'Lưu',
      'success': 'Thành công',
      'error': 'Lỗi',
    },
    'en': {
      // Navigation & Tabs
      'menu': 'Menu',
      'offer': 'Offers',
      'profile': 'Profile',
      'more': 'More',
      'home': 'Home',
      'search': 'Search Food',
      'cart': 'Cart',
      'my_order': 'My Order',

      // Auth & Welcome
      'welcome': 'Welcome',
      'login': 'Login',
      'sign_up': 'Sign Up',
      'logout': 'Logout',
      'login_title': 'Login',
      'login_subtitle': 'Add your details to login',
      'your_email': 'Your Email',
      'password': 'Password',
      'forgot_password': 'Forgot Password?',
      'or_login_with': 'Or Login With',
      'login_google': 'Login with Google',
      'dont_have_account': "Don't have an Account?",
      'already_have_account': 'Already have an Account?',

      // Menu Categories
      'food': 'Food',
      'beverages': 'Beverages',
      'desserts': 'Desserts',
      'promotions': 'Promotions',
      'items': 'items',

      // Settings & Theme
      'settings': 'Settings',
      'language': 'Language',
      'theme_mode': 'Theme Mode',
      'select_language': 'Select Language',
      'select_theme': 'Select Theme Mode',
      'vietnamese': 'Tiếng Việt',
      'english': 'English',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'system_mode': 'System Default',

      // Profile & More Options
      'payment_details': 'Payment Details',
      'notifications': 'Notifications',
      'inbox': 'Inbox',
      'about_us': 'About Us',
      'change_address': 'Change Address',
      'confirm': 'Confirm',
      'cancel': 'Cancel',
      'save': 'Save',
      'success': 'Success',
      'error': 'Error',
    },
  };
}

class _LanguageProviderScope extends InheritedWidget {
  final LanguageProvider provider;
  const _LanguageProviderScope({required this.provider, required super.child});

  @override
  bool updateShouldNotify(_LanguageProviderScope oldWidget) => true;
}
