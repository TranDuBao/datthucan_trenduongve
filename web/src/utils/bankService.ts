// VietQR Official API Integration Service for Bank Selection

export interface BankItem {
  id: number;
  name: string;
  code: string;
  shortName: string;
  bin: string;
  logo: string;
  displayName: string;
}

let cachedBanks: BankItem[] = [];

export async function fetchVietQRBanks(): Promise<BankItem[]> {
  if (cachedBanks.length > 0) {
    return cachedBanks;
  }

  try {
    const res = await fetch('https://api.vietqr.io/v2/banks');
    if (!res.ok) throw new Error('Không thể kết nối API VietQR');
    const json = await res.json();
    if (json.data && Array.isArray(json.data) && json.data.length > 0) {
      cachedBanks = json.data.map((b: any) => ({
        id: b.id,
        name: b.name,
        code: b.code,
        shortName: b.shortName || b.name,
        bin: b.bin,
        logo: b.logo,
        displayName: b.shortName
          ? `${b.shortName} (${b.code}) - ${b.name}`
          : `${b.name} (${b.code})`,
      }));
      return cachedBanks;
    }
  } catch (err) {
    console.warn('⚡ Lỗi gọi API VietQR Banks, chuyển sang danh sách ngân hàng chuẩn:', err);
  }

  // Fallback complete Vietnamese banks list if offline/network restriction
  cachedBanks = [
    { id: 1, name: 'Ngân hàng Ngoại Thương Việt Nam', code: 'VCB', shortName: 'Vietcombank', bin: '970436', logo: '', displayName: 'Vietcombank (VCB) - Ngân hàng Ngoại Thương' },
    { id: 2, name: 'Ngân hàng TMCP Công Thương Việt Nam', code: 'ICB', shortName: 'VietinBank', bin: '970415', logo: '', displayName: 'VietinBank (ICB) - Ngân hàng Công Thương' },
    { id: 3, name: 'Ngân hàng Đầu tư và Phát triển Việt Nam', code: 'BIDV', shortName: 'BIDV', bin: '970418', logo: '', displayName: 'BIDV (BIDV) - Ngân hàng Đầu tư và Phát triển' },
    { id: 4, name: 'Ngân hàng Nông nghiệp và Phát triển Nông thôn Việt Nam', code: 'VBA', shortName: 'Agribank', bin: '970405', logo: '', displayName: 'Agribank (VBA) - Ngân hàng Nông nghiệp' },
    { id: 5, name: 'Ngân hàng TMCP Quân Đội', code: 'MB', shortName: 'MBBank', bin: '970422', logo: '', displayName: 'MBBank (MB) - Ngân hàng Quân Đội' },
    { id: 6, name: 'Ngân hàng TMCP Kỹ Thương Việt Nam', code: 'TCB', shortName: 'Techcombank', bin: '970407', logo: '', displayName: 'Techcombank (TCB) - Ngân hàng Kỹ Thương' },
    { id: 7, name: 'Ngân hàng TMCP Á Châu', code: 'ACB', shortName: 'ACB', bin: '970416', logo: '', displayName: 'ACB (ACB) - Ngân hàng Á Châu' },
    { id: 8, name: 'Ngân hàng TMCP Việt Nam Thịnh Vượng', code: 'VPB', shortName: 'VPBank', bin: '970432', logo: '', displayName: 'VPBank (VPB) - Ngân hàng Việt Nam Thịnh Vượng' },
    { id: 9, name: 'Ngân hàng TMCP Tiên Phong', code: 'TPB', shortName: 'TPBank', bin: '970423', logo: '', displayName: 'TPBank (TPB) - Ngân hàng Tiên Phong' },
    { id: 10, name: 'Ngân hàng TMCP Sài Gòn Thương Tín', code: 'STB', shortName: 'Sacombank', bin: '970403', logo: '', displayName: 'Sacombank (STB) - Ngân hàng Sài Gòn Thương Tín' },
    { id: 11, name: 'Ngân hàng TMCP Quốc Tế Việt Nam', code: 'VIB', shortName: 'VIB', bin: '970441', logo: '', displayName: 'VIB (VIB) - Ngân hàng Quốc Tế' },
    { id: 12, name: 'Ngân hàng TMCP Phát Triển TP.HCM', code: 'HDB', shortName: 'HDBank', bin: '970437', logo: '', displayName: 'HDBank (HDB) - Ngân hàng Phát Triển TP.HCM' },
    { id: 13, name: 'Ngân hàng TMCP Sài Gòn Hà Nội', code: 'SHB', shortName: 'SHB', bin: '970443', logo: '', displayName: 'SHB (SHB) - Ngân hàng Sài Gòn Hà Nội' },
    { id: 14, name: 'Ngân hàng TMCP Hàng Hải Việt Nam', code: 'MSB', shortName: 'MSB', bin: '970426', logo: '', displayName: 'MSB (MSB) - Ngân hàng Hàng Hải' },
  ];

  return cachedBanks;
}
