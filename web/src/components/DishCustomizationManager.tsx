import React, { useState } from 'react';
import { Layers, Plus, Trash2, CheckCircle2, Sparkles, Coffee, Utensils, RotateCcw } from 'lucide-react';

export interface DishOptionItem {
  name: string;
  extra: number;
}

interface DishCustomizationManagerProps {
  sizes: DishOptionItem[];
  toppings: DishOptionItem[];
  onChangeSizes: (sizes: DishOptionItem[]) => void;
  onChangeToppings: (toppings: DishOptionItem[]) => void;
}

export const DishCustomizationManager: React.FC<DishCustomizationManagerProps> = ({
  sizes,
  toppings,
  onChangeSizes,
  onChangeToppings,
}) => {
  // New size input state
  const [newSizeName, setNewSizeName] = useState('');
  const [newSizeExtra, setNewSizeExtra] = useState('');

  // New topping input state
  const [newToppingName, setNewToppingName] = useState('');
  const [newToppingExtra, setNewToppingExtra] = useState('');

  const formatVND = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount);
  };

  // ── SIZES CRUD ──
  const handleAddSize = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const name = newSizeName.trim();
    if (!name) return;
    const extra = Math.max(0, parseInt(newSizeExtra, 10) || 0);

    onChangeSizes([...sizes, { name, extra }]);
    setNewSizeName('');
    setNewSizeExtra('');
  };

  const handleUpdateSize = (index: number, field: 'name' | 'extra', value: any) => {
    const updated = sizes.map((item, i) => {
      if (i !== index) return item;
      if (field === 'name') return { ...item, name: value };
      return { ...item, extra: Math.max(0, parseInt(value, 10) || 0) };
    });
    onChangeSizes(updated);
  };

  const handleRemoveSize = (index: number) => {
    onChangeSizes(sizes.filter((_, i) => i !== index));
  };

  // ── TOPPINGS CRUD ──
  const handleAddTopping = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const name = newToppingName.trim();
    if (!name) return;
    const extra = Math.max(0, parseInt(newToppingExtra, 10) || 0);

    onChangeToppings([...toppings, { name, extra }]);
    setNewToppingName('');
    setNewToppingExtra('');
  };

  const handleUpdateTopping = (index: number, field: 'name' | 'extra', value: any) => {
    const updated = toppings.map((item, i) => {
      if (i !== index) return item;
      if (field === 'name') return { ...item, name: value };
      return { ...item, extra: Math.max(0, parseInt(value, 10) || 0) };
    });
    onChangeToppings(updated);
  };

  const handleRemoveTopping = (index: number) => {
    onChangeToppings(toppings.filter((_, i) => i !== index));
  };

  // ── PRESETS ──
  const applyDrinkPresets = () => {
    onChangeSizes([
      { name: 'Size Vừa (M)', extra: 0 },
      { name: 'Size Lớn (L)', extra: 6000 },
      { name: 'Size Nhỏ (S)', extra: 0 },
    ]);
    onChangeToppings([
      { name: 'Trân châu đen', extra: 5000 },
      { name: 'Trân châu trắng', extra: 5000 },
      { name: 'Thạch nha đam', extra: 5000 },
      { name: 'Pudding trứng', extra: 7000 },
    ]);
  };

  const applyFoodPresets = () => {
    onChangeSizes([
      { name: 'Phần Tiêu Chuẩn', extra: 0 },
      { name: 'Phần Lớn (Nhiều hơn)', extra: 10000 },
      { name: 'Phần Đặc Biệt', extra: 20000 },
    ]);
    onChangeToppings([
      { name: 'Thịt thêm', extra: 15000 },
      { name: 'Trứng ốp la / Trứng chần', extra: 5000 },
      { name: 'Rau thêm', extra: 5000 },
    ]);
  };

  const clearAll = () => {
    onChangeSizes([]);
    onChangeToppings([]);
  };

  return (
    <div style={{ marginBottom: '24px', display: 'flex', flexDirection: 'column', gap: '18px' }}>
      {/* Header and Quick Presets */}
      <div style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', justifyContent: 'space-between', gap: '8px' }}>
        <div>
          <label className="form-label" style={{ marginBottom: 0, display: 'flex', alignItems: 'center', gap: '7px', fontSize: '14px', fontWeight: 700 }}>
            <Layers size={17} color="#f97316" />
            <span>Tùy Chỉnh Khẩu Phần & Topping (Khách chọn trên App)</span>
          </label>
          <span style={{ fontSize: '12px', color: '#64748b' }}>
            Quán tự do cài đặt các size và món thêm kèm giá mong muốn cho từng món ăn
          </span>
        </div>
        <div style={{ display: 'flex', gap: '6px', flexWrap: 'wrap' }}>
          <button
            type="button"
            onClick={applyDrinkPresets}
            style={{
              padding: '5px 10px',
              fontSize: '11.5px',
              borderRadius: '8px',
              border: '1px solid #fed7aa',
              backgroundColor: '#fff7ed',
              color: '#ea580c',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
            title="Áp dụng mẫu Size M/L & Topping Trà Sữa"
          >
            <Coffee size={13} /> Mẫu Trà Sữa/Nước
          </button>
          <button
            type="button"
            onClick={applyFoodPresets}
            style={{
              padding: '5px 10px',
              fontSize: '11.5px',
              borderRadius: '8px',
              border: '1px solid #bbf7d0',
              backgroundColor: '#f0fdf4',
              color: '#16a34a',
              fontWeight: 600,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
            title="Áp dụng mẫu Phần ăn & Topping Cơm/Phở/Món mặn"
          >
            <Utensils size={13} /> Mẫu Cơm/Phở/Món
          </button>
          {(sizes.length > 0 || toppings.length > 0) && (
            <button
              type="button"
              onClick={clearAll}
              style={{
                padding: '5px 10px',
                fontSize: '11.5px',
                borderRadius: '8px',
                border: '1px solid #e2e8f0',
                backgroundColor: '#f8fafc',
                color: '#64748b',
                fontWeight: 600,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: '4px',
              }}
              title="Xóa trắng các tùy chọn (Món chỉ có 1 giá chuẩn)"
            >
              <RotateCcw size={12} /> Xóa hết
            </button>
          )}
        </div>
      </div>

      {/* SECTION 1: LỰA CHỌN KHẨU PHẦN (SIZES) */}
      <div
        style={{
          border: '1px solid #fed7aa',
          borderRadius: '12px',
          backgroundColor: '#fffbf7',
          padding: '14px 16px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '13px', fontWeight: 800, color: '#9a3412' }}>
              1. Lựa chọn khẩu phần (Size)
            </span>
            <span
              style={{
                fontSize: '10.5px',
                fontWeight: 700,
                padding: '2px 7px',
                borderRadius: '6px',
                backgroundColor: '#ffedd5',
                color: '#c2410c',
              }}
            >
              Bắt buộc chọn 1 trên app
            </span>
          </div>
          <span style={{ fontSize: '12px', color: '#64748b' }}>
            {sizes.length > 0 ? `${sizes.length} khẩu phần` : 'Chưa cấu hình (dùng giá gốc)'}
          </span>
        </div>

        {/* List of existing sizes */}
        {sizes.length > 0 ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '12px' }}>
            {sizes.map((s, idx) => (
              <div
                key={idx}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  backgroundColor: '#ffffff',
                  border: '1px solid #e2e8f0',
                  borderRadius: '9px',
                  padding: '7px 10px',
                }}
              >
                <div style={{ flex: 1 }}>
                  <input
                    type="text"
                    value={s.name}
                    onChange={(e) => handleUpdateSize(idx, 'name', e.target.value)}
                    placeholder="Tên size (vd: Size Vừa (M))"
                    style={{
                      width: '100%',
                      padding: '5px 8px',
                      borderRadius: '6px',
                      border: '1px solid #cbd5e1',
                      fontSize: '13px',
                      fontWeight: 600,
                    }}
                  />
                </div>
                <div style={{ width: '130px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <span style={{ fontSize: '12px', color: '#64748b', fontWeight: 600 }}>+</span>
                  <input
                    type="number"
                    value={s.extra === 0 ? '' : s.extra}
                    onChange={(e) => handleUpdateSize(idx, 'extra', e.target.value)}
                    placeholder="0"
                    style={{
                      width: '100%',
                      padding: '5px 8px',
                      borderRadius: '6px',
                      border: '1px solid #cbd5e1',
                      fontSize: '13px',
                      fontWeight: 700,
                      color: s.extra > 0 ? '#ea580c' : '#16a34a',
                    }}
                  />
                  <span style={{ fontSize: '11px', color: '#64748b' }}>đ</span>
                </div>
                <span
                  style={{
                    fontSize: '11px',
                    fontWeight: 700,
                    width: '85px',
                    textAlign: 'right',
                    color: s.extra > 0 ? '#ea580c' : '#16a34a',
                  }}
                >
                  {s.extra === 0 ? 'Miễn phí' : `+${formatVND(s.extra)}`}
                </span>
                <button
                  type="button"
                  onClick={() => handleRemoveSize(idx)}
                  style={{
                    border: 'none',
                    backgroundColor: '#fee2e2',
                    color: '#dc2626',
                    width: '28px',
                    height: '28px',
                    borderRadius: '6px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: 'pointer',
                  }}
                  title="Xóa khẩu phần này"
                >
                  <Trash2 size={13} />
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div
            style={{
              padding: '10px',
              backgroundColor: '#ffffff',
              borderRadius: '8px',
              border: '1px dashed #cbd5e1',
              color: '#64748b',
              fontSize: '12px',
              textAlign: 'center',
              marginBottom: '10px',
            }}
          >
            Chưa có khẩu phần nào. Hãy thêm các size như <strong>Size Vừa (M) (+0đ)</strong>, <strong>Size Lớn (L) (+6.000đ)</strong> bên dưới.
          </div>
        )}

        {/* Add new size input row */}
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <input
            type="text"
            placeholder="Tên khẩu phần mới (vd: Size Lớn (L), Phần đặc biệt...)"
            value={newSizeName}
            onChange={(e) => setNewSizeName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                handleAddSize();
              }
            }}
            style={{
              flex: 1,
              padding: '7px 10px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '12.5px',
            }}
          />
          <input
            type="number"
            placeholder="Giá thêm (+đ)"
            value={newSizeExtra}
            onChange={(e) => setNewSizeExtra(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                handleAddSize();
              }
            }}
            style={{
              width: '120px',
              padding: '7px 10px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '12.5px',
            }}
          />
          <button
            type="button"
            onClick={() => handleAddSize()}
            disabled={!newSizeName.trim()}
            style={{
              padding: '7px 14px',
              borderRadius: '8px',
              backgroundColor: newSizeName.trim() ? '#ea580c' : '#fed7aa',
              color: '#ffffff',
              border: 'none',
              fontWeight: 700,
              fontSize: '12.5px',
              cursor: newSizeName.trim() ? 'pointer' : 'not-allowed',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <Plus size={14} /> Thêm Size
          </button>
        </div>
      </div>

      {/* SECTION 2: TOPPING & TÙY CHỌN THÊM (TOPPINGS) */}
      <div
        style={{
          border: '1px solid #e2e8f0',
          borderRadius: '12px',
          backgroundColor: '#f8fafc',
          padding: '14px 16px',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '10px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span style={{ fontSize: '13px', fontWeight: 800, color: '#334155' }}>
              2. Topping & Tùy chọn thêm
            </span>
            <span
              style={{
                fontSize: '10.5px',
                fontWeight: 700,
                padding: '2px 7px',
                borderRadius: '6px',
                backgroundColor: '#e2e8f0',
                color: '#475569',
              }}
            >
              Khách chọn nhiều trên app
            </span>
          </div>
          <span style={{ fontSize: '12px', color: '#64748b' }}>
            {toppings.length > 0 ? `${toppings.length} topping` : 'Không có topping'}
          </span>
        </div>

        {/* List of existing toppings */}
        {toppings.length > 0 ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginBottom: '12px' }}>
            {toppings.map((t, idx) => (
              <div
                key={idx}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  backgroundColor: '#ffffff',
                  border: '1px solid #e2e8f0',
                  borderRadius: '9px',
                  padding: '7px 10px',
                }}
              >
                <div style={{ flex: 1 }}>
                  <input
                    type="text"
                    value={t.name}
                    onChange={(e) => handleUpdateTopping(idx, 'name', e.target.value)}
                    placeholder="Tên topping (vd: Trân châu đen)"
                    style={{
                      width: '100%',
                      padding: '5px 8px',
                      borderRadius: '6px',
                      border: '1px solid #cbd5e1',
                      fontSize: '13px',
                      fontWeight: 600,
                    }}
                  />
                </div>
                <div style={{ width: '130px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                  <span style={{ fontSize: '12px', color: '#64748b', fontWeight: 600 }}>+</span>
                  <input
                    type="number"
                    value={t.extra === 0 ? '' : t.extra}
                    onChange={(e) => handleUpdateTopping(idx, 'extra', e.target.value)}
                    placeholder="0"
                    style={{
                      width: '100%',
                      padding: '5px 8px',
                      borderRadius: '6px',
                      border: '1px solid #cbd5e1',
                      fontSize: '13px',
                      fontWeight: 700,
                      color: '#0284c7',
                    }}
                  />
                  <span style={{ fontSize: '11px', color: '#64748b' }}>đ</span>
                </div>
                <span
                  style={{
                    fontSize: '11px',
                    fontWeight: 700,
                    width: '85px',
                    textAlign: 'right',
                    color: '#0284c7',
                  }}
                >
                  {t.extra === 0 ? 'Miễn phí' : `+${formatVND(t.extra)}`}
                </span>
                <button
                  type="button"
                  onClick={() => handleRemoveTopping(idx)}
                  style={{
                    border: 'none',
                    backgroundColor: '#fee2e2',
                    color: '#dc2626',
                    width: '28px',
                    height: '28px',
                    borderRadius: '6px',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    cursor: 'pointer',
                  }}
                  title="Xóa topping này"
                >
                  <Trash2 size={13} />
                </button>
              </div>
            ))}
          </div>
        ) : (
          <div
            style={{
              padding: '10px',
              backgroundColor: '#ffffff',
              borderRadius: '8px',
              border: '1px dashed #cbd5e1',
              color: '#64748b',
              fontSize: '12px',
              textAlign: 'center',
              marginBottom: '10px',
            }}
          >
            Chưa có topping hoặc món ăn kèm. Có thể thêm các món như <strong>Trân châu</strong>, <strong>Thịt thêm</strong>, <strong>Trứng ốp la</strong>...
          </div>
        )}

        {/* Add new topping input row */}
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <input
            type="text"
            placeholder="Tên topping mới (vd: Trân châu trắng, Trứng ốp la...)"
            value={newToppingName}
            onChange={(e) => setNewToppingName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                handleAddTopping();
              }
            }}
            style={{
              flex: 1,
              padding: '7px 10px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '12.5px',
            }}
          />
          <input
            type="number"
            placeholder="Giá thêm (+đ)"
            value={newToppingExtra}
            onChange={(e) => setNewToppingExtra(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault();
                handleAddTopping();
              }
            }}
            style={{
              width: '120px',
              padding: '7px 10px',
              borderRadius: '8px',
              border: '1px solid #cbd5e1',
              fontSize: '12.5px',
            }}
          />
          <button
            type="button"
            onClick={() => handleAddTopping()}
            disabled={!newToppingName.trim()}
            style={{
              padding: '7px 14px',
              borderRadius: '8px',
              backgroundColor: newToppingName.trim() ? '#0284c7' : '#bae6fd',
              color: '#ffffff',
              border: 'none',
              fontWeight: 700,
              fontSize: '12.5px',
              cursor: newToppingName.trim() ? 'pointer' : 'not-allowed',
              display: 'flex',
              alignItems: 'center',
              gap: '4px',
            }}
          >
            <Plus size={14} /> Thêm Topping
          </button>
        </div>
      </div>
    </div>
  );
};

