import React, { useRef } from 'react';
import { Calendar } from 'lucide-react';

interface DatePickerInputProps {
  label?: string;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  required?: boolean;
  disabled?: boolean;
}

export const DatePickerInput: React.FC<DatePickerInputProps> = ({
  label,
  value,
  onChange,
  placeholder = 'dd/mm/yyyy (VD: 10/05/2004)',
  required = false,
  disabled = false,
}) => {
  const dateInputRef = useRef<HTMLInputElement>(null);

  // Helper to convert DD/MM/YYYY to YYYY-MM-DD for <input type="date">
  const getIsoValue = (val: string): string => {
    if (!val) return '';
    if (/^\d{4}-\d{2}-\d{2}/.test(val)) return val.split('T')[0];
    const parts = val.split('/');
    if (parts.length === 3) {
      const [d, m, y] = parts;
      if (y.length === 4 && d.length <= 2 && m.length <= 2) {
        return `${y}-${m.padStart(2, '0')}-${d.padStart(2, '0')}`;
      }
    }
    return '';
  };

  // Helper to convert YYYY-MM-DD back to DD/MM/YYYY for text display
  const formatVnDate = (isoVal: string): string => {
    if (!isoVal) return '';
    const parts = isoVal.split('-');
    if (parts.length === 3) {
      const [y, m, d] = parts;
      return `${d.padStart(2, '0')}/${m.padStart(2, '0')}/${y}`;
    }
    return isoVal;
  };

  const handleCalendarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const rawIso = e.target.value; // "YYYY-MM-DD"
    if (rawIso) {
      const formatted = formatVnDate(rawIso);
      onChange(formatted);
    }
  };

  const openCalendar = () => {
    if (dateInputRef.current) {
      if ('showPicker' in HTMLInputElement.prototype) {
        try {
          dateInputRef.current.showPicker();
        } catch (_) {
          dateInputRef.current.focus();
        }
      } else {
        dateInputRef.current.focus();
        dateInputRef.current.click();
      }
    }
  };

  return (
    <div className="form-group" style={{ marginBottom: '14px' }}>
      {label && <label className="form-label">{label}</label>}
      <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
        <input
          type="text"
          className="form-control"
          placeholder={placeholder}
          value={value || ''}
          onChange={(e) => onChange(e.target.value)}
          required={required}
          disabled={disabled}
          style={{ paddingRight: '42px' }}
        />

        {/* Hidden HTML5 date picker input positioned over button */}
        <input
          ref={dateInputRef}
          type="date"
          value={getIsoValue(value)}
          onChange={handleCalendarChange}
          disabled={disabled}
          style={{
            position: 'absolute',
            right: '8px',
            opacity: 0,
            width: '30px',
            height: '30px',
            cursor: 'pointer',
            zIndex: 2,
          }}
        />

        {/* Visible Calendar Icon Button */}
        <button
          type="button"
          onClick={openCalendar}
          disabled={disabled}
          title="Chọn ngày từ lịch"
          style={{
            position: 'absolute',
            right: '8px',
            background: 'none',
            border: 'none',
            color: '#64748b',
            cursor: 'pointer',
            padding: '4px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            borderRadius: '6px',
            transition: 'all 0.2s',
            zIndex: 1,
          }}
        >
          <Calendar size={18} color="#fc6011" />
        </button>
      </div>
    </div>
  );
};
