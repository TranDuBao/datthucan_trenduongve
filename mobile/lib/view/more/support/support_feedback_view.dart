import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/color_extension.dart';
import '../../../common/format_utils.dart';
import '../../../common/globs.dart';
import '../../../model/support_model.dart';
import '../../../services/support_service.dart';
import '../../../services/upload_service.dart';
import '../../../widgets/modern_notification_modal.dart';

class SupportFeedbackView extends StatefulWidget {
  const SupportFeedbackView({super.key});

  @override
  State<SupportFeedbackView> createState() => _SupportFeedbackViewState();
}

class _SupportFeedbackViewState extends State<SupportFeedbackView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _contentCtrl = TextEditingController();

  final List<String> _feedbackTypes = [
    'Chất lượng món ăn',
    'Giao hàng',
    'Thanh toán',
    'Lỗi ứng dụng',
    'Thái độ phục vụ',
    'Khác',
  ];
  late String _selectedType;
  double _rating = 5.0;
  final List<String> _uploadedImages = [];
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = _feedbackTypes.first;
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_uploadedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.supportFeedbackMaxImages)),
      );
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (picked == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final bytes = await picked.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final uploadedUrl = await UploadService.uploadImageBase64(base64Str);

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        setState(() {
          _uploadedImages.add(uploadedUrl);
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.supportFeedbackUploadFailed)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final req = SupportFeedbackRequest(
        loaiGopY: _selectedType,
        noiDung: _contentCtrl.text.trim(),
        danhGiaSao: _rating.round(),
        danhSachAnh: _uploadedImages,
      );

      final res = await SupportService.submitFeedback(req);

      if (!mounted) return;

      if (res['success'] == true) {
        ModernNotificationModal.showSuccess(
          context: context,
          title: 'Cảm ơn bạn!',
          message:
              'Góp ý của bạn đã được ghi nhận. Đội ngũ Food Route sẽ luôn nỗ lực cải thiện để mang đến dịch vụ tốt nhất!',
          badgeText: 'ĐÃ GHI NHẬN GÓP Ý',
          buttonText: 'Đóng',
          onConfirm: () {
            Navigator.pop(context);
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? context.l10n.supportFeedbackFailedMsg)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E232E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryTextOf(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.supportFeedbackTitle,
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E232E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type Selection
                    Text(
                      context.l10n.supportFeedbackTopic,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _feedbackTypes.map((type) {
                        final isSelected = _selectedType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedType = type;
                              });
                            }
                          },
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                          selectedColor: TColor.primary,
                          backgroundColor: isDark ? const Color(0xFF262C3A) : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? TColor.primary : (isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Star Rating
                    Text(
                      'Mức độ hài lòng của bạn',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBar.builder(
                          initialRating: _rating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 32,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFB300),
                          ),
                          onRatingUpdate: (rating) {
                            setState(() {
                              _rating = rating;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_rating.toInt()}/5 sao',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TColor.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Content Field
                    Text(
                      'Nội dung chi tiết *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _contentCtrl,
                      maxLines: 5,
                      style: TextStyle(fontSize: 14, color: TColor.primaryTextOf(context)),
                      decoration: InputDecoration(
                        hintText: 'Mô tả chi tiết trải nghiệm, đề xuất hoặc sự cố bạn gặp phải...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF262C3A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: TColor.primary, width: 1.5),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 5) {
                          return 'Vui lòng nhập nội dung góp ý (tối thiểu 5 ký tự)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Image Attachments
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hình ảnh đính kèm (tối đa 3)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${_uploadedImages.length}/3',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (int i = 0; i < _uploadedImages.length; i++)
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(SVKey.formatImageUrl(_uploadedImages[i])),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _uploadedImages.removeAt(i);
                                    });
                                  },
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        if (_uploadedImages.length < 3)
                          InkWell(
                            onTap: _isUploadingImage ? null : _pickAndUploadImage,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF333E52) : const Color(0xFFCBD5E1),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _isUploadingImage
                                  ? const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined, color: TColor.primary, size: 26),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Thêm ảnh',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        context.l10n.supportFeedbackSubmit,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
