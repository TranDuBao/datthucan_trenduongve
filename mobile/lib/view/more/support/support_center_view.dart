import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../common/color_extension.dart';
import '../../../common/format_utils.dart';
import '../../../providers/support_provider.dart';
import '../../../widgets/skeleton/support_skeleton.dart';
import '../widgets/store_registration_section_card.dart';
import 'support_faq_view.dart';
import 'support_feedback_view.dart';
import 'support_ticket_list_view.dart';
import 'support_ticket_create_view.dart';

class SupportCenterView extends StatefulWidget {
  const SupportCenterView({super.key});

  @override
  State<SupportCenterView> createState() => _SupportCenterViewState();
}

class _SupportCenterViewState extends State<SupportCenterView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().loadConfig();
      context.read<SupportProvider>().loadFaqs();
      context.read<SupportProvider>().loadMyTickets();
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleanPhone));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.supportDialError(phoneNumber)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email?subject=Hỗ trợ khách hàng Food Route');
    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        throw Exception('Could not launch mailto');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: email));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.supportCopyEmailSuccess(email)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final support = context.watch<SupportProvider>();
    final config = support.config;
    final hotline = config?.hotline ?? '1900 6868';
    final gioLamViec = config?.gioLamViec ?? '08:00 - 22:00 (T2 - CN)';
    final email = config?.emailHoTro ?? 'support@foodroute.vn';

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E232E) : Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryTextOf(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.l10n.moreSupportCenter,
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: support.isLoadingConfig && config == null
          ? const SupportCenterSkeleton()
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  context.read<SupportProvider>().loadConfig(forceRefresh: true),
                  context.read<SupportProvider>().loadFaqs(forceRefresh: true),
                  context.read<SupportProvider>().loadMyTickets(forceRefresh: true),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Hero Banner (Fixed padding, no cut-off)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFC6011), Color(0xFFFF8533)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFC6011).withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.supportHeroTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.l10n.supportHeroDesc,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.94),
                                    fontSize: 12.5,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.headset_mic_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SECTION 1: Báo Cáo Sự Cố & Chat Trực Tuyến
                    StoreRegistrationSectionCard(
                      title: context.l10n.supportSecIncidentChat,
                      subtitle: context.l10n.supportSecIncidentChatSub,
                      icon: Icons.chat_bubble_outline_rounded,
                      children: [
                        // View tickets card
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SupportTicketListView()),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: TColor.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.forum_outlined, color: TColor.primary, size: 21),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Danh sách phiếu & Chat hỗ trợ',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          if (support.unreadTicketsCount > 0) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${support.unreadTicketsCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        support.myTickets.isEmpty
                                            ? 'Xem tiến độ xử lý và trao đổi realtime'
                                            : 'Bạn có ${support.myTickets.length} phiếu hỗ trợ',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : const Color(0xFF94A3B8), size: 22),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Create Ticket Button (Solid, neat, perfectly centered)
                        SizedBox(
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SupportTicketCreateView()),
                              );
                            },
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                            label: Text(
                              context.l10n.supportCreateTicket,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColor.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // SECTION 2: Liên Hệ Trực Tiếp (Hotline & Email aligned symmetrically)
                    StoreRegistrationSectionCard(
                      title: context.l10n.supportSecDirectContact,
                      subtitle: context.l10n.supportSecDirectContactSub,
                      icon: Icons.phone_in_talk_rounded,
                      children: [
                        // Hotline Card
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.phone_forwarded_rounded, color: Colors.green, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tổng đài Hotline',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      hotline,
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            gioLamViec,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () => _makePhoneCall(hotline),
                                  icon: const Icon(Icons.phone_rounded, size: 13),
                                  label: const Text(
                                    'Gọi ngay',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Email Support Card (Identical layout and button size)
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.mail_outline_rounded, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hộp thư hỗ trợ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Phản hồi trong 24 giờ làm việc',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton.icon(
                                  onPressed: () => _sendEmail(email),
                                  icon: const Icon(Icons.send_rounded, size: 13),
                                  label: const Text(
                                    'Gửi email',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // SECTION 3: Tự phục vụ & Góp ý
                    StoreRegistrationSectionCard(
                      title: context.l10n.supportSecFaqFeedback,
                      subtitle: context.l10n.supportSecFaqFeedbackSub,
                      icon: Icons.lightbulb_outline_rounded,
                      children: [
                        // FAQ Navigation Item
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SupportFaqView()),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: TColor.primary.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.help_outline_rounded, color: TColor.primary, size: 21),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Câu hỏi thường gặp (FAQ)',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Giải đáp về đặt món, giao hàng, thanh toán & đối tác',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : const Color(0xFF94A3B8), size: 22),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Feedback Navigation Item
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SupportFeedbackView()),
                            );
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF333E52) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.amber, size: 21),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Góp ý & Đánh giá chất lượng',
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Chia sẻ trải nghiệm giúp Food Route phục vụ bạn tốt hơn',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white54 : const Color(0xFF94A3B8), size: 22),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
