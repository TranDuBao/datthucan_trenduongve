export enum LoaiHinhPhapLy {
  CA_NHAN = 'CA_NHAN',
  HO_KINH_DOANH = 'HO_KINH_DOANH',
  DOANH_NGHIEP = 'DOANH_NGHIEP',
}

export interface LegalFieldRequirement {
  requireTaxCode: boolean;
  requireBusinessLicense: boolean;
  requireFoodSafetyCert: boolean;
  label: string;
}

// Single Source of Truth for legal requirements per business type
export const LEGAL_REQUIREMENTS: Record<LoaiHinhPhapLy, LegalFieldRequirement> = {
  [LoaiHinhPhapLy.CA_NHAN]: {
    requireTaxCode: true, // Cá nhân kinh doanh bắt buộc MST cá nhân
    requireBusinessLicense: false,
    requireFoodSafetyCert: false,
    label: 'Cá nhân kinh doanh',
  },
  [LoaiHinhPhapLy.HO_KINH_DOANH]: {
    requireTaxCode: true,
    requireBusinessLicense: true, // Hộ kinh doanh bắt buộc Số GĐKKD
    requireFoodSafetyCert: false,
    label: 'Hộ kinh doanh cá thể',
  },
  [LoaiHinhPhapLy.DOANH_NGHIEP]: {
    requireTaxCode: true,
    requireBusinessLicense: true,
    requireFoodSafetyCert: true, // Doanh nghiệp F&B bắt buộc chứng nhận ATTP
    label: 'Doanh nghiệp / Công ty',
  },
};

/**
 * Validate Vietnamese Tax Identification Number (MST)
 * 10 digits (personal/business) or 13 digits (10 digits + '-' + 3 digits for branches)
 */
export function validateMaSoThue(mst?: string | null): boolean {
  if (!mst) return false;
  const clean = mst.trim();
  const taxRegex = /^[0-9]{10}(-[0-9]{3})?$/;
  return taxRegex.test(clean);
}

