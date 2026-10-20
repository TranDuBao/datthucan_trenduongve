import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BankItem {
  final int id;
  final String name;
  final String code;
  final String bin;
  final String shortName;
  final String logo;
  final String displayName;

  BankItem({
    required this.id,
    required this.name,
    required this.code,
    required this.bin,
    required this.shortName,
    required this.logo,
    required this.displayName,
  });

  factory BankItem.fromJson(Map<String, dynamic> json) {
    final sName = (json['shortName'] ?? json['short_name'] ?? json['code'] ?? '').toString();
    final c = (json['code'] ?? '').toString();
    final n = (json['name'] ?? '').toString();
    final l = (json['logo'] ?? '').toString();
    final b = (json['bin'] ?? '').toString();
    final idVal = json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0;

    final disp = sName.isNotEmpty
        ? (c.isNotEmpty ? '$sName ($c)' : sName)
        : (c.isNotEmpty ? '$n ($c)' : n);

    return BankItem(
      id: idVal,
      name: n,
      code: c,
      bin: b,
      shortName: sName.isNotEmpty ? sName : c,
      logo: l,
      displayName: disp,
    );
  }
}

class BankService {
  static List<BankItem>? _cachedBanks;

  static Future<List<BankItem>> getVietQRBanks() async {
    if (_cachedBanks != null && _cachedBanks!.isNotEmpty) {
      return _cachedBanks!;
    }

    try {
      final res = await http.get(Uri.parse('https://api.vietqr.io/v2/banks')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        final list = body['data'];
        if (list is List && list.isNotEmpty) {
          _cachedBanks = list.map((item) => BankItem.fromJson(item as Map<String, dynamic>)).toList();
          return _cachedBanks!;
        }
      }
    } catch (e) {
      debugPrint('[BankService] Error fetching VietQR banks: $e');
    }

    _cachedBanks = _fallbackBanks;
    return _cachedBanks!;
  }

  static final List<BankItem> _fallbackBanks = [
    BankItem(id: 1, name: 'Ngân hàng TMCP Ngoại Thương Việt Nam', code: 'VCB', bin: '970436', shortName: 'Vietcombank', logo: 'https://api.vietqr.io/img/VCB.png', displayName: 'Vietcombank (VCB)'),
    BankItem(id: 2, name: 'Ngân hàng TMCP Công Thương Việt Nam', code: 'ICB', bin: '970415', shortName: 'VietinBank', logo: 'https://api.vietqr.io/img/ICB.png', displayName: 'VietinBank (ICB)'),
    BankItem(id: 3, name: 'Ngân hàng TMCP Đầu tư và Phát triển Việt Nam', code: 'BIDV', bin: '970418', shortName: 'BIDV', logo: 'https://api.vietqr.io/img/BIDV.png', displayName: 'BIDV (BIDV)'),
    BankItem(id: 4, name: 'Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam', code: 'VBA', bin: '970405', shortName: 'Agribank', logo: 'https://api.vietqr.io/img/VBA.png', displayName: 'Agribank (VBA)'),
    BankItem(id: 5, name: 'Ngân hàng TMCP Quân Đội', code: 'MB', bin: '970422', shortName: 'MBBank', logo: 'https://api.vietqr.io/img/MB.png', displayName: 'MBBank (MB)'),
    BankItem(id: 6, name: 'Ngân hàng TMCP Kỹ Thương Việt Nam', code: 'TCB', bin: '970407', shortName: 'Techcombank', logo: 'https://api.vietqr.io/img/TCB.png', displayName: 'Techcombank (TCB)'),
    BankItem(id: 7, name: 'Ngân hàng TMCP Á Châu', code: 'ACB', bin: '970416', shortName: 'ACB', logo: 'https://api.vietqr.io/img/ACB.png', displayName: 'ACB (ACB)'),
    BankItem(id: 8, name: 'Ngân hàng TMCP Việt Nam Thịnh Vượng', code: 'VPB', bin: '970432', shortName: 'VPBank', logo: 'https://api.vietqr.io/img/VPB.png', displayName: 'VPBank (VPB)'),
    BankItem(id: 9, name: 'Ngân hàng TMCP Tiên Phong', code: 'TPB', bin: '970423', shortName: 'TPBank', logo: 'https://api.vietqr.io/img/TPB.png', displayName: 'TPBank (TPB)'),
    BankItem(id: 10, name: 'Ngân hàng TMCP Sài Gòn Thương Tín', code: 'STB', bin: '970403', shortName: 'Sacombank', logo: 'https://api.vietqr.io/img/STB.png', displayName: 'Sacombank (STB)'),
    BankItem(id: 11, name: 'Ngân hàng TMCP Quốc Tế Việt Nam', code: 'VIB', bin: '970441', shortName: 'VIB', logo: 'https://api.vietqr.io/img/VIB.png', displayName: 'VIB (VIB)'),
    BankItem(id: 12, name: 'Ngân hàng TMCP Phát Triển TP.HCM', code: 'HDB', bin: '970437', shortName: 'HDBank', logo: 'https://api.vietqr.io/img/HDB.png', displayName: 'HDBank (HDB)'),
    BankItem(id: 13, name: 'Ngân hàng TMCP Sài Gòn Hà Nội', code: 'SHB', bin: '970443', shortName: 'SHB', logo: 'https://api.vietqr.io/img/SHB.png', displayName: 'SHB (SHB)'),
    BankItem(id: 14, name: 'Ngân hàng TMCP Hàng Hải Việt Nam', code: 'MSB', bin: '970426', shortName: 'MSB', logo: 'https://api.vietqr.io/img/MSB.png', displayName: 'MSB (MSB)'),
    BankItem(id: 15, name: 'Ngân hàng TMCP Phương Đông', code: 'OCB', bin: '970448', shortName: 'OCB', logo: 'https://api.vietqr.io/img/OCB.png', displayName: 'OCB (OCB)'),
    BankItem(id: 16, name: 'Ngân hàng TMCP Lộc Phát Việt Nam', code: 'LPB', bin: '970449', shortName: 'LPBank', logo: 'https://api.vietqr.io/img/LPB.png', displayName: 'LPBank (LPB)'),
    BankItem(id: 17, name: 'Ngân hàng TMCP Sài Gòn', code: 'SCB', bin: '970429', shortName: 'SCB', logo: 'https://api.vietqr.io/img/SCB.png', displayName: 'SCB (SCB)'),
    BankItem(id: 18, name: 'Ngân hàng TMCP Nam Á', code: 'NAB', bin: '970428', shortName: 'NamABank', logo: 'https://api.vietqr.io/img/NAB.png', displayName: 'NamABank (NAB)'),
    BankItem(id: 19, name: 'Ngân hàng TMCP An Bình', code: 'ABB', bin: '970425', shortName: 'ABBANK', logo: 'https://api.vietqr.io/img/ABB.png', displayName: 'ABBANK (ABB)'),
    BankItem(id: 20, name: 'Ngân hàng TMCP Bắc Á', code: 'BAB', bin: '970409', shortName: 'BacABank', logo: 'https://api.vietqr.io/img/BAB.png', displayName: 'BacABank (BAB)'),
    BankItem(id: 21, name: 'Ngân hàng TMCP Bản Việt', code: 'BVB', bin: '970454', shortName: 'BVBank', logo: 'https://api.vietqr.io/img/BVB.png', displayName: 'BVBank (BVB)'),
    BankItem(id: 22, name: 'Ngân hàng TMCP Đông Nam Á', code: 'SEAB', bin: '970440', shortName: 'SeABank', logo: 'https://api.vietqr.io/img/SEAB.png', displayName: 'SeABank (SEAB)'),
    BankItem(id: 23, name: 'Ngân hàng TMCP Xuất Nhập Khẩu Việt Nam', code: 'EIB', bin: '970431', shortName: 'Eximbank', logo: 'https://api.vietqr.io/img/EIB.png', displayName: 'Eximbank (EIB)'),
    BankItem(id: 24, name: 'Ngân hàng TNHH MTV Shinhan Việt Nam', code: 'SHBVN', bin: '970424', shortName: 'ShinhanBank', logo: 'https://api.vietqr.io/img/SHBVN.png', displayName: 'ShinhanBank (SHBVN)'),
    BankItem(id: 25, name: 'Ngân hàng Wooribank Việt Nam', code: 'WOO', bin: '970457', shortName: 'Woori', logo: 'https://api.vietqr.io/img/WOO.png', displayName: 'Woori Bank (WOO)'),
  ];
}
