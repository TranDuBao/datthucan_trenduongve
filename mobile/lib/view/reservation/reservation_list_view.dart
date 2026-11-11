import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../models/reservation_model.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/skeleton/reservation_item_skeleton.dart';
import 'reservation_card.dart';
import 'reservation_detail_view.dart';
import 'widgets/cancel_reservation_sheet.dart';

class ReservationListView extends StatefulWidget {
  const ReservationListView({super.key});

  @override
  State<ReservationListView> createState() => _ReservationListViewState();
}

class _ReservationListViewState extends State<ReservationListView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservationProvider>().fetchMyReservations(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showCancelDialog(ReservationModel resv) async {
    final success = await CancelReservationSheet.show(
      context: context,
      reservation: resv,
    );
    if (success == true && mounted) {
      context.read<ReservationProvider>().fetchMyReservations(refresh: true);
    }
  }

  Widget _buildEmptyState({required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: TColor.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.table_restaurant_outlined, size: 40, color: TColor.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: TColor.primaryTextOf(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: TColor.secondaryTextOf(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationList(List<ReservationModel> list, {required String emptyTitle, required String emptySubtitle}) {
    if (list.isEmpty) {
      return _buildEmptyState(title: emptyTitle, subtitle: emptySubtitle);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final resv = list[index];
        return ReservationCard(
          reservation: resv,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReservationDetailView(reservationId: resv.maDatBan),
              ),
            );
          },
          onCancel: resv.canCancel ? () => _showCancelDialog(resv) : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReservationProvider>();
    final upcomingList = provider.upcomingReservations;
    final historyList = provider.historyReservations;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        backgroundColor: TColor.cardOf(context),
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryTextOf(context), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bàn đã đặt',
          style: TextStyle(
            color: TColor.primaryTextOf(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TColor.primary,
          labelColor: TColor.primary,
          unselectedLabelColor: TColor.secondaryTextOf(context),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sắp tới'),
                  if (upcomingList.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: TColor.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${upcomingList.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Lịch sử'),
          ],
        ),
      ),
      body: provider.isLoading && provider.reservations.isEmpty
          ? const ReservationSkeletonList()
          : RefreshIndicator(
              onRefresh: () => provider.fetchMyReservations(refresh: true),
              color: TColor.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReservationList(
                    upcomingList,
                    emptyTitle: 'Chưa có lượt đặt bàn sắp tới',
                    emptySubtitle: 'Khi bạn đặt bàn tại các nhà hàng, thông tin lịch hẹn sẽ hiển thị tại đây.',
                  ),
                  _buildReservationList(
                    historyList,
                    emptyTitle: 'Chưa có lịch sử đặt bàn',
                    emptySubtitle: 'Các lượt đặt bàn đã hoàn tất hoặc đã hủy sẽ được lưu trữ tại đây.',
                  ),
                ],
              ),
            ),
    );
  }
}
