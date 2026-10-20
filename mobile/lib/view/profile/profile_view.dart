import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import '../../common_widget/custom_modal_alert.dart';
import '../../providers/language_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/notification_bell.dart';
import '../../services/upload_service.dart';
import '../more/my_order_view.dart';
import 'avatar_crop_dialog.dart';
import 'change_password_sheet.dart';
import 'profile_field_item.dart';
import 'profile_settings_sheet.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final ImagePicker picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _croppedBytes;
  String _avatarUrl = '';

  TextEditingController txtName = TextEditingController();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtMobile = TextEditingController();
  TextEditingController txtAddress = TextEditingController();

  String userName = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchUserProfileFromApi();
  }

  @override
  void dispose() {
    txtName.dispose();
    txtEmail.dispose();
    txtMobile.dispose();
    txtAddress.dispose();
    super.dispose();
  }

  void _loadUserProfile() {
    var rawPayload = ServiceCall.userPayload.isEmpty
        ? Globs.udValue(Globs.userPayload)
        : ServiceCall.userPayload;
    var payload = rawPayload is Map ? rawPayload : {};

    if (payload.isNotEmpty) {
      ServiceCall.userPayload = payload;
      Globs.udBoolSet(true, Globs.userLogin);
    }

    var userObj = payload["user"] is Map ? payload["user"] : payload;
    var khachHangObj = payload["khachHang"] is Map ? payload["khachHang"] : payload;

    String name = payload["fullName"]?.toString() ??
        payload["name"]?.toString() ??
        khachHangObj["hoTen"]?.toString() ??
        userObj["fullName"]?.toString() ??
        userObj["tenDangNhap"]?.toString() ??
        "";

    String email = payload["email"]?.toString() ??
        khachHangObj["email"]?.toString() ??
        userObj["email"]?.toString() ??
        userObj["tenDangNhap"]?.toString() ??
        "";

    String phone = payload["phone"]?.toString() ??
        payload["mobile"]?.toString() ??
        khachHangObj["sdt"]?.toString() ??
        userObj["phone"]?.toString() ??
        "";

    String address = payload["address"]?.toString() ??
        payload["diaChi"]?.toString() ??
        khachHangObj["diaChi"]?.toString() ??
        userObj["address"]?.toString() ??
        "";

    String avatarVal = payload["avatar"]?.toString() ??
        khachHangObj["avatar"]?.toString() ??
        '';

    txtName.text = name;
    txtEmail.text = email;
    txtMobile.text = phone;
    txtAddress.text = address;
    userName = name;
    _avatarUrl = avatarVal;
  }

  void _fetchUserProfileFromApi() {
    var rawPayload = ServiceCall.userPayload.isEmpty
        ? Globs.udValue(Globs.userPayload)
        : ServiceCall.userPayload;
    var payload = rawPayload is Map ? rawPayload : {};
    int userId = (payload["id"] ?? payload["maTaiKhoan"] ?? 0) as int;

    ServiceCall.post({
      "userId": userId,
      "email": payload["email"] ?? txtEmail.text.trim(),
    }, SVKey.svGetProfile, withSuccess: (responseObj) async {
      if (responseObj[KKey.status] == "1") {
        var serverPayload = responseObj[KKey.payload];
        if (serverPayload is Map && serverPayload.isNotEmpty) {
          var updatedPayload = Map<String, dynamic>.from(payload);
          updatedPayload.addAll(Map<String, dynamic>.from(serverPayload));

          ServiceCall.userPayload = updatedPayload;
          Globs.udSet(updatedPayload, Globs.userPayload);
          Globs.udBoolSet(true, Globs.userLogin);

          if (mounted) {
            setState(() {
              _loadUserProfile();
            });
          }
        }
      }
    }, failure: (err) async {
      debugPrint("Fetch profile from API error: $err");
    });
  }

  // ── Avatar Picker with crop ──
  Future<void> _onPickAvatar() async {
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    final Uint8List? cropped = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AvatarCropDialog(imageBytes: bytes),
    );
    if (cropped != null && mounted) {
      setState(() {
        _pickedImage = picked;
        _croppedBytes = cropped;
      });

      // Tự động tải ảnh lên server và cập nhật hồ sơ ngay lập tức
      final lang = Provider.of<LanguageProvider>(context, listen: false);
      Globs.showHUD();
      try {
        final base64Str = 'data:image/jpeg;base64,${base64Encode(cropped)}';
        final uploaded = await UploadService.uploadImageBase64(base64Str);
        if (uploaded != null && uploaded.isNotEmpty) {
          _avatarUrl = uploaded;
          _croppedBytes = null; // Chuyển sang dùng URL đã upload

          var rawPayload = ServiceCall.userPayload.isEmpty
              ? Globs.udValue(Globs.userPayload)
              : ServiceCall.userPayload;
          var payload = Map<String, dynamic>.from(rawPayload is Map ? rawPayload : {});
          payload['avatar'] = uploaded;
          if (payload['user'] is Map) {
            (payload['user'] as Map)['avatar'] = uploaded;
          }
          if (payload['khachHang'] is Map) {
            (payload['khachHang'] as Map)['avatar'] = uploaded;
          }
          ServiceCall.userPayload = payload;
          Globs.udSet(payload, Globs.userPayload);

          final apiBody = <String, dynamic>{
            'userId': payload['id'] ?? payload['maTaiKhoan'] ?? 0,
            'avatar': uploaded,
          };
          ServiceCall.post(apiBody, SVKey.svUpdateProfile,
              withSuccess: (responseObj) async {
            Globs.hideHUD();
            if (!mounted) return;
            if (responseObj[KKey.status] == '1' || responseObj['statusCode'] == 200) {
              setState(() {});
              CustomModalAlert.show(
                context: context,
                title: lang.languageCode == 'vi' ? 'Thành công' : 'Success',
                message: lang.languageCode == 'vi'
                    ? 'Đã cập nhật ảnh đại diện thành công!'
                    : 'Avatar updated successfully!',
                buttonTitle: 'OK',
              );
            } else {
              CustomModalAlert.show(
                context: context,
                title: lang.languageCode == 'vi' ? 'Lỗi' : 'Error',
                message: responseObj[KKey.message]?.toString() ??
                    responseObj['message']?.toString() ??
                    (lang.languageCode == 'vi' ? 'Không thể cập nhật ảnh!' : 'Failed to update avatar!'),
                buttonTitle: 'OK',
              );
            }
          }, failure: (err) async {
            Globs.hideHUD();
            debugPrint("Update avatar API error: $err");
            if (mounted) {
              CustomModalAlert.show(
                context: context,
                title: lang.languageCode == 'vi' ? 'Lỗi' : 'Error',
                message: err.toString(),
                buttonTitle: 'OK',
              );
            }
          });
        } else {
          Globs.hideHUD();
          if (mounted) {
            CustomModalAlert.show(
              context: context,
              title: lang.languageCode == 'vi' ? 'Lỗi' : 'Error',
              message: lang.languageCode == 'vi'
                  ? 'Không thể tải ảnh đại diện lên máy chủ!'
                  : 'Failed to upload avatar to server!',
              buttonTitle: 'OK',
            );
          }
        }
      } catch (e) {
        Globs.hideHUD();
        debugPrint("Auto upload avatar error: $e");
      }
    }
  }

  void _saveProfile(LanguageProvider lang) async {
    String name = txtName.text.trim();
    String email = txtEmail.text.trim();
    String phone = txtMobile.text.trim();
    String address = txtAddress.text.trim();

    if (name.isEmpty) {
      CustomModalAlert.show(
        context: context,
        title: lang.languageCode == 'vi' ? 'Thông báo' : 'Notice',
        message: lang.languageCode == 'vi' ? 'Vui lòng nhập họ và tên!' : 'Please enter full name!',
        buttonTitle: 'OK',
      );
      return;
    }

    Globs.showHUD();

    String? finalAvatarUrl = _avatarUrl.isNotEmpty ? _avatarUrl : null;
    if (_croppedBytes != null) {
      final base64Str = 'data:image/jpeg;base64,${base64Encode(_croppedBytes!)}';
      final uploaded = await UploadService.uploadImageBase64(base64Str);
      if (uploaded != null && uploaded.isNotEmpty) {
        finalAvatarUrl = uploaded;
        _avatarUrl = uploaded;
        _croppedBytes = null;
      } else {
        Globs.hideHUD();
        if (mounted) {
          CustomModalAlert.show(
            context: context,
            title: lang.languageCode == 'vi' ? 'Lỗi' : 'Error',
            message: lang.languageCode == 'vi'
                ? 'Không thể tải ảnh đại diện lên máy chủ!'
                : 'Failed to upload avatar to server!',
            buttonTitle: 'OK',
          );
        }
        return;
      }
    }

    var rawPayload = ServiceCall.userPayload.isEmpty
        ? Globs.udValue(Globs.userPayload)
        : ServiceCall.userPayload;
    var payload = Map<String, dynamic>.from(rawPayload is Map ? rawPayload : {});

    payload['fullName'] = name;
    payload['name'] = name;
    payload['email'] = email;
    payload['phone'] = phone;
    payload['mobile'] = phone;
    payload['address'] = address;
    payload['diaChi'] = address;
    if (finalAvatarUrl != null) payload['avatar'] = finalAvatarUrl;

    if (payload['user'] is Map) {
      var userMap = Map<String, dynamic>.from(payload['user'] as Map);
      userMap['fullName'] = name;
      userMap['name'] = name;
      userMap['email'] = email;
      userMap['phone'] = phone;
      userMap['address'] = address;
      payload['user'] = userMap;
    }

    if (payload['khachHang'] is Map) {
      var khMap = Map<String, dynamic>.from(payload['khachHang'] as Map);
      khMap['hoTen'] = name;
      khMap['email'] = email;
      khMap['sdt'] = phone;
      khMap['diaChi'] = address;
      if (finalAvatarUrl != null) khMap['avatar'] = finalAvatarUrl;
      payload['khachHang'] = khMap;
    } else {
      payload['khachHang'] = {
        'hoTen': name,
        'email': email,
        'sdt': phone,
        'diaChi': address,
        if (finalAvatarUrl != null) 'avatar': finalAvatarUrl,
      };
    }

    ServiceCall.userPayload = payload;
    Globs.udSet(payload, Globs.userPayload);
    Globs.udBoolSet(true, Globs.userLogin);

    setState(() {
      userName = name;
      _isEditing = false;
    });

    final apiBody = <String, dynamic>{
      'userId': payload['id'] ?? payload['maTaiKhoan'] ?? 0,
      'fullName': name,
      'name': name,
      'email': email,
      'phone': phone,
      'sdt': phone,
      'address': address,
      'diaChi': address,
    };
    if (finalAvatarUrl != null) apiBody['avatar'] = finalAvatarUrl;

    ServiceCall.post(apiBody, SVKey.svUpdateProfile,
        withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (!mounted) return;
      if (responseObj[KKey.status] == '1' || responseObj['statusCode'] == 200) {
        var serverPayload = responseObj[KKey.payload];
        if (serverPayload is Map && serverPayload.isNotEmpty) {
          payload.addAll(Map<String, dynamic>.from(serverPayload));
          if (payload['avatar'] != null) {
            setState(() => _avatarUrl = payload['avatar'].toString());
          }
          ServiceCall.userPayload = payload;
          Globs.udSet(payload, Globs.userPayload);
          Globs.udBoolSet(true, Globs.userLogin);
        }
        CustomModalAlert.show(
          context: context,
          title: lang.languageCode == 'vi' ? 'Thành công!' : 'Success!',
          message: lang.languageCode == 'vi'
              ? 'Đã lưu thông tin tài khoản thành công!'
              : 'Profile saved successfully!',
          buttonTitle: lang.languageCode == 'vi' ? 'Hoàn tất' : 'Done',
        );
      } else {
        CustomModalAlert.show(
          context: context,
          title: lang.languageCode == 'vi' ? 'Lỗi cập nhật' : 'Update Error',
          message: responseObj[KKey.message]?.toString() ??
              responseObj['message']?.toString() ??
              'Không thể cập nhật hồ sơ!',
          buttonTitle: 'OK',
        );
      }
    }, failure: (err) async {
      Globs.hideHUD();
      debugPrint('UpdateProfile error: $err');
      if (!mounted) return;
      CustomModalAlert.show(
        context: context,
        title: lang.languageCode == 'vi' ? 'Lỗi kết nối' : 'Connection Error',
        message: err.toString(),
        buttonTitle: 'OK',
      );
    });
  }

  void _openSettingsSheet(BuildContext context, LanguageProvider lang) {
    var rawPayload = ServiceCall.userPayload.isEmpty
        ? Globs.udValue(Globs.userPayload)
        : ServiceCall.userPayload;
    var payload = rawPayload is Map ? rawPayload : {};
    bool isGoogleUser = payload["isGoogle"] == true ||
        payload["loginType"] == "google" ||
        payload["googleId"] != null;

    showProfileSettingsSheet(
      context: context,
      lang: lang,
      isGoogleUser: isGoogleUser,
      onChangePassword: () => showChangePasswordModal(context, lang, txtEmail.text.trim()),
      onOpenOrders: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyOrderView()),
        );
      },
    );
  }

  Widget _buildAvatar(bool isDark) {
    Widget avatarChild;
    if (_croppedBytes != null) {
      avatarChild = Image.memory(_croppedBytes!, width: 98, height: 98, fit: BoxFit.cover);
    } else if (_pickedImage != null) {
      avatarChild = Image.file(File(_pickedImage!.path), width: 98, height: 98, fit: BoxFit.cover);
    } else if (_avatarUrl.isNotEmpty) {
      final formattedAvatar = SVKey.formatImageUrl(_avatarUrl);
      if (formattedAvatar.startsWith('data:image')) {
        try {
          final bytes = base64Decode(formattedAvatar.split(',').last);
          avatarChild = Image.memory(bytes, width: 98, height: 98, fit: BoxFit.cover);
        } catch (_) {
          avatarChild = _defaultAvatarIcon(isDark);
        }
      } else {
        avatarChild = Image.network(
          formattedAvatar,
          width: 98,
          height: 98,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatarIcon(isDark),
        );
      }
    } else {
      avatarChild = _defaultAvatarIcon(isDark);
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: TColor.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: avatarChild,
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: GestureDetector(
            onTap: _onPickAvatar,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: TColor.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0xFF171B26) : Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatarIcon(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF232836) : const Color(0xFFEAEBED),
      alignment: Alignment.center,
      child: Icon(
        Icons.person_rounded,
        size: 62,
        color: isDark ? const Color(0xFF6C727F) : const Color(0xFFA0A5B1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: TColor.bgOf(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 46),

              // Top Bar (Title, Bell, Cart, Settings)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      lang.languageCode == 'vi' ? "Chỉnh sửa hồ sơ" : "Edit Profile",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: TColor.primaryTextOf(context),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NotificationBell(
                        backgroundColor: TColor.cardOf(context),
                        iconColor: TColor.primaryTextOf(context),
                        border: Border.all(color: TColor.borderOf(context), width: 1),
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: TColor.cardOf(context),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: TColor.borderOf(context), width: 1),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const MyOrderView()),
                                );
                              },
                              icon: Icon(
                                Icons.shopping_cart_outlined,
                                color: TColor.primaryTextOf(context),
                                size: 20,
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final cartCount = context.watch<CartProvider>().totalItemCount;
                              if (cartCount == 0) return const SizedBox.shrink();
                              return Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: TColor.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$cartCount",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: TColor.cardOf(context),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: TColor.borderOf(context), width: 1),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _openSettingsSheet(context, lang),
                          icon: Icon(
                            Icons.settings_outlined,
                            color: TColor.primaryTextOf(context),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Avatar with camera badge
              _buildAvatar(isDark),

              const SizedBox(height: 14),

              // User Name Title
              Text(
                userName.isNotEmpty ? userName : (lang.languageCode == 'vi' ? "Người dùng" : "Customer"),
                style: TextStyle(
                  color: TColor.primaryTextOf(context),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              // Gold Member Tag & Logout Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFB300), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFFFF8F00), size: 14),
                        SizedBox(width: 4),
                        Text(
                          "Gold Member",
                          style: TextStyle(
                            color: Color(0xFFE65100),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TColor.secondaryTextOf(context),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      ServiceCall.showLogoutDialog(context);
                    },
                    child: const Text(
                      "Logout",
                      style: TextStyle(
                        color: Color(0xFFFF5252),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Form Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TColor.cardOf(context),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: TColor.borderOf(context), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.languageCode == 'vi' ? 'Thông tin cá nhân' : 'Personal Information',
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isEditing = !_isEditing),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isEditing ? TColor.primary : TColor.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                                  color: _isEditing ? Colors.white : TColor.primary,
                                  size: 15,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isEditing
                                      ? (lang.languageCode == 'vi' ? 'Xong' : 'Done')
                                      : (lang.languageCode == 'vi' ? 'Chỉnh sửa' : 'Edit'),
                                  style: TextStyle(
                                    color: _isEditing ? Colors.white : TColor.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProfileFieldItem(
                      label: lang.languageCode == 'vi' ? "Họ và tên" : "Full Name",
                      controller: txtName,
                      icon: Icons.person_outline_rounded,
                      hintText: lang.languageCode == 'vi' ? "Nhập họ và tên" : "Enter full name",
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 14),

                    ProfileFieldItem(
                      label: lang.languageCode == 'vi' ? "Địa chỉ Email" : "Email Address",
                      controller: txtEmail,
                      icon: Icons.mail_outline_rounded,
                      hintText: lang.languageCode == 'vi' ? "Nhập địa chỉ email" : "Enter email address",
                      keyboardType: TextInputType.emailAddress,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 14),

                    ProfileFieldItem(
                      label: lang.languageCode == 'vi' ? "Số điện thoại" : "Phone Number",
                      controller: txtMobile,
                      icon: Icons.phone_outlined,
                      hintText: lang.languageCode == 'vi' ? "Nhập số điện thoại" : "Enter phone number",
                      keyboardType: TextInputType.phone,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 14),

                    ProfileFieldItem(
                      label: lang.languageCode == 'vi' ? "Địa chỉ giao hàng" : "Delivery Address",
                      controller: txtAddress,
                      icon: Icons.location_on_outlined,
                      hintText: lang.languageCode == 'vi' ? "Nhập địa chỉ giao hàng" : "Enter delivery address",
                      enabled: _isEditing,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Full-width Solid Orange Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () => _saveProfile(lang),
                  child: Text(
                    lang.tr('save'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
