import 'package:flutter/material.dart';
import '../common/color_extension.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import 'custom_toast.dart';

class ReviewReplySheet extends StatefulWidget {
  final ReviewModel review;
  final ValueChanged<String>? onReplied;

  const ReviewReplySheet({
    super.key,
    required this.review,
    this.onReplied,
  });

  static Future<void> show(
    BuildContext context, {
    required ReviewModel review,
    ValueChanged<String>? onReplied,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReviewReplySheet(
        review: review,
        onReplied: onReplied,
      ),
    );
  }

  @override
  State<ReviewReplySheet> createState() => _ReviewReplySheetState();
}

class _ReviewReplySheetState extends State<ReviewReplySheet> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.review.reply ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      CustomToast.showError(context, 'Vui lòng nhập nội dung phản hồi');
      return;
    }

    setState(() => _isSubmitting = true);
    final res = await ReviewService.replyReview(
      reviewId: widget.review.id,
      reply: text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res['success'] == true) {
      CustomToast.showSuccess(context, 'Phản hồi đánh giá thành công');
      widget.onReplied?.call(text);
      Navigator.pop(context);
    } else {
      CustomToast.showError(context, res['message'] ?? 'Không thể gửi phản hồi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.review.reply != null && widget.review.reply!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: TColor.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.reply_rounded, color: TColor.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEditing ? 'Chỉnh Sửa Phản Hồi' : 'Phản Hồi Đánh Giá',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: TColor.primaryTextOf(context),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Customer Review Snippet
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232833) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TColor.borderOf(context), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.review.customerName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: TColor.primaryTextOf(context),
                      ),
                    ),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: index < widget.review.rating
                              ? const Color(0xFFF59E0B)
                              : Colors.grey.shade400,
                        );
                      }),
                    ),
                  ],
                ),
                if (widget.review.comment != null && widget.review.comment!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.review.comment!,
                    style: TextStyle(
                      fontSize: 12,
                      color: TColor.secondaryTextOf(context),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Input Text Field
          Text(
            'Nội dung phản hồi của quán:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TColor.primaryTextOf(context),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Cảm ơn quý khách đã ủng hộ quán! Quán sẽ ghi nhận và cải thiện...',
              hintStyle: TextStyle(fontSize: 12.5, color: TColor.secondaryTextOf(context)),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E232E) : const Color(0xFFF1F5F9),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TColor.borderOf(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: TColor.primary, width: 1.5),
              ),
            ),
            style: TextStyle(fontSize: 13, color: TColor.primaryTextOf(context)),
          ),
          const SizedBox(height: 18),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: TColor.borderOf(context)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Hủy',
                    style: TextStyle(color: TColor.secondaryTextOf(context), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEditing ? 'Lưu Phản Hồi' : 'Gửi Phản Hồi',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

