import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../model/support_model.dart';
import '../../../services/support_service.dart';
import '../../../services/upload_service.dart';
import 'support_chat_view.dart';

class SupportTicketCreateView extends StatefulWidget {
  final int? prefilledOrderId;

  const SupportTicketCreateView({super.key, this.prefilledOrderId});

  @override
  State<SupportTicketCreateView> createState() => _SupportTicketCreateViewState();
}

class _SupportTicketCreateViewState extends State<SupportTicketCreateView> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _orderIdCtrl = TextEditingController();

  final List<String> _issueTypes = [
    'Đơn hàng',
    'Thanh toán',
    'Quán ăn',
    'Lỗi ứng dụng',
    'Khác',
  ];

  late String _selectedType;
  final List<String> _uploadedImages = [];
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedType = _issueTypes.first;
    if (widget.prefilledOrderId != null) {
      _orderIdCtrl.text = widget.prefilledOrderId.toString();
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _orderIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_uploadedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa đính kèm 3 hình ảnh.')),
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
            const SnackBar(content: Text('Tải ảnh thất bại. Vui lòng thử lại!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
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
      final req = CreateTicketRequest(
        loaiSuCo: _selectedType,
        moTa: _descCtrl.text.trim(),
        tieuDe: 'Hỗ trợ: $_selectedType',
        maDonHang: _orderIdCtrl.text.trim().isNotEmpty ? int.tryParse(_orderIdCtrl.text.trim()) : null,
        danhSachAnh: _uploadedImages,
      );

      final ticket = await SupportService.createTicket(req);

      if (!mounted) return;

      if (ticket != null) {
        // Redirect directly to live chat view and replace current create view
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (ctx) => SupportChatView(ticket: ticket)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi yêu cầu hỗ trợ thất bại. Vui lòng thử lại!')),
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
          'Báo Cáo Sự Cố',
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
                    // Issue category
                    Text(
                      'Loại sự cố gặp phải *',
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
                      children: _issueTypes.map((type) {
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

                    const SizedBox(height: 18),

                    // Related Order ID (Optional)
                    Text(
                      'Mã đơn hàng liên quan (tùy chọn)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _orderIdCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: 14, color: TColor.primaryTextOf(context)),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: 1234',
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
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Description
                    Text(
                      'Mô tả chi tiết sự cố *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 5,
                      style: TextStyle(fontSize: 14, color: TColor.primaryTextOf(context)),
                      decoration: InputDecoration(
                        hintText: 'Vui lòng mô tả rõ sự cố để nhân viên hỗ trợ bạn nhanh chóng nhất...',
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
                          return 'Vui lòng mô tả sự cố (tối thiểu 5 ký tự)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Photos Attachment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hình ảnh minh họa sự cố',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${_uploadedImages.length}/3 ảnh',
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
                            onTap: _isUploadingImage ? null : _pickImage,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF333E52) : const Color(0xFFCBD5E1),
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Gửi Báo Cáo & Bắt Đầu Chat',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

