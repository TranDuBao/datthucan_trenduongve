import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/place_model.dart';
import '../providers/map_provider.dart';
import 'place_detail_sheet.dart';

class PlaceSearchSuggestionsDropdown extends StatelessWidget {
  final MapProvider provider;
  final bool isOriginActive;
  final FocusNode originFocus;
  final FocusNode destFocus;

  const PlaceSearchSuggestionsDropdown({
    super.key,
    required this.provider,
    required this.isOriginActive,
    required this.originFocus,
    required this.destFocus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171B26) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: provider.isSearching
            ? _buildSearchLoadingIndicator(isDark)
            : provider.suggestions.isEmpty
                ? _buildNoResultsPlaceholder(isDark)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: provider.suggestions.length,
                    separatorBuilder: (_, __) => Divider(
                      color: isDark
                          ? const Color(0xFF232836)
                          : const Color(0xFFF1F5F9),
                      height: 1,
                    ),
                    itemBuilder: (ctx, index) {
                      final place = provider.suggestions[index];
                      return _buildSuggestionItem(ctx, place, provider, isDark);
                    },
                  ),
      ),
    );
  }

  Widget _buildSearchLoadingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: Color(0xFFFC6011),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Đang tìm kiếm...',
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsPlaceholder(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            'Không tìm thấy địa điểm nào',
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy gõ tiếng Việt có dấu đầy đủ (Ví dụ: Đại học Công nghiệp, Gò Vấp, Quận 1)',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(
    BuildContext context,
    PlaceModel place,
    MapProvider provider,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        originFocus.unfocus();
        destFocus.unfocus();
        provider.dismissSuggestions();

        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => PlaceDetailSheet(
            place: place,
            provider: provider,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFFC6011),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.address,
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

