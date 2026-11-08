import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/color_extension.dart';
import '../../../common/format_utils.dart';
import '../../../model/support_model.dart';
import '../../../providers/support_provider.dart';
import '../../../widgets/skeleton/support_skeleton.dart';

class SupportFaqView extends StatefulWidget {
  const SupportFaqView({super.key});

  @override
  State<SupportFaqView> createState() => _SupportFaqViewState();
}

class _SupportFaqViewState extends State<SupportFaqView> {
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedGroupId; // null means All

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().loadFaqs();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final support = context.watch<SupportProvider>();
    final groups = support.faqGroups;
    final questions = support.getFilteredQuestions(selectedGroupId: _selectedGroupId);

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E232E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryTextOf(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.supportFaqTitle,
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? const Color(0xFF1E232E) : Colors.white,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => support.setFaqSearchQuery(val),
                style: TextStyle(fontSize: 14, color: TColor.primaryTextOf(context)),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                  hintText: context.l10n.supportFaqSearchHint,
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            support.setFaqSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // Group Filter Chips (Horizontal Scroll)
          if (groups.isNotEmpty)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: isDark ? const Color(0xFF1E232E) : Colors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    label: context.l10n.notifTabAll,
                    isSelected: _selectedGroupId == null,
                    onTap: () {
                      setState(() {
                        _selectedGroupId = null;
                      });
                    },
                    isDark: isDark,
                  ),
                  for (final g in groups)
                    _buildFilterChip(
                      label: g.tenNhom,
                      isSelected: _selectedGroupId == g.maNhom,
                      onTap: () {
                        setState(() {
                          _selectedGroupId = g.maNhom;
                        });
                      },
                      isDark: isDark,
                    ),
                ],
              ),
            ),

          const Divider(height: 1, thickness: 1, color: Color(0x1A000000)),

          // Question List
          Expanded(
            child: support.isLoadingFaq && groups.isEmpty
                ? const SupportFaqSkeleton()
                : questions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, size: 54, color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
                              const SizedBox(height: 12),
                              Text(
                                context.l10n.supportFaqEmpty,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hãy thử tìm từ khóa khác hoặc liên hệ hotline để được hỗ trợ.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => context.read<SupportProvider>().loadFaqs(forceRefresh: true),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: questions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final q = questions[index];
                            return _buildFaqTile(q, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? TColor.primary
                : (isDark ? const Color(0xFF262C3A) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? TColor.primary
                  : (isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(FaqQuestionModel q, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: TColor.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.help_outline_rounded, color: TColor.primary, size: 18),
          ),
          title: Text(
            q.cauHoi,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                q.cauTraLoi,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
