import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../common_widget/smart_network_image.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/map_provider.dart';
import '../../services/order_route_storage.dart';
import '../../services/category_service.dart';
import '../../widgets/custom_toast.dart';
import '../main_tabview/main_tabview.dart';
import '../../widgets/skeleton/reservation_item_skeleton.dart';
import 'widgets/cancel_reservation_sheet.dart';

class ReservationDetailView extends StatefulWidget {
  final int reservationId;

  const ReservationDetailView({super.key, required this.reservationId});

  @override
  State<ReservationDetailView> createState() => _ReservationDetailViewState();
}

class _ReservationDetailViewState extends State<ReservationDetailView> {
  OrderRouteInfo? _routeInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().fetchReservationDetail(widget.reservationId);
      _loadRoute();
    });
  }

  Future<void> _loadRoute() async {
    final info = await OrderRouteStorage.getReservationRoute(widget.reservationId);
    if (mounted) {
      setState(() {
        _routeInfo = info;
      });
    }
  }

  Future<void> _startNavigation(ReservationModel resv) async {
    final navContext = context;
    final mapProvider = Provider.of<MapProvider>(navContext, listen: false);
    final res = resv.cuaHang;
    final storeName = res?.tenQuan ?? 'Quán ăn';
    final storeAddress = res?.diaChi ?? '';
    double? sLat = res?.lat;
    double? sLng = res?.lng;

    if (sLat == null || sLng == null) {
      try {
        final stores = await CategoryService.fetchRestaurantsFromDB();
        final matched = stores.firstWhere(
          (s) => s['maQuan'] == resv.maQuan || s['tenQuan'] == storeName,
          orElse: () => null,
        );
        if (matched != null) {
          sLat = (matched['lat'] as num?)?.toDouble();
          sLng = (matched['lng'] as num?)?.toDouble();
        }
      } catch (_) {}
    }

    if (!mounted) return;

    sLat ??= 10.7812;
    sLng ??= 106.6985;
    final storePos = LatLng(sLat, sLng);

    // Chuyển sang Tab 2 (Bản đồ lộ trình)
    MainTabView.switchTab(navContext, 2);

    final route = _routeInfo ?? await OrderRouteStorage.getReservationRoute(resv.maDatBan);

    await mapProvider.navigateToOrderStore(
      orderId: resv.maDatBan,
      storeName: storeName,
      storeAddress: storeAddress,
      storeLatLng: storePos,
      destinationLatLng: route != null ? LatLng(route.destLat, route.destLng) : null,
      destinationName: route?.destName,
      destinationAddress: route?.destAddress,
      pickupTime: DateFormat('HH:mm • dd/MM').format(resv.thoiGianBatDau.toLocal()),
      status: 'Đặt bàn: ${resv.statusTitle}',
    );

    if (mounted) {
      CustomToast.showSuccess(navContext, "Đang dẫn đường đến $storeName");
    }
  }

  Future<void> _openGoogleMaps(ReservationModel resv) async {
    final res = resv.cuaHang;
    final storeAddress = res?.diaChi ?? '';
    final double? sLat = res?.lat;
    final double? sLng = res?.lng;

    Uri uri;
    if (sLat != null && sLng != null) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$sLat,$sLng');
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(storeAddress)}');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    // Leave room cleanly
    context.read<ReservationProvider>().leaveCurrentReservationRoom();
    super.dispose();
  }

  Future<void> _showCancelDialog(ReservationModel resv) async {
    final success = await CancelReservationSheet.show(
      context: context,
      reservation: resv,
    );
    if (success == true && mounted) {
      context.read<ReservationProvider>().fetchReservationDetail(resv.maDatBan);
    }
  }

  Widget _buildStepItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
  }) {
    final activeColor = TColor.primary;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF323846)
        : const Color(0xFFE0E0E0);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator column
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? activeColor
                      : isCurrent
                          ? activeColor.withValues(alpha: 0.15)
                          : inactiveColor,
                  border: isCurrent ? Border.all(color: activeColor, width: 2) : null,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : isCurrent
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
                            ),
                          )
                        : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? activeColor : inactiveColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent || isCompleted ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent || isCompleted
                          ? TColor.primaryTextOf(context)
                          : TColor.secondaryTextOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStepper(ReservationModel resv) {
    final status = resv.trangThai.toUpperCase();

    // Special banner for cancelled / rejected / no-show
    if (resv.isCancelled || resv.isRejected || resv.isNoShow) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          children: [
            Icon(
              resv.isCancelled
                  ? Icons.cancel_outlined
                  : resv.isRejected
                      ? Icons.block_flipped
                      : Icons.person_off_outlined,
              color: const Color(0xFFE53935),
              size: 26,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resv.statusTitle,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (resv.ghiChu != null && resv.ghiChu!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      resv.ghiChu!,
                      style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isChoXacNhan = status == ReservationStatus.choXacNhan;
    final isDaXacNhan = status == ReservationStatus.daXacNhan;
    final isDangDung = status == ReservationStatus.daDen || status == ReservationStatus.dangSuDung;
    final isHoanTat = status == ReservationStatus.daHoanTat;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến trình đặt bàn',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: TColor.primaryTextOf(context),
            ),
          ),
          const SizedBox(height: 14),
          _buildStepItem(
            context: context,
            title: '1. Gửi yêu cầu',
            subtitle: 'Đang chờ quán xác nhận bàn',
            isCompleted: isDaXacNhan || isDangDung || isHoanTat,
            isCurrent: isChoXacNhan,
            isLast: false,
          ),
          _buildStepItem(
            context: context,
            title: '2. Quán đã xác nhận',
            subtitle: 'Bàn đã được giữ cho bạn',
            isCompleted: isDangDung || isHoanTat,
            isCurrent: isDaXacNhan,
            isLast: false,
          ),
          _buildStepItem(
            context: context,
            title: '3. Nhận bàn & dùng bữa',
            subtitle: 'Khách đến quán và ngồi tại bàn',
            isCompleted: isHoanTat,
            isCurrent: isDangDung,
            isLast: false,
          ),
          _buildStepItem(
            context: context,
            title: '4. Hoàn tất',
            subtitle: 'Bữa ăn kết thúc tốt đẹp',
            isCompleted: isHoanTat,
            isCurrent: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final resv = provider.currentReservation;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        backgroundColor: TColor.cardOf(context),
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryTextOf(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          resv != null ? 'Chi tiết đặt bàn #${resv.maDatBan}' : 'Chi tiết đặt bàn',
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: provider.isLoading && resv == null
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ReservationItemSkeleton(),
            )
          : resv == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 56, color: TColor.secondaryTextOf(context)),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage ?? 'Không tìm thấy lượt đặt bàn',
                        style: TextStyle(color: TColor.secondaryTextOf(context), fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => provider.fetchReservationDetail(widget.reservationId),
                  color: TColor.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Stepper / Banner
                        _buildStatusStepper(resv),

                        // Restaurant Information Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: TColor.cardOf(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TColor.borderOf(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Thông tin quán ăn',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: TColor.primaryTextOf(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: resv.cuaHang?.img != null && resv.cuaHang!.img!.isNotEmpty
                                          ? SmartNetworkImage(imageUrl: resv.cuaHang!.img!, width: 56, height: 56, fit: BoxFit.cover)
                                          : Container(
                                              color: TColor.primary.withValues(alpha: 0.1),
                                              child: Icon(Icons.restaurant_rounded, color: TColor.primary, size: 28),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resv.cuaHang?.tenQuan ?? 'Quán ăn',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: TColor.primaryTextOf(context),
                                          ),
                                        ),
                                        if (resv.cuaHang?.diaChi != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            resv.cuaHang!.diaChi,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: TColor.secondaryTextOf(context)),
                                          ),
                                        ],
                                        if (resv.cuaHang?.sdt != null && resv.cuaHang!.sdt!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Hotline: ${resv.cuaHang!.sdt}',
                                            style: TextStyle(fontSize: 12, color: TColor.primary, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Route Guidance Card (Chỉ dẫn lộ trình 2 chặng)
                        _buildRouteGuidanceCard(context, resv),

                        // Booking Details Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: TColor.cardOf(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TColor.borderOf(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chi tiết lịch hẹn',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: TColor.primaryTextOf(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                context,
                                icon: Icons.calendar_today_rounded,
                                label: 'Thời gian bắt đầu',
                                value: DateFormat('HH:mm • dd/MM/yyyy').format(resv.thoiGianBatDau.toLocal()),
                                isHighlighted: true,
                              ),
                              _buildInfoRow(
                                context,
                                icon: Icons.access_time_rounded,
                                label: 'Dự kiến kết thúc',
                                value: DateFormat('HH:mm • dd/MM/yyyy').format(resv.thoiGianKetThuc.toLocal()),
                              ),
                              _buildInfoRow(
                                context,
                                icon: Icons.table_restaurant_rounded,
                                label: 'Bàn phục vụ',
                                value: resv.ban?.tenBan ?? 'Quán tự xếp bàn',
                              ),
                              _buildInfoRow(
                                context,
                                icon: Icons.people_outline_rounded,
                                label: 'Số lượng khách',
                                value: '${resv.soNguoi} người',
                              ),
                              if (resv.ghiChu != null && resv.ghiChu!.isNotEmpty)
                                _buildInfoRow(
                                  context,
                                  icon: Icons.note_alt_outlined,
                                  label: 'Ghi chú',
                                  value: resv.ghiChu!,
                                ),
                            ],
                          ),
                        ),

                        // Contact Customer Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: TColor.cardOf(context),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: TColor.borderOf(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Người đặt bàn',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: TColor.primaryTextOf(context),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                context,
                                icon: Icons.person_outline_rounded,
                                label: 'Họ tên',
                                value: resv.tenKhachHang ?? 'Khách hàng',
                              ),
                              if (resv.sdtKhachHang != null)
                                _buildInfoRow(
                                  context,
                                  icon: Icons.phone_outlined,
                                  label: 'Số điện thoại',
                                  value: resv.sdtKhachHang!,
                                ),
                            ],
                          ),
                        ),

                        // Cancel Button
                        if (resv.canCancel)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE53935)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => _showCancelDialog(resv),
                              child: const Text(
                                'Hủy đặt bàn',
                                style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildRouteGuidanceCard(BuildContext context, ReservationModel resv) {
    final res = resv.cuaHang;
    final storeName = res?.tenQuan ?? 'Quán ăn';
    final storeAddress = res?.diaChi ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColor.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.alt_route_rounded, color: Color(0xFFFC6011), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Chỉ dẫn lộ trình di chuyển',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: TColor.primaryTextOf(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '2 Chặng',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFFC6011),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── CHẶNG 1: ĐẾN QUÁN (Cam #FC6011) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC6011).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFFFC6011)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Chặng 1: Đến quán ăn',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFFC6011),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      storeName,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: TColor.primaryTextOf(context),
                      ),
                    ),
                    if (storeAddress.isNotEmpty)
                      Text(
                        storeAddress,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: TColor.secondaryTextOf(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Đường nối 2 chặng
          Padding(
            padding: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 2,
                height: 16,
                color: const Color(0xFFCBD5E1),
              ),
            ),
          ),

          // ── CHẶNG 2: ĐẾN ĐÍCH (Xanh lá #10B981) ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded, size: 16, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Chặng 2: Tiếp tục đến đích',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF10B981),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _routeInfo?.destName ?? 'Điểm đến theo lộ trình',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: TColor.primaryTextOf(context),
                      ),
                    ),
                    if ((_routeInfo?.destAddress ?? '').isNotEmpty)
                      Text(
                        _routeInfo!.destAddress,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: TColor.secondaryTextOf(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // ── HÀNG NÚT BẤM DẪN ĐƯỜNG ──
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _openGoogleMaps(resv),
                  icon: const Icon(Icons.map_outlined, size: 16, color: Color(0xFF475467)),
                  label: Text(
                    'Mở Google Maps',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF344054),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFFFC6011),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  onPressed: () => _startNavigation(resv),
                  icon: const Icon(Icons.near_me_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Bắt đầu dẫn đường',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TColor.primary.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: TColor.primary),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TColor.secondaryTextOf(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                color: isHighlighted ? TColor.primary : TColor.primaryTextOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
