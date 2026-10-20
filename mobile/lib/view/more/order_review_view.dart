import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../common/color_extension.dart';
import '../../models/review_model.dart';
import '../../services/order_service.dart';
import '../../services/review_service.dart';
import '../menu/item_details_view.dart';

class OrderReviewView extends StatefulWidget {
  final OrderServiceModel order;
  final ReviewModel? existingReview;

  const OrderReviewView({
    super.key,
    required this.order,
    this.existingReview,
  });

  @override
  State<OrderReviewView> createState() => _OrderReviewViewState();
}

class _OrderReviewViewState extends State<OrderReviewView> {
  int _selectedRating = 5;
  late TextEditingController _commentCtrl;
  bool _isLoadingCheck = true;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;
  ReviewModel? _existingReview;
  bool _canEdit = true;
  String? _editRestrictionReason;

  final Map<int, int> _dishRatings = {};
  final Map<int, TextEditingController> _dishCommentCtrls = {};

  @override
  void initState() {
    super.initState();
    _commentCtrl = TextEditingController();
    _existingReview = widget.existingReview;

    // Initialize dish rating controllers
    for (var item in widget.order.items) {
      final dishId = item['maMonAn'] ?? item['foodId'] ?? item['id'];
      if (dishId != null) {
        _dishRatings[dishId] = 5;
        _dishCommentCtrls[dishId] = TextEditingController();
      }
    }

    _loadExistingReview();
  }

  Future<void> _loadExistingReview() async {
    if (_existingReview == null) {
      final rev = await ReviewService.getReviewByOrder(widget.order.orderId);
      if (mounted) {
        setState(() {
          _existingReview = rev;
        });
      }
    }

    if (_existingReview != null) {
      _selectedRating = _existingReview!.rating;
      _commentCtrl.text = _existingReview!.comment ?? '';
      _uploadedImageUrl = _existingReview!.image;

      if (_existingReview!.isEdited) {
        _canEdit = false;
        _editRestrictionReason = "Đánh giá này đã được chỉnh sửa 1 lần.";
      } else if (_existingReview!.createdAt.isNotEmpty) {
        try {
          final dt = DateTime.parse(_existingReview!.createdAt);
          if (DateTime.now().difference(dt).inHours >= 24) {
            _canEdit = false;
            _editRestrictionReason = "Đã quá 24 giờ kể từ khi gửi đánh giá.";
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingCheck = false;
      });
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    for (var ctrl in _dishCommentCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (!_canEdit || _isUploadingImage) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final bytes = await image.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final uploadedUrl = await ReviewService.uploadImageBase64(base64Str);

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          if (uploadedUrl != null) {
            _uploadedImageUrl = uploadedUrl;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không thể tải hình ảnh lên server'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF1B1E28) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _existingReview != null ? "Cập nhật thành công!" : "Đánh giá thành công!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Cảm ơn bạn đã gửi ý kiến đánh giá. Ý kiến của bạn giúp nhà hàng cải thiện chất lượng tốt hơn!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF98A2B3) : const Color(0xFF667085),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (idx) {
                    return Icon(
                      idx < _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFFFB800),
                      size: 24,
                    );
                  }),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFC6011),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Đã hiểu & Hoàn tất",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting || !_canEdit) return;

    setState(() {
      _isSubmitting = true;
    });

    Map<String, dynamic> res;
    if (_existingReview != null) {
      // Update
      res = await ReviewService.updateReview(
        reviewId: _existingReview!.id,
        rating: _selectedRating,
        comment: _commentCtrl.text,
        image: _uploadedImageUrl,
      );
    } else {
      // Create new
      final List<Map<String, dynamic>> dishRatingsList = [];
      _dishRatings.forEach((dishId, rating) {
        dishRatingsList.add({
          'dishId': dishId,
          'rating': rating,
          'comment': _dishCommentCtrls[dishId]?.text,
        });
      });

      res = await ReviewService.submitReview(
        orderId: widget.order.orderId,
        rating: _selectedRating,
        comment: _commentCtrl.text,
        image: _uploadedImageUrl,
        dishRatings: dishRatingsList,
      );
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (res['success'] == true) {
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Đã có lỗi xảy ra'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return "1★ - Rất tệ";
      case 2:
        return "2★ - Không hài lòng";
      case 3:
        return "3★ - Bình thường";
      case 4:
        return "4★ - Rất ngon";
      case 5:
        return "5★ - Xuất sắc!";
      default:
        return "5★ - Xuất sắc!";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12141C) : const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: Text(
          _existingReview != null ? "Chỉnh sửa đánh giá" : "Đánh giá đơn hàng",
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: _isLoadingCheck
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1E28) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TColor.borderOf(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "#DH${widget.order.orderId}",
                              style: const TextStyle(
                                color: Color(0xFFFC6011),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "${widget.order.totalAmount.toStringAsFixed(0)}đ",
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF101828),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.order.restaurantName,
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF344054),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (!_canEdit && _editRestrictionReason != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _editRestrictionReason!,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Overall Rating Picker
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1E28) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TColor.borderOf(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "Chất lượng quán như thế nào?",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            return IconButton(
                              onPressed: _canEdit
                                  ? () {
                                      setState(() {
                                        _selectedRating = star;
                                      });
                                    }
                                  : null,
                              iconSize: 36,
                              icon: Icon(
                                star <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                                color: const Color(0xFFFFB800),
                              ),
                            );
                          }),
                        ),
                        Center(
                          child: Text(
                            _getRatingText(_selectedRating),
                            style: const TextStyle(
                              color: Color(0xFFFC6011),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _commentCtrl,
                          enabled: _canEdit,
                          maxLines: 4,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: "Hãy chia sẻ cảm nhận của bạn về hương vị, thái độ phục vụ...",
                            hintStyle: TextStyle(
                              color: isDark ? const Color(0xFF707688) : const Color(0xFF98A2B3),
                              fontSize: 13,
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF12141C) : const Color(0xFFF7F7F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: TColor.borderOf(context)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: TColor.borderOf(context)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Image Attachment Picker Section
                        if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) ...[
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _uploadedImageUrl!,
                                  width: double.infinity,
                                  height: 160,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 120,
                                    color: Colors.grey.withOpacity(0.2),
                                    child: const Center(child: Icon(Icons.image_not_supported)),
                                  ),
                                ),
                              ),
                              if (_canEdit)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _uploadedImageUrl = null;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ] else if (_canEdit) ...[
                          OutlinedButton.icon(
                            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                            icon: _isUploadingImage
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add_a_photo_rounded, color: Color(0xFFFC6011), size: 18),
                            label: Text(
                              _isUploadingImage ? "Đang tải ảnh..." : "Đính kèm hình ảnh món ăn",
                              style: const TextStyle(
                                color: Color(0xFFFC6011),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFC6011)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Per-dish Rating section
                  if (widget.order.items.isNotEmpty && _existingReview == null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Đánh giá chi tiết từng món",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    ...widget.order.items.map((item) {
                      final dishId = item['maMonAn'] ?? item['foodId'] ?? item['id'];
                      final dishName = item['tenMonAn'] ?? item['foodName'] ?? 'Món ăn';
                      if (dishId == null) return const SizedBox();

                      final rating = _dishRatings[dishId] ?? 5;
                      final ctrl = _dishCommentCtrls[dishId];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1B1E28) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: TColor.borderOf(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    dishName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    final itemObj = {
                                      "maMonAn": dishId,
                                      "tenMonAn": dishName,
                                      "name": dishName,
                                      "giaMonAn": item['gia'] ?? item['price'] ?? 65000,
                                      "price": item['gia'] ?? item['price'] ?? 65000,
                                      "hinhAnh": item['hinhAnh'] ?? item['image'] ?? '',
                                      "image": item['hinhAnh'] ?? item['image'] ?? '',
                                      "maQuan": item['maQuan'] ?? item['restaurantId'] ?? 1,
                                      "restaurantId": item['maQuan'] ?? item['restaurantId'] ?? 1,
                                      "tenQuan": widget.order.restaurantName,
                                      "trangThaiMon": "DANG_BAN",
                                      "soLuongMon": 99,
                                    };
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ItemDetailsView(itemObj: itemObj),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4EE),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFFE5D6)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          "Đi đến sản phẩm",
                                          style: TextStyle(
                                            color: Color(0xFFFC6011),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFC6011), size: 9),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: List.generate(5, (idx) {
                                final star = idx + 1;
                                return IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _dishRatings[dishId] = star;
                                    });
                                  },
                                  iconSize: 26,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: const Color(0xFFFFB800),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 6),
                            if (ctrl != null)
                              TextField(
                                controller: ctrl,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: "Nhận xét về món $dishName (tùy chọn)",
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF12141C) : const Color(0xFFF7F7F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: TColor.borderOf(context)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (_canEdit && !_isSubmitting) ? _handleSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6011),
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _existingReview != null ? "Lưu thay đổi" : "Gửi đánh giá",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
