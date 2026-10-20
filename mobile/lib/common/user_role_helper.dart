import 'globs.dart';
import 'service_call.dart';

class UserRoleHelper {
  static Map<String, dynamic> get payload {
    final stored = Globs.udValue(Globs.userPayload);
    if (stored is Map && stored.isNotEmpty) {
      return Map<String, dynamic>.from(stored);
    }
    if (ServiceCall.userPayload.isNotEmpty) {
      return Map<String, dynamic>.from(ServiceCall.userPayload);
    }
    return {};
  }

  static String get userRole {
    final p = payload;
    if (p.isEmpty) return 'KHACH_HANG';

    // 1. Check user.role or user.loaiTaiKhoan
    if (p['user'] is Map) {
      final userMap = p['user'] as Map;
      if (userMap['role'] != null) return userMap['role'].toString().toUpperCase();
      if (userMap['loaiTaiKhoan'] != null) return userMap['loaiTaiKhoan'].toString().toUpperCase();
    }

    // 2. Check top-level role or loaiTaiKhoan
    if (p['role'] != null) return p['role'].toString().toUpperCase();
    if (p['loaiTaiKhoan'] != null) return p['loaiTaiKhoan'].toString().toUpperCase();

    return 'KHACH_HANG';
  }

  static bool get isMerchant {
    final r = userRole;
    return r == 'CUAN_HANG' || r == 'RESTAURANT' || r == 'MERCHANT' || r == 'CHỦ QUÁN';
  }

  static bool get isAdmin {
    final r = userRole;
    return r == 'ADMIN' || r == 'QUẢN TRỊ';
  }

  static String get userName {
    final p = payload;
    if (p['user'] is Map) {
      final u = p['user'] as Map;
      return u['fullName'] ?? u['username'] ?? u['email'] ?? 'Cửa Hàng';
    }
    return p['fullName'] ?? p['username'] ?? p['email'] ?? 'Cửa Hàng';
  }
}
