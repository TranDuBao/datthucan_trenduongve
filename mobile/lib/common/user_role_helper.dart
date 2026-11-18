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
    return r == 'CUAN_HANG' ||
        r == 'CUA_HANG' ||
        r == 'RESTAURANT' ||
        r == 'STORE' ||
        r == 'MERCHANT' ||
        r == 'CHỦ QUÁN';
  }

  static bool get isAdmin {
    final r = userRole;
    return r == 'ADMIN' || r == 'QUẢN TRỊ';
  }

  static bool get isGuest {
    // 1. Chế độ khách vãng lai tường minh
    if (Globs.udValueBool(Globs.isGuestMode)) return true;

    // 2. Nếu có auth token hợp lệ -> Chắc chắn là người dùng đã đăng nhập, không bao giờ là khách
    final token = Globs.udValueString(KKey.authToken).trim();
    if (token.isNotEmpty) return false;

    // 3. Nếu chưa đăng nhập
    if (!Globs.udValueBool(Globs.userLogin)) return true;

    return false;
  }

  static String get userName {
    if (isGuest) return 'Khách';
    final p = payload;
    if (p['user'] is Map) {
      final u = p['user'] as Map;
      return u['fullName'] ??
          u['hoTen'] ??
          u['tenDangNhap'] ??
          u['username'] ??
          u['email'] ??
          'Khách Hàng';
    }
    if (p['khachHang'] is Map) {
      final kh = p['khachHang'] as Map;
      return kh['hoTen'] ?? kh['fullName'] ?? 'Khách Hàng';
    }
    return p['fullName'] ??
        p['hoTen'] ??
        p['tenDangNhap'] ??
        p['username'] ??
        p['email'] ??
        'Khách Hàng';
  }
}
