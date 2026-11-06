import 'package:flutter/material.dart';
import '../../common/color_extension.dart';
import '../../model/store_registration_model.dart';
import '../../services/store_registration_service.dart';
import 'store_registration_view.dart';
import 'widgets/store_approval_celebration_dialog.dart';

class StoreRegistrationStatusView extends StatefulWidget {
  final StoreRegistrationModel initialStatus;

  const StoreRegistrationStatusView({super.key, required this.initialStatus});

  @override
  State<StoreRegistrationStatusView> createState() => _StoreRegistrationStatusViewState();
}

class _StoreRegistrationStatusViewState extends State<StoreRegistrationStatusView> {
  late StoreRegistrationModel _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    if (_status.isApproved) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        StoreApprovalCelebrationDialog.show(context);
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    final updated = await StoreRegistrationService.fetchMyStatus();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (updated != null) {
          _status = updated;
          if (_status.isApproved) {
            StoreRegistrationService.refreshUserProfile();
            StoreApprovalCelebrationDialog.show(context);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          "Trạng Thái Đơn Đăng Ký",
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.refresh_rounded, color: TColor.primaryTextOf(context)),
            onPressed: _isLoading ? null : _refresh,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner Card
            _buildStatusCard(isDark),
            const SizedBox(height: 20),

            // Summary Information Card
            _buildInfoCard(isDark),
            const SizedBox(height: 28),

            // Action Buttons
            if (_status.isRejected)
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => StoreRegistrationView(existingData: _status),
                      ),
                    );
                    if (res == true) {
                      _refresh();
                    }
                  },
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                  label: const Text(
                    "Chỉnh sửa & Gửi lại đơn",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

            if (_status.isApproved)
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    StoreApprovalCelebrationDialog.show(context);
                  },
                  icon: const Icon(Icons.celebration_rounded, color: Colors.white),
                  label: const Text(
                    "Xem thông báo chúc mừng",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    Color bg;
    Color border;
    Color iconColor;
    IconData icon;
    String title;
    String desc;

    if (_status.isPending) {
      bg = isDark ? const Color(0xFF2A2415) : const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      iconColor = const Color(0xFFD97706);
      icon = Icons.access_time_filled_rounded;
      title = "Hồ sơ đang chờ phê duyệt";
      desc =
          "Đơn đăng ký của bạn đang được Ban Quản Trị xem xét. Hệ thống sẽ thông báo ngay khi hồ sơ được duyệt. Bạn không thể gửi đơn mới trong khi đơn này đang chờ xử lý.";
    } else if (_status.isApproved) {
      bg = isDark ? const Color(0xFF162B20) : const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      iconColor = const Color(0xFF16A34A);
      icon = Icons.check_circle_rounded;
      title = "Đơn đăng ký đã được chấp thuận!";
      desc = "Chúc mừng bạn đã chính thức trở thành cửa hàng đối tác của Food Route.";
    } else {
      bg = isDark ? const Color(0xFF2D1717) : const Color(0xFFFEF2F2);
      border = const Color(0xFFFECACA);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.cancel_rounded;
      title = "Đơn đăng ký bị từ chối";
      desc = "Rất tiếc, hồ sơ của bạn chưa đủ điều kiện phê duyệt vào lúc này.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          if (_status.isRejected && (_status.lyDoTuChoi?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF381B1B) : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Lý do: ${_status.lyDoTuChoi}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F29) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thông Tin Hồ Sơ Đã Gửi",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          _buildRow("Tên thương hiệu:", _status.tenQuan, isDark),
          _buildRow("Loại hình:", _status.danhMuc ?? 'Chưa chọn', isDark),
          _buildRow("Địa chỉ quán:", _status.diaChi, isDark),
          _buildRow("Số điện thoại:", _status.sdt, isDark),
          _buildRow("Chủ quán:", _status.hoTenChuQuan, isDark),
          _buildRow("CCCD:", _status.soCCCD, isDark),
          if (_status.diaChiThuongTru?.isNotEmpty ?? false)
            _buildRow("Địa chỉ thường trú:", _status.diaChiThuongTru!, isDark),
          _buildRow("Ngân hàng:", _status.tenNganHang, isDark),
          _buildRow("Số tài khoản:", _status.soTaiKhoanNganHang, isDark),
          _buildRow("Chủ tài khoản:", _status.tenChuTaiKhoan, isDark),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

