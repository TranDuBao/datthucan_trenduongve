import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../models/place_model.dart';
import '../services/directions_service.dart';
import 'place_detail_sheet.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  bool _originFocused = false;
  bool _destFocused = false;

  final FocusNode _originFocus = FocusNode();
  final FocusNode _destFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _originFocus.addListener(_onFocusChange);
    _destFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {
      _originFocused = _originFocus.hasFocus;
      _destFocused = _destFocus.hasFocus;
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _originFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        final showList = provider.showSuggestions ||
            _originFocused ||
            _destFocused;

        if (showList) {
          _animCtrl.forward();
        } else {
          _animCtrl.reverse();
        }

        return Column(
          children: [
            _buildSearchCard(provider),
            if (provider.showSuggestions)
              FadeTransition(
                opacity: _fadeAnim,
                child: _buildSuggestionsList(provider),
              )
            else if ((_originFocused || _destFocused) &&
                provider.suggestions.isEmpty)
              FadeTransition(
                opacity: _fadeAnim,
                child: _buildQuickOptions(provider),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchCard(MapProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchField(
            controller: provider.originController,
            focusNode: _originFocus,
            isFocused: _originFocused,
            hint: 'Điểm bắt đầu...',
            icon: Icons.radio_button_checked_rounded,
            iconColor: const Color(0xFF00E676),
            isOrigin: true,
            provider: provider,
            suffix: provider.originPlace != null
                ? _clearButton(() => provider.clearAll())
                : null,
          ),
          _buildDividerWithSwap(provider),
          _buildSearchField(
            controller: provider.destinationController,
            focusNode: _destFocus,
            isFocused: _destFocused,
            hint: 'Tìm điểm đến...',
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFFF5252),
            isOrigin: false,
            provider: provider,
            suffix: provider.destinationPlace != null
                ? _clearButton(() => provider.clearAll())
                : null,
          ),
          _buildTravelModes(provider),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool isOrigin,
    required MapProvider provider,
    Widget? suffix,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isFocused
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) =>
                  provider.onSearchChanged(v, isOrigin: isOrigin),
              onTap: () {
                if (controller.text.isNotEmpty) {
                  provider.onSearchChanged(controller.text,
                      isOrigin: isOrigin);
                }
              },
            ),
          ),
          if (suffix != null) suffix,
          if (isFocused && controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                provider.onSearchChanged('', isOrigin: isOrigin);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDividerWithSwap(MapProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: provider.swapPlaces,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D5E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.swap_vert_rounded,
                color: Color(0xFF00E5FF),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelModes(MapProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _travelModeButton(
              provider, TravelMode.car, Icons.directions_car_rounded, 'Xe hơi'),
          _travelModeButton(provider, TravelMode.foot,
              Icons.directions_walk_rounded, 'Đi bộ'),
          _travelModeButton(provider, TravelMode.bike,
              Icons.directions_bike_rounded, 'Xe đạp'),
        ],
      ),
    );
  }

  Widget _travelModeButton(
    MapProvider provider,
    TravelMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = provider.travelMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => provider.changeTravelMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? const Color(0xFF00E5FF)
                    : Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  color: isSelected
                      ? const Color(0xFF00E5FF)
                      : Colors.white.withValues(alpha: 0.4),
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(MapProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 300),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: provider.isSearching
            ? _buildSearchLoadingIndicator()
            : provider.suggestions.isEmpty
                ? _buildNoResultsPlaceholder()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: provider.suggestions.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withValues(alpha: 0.04),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final place = provider.suggestions[index];
                      return _buildSuggestionItem(place, provider);
                    },
                  ),
      ),
    );
  }

  Widget _buildSearchLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF00E5FF),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Đang tìm kiếm...',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            color: Colors.white.withValues(alpha: 0.3),
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            'Không tìm thấy địa điểm nào',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hãy gõ tiếng Việt có dấu đầy đủ (Ví dụ: Đại học Công nghiệp, Gò Vấp, Quận 1)',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOptions(MapProvider provider) {
    final isOriginActive = _originFocused;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOriginActive)
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: () async {
                await provider.useCurrentLocationAsOrigin();
                _originFocus.unfocus();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          color: Color(0xFF00E5FF), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dùng vị trí của tôi',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF00E5FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Điểm bắt đầu là vị trí GPS hiện tại',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, isOriginActive ? 0 : 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D5E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gõ tên địa điểm để tìm kiếm...',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(PlaceModel place, MapProvider provider) {
    return InkWell(
      onTap: () {
        _originFocus.unfocus();
        _destFocus.unfocus();
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D5E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  place.typeLabel.split(' ').first,
                  style: const TextStyle(fontSize: 16),
                ),
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
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.address,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withValues(alpha: 0.5),
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

  Widget _clearButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(Icons.close_rounded,
          size: 16, color: Colors.white.withValues(alpha: 0.4)),
    );
  }
}
