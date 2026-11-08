import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/color_extension.dart';
import '../../../common/format_utils.dart';
import '../../../providers/support_provider.dart';
import '../../../widgets/skeleton/support_skeleton.dart';
import 'support_chat_view.dart';
import 'support_ticket_create_view.dart';

class SupportTicketListView extends StatefulWidget {
  const SupportTicketListView({super.key});

  @override
  State<SupportTicketListView> createState() => _SupportTicketListViewState();
}

class _SupportTicketListViewState extends State<SupportTicketListView> {
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().loadMyTickets();
    });
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'MOI':
        return Colors.blue.withValues(alpha: 0.12);
      case 'DANG_XU_LY':
        return Colors.orange.withValues(alpha: 0.12);
      case 'DA_GIAI_QUYET':
        return Colors.green.withValues(alpha: 0.12);
      case 'DA_DONG':
        return Colors.grey.withValues(alpha: 0.15);
      default:
        return Colors.blue.withValues(alpha: 0.12);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'MOI':
        return Colors.blue;
      case 'DANG_XU_LY':
        return Colors.orange;
      case 'DA_GIAI_QUYET':
        return Colors.green;
      case 'DA_DONG':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    switch (status) {
      case 'MOI':
        return context.l10n.supportStatusNew;
      case 'DANG_XU_LY':
        return context.l10n.supportStatusProcessing;
      case 'DA_GIAI_QUYET':
        return context.l10n.supportStatusResolved;
      case 'DA_DONG':
        return context.l10n.supportStatusClosed;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final support = context.watch<SupportProvider>();
    final allTickets = support.myTickets;

    final filteredTickets = allTickets.where((t) {
      if (_selectedStatus == 'ALL') return true;
      if (_selectedStatus == 'CLOSED') {
        return t.trangThai == 'DA_GIAI_QUYET' || t.trangThai == 'DA_DONG';
      }
      return t.trangThai == _selectedStatus;
    }).toList();

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
          context.l10n.supportMyTicketsTitle,
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const SupportTicketCreateView()),
          );
        },
        backgroundColor: TColor.primary,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 20),
        label: Text(
          context.l10n.supportNewReportBtn,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: isDark ? const Color(0xFF1E232E) : Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(context.l10n.commonAll, 'ALL', isDark),
                _buildFilterChip(context.l10n.supportStatusNew, 'MOI', isDark),
                _buildFilterChip(context.l10n.supportStatusProcessing, 'DANG_XU_LY', isDark),
                _buildFilterChip(context.l10n.supportStatusResolved, 'CLOSED', isDark),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0x1A000000)),

          // Ticket List
          Expanded(
            child: support.isLoadingTickets && allTickets.isEmpty
                ? const SupportTicketListSkeleton()
                : filteredTickets.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inbox_rounded, size: 56, color: isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
                              const SizedBox(height: 12),
                              Text(
                                context.l10n.supportNoTicketsTitle,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.supportNoTicketsDesc,
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
                        onRefresh: () => context.read<SupportProvider>().loadMyTickets(forceRefresh: true),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: filteredTickets.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final t = filteredTickets[index];
                            final hasUnread = t.soTinChuaDocUser > 0;

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (ctx) => SupportChatView(ticket: t)),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E232E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: hasUnread
                                        ? TColor.primary
                                        : (isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0)),
                                    width: hasUnread ? 1.5 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '#${t.maPhieu}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                t.loaiSuCo,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _getStatusBg(t.trangThai),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _getStatusText(context, t.trangThai),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: _getStatusColor(t.trangThai),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      t.tinNhanCuoi ?? t.moTa,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          t.thoiGianTinCuoi != null
                                              ? '${t.thoiGianTinCuoi!.day}/${t.thoiGianTinCuoi!.month} lúc ${t.thoiGianTinCuoi!.hour.toString().padLeft(2, '0')}:${t.thoiGianTinCuoi!.minute.toString().padLeft(2, '0')}'
                                              : '',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                        ),

                                        if (hasUnread)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: TColor.primary,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              context.l10n.supportNewMessagesCount(t.soTinChuaDocUser),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = value;
          });
        },
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
}
