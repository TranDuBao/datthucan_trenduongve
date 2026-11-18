class FoodTranslateHelper {
  static const Map<String, String> _knownDishes = {
    'phở bò tái nạm đặc biệt': 'Special Rare & Flank Beef Pho',
    'phở bò tái sườn sụn': 'Rare Beef & Cartilage Pho',
    'phở bò gầu bắp trứng chèn': 'Brisket & Shank Pho with Egg',
    'phở bò tái nạm': 'Rare & Flank Beef Pho',
    'phở bò tái': 'Rare Beef Pho',
    'phở gà': 'Chicken Pho',
    'phở truyền thống': 'Traditional Pho',
    'trà đá đường thốt nốt': 'Iced Tea with Palm Sugar',
    'quẩy giòn hà nội': 'Hanoi Crispy Fried Dough',
    'quẩy giòn': 'Crispy Fried Dough',
    'bánh sinh nhật dâu tây kem bơ': 'Strawberry Buttercream Birthday Cake',
    'kem bơ sáp dừa tươi': 'Fresh Coconut Avocado Gelato',
    'cà phê phin sữa đậm đà': 'Rich Vietnamese Drip Milk Coffee',
    'cà phê sữa đá': 'Iced Milk Coffee',
    'cà phê đen đá': 'Iced Black Coffee',
    'trà sữa phúc long': 'Phuc Long Milk Tea',
    'cơm tấm sườn bì chả': 'Broken Rice with Pork Chop & Meatloaf',
    'cơm tấm sườn nướng': 'Broken Rice with Grilled Pork Chop',
    'cơm tấm đặc biệt': 'Special Broken Rice',
    'bún bò huế': 'Hue Spicy Beef Noodles',
    'bún bò': 'Beef Noodles',
    'nước hạt chia': 'Chia Seed Beverage',
    'cơm muối sả': 'Lemongrass Salted Rice',
  };

  static String translate(String viName) {
    if (viName.trim().isEmpty) return viName;
    final lower = viName.trim().toLowerCase();
    if (_knownDishes.containsKey(lower)) {
      return _knownDishes[lower]!;
    }
    for (final entry in _knownDishes.entries) {
      if (lower == entry.key || lower.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return viName;
  }
}

