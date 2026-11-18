import 'dart:convert';
import 'package:flutter/material.dart';

class ParsedItemCustomization {
  final String cleanName;
  final String? size;
  final List<String> toppings;
  final String? dishNote;

  const ParsedItemCustomization({
    required this.cleanName,
    this.size,
    this.toppings = const [],
    this.dishNote,
  });

  bool get hasCustomization =>
      (size != null && size!.isNotEmpty) ||
      toppings.isNotEmpty ||
      (dishNote != null && dishNote!.isNotEmpty);
}

class OrderItemCustomizationParser {
  static ParsedItemCustomization parse(Map item) {
    String cleanName = (item['tenMonAn'] ??
            item['foodName'] ??
            item['name'] ??
            'Món ăn')
        .toString()
        .trim();

    String? size = item['size']?.toString().trim();
    if (size != null && size.isEmpty) size = null;

    List<String> toppings = [];
    final rawToppings = item['toppings'];
    if (rawToppings is List) {
      toppings = rawToppings
          .map((t) => t.toString().trim())
          .where((t) => t.isNotEmpty)
          .toList();
    } else if (rawToppings is String && rawToppings.trim().isNotEmpty) {
      toppings = rawToppings
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    String? dishNote = (item['dishNote'] ?? item['ghiChuMon'])?.toString().trim();
    if (dishNote != null && dishNote.isEmpty) dishNote = null;

    final rawGhiChu = (item['ghiChu'] ?? item['note'] ?? '').toString().trim();

    // 1. Try parsing JSON ghiChu first
    if (rawGhiChu.startsWith('{') && rawGhiChu.endsWith('}')) {
      try {
        final parsed = jsonDecode(rawGhiChu);
        if (parsed is Map) {
          if (size == null && parsed['size'] != null) {
            size = parsed['size'].toString().trim();
          }
          if (toppings.isEmpty && parsed['toppings'] != null) {
            final pt = parsed['toppings'];
            if (pt is List) {
              toppings = pt
                  .map((t) => t.toString().trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
            } else if (pt is String && pt.trim().isNotEmpty) {
              toppings = pt
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
            }
          }
          if (dishNote == null) {
            final dn = (parsed['ghiChu'] ?? parsed['dishNote'])?.toString().trim();
            if (dn != null && dn.isNotEmpty) dishNote = dn;
          }
        }
      } catch (_) {}
    } else if (rawGhiChu.isNotEmpty) {
      // 2. Parse text ghiChu (e.g. "Topping: Trân Châu Trắng • it da" or "it da")
      final segments = rawGhiChu.split('•').map((s) => s.trim()).toList();
      for (final seg in segments) {
        final lower = seg.toLowerCase();
        if (lower.startsWith('topping:')) {
          final topContent = seg.substring(8).trim();
          final splitTops = topContent
              .split(',')
              .map((t) => t.trim())
              .where((t) => t.isNotEmpty)
              .toList();
          for (final st in splitTops) {
            if (!toppings.contains(st)) toppings.push(st);
          }
        } else if (dishNote == null || dishNote.isEmpty) {
          dishNote = seg;
        } else if (!dishNote.contains(seg)) {
          dishNote = '$dishNote • $seg';
        }
      }
    }

    // 3. Extract size from cleanName if present (e.g. "Trà Sữa Khoai Môn (Size L)")
    final sizeRegex = RegExp(r'\((Size\s*[:\s]*[^)]+|Phần\s*[:\s]*[^)]+|[SML])\)$', caseSensitive: false);
    final match = sizeRegex.firstMatch(cleanName);
    if (match != null) {
      if (size == null || size.isEmpty) {
        final captured = match.group(1) ?? '';
        size = captured.replaceAll(RegExp(r'^Size\s*[:\s]*', caseSensitive: false), '').trim();
      }
      cleanName = cleanName.replaceAll(sizeRegex, '').trim();
    }

    if (size != null && size.toLowerCase().startsWith('size ')) {
      size = size.substring(5).trim();
    }

    return ParsedItemCustomization(
      cleanName: cleanName.isNotEmpty ? cleanName : 'Món ăn',
      size: size,
      toppings: toppings,
      dishNote: dishNote,
    );
  }
}

extension _ListPush<T> on List<T> {
  void push(T val) => add(val);
}

class OrderItemCustomizationTags extends StatelessWidget {
  final ParsedItemCustomization customization;
  final bool showDefaultIfEmpty;

  const OrderItemCustomizationTags({
    super.key,
    required this.customization,
    this.showDefaultIfEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!customization.hasCustomization && !showDefaultIfEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Size
          if (customization.size != null && customization.size!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0C2A44) : const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Size: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                    ),
                    Text(
                      customization.size ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (showDefaultIfEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  'Khẩu phần: Tiêu chuẩn',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),

          // 2. Topping / Lựa chọn
          if (customization.toppings.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF06331C) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isDark ? const Color(0xFF15803D) : const Color(0xFFBBF7D0),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Topping: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        customization.toppings.join(', '),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFBBF7D0) : const Color(0xFF15803D),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Ghi chú món
          if (customization.dishNote != null && customization.dishNote!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF382305) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: isDark ? const Color(0xFFB45309) : const Color(0xFFFDE68A),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ghi chú món: ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      customization.dishNote!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
