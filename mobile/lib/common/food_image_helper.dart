class FoodImageHelper {
  /// Lấy ảnh đại diện nhà hàng thật từ CSDL, tuyệt đối không gán ảnh giả
  static String getRestaurantImage(String? rawImg, String name, {int id = 0, String? category}) {
    if (rawImg != null &&
        rawImg.trim().isNotEmpty &&
        !rawImg.contains('photo-1582878826629-29b7ad1cdc43')) {
      return rawImg.trim();
    }
    return '';
  }

  /// Lấy ảnh món ăn thật từ CSDL, tuyệt đối không gán ảnh giả
  static String getFoodImage(String? rawImg, String foodName, {int id = 0}) {
    if (rawImg != null &&
        rawImg.trim().isNotEmpty &&
        !rawImg.contains('photo-1582878826629-29b7ad1cdc43')) {
      return rawImg.trim();
    }
    return '';
  }
}
