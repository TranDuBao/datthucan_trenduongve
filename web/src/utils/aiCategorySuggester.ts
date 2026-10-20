import { removeVietnameseTones } from './textUtils';

export interface CategoryItem {
  maDanhMuc: number;
  tenDanhMuc: string;
}

export interface AISuggestionResult {
  suggestedCategoryId?: number;
  suggestedCategoryName: string;
  confidence: number; // 0 - 100
  reason: string;
  isExistingCategory: boolean;
}

// Culinary taxonomy dictionary with keyword clusters
interface CategoryRule {
  targetKeywords: string[]; // Primary keywords indicating this category
  categoryNames: string[]; // Existing category names this maps to
  fallbackName: string; // If no existing category matches, propose this name
  reasonTemplate: string;
}

const CULINARY_RULES: CategoryRule[] = [
  {
    targetKeywords: [
      'tra sua', 'hong tra', 'luc tra', 'oolong', 'o long', 'tran chau', 'milk tea',
      'macchiato', 'kem cheese', 'thai xanh', 'thai do', 'tra dao', 'tra vai', 'tra tac',
      'tra chanh', 'tra sen', 'tra buoi', 'tra mang cau', 'kem trung nuong', 'boba'
    ],
    categoryNames: ['Trà Sữa', 'Trà & Trà Sữa', 'Thức Uống', 'Giải Khát'],
    fallbackName: 'Trà Sữa',
    reasonTemplate: 'Phát hiện các từ khóa hương vị trà sữa, topping hoặc trà trái cây'
  },
  {
    targetKeywords: [
      'ca phe', 'cafe', 'coffee', 'espresso', 'cappuccino', 'latte', 'americano',
      'bac xiu', 'nau da', 'den da', 'phin', 'muoi', 'cold brew', 'mocha', 'macchiato'
    ],
    categoryNames: ['Cà Phê', 'Coffee & Cà Phê', 'Thức Uống'],
    fallbackName: 'Cà Phê',
    reasonTemplate: 'Nhận diện dòng thức uống Cà phê và các biến thể pha chế'
  },
  {
    targetKeywords: [
      'banh sinh nhat', 'kem bo', 'gateau', 'kem tuoi', 'banh kem', 'fondant'
    ],
    categoryNames: ['Bánh Sinh Nhật', 'Bánh Kem', 'Bánh Ngọt'],
    fallbackName: 'Bánh Sinh Nhật',
    reasonTemplate: 'Món thuộc nhóm bánh sinh nhật và bánh tiệc kỷ niệm'
  },
  {
    targetKeywords: [
      'banh', 'croissant', 'tiramisu', 'muffin', 'su kem', 'tart', 'cheesecake',
      'pancake', 'waffle', 'bong lan', 'donut', 'cupcake', 'brownie', 'cookies', 'pastry'
    ],
    categoryNames: ['Bánh Ngọt', 'Bánh & Điểm Tâm', 'Bánh Sinh Nhật'],
    fallbackName: 'Bánh Ngọt',
    reasonTemplate: 'Nhận diện các loại bánh ngọt, bánh nướng hoặc tráng miệng phong cách Âu/Á'
  },
  {
    targetKeywords: [
      'kem', 'ice cream', 'gelato', 'sorbet', 'bơ sap', 'kem ly', 'kem que',
      'kem oc que', 'kem bo sap', 'sundae', 'bingsu'
    ],
    categoryNames: ['Kem', 'Nước Uống & Tráng Miệng', 'Giải Khát'],
    fallbackName: 'Kem',
    reasonTemplate: 'Nhận diện món tráng miệng lạnh, kem bơ hoặc kem Gelato'
  },
  {
    targetKeywords: [
      'bun bo', 'bun bo hue', 'gio heo', 'cha cua', 'bo nam', 'bo tai', 'bun',
      'bun moc', 'bun moc', 'bun rieu', 'bun cha', 'bun thit nuong', 'bun dau'
    ],
    categoryNames: ['Bún Bò Huế', 'Bún Truyền Thống', 'Món Nước'],
    fallbackName: 'Bún Bò Huế',
    reasonTemplate: 'Món ăn sợi bún truyền thống, đậm đà phong vị Việt'
  },
  {
    targetKeywords: [
      'pho', 'pho bo', 'pho ga', 'tai nam', 'gau bap', 'trung tran', 'banh pho'
    ],
    categoryNames: ['Phở Truyền Thống', 'Phở Gia Truyền', 'Món Nước'],
    fallbackName: 'Phở Truyền Thống',
    reasonTemplate: 'Món phở truyền thống danh tiếng với nước dùng hầm'
  },
  {
    targetKeywords: [
      'com tam', 'suon bi', 'cha trung', 'suon cot let', 'com suon', 'com nieu',
      'com ga', 'com chien', 'com rang', 'canh kho qua', 'canh rong bien'
    ],
    categoryNames: ['Cơm Tấm Đặc Biệt', 'Cơm Tấm', 'Món Cơm'],
    fallbackName: 'Cơm Tấm Đặc Biệt',
    reasonTemplate: 'Món cơm tấm sườn chả hoặc cơm nóng đặc sản'
  },
  {
    targetKeywords: [
      'kem', 'kem theo', 'topping', 'cha gio', 'nem ran', 'khoai tay', 'xuc xich',
      'chan ga', 'quay', 'dau hu chiên', 'cha cua', 'an kem'
    ],
    categoryNames: ['Món Ăn Kèm', 'Món Ăn Kèm Huế', 'Món Kèm & Giải Khát'],
    fallbackName: 'Món Ăn Kèm',
    reasonTemplate: 'Món ăn kèm thêm hoặc đồ khai vị/topping bữa ăn'
  },
  {
    targetKeywords: [
      'thao moc', 'sam', 'atiso', 'nha dam', 'mat ong', 'hoa cuc', 'tra thao moc', 'la dua'
    ],
    categoryNames: ['Thảo mộc', 'Giải Khát', 'Nước Uống & Tráng Miệng'],
    fallbackName: 'Thảo mộc',
    reasonTemplate: 'Thức uống thanh lọc có nguồn gốc thảo mộc, hoa quả thiên nhiên'
  },
  {
    targetKeywords: [
      'giai khat', 'nuoc suoi', 'nuoc ngot', 'sting', 'coca', 'pepsi', '7up', 'soda',
      'nuoc khoang', 'nuoc ep', 'sinh to', 'smoothie', 'da me', 'nuoc mia'
    ],
    categoryNames: ['Giải Khát', 'Nước Uống & Tráng Miệng', 'Nước Ép & Sinh Tố'],
    fallbackName: 'Giải Khát',
    reasonTemplate: 'Đồ uống đóng chai hoặc giải khát làm mát tức thì'
  },
  {
    targetKeywords: [
      'chè', 'che buoi', 'che thai', 'sua chua', 'yaourt', 'pudding', 'flan', 'thach'
    ],
    categoryNames: ['Nước Uống & Tráng Miệng', 'Chè & Tráng Miệng', 'Kem'],
    fallbackName: 'Nước Uống & Tráng Miệng',
    reasonTemplate: 'Món tráng miệng ngọt ngào thanh mát'
  },
  {
    targetKeywords: [
      'lau', 'nuong', 'bbq', 'hai san', 'tom', 'cua', 'muc', 'bo my'
    ],
    categoryNames: ['Lẩu & Nướng', 'Món Nướng', 'Hải Sản'],
    fallbackName: 'Lẩu & Nướng',
    reasonTemplate: 'Món lẩu tụ họp gia đình, bạn bè hoặc món nướng thơm lừng'
  },
  {
    targetKeywords: [
      'chay', 'nam', 'dau hu', 'rau cu', 'an chay'
    ],
    categoryNames: ['Món Chay', 'Thực Dưỡng'],
    fallbackName: 'Món Chay',
    reasonTemplate: 'Món ăn thuần chay thanh đạm bảo vệ sức khỏe'
  }
];

/**
 * AI Suggests the most suitable Category for a Given Dish Name.
 */
export function suggestCategoryForDish(
  dishName: string,
  availableCategories: CategoryItem[]
): AISuggestionResult | null {
  if (!dishName || !dishName.trim()) return null;

  const rawClean = dishName.trim();
  const unaccentName = removeVietnameseTones(rawClean);

  let bestRule: CategoryRule | null = null;
  let bestScore = 0;
  let matchedKeyword = '';

  for (const rule of CULINARY_RULES) {
    for (const kw of rule.targetKeywords) {
      const cleanKw = removeVietnameseTones(kw);
      if (unaccentName.includes(cleanKw)) {
        // Longer keyword matches are more specific (e.g. "banh sinh nhat" > "banh")
        const score = cleanKw.length * 10;
        if (score > bestScore) {
          bestScore = score;
          bestRule = rule;
          matchedKeyword = kw;
        }
      }
    }
  }

  if (!bestRule) {
    // Generic fallback: check if any available category name appears in the dish name
    for (const cat of availableCategories) {
      const catUnaccent = removeVietnameseTones(cat.tenDanhMuc);
      if (unaccentName.includes(catUnaccent)) {
        return {
          suggestedCategoryId: cat.maDanhMuc,
          suggestedCategoryName: cat.tenDanhMuc,
          confidence: 85,
          reason: `Tên món có chứa trực tiếp tên danh mục "${cat.tenDanhMuc}"`,
          isExistingCategory: true,
        };
      }
    }
    return null;
  }

  // Find if bestRule maps to any of the existing availableCategories
  let matchedExistingCat: CategoryItem | undefined;

  for (const targetName of bestRule.categoryNames) {
    const targetClean = removeVietnameseTones(targetName);
    matchedExistingCat = availableCategories.find(
      (c) => removeVietnameseTones(c.tenDanhMuc) === targetClean
    );
    if (matchedExistingCat) break;
  }

  // If not exact name match, check partial name match in availableCategories
  if (!matchedExistingCat) {
    for (const targetName of bestRule.categoryNames) {
      const targetClean = removeVietnameseTones(targetName);
      matchedExistingCat = availableCategories.find(
        (c) => removeVietnameseTones(c.tenDanhMuc).includes(targetClean) ||
               targetClean.includes(removeVietnameseTones(c.tenDanhMuc))
      );
      if (matchedExistingCat) break;
    }
  }

  const confidence = Math.min(99, Math.max(78, 70 + bestScore));

  if (matchedExistingCat) {
    return {
      suggestedCategoryId: matchedExistingCat.maDanhMuc,
      suggestedCategoryName: matchedExistingCat.tenDanhMuc,
      confidence,
      reason: `${bestRule.reasonTemplate} (từ khóa: "${matchedKeyword}")`,
      isExistingCategory: true,
    };
  }

  // Suggest new category name
  return {
    suggestedCategoryName: bestRule.fallbackName,
    confidence,
    reason: `${bestRule.reasonTemplate}. Chưa có danh mục này trong quán, bạn có thể tạo mới!`,
    isExistingCategory: false,
  };
}
