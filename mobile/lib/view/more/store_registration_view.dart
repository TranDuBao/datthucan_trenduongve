import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../common/color_extension.dart';
import '../../model/store_registration_model.dart';
import '../../services/store_registration_service.dart';
import 'store_registration_status_view.dart';
import 'widgets/store_approval_celebration_dialog.dart';
import 'widgets/store_bank_picker_sheet.dart';
import 'widgets/store_birthdate_picker_dialog.dart';
import 'widgets/store_category_picker_sheet.dart';
import 'widgets/store_submission_success_dialog.dart';
import 'widgets/store_registration_legal_section.dart';
import 'widgets/store_registration_section_card.dart';
import '../../common/legal_config.dart';
import '../../model/legal_document_model.dart';
import '../../widgets/skeleton/store_registration_skeleton.dart';

class StoreRegistrationView extends StatefulWidget {
  final StoreRegistrationModel? existingData;

  const StoreRegistrationView({super.key, this.existingData});

  @override
  State<StoreRegistrationView> createState() => _StoreRegistrationViewState();
}

class _StoreRegistrationViewState extends State<StoreRegistrationView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _tenQuanCtrl;
  late TextEditingController _diaChiCtrl;
  late TextEditingController _sdtCtrl;
  late TextEditingController _hoTenCtrl;
  late TextEditingController _soCccdCtrl;
  late TextEditingController _diaChiThuongTruCtrl;
  late TextEditingController _soTaiKhoanCtrl;
  late TextEditingController _tenChuTaiKhoanCtrl;

  // Legal Information Controllers
  late TextEditingController _maSoThueCtrl;
  late TextEditingController _soGiayPhepCtrl;
  late TextEditingController _soGiayAttpCtrl;
  LoaiHinhPhapLy _selectedLoaiHinh = LoaiHinhPhapLy.caNhan;

  // Consent & Legal Documents state (NOT pre-checked)
  bool _agreedTerms = false;
  bool _agreedPrivacy = false;
  ActiveLegalDocumentsResponse? _activeLegalDocs;
  bool _isLoadingLegalDocs = false;
  String? _legalDocsError;

  String _selectedDanhMuc = StoreRegistrationService.storeCategories.first;
  String _selectedBankCode = 'VCB';
  String _selectedBankName = 'Vietcombank (VCB)';
  String _selectedBankLogo = 'https://api.vietqr.io/img/VCB.png';
  DateTime? _selectedDob;
  double? _lat;
  double? _lng;

  bool _isLoadingGps = false;
  bool _isSubmitting = false;
  bool _isCheckingStatus = true;

  bool get _canSubmit =>
      _agreedTerms &&
      _agreedPrivacy &&
      _activeLegalDocs != null &&
      _activeLegalDocs!.isReady &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    final d = widget.existingData;
    if (d != null) {
      _isCheckingStatus = false;
    } else {
      _checkExistingStatus();
    }
    _loadActiveLegalDocuments();

    _tenQuanCtrl = TextEditingController(text: d?.tenQuan ?? '');
    _diaChiCtrl = TextEditingController(text: d?.diaChi ?? '');
    _sdtCtrl = TextEditingController(text: d?.sdt ?? '');
    _hoTenCtrl = TextEditingController(text: d?.hoTenChuQuan ?? '');
    _soCccdCtrl = TextEditingController(text: d?.soCCCD ?? '');
    _diaChiThuongTruCtrl = TextEditingController(text: d?.diaChiThuongTru ?? '');
    _soTaiKhoanCtrl = TextEditingController(text: d?.soTaiKhoanNganHang ?? '');
    _tenChuTaiKhoanCtrl = TextEditingController(text: d?.tenChuTaiKhoan ?? '');

    _maSoThueCtrl = TextEditingController(text: d?.maSoThue ?? '');
    _soGiayPhepCtrl = TextEditingController(text: d?.soGiayPhepKinhDoanh ?? '');
    _soGiayAttpCtrl = TextEditingController(text: d?.soGiayAttp ?? '');

    if (d?.loaiHinhPhapLy != null) {
      if (d!.loaiHinhPhapLy == 'HO_KINH_DOANH') {
        _selectedLoaiHinh = LoaiHinhPhapLy.hoKinhDoanh;
      } else if (d.loaiHinhPhapLy == 'DOANH_NGHIEP') {
        _selectedLoaiHinh = LoaiHinhPhapLy.doanhNghiep;
      } else {
        _selectedLoaiHinh = LoaiHinhPhapLy.caNhan;
      }
    }

    if (d?.danhMuc != null && StoreRegistrationService.storeCategories.contains(d!.danhMuc)) {
      _selectedDanhMuc = d.danhMuc!;
    }

    if (d?.tenNganHang != null && d!.tenNganHang.isNotEmpty) {
      _selectedBankName = d.tenNganHang;
    }

    if (d?.ngaySinhChuQuan != null) {
      _selectedDob = DateTime.tryParse(d!.ngaySinhChuQuan!);
    }

    _lat = d?.lat;
    _lng = d?.lng;
  }

  @override
  void dispose() {
    _tenQuanCtrl.dispose();
    _diaChiCtrl.dispose();
    _sdtCtrl.dispose();
    _hoTenCtrl.dispose();
    _soCccdCtrl.dispose();
    _diaChiThuongTruCtrl.dispose();
    _soTaiKhoanCtrl.dispose();
    _tenChuTaiKhoanCtrl.dispose();
    _maSoThueCtrl.dispose();
    _soGiayPhepCtrl.dispose();
    _soGiayAttpCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadActiveLegalDocuments() async {
    setState(() {
      _isLoadingLegalDocs = true;
      _legalDocsError = null;
    });
    try {
      final res = await StoreRegistrationService.fetchActiveLegalDocuments();
      if (!mounted) return;
      setState(() {
        _activeLegalDocs = res;
        _isLoadingLegalDocs = false;
        if (res == null || !res.isReady) {
          _legalDocsError = "Hệ thống hiện chưa xuất bản điều khoản hiệu lực. Vui lòng thử lại sau.";
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLegalDocs = false;
        _legalDocsError = "Không thể tải điều khoản dịch vụ. Vui lòng kiểm tra kết nối mạng.";
      });
    }
  }

  Future<void> _checkExistingStatus() async {
    final status = await StoreRegistrationService.fetchMyStatus();
    if (!mounted) return;
    if (status != null) {
      if (status.isPending || status.isRejected) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (ctx) => StoreRegistrationStatusView(initialStatus: status)),
        );
        return;
      } else if (status.isApproved) {
        StoreApprovalCelebrationDialog.show(context);
      }
    }
    setState(() {
      _isCheckingStatus = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showToast("Quyền truy cập vị trí bị từ chối");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showToast("Vui lòng cấp quyền vị trí trong Cài đặt thiết bị");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        if (_diaChiCtrl.text.isEmpty) {
          _diaChiCtrl.text = "Tọa độ GPS: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}";
        }
      });
      _showToast("Đã lấy vị trí GPS thành công!");
    } catch (e) {
      _showToast("Lỗi lấy vị trí: $e");
    } finally {
      setState(() => _isLoadingGps = false);
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await StoreBirthdatePickerDialog.show(
      context,
      initialDate: _selectedDob,
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  void _showCategoryPicker() {
    StoreCategoryPickerSheet.show(
      context,
      currentCategory: _selectedDanhMuc,
      onSelected: (cat) {
        setState(() => _selectedDanhMuc = cat);
      },
    );
  }

  void _showBankPicker() {
    StoreBankPickerSheet.show(
      context,
      currentBankCode: _selectedBankCode,
      onSelected: (bank) {
        setState(() {
          _selectedBankCode = bank.code;
          _selectedBankName = bank.shortName.isNotEmpty ? "${bank.shortName} (${bank.code})" : bank.name;
          _selectedBankLogo = bank.logo;
        });
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDob == null) {
      _showToast("Vui lòng chọn ngày sinh của chủ quán");
      return;
    }

    final now = DateTime.now();
    int age = now.year - _selectedDob!.year;
    if (now.month < _selectedDob!.month ||
        (now.month == _selectedDob!.month && now.day < _selectedDob!.day)) {
      age--;
    }
    if (age < 18) {
      _showToast("Chủ quán phải từ đủ 18 tuổi trở lên");
      return;
    }

    final cleanCCCD = _soCccdCtrl.text.trim();
    if (!RegExp(r'^\d{12}$').hasMatch(cleanCCCD)) {
      _showToast("Số CCCD phải bao gồm đúng 12 chữ số");
      return;
    }

    final cleanPhone = _sdtCtrl.text.replaceAll(' ', '');
    if (!RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(cleanPhone)) {
      _showToast("Số điện thoại không đúng định dạng");
      return;
    }

    // Validate Legal Requirements
    final legalReq = LegalConfig.getRequirement(_selectedLoaiHinh);
    if (legalReq.requireTaxCode) {
      if (!LegalConfig.validateMaSoThue(_maSoThueCtrl.text)) {
        _showToast("Mã số thuế không đúng định dạng (gồm 10 hoặc 13 chữ số)");
        return;
      }
    }
    if (legalReq.requireBusinessLicense && _soGiayPhepCtrl.text.trim().isEmpty) {
      _showToast("Vui lòng nhập Số Giấy phép ĐKKD cho ${legalReq.label}");
      return;
    }
    if (legalReq.requireFoodSafetyCert && _soGiayAttpCtrl.text.trim().isEmpty) {
      _showToast("Vui lòng nhập Giấy chứng nhận ATTP cho ${legalReq.label}");
      return;
    }

    // Validate Mandatory Consent
    if (!_agreedTerms || !_agreedPrivacy) {
      _showToast("Bạn bắt buộc phải đọc và tích đồng ý cả 2 ô điều khoản và chính sách dữ liệu");
      return;
    }

    if (_activeLegalDocs == null || !_activeLegalDocs!.isReady) {
      _showToast("Hệ thống chưa tải được điều khoản hiệu lực. Vui lòng bấm Thử lại.");
      return;
    }

    setState(() => _isSubmitting = true);

    final model = StoreRegistrationModel(
      tenQuan: _tenQuanCtrl.text.trim(),
      danhMuc: _selectedDanhMuc,
      diaChi: _diaChiCtrl.text.trim(),
      lat: _lat,
      lng: _lng,
      sdt: cleanPhone,
      hoTenChuQuan: _hoTenCtrl.text.trim(),
      ngaySinhChuQuan: "${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}",
      soCCCD: cleanCCCD,
      diaChiThuongTru: _diaChiThuongTruCtrl.text.trim(),
      tenNganHang: _selectedBankName,
      soTaiKhoanNganHang: _soTaiKhoanCtrl.text.trim(),
      tenChuTaiKhoan: _tenChuTaiKhoanCtrl.text.trim().toUpperCase(),

      // Legal & Consent Proof
      loaiHinhPhapLy: legalReq.key,
      maSoThue: _maSoThueCtrl.text.trim().isNotEmpty ? _maSoThueCtrl.text.trim() : null,
      soGiayPhepKinhDoanh: _soGiayPhepCtrl.text.trim().isNotEmpty ? _soGiayPhepCtrl.text.trim() : null,
      soGiayAttp: _soGiayAttpCtrl.text.trim().isNotEmpty ? _soGiayAttpCtrl.text.trim() : null,
      maPhienBanDieuKhoan: _activeLegalDocs?.dieuKhoan?.maPhienBan,
      maPhienBanChinhSach: _activeLegalDocs?.chinhSach?.maPhienBan,
      dongYDieuKhoan: true,
      dongYChinhSachDuLieu: true,
    );

    final res = await StoreRegistrationService.submitRegistration(model);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success'] == true) {
        final savedData = res['data'] as StoreRegistrationModel? ?? model;
        StoreSubmissionSuccessDialog.show(
          context,
          storeName: model.tenQuan,
          maDon: savedData.maDon,
          onViewStatus: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (ctx) => StoreRegistrationStatusView(initialStatus: savedData),
              ),
            );
          },
        );
      } else if (res['code'] == 'TERMS_VERSION_OUTDATED') {
        // Version changed during form filling: reload documents & require user re-consent
        setState(() {
          _agreedTerms = false;
          _agreedPrivacy = false;
        });
        _loadActiveLegalDocuments();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Cập Nhật Điều Khoản", style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              "Điều khoản đối tác hoặc chính sách dữ liệu vừa được cập nhật phiên bản mới. "
              "Ứng dụng đã tự động tải lại văn bản mới, vui lòng đọc và xác nhận đồng ý lại để tiếp tục gửi đơn.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Đã hiểu"),
              ),
            ],
          ),
        );
      } else {
        _showToast(res['message'] ?? "Lỗi nộp đơn");
      }
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isCheckingStatus) {
      return const StoreRegistrationSkeleton();
    }

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        backgroundColor: TColor.bgOf(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: TColor.primaryTextOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Trở Thành Cửa Hàng",
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      TColor.primary.withOpacity(0.12),
                      const Color(0xFFFF8A50).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TColor.primary.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: TColor.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Đăng Ký Đối Tác Food Route",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Mở rộng kinh doanh & tiếp cận hàng nghìn khách hàng dọc theo lộ trình di chuyển.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Thông tin thương hiệu & Vị trí
              StoreRegistrationSectionCard(
                title: "1. Thông tin thương hiệu & Vị trí",
                subtitle: "Tên quán, loại hình kinh doanh và vị trí đón khách",
                icon: Icons.storefront_rounded,
                children: [
                  _buildTextField(
                    controller: _tenQuanCtrl,
                    label: "Tên thương hiệu / Tên quán *",
                    hint: "Ví dụ: Phúc Long Coffee & Tea, Bún Bò Huế Ba Nghị...",
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập tên quán" : null,
                  ),
                  const SizedBox(height: 14),

                  // Category Selector
                  _buildSelectorField(
                    label: "Loại hình kinh doanh *",
                    value: _selectedDanhMuc,
                    icon: Icons.category_outlined,
                    onTap: _showCategoryPicker,
                  ),
                  const SizedBox(height: 14),

                  // Address + GPS Picker
                  _buildTextField(
                    controller: _diaChiCtrl,
                    label: "Địa chỉ vị trí quán *",
                    hint: "Số nhà, tên đường, phường/xã, quận/huyện...",
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập địa chỉ quán" : null,
                    suffix: TextButton.icon(
                      onPressed: _isLoadingGps ? null : _getCurrentLocation,
                      icon: _isLoadingGps
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.my_location_rounded, size: 16, color: TColor.primary),
                      label: Text(
                        "Lấy GPS",
                        style: TextStyle(fontSize: 12, color: TColor.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (_lat != null && _lng != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        "Đã lưu tọa độ: ${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),

              // Section 2: Thông tin chủ quán & định danh
              StoreRegistrationSectionCard(
                title: "2. Thông tin chủ quán & CCCD",
                subtitle: "Thông tin cá nhân người đại diện hợp pháp",
                icon: Icons.person_rounded,
                children: [
                  _buildTextField(
                    controller: _hoTenCtrl,
                    label: "Họ và tên chủ quán *",
                    hint: "Ví dụ: NGUYỄN VĂN A",
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập họ tên chủ quán" : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _sdtCtrl,
                    label: "Số điện thoại liên hệ *",
                    hint: "0901234567",
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập số điện thoại" : null,
                  ),
                  const SizedBox(height: 14),

                  // DOB Picker
                  _buildSelectorField(
                    label: "Ngày sinh chủ quán (Từ 18 tuổi) *",
                    value: _selectedDob != null
                        ? "${_selectedDob!.day}/${_selectedDob!.month}/${_selectedDob!.year}"
                        : "Chọn ngày sinh...",
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickDateOfBirth,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _soCccdCtrl,
                    label: "Số Căn Cước Công Dân (12 số) *",
                    hint: "Nhập đúng 12 chữ số",
                    keyboardType: TextInputType.number,
                    maxLength: 12,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Vui lòng nhập số CCCD";
                      if (!RegExp(r'^\d{12}$').hasMatch(v.trim())) return "CCCD phải đúng 12 chữ số";
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _diaChiThuongTruCtrl,
                    label: "Địa chỉ thường trú *",
                    hint: "Ghi đúng địa chỉ trên thẻ CCCD",
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập địa chỉ thường trú" : null,
                  ),
                ],
              ),

              // Section 3: Tài khoản ngân hàng
              StoreRegistrationSectionCard(
                title: "3. Thông tin ngân hàng nhận thanh toán",
                subtitle: "Tài khoản thụ hưởng doanh thu bán hàng",
                icon: Icons.account_balance_rounded,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ngân hàng sử dụng *",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _showBankPicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1A1F29) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              if (_selectedBankLogo.isNotEmpty) ...[
                                Container(
                                  width: 52,
                                  height: 32,
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                                  ),
                                  child: Image.network(
                                    _selectedBankLogo,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(_selectedBankCode, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: TColor.primary)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ] else ...[
                                const Icon(Icons.account_balance_outlined, size: 20, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Text(
                                  _selectedBankName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _soTaiKhoanCtrl,
                    label: "Số tài khoản ngân hàng *",
                    hint: "Nhập số tài khoản thụ hưởng",
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập số tài khoản ngân hàng" : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _tenChuTaiKhoanCtrl,
                    label: "Tên chủ tài khoản (In hoa không dấu) *",
                    hint: "Ví dụ: NGUYEN VAN A",
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Vui lòng nhập tên chủ tài khoản" : null,
                  ),
                ],
              ),

              // Legal Information & Mandatory Consents
              StoreRegistrationLegalSection(
                selectedLoaiHinh: _selectedLoaiHinh,
                onLoaiHinhChanged: (v) => setState(() => _selectedLoaiHinh = v),
                maSoThueCtrl: _maSoThueCtrl,
                soGiayPhepCtrl: _soGiayPhepCtrl,
                soGiayAttpCtrl: _soGiayAttpCtrl,
                agreedTerms: _agreedTerms,
                onAgreedTermsChanged: (v) => setState(() => _agreedTerms = v),
                agreedPrivacy: _agreedPrivacy,
                onAgreedPrivacyChanged: (v) => setState(() => _agreedPrivacy = v),
                activeLegalDocs: _activeLegalDocs,
                isLoadingLegalDocs: _isLoadingLegalDocs,
                legalDocsError: _legalDocsError,
                onRetryLoadDocs: _loadActiveLegalDocuments,
                showToast: _showToast,
              ),
              const SizedBox(height: 28),

              // Submit Button (Clearly disabled unless both checkboxes are checked and documents loaded)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canSubmit ? TColor.primary : const Color(0xFFCBD5E1),
                    disabledBackgroundColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                    elevation: _canSubmit ? 2 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          "Gửi Hồ Sơ Đăng Ký",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _canSubmit
                                ? Colors.white
                                : (isDark ? const Color(0xFF718096) : const Color(0xFF94A3B8)),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            counterText: "",
            suffixIcon: suffix,
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1F29) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: TColor.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1F29) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

