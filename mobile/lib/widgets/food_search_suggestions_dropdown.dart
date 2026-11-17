import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../common/string_utils.dart';
import '../services/category_service.dart';

class FoodSearchSuggestionsDropdown extends StatefulWidget {
  final String query;
  final List<dynamic> routeRestaurants;
  final ValueChanged<String> onSelectKeyword;
  final VoidCallback onDismiss;

  const FoodSearchSuggestionsDropdown({
    super.key,
    required this.query,
    required this.routeRestaurants,
    required this.onSelectKeyword,
    required this.onDismiss,
  });

  @override
  State<FoodSearchSuggestionsDropdown> createState() =>
      _FoodSearchSuggestionsDropdownState();
}

class _FoodSearchSuggestionsDropdownState
    extends State<FoodSearchSuggestionsDropdown> {
  static List<Map<String, dynamic>>? _cachedOverviewFoods;
  static bool _isLoadingOverview = false;

  @override
  void initState() {
    super.initState();
    _loadOverviewFoods();
  }

  Future<void> _loadOverviewFoods() async {
    if (_cachedOverviewFoods != null || _isLoadingOverview) return;
    _isLoadingOverview = true;
    try {
      final list = await CategoryService.fetchFoodsOverviewFromDB();
      if (mounted) {
        setState(() {
          _cachedOverviewFoods = list
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoadingOverview = false;
        });
      }
    } catch (_) {
      _isLoadingOverview = false;
    }
  }

  List<Map<String, dynamic>> _collectCandidateFoods() {
    final results = <Map<String, dynamic>>[];
    final seenNames = <String>{};

    // 1. Dishes from restaurants on current route (priority)
    for (final res in widget.routeRestaurants) {
      if (res is! Map) continue;
      final storeName = (res['tenQuan'] ?? res['name'] ?? '').toString();
      final dist = (res['distanceFromRouteMeters'] as num?)?.toInt() ?? 0;

      final foods = res['foods'];
      if (foods is List && foods.isNotEmpty) {
        for (final f in foods) {
          if (f is! Map) continue;
          final name = (f['tenMonAn'] ?? f['name'] ?? '').toString().trim();
          final normName = StringUtils.removeDiacritics(name).toLowerCase();
          if (name.isNotEmpty && seenNames.add(normName)) {
            results.add({
              'name': name,
              'storeName': storeName,
              'dist': dist,
              'isOnRoute': true,
            });
          }
        }
      }

      final pf = res['primaryFood'];
      if (pf is Map) {
        final name = (pf['tenMonAn'] ?? pf['name'] ?? '').toString().trim();
        final normName = StringUtils.removeDiacritics(name).toLowerCase();
        if (name.isNotEmpty && seenNames.add(normName)) {
          results.add({
            'name': name,
            'storeName': storeName,
            'dist': dist,
            'isOnRoute': true,
          });
        }
      }
    }

    // 2. Overview foods from database
    if (_cachedOverviewFoods != null) {
      for (final f in _cachedOverviewFoods!) {
        final name = (f['tenMonAn'] ?? f['name'] ?? '').toString().trim();
        final normName = StringUtils.removeDiacritics(name).toLowerCase();
        if (name.isNotEmpty && seenNames.add(normName)) {
          results.add({
            'name': name,
            'storeName': (f['tenQuan'] ?? f['storeName'] ?? '').toString(),
            'dist': null,
            'isOnRoute': false,
          });
        }
      }
    }

    return results;
  }

  List<Map<String, dynamic>> _filterSuggestions(
    String query,
    List<Map<String, dynamic>> allFoods,
  ) {
    final cleanQuery = query.trim().toLowerCase();

    // If query is empty: return top 4 popular foods
    if (cleanQuery.isEmpty) {
      return allFoods.take(4).toList();
    }

    final qNoTone = StringUtils.removeDiacritics(cleanQuery);
    final results = <Map<String, dynamic>>[];
    final seen = <String>{};

    // Priority 1: Dishes where the FIRST word starts with the query prefix (e.g. "b" -> "Bún bò", "Bia", "Bắp")
    for (final f in allFoods) {
      final name = (f['name'] as String).trim();
      final norm = StringUtils.removeDiacritics(name).toLowerCase();
      if (seen.contains(norm)) continue;

      final rawLower = name.toLowerCase();
      if (rawLower.startsWith(cleanQuery) || norm.startsWith(qNoTone)) {
        seen.add(norm);
        results.add(f);
        if (results.length >= 4) break;
      }
    }

    // Priority 2: Dishes where ANY word starts with the query prefix (e.g. "b" -> "Phở bò", "Chả bắp")
    if (results.length < 4) {
      for (final f in allFoods) {
        final name = (f['name'] as String).trim();
        final norm = StringUtils.removeDiacritics(name).toLowerCase();
        if (seen.contains(norm)) continue;

        final words = norm.split(RegExp(r'\s+'));
        final matchesWordPrefix = words.any((w) => w.startsWith(qNoTone));
        if (matchesWordPrefix) {
          seen.add(norm);
          results.add(f);
          if (results.length >= 4) break;
        }
      }
    }

    // Priority 3: Fuzzy matching anywhere in the name
    if (results.length < 4) {
      for (final f in allFoods) {
        final name = (f['name'] as String).trim();
        final norm = StringUtils.removeDiacritics(name).toLowerCase();
        if (seen.contains(norm)) continue;

        if (StringUtils.fuzzyMatch(name, cleanQuery)) {
          seen.add(norm);
          results.add(f);
          if (results.length >= 4) break;
        }
      }
    }

    return results.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final queryText = widget.query.trim();
    final allCandidates = _collectCandidateFoods();
    final suggestions = _filterSuggestions(queryText, allCandidates);

    if (suggestions.isEmpty && queryText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (suggestions.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.8,
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFF2F2F7),
                  indent: 44,
                  endIndent: 14,
                ),
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return _buildSuggestionRow(item, queryText, isDark);
                },
              )
            else if (queryText.isNotEmpty)
              InkWell(
                onTap: () => widget.onSelectKeyword(queryText),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFFC6011),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tìm kiếm "$queryText" trên lộ trình',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFC6011),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFFC6011),
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionRow(
    Map<String, dynamic> item,
    String query,
    bool isDark,
  ) {
    final name = (item['name'] ?? '').toString();
    final store = (item['storeName'] ?? '').toString();
    final isOnRoute = item['isOnRoute'] == true;
    final dist = item['dist'] as int?;

    return InkWell(
      onTap: () => widget.onSelectKeyword(name),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFC6011).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                color: Color(0xFFFC6011),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHighlightedText(name, query, isDark),
                  if (store.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            store,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOnRoute && dist != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• Lệch ${dist}m',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34C759),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.north_west_rounded,
              size: 15,
              color: isDark ? Colors.white38 : const Color(0xFFC7C7CC),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, bool isDark) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final normText = StringUtils.removeDiacritics(text).toLowerCase();
    final normQuery = StringUtils.removeDiacritics(cleanQuery).toLowerCase();
    final matchIdx = normText.indexOf(normQuery);

    if (matchIdx < 0) {
      return Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final endIdx = matchIdx + cleanQuery.length;
    final safeEnd = endIdx <= text.length ? endIdx : text.length;

    final before = text.substring(0, matchIdx);
    final match = text.substring(matchIdx, safeEnd);
    final after = safeEnd < text.length ? text.substring(safeEnd) : '';

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: GoogleFonts.outfit(
          fontSize: 13.5,
          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
        ),
        children: [
          if (before.isNotEmpty)
            TextSpan(
              text: before,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          TextSpan(
            text: match,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFFC6011),
            ),
          ),
          if (after.isNotEmpty)
            TextSpan(
              text: after,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }
}
