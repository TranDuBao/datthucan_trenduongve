import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/map_provider.dart';
import 'food_stopover_sheet.dart';

class DistantStoresSheet extends StatelessWidget {
  final MapProvider provider;

  const DistantStoresSheet({super.key, required this.provider});

  static void show(BuildContext context, MapProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DistantStoresSheet(provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stores = provider.distantStores;
    final foodKw = provider.foodKeyword;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.alt_route_rounded,
                    color: Color(0xFFFC6011),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quán gợi ý ở xa hơn (${stores.length})',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sắp xếp theo độ lệch tuyến ít nhất để bạn cân nhắc',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          // List of distant stores
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final store = stores[i];
                final storeName = (store['tenQuan'] ?? store['name'] ?? 'Quán ăn').toString();
                final address = (store['diaChi'] ?? store['address'] ?? '').toString();
                final dist = (store['distanceFromRouteMeters'] as num?)?.toInt() ?? 0;
                final matchedFoods = (store['matchedFoods'] as List?) ?? [];
                final primaryFood = store['primaryFood'] ?? (matchedFoods.isNotEmpty ? matchedFoods[0] : null);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: name and distance badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              storeName,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF1E293B),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0E6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Lệch +${dist}m',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFC6011),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          address,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (primaryFood != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.restaurant_rounded, size: 14, color: Color(0xFFFC6011)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${primaryFood['tenMonAn'] ?? primaryFood['name'] ?? foodKw} • ${primaryFood['giaMonAn'] ?? primaryFood['price'] ?? 0}đ',
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF334155),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Actions row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                provider.previewDistantStoreRoute(store);
                              },
                              icon: const Icon(Icons.alt_route_rounded, size: 16, color: Color(0xFFFC6011)),
                              label: Text(
                                'Xem lộ trình rẽ',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFFFC6011),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFFC6011)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                provider.previewDistantStoreRoute(store);
                                FoodStopoverSheet.show(
                                  context,
                                  restaurant: store,
                                  selectedFood: primaryFood as Map<String, dynamic>?,
                                );
                              },
                              icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.white),
                              label: Text(
                                'Đặt món',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFC6011),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
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

