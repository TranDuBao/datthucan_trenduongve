import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../common/format_utils.dart';
import '../providers/map_provider.dart';
import '../models/place_model.dart';
import 'place_detail_sheet.dart';
import 'notification_bell.dart';

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
  bool _isExpanded = true;

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
      if (_originFocused || _destFocused) {
        _isExpanded = true;
      }
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
        final showList = _isExpanded &&
            (provider.showSuggestions ||
                _originFocused ||
                _destFocused);

        if (showList) {
          _animCtrl.forward();
        } else {
          _animCtrl.reverse();
        }

        return Column(
          children: [
            _buildHeaderBar(provider),
            AnimatedCrossFade(
              firstChild: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
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
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0E6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.near_me_rounded,
                        color: Color(0xFFFC6011),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.l10n.homeDeliverTo,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF8E8E93),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            provider.originPlace?.name ?? context.l10n.navHome,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1C1C1E),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF1C1C1E),
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const NotificationBell(width: 48, height: 48, size: 22),
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
            label: context.l10n.homePickupPoint,
            subtitleColor: const Color(0xFF00C853),
            icon: Icons.circle,
            iconColor: const Color(0xFF00C853),
            controller: provider.originController,
            focusNode: _originFocus,
            isFocused: _originFocused,
            hint: context.l10n.homePickupHint,
            isOrigin: true,
            provider: provider,
            rightAction: GestureDetector(
              onTap: provider.swapPlaces,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F2F7),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Color(0xFFF2F2F7), height: 1),
          ),
          _buildLocationInputRow(
            label: context.l10n.homeDestination,
            subtitleColor: const Color(0xFFFC6011),
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFFC6011),
            controller: provider.destinationController,
            focusNode: _destFocus,
            isFocused: _destFocused,
            hint: context.l10n.homeDestinationHint,
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Color(0xFFF2F2F7), height: 1),
          ),
          _buildFoodSearchRow(provider),
          _buildDeliveryOptionTabs(provider),
        ],
      ),
    );
  }

  Widget _buildFoodSearchRow(MapProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFC6011).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fastfood_rounded, color: Color(0xFFFC6011), size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      context.l10n.homeFoodSearchAlongRoute,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFFFC6011),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (provider.isSearchingFood) ...[
                      const SizedBox(width: 6),
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(color: Color(0xFFFC6011), strokeWidth: 1.5),
                      ),
                    ],
                  ],
                ),
                TextField(
                  controller: provider.foodKeywordController,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1C1C1E),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: context.l10n.homeFoodSearchHint,
                    hintStyle: GoogleFonts.outfit(
                      color: const Color(0xFFC7C7CC),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  onSubmitted: (v) => provider.setFoodKeyword(v),
                  onChanged: (v) {
                    if (v.isEmpty) {
                      provider.clearFoodKeyword();
                    }
                  },
                ),
              ],
            ),
          ),
          if (provider.foodKeyword.isNotEmpty)
            GestureDetector(
              onTap: provider.clearFoodKeyword,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E5EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93), size: 14),
              ),
            )
          else
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.search_rounded, color: Color(0xFFFC6011), size: 20),
              onPressed: () => provider.setFoodKeyword(provider.foodKeywordController.text),
            ),
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
            label: context.l10n.orderModeQuickStop,
            subtext: provider.travelMinutes > 0
                ? context.l10n.homeSubtextTravel(provider.travelMinutes)
                : context.l10n.homeSubtextQuickPickup,
            icon: Icons.shopping_bag_rounded,
          ),
          const SizedBox(width: 8),
          _foodRouteOptionTab(
            provider: provider,
            option: FoodRouteOption.preOrder,
            label: context.l10n.orderModePreOrder,
            subtext: context.l10n.homeSubtextPreOrderPrep,
            icon: Icons.access_time_filled_rounded,
          ),
          const SizedBox(width: 8),
          _foodRouteOptionTab(
            provider: provider,
            option: FoodRouteOption.dineIn,
            label: context.l10n.orderModeDineIn,
            subtext: context.l10n.homeSubtextDineInRelax,
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
                    itemBuilder: (context, index) {
                      final place = provider.suggestions[index];
                      return _buildSuggestionItem(place, provider, isDark);
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

  Widget _buildQuickOptions(MapProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOriginActive = _originFocused;
    final recentList = provider.recentDestinations;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOriginActive)
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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
                        color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.my_location_rounded,
                          color: Color(0xFFFC6011), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dùng vị trí của tôi',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFFC6011),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Điểm bắt đầu là vị trí GPS hiện tại',
                            style: GoogleFonts.outfit(
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
          if (!isOriginActive && recentList.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 16, color: Color(0xFFFC6011)),
                  const SizedBox(width: 6),
                  Text(
                    '${recentList.length} điểm đến gần nhất',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => provider.clearRecentDestinations(),
                    child: Text(
                      'Xóa',
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...recentList.map((place) => InkWell(
              onTap: () {
                _destFocus.unfocus();
                provider.selectPlace(place, isOrigin: false);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFC6011).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.place_rounded, color: Color(0xFFFC6011), size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            place.address.isNotEmpty ? place.address : 'Tọa độ: ${place.latLng.latitude.toStringAsFixed(4)}, ${place.latLng.longitude.toStringAsFixed(4)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.north_west_rounded,
                      size: 14,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            )),
            Divider(
              color: isDark ? const Color(0xFF232836) : const Color(0xFFF1F5F9),
              height: 1,
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, isOriginActive || recentList.isNotEmpty ? 10 : 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF232836) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E3547) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFFC6011),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Gõ tên địa điểm để tìm kiếm...',
                  style: GoogleFonts.outfit(
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
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

  Widget _buildSuggestionItem(PlaceModel place, MapProvider provider, bool isDark) {
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
