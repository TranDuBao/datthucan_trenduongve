import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../services/upload_service.dart';
import '../../../widgets/custom_toast.dart';

class FoodFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final List<Map<String, dynamic>> categories;
  final Future<void> Function(Map<String, dynamic> data) onSave;

  const FoodFormSheet({
    super.key,
    this.initialData,
    required this.categories,
    required this.onSave,
  });

  static void show(
    BuildContext context, {
    Map<String, dynamic>? initialData,
    required List<Map<String, dynamic>> categories,
    required Future<void> Function(Map<String, dynamic> data) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FoodFormSheet(
        initialData: initialData,
        categories: categories,
        onSave: onSave,
      ),
    );
  }

  @override
  State<FoodFormSheet> createState() => _FoodFormSheetState();
}

class _FoodFormSheetState extends State<FoodFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late TextEditingController _descController;

  int? _selectedCategoryId;
  String _status = 'DANG_BAN'; // 'DANG_BAN', 'HET_HANG', 'TAM_NGUNG'
  String _imageUrl = '';
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  List<String> _selectedTags = [];
  final TextEditingController _customTagController = TextEditingController();

  static const List<Map<String, dynamic>> _presetTagGroups = [
    {
      'title': 'Thời gian phục vụ',
      'icon': Icons.access_time_rounded,
      'color': Color(0xFF0284C7),
      'tags': ['~5 phút', '~10 phút', '~15 phút', '~20 phút', '~25 phút', 'Chế biến nhanh'],
    },
    {
      'title': 'Năng lượng & Calo',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFEA580C),
      'tags': ['120 kcal', '180 kcal', '250 kcal', '320 kcal', '450 kcal', '580 kcal', 'Ít calo / Eat Clean', 'Giàu Protein'],
    },
    {
      'title': 'Đặc tính & Trọng điểm',
      'icon': Icons.eco_rounded,
      'color': Color(0xFF16A34A),
      'tags': ['Đá riêng / Nóng', 'Bánh tươi mỗi ngày', 'Nguyên liệu tươi sạch', 'Không cay', 'Cay vừa', 'Ăn chay'],
    },
  ];

  bool get isEdit => widget.initialData != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameController = TextEditingController(text: d?['tenMonAn'] ?? '');
    
    // Parse price cleanly (e.g. 35000)
    final num? rawPrice = d?['giaMonAn'] ?? d?['gia'];
    _priceController = TextEditingController(
      text: rawPrice != null ? rawPrice.toInt().toString() : '',
    );

    final rawQty = d?['soLuongMon'] ?? d?['quantity'] ?? 50;
    _qtyController = TextEditingController(text: rawQty.toString());
    _descController = TextEditingController(text: d?['moTa'] ?? d?['mota'] ?? d?['description'] ?? '');

    _imageUrl = (d?['img'] ?? d?['image'] ?? '').toString();

    // Match category
    if (d?['maDanhMuc'] != null) {
      _selectedCategoryId = int.tryParse(d!['maDanhMuc'].toString());
    } else if (widget.categories.isNotEmpty) {
      final firstCatId = widget.categories[0]['maDanhMuc'];
      _selectedCategoryId = firstCatId is int ? firstCatId : int.tryParse(firstCatId.toString());
    }

    final rawStatus = (d?['trangThaiMon'] ?? 'DANG_BAN').toString().toUpperCase();
    if (rawStatus == 'HET_MON') {
      _status = 'HET_HANG';
    } else if (['DANG_BAN', 'HET_HANG', 'TAM_NGUNG'].contains(rawStatus)) {
      _status = rawStatus;
    } else {
      _status = 'DANG_BAN';
    }

    final rawTraits = d?['dacTinh'] ?? d?['dactinh'];
    if (rawTraits is List) {
      _selectedTags = rawTraits.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    } else if (rawTraits is String && rawTraits.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTraits);
        if (decoded is List) {
          _selectedTags = decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        } else {
          _selectedTags = rawTraits.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        _selectedTags = rawTraits.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    } else if (!isEdit) {
      _selectedTags = ['~10 phút', '180 kcal'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _descController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final uploadedUrl = await UploadService.uploadImageBase64(base64Image);

      if (mounted) {
        setState(() {
          _isUploadingImage = false;
          if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
            _imageUrl = uploadedUrl;
            CustomToast.showSuccess(context, 'Tải ảnh món ăn thành công');
          } else {
            CustomToast.showError(context, 'Không thể tải ảnh lên máy chủ');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        CustomToast.showError(context, 'Lỗi chọn ảnh: $e');
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;

    final payload = <String, dynamic>{
      'tenMonAn': _nameController.text.trim(),
      'giaMonAn': price,
      'soLuongMon': qty,
      'trangThaiMon': _status,
      'moTa': _descController.text.trim(),
      'dacTinh': jsonEncode(_selectedTags),
      if (_selectedCategoryId != null) 'maDanhMuc': _selectedCategoryId,
      if (_imageUrl.isNotEmpty) 'img': _imageUrl,
    };

    setState(() => _isSubmitting = true);
    try {
      await widget.onSave(payload);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        CustomToast.showError(context, 'Lỗi lưu món ăn: $e');
      }
    }
  }

  Widget _buildImagePreview() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget imageWidget;
    if (_imageUrl.isEmpty) {
      imageWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_rounded, size: 36, color: TColor.primary),
          const SizedBox(height: 6),
          Text(
            'Chọn ảnh món ăn',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TColor.secondaryTextOf(context),
            ),
          ),
        ],
      );
    } else if (_imageUrl.startsWith('data:image')) {
      try {
        final base64Str = _imageUrl.split(',').last;
        imageWidget = Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      } catch (_) {
        imageWidget = Icon(Icons.fastfood_rounded, size: 40, color: TColor.primary);
      }
    } else {
      final formatted = SVKey.formatImageUrl(_imageUrl);
      imageWidget = Image.network(
        formatted,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Icon(Icons.fastfood_rounded, size: 40, color: TColor.primary),
      );
    }

    return Center(
      child: Stack(
        children: [
          InkWell(
            onTap: _isUploadingImage ? null : _pickImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232A34) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _imageUrl.isNotEmpty ? TColor.primary : TColor.borderOf(context),
                  width: _imageUrl.isNotEmpty ? 2 : 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: _isUploadingImage
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFC6011), strokeWidth: 2.5),
                      )
                    : imageWidget,
              ),
            ),
          ),
          if (_imageUrl.isNotEmpty && !_isUploadingImage)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFFFC6011),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Tiêu đề
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Chỉnh Sửa Món Ăn' : 'Thêm Món Ăn Mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: TColor.primaryTextOf(context),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: TColor.secondaryTextOf(context)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Khung chọn ảnh
              _buildImagePreview(),
              const SizedBox(height: 20),

              // Tên món ăn
              Text(
                'Tên Món Ăn *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Cơm Tấm Sườn Bì Chả...',
                  hintStyle: TextStyle(fontSize: 13, color: TColor.secondaryTextOf(context)),
                  prefixIcon: const Icon(Icons.restaurant_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF28303D) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên món ăn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Chi Tiết / Mô Tả Món Ăn
              Text(
                'Chi Tiết / Mô Tả Món Ăn',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Mô tả nguyên liệu, hương vị đặc trưng, thành phần dinh dưỡng...',
                  hintStyle: TextStyle(fontSize: 13, color: TColor.secondaryTextOf(context)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF28303D) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                ),
              ),
              const SizedBox(height: 16),

              // Đặc Trưng & Nhãn Món Ăn (Hiển thị cho khách)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sell_outlined, size: 16, color: Color(0xFFFC6011)),
                      const SizedBox(width: 6),
                      Text(
                        'Đặc Trưng & Nhãn Món Ăn',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
                      ),
                    ],
                  ),
                  Text(
                    'Đã chọn: ${_selectedTags.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFC6011)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Danh sách nhãn đã chọn
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF28303D) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TColor.borderOf(context)),
                ),
                child: _selectedTags.isEmpty
                    ? Text(
                        'Chưa chọn nhãn nào. Bấm vào các gợi ý bên dưới hoặc thêm nhãn riêng.',
                        style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context), fontStyle: FontStyle.italic),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF2EC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFD1BD)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tag,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFC6011)),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTags.remove(tag);
                                    });
                                  },
                                  child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFFC6011)),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 10),

              // Gợi ý nhanh các nhóm nhãn (Thời gian, Calo, Đặc tính)
              ..._presetTagGroups.map((group) {
                final groupTags = group['tags'] as List<String>;
                final groupColor = group['color'] as Color;
                final groupIcon = group['icon'] as IconData;
                final groupTitle = group['title'] as String;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(groupIcon, size: 13, color: groupColor),
                          const SizedBox(width: 4),
                          Text(
                            groupTitle,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: groupColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: groupTags.map((tag) {
                          final isSelected = _selectedTags.contains(tag);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedTags.remove(tag);
                                } else {
                                  _selectedTags.add(tag);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? groupColor.withOpacity(0.12)
                                    : (isDark ? const Color(0xFF1F2430) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? groupColor : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected) ...[
                                    Icon(Icons.check_rounded, size: 12, color: groupColor),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? groupColor : TColor.primaryTextOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),

              // Ô nhập nhãn tự do
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _customTagController,
                        decoration: InputDecoration(
                          hintText: 'Nhập nhãn tùy ý (vd: Ít cay, Không hành...)',
                          hintStyle: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF28303D) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: TColor.borderOf(context))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: TColor.borderOf(context))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6011),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final val = _customTagController.text.trim();
                        if (val.isNotEmpty && !_selectedTags.contains(val)) {
                          setState(() {
                            _selectedTags.add(val);
                            _customTagController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Danh mục món ăn
              if (widget.categories.isNotEmpty) ...[
                Text(
                  'Danh Mục Món',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: widget.categories.any((c) => (c['maDanhMuc'] is int ? c['maDanhMuc'] : int.tryParse(c['maDanhMuc'].toString())) == _selectedCategoryId)
                      ? _selectedCategoryId
                      : null,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF28303D) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                  ),
                  items: widget.categories.map((c) {
                    final id = c['maDanhMuc'] is int ? c['maDanhMuc'] as int : int.tryParse(c['maDanhMuc'].toString()) ?? 0;
                    final name = (c['tenDanhMuc'] ?? 'Danh mục').toString();
                    return DropdownMenuItem<int>(
                      value: id,
                      child: Text(name, style: TextStyle(fontSize: 13, color: TColor.primaryTextOf(context))),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategoryId = val);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Giá bán & Số lượng tồn kho
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giá Bán (VNĐ) *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '50000',
                            prefixIcon: const Icon(Icons.attach_money_rounded, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF28303D) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Nhập giá bán';
                            final p = double.tryParse(val.trim());
                            if (p == null || p < 0) return 'Giá không hợp lệ';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Số Lượng (phần) *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '50',
                            prefixIcon: const Icon(Icons.inventory_2_rounded, size: 18),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF28303D) : const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TColor.borderOf(context))),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Nhập số lượng';
                            final q = int.tryParse(val.trim());
                            if (q == null || q < 0) return 'Số lượng >= 0';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Trạng thái món ăn
              Text(
                'Trạng Thái Phục Vụ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusChip('DANG_BAN', 'Còn Hàng', const Color(0xFF10B981), Icons.check_circle_rounded),
                  const SizedBox(width: 8),
                  _buildStatusChip('HET_HANG', 'Hết Món', const Color(0xFFEF4444), Icons.cancel_rounded),
                  const SizedBox(width: 8),
                  _buildStatusChip('TAM_NGUNG', 'Tạm Ngưng', const Color(0xFFF59E0B), Icons.pause_circle_rounded),
                ],
              ),
              const SizedBox(height: 24),

              // Nút hành động
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: TColor.borderOf(context)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Hủy',
                        style: TextStyle(fontWeight: FontWeight.w700, color: TColor.primaryTextOf(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFC6011),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      icon: _isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        isEdit ? 'Cập Nhật Món' : 'Thêm Món Mới',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, Color color, IconData icon) {
    final isSelected = _status == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _status = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : (isDark ? const Color(0xFF28303D) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : TColor.borderOf(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : TColor.secondaryTextOf(context), size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : TColor.secondaryTextOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

