import React, { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { MapPin, Search, Navigation, ExternalLink, AlertTriangle, CheckCircle2 } from 'lucide-react';

interface MapLocationPickerProps {
  lat: number;
  lng: number;
  currentAddress?: string;
  onChange: (coords: { lat: number; lng: number }) => void;
}

export const MapLocationPicker: React.FC<MapLocationPickerProps> = ({
  lat,
  lng,
  currentAddress = '',
  onChange,
}) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markerRef = useRef<L.Marker | null>(null);

  const [searchQuery, setSearchQuery] = useState('');
  const [isSearching, setIsSearching] = useState(false);
  const [searchError, setSearchError] = useState<string | null>(null);

  // Default coordinate: District 1, Ho Chi Minh City if 0 or invalid
  const validLat = lat && lat !== 0 ? lat : 10.7769;
  const validLng = lng && lng !== 0 ? lng : 106.7009;

  // Check if coordinates belong to Ho Chi Minh City / Vietnam
  const isVietnam = validLat >= 8.5 && validLat <= 23.5 && validLng >= 102.0 && validLng <= 110.0;
  const isHCMC = validLat >= 10.3 && validLat <= 11.2 && validLng >= 106.3 && validLng <= 107.1;

  // Custom pulse pin icon
  const customPinIcon = L.divIcon({
    className: 'custom-map-pin',
    html: `
      <div style="position: relative; width: 34px; height: 34px; display: flex; align-items: center; justify-content: center;">
        <div style="position: absolute; width: 34px; height: 34px; border-radius: 50%; background: rgba(252, 96, 17, 0.25); animation: ping 1.5s cubic-bezier(0, 0, 0.2, 1) infinite;"></div>
        <div style="position: relative; width: 28px; height: 28px; background: #FC6011; border: 2.5px solid #ffffff; border-radius: 50%; box-shadow: 0 4px 10px rgba(0,0,0,0.3); display: flex; align-items: center; justify-content: center; color: white;">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"></path>
            <circle cx="12" cy="10" r="3"></circle>
          </svg>
        </div>
      </div>
    `,
    iconSize: [34, 34],
    iconAnchor: [17, 34],
  });

  // Initialize Leaflet map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current, {
        center: [validLat, validLng],
        zoom: lat && lng ? 16 : 14,
        zoomControl: true,
      });

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; OpenStreetMap contributors',
        maxZoom: 19,
      }).addTo(map);

      const marker = L.marker([validLat, validLng], {
        icon: customPinIcon,
        draggable: true,
      }).addTo(map);

      marker.on('dragend', () => {
        const pos = marker.getLatLng();
        onChange({
          lat: Number(pos.lat.toFixed(6)),
          lng: Number(pos.lng.toFixed(6)),
        });
      });

      map.on('click', (e: L.LeafletMouseEvent) => {
        const { lat: clickLat, lng: clickLng } = e.latlng;
        marker.setLatLng([clickLat, clickLng]);
        onChange({
          lat: Number(clickLat.toFixed(6)),
          lng: Number(clickLng.toFixed(6)),
        });
      });

      mapInstanceRef.current = map;
      markerRef.current = marker;
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
        markerRef.current = null;
      }
    };
  }, []);

  // Update map view & marker when lat/lng props change from outside
  useEffect(() => {
    if (!mapInstanceRef.current || !markerRef.current) return;
    if (lat && lng) {
      const curr = markerRef.current.getLatLng();
      if (Math.abs(curr.lat - lat) > 0.00001 || Math.abs(curr.lng - lng) > 0.00001) {
        markerRef.current.setLatLng([lat, lng]);
        mapInstanceRef.current.panTo([lat, lng], { animate: true });
      }
    }
  }, [lat, lng]);

  // Geocode address search function
  const handleSearchLocation = async (addressToSearch?: string) => {
    const rawTarget = (addressToSearch || searchQuery || currentAddress || '').trim();
    if (!rawTarget) {
      setSearchError('Vui lòng nhập tên đường, địa chỉ hoặc địa danh để tìm kiếm.');
      return;
    }

    setIsSearching(true);
    setSearchError(null);

    // Normalize query string: clean up punctuation for better OSM Nominatim matching
    const searchTarget = rawTarget
      .replace(/^(Việt Nam|TP\.?\s*Hồ Chí Minh|Hà Nội)[\s,]+/i, '')
      .trim();

    try {
      // 1. First try Nominatim OpenStreetMap
      const query = encodeURIComponent(`${searchTarget}, Việt Nam`);
      const res = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${query}&countrycodes=vn&limit=5`,
        { headers: { 'Accept-Language': 'vi,en' } }
      );
      const data = await res.json();

      let targetItem = null;
      if (Array.isArray(data) && data.length > 0) {
        targetItem = data[0];
      } else {
        // Fallback: search Photon OSM
        const photonRes = await fetch(
          `https://photon.komoot.io/api/?q=${encodeURIComponent(searchTarget)}&limit=3`
        );
        const photonData = await photonRes.json();
        if (photonData?.features?.length > 0) {
          const coords = photonData.features[0].geometry.coordinates;
          targetItem = { lat: coords[1], lon: coords[0] };
        }
      }

      if (targetItem) {
        const newLat = Number(parseFloat(targetItem.lat).toFixed(6));
        const newLng = Number(parseFloat(targetItem.lon).toFixed(6));

        onChange({ lat: newLat, lng: newLng });

        if (mapInstanceRef.current && markerRef.current) {
          markerRef.current.setLatLng([newLat, newLng]);
          mapInstanceRef.current.flyTo([newLat, newLng], 16, { duration: 1.2 });
        }
        setSearchError(null);
      } else {
        setSearchError(`Không tìm thấy vị trí khớp với "${rawTarget}". Hãy thử nhập tên đường chính.`);
      }
    } catch (err: any) {
      setSearchError('Lỗi kết nối khi tìm vị trí bản đồ. Vui lòng thử lại.');
    } finally {
      setIsSearching(false);
    }
  };

  // Get current device GPS location
  const handleGetCurrentGPS = () => {
    if (!navigator.geolocation) {
      setSearchError('Trình duyệt không hỗ trợ định vị GPS.');
      return;
    }

    setIsSearching(true);
    setSearchError(null);

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setIsSearching(false);
        const newLat = Number(pos.coords.latitude.toFixed(6));
        const newLng = Number(pos.coords.longitude.toFixed(6));

        onChange({ lat: newLat, lng: newLng });

        if (mapInstanceRef.current && markerRef.current) {
          markerRef.current.setLatLng([newLat, newLng]);
          mapInstanceRef.current.flyTo([newLat, newLng], 17, { duration: 1.2 });
        }
      },
      (err) => {
        setIsSearching(false);
        setSearchError(`Không thể lấy vị trí GPS: ${err.message}`);
      },
      { enableHighAccuracy: true, timeout: 10000 }
    );
  };

  return (
    <div style={{ marginTop: '14px', borderRadius: '10px', border: '1px solid #cbd5e1', overflow: 'hidden', background: '#ffffff' }}>
      {/* Map Control Header */}
      <div style={{ padding: '10px 14px', background: '#f1f5f9', borderBottom: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column', gap: '8px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '8px' }}>
          <div style={{ fontSize: '13px', fontWeight: 700, color: '#334155', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <MapPin size={16} color="#FC6011" /> Bấm trực tiếp trên bản đồ hoặc kéo ghim để chọn vị trí quán
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            {currentAddress && (
              <button
                type="button"
                onClick={() => handleSearchLocation(currentAddress)}
                disabled={isSearching}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '5px',
                  padding: '5px 10px',
                  fontSize: '12px',
                  fontWeight: 600,
                  color: '#0369a1',
                  background: '#e0f2fe',
                  border: '1px solid #bae6fd',
                  borderRadius: '6px',
                  cursor: isSearching ? 'not-allowed' : 'pointer',
                }}
                title="Tự động tìm kiếm tọa độ dựa theo địa chỉ bạn vừa nhập ở trên"
              >
                <MapPin size={13} /> Tìm theo địa chỉ quán
              </button>
            )}

            <button
              type="button"
              onClick={handleGetCurrentGPS}
              disabled={isSearching}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '5px',
                padding: '5px 10px',
                fontSize: '12px',
                fontWeight: 600,
                color: '#15803d',
                background: '#dcfce7',
                border: '1px solid #bbf7d0',
                borderRadius: '6px',
                cursor: isSearching ? 'not-allowed' : 'pointer',
              }}
              title="Lấy vị trí GPS hiện tại của thiết bị"
            >
              <Navigation size={13} /> GPS hiện tại
            </button>
          </div>
        </div>

        {/* Search input on map */}
        <div style={{ display: 'flex', gap: '6px' }}>
          <div style={{ position: 'relative', flex: 1 }}>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  handleSearchLocation();
                }
              }}
              placeholder="Gõ tên đường, chợ, tòa nhà để nhảy bản đồ đến đó (Ví dụ: 235 Nguyễn Trãi, Quận 1)..."
              style={{
                width: '100%',
                padding: '6px 10px 6px 32px',
                fontSize: '12.5px',
                borderRadius: '6px',
                border: '1px solid #cbd5e1',
                outline: 'none',
                background: '#ffffff',
              }}
            />
            <Search size={14} color="#64748b" style={{ position: 'absolute', left: '10px', top: '50%', transform: 'translateY(-50%)' }} />
          </div>

          <button
            type="button"
            onClick={() => handleSearchLocation()}
            disabled={isSearching}
            style={{
              padding: '6px 14px',
              fontSize: '12px',
              fontWeight: 600,
              color: '#ffffff',
              background: '#FC6011',
              border: 'none',
              borderRadius: '6px',
              cursor: isSearching ? 'not-allowed' : 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            {isSearching ? 'Đang tìm...' : 'Đến vị trí'}
          </button>
        </div>

        {searchError && (
          <div style={{ fontSize: '11.5px', color: '#dc2626', background: '#fee2e2', padding: '4px 8px', borderRadius: '4px' }}>
            {searchError}
          </div>
        )}
      </div>

      {/* Leaflet Map Canvas */}
      <div
        ref={mapContainerRef}
        style={{
          width: '100%',
          height: '280px',
          background: '#e2e8f0',
          position: 'relative',
          zIndex: 1,
        }}
      />

      {/* Status & Validation Bar below map */}
      <div style={{ padding: '8px 12px', background: '#f8fafc', borderTop: '1px solid #e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: '6px', fontSize: '12px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          {isHCMC ? (
            <span style={{ color: '#16a34a', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 600 }}>
              <CheckCircle2 size={14} /> Tọa độ hợp lệ tại TP. Hồ Chí Minh
            </span>
          ) : isVietnam ? (
            <span style={{ color: '#0284c7', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 600 }}>
              <CheckCircle2 size={14} /> Tọa độ hợp lệ tại Việt Nam
            </span>
          ) : (
            <span style={{ color: '#dc2626', display: 'flex', alignItems: 'center', gap: '4px', fontWeight: 700 }}>
              <AlertTriangle size={14} /> Cảnh báo: Tọa độ đang nằm ngoài lãnh thổ Việt Nam!
            </span>
          )}
          <span style={{ color: '#64748b' }}>({validLat}, {validLng})</span>
        </div>

        <a
          href={`https://www.google.com/maps?q=${validLat},${validLng}`}
          target="_blank"
          rel="noopener noreferrer"
          style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#FC6011', textDecoration: 'none', fontWeight: 600 }}
        >
          Kiểm tra trên Google Maps <ExternalLink size={12} />
        </a>
      </div>
    </div>
  );
};
