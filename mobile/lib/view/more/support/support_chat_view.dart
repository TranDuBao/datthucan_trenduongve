import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../common/color_extension.dart';
import '../../../common/globs.dart';
import '../../../common/locator.dart';
import '../../../model/support_model.dart';
import '../../../providers/support_provider.dart';
import '../../../services/socket_service.dart';
import '../../../services/support_service.dart';
import '../../../services/upload_service.dart';

class SupportChatView extends StatefulWidget {
  final SupportTicketModel ticket;

  const SupportChatView({super.key, required this.ticket});

  @override
  State<SupportChatView> createState() => _SupportChatViewState();
}

class _SupportChatViewState extends State<SupportChatView> {
  late SupportTicketModel _ticket;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<SupportTicketMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploadingImage = false;
  final List<String> _pendingImages = [];

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _joinTicketRoom();
    _loadMessages();

    // Mark as read in provider and backend
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().markTicketAsReadLocally(_ticket.maPhieu);
    });
  }

  void _joinTicketRoom() {
    try {
      final socket = locator<SocketService>();
      socket.emit('room:join', {'roomType': 'ticket', 'id': _ticket.maPhieu});
      socket.subscribe('ticket:message_new', _onNewMessage);
      socket.subscribe('ticket:message_read', _onMessageRead);
      socket.subscribe('ticket:status_changed', _onStatusChanged);
    } catch (e) {
      debugPrint('[SupportChatView] join room error: $e');
    }
  }

  void _leaveTicketRoom() {
    try {
      final socket = locator<SocketService>();
      socket.emit('room:leave', {'roomType': 'ticket', 'id': _ticket.maPhieu});
      socket.unsubscribe('ticket:message_new', _onNewMessage);
      socket.unsubscribe('ticket:message_read', _onMessageRead);
      socket.unsubscribe('ticket:status_changed', _onStatusChanged);
    } catch (_) {}
  }

  void _onNewMessage(dynamic data) {
    if (data is Map && data['maPhieu'] == _ticket.maPhieu) {
      final newMsg = SupportTicketMessageModel.fromJson(Map<String, dynamic>.from(data));
      if (mounted) {
        setState(() {
          if (!_messages.any((m) => m.maTinNhan == newMsg.maTinNhan)) {
            _messages.add(newMsg);
          }
        });
        _scrollToBottom();
        // Mark as read if sent by admin
        if (newMsg.vaiTroGui == 'ADMIN') {
          context.read<SupportProvider>().markTicketAsReadLocally(_ticket.maPhieu);
        }
      }
    }
  }

  void _onMessageRead(dynamic data) {
    if (data is Map && data['maPhieu'] == _ticket.maPhieu && data['readerRole'] == 'ADMIN') {
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) {
            if (m.vaiTroGui == 'USER') {
              return SupportTicketMessageModel(
                maTinNhan: m.maTinNhan,
                maPhieu: m.maPhieu,
                maTaiKhoanGui: m.maTaiKhoanGui,
                vaiTroGui: m.vaiTroGui,
                noiDung: m.noiDung,
                danhSachAnh: m.danhSachAnh,
                daXem: true,
                thoiGianXem: DateTime.now(),
                ngayTao: m.ngayTao,
              );
            }
            return m;
          }).toList();
        });
      }
    }
  }

  void _onStatusChanged(dynamic data) {
    if (data is Map && data['maPhieu'] == _ticket.maPhieu) {
      final newStatus = data['trangThai']?.toString();
      if (newStatus != null && mounted) {
        setState(() {
          _ticket = SupportTicketModel(
            maPhieu: _ticket.maPhieu,
            maTaiKhoan: _ticket.maTaiKhoan,
            tieuDe: _ticket.tieuDe,
            loaiSuCo: _ticket.loaiSuCo,
            moTa: _ticket.moTa,
            maDonHang: _ticket.maDonHang,
            danhSachAnh: _ticket.danhSachAnh,
            trangThai: newStatus,
            soTinChuaDocUser: _ticket.soTinChuaDocUser,
            soTinChuaDocAdmin: _ticket.soTinChuaDocAdmin,
            tinNhanCuoi: _ticket.tinNhanCuoi,
            thoiGianTinCuoi: _ticket.thoiGianTinCuoi,
            ngayTao: _ticket.ngayTao,
            ngayCapNhat: DateTime.now(),
          );
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    final list = await SupportService.getTicketMessages(_ticket.maPhieu);
    if (mounted) {
      setState(() {
        _messages = list;
        _isLoading = false;
      });
      _scrollToBottom(smooth: false);
    }
  }

  void _scrollToBottom({bool smooth = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        if (smooth) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      }
    });
  }

  Future<void> _pickImage() async {
    if (_pendingImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 3 ảnh cho mỗi tin nhắn')),
      );
      return;
    }

    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (file == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final bytes = await file.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      final uploadedUrl = await UploadService.uploadImageBase64(base64Str);

      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        setState(() {
          _pendingImages.add(uploadedUrl);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && _pendingImages.isEmpty) return;

    final imagesToSend = List<String>.from(_pendingImages);
    _msgCtrl.clear();
    setState(() {
      _pendingImages.clear();
      _isSending = true;
    });

    final res = await SupportService.sendTicketMessage(
      _ticket.maPhieu,
      noiDung: text,
      danhSachAnh: imagesToSend,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        if (res != null && !_messages.any((m) => m.maTinNhan == res.maTinNhan)) {
          _messages.add(res);
        }
      });
      _scrollToBottom();
    }
  }

  void _showImageDialog(String imgUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  SVKey.formatImageUrl(imgUrl),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'MOI':
        return Colors.blue.withValues(alpha: 0.15);
      case 'DANG_XU_LY':
        return Colors.orange.withValues(alpha: 0.15);
      case 'DA_GIAI_QUYET':
        return Colors.green.withValues(alpha: 0.15);
      case 'DA_DONG':
        return Colors.grey.withValues(alpha: 0.2);
      default:
        return Colors.blue.withValues(alpha: 0.15);
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

  String _getStatusText(String status) {
    switch (status) {
      case 'MOI':
        return 'Mới';
      case 'DANG_XU_LY':
        return 'Đang xử lý';
      case 'DA_GIAI_QUYET':
        return 'Đã giải quyết';
      case 'DA_DONG':
        return 'Đã đóng';
      default:
        return status;
    }
  }

  @override
  void dispose() {
    _leaveTicketRoom();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isClosed = _ticket.trangThai == 'DA_DONG';

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E232E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: TColor.primaryTextOf(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hỗ trợ #${_ticket.maPhieu}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: TColor.primaryTextOf(context),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusBg(_ticket.trangThai),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getStatusText(_ticket.trangThai),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(_ticket.trangThai),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _ticket.loaiSuCo,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Notice if closed
          if (isClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Phiếu hỗ trợ này đã được đóng.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),

          // Messages Stream
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isUser = m.vaiTroGui == 'USER';

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          child: Column(
                            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              // Sender label & time
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3, left: 2, right: 2),
                                child: Text(
                                  isUser
                                      ? 'Bạn • ${m.ngayTao.hour.toString().padLeft(2, '0')}:${m.ngayTao.minute.toString().padLeft(2, '0')}'
                                      : 'Admin Food Route • ${m.ngayTao.hour.toString().padLeft(2, '0')}:${m.ngayTao.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                ),
                              ),

                              // Bubble
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? TColor.primary
                                      : (isDark ? const Color(0xFF262C3A) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                                    bottomRight: Radius.circular(isUser ? 4 : 16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.noiDung,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.35,
                                        color: isUser
                                            ? Colors.white
                                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                      ),
                                    ),

                                    // Image attachments
                                    if (m.danhSachAnh.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: m.danhSachAnh.map((img) {
                                          return InkWell(
                                            onTap: () => _showImageDialog(img),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                SVKey.formatImageUrl(img),
                                                width: 70,
                                                height: 70,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Read Receipt
                              if (isUser)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2, right: 2),
                                  child: Text(
                                    m.daXem ? 'Đã xem' : 'Đã gửi',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: m.daXem ? Colors.blue : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Pending attachments preview
          if (_pendingImages.isNotEmpty)
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF1E232E) : Colors.white,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pendingImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          SVKey.formatImageUrl(_pendingImages[idx]),
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _pendingImages.removeAt(idx);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E232E) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isUploadingImage || isClosed ? null : _pickImage,
                  icon: _isUploadingImage
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.photo_camera_outlined, color: TColor.primary, size: 24),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262C3A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      enabled: !isClosed,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(fontSize: 14, color: TColor.primaryTextOf(context)),
                      decoration: InputDecoration(
                        hintText: isClosed ? 'Phiếu hỗ trợ đã đóng' : 'Nhập tin nhắn hỗ trợ...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending || isClosed ? null : _send,
                  icon: _isSending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.send_rounded, color: TColor.primary, size: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

