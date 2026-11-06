import 'package:flutter/foundation.dart';
import '../common/locator.dart';
import '../model/support_model.dart';
import '../services/socket_service.dart';
import '../services/support_service.dart';

class SupportProvider extends ChangeNotifier {
  SupportConfigModel? _config;
  List<FaqGroupModel> _faqGroups = [];
  List<SupportTicketModel> _myTickets = [];
  bool _isLoadingConfig = false;
  bool _isLoadingFaq = false;
  bool _isLoadingTickets = false;
  String _faqSearchQuery = '';

  SupportConfigModel? get config => _config;
  List<FaqGroupModel> get faqGroups => _faqGroups;
  List<SupportTicketModel> get myTickets => _myTickets;
  bool get isLoadingConfig => _isLoadingConfig;
  bool get isLoadingFaq => _isLoadingFaq;
  bool get isLoadingTickets => _isLoadingTickets;
  String get faqSearchQuery => _faqSearchQuery;

  int get unreadTicketsCount =>
      _myTickets.fold(0, (sum, t) => sum + t.soTinChuaDocUser);

  SupportProvider() {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    try {
      final socketService = locator<SocketService>();
      socketService.subscribe('support:config_updated', _onConfigUpdatedRealtime);
      socketService.subscribe('support:faq_updated', _onFaqUpdatedRealtime);
      socketService.subscribe('ticket:created', _onTicketCreatedRealtime);
      socketService.subscribe('ticket:status_changed', _onTicketStatusChangedRealtime);
      socketService.subscribe('ticket:message_new', _onTicketMessageNewRealtime);
    } catch (e) {
      debugPrint('[SupportProvider] socket subscription error: $e');
    }
  }

  void _onConfigUpdatedRealtime(dynamic data) {
    debugPrint('[SupportProvider] [Realtime] config_updated received: $data');
    if (data is Map<String, dynamic>) {
      _config = SupportConfigModel.fromJson(data);
      notifyListeners();
    } else {
      loadConfig();
    }
  }

  void _onFaqUpdatedRealtime(dynamic data) {
    debugPrint('[SupportProvider] [Realtime] faq_updated received: $data');
    loadFaqs(forceRefresh: true);
  }

  void _onTicketCreatedRealtime(dynamic data) {
    debugPrint('[SupportProvider] [Realtime] ticket:created: $data');
    loadMyTickets(forceRefresh: true);
  }

  void _onTicketStatusChangedRealtime(dynamic data) {
    debugPrint('[SupportProvider] [Realtime] ticket:status_changed: $data');
    if (data is Map) {
      final ticketId = int.tryParse(data['maPhieu']?.toString() ?? '0');
      final newStatus = data['trangThai']?.toString();
      if (ticketId != null && newStatus != null) {
        final idx = _myTickets.indexWhere((t) => t.maPhieu == ticketId);
        if (idx != -1) {
          final old = _myTickets[idx];
          _myTickets[idx] = SupportTicketModel(
            maPhieu: old.maPhieu,
            maTaiKhoan: old.maTaiKhoan,
            tieuDe: old.tieuDe,
            loaiSuCo: old.loaiSuCo,
            moTa: old.moTa,
            maDonHang: old.maDonHang,
            danhSachAnh: old.danhSachAnh,
            trangThai: newStatus,
            soTinChuaDocUser: old.soTinChuaDocUser,
            soTinChuaDocAdmin: old.soTinChuaDocAdmin,
            tinNhanCuoi: old.tinNhanCuoi,
            thoiGianTinCuoi: old.thoiGianTinCuoi,
            ngayTao: old.ngayTao,
            ngayCapNhat: DateTime.now(),
          );
          notifyListeners();
          return;
        }
      }
    }
    loadMyTickets(forceRefresh: true);
  }

  void _onTicketMessageNewRealtime(dynamic data) {
    debugPrint('[SupportProvider] [Realtime] ticket:message_new: $data');
    if (data is Map) {
      final ticketId = int.tryParse(data['maPhieu']?.toString() ?? '0');
      final noiDung = data['noiDung']?.toString();
      final senderRole = data['vaiTroGui']?.toString();
      final ticketStatus = data['ticketStatus']?.toString();

      if (ticketId != null && ticketId > 0) {
        final idx = _myTickets.indexWhere((t) => t.maPhieu == ticketId);
        if (idx != -1) {
          final old = _myTickets[idx];
          final updated = SupportTicketModel(
            maPhieu: old.maPhieu,
            maTaiKhoan: old.maTaiKhoan,
            tieuDe: old.tieuDe,
            loaiSuCo: old.loaiSuCo,
            moTa: old.moTa,
            maDonHang: old.maDonHang,
            danhSachAnh: old.danhSachAnh,
            trangThai: ticketStatus ?? old.trangThai,
            soTinChuaDocUser: senderRole == 'ADMIN' ? old.soTinChuaDocUser + 1 : old.soTinChuaDocUser,
            soTinChuaDocAdmin: old.soTinChuaDocAdmin,
            tinNhanCuoi: noiDung ?? old.tinNhanCuoi,
            thoiGianTinCuoi: DateTime.now(),
            ngayTao: old.ngayTao,
            ngayCapNhat: DateTime.now(),
          );
          _myTickets.removeAt(idx);
          _myTickets.insert(0, updated);
          notifyListeners();
          return;
        }
      }
    }
    loadMyTickets(forceRefresh: true);
  }

  Future<void> loadConfig({bool forceRefresh = false}) async {
    if (_config != null && !forceRefresh) return;
    _isLoadingConfig = true;
    notifyListeners();

    try {
      final res = await SupportService.getPublicConfig();
      if (res != null) {
        _config = res;
      }
    } catch (e) {
      debugPrint('[SupportProvider] loadConfig error: $e');
    } finally {
      _isLoadingConfig = false;
      notifyListeners();
    }
  }

  Future<void> loadFaqs({bool forceRefresh = false}) async {
    if (_faqGroups.isNotEmpty && !forceRefresh) return;
    _isLoadingFaq = true;
    notifyListeners();

    try {
      final list = await SupportService.getPublicFaqs();
      _faqGroups = list;
    } catch (e) {
      debugPrint('[SupportProvider] loadFaqs error: $e');
    } finally {
      _isLoadingFaq = false;
      notifyListeners();
    }
  }

  Future<void> loadMyTickets({bool forceRefresh = false}) async {
    if (_myTickets.isNotEmpty && !forceRefresh) return;
    _isLoadingTickets = true;
    notifyListeners();

    try {
      final list = await SupportService.getMyTickets();
      _myTickets = list;
    } catch (e) {
      debugPrint('[SupportProvider] loadMyTickets error: $e');
    } finally {
      _isLoadingTickets = false;
      notifyListeners();
    }
  }

  void markTicketAsReadLocally(int ticketId) {
    final idx = _myTickets.indexWhere((t) => t.maPhieu == ticketId);
    if (idx != -1) {
      final old = _myTickets[idx];
      _myTickets[idx] = SupportTicketModel(
        maPhieu: old.maPhieu,
        maTaiKhoan: old.maTaiKhoan,
        tieuDe: old.tieuDe,
        loaiSuCo: old.loaiSuCo,
        moTa: old.moTa,
        maDonHang: old.maDonHang,
        danhSachAnh: old.danhSachAnh,
        trangThai: old.trangThai,
        soTinChuaDocUser: 0,
        soTinChuaDocAdmin: old.soTinChuaDocAdmin,
        tinNhanCuoi: old.tinNhanCuoi,
        thoiGianTinCuoi: old.thoiGianTinCuoi,
        ngayTao: old.ngayTao,
        ngayCapNhat: old.ngayCapNhat,
      );
      notifyListeners();
    }
    SupportService.markTicketMessagesAsRead(ticketId);
  }

  void setFaqSearchQuery(String query) {
    _faqSearchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  List<FaqQuestionModel> getFilteredQuestions({int? selectedGroupId}) {
    List<FaqQuestionModel> result = [];

    for (final group in _faqGroups) {
      if (selectedGroupId != null && group.maNhom != selectedGroupId) {
        continue;
      }

      for (final q in group.cauHoi) {
        if (_faqSearchQuery.isEmpty) {
          result.add(q);
        } else {
          final matchQuestion = q.cauHoi.toLowerCase().contains(_faqSearchQuery);
          final matchAnswer = q.cauTraLoi.toLowerCase().contains(_faqSearchQuery);
          if (matchQuestion || matchAnswer) {
            result.add(q);
          }
        }
      }
    }

    return result;
  }

  @override
  void dispose() {
    try {
      final socketService = locator<SocketService>();
      socketService.unsubscribe('support:config_updated', _onConfigUpdatedRealtime);
      socketService.unsubscribe('support:faq_updated', _onFaqUpdatedRealtime);
      socketService.unsubscribe('ticket:created', _onTicketCreatedRealtime);
      socketService.unsubscribe('ticket:status_changed', _onTicketStatusChangedRealtime);
      socketService.unsubscribe('ticket:message_new', _onTicketMessageNewRealtime);
    } catch (_) {}
    super.dispose();
  }
}
