import 'dart:convert';
import 'package:http/http.dart' as http;
import '../common/globs.dart';

class CategoryModel {
  final int id;
  final int maQuan;
  final String key;
  final String name;
  final String image;
  final int itemsCount;
  final bool isHot;
  final List<dynamic> items;

  CategoryModel({
    required this.id,
    this.maQuan = 0,
    required this.key,
    required this.name,
    required this.image,
    required this.itemsCount,
    this.isHot = false,
    this.items = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['maDanhMuc'] ?? json['id'] ?? 0,
      maQuan: json['maQuan'] ?? 0,
      key: json['key'] ?? json['tenDanhMuc']?.toString().toLowerCase() ?? 'category',
      name: json['tenDanhMuc'] ?? json['name'] ?? 'Danh mục',
      image: json['hinhAnh'] ?? json['image'] ?? 'assets/img/menu_1.png',
      itemsCount: json['soLuongMon'] ?? json['itemsCount'] ?? 0,
      isHot: json['isHot'] ?? false,
      items: json['items'] ?? [],
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

    return [];
  }

  static Future<List<dynamic>> fetchRestaurantMenuFromDB(int restaurantId) async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse(SVKey.svRestaurantMenu(restaurantId));
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final resJson = json.decode(response.body);
        return resJson['data'] ?? [];
      }
    } catch (_) {}

    return [];
  }

  static Future<List<dynamic>> fetchRestaurantsFromDB() async {
    try {
      final token = Globs.udValueString(KKey.authToken);
      final url = Uri.parse(SVKey.svRestaurants);
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final resJson = json.decode(response.body);
        return resJson['data'] ?? [];
      }
    } catch (_) {}

    return [];
  }
}
