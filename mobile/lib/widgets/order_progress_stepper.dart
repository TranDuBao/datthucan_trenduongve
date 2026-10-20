import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class OrderProgressStepper extends StatefulWidget {
  final String status;
  final bool isCompact;
  final String? estimatedPickupTime;
  final String? cancelReason;
  final String? timeStep1;
  final String? timeStep2;
  final String? timeStep3;
  final String? timeStep4;

  const OrderProgressStepper({
    super.key,
    required this.status,
    this.isCompact = false,
    this.estimatedPickupTime,
    this.cancelReason,
    this.timeStep1,
    this.timeStep2,
    this.timeStep3,
    this.timeStep4,
  });

  static int getStepFromStatus(String statusStr) {
    final s = statusStr.trim().toUpperCase();
    if (s == 'DA_HUY' || s == 'CANCELLED' || s == 'ĐÃ HỦY') return 0;
    if (s == 'HOAN_TAT' ||
        s == 'HOAN_THANH' ||
        s == 'COMPLETED' ||
        s == 'PICKED_UP' ||
        s == 'ĐÃ HOÀN THÀNH' ||
        s == 'ĐÃ HOÀN TẤT' ||
        s == 'THÀNH CÔNG' ||
        s == 'ĐÃ GIAO' ||
        s == 'ĐÃ LẤY') return 5;
    if (s == 'SAN_SANG' ||
        s == 'READY' ||
        s == 'READY_FOR_PICKUP' ||
        s == 'SẴN SÀNG GHÉ LẤY' ||
        s == 'CHỜ GHÉ LẤY' ||
        s == 'SẴN SÀNG') return 4;
    if (s == 'DANG_CHUAN_BI' ||
        s == 'PREPARING' ||
        s == 'ĐANG CHUẨN BỊ' ||
        s == 'CHƯA LÀM') return 3;
    if (s == 'DA_XAC_NHAN' || s == 'CONFIRMED' || s == 'ĐÃ XÁC NHẬN') return 2;
    return 1;
  }

  static bool isCancelledStatus(String statusStr) {
    final s = statusStr.trim().toUpperCase();
    return s == 'DA_HUY' || s == 'CANCELLED' || s == 'ĐÃ HỦY';
  }

  @override
  State<OrderProgressStepper> createState() => _OrderProgressStepperState();
}

class _OrderProgressStepperState extends State<OrderProgressStepper>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = OrderProgressStepper.isCancelledStatus(widget.status);
    final currentStep = OrderProgressStepper.getStepFromStatus(widget.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCancelled) {
      return _buildCancelledBanner(context, isDark);
    }

    if (widget.isCompact) {
      return _buildCompactStepper(context, currentStep, isDark);
    }

    return _buildFullStepper(context, currentStep, isDark);
  }

  Widget _buildCancelledBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF3B30).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_rounded, color: Color(0xFFFF3B30), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Đơn hàng đã hủy",
                  style: TextStyle(
                    color: Color(0xFFFF3B30),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                if (widget.cancelReason != null && widget.cancelReason!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Lý do: ${widget.cancelReason}",
                    style: TextStyle(
                      color: isDark ? const Color(0xFFD0D4E0) : const Color(0xFF666666),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStepper(BuildContext context, int currentStep, bool isDark) {
    final steps = [
      "1. Đã đặt",
      "2. Xác nhận",
      "3. Chuẩn bị",
      "4. Chờ ghé lấy",
      "5. Đã lấy",
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E28) : const Color(0xFFF7F7F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TColor.borderOf(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              final stepNum = index + 1;
              final isPassed = stepNum < currentStep;
              final isActive = stepNum == currentStep;

              Color dotColor = isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0);
              if (isPassed || isActive) dotColor = TColor.primary;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: isActive ? 10 : 8,
                      height: isActive ? 10 : 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: TColor.primary.withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                    if (index < 4)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 2,
                          color: stepNum < currentStep
                              ? TColor.primary
                              : (isDark ? const Color(0xFF2C3240) : const Color(0xFFE0E0E0)),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Trạng thái:",
                style: TextStyle(
                  color: TColor.secondaryTextOf(context),
                  fontSize: 11,
                ),
              ),
              Text(
                steps[currentStep > 0 && currentStep <= 5 ? currentStep - 1 : 0],
                style: TextStyle(
                  color: TColor.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFullStepper(BuildContext context, int currentStep, bool isDark) {
    final stepLabels = [
      "Đã đặt",
      "Quán\nxác nhận",
      "Đang\nchuẩn bị",
      "Chờ\nghé lấy",
      "Đã lấy",
    ];

    final times = [
      widget.timeStep1,
      widget.timeStep2,
      widget.timeStep3,
      widget.timeStep4 ?? (widget.estimatedPickupTime != null ? "Dự kiến ${widget.estimatedPickupTime}" : null),
      null,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TColor.borderOf(context), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final sidePadding = totalWidth / 10;

          return Stack(
            alignment: Alignment.topCenter,
            children: [
              // Background line
              Positioned(
                left: sidePadding,
                right: sidePadding,
                top: 14,
                child: Row(
                  children: List.generate(4, (index) {
                    final isFilled = index + 1 < currentStep;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        height: 3,
                        decoration: BoxDecoration(
                          color: isFilled
                              ? TColor.primary
                              : (isDark ? const Color(0xFF2C3240) : const Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 5 Step Columns (Node + Text + Time)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(5, (index) {
                  final stepNum = index + 1;
                  final isPassed = stepNum < currentStep;
                  final isActive = stepNum == currentStep;
                  final timeStr = times[index];

                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 30,
                          alignment: Alignment.center,
                          child: _buildStepNode(stepNum, isPassed, isActive, isDark),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          stepLabels[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isActive || isPassed
                                ? (isActive ? TColor.primary : TColor.primaryTextOf(context))
                                : TColor.secondaryTextOf(context),
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w900
                                : (isPassed ? FontWeight.w700 : FontWeight.w500),
                            height: 1.15,
                          ),
                        ),
                        if (timeStr != null && timeStr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            timeStr,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isActive ? TColor.primary : TColor.secondaryTextOf(context),
                              fontSize: 8.5,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepNode(int stepNum, bool isPassed, bool isActive, bool isDark) {
    if (isPassed) {
      // Completed step (solid primary with checkmark)
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: TColor.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: TColor.primary.withOpacity(0.3),
              blurRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
      );
    }

    if (isActive) {
      // Active current step with pulse halo
      return AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          final scale = 1.0 + (_pulseCtrl.value * 0.12);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: TColor.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: TColor.primary.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // Future step (dot with number)
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F222E) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF3B4052) : const Color(0xFFD0D4E0),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        "$stepNum",
        style: TextStyle(
          color: isDark ? const Color(0xFF707688) : const Color(0xFF999999),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
