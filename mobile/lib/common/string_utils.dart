class StringUtils {
  /// Strips Vietnamese diacritics and converts to lower case
  /// Examples:
  ///   "Cơm tấm" -> "com tam"
  ///   "Phở Bò" -> "pho bo"
  ///   "Trà Sữa" -> "tra sua"
  ///   "Cà Phê" -> "ca phe"
  static String removeDiacritics(String str) {
    if (str.isEmpty) return "";
    var res = str;

    const vietnameseMap = {
      'a': 'áàảãạăắằẳẵặâấầẩẫậÁÀẢÃẠĂẮẰẲẴẶÂẤẦẨẪẬ',
      'd': 'đĐ',
      'e': 'éèẻẽẹêếềểễệÉÈẺẼẸÊẾỀỂỄỆ',
      'i': 'íìỉĩịÍÌỈĨỊ',
      'o': 'óòỏõọôốồổỗộơớờởỡợÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢ',
      'u': 'úùủũụưứừửữựÚÙỦŨỤƯỨỪỬỮỰ',
      'y': 'ýỳỷỹỵÝỲỶỸỴ',
    };

    for (final entry in vietnameseMap.entries) {
      final target = entry.key;
      for (var i = 0; i < entry.value.length; i++) {
        res = res.replaceAll(entry.value[i], target);
      }
    }

    // Strip combining diacritical marks (NFD decomposed unicode)
    res = res.replaceAll(RegExp(r'[\u0300-\u036f]'), '');

    return res.toLowerCase().trim();
  }

  /// Checks if [source] matches [query] with or without accents
  /// Example: "Cơm tấm" matches "com", "cơm", "tam", "tấm"
  static bool fuzzyMatch(String source, String query) {
    if (query.trim().isEmpty) return true;
    final rawSource = source.toLowerCase();
    final rawQuery = query.toLowerCase().trim();
    final normSource = removeDiacritics(source);
    final normQuery = removeDiacritics(query);

    return rawSource.contains(rawQuery) ||
        normSource.contains(rawQuery) ||
        rawSource.contains(normQuery) ||
        normSource.contains(normQuery);
  }
}
