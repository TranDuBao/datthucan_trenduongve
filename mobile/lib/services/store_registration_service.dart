import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../common/globs.dart';
import '../common/service_call.dart';
import '../model/store_registration_model.dart';
import '../model/legal_document_model.dart';

class StoreRegistrationService {
  static const List<String> storeCategories = [
    'Cà phê & Trà',
    'Cơm & Món mặn',
    'Bánh mì & Xôi',
    'Bún, Phở & Mì',
    'Trà sữa & Ăn vặt',
    'Đồ ăn nhanh & Burger',
    'Lẩu & Nướng',
    'Món Chay',
    'Khác',
  ];

  static const List<Map<String, String>> vietnameseBanks = [
    {'code': 'VCB', 'name': 'Vietcombank (Ngoại Thương Việt Nam)'},
    {'code': 'MB', 'name': 'MB Bank (Quân Đội)'},
    {'code': 'TCB', 'name': 'Techcombank (Kỹ Thương Việt Nam)'},
    {'code': 'BIDV', 'name': 'BIDV (Đầu Tư & Phát Triển)'},
    {'code': 'CTG', 'name': 'VietinBank (Công Thương Việt Nam)'},
    {'code': 'VPB', 'name': 'VPBank (Việt Nam Thịnh Vượng)'},
    {'code': 'ACB', 'name': 'ACB (Á Châu)'},
    {'code': 'TPB', 'name': 'TPBank (Tiên Phong)'},
    {'code': 'STB', 'name': 'Sacombank (Sài Gòn Thương Tín)'},
    {'code': 'HDB', 'name': 'HDBank (Phát Triển TP.HCM)'},
    {'code': 'VIB', 'name': 'VIB (Quốc Tế Việt Nam)'},
    {'code': 'AGR', 'name': 'Agribank (Nông Nghiệp & PTNT)'},
    {'code': 'MSB', 'name': 'MSB (Hàng Hải Việt Nam)'},
    {'code': 'SHB', 'name': 'SHB (Sài Gòn - Hà Nội)'},
    {'code': 'OCB', 'name': 'OCB (Phương Đông)'},
  ];

  static Future<Map<String, dynamic>> submitRegistration(StoreRegistrationModel model) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse(SVKey.svStoreRegistration);

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(model.toJson()),
      ).timeout(const Duration(seconds: 15));

      final resJson = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': resJson['message'] ?? 'Gửi đơn đăng ký thành công',
          'data': resJson['data'] != null ? StoreRegistrationModel.fromJson(resJson['data']) : null,
        };
      } else {
        return {
          'success': false,
          'code': resJson['code'],
          'message': resJson['message'] ?? 'Không thể gửi đơn đăng ký',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Hết thời gian chờ kết nối máy chủ. Vui lòng thử lại!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối máy chủ: $e',
      };
    }
  }

  static Future<StoreRegistrationModel?> fetchMyStatus() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      if (token.isEmpty) return null;

      final url = Uri.parse(SVKey.svStoreRegistrationMyStatus);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['data'] != null) {
          return StoreRegistrationModel.fromJson(resJson['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[StoreRegistrationService] fetchMyStatus error: $e');
      return null;
    }
  }

  static Future<bool> refreshUserProfile() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      if (token.isEmpty) return false;

      final url = Uri.parse(SVKey.svRefreshProfile);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        final payload = resJson['payload'] ?? resJson['data'];
        if (payload != null) {
          if (payload['accessToken'] != null) {
            Globs.udSet(payload['accessToken'], KKey.authToken);
          }
          if (payload['user'] != null) {
            Globs.udSet(payload['user'], Globs.userPayload);
            ServiceCall.userPayload = Map<String, dynamic>.from(payload['user']);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[StoreRegistrationService] refreshUserProfile error: $e');
      return false;
    }
  }

  static Future<ActiveLegalDocumentsResponse?> fetchActiveLegalDocuments() async {
    try {
      final url = Uri.parse(SVKey.svActiveLegalDocuments);
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final resJson = jsonDecode(response.body);
        if (resJson['data'] != null) {
          return ActiveLegalDocumentsResponse.fromJson(resJson['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[StoreRegistrationService] fetchActiveLegalDocuments error: $e');
      return null;
    }
  }
}

