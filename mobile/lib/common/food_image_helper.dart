class FoodImageHelper {
  // Collection of distinct high quality restaurant cover photos
  static const List<String> _curatedRestaurantCovers = [
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=600', // Modern Asian bistro
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600', // Fine dining cozy
    'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=600', // Warm wooden restaurant
    'https://images.unsplash.com/photo-1543007630-9710e4a00a20?w=600', // Bar & coffee interior
    'https://images.unsplash.com/photo-1537047902294-62a40c20a6ae?w=600', // Outdoor patio cafe
    'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=600', // Minimalist food venue
    'https://images.unsplash.com/photo-1578474846511-04ba529f0b88?w=600', // Casual restaurant vibe
    'https://images.unsplash.com/photo-1525610553991-2bede1a236e2?w=600', // Elegant street bistro
  ];

  /// Lấy ảnh đại diện nhà hàng thông minh theo tên, danh mục hoặc ID
  static String getRestaurantImage(String? rawImg, String name, {int id = 0, String? category}) {
    if (rawImg != null &&
        rawImg.trim().isNotEmpty &&
        !rawImg.contains('photo-1582878826629-29b7ad1cdc43')) {
      return rawImg.trim();
    }

    final lowerName = name.toLowerCase();
    final lowerCat = (category ?? '').toLowerCase();
    final combined = '$lowerName $lowerCat';

    // 1. Cà phê / Phúc Long / Highlands / Trà
    if (combined.contains('phúc long') ||
        combined.contains('cà phê') ||
        combined.contains('coffee') ||
        combined.contains('highlands') ||
        combined.contains('tea') && !combined.contains('trà sữa')) {
      return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=600';
    }

    // 2. Trà sữa / The Alley / Boba / Gong Cha
    if (combined.contains('trà sữa') ||
        combined.contains('alley') ||
        combined.contains('boba') ||
        combined.contains('gong cha')) {
      return 'https://images.unsplash.com/photo-1558857563-b37df2dd4b74?w=600';
    }

    // 3. Pizza / Pizza 4P's / Mì Ý / Pasta
    if (combined.contains('pizza') || combined.contains('pasta') || combined.contains('spaghetti')) {
      return 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600';
    }

    // 4. Mì Udon / Marukame / Ramen / Soba
    if (combined.contains('udon') ||
        combined.contains('marukame') ||
        combined.contains('ramen') ||
        combined.contains('mì nhật')) {
      return 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=600';
    }

    // 5. Steak / El Gaucho / Bò / Beef / Bít tết
    if (combined.contains('gaucho') ||
        combined.contains('steak') ||
        combined.contains('bò bít tết') ||
        combined.contains('beef')) {
      return 'https://images.unsplash.com/photo-1558030006-450675393462?w=600';
    }

    // 6. Gà nướng / Ò Ó O / Gà rán / Chicken
    if (combined.contains('gà') || combined.contains('ò ó o') || combined.contains('chicken')) {
      return 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=600';
    }

    // 7. Cơm / Cơm tấm / Cơm sườn
    if (combined.contains('cơm') || combined.contains('sườn') || combined.contains('tấm')) {
      return 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600';
    }

    // 8. Bún đậu / Mắm tôm / Cô Khàn
    if (combined.contains('bún đậu') || combined.contains('mắm tôm') || combined.contains('cô khàn')) {
      return 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600';
    }

    // 9. Bánh canh / Hủ tiếu / Bún bò / Trần Khắc Chân
    if (combined.contains('bánh canh') ||
        combined.contains('hủ tiếu') ||
        combined.contains('bún') ||
        combined.contains('trần khắc chân')) {
      return 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600';
    }

    // 10. Phở / Phở Bò / Hà Nội
    if (combined.contains('phở')) {
      return 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=600';
    }

    // 11. Bánh / Bánh ngọt / Bakery / Croissant / Morico
    if (combined.contains('bánh') ||
        combined.contains('morico') ||
        combined.contains('bakery') ||
        combined.contains('cake') ||
        combined.contains('croissant')) {
      return 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600';
    }

    // Phân bổ ngẫu nhiên có kiểm soát theo ID để không bị trùng lặp
    final index = (id.abs() + name.length) % _curatedRestaurantCovers.length;
    return _curatedRestaurantCovers[index];
  }

  /// Lấy ảnh món ăn thông minh theo tên món
  static String getFoodImage(String? rawImg, String foodName, {int id = 0}) {
    if (rawImg != null &&
        rawImg.trim().isNotEmpty &&
        !rawImg.contains('photo-1582878826629-29b7ad1cdc43')) {
      return rawImg.trim();
    }

    final lower = foodName.toLowerCase();

    // 1. Cà phê
    if (lower.contains('cà phê') ||
        lower.contains('coffee') ||
        lower.contains('phin') ||
        lower.contains('bạc xỉu') ||
        lower.contains('espresso') ||
        lower.contains('latte')) {
      return 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500';
    }

    // 2. Trà sữa & Trà trái cây
    if (lower.contains('trà sữa') ||
        lower.contains('ô long') ||
        lower.contains('olong') ||
        lower.contains('boba') ||
        lower.contains('trân châu') ||
        lower.contains('trà đào') ||
        lower.contains('trà vải') ||
        lower.contains('macchiato')) {
      return 'https://images.unsplash.com/photo-1558857563-b37df2dd4b74?w=500';
    }

    // 3. Bánh ngọt, bánh mì, Croissant
    if (lower.contains('croissant') ||
        lower.contains('bánh mì') ||
        lower.contains('tiramisu') ||
        lower.contains('mousse') ||
        lower.contains('cheesecake') ||
        lower.contains('bánh')) {
      return 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500';
    }

    // 4. Pizza
    if (lower.contains('pizza')) {
      return 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500';
    }

    // 5. Mì / Udon / Ramen / Spaghetti / Pasta
    if (lower.contains('udon') ||
        lower.contains('mì') ||
        lower.contains('ramen') ||
        lower.contains('spaghetti') ||
        lower.contains('pasta')) {
      return 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=500';
    }

    // 6. Cơm / Cơm sườn / Cơm gà
    if (lower.contains('cơm')) {
      return 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=500';
    }

    // 7. Gà rán / Gà nướng / Cánh gà
    if (lower.contains('gà')) {
      return 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=500';
    }

    // 8. Bún / Phở / Bánh canh / Hủ tiếu
    if (lower.contains('phở') ||
        lower.contains('bún') ||
        lower.contains('bánh canh') ||
        lower.contains('hủ tiếu')) {
      return 'https://images.unsplash.com/photo-1582878826629-29b7ad1cdc43?w=500';
    }

    // 9. Nước ngọt / Soda / Nước ép / Sinh tố
    if (lower.contains('nước') ||
        lower.contains('soda') ||
        lower.contains('sinh tố') ||
        lower.contains('juice') ||
        lower.contains('smoothie')) {
      return 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=500';
    }

    // 10. Tráng miệng / Kem
    if (lower.contains('kem') || lower.contains('chè') || lower.contains('flan')) {
      return 'https://images.unsplash.com/photo-1501443762994-82bd5dace89a?w=500';
    }

    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500';
  }
}
