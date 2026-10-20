import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../common/color_extension.dart';
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
  String? _error;
  List<dynamic> _availableVouchers = [];

  @override
  void initState() {
    super.initState();
    _fetchStoreVouchers();
    locator<SocketService>().listenToVoucherUpdates((_) {
      if (mounted) _fetchStoreVouchers();
    });
  }

  @override
  void dispose() {
    locator<SocketService>().offVoucherUpdates();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchStoreVouchers() async {
    final cart = context.read<CartProvider>();
    final storeId = cart.items.isNotEmpty ? cart.items.first.restaurantId : cart.restaurantId;

    setState(() {
      _loading = true;
      _error = null;
    });

    final token = Globs.udValueString(KKey.authToken);
    final url = "${SVKey.mainUrl}/api/v1/vouchers?maQuan=$storeId";

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body['data'] is List) {
          final list = List.from(body['data']).where((item) {
            final c = (item['maCode'] ?? item['code'] ?? '').toString().toUpperCase();
            final n = (item['tenVoucher'] ?? item['name'] ?? '').toString().toLowerCase();
            final st = (item['computedStatus'] ?? item['trangThai'] ?? '').toString().toUpperCase();
            final mq = item['maQuan'] != null ? int.tryParse(item['maQuan'].toString()) : null;

            if (c.contains('FREESHIP') || n.contains('freeship')) return false;
            if (st == 'TAM_TAT' || st == 'HET_HAN' || st == 'HET_LUOT') return false;
            if (storeId != null && mq != null && mq != storeId) return false;

            return true;
          }).toList();
          setState(() {
            _availableVouchers = list;
            _loading = false;
          });
          return;
        }
      }
      setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _applyVoucherCode(String code) async {
    final rawCode = code.trim().toUpperCase();
    if (rawCode.isEmpty) {
      CustomToast.showError(context, "Vui lòng nhập mã voucher");
      return;
    }
    if (rawCode.contains('FREESHIP')) {
      CustomToast.showError(context, "Mã voucher này không còn hiệu lực");
      return;
    }

    final cart = context.read<CartProvider>();
    if (cart.subTotal <= 0) {
      CustomToast.showError(context, "Giỏ hàng đang trống");
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
            "Đã áp dụng mã ${data['maCode']} (Giảm ${_formatVND(discountAmount)})",
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          CustomToast.showError(context, body['message'] ?? "Mã voucher không hợp lệ");
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, "Không thể xác minh mã voucher. Vui lòng kiểm tra lại mạng.");
      }
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  String _formatVND(dynamic amount) {
    final val = double.tryParse((amount ?? 0).toString()) ?? 0.0;
    return "${val.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}₫";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = context.watch<CartProvider>();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                    "Chọn Ưu Đãi Khuyến Mãi",
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
                    hintText: "Nhập mã giảm giá...",
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
                    : const Text("Áp dụng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
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
                            "Đã áp dụng: ${cart.appliedVoucherCode}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 13),
                          ),
                          Text(
                            "Giảm giá: -${_formatVND(cart.discountAmount)}",
                            style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      cart.removeVoucher();
                      CustomToast.showSuccess(context, "Đã gỡ voucher");
                    },
                    child: const Text("Gỡ bỏ", style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          Text(
            "Mã ưu đãi khả dụng",
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
                          "Chưa có voucher khả dụng từ nhà hàng này",
                          style: TextStyle(fontSize: 13, color: TColor.secondaryTextOf(context)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _availableVouchers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final v = Map<String, dynamic>.from(_availableVouchers[index]);
                          final code = v['maCode'] ?? '';
                          final isPercent = v['loaiGiam'] == 'PERCENT';
                          final giamGia = double.tryParse((v['giamGia'] ?? 0).toString()) ?? 0.0;
                          final giamToiDa = double.tryParse((v['giaTriGiamToiDa'] ?? 0).toString()) ?? 0.0;
                          final donToiThieu = double.tryParse((v['dieuKienDonToiThieu'] ?? 0).toString()) ?? 0.0;
                          final isApplied = cart.appliedVoucherCode == code;

                          final isEligible = donToiThieu == 0 || cart.subTotal >= donToiThieu;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TColor.cardOf(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isApplied ? TColor.primary : TColor.borderOf(context),
                                width: isApplied ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: TColor.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    code,
                                    style: TextStyle(color: TColor.primary, fontWeight: FontWeight.w900, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v['tenVoucher'] ?? '',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: TColor.primaryTextOf(context)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isPercent
                                            ? "Giảm ${giamGia.toInt()}%${giamToiDa > 0 ? ' (Tối đa ${_formatVND(giamToiDa)})' : ''}"
                                            : "Giảm ${_formatVND(giamGia)}",
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                                      ),
                                      if (donToiThieu > 0)
                                        Text(
                                          "Đơn từ ${_formatVND(donToiThieu)}",
                                          style: TextStyle(fontSize: 10.5, color: isEligible ? TColor.secondaryTextOf(context) : Colors.redAccent),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isApplied ? Colors.grey : TColor.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: isApplied || !isEligible ? null : () => _applyVoucherCode(code),
                                  child: Text(
                                    isApplied ? "Đã dùng" : isEligible ? "Áp dụng" : "Chưa đủ đơn",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
