import React, { useState, useEffect, useRef } from 'react';
import { MapPin, Globe, Building2, Home } from 'lucide-react';

export interface LocationSelectorProps {
  label?: string;
  value: string;
  onChange: (fullAddress: string) => void;
  required?: boolean;
}

const COUNTRIES = ['Việt Nam', 'Hoa Kỳ (USA)', 'Nhật Bản (Japan)', 'Hàn Quốc (South Korea)', 'Khác / Quốc tế'];

const PROVINCES_VN = [
  'TP. Hồ Chí Minh',
  'Hà Nội',
  'Đà Nẵng',
  'Bình Dương',
  'Đồng Nai',
  'Cần Thơ',
  'Hải Phòng',
  'An Giang',
  'Bà Rịa - Vũng Tàu',
  'Bắc Giang',
  'Bắc Ninh',
  'Bến Tre',
  'Bình Định',
  'Bình Thuận',
  'Cà Mau',
  'Đắk Lắk',
  'Đồng Tháp',
  'Gia Lai',
  'Hải Dương',
  'Khánh Hòa',
  'Kiên Giang',
  'Lâm Đồng',
  'Long An',
  'Nam Định',
  'Nghệ An',
  'Ninh Bình',
  'Phú Thọ',
  'Quảng Nam',
  'Quảng Ninh',
  'Quảng Trị',
  'Sóc Trăng',
  'Tây Ninh',
  'Thái Nguyên',
  'Thanh Hóa',
  'Thừa Thiên Huế',
  'Tiền Giang',
  'Vĩnh Long',
  'Vĩnh Phúc',
];

const DISTRICTS_WARDS_MAP: Record<string, string[]> = {
  'TP. Hồ Chí Minh': [
    'Phường Bến Nghé (Quận 1)',
    'Phường Bến Thành (Quận 1)',
    'Phường Đa Kao (Quận 1)',
    'Phường Tân Định (Quận 1)',
    'Phường Nguyễn Cư Trinh (Quận 1)',
    'Phường Thảo Điền (TP. Thủ Đức)',
    'Phường An Phú (TP. Thủ Đức)',
    'Phường Hiệp Bình Chánh (TP. Thủ Đức)',
    'Phường Linh Trung (TP. Thủ Đức)',
    'Phường Võ Thị Sáu (Quận 3)',
    'Phường 1 (Quận 3)',
    'Phường 2 (Quận 5)',
    'Phường Tân Phong (Quận 7)',
    'Phường 12 (Quận 10)',
    'Phường 25 (Quận Bình Thạnh)',
    'Phường 5 (Quận Gò Vấp)',
    'Phường 2 (Quận Tân Bình)',
    'Phường 14 (Quận Tân Phú)',
    'Xã Bình Hưng (Huyện Bình Chánh)',
    'Xã Tân Thạnh Đông (Huyện Củ Chi)',
    'Xã Bà Điểm (Huyện Hóc Môn)',
    'Khác / Tự nhập',
  ],
  'Hà Nội': [
    'Phường Hàng Bạc (Quận Hoàn Kiếm)',
    'Phường Tràng Tiền (Quận Hoàn Kiếm)',
    'Phường Dịch Vọng (Quận Cầu Giấy)',
    'Phường Yên Hòa (Quận Cầu Giấy)',
    'Phường Điện Biên (Quận Ba Đình)',
    'Phường Kim Liên (Quận Đống Đa)',
    'Phường Bách Khoa (Quận Hai Bà Trưng)',
    'Phường Mỹ Đình 1 (Quận Nam Từ Liêm)',
    'Phường Văn Quán (Quận Hà Đông)',
    'Khác / Tự nhập',
  ],
  'Đà Nẵng': [
    'Phường Hải Châu 1 (Quận Hải Châu)',
    'Phường Thạch Thang (Quận Hải Châu)',
    'Phường Phước Mỹ (Quận Sơn Trà)',
    'Phường Hòa Khánh Bắc (Quận Liên Chiểu)',
    'Phường Khuê Mỹ (Quận Ngũ Hành Sơn)',
    'Khác / Tự nhập',
  ],
  'Bình Dương': [
    'Phường Phú Hòa (TP. Thủ Dầu Một)',
    'Phường Dĩ An (TP. Dĩ An)',
    'Phường Lái Thiêu (TP. Thuận An)',
    'Phường Bến Cát (TP. Bến Cát)',
    'Khác / Tự nhập',
  ],
  'Đồng Nai': [
    'Phường Tân Phong (TP. Biên Hòa)',
    'Phường Trảng Dài (TP. Biên Hòa)',
    'Phường Quyết Thắng (TP. Biên Hòa)',
    'Phường Long Bình (TP. Biên Hòa)',
    'Khác / Tự nhập',
  ],
};

const DEFAULT_WARDS = [
  'Phường Trung Tâm',
  'Phường 1',
  'Phường 2',
  'Phường 3',
  'Phường Tân Thành',
  'Xã Bình Minh',
  'Khác / Tự nhập',
];

export const LocationSelector: React.FC<LocationSelectorProps> = ({
  label = 'Địa Chỉ (Phân Cấp / Cascading Dropdown)',
  value,
  onChange,
  required = false,
}) => {
  const [country, setCountry] = useState<string>('Việt Nam');
  const [province, setProvince] = useState<string>('');
  const [ward, setWard] = useState<string>('');
  const [customWard, setCustomWard] = useState<string>('');
  const [street, setStreet] = useState<string>('');

  const lastPropValue = useRef<string>('');

  // Parse existing address string when value is supplied externally (e.g. via AI Scan or initial load)
  useEffect(() => {
    if (value === lastPropValue.current) return;
    lastPropValue.current = value || '';

    if (!value || typeof value !== 'string' || !value.trim()) {
      setCountry('Việt Nam');
      setProvince('');
      setWard('');
      setCustomWard('');
      setStreet('');
      return;
    }

    const parts = value.split(',').map((s) => s.trim()).filter(Boolean);
    if (parts.length === 0) {
      setCountry('Việt Nam');
      setProvince('');
      setWard('');
      setCustomWard('');
      setStreet('');
      return;
    }

    let parsedCountry = 'Việt Nam';
    let parsedProvince = '';
    let parsedWard = '';
    let parsedStreet = '';

    const remainingParts = [...parts];

    // 1. Check if last part is Country
    if (remainingParts.length > 0) {
      const lastPart = remainingParts[remainingParts.length - 1];
      const matchedCountry = COUNTRIES.find(
        (c) => c.toLowerCase() === lastPart.toLowerCase() || c.toLowerCase().includes(lastPart.toLowerCase()) || lastPart.toLowerCase().includes(c.toLowerCase())
      );
      if (matchedCountry) {
        parsedCountry = matchedCountry;
        remainingParts.pop();
      }
    }

    // 2. Check if current last part is Province
    if (remainingParts.length > 0) {
      const lastPart = remainingParts[remainingParts.length - 1];
      const matchedProvince = PROVINCES_VN.find(
        (p) => p.toLowerCase() === lastPart.toLowerCase() || p.toLowerCase().includes(lastPart.toLowerCase()) || lastPart.toLowerCase().includes(p.toLowerCase())
      );
      if (matchedProvince) {
        parsedProvince = matchedProvince;
        remainingParts.pop();
      }
    }

    // 3. Check if current last part is Ward (if there are still at least 2 parts left, or if it matches ward list)
    if (remainingParts.length > 0) {
      const lastPart = remainingParts[remainingParts.length - 1];
      const availableWards = parsedProvince ? (DISTRICTS_WARDS_MAP[parsedProvince] || DEFAULT_WARDS) : [];
      const matchedWard = availableWards.find(
        (w) => w.toLowerCase() === lastPart.toLowerCase() || w.toLowerCase().includes(lastPart.toLowerCase())
      );

      // If remaining parts has >= 2 parts left, then the part right before province is ward
      if (remainingParts.length >= 2 || matchedWard) {
        parsedWard = lastPart;
        remainingParts.pop();
      }
    }

    // 4. Remaining parts constitute the street address
    parsedStreet = remainingParts.join(', ');

    setCountry(parsedCountry);
    setProvince(parsedProvince);

    if (parsedWard) {
      const availableWards = parsedProvince ? (DISTRICTS_WARDS_MAP[parsedProvince] || DEFAULT_WARDS) : DEFAULT_WARDS;
      if (availableWards.includes(parsedWard)) {
        setWard(parsedWard);
        setCustomWard('');
      } else {
        setWard('Khác / Tự nhập');
        setCustomWard(parsedWard);
      }
    } else {
      setWard('');
      setCustomWard('');
    }

    setStreet(parsedStreet);
  }, [value]);

  // Helper to compile and trigger onChange
  const updateFullAddress = (
    newCountry: string,
    newProvince: string,
    newWard: string,
    newCustomWard: string,
    newStreet: string
  ) => {
    const finalWard = newWard === 'Khác / Tự nhập' ? newCustomWard : newWard;
    const components = [];
    if (newStreet.trim()) components.push(newStreet.trim());
    if (finalWard.trim()) components.push(finalWard.trim());
    if (newProvince.trim()) components.push(newProvince.trim());
    if (newCountry.trim()) components.push(newCountry.trim());

    const fullStr = components.join(', ');
    lastPropValue.current = fullStr;
    onChange(fullStr);
  };

  const handleCountryChange = (c: string) => {
    setCountry(c);
    setProvince('');
    setWard('');
    setCustomWard('');
    updateFullAddress(c, '', '', '', street);
  };

  const handleProvinceChange = (p: string) => {
    setProvince(p);
    setWard('');
    setCustomWard('');
    updateFullAddress(country, p, '', '', street);
  };

  const handleWardChange = (w: string) => {
    setWard(w);
    updateFullAddress(country, province, w, customWard, street);
  };

  const handleCustomWardChange = (cw: string) => {
    setCustomWard(cw);
    updateFullAddress(country, province, ward, cw, street);
  };

  const handleStreetChange = (s: string) => {
    setStreet(s);
    updateFullAddress(country, province, ward, customWard, s);
  };

  const currentWards = DISTRICTS_WARDS_MAP[province] || DEFAULT_WARDS;

  return (
    <div
      style={{
        background: '#f8fafc',
        border: '1px solid #e2e8f0',
        borderRadius: '10px',
        padding: '14px',
        marginBottom: '16px',
      }}
    >
      <div
        style={{
          fontSize: '13px',
          fontWeight: 700,
          color: '#334155',
          marginBottom: '10px',
          display: 'flex',
          alignItems: 'center',
          gap: '6px',
        }}
      >
        <MapPin size={15} color="#fc6011" /> {label}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '10px' }}>
        {/* 1. Quốc gia */}
        <div>
          <label style={{ fontSize: '11px', fontWeight: 600, color: '#64748b', display: 'flex', alignItems: 'center', gap: '4px', marginBottom: '4px' }}>
            <Globe size={12} /> Quốc Gia
          </label>
          <select
            className="form-control"
            value={country}
            onChange={(e) => handleCountryChange(e.target.value)}
            required={required}
            style={{ fontSize: '13px' }}
          >
            {COUNTRIES.map((c) => (
              <option key={c} value={c}>{c}</option>
            ))}
          </select>
        </div>

        {/* 2. Tỉnh / Thành phố */}
        <div>
          <label style={{ fontSize: '11px', fontWeight: 600, color: '#64748b', display: 'flex', alignItems: 'center', gap: '4px', marginBottom: '4px' }}>
            <Building2 size={12} /> Tỉnh / Thành Phố
          </label>
          <select
            className="form-control"
            value={province}
            onChange={(e) => handleProvinceChange(e.target.value)}
            disabled={country !== 'Việt Nam'}
            required={required && country === 'Việt Nam'}
            style={{ fontSize: '13px' }}
          >
            <option value="">-- Chọn Tỉnh/Thành phố --</option>
            {PROVINCES_VN.map((p) => (
              <option key={p} value={p}>{p}</option>
            ))}
          </select>
        </div>
      </div>

      {/* 3. Phường / Xã / Quận / Huyện */}
      <div style={{ marginBottom: '10px' }}>
        <label style={{ fontSize: '11px', fontWeight: 600, color: '#64748b', display: 'flex', alignItems: 'center', gap: '4px', marginBottom: '4px' }}>
          <MapPin size={12} /> Phường / Xã / Quận / Huyện
        </label>
        <select
          className="form-control"
          value={ward}
          onChange={(e) => handleWardChange(e.target.value)}
          disabled={!province && country === 'Việt Nam'}
          style={{ fontSize: '13px' }}
        >
          <option value="">-- Chọn Phường/Xã hoặc Quận/Huyện --</option>
          {currentWards.map((w) => (
            <option key={w} value={w}>{w}</option>
          ))}
        </select>
      </div>

      {/* Tự nhập Phường/Xã nếu chọn Khác */}
      {ward === 'Khác / Tự nhập' && (
        <div style={{ marginBottom: '10px' }}>
          <input
            type="text"
            className="form-control"
            placeholder="Nhập Phường/Xã, Quận/Huyện cụ thể..."
            value={customWard}
            onChange={(e) => handleCustomWardChange(e.target.value)}
            style={{ fontSize: '13px' }}
          />
        </div>
      )}

      {/* 4. Số nhà / Tên đường */}
      <div>
        <label style={{ fontSize: '11px', fontWeight: 600, color: '#64748b', display: 'flex', alignItems: 'center', gap: '4px', marginBottom: '4px' }}>
          <Home size={12} /> Số Nhà / Tên Đường / Tòa Nhà
        </label>
        <input
          type="text"
          className="form-control"
          placeholder="VD: 123 Nguyễn Huệ, Tòa nhà Bitexco..."
          value={street}
          onChange={(e) => handleStreetChange(e.target.value)}
          style={{ fontSize: '13px' }}
        />
      </div>

      {/* Chuỗi Địa Chỉ Hoàn Chỉnh */}
      <div style={{ marginTop: '8px', fontSize: '11px', color: '#64748b', fontStyle: 'italic' }}>
        📍 Địa chỉ đầy đủ: <strong>{street || ward || province ? `${street ? street + ', ' : ''}${ward && ward !== 'Khác / Tự nhập' ? ward + ', ' : customWard ? customWard + ', ' : ''}${province ? province + ', ' : ''}${country}` : 'Chưa nhập'}</strong>
      </div>
    </div>
  );
};
