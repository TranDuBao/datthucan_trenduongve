import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class CategoryModel {
  final int id;
  final String key;
  final String name;
  final String image;
  final int itemsCount;
  final bool isHot;

  CategoryModel({
    required this.id,
    required this.key,
    required this.name,
    required this.image,
    required this.itemsCount,
    this.isHot = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['maDanhMuc'] ?? json['id'] ?? 0,
      key: json['key'] ?? json['tenDanhMuc']?.toString().toLowerCase() ?? 'category',
      name: json['tenDanhMuc'] ?? json['name'] ?? 'Danh mục',
      image: json['hinhAnh'] ?? json['image'] ?? 'assets/img/menu_1.png',
      itemsCount: json['soLuongMon'] ?? json['itemsCount'] ?? 0,
      isHot: json['isHot'] ?? false,
    );
  }
}

class CategoryService {
  static Future<List<CategoryModel>> fetchCategoriesFromDB() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse('${SVKey.nodeUrl}/api/v1/categories');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> body = json.decode(response.body);
        return body.map((item) => CategoryModel.fromJson(item)).toList();
      }
    } catch (e) {
      // Return empty list if network/DB has no categories
    }

    // STRICT RULE: No hardcoded fake data! Extract strictly from database response.
    return [];
  }
}
