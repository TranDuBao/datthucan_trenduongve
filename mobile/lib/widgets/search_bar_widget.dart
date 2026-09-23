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
            _buildHeaderBar(provider),
            const SizedBox(height: 8),
            _buildDeliveryCard(provider),
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

  Widget _buildHeaderBar(MapProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.near_me_rounded,
              color: Color(0xFFFC6011),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GIAO ĐẾN HIỆN TẠI',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        provider.originPlace?.name ?? 'Trang Chủ',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1C1C1E),
                  size: 22,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C3E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(MapProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLocationInputRow(
            label: 'ĐIỂM ĐÓN',
            subtitleColor: const Color(0xFF00C853),
            icon: Icons.circle,
            iconColor: const Color(0xFF00C853),
            controller: provider.originController,
            focusNode: _originFocus,
            isFocused: _originFocused,
            hint: 'Nhập vị trí điểm đón...',
            isOrigin: true,
            provider: provider,
            rightAction: GestureDetector(
              onTap: provider.swapPlaces,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: Color(0xFF636366),
                  size: 18,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: const Color(0xFFF2F2F7), height: 1),
          ),
          _buildLocationInputRow(
            label: 'ĐIỂM ĐẾN',
            subtitleColor: const Color(0xFFFC6011),
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFFC6011),
            controller: provider.destinationController,
            focusNode: _destFocus,
            isFocused: _destFocused,
            hint: 'Chọn địa điểm đến...',
            isOrigin: false,
            provider: provider,
            rightAction: provider.destinationPlace != null
                ? GestureDetector(
                    onTap: provider.clearAll,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5E5EA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF8E8E93),
                        size: 16,
                      ),
                    ),
                  )
                : null,
          ),
          _buildDeliveryOptionTabs(provider),
        ],
      ),
    );
  }

  Widget _buildLocationInputRow({
    required String label,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    required bool isOrigin,
    required MapProvider provider,
    Widget? rightAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8E8E93),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1C1C1E),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFC7C7CC),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
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
              ],
            ),
          ),
          if (rightAction != null) rightAction,
        ],
      ),
    );
  }

  Widget _buildDeliveryOptionTabs(MapProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Row(
        children: [
          _foodRouteOptionTab(
            provider: provider,
            option: FoodRouteOption.takeaway,
            label: 'Ghé mua',
            subtext: '${provider.travelMinutes}p di chuyển',
            icon: Icons.shopping_bag_rounded,
          ),
          const SizedBox(width: 8),
          _foodRouteOptionTab(
            provider: provider,
            option: FoodRouteOption.preOrder,
            label: 'Đặt trước',
            subtext: 'Chuẩn bị ~15p',
            icon: Icons.access_time_filled_rounded,
          ),
          const SizedBox(width: 8),
          _foodRouteOptionTab(
            provider: provider,
            option: FoodRouteOption.dineIn,
            label: 'Ăn tại quán',
            subtext: 'Thoải mái ghé',
            icon: Icons.table_restaurant_rounded,
          ),
        ],
      ),
    );
  }

  Widget _foodRouteOptionTab({
    required MapProvider provider,
    required FoodRouteOption option,
    required String label,
    required String subtext,
    required IconData icon,
  }) {
    final isSelected = provider.foodRouteOption == option;

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.changeFoodRouteOption(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFC6011), Color(0xFFFF7A00)],
                  )
                : null,
            color: isSelected ? null : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE5E5EA),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFC6011).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF636366),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF8E8E93),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFC6011).withValues(alpha: 0.15),
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
                      color: const Color(0xFFFC6011),
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
                      color: Colors.white.withValues(alpha: 0.6),
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
