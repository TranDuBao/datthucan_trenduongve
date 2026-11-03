import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTestRestaurantCard(Map<String, dynamic> pObj) {
  final hasReviews = pObj["hasReviews"] == true;
  final rateStr = hasReviews ? pObj["rate"].toString() : "Chưa có đánh giá";
  final String category = (pObj["category"] ?? "").toString().trim();
  final String discount = (pObj["discount"] ?? "").toString().trim();
  final String image = (pObj["image"] ?? "").toString().trim();
  final String time = (pObj["time"] ?? "15-20 phút").toString();

  return Container(
    key: ValueKey<int>(pObj["maQuan"] as int),
    margin: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            image.isNotEmpty
                ? Image.network(
                    image,
                    width: double.infinity,
                    height: 50,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                  )
                : Container(
                    key: const ValueKey('neutral_placeholder'),
                    width: double.infinity,
                    height: 50,
                    color: const Color(0xFFF1F3F7),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront_rounded, size: 24),
                          Text("Chưa cập nhật ảnh quán"),
                        ],
                      ),
                    ),
                  ),
            if (discount.isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  key: const ValueKey('discount_badge'),
                  child: Text(discount),
                ),
              ),
            Positioned(
              bottom: 12,
              right: 12,
              child: Text(time),
            ),
          ],
        ),
        Text(pObj["name"].toString()),
        Row(
          children: [
            Icon(hasReviews ? Icons.star_rounded : Icons.star_border_rounded),
            Text(rateStr),
            if (hasReviews) Text("(${pObj["ratingCount"]} đánh giá)"),
            if (category.isNotEmpty) Text("• $category"),
          ],
        ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<Map<String, dynamic>> testStores = [
    {
      "maQuan": 12,
      "name": "Tiệm Kem Sweet Cake",
      "rate": "5.0",
      "rateVal": 5.0,
      "ratingCount": 3,
      "hasReviews": true,
      "discount": "Giảm 10%",
      "time": "40-45 phút",
      "category": "Thức uống",
      "image": "https://example.com/sweet_cake.jpg",
    },
    {
      "maQuan": 3,
      "name": "Cơm Tấm Sài Gòn 99",
      "rate": "2.7",
      "rateVal": 2.7,
      "ratingCount": 3,
      "hasReviews": true,
      "discount": "",
      "time": "15-20 phút",
      "category": "Đồ ăn",
      "image": "https://example.com/com_tam.jpg",
    },
    {
      "maQuan": 57,
      "name": "Phở Hòa Pasteur",
      "rate": "Chưa có đánh giá",
      "rateVal": 0.0,
      "ratingCount": 0,
      "hasReviews": false,
      "discount": "",
      "time": "10-15 phút",
      "category": "Phở & Bún Mì",
      "image": "", // Thiếu ảnh -> phải dùng placeholder
    },
    {
      "maQuan": 59,
      "name": "Bún Đậu Cô Khàn",
      "rate": "Chưa có đánh giá",
      "rateVal": 0.0,
      "ratingCount": 0,
      "hasReviews": false,
      "discount": "",
      "time": "10-15 phút",
      "category": "Đặc Sản Bắc",
      "image": "", // Thiếu ảnh -> phải dùng placeholder
    },
    {
      "maQuan": 2,
      "name": "Phở Bò Hà Nội",
      "rate": "Chưa có đánh giá",
      "rateVal": 0.0,
      "ratingCount": 0,
      "hasReviews": false,
      "discount": "Giảm 15k",
      "time": "15-20 phút",
      "category": "Đồ ăn",
      "image": "https://example.com/pho_bo.jpg",
    },
    {
      "maQuan": 65,
      "name": "Trà & Bánh Morico",
      "rate": "Chưa có đánh giá",
      "rateVal": 0.0,
      "ratingCount": 0,
      "hasReviews": false,
      "discount": "",
      "time": "10-15 phút",
      "category": "Bánh Ngọt",
      "image": "", // Thiếu ảnh
    },
  ];

  group('Widget Test: Restaurant Card & Data Consistency', () {
    testWidgets('1. Displays correct ratings: real stars for reviewed stores, "Chưa có đánh giá" for unreviewed', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: testStores.map((s) => buildTestRestaurantCard(s)).toList(),
              ),
            ),
          ),
        ),
      );

      // Quán có đánh giá:
      expect(find.text('5.0'), findsOneWidget);
      expect(find.text('(3 đánh giá)'), findsNWidgets(2)); // Quán 12 và Quán 3
      expect(find.text('2.7'), findsOneWidget);

      // Quán chưa có đánh giá:
      expect(find.text('Chưa có đánh giá'), findsNWidgets(4)); // Quán 57, 59, 2, 65
      expect(find.text('4.8'), findsNothing); // Không được hiện 4.8 giả
      expect(find.text('15 Ratings'), findsNothing); // Không được hiện Ratings tiếng Anh
    });

    testWidgets('2. Placeholder & Images: missing images show neutral placeholder without duplicate photo', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: testStores.map((s) => buildTestRestaurantCard(s)).toList(),
              ),
            ),
          ),
        ),
      );

      // Có đúng 3 quán thiếu ảnh (57, 59, 65)
      expect(find.byKey(const ValueKey('neutral_placeholder')), findsNWidgets(3));
      expect(find.text('Chưa cập nhật ảnh quán'), findsNWidgets(3));
    });

    testWidgets('3. Discount Badge: Only renders when store has active voucher', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: testStores.map((s) => buildTestRestaurantCard(s)).toList(),
              ),
            ),
          ),
        ),
      );

      // Chỉ có Quán 12 (Giảm 10%) và Quán 2 (Giảm 15k) có voucher
      expect(find.byKey(const ValueKey('discount_badge')), findsNWidgets(2));
      expect(find.text('Giảm 10%'), findsOneWidget);
      expect(find.text('Giảm 15k'), findsOneWidget);
      expect(find.text('ƯU ĐÃI LỘ TRÌNH 10K'), findsNothing); // Đã loại bỏ hằng số giả
    });

    testWidgets('4. Preparation Time & Category: renders real intervals and categories', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: testStores.map((s) => buildTestRestaurantCard(s)).toList(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('40-45 phút'), findsOneWidget); // Quán 12 (45p)
      expect(find.text('15-20 phút'), findsNWidgets(2)); // Quán 3 và 2 (20p)
      expect(find.text('10-15 phút'), findsNWidgets(3)); // Quán 57, 59, 65 (15p)

      expect(find.text('• Thức uống'), findsOneWidget);
      expect(find.text('• Phở & Bún Mì'), findsOneWidget);
      expect(find.text('• Đặc Sản Bắc'), findsOneWidget);
      expect(find.text('Món Việt • Đặc sản lộ trình'), findsNothing); // Đã loại bỏ hằng số giả
    });

    testWidgets('5. Reordering & Keys: Each card maintains its specific ValueKey', (tester) async {
      tester.view.physicalSize = const Size(1080, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final reversedList = testStores.reversed.toList();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: reversedList.map((s) => buildTestRestaurantCard(s)).toList(),
              ),
            ),
          ),
        ),
      );

      // Kiểm tra các Key tồn tại đúng theo maQuan
      expect(find.byKey(const ValueKey(12)), findsOneWidget);
      expect(find.byKey(const ValueKey(57)), findsOneWidget);
      expect(find.byKey(const ValueKey(59)), findsOneWidget);
      expect(find.byKey(const ValueKey(3)), findsOneWidget);
    });
  });
}
