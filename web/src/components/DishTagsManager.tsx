import React, { useState } from 'react';
import { Tag, Plus, X, Clock, Flame, Leaf, Snowflake, Utensils } from 'lucide-react';

interface DishTagsManagerProps {
  tags: string[];
  onChange: (newTags: string[]) => void;
}

export const PRESET_TAG_GROUPS = [
  {
    name: 'Thời gian phục vụ',
    icon: Clock,
    color: '#0284c7',
    bgColor: '#f0f9ff',
    items: ['~5 phút', '~10 phút', '~15 phút', '~20 phút', '~25 phút', 'Chế biến nhanh', 'Nấu kỹ gia truyền'],
  },
  {
    name: 'Năng lượng & Calo',
    icon: Flame,
    color: '#ea580c',
    bgColor: '#fff7ed',
    items: ['120 kcal', '180 kcal', '250 kcal', '320 kcal', '450 kcal', '580 kcal', '650 kcal', 'Ít calo / Eat Clean', 'Giàu Protein'],
  },
  {
    name: 'Nguyên liệu & Chế biến',
    icon: Leaf,
    color: '#16a34a',
    bgColor: '#f0fdf4',
    items: ['Nguyên liệu tươi sạch', 'Hầm xương đậm đà', 'Thịt bò tươi mềm', 'Gà ta thả vườn', 'Hải sản tươi sống', 'Không chất bảo quản', 'Nước dùng gia truyền', 'Nướng than hoa'],
  },
  {
    name: 'Đồ uống & Tráng miệng',
    icon: Snowflake,
    color: '#0891b2',
    bgColor: '#ecfeff',
    items: ['Đá riêng / Nóng', 'Ít ngọt / Không đường', 'Trà ủ lạnh', 'Trái cây tươi', 'Bánh tươi mỗi ngày', 'Cà phê rang xay'],
  },
  {
    name: 'Khẩu vị & Đặc tính',
    icon: Utensils,
    color: '#9333ea',
    bgColor: '#faf5ff',
    items: ['Không cay', 'Cay vừa', 'Cay nồng', 'Ăn chay (Vegetarian)', 'Ít dầu mỡ', 'Đậm vị truyền thống', 'Vị thanh ngọt'],
  },
];

export const DishTagsManager: React.FC<DishTagsManagerProps> = ({ tags, onChange }) => {
  const [customInput, setCustomInput] = useState('');
  const [activeTab, setActiveTab] = useState(0);

  const handleAddCustom = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const trimmed = customInput.trim();
    if (!trimmed) return;
    if (!tags.includes(trimmed)) {
      onChange([...tags, trimmed]);
    }
    setCustomInput('');
  };

  const handleToggleTag = (tag: string) => {
    if (tags.includes(tag)) {
      onChange(tags.filter((t) => t !== tag));
    } else {
      onChange([...tags, tag]);
    }
  };

  const handleRemoveTag = (index: number) => {
    onChange(tags.filter((_, i) => i !== index));
  };

  return (
    <div className="form-group" style={{ marginBottom: '20px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '8px' }}>
        <label className="form-label" style={{ marginBottom: 0, display: 'flex', alignItems: 'center', gap: '6px' }}>
          <Tag size={16} color="#ea580c" />
          <span>Đặc Trưng & Nhãn Món Ăn (Hiển thị trên Mobile)</span>
        </label>
        <span style={{ fontSize: '12px', color: '#64748b', fontWeight: 500 }}>
          Đã chọn: <strong style={{ color: '#ea580c' }}>{tags.length}</strong> nhãn
        </span>
      </div>

      {/* Selected Tags Display */}
      <div
        style={{
          minHeight: '44px',
          padding: '8px 12px',
          border: '1.5px dashed #cbd5e1',
          borderRadius: '10px',
          backgroundColor: '#f8fafc',
          display: 'flex',
          flexWrap: 'wrap',
          gap: '8px',
          alignItems: 'center',
          marginBottom: '12px',
        }}
      >
        {tags.length === 0 ? (
          <span style={{ fontSize: '13px', color: '#94a3b8', fontStyle: 'italic' }}>
            Chưa có nhãn nào được chọn. Nhấp vào các gợi ý bên dưới hoặc tự nhập nhãn mới.
          </span>
        ) : (
          tags.map((tag, idx) => (
            <span
              key={idx}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '5px',
                padding: '4px 10px',
                background: '#ffedd5',
                border: '1px solid #fdba74',
                color: '#c2410c',
                fontSize: '13px',
                fontWeight: 600,
                borderRadius: '20px',
                boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
              }}
            >
              {tag}
              <button
                type="button"
                onClick={() => handleRemoveTag(idx)}
                style={{
                  background: 'transparent',
                  border: 'none',
                  color: '#ea580c',
                  cursor: 'pointer',
                  padding: '1px',
                  display: 'flex',
                  alignItems: 'center',
                  borderRadius: '50%',
                }}
                title="Xóa nhãn"
              >
                <X size={14} />
              </button>
            </span>
          ))
        )}
      </div>

      {/* Custom Tag Input */}
      <div style={{ display: 'flex', gap: '8px', marginBottom: '14px' }}>
        <input
          type="text"
          className="form-control"
          placeholder="Nhập nhãn tùy chỉnh (ví dụ: ~8 phút, 350 kcal, Bò Kobe...)"
          value={customInput}
          onChange={(e) => setCustomInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              handleAddCustom();
            }
          }}
          style={{ flex: 1, fontSize: '13px' }}
        />
        <button
          type="button"
          onClick={() => handleAddCustom()}
          disabled={!customInput.trim()}
          style={{
            padding: '8px 16px',
            backgroundColor: customInput.trim() ? '#ea580c' : '#e2e8f0',
            color: customInput.trim() ? '#ffffff' : '#94a3b8',
            border: 'none',
            borderRadius: '8px',
            fontWeight: 600,
            fontSize: '13px',
            cursor: customInput.trim() ? 'pointer' : 'default',
            display: 'flex',
            alignItems: 'center',
            gap: '6px',
            transition: 'all 0.2s',
          }}
        >
          <Plus size={16} />
          <span>Thêm nhãn</span>
        </button>
      </div>

      {/* Preset Categories Tabs */}
      <div
        style={{
          border: '1px solid #e2e8f0',
          borderRadius: '10px',
          overflow: 'hidden',
          backgroundColor: '#ffffff',
        }}
      >
        <div
          style={{
            display: 'flex',
            overflowX: 'auto',
            background: '#f8fafc',
            borderBottom: '1px solid #e2e8f0',
            padding: '4px',
            gap: '4px',
          }}
        >
          {PRESET_TAG_GROUPS.map((group, idx) => {
            const Icon = group.icon;
            const isActive = activeTab === idx;
            return (
              <button
                key={idx}
                type="button"
                onClick={() => setActiveTab(idx)}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '6px',
                  padding: '6px 12px',
                  borderRadius: '7px',
                  border: 'none',
                  background: isActive ? '#ffffff' : 'transparent',
                  color: isActive ? '#0f172a' : '#64748b',
                  fontSize: '12px',
                  fontWeight: isActive ? 700 : 500,
                  cursor: 'pointer',
                  boxShadow: isActive ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
                  whiteSpace: 'nowrap',
                  transition: 'all 0.15s',
                }}
              >
                <Icon size={14} color={isActive ? group.color : '#94a3b8'} />
                <span>{group.name}</span>
              </button>
            );
          })}
        </div>

        {/* Preset Items Container */}
        <div style={{ padding: '12px', display: 'flex', flexWrap: 'wrap', gap: '8px' }}>
          {PRESET_TAG_GROUPS[activeTab].items.map((item, i) => {
            const isSelected = tags.includes(item);
            return (
              <button
                key={i}
                type="button"
                onClick={() => handleToggleTag(item)}
                style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: '5px',
                  padding: '5px 11px',
                  borderRadius: '16px',
                  fontSize: '12px',
                  fontWeight: isSelected ? 700 : 500,
                  border: isSelected ? '1.5px solid #ea580c' : '1px solid #e2e8f0',
                  background: isSelected ? '#fff7ed' : '#f8fafc',
                  color: isSelected ? '#c2410c' : '#334155',
                  cursor: 'pointer',
                  transition: 'all 0.15s',
                }}
              >
                <span>{isSelected ? '✓ ' : '+ '}</span>
                <span>{item}</span>
              </button>
            );
          })}
        </div>
      </div>
      <div style={{ fontSize: '11px', color: '#94a3b8', marginTop: '6px' }}>
        * Bạn có thể chọn nhiều nhãn gợi ý hoặc tự nhập nhãn riêng để hiển thị trực quan dưới phần đánh giá của món trên ứng dụng Mobile.
      </div>
    </div>
  );
};
