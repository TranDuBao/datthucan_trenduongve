import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/color_extension.dart';
import '../../common/globs.dart';
import '../../common/service_call.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/custom_toast.dart';
import 'reservation_detail_view.dart';
import 'widgets/reservation_booking_widgets.dart';

class ReservationBookingView extends StatefulWidget {
  final Map restaurantObj;
  final DateTime? initialDateTime;

  const ReservationBookingView({
    super.key,
    required this.restaurantObj,
    this.initialDateTime,
  });

  @override
  State<ReservationBookingView> createState() => _ReservationBookingViewState();
}

class _ReservationBookingViewState extends State<ReservationBookingView> {
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay(
    hour: (DateTime.now().hour + 1) % 24,
    minute: (DateTime.now().minute ~/ 15) * 15,
  );
  int _guestCount = 2;
  int? _selectedTableId;
  SeatingAreaPreference _seatingPref = SeatingAreaPreference.auto;

  final TextEditingController _txtName = TextEditingController();
  final TextEditingController _txtPhone = TextEditingController();
  final TextEditingController _txtNote = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final List<TimeOfDay> _quickTimeSlots = const [
    TimeOfDay(hour: 11, minute: 30),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 12, minute: 30),
    TimeOfDay(hour: 18, minute: 0),
    TimeOfDay(hour: 18, minute: 30),
    TimeOfDay(hour: 19, minute: 0),
    TimeOfDay(hour: 19, minute: 30),
    TimeOfDay(hour: 20, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDateTime != null) {
      _selectedDate = widget.initialDateTime!;
      _selectedTime = TimeOfDay(
        hour: widget.initialDateTime!.hour,
        minute: widget.initialDateTime!.minute,
      );
    }
    _loadUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAvailability();
    });
  }

  @override
  void dispose() {
    _txtName.dispose();
    _txtPhone.dispose();
    _txtNote.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    var rawPayload = ServiceCall.userPayload.isEmpty
        ? Globs.udValue(Globs.userPayload)
        : ServiceCall.userPayload;
    var payload = rawPayload is Map ? rawPayload : {};

    var userObj = payload["user"] is Map ? payload["user"] : payload;
    var khachHangObj = payload["khachHang"] is Map ? payload["khachHang"] : payload;

    String name = payload["fullName"]?.toString() ??
        payload["name"]?.toString() ??
        khachHangObj["hoTen"]?.toString() ??
        userObj["fullName"]?.toString() ??
        userObj["tenDangNhap"]?.toString() ??
        "";

    String phone = payload["phoneNumber"]?.toString() ??
        payload["phone"]?.toString() ??
        khachHangObj["sdt"]?.toString() ??
        userObj["sdt"]?.toString() ??
        "";

    _txtName.text = name;
    _txtPhone.text = phone;
  }

  DateTime get _startDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  int get _restaurantId {
    final raw = widget.restaurantObj['maQuan'] ?? widget.restaurantObj['id'] ?? 1;
    return raw is int ? raw : (int.tryParse(raw.toString()) ?? 1);
  }

  Future<void> _checkAvailability() async {
    final provider = context.read<ReservationProvider>();
    await provider.checkAvailability(
      restaurantId: _restaurantId,
      startTime: _startDateTime,
      guestCount: _guestCount,
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primary,
              onPrimary: Colors.white,
              surface: TColor.cardOf(context),
              onSurface: TColor.primaryTextOf(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _checkAvailability();
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.primary,
              onPrimary: Colors.white,
              surface: TColor.cardOf(context),
              onSurface: TColor.primaryTextOf(context),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
      _checkAvailability();
    }
  }

  Future<void> _callRestaurant() async {
    final phone = widget.restaurantObj['soDienThoai'] ??
        widget.restaurantObj['phone'] ??
        widget.restaurantObj['sdt'] ??
        '';
    if (phone.toString().trim().isNotEmpty) {
      final uri = Uri.parse('tel:${phone.toString().trim()}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
    if (mounted) {
      CustomToast.showInfo(context, 'Số điện thoại quán: ${phone.isNotEmpty ? phone : "Chưa cập nhật"}');
    }
  }

  Future<void> _submitReservation() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDateTime.isBefore(DateTime.now())) {
      CustomToast.showError(context, 'Thời gian đặt bàn không được ở quá khứ');
      return;
    }

    final provider = context.read<ReservationProvider>();
    final avail = provider.availabilityResult;
    final bool isAccepting = avail == null || (avail.isOpen && avail.allowReservation);

    if (!isAccepting) {
      CustomToast.showError(
        context,
        avail.message.isNotEmpty
            ? avail.message
            : 'Nhà hàng hiện không thể tiếp nhận đặt bàn vào giờ này',
      );
      return;
    }

    String fullNote = _txtNote.text.trim();
    if (_seatingPref == SeatingAreaPreference.indoor) {
      fullNote = fullNote.isEmpty ? '[Khu vực: Máy lạnh / Trong nhà]' : '$fullNote (Khu vực: Máy lạnh / Trong nhà)';
    } else if (_seatingPref == SeatingAreaPreference.outdoor) {
      fullNote = fullNote.isEmpty ? '[Khu vực: Sân vườn / Ngoài trời]' : '$fullNote (Khu vực: Sân vườn / Ngoài trời)';
    }

    final result = await provider.createReservation(
      restaurantId: _restaurantId,
      startTime: _startDateTime,
      guestCount: _guestCount,
      tableId: _selectedTableId,
      customerName: _txtName.text.trim(),
      customerPhone: _txtPhone.text.trim(),
      note: fullNote,
      restaurantData: widget.restaurantObj,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final ReservationModel? created = result['data'];
      _showSuccessDialog(created);
    } else {
      CustomToast.showError(context, result['message'] ?? 'Không thể đặt bàn');
    }
  }

  void _showSuccessDialog(ReservationModel? resv) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: TColor.cardOf(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Đặt bàn thành công!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TColor.primaryTextOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yêu cầu của bạn đã được gửi tới quán. Quán sẽ sớm xác nhận đặt bàn cho bạn!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: TColor.secondaryTextOf(context),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (resv != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReservationDetailView(reservationId: resv.maDatBan),
                        ),
                      );
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Xem chi tiết đặt bàn',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDateSubtitle() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) return 'Hôm nay';
    if (diffDays == 1) return 'Ngày mai';
    return DateFormat('EEEE', 'vi_VN').format(_selectedDate);
  }

  String _getGuestSubtitle() {
    if (_guestCount <= 2) return 'Bàn chuẩn kèm phục vụ';
    if (_guestCount <= 5) return 'Bàn gia đình rộng rãi';
    return 'Bàn tiệc nhóm đông người';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ReservationProvider>();
    final avail = provider.availabilityResult;

    final storeName = widget.restaurantObj['tenQuan'] ?? widget.restaurantObj['name'] ?? 'Quán ăn';
    final storeAddress = widget.restaurantObj['diaChi'] ?? widget.restaurantObj['address'] ?? '';
    final storeImg = widget.restaurantObj['img'] ?? widget.restaurantObj['image'] ?? '';
    final rawRating = widget.restaurantObj['danhGia'] ?? widget.restaurantObj['rating'] ?? 4.8;
    final double ratingVal = (rawRating is num) ? rawRating.toDouble() : (double.tryParse(rawRating.toString()) ?? 4.8);

    final bool isAccepting = avail == null || (avail.isOpen && avail.allowReservation);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12141A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E222D) : Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: TColor.primaryTextOf(context),
                  size: 16,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          'Đặt bàn trước',
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: InkWell(
                onTap: _callRestaurant,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: TColor.primary.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    color: TColor.primary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Restaurant Card ──────────────────────────────────────────
              ReservationRestaurantCard(
                storeName: storeName,
                storeAddress: storeAddress,
                storeImg: storeImg,
                ratingVal: ratingVal,
                isAccepting: isAccepting,
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // ── Section 1: CHỌN THỜI GIAN ĐẾN ─────────────────────────────
              ReservationSectionTitle(
                stepNum: '1',
                title: 'CHỌN THỜI GIAN ĐẾN',
                trailingText: _getDateSubtitle(),
                trailingColor: TColor.primary,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ReservationDateTimeCard(
                      label: 'Ngày hẹn',
                      value: DateFormat('dd/MM/yyyy').format(_selectedDate),
                      icon: Icons.calendar_today_outlined,
                      isActive: false,
                      onTap: _selectDate,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ReservationDateTimeCard(
                      label: 'Giờ hẹn',
                      value: "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}",
                      icon: Icons.access_time_filled,
                      isActive: true,
                      onTap: _selectTime,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ReservationQuickTimeChips(
                slots: _quickTimeSlots,
                selectedTime: _selectedTime,
                onSelected: (slot) {
                  setState(() => _selectedTime = slot);
                  _checkAvailability();
                },
                isDark: isDark,
              ),

              const SizedBox(height: 22),

              // ── Section 2: SỐ LƯỢNG KHÁCH ─────────────────────────────────
              const ReservationSectionTitle(
                stepNum: '2',
                title: 'SỐ LƯỢNG KHÁCH',
                trailingText: 'Tối đa 20 người',
                trailingColor: Colors.grey,
              ),
              const SizedBox(height: 12),
              ReservationGuestCounter(
                guestCount: _guestCount,
                subtitle: _getGuestSubtitle(),
                onCountChanged: (val) {
                  setState(() => _guestCount = val);
                  _checkAvailability();
                },
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              ReservationQuickGuestChips(
                guestCount: _guestCount,
                onSelected: (count) {
                  setState(() => _guestCount = count);
                  _checkAvailability();
                },
                isDark: isDark,
              ),

              const SizedBox(height: 22),

              // ── Section 3: CHỌN BÀN ĂN ────────────────────────────────────
              ReservationSectionTitle(
                stepNum: '3',
                title: 'CHỌN BÀN ĂN',
                trailingWidget: provider.isCheckingAvailability
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              _buildTableSelectionSection(avail, isDark),

              const SizedBox(height: 22),

              // ── Section 4: THÔNG TIN LIÊN HỆ ─────────────────────────────
              const ReservationSectionTitle(
                stepNum: '4',
                title: 'THÔNG TIN LIÊN HỆ',
              ),
              const SizedBox(height: 12),
              ReservationContactCard(
                nameController: _txtName,
                phoneController: _txtPhone,
                noteController: _txtNote,
                isDark: isDark,
              ),

              const SizedBox(height: 26),

              // ── Submit Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isAccepting ? Colors.grey.shade400 : TColor.primary,
                    disabledBackgroundColor: Colors.grey.shade400,
                    elevation: !isAccepting ? 0 : 3,
                    shadowColor: TColor.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: (!isAccepting || provider.isSubmitting) ? null : _submitReservation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        !isAccepting
                            ? 'KHÔNG THỂ ĐẶT BÀN'
                            : (provider.isSubmitting ? 'ĐANG GỬI YÊU CẦU...' : 'XÁC NHẬN ĐẶT BÀN'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (isAccepting) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Center(
                child: Text(
                  'Giữ chỗ trước tối đa 15 phút so với giờ hẹn',
                  style: TextStyle(
                    fontSize: 12,
                    color: TColor.secondaryTextOf(context),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTableSelectionSection(ReservationAvailabilityResult? avail, bool isDark) {
    if (avail != null && (!avail.isOpen || !avail.allowReservation)) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFE53935), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                avail.message.isNotEmpty ? avail.message : 'Quán không nhận đặt bàn vào giờ này',
                style: const TextStyle(color: Color(0xFFC62828), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 1. Quán tự xếp bàn phù hợp (Khuyến nghị)
        ReservationAreaCard(
          title: 'Quán tự xếp bàn phù hợp',
          subtitle: 'Tối ưu vị trí ngồi thoáng đãng, sắp xếp nhanh nhất khi đến quán',
          badgeText: 'KHUYẾN NGHỊ',
          isSelected: _selectedTableId == null && _seatingPref == SeatingAreaPreference.auto,
          onTap: () {
            setState(() {
              _selectedTableId = null;
              _seatingPref = SeatingAreaPreference.auto;
            });
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        // 2. Khu vực máy lạnh / Trong nhà
        ReservationAreaCard(
          title: 'Khu vực máy lạnh / Trong nhà',
          subtitle: 'Yên tĩnh, thích hợp trò chuyện & làm việc',
          isSelected: _selectedTableId == null && _seatingPref == SeatingAreaPreference.indoor,
          onTap: () {
            setState(() {
              _selectedTableId = null;
              _seatingPref = SeatingAreaPreference.indoor;
            });
          },
          isDark: isDark,
        ),
        const SizedBox(height: 10),

        // 3. Khu vực sân vườn / Ban công ngoài trời
        ReservationAreaCard(
          title: 'Khu vực sân vườn / Ban công ngoài trời',
          subtitle: 'Không gian mở thoáng đãng nhìn phố',
          isSelected: _selectedTableId == null && _seatingPref == SeatingAreaPreference.outdoor,
          onTap: () {
            setState(() {
              _selectedTableId = null;
              _seatingPref = SeatingAreaPreference.outdoor;
            });
          },
          isDark: isDark,
        ),

        // 4. Danh sách bàn cụ thể (nếu quán có cấu hình danh sách bàn thực tế từ DB)
        if (avail != null && avail.availableTables.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...avail.availableTables.map((table) {
            final isSelected = _selectedTableId == table.maBan;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ReservationAreaCard(
                title: table.tenBan,
                subtitle: 'Sức chứa ${table.sucChua} người • Bàn chọn trực tiếp',
                isSelected: isSelected,
                onTap: () {
                  setState(() => _selectedTableId = table.maBan);
                },
                isDark: isDark,
              ),
            );
          }),
        ],
      ],
    );
  }
}
