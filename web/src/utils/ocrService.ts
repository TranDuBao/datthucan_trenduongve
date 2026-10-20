// Tesseract.js dynamic loader & Intelligent CCCD OCR Parser

const loadTesseract = (): Promise<any> => {
  return new Promise((resolve, reject) => {
    if ((window as any).Tesseract) {
      return resolve((window as any).Tesseract);
    }
    const script = document.createElement('script');
    script.src = 'https://cdn.jsdelivr.net/npm/tesseract.js@5/dist/tesseract.min.js';
    script.async = true;
    script.onload = () => {
      if ((window as any).Tesseract) {
        resolve((window as any).Tesseract);
      } else {
        reject(new Error('Tesseract script loaded but Tesseract object missing'));
      }
    };
    script.onerror = () => reject(new Error('Không thể tải thư viện Tesseract.js từ CDN'));
    document.head.appendChild(script);
  });
};

export interface OcrResult {
  soCCCD: string;
  hoTen: string;
  ngaySinh: string;
  diaChiThuongTru: string;
}

export async function parseCCCDImage(frontBase64?: string, backBase64?: string): Promise<OcrResult> {
  let combinedText = '';

  try {
    const Tesseract = await loadTesseract();
    const worker = await Tesseract.createWorker('vie+eng');

    if (frontBase64 && frontBase64.startsWith('data:image')) {
      const resFront = await worker.recognize(frontBase64);
      combinedText += '\n' + (resFront.data.text || '');
    }

    if (backBase64 && backBase64.startsWith('data:image')) {
      const resBack = await worker.recognize(backBase64);
      combinedText += '\n' + (resBack.data.text || '');
    }

    await worker.terminate();
  } catch (err) {
    console.warn('⚡ Tesseract OCR fallback to pattern analysis:', err);
  }

  const rawData = combinedText;

  // 1. Extract 12-digit CCCD Number
  let soCCCD = '';
  const numMatch = rawData.match(/\b(0\d{11})\b/) || rawData.match(/\b(\d{12})\b/);
  if (numMatch && numMatch[1]) {
    soCCCD = numMatch[1];
  } else {
    const spacedMatch = rawData.match(/\b(\d{3}\s?\d{3}\s?\d{6})\b/);
    if (spacedMatch && spacedMatch[1]) {
      soCCCD = spacedMatch[1].replace(/\s+/g, '');
    }
  }

  // 2. Extract Full Name (Họ và tên)
  let hoTen = '';
  const nameLabelMatch = combinedText.match(/(?:Họ và tên|Ho va ten|Full name|Họ tên)[:\s]+([A-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚƯĐẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪỬỮỰỲỴÝỶỸ\s]{3,40})/i);
  if (nameLabelMatch && nameLabelMatch[1]) {
    hoTen = nameLabelMatch[1].trim();
  } else {
    const lines = combinedText.split('\n').map((l) => l.trim());
    for (const line of lines) {
      if (
        /^[A-ZÀÁÂÃÈÉÊÌÍÒÓÔÕÙÚƯĐẠẢẤẦẨẪẬẮẰẲẴẶẸẺẼỀỀỂỄỆỈỊỌỎỐỒỔỖỘỚỜỞỠỢỤỦỨỪỬỮỰỲỴÝỶỸ\s]{4,40}$/.test(line) &&
        !line.includes('CỘNG HÒA') &&
        !line.includes('XÃ HỘI') &&
        !line.includes('ĐỘC LẬP') &&
        !line.includes('TỰ DO') &&
        !line.includes('CĂN CƯỚC') &&
        !line.includes('VIỆT NAM') &&
        !line.includes('GIỚI TÍNH') &&
        !line.includes('QUỐC TỊCH') &&
        !line.includes('QUÊ QUÁN') &&
        !line.includes('THƯỜNG TRÚ')
      ) {
        hoTen = line;
        break;
      }
    }
  }

  // 3. Extract Date of Birth (Ngày sinh)
  let ngaySinh = '';
  const dobMatch =
    combinedText.match(/(?:Ngày sinh|Ngay sinh|Date of birth)[:\s]+(\d{2})[\/\-\.](\d{2})[\/\-\.](\d{4})/i) ||
    combinedText.match(/\b(\d{2})[\/\-\.](\d{2})[\/\-\.](\d{4})\b/);
  if (dobMatch) {
    const d = dobMatch[1];
    const m = dobMatch[2];
    const y = dobMatch[3];
    ngaySinh = `${y}-${m}-${d}`;
  }

  // 4. Extract Residence Address (Địa chỉ thường trú)
  let diaChiThuongTru = '';
  const addrMatch = combinedText.match(/(?:Thường trú|Nơi thường trú|Noi thuong tru|Place of residence)[:\s]+([^\n]+)/i);
  if (addrMatch && addrMatch[1]) {
    diaChiThuongTru = addrMatch[1].trim();
  }

  return {
    soCCCD,
    hoTen,
    ngaySinh,
    diaChiThuongTru,
  };
}

export function formatDateVN(str: string): string {
  if (!str) return '';
  if (/^\d{4}-\d{2}-\d{2}/.test(str)) {
    const [y, m, d] = str.split('T')[0].split('-');
    return `${d}/${m}/${y}`;
  }
  if (/^\d{2}\/\d{2}\/\d{4}$/.test(str)) {
    return str;
  }
  const date = new Date(str);
  if (isNaN(date.getTime())) return str;
  const d = String(date.getDate()).padStart(2, '0');
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const y = date.getFullYear();
  return `${d}/${m}/${y}`;
}

export function toISODate(str: string): string | null {
  if (!str || !str.trim()) return null;
  if (/^\d{4}-\d{2}-\d{2}/.test(str)) return str.split('T')[0];
  const parts = str.split(/[\/\-\.]/);
  if (parts.length === 3) {
    let [d, m, y] = parts;
    if (d.length === 4) {
      return `${d}-${m.padStart(2, '0')}-${y.padStart(2, '0')}`;
    }
    return `${y.padStart(4, '20')}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`;
  }
  return null;
}

