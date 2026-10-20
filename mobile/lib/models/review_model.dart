class DishReviewModel {
  final int id;
  final int dishId;
  final String dishName;
  final int rating;
  final String? comment;

  DishReviewModel({
    required this.id,
    required this.dishId,
    required this.dishName,
    required this.rating,
    this.comment,
  });

  factory DishReviewModel.fromJson(Map<String, dynamic> json) {
    return DishReviewModel(
      id: json['id'] ?? 0,
      dishId: json['dishId'] ?? 0,
      dishName: json['dishName'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'],
    );
  }
}

class ReviewModel {
  final int id;
  final int? orderId;
  final int? storeId;
  final int? customerId;
  final String customerName;
  final int rating;
  final String? comment;
  final String? image;
  final String? reply;
  final String? repliedAt;
  final String createdAt;
  final bool isEdited;
  final String? storeName;
  final String? storeImg;
  final List<DishReviewModel> dishReviews;

  ReviewModel({
    required this.id,
    this.orderId,
    this.storeId,
    this.customerId,
    required this.customerName,
    required this.rating,
    this.comment,
    this.image,
    this.reply,
    this.repliedAt,
    required this.createdAt,
    this.isEdited = false,
    this.storeName,
    this.storeImg,
    this.dishReviews = const [],
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    var rawDishList = json['dishReviews'];
    List<DishReviewModel> parsedDishReviews = [];
    if (rawDishList is List) {
      parsedDishReviews = rawDishList.map((d) => DishReviewModel.fromJson(d)).toList();
    }

    return ReviewModel(
      id: json['maDanhGia'] ?? json['id'] ?? 0,
      orderId: json['maDonHang'] ?? json['orderId'],
      storeId: json['maQuan'] ?? json['storeId'],
      customerId: json['maKhachHang'] ?? json['customerId'],
      customerName: json['tenKhachHang'] ?? 'Khách hàng',
      rating: json['soLuongSao'] ?? json['rating'] ?? 5,
      comment: json['nhanXet'] ?? json['comment'],
      image: json['hinhAnh'] ?? json['image'],
      reply: json['phanHoi'] ?? json['reply'],
      repliedAt: json['ngayPhanHoi'] != null ? json['ngayPhanHoi'].toString() : null,
      createdAt: json['ngayNhanXet'] != null ? json['ngayNhanXet'].toString() : '',
      isEdited: json['isEdited'] ?? json['is_edited'] ?? false,
      storeName: json['tenQuan'],
      storeImg: json['imgQuan'],
      dishReviews: parsedDishReviews,
    );
  }
}
