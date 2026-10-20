import React, { useState, useEffect, useRef } from 'react';
import { fetchVietQRBanks, BankItem } from '../utils/bankService';
import { Building2, ChevronDown, Search, Check } from 'lucide-react';

interface BankSelectorProps {
  label?: string;
  value: string;
  onChange: (bankName: string, bankLogo?: string) => void;
}

export const BankSelector: React.FC<BankSelectorProps> = ({
  label = 'Tên Ngân Hàng',
  value,
  onChange,
}) => {
  const [banks, setBanks] = useState<BankItem[]>([]);
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchVietQRBanks().then((data) => setBanks(data));
  }, []);

  // Close dropdown on outside click
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Find currently selected bank object
  const selectedBank = banks.find((b) => {
    if (!value) return false;
    const vLower = value.toLowerCase();
    return (
      b.code.toLowerCase() === vLower ||
      b.shortName.toLowerCase() === vLower ||
      vLower.includes(b.code.toLowerCase()) ||
      vLower.includes(b.shortName.toLowerCase())
    );
  });

  const filteredBanks = banks.filter((b) => {
    const q = search.toLowerCase().trim();
    if (!q) return true;
    return (
      b.shortName.toLowerCase().includes(q) ||
      b.code.toLowerCase().includes(q) ||
      b.name.toLowerCase().includes(q)
    );
  });

  const handleSelectBank = (b: BankItem) => {
    const valStr = `${b.shortName} (${b.code})`;
    onChange(valStr, b.logo);
    setIsOpen(false);
  };

  return (
    <div className="form-group" style={{ position: 'relative' }} ref={dropdownRef}>
      <label className="form-label">{label}</label>

      {/* Select Input Trigger Box */}
      <div
        onClick={() => setIsOpen(!isOpen)}
        className="form-control"
        style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          cursor: 'pointer',
          background: '#ffffff',
          minHeight: '42px',
          padding: '6px 12px',
          border: isOpen ? '1px solid #fc6011' : '1px solid #cbd5e1',
          boxShadow: isOpen ? '0 0 0 3px rgba(252, 96, 17, 0.15)' : 'none',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', overflow: 'hidden' }}>
          {selectedBank && selectedBank.logo ? (
            <img
              src={selectedBank.logo}
              alt={selectedBank.shortName}
              style={{ width: '32px', height: '20px', objectFit: 'contain' }}
              onError={(e) => {
                (e.target as HTMLImageElement).style.display = 'none';
              }}
            />
          ) : (
            <Building2 size={18} color="#fc6011" />
          )}
          <span style={{ fontWeight: 600, color: value ? '#0f172a' : '#94a3b8', fontSize: '13px' }}>
            {value || '-- Chọn Ngân Hàng --'}
          </span>
        </div>

        <ChevronDown size={16} color="#64748b" style={{ transform: isOpen ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }} />
      </div>

      {/* Popover Dropdown List */}
      {isOpen && (
        <div
          style={{
            position: 'absolute',
            top: '100%',
            left: 0,
            right: 0,
            zIndex: 1050,
            marginTop: '4px',
            background: '#ffffff',
            borderRadius: '12px',
            border: '1px solid #cbd5e1',
            boxShadow: '0 10px 25px -5px rgba(0,0,0,0.15), 0 8px 10px -6px rgba(0,0,0,0.1)',
            overflow: 'hidden',
          }}
        >
          {/* Search Box */}
          <div style={{ padding: '8px', borderBottom: '1px solid #f1f5f9', background: '#f8fafc' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px', background: '#ffffff', border: '1px solid #cbd5e1', borderRadius: '8px', padding: '4px 10px' }}>
              <Search size={14} color="#64748b" />
              <input
                type="text"
                placeholder="Tìm ngân hàng (VD: VCB, Vietinbank, MB...)"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                style={{ border: 'none', outline: 'none', width: '100%', fontSize: '12px', background: 'transparent' }}
                autoFocus
              />
            </div>
          </div>

          {/* Banks Items List */}
          <div style={{ maxHeight: '240px', overflowY: 'auto' }}>
            {filteredBanks.length === 0 ? (
              <div style={{ padding: '16px', textAlign: 'center', fontSize: '12px', color: '#94a3b8' }}>
                Không tìm thấy ngân hàng nào
              </div>
            ) : (
              filteredBanks.map((b) => {
                const isSelected = selectedBank?.code === b.code;
                return (
                  <div
                    key={b.id}
                    onClick={() => handleSelectBank(b)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      padding: '8px 12px',
                      cursor: 'pointer',
                      background: isSelected ? '#fff7ed' : 'transparent',
                      borderBottom: '1px solid #f8fafc',
                      transition: 'background 0.15s',
                    }}
                    onMouseEnter={(e) => {
                      if (!isSelected) e.currentTarget.style.background = '#f1f5f9';
                    }}
                    onMouseLeave={(e) => {
                      if (!isSelected) e.currentTarget.style.background = 'transparent';
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                      {b.logo ? (
                        <img
                          src={b.logo}
                          alt={b.shortName}
                          style={{ width: '36px', height: '24px', objectFit: 'contain', background: '#ffffff', borderRadius: '4px', border: '1px solid #e2e8f0', padding: '2px' }}
                        />
                      ) : (
                        <Building2 size={16} color="#64748b" />
                      )}
                      <div>
                        <div style={{ fontWeight: 700, fontSize: '13px', color: isSelected ? '#fc6011' : '#0f172a' }}>
                          {b.shortName} <span style={{ fontSize: '11px', color: '#64748b' }}>({b.code})</span>
                        </div>
                        <div style={{ fontSize: '11px', color: '#64748b', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', maxWidth: '280px' }}>
                          {b.name}
                        </div>
                      </div>
                    </div>

                    {isSelected && <Check size={16} color="#fc6011" />}
                  </div>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
};
