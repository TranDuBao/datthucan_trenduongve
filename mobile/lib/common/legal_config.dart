enum LoaiHinhPhapLy {
  caNhan,
  hoKinhDoanh,
  doanhNghiep,
}

class LegalFieldRequirement {
  final String key;
  final String label;
  final bool requireTaxCode;
  final bool requireBusinessLicense;
  final bool requireFoodSafetyCert;

  const LegalFieldRequirement({
    required this.key,
    required this.label,
    required this.requireTaxCode,
    required this.requireBusinessLicense,
    required this.requireFoodSafetyCert,
  });
}

/// Single Source of Truth for Legal Configurations across Mobile App
class LegalConfig {
  static const Map<LoaiHinhPhapLy, LegalFieldRequirement> requirements = {
    LoaiHinhPhapLy.caNhan: LegalFieldRequirement(
      key: 'CA_NHAN',
      label: 'Cá nhân kinh doanh',
      requireTaxCode: true,
      requireBusinessLicense: false,
      requireFoodSafetyCert: false,
    ),
    LoaiHinhPhapLy.hoKinhDoanh: LegalFieldRequirement(
      key: 'HO_KINH_DOANH',
      label: 'Hộ kinh doanh cá thể',
      requireTaxCode: true,
      requireBusinessLicense: true,
      requireFoodSafetyCert: false,
    ),
    LoaiHinhPhapLy.doanhNghiep: LegalFieldRequirement(
      key: 'DOANH_NGHIEP',
      label: 'Doanh nghiệp / Công ty',
      requireTaxCode: true,
      requireBusinessLicense: true,
      requireFoodSafetyCert: true,
    ),
  };

  static LegalFieldRequirement getRequirement(LoaiHinhPhapLy type) {
    return requirements[type] ?? requirements[LoaiHinhPhapLy.caNhan]!;
  }

  static LegalFieldRequirement getRequirementByKey(String? key) {
    for (final entry in requirements.values) {
      if (entry.key == key) return entry;
    }
    return requirements[LoaiHinhPhapLy.caNhan]!;
  }

  /// Validate Vietnamese Tax Identification Number (MST)
  /// 10 digits or 13 digits (10 digits + '-' + 3 digits)
  static bool validateMaSoThue(String? mst) {
    if (mst == null) return false;
    final clean = mst.trim();
    final regex = RegExp(r'^[0-9]{10}(-[0-9]{3})?$');
    return regex.hasMatch(clean);
  }
}

