import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../common/color_extension.dart';
import '../common/format_utils.dart';
import '../common/globs.dart';
import '../providers/cart_provider.dart';
import '../common/locator.dart';
import '../services/socket_service.dart';
import '../widgets/custom_toast.dart';

class CustomerVoucherModal extends StatefulWidget {
  const CustomerVoucherModal({super.key});

  @override
  State<CustomerVoucherModal> createState() => _CustomerVoucherModalState();
}

class _CustomerVoucherModalState extends State<CustomerVoucherModal> {
  final TextEditingController _codeController = TextEditingController();
  bool _loading = true;
  bool _validating = false;
  List<dynamic> _availableVouchers = [];
  late void Function(dynamic) _voucherListener;

  @override
  void initState() {
    super.initState();
    _fetchStoreVouchers();
    _voucherListener = (_) {
      if (mounted) _fetchStoreVouchers();
    };
    locator<SocketService>().listenToVoucherUpdates(_voucherListener);
  }

  @override
  void dispose() {
    locator<SocketService>().offVoucherUpdates(_voucherListener);
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchStoreVouchers() async {
    final cart = context.read<CartProvider>();
    final storeId = cart.items.isNotEmpty ? cart.items.first.restaurantId : cart.restaurantId;

    setState(() {
      _loading = true;
    });

    final token = Globs.udValueString(KKey.authToken);
    final url = "${SVKey.mainUrl}/api/v1/vouchers?maQuan=$storeId&includeSystem=true";

    try {
      final futures = <Future<http.Response>>[
        http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 5)),
      ];

      if (token.isNotEmpty) {
        futures.add(
          http.get(
            Uri.parse("${SVKey.mainUrl}/api/v1/customer/my-vouchers"),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(const Duration(seconds: 5)),
        );
      }

      final responses = await Future.wait(futures);
      final List<dynamic> combined = [];
      final Set<String> seenCodes = {};

      for (var res in responses) {
        if (res.statusCode == 200) {
          final body = json.decode(res.body);
          if (body['data'] is List) {
            for (var item in body['data']) {
              final c = (item['maCode'] ?? item['code'] ?? '').toString().toUpperCase();
              final n = (item['tenVoucher'] ?? item['name'] ?? '').toString().toLowerCase();
              final st = (item['computedStatus'] ?? item['trangThai'] ?? '').toString().toUpperCase();
              final mq = item['maQuan'] != null ? int.tryParse(item['maQuan'].toString()) : null;

              if (c.isEmpty || seenCodes.contains(c)) continue;
              if (c.contains('FREESHIP') || n.contains('freeship')) continue;
              if (st == 'TAM_TAT' || st == 'HET_HAN' || st == 'HET_LUOT') continue;
              if (storeId != null && mq != null && mq != storeId) continue;

              seenCodes.add(c);
              combined.add(item);
            }
          }
        }
      }

      // Sort: Currently applied first, then eligible vouchers, then by smallest missing amount
      combined.sort((a, b) {
        final codeA = (a['maCode'] ?? a['code'] ?? '').toString();
        final codeB = (b['maCode'] ?? b['code'] ?? '').toString();
        if (cart.appliedVoucherCode == codeA) return -1;
        if (cart.appliedVoucherCode == codeB) return 1;

        final minA = double.tryParse((a['dieuKienDonToiThieu'] ?? 0).toString()) ?? 0.0;
        final minB = double.tryParse((b['dieuKienDonToiThieu'] ?? 0).toString()) ?? 0.0;
        final eligA = cart.subTotal >= minA;
        final eligB = cart.subTotal >= minB;

        if (eligA != eligB) {
          return eligA ? -1 : 1;
        }
        return minA.compareTo(minB);
      });

      if (mounted) {
        setState(() {
          _availableVouchers = combined;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyVoucherCode(String code) async {
    final rawCode = code.trim().toUpperCase();
    if (rawCode.isEmpty) {
      CustomToast.showError(context, context.l10n.voucherInputRequired);
      return;
    }
    if (rawCode.contains('FREESHIP')) {
      CustomToast.showError(context, context.l10n.voucherInvalid);
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.subTotal <= 0) {
      CustomToast.showError(context, context.l10n.cartEmptyTitle);
      return;
    }

    final storeId = cart.items.isNotEmpty ? cart.items.first.restaurantId : cart.restaurantId;

    setState(() => _validating = true);
    final token = Globs.udValueString(KKey.authToken);

    try {
      final res = await http.post(
        Uri.parse("${SVKey.mainUrl}/api/v1/vouchers/apply"),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'maCode': rawCode,
          'maQuan': storeId,
          'orderTotal': cart.subTotal,
        }),
      ).timeout(const Duration(seconds: 5));

      final body = json.decode(res.body);

      if (res.statusCode == 200 && body['data'] != null) {
        final data = body['data'];
        final discountAmount = double.tryParse((data['discountAmount'] ?? 0).toString()) ?? 0.0;
        final maVoucher = data['maVoucher'] != null ? int.tryParse(data['maVoucher'].toString()) : null;

        cart.applyVoucher(
          data['maCode'] ?? rawCode,
          discountAmount,
          voucherId: maVoucher,
        );

        if (mounted) {
          CustomToast.showSuccess(
            context,
            context.l10n.voucherAppliedSuccess((data['maCode'] ?? rawCode).toString(), _formatVND(discountAmount)),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          CustomToast.showError(context, body['message'] ?? context.l10n.voucherInvalid);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, context.l10n.voucherNetworkError);
      }
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  String _formatVND(dynamic amount) {
    final val = double.tryParse((amount ?? 0).toString()) ?? 0.0;
    return FormatUtils.formatCurrency(val, locale: Localizations.localeOf(context));
  }

  Widget _buildVoucherCard(
    BuildContext context,
    Map<String, dynamic> v,
    CartProvider cart,
    bool isDark,
  ) {
    final code = (v['maCode'] ?? v['code'] ?? '').toString();
    final isPercent = v['loaiGiam'] == 'PERCENT';
    final giamGia = double.tryParse((v['giamGia'] ?? 0).toString()) ?? 0.0;
    final giamToiDa = double.tryParse((v['giaTriGiamToiDa'] ?? 0).toString()) ?? 0.0;
    final donToiThieu = double.tryParse((v['dieuKienDonToiThieu'] ?? 0).toString()) ?? 0.0;
    final isApplied = cart.appliedVoucherCode == code;
    final isEligible = donToiThieu == 0 || cart.subTotal >= donToiThieu;
    final missingAmount = donToiThieu - cart.subTotal;

    String discountBadge;
    if (isPercent) {
      discountBadge = "${giamGia.toInt()}%";
    } else if (giamGia >= 1000 && giamGia % 1000 == 0) {
      discountBadge = "${(giamGia / 1000).toInt()}K";
    } else {
      discountBadge = _formatVND(giamGia);
    }

    void handleAction() {
      if (isApplied) {
        cart.removeVoucher();
        CustomToast.showSuccess(context, context.l10n.voucherRemovedSuccess);
      } else if (isEligible) {
        _applyVoucherCode(code);
      } else {
        CustomToast.showError(
          context,
          "Đơn hiện tại: ${_formatVND(cart.subTotal)}. Cần mua thêm ${_formatVND(missingAmount)} để dùng mã $code (Tối thiểu ${_formatVND(donToiThieu)}).",
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TColor.cardOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApplied
              ? const Color(0xFF10B981)
              : (isEligible
                  ? TColor.primary.withValues(alpha: 0.35)
                  : TColor.borderOf(context)),
          width: isApplied ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _validating ? null : handleAction,
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Left Ticket Stub (Discount Pill)
                Container(
                  width: 76,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isApplied
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : (isEligible
                            ? TColor.primary.withValues(alpha: 0.1)
                            : (isDark ? const Color(0xFF252B36) : const Color(0xFFF3F4F6))),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPercent ? Icons.percent_rounded : Icons.confirmation_number_rounded,
                        size: 18,
                        color: isApplied
                            ? const Color(0xFF10B981)
                            : (isEligible ? TColor.primary : TColor.secondaryTextOf(context)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        discountBadge,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isApplied
                              ? const Color(0xFF10B981)
                              : (isEligible ? TColor.primary : TColor.secondaryTextOf(context)),
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "GIẢM",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isApplied
                              ? const Color(0xFF10B981)
                              : (isEligible ? TColor.primary : TColor.secondaryTextOf(context)),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Dashed vertical line
                CustomPaint(
                  size: const Size(1, double.infinity),
                  painter: _DashedLinePainter(
                    color: isDark ? const Color(0xFF384050) : const Color(0xFFE2E8F0),
                  ),
                ),

                // 3. Middle Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Code pill & applied badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C3240) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: TColor.primaryTextOf(context),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            if (isApplied) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                                    SizedBox(width: 3),
                                    Text(
                                      "Đang dùng",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),

                        // Title
                        Text(
                          v['tenVoucher'] ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: TColor.primaryTextOf(context),
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Condition & Missing info
                        if (donToiThieu > 0)
                          Text(
                            isPercent && giamToiDa > 0
                                ? "Tối đa ${_formatVND(giamToiDa)} • Đơn từ ${_formatVND(donToiThieu)}"
                                : "Đơn tối thiểu ${_formatVND(donToiThieu)}",
                            style: TextStyle(
                              fontSize: 11,
                              color: TColor.secondaryTextOf(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 4),
                        // Eligibility / Status line
                        if (!isEligible)
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFFEA580C)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "Mua thêm ${_formatVND(missingAmount)} để dùng",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFEA580C),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else if (!isApplied)
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text(
                                "Đủ điều kiện áp dụng",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // 4. Right Action Button
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
                  child: Center(
                    child: isApplied
                        ? OutlinedButton(
                            onPressed: () {
                              cart.removeVoucher();
                              CustomToast.showSuccess(context, context.l10n.voucherRemovedSuccess);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 1.2),
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              "Bỏ chọn",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          )
                        : isEligible
                            ? ElevatedButton(
                                onPressed: _validating ? null : () => _applyVoucherCode(code),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: TColor.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text(
                                  "Áp dụng",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: handleAction,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF3E4758) : const Color(0xFFCBD5E1),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  "Chưa đủ",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: TColor.secondaryTextOf(context),
                                  ),
                                ),
                              ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                  Icon(Icons.confirmation_number_rounded, color: TColor.primary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.voucherSelectTitle,
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
          const SizedBox(height: 12),

          // Manual Code Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: context.l10n.voucherInputHint,
                    hintStyle: TextStyle(fontSize: 13, color: TColor.secondaryTextOf(context)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF2C3240) : const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _validating ? null : () => _applyVoucherCode(_codeController.text),
                child: _validating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(context.l10n.commonApply, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (cart.appliedVoucherCode != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.voucherAppliedCode(cart.appliedVoucherCode ?? ''),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 13),
                          ),
                          Text(
                            context.l10n.voucherDiscountAmount(_formatVND(cart.discountAmount)),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      cart.removeVoucher();
                      CustomToast.showSuccess(context, context.l10n.voucherRemovedSuccess);
                    },
                    child: Text(context.l10n.voucherRemove, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          Text(
            context.l10n.voucherAvailableTitle,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TColor.secondaryTextOf(context)),
          ),
          const SizedBox(height: 10),

          // Available Vouchers List
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: TColor.primary))
                : _availableVouchers.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.voucherNoAvailableFromStore,
                          style: TextStyle(fontSize: 13, color: TColor.secondaryTextOf(context)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _availableVouchers.length,
                        itemBuilder: (context, index) {
                          final v = Map<String, dynamic>.from(_availableVouchers[index]);
                          return _buildVoucherCard(context, v, cart, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 6;
    while (startY < size.height - 6) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
