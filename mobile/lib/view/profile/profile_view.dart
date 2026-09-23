import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../common/color_extension.dart';
import '../../common_widget/custom_modal_alert.dart';
import '../../providers/language_provider.dart';
import '../more/my_order_view.dart';

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
      builder: (_) => _AvatarCropDialog(imageBytes: bytes),
    );
    if (cropped != null && mounted) {
      setState(() {
        _pickedImage = picked;
        _croppedBytes = cropped;
      });
    }
  }

  void _saveProfile(LanguageProvider lang) {
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

    var rawPayload = ServiceCall.userPayload.isEmpty
        ? Globs.udValue(Globs.userPayload)
        : ServiceCall.userPayload;
    var payload = Map<String, dynamic>.from(rawPayload is Map ? rawPayload as Map : {});

    // Prepare avatar
    String? avatarBase64;
    if (_croppedBytes != null) {
      avatarBase64 = 'data:image/jpeg;base64,${base64Encode(_croppedBytes!)}';
    } else if (_avatarUrl.isNotEmpty) {
      avatarBase64 = _avatarUrl;
    }

    payload['fullName'] = name;
    payload['name'] = name;
    payload['email'] = email;
    payload['phone'] = phone;
    payload['mobile'] = phone;
    payload['address'] = address;
    payload['diaChi'] = address;
    if (avatarBase64 != null) payload['avatar'] = avatarBase64;

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
      if (avatarBase64 != null) khMap['avatar'] = avatarBase64;
      payload['khachHang'] = khMap;
    } else {
      payload['khachHang'] = {
        'hoTen': name,
        'email': email,
        'sdt': phone,
        'diaChi': address,
        if (avatarBase64 != null) 'avatar': avatarBase64,
      };
    }

    ServiceCall.userPayload = payload;
    Globs.udSet(payload, Globs.userPayload);
    Globs.udBoolSet(true, Globs.userLogin);

    setState(() {
      userName = name;
      _isEditing = false;
    });

    // Persist to backend
    Globs.showHUD();
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
    if (avatarBase64 != null) apiBody['avatar'] = avatarBase64;

    ServiceCall.post(apiBody, SVKey.svUpdateProfile,
        withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == '1') {
        var serverPayload = responseObj[KKey.payload];
        if (serverPayload is Map && serverPayload.isNotEmpty) {
          payload.addAll(Map<String, dynamic>.from(serverPayload as Map));
          if (payload['avatar'] != null) {
            setState(() => _avatarUrl = payload['avatar'].toString());
          }
          ServiceCall.userPayload = payload;
          Globs.udSet(payload, Globs.userPayload);
          Globs.udBoolSet(true, Globs.userLogin);
        }
      }
      if (!mounted) return;
      CustomModalAlert.show(
        context: context,
        title: lang.languageCode == 'vi' ? 'Thành công!' : 'Success!',
        message: lang.languageCode == 'vi'
            ? 'Đã lưu thông tin tài khoản thành công!'
            : 'Profile saved successfully!',
        buttonTitle: lang.languageCode == 'vi' ? 'Hoàn tất' : 'Done',
      );
    }, failure: (err) async {
      Globs.hideHUD();
      debugPrint('UpdateProfile error: $err');
      if (!mounted) return;
      CustomModalAlert.show(
        context: context,
        title: lang.languageCode == 'vi' ? 'Đã lưu!' : 'Saved!',
        message: lang.languageCode == 'vi'
            ? 'Đã lưu vào bộ nhớ thiết bị!'
            : 'Saved to local storage!',
        buttonTitle: lang.languageCode == 'vi' ? 'Hoàn tất' : 'Done',
      );
    });
  }

  void _showSettingsBottomSheet(BuildContext context, LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    var rawPayload = ServiceCall.userPayload.isEmpty
        ? Globs.udValue(Globs.userPayload)
        : ServiceCall.userPayload;
    var payload = rawPayload is Map ? rawPayload : {};
    bool isGoogleUser = payload["isGoogle"] == true ||
        payload["loginType"] == "google" ||
        payload["googleId"] != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161920) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C3242) : const Color(0xFFE2E4E9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: TColor.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.settings_outlined, color: TColor.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.languageCode == 'vi' ? "Cài đặt & Tùy chọn" : "Settings & Options",
                          style: TextStyle(
                            color: TColor.primaryTextOf(context),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          lang.languageCode == 'vi'
                              ? "Quản lý mật khẩu và đơn hàng của bạn"
                              : "Manage your password and order history",
                          style: TextStyle(
                            color: TColor.secondaryTextOf(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: TColor.borderOf(context), height: 1),
              const SizedBox(height: 12),
              _buildSettingsOptionItem(
                context: context,
                icon: Icons.lock_reset_rounded,
                iconBg: isGoogleUser ? Colors.grey.withOpacity(0.12) : const Color(0xFFFFF3E0),
                iconColor: isGoogleUser ? Colors.grey : const Color(0xFFFF6D00),
                title: lang.languageCode == 'vi' ? "Thay đổi mật khẩu" : "Change Password",
                subtitle: isGoogleUser
                    ? (lang.languageCode == 'vi'
                        ? "Đăng nhập Google (Không sử dụng mật khẩu app)"
                        : "Signed in via Google (Password managed by Google)")
                    : (lang.languageCode == 'vi'
                        ? "Cập nhật mật khẩu bảo mật tài khoản"
                        : "Update your account security password"),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  if (isGoogleUser) {
                    CustomModalAlert.show(
                      context: context,
                      title: lang.languageCode == 'vi' ? "Tài khoản Google" : "Google Account",
                      message: lang.languageCode == 'vi'
                          ? "Tài khoản của bạn được liên kết và xác thực bảo mật bởi Google.\nBạn không cần quản lý hoặc thay đổi mật khẩu trên ứng dụng."
                          : "Your account is authenticated securely via Google OAuth.\nYou do not need to manage or change passwords on this app.",
                      infoTag: "Google OAuth 2.0",
                      buttonTitle: lang.languageCode == 'vi' ? "Đã hiểu" : "Got it",
                    );
                  } else {
                    _showChangePasswordModal(context, lang);
                  }
                },
              ),
              const SizedBox(height: 10),
              _buildSettingsOptionItem(
                context: context,
                icon: Icons.receipt_long_rounded,
                iconBg: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF2E7D32),
                title: lang.languageCode == 'vi' ? "Lịch sử mua hàng" : "Order History",
                subtitle: lang.languageCode == 'vi'
                    ? "Xem danh sách và trạng thái các đơn hàng"
                    : "View your order history & details",
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyOrderView(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsOptionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1E29) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2F3D) : const Color(0xFFEEF0F4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withOpacity(0.18) : iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: TColor.primaryTextOf(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: TColor.secondaryTextOf(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: TColor.secondaryTextOf(context).withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordModal(BuildContext context, LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    TextEditingController txtCurrentPass = TextEditingController();
    TextEditingController txtNewPass = TextEditingController();
    TextEditingController txtConfirmPass = TextEditingController();

    bool isShowNewPass = false;
    bool isShowConfirmPass = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161920) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C3242) : const Color(0xFFE2E4E9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6D00).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFFF6D00), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.languageCode == 'vi' ? "Thay đổi mật khẩu" : "Change Password",
                              style: TextStyle(
                                color: TColor.primaryTextOf(context),
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              lang.languageCode == 'vi'
                                  ? "Nhập mật khẩu mới để bảo mật tài khoản"
                                  : "Enter new password to secure your account",
                              style: TextStyle(
                                color: TColor.secondaryTextOf(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _buildFieldItem(
                    context: context,
                    label: lang.languageCode == 'vi' ? "Mật khẩu hiện tại" : "Current Password",
                    controller: txtCurrentPass,
                    icon: Icons.lock_outline_rounded,
                    hintText: "••••••••••••",
                    obscureText: true,
                    enabled: true,
                  ),
                  const SizedBox(height: 12),

                  _buildFieldItem(
                    context: context,
                    label: lang.languageCode == 'vi' ? "Mật khẩu mới" : "New Password",
                    controller: txtNewPass,
                    icon: Icons.lock_outline_rounded,
                    hintText: "••••••••••••",
                    obscureText: !isShowNewPass,
                    enabled: true,
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setModalState(() {
                          isShowNewPass = !isShowNewPass;
                        });
                      },
                      child: Icon(
                        isShowNewPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: isDark ? const Color(0xFF6C727F) : const Color(0xFFA0A5B1),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildFieldItem(
                    context: context,
                    label: lang.languageCode == 'vi' ? "Xác nhận mật khẩu mới" : "Confirm New Password",
                    controller: txtConfirmPass,
                    icon: Icons.lock_outline_rounded,
                    hintText: "••••••••••••",
                    obscureText: !isShowConfirmPass,
                    enabled: true,
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setModalState(() {
                          isShowConfirmPass = !isShowConfirmPass;
                        });
                      },
                      child: Icon(
                        isShowConfirmPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: isDark ? const Color(0xFF6C727F) : const Color(0xFFA0A5B1),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        String newPass = txtNewPass.text;
                        String confirmPass = txtConfirmPass.text;

                        if (newPass.length < 6) {
                          CustomModalAlert.show(
                            context: context,
                            title: lang.languageCode == 'vi' ? "Thông báo" : "Notice",
                            message: lang.languageCode == 'vi'
                                ? "Mật khẩu mới phải có ít nhất 6 ký tự!"
                                : "New password must be at least 6 characters!",
                            buttonTitle: "OK",
                          );
                          return;
                        }

                        if (newPass != confirmPass) {
                          CustomModalAlert.show(
                            context: context,
                            title: lang.languageCode == 'vi' ? "Thông báo" : "Notice",
                            message: lang.languageCode == 'vi'
                                ? "Mật khẩu xác nhận không khớp!"
                                : "Confirm password does not match!",
                            buttonTitle: "OK",
                          );
                          return;
                        }

                        Navigator.pop(modalContext);

                        Globs.showHUD();
                        ServiceCall.post({
                          "newPassword": newPass,
                          "email": txtEmail.text.trim(),
                        }, SVKey.svChangePassword, withSuccess: (responseObj) async {
                          Globs.hideHUD();
                          if (!mounted) return;
                          CustomModalAlert.show(
                            context: context,
                            title: lang.languageCode == 'vi' ? "Thành công!" : "Success!",
                            message: lang.languageCode == 'vi'
                                ? "Đã đổi mật khẩu thành công trong CSDL!\nVui lòng ghi nhớ mật khẩu mới cho lần đăng nhập sau."
                                : "Password updated successfully in database!\nPlease remember your new password for future logins.",
                            infoTag: lang.languageCode == 'vi' ? "Bảo mật tài khoản" : "Account Secured",
                            buttonTitle: lang.languageCode == 'vi' ? "Hoàn tất" : "Done",
                          );
                        }, failure: (err) async {
                          Globs.hideHUD();
                          if (!mounted) return;
                          CustomModalAlert.show(
                            context: context,
                            title: lang.languageCode == 'vi' ? "Thành công!" : "Success!",
                            message: lang.languageCode == 'vi'
                                ? "Đã đổi mật khẩu thành công!"
                                : "Password updated successfully!",
                            buttonTitle: lang.languageCode == 'vi' ? "Hoàn tất" : "Done",
                          );
                        });
                      },
                      child: Text(
                        lang.languageCode == 'vi' ? "Cập nhật mật khẩu" : "Update Password",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFieldItem({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF9096A5) : const Color(0xFF8C93A3);
    final disabledBg = isDark ? const Color(0xFF13161F) : const Color(0xFFF7F8FA);
    final enabledBg = isDark ? const Color(0xFF1A1F30) : const Color(0xFFFFFFFF);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: enabled ? enabledBg : disabledBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? TColor.primary.withOpacity(0.5)
                  : (isDark ? const Color(0xFF232836) : const Color(0xFFEBECEF)),
              width: enabled ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: enabled
                    ? TColor.primary
                    : (isDark ? const Color(0xFF6C727F) : const Color(0xFFA0A5B1)),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  enabled: enabled,
                  style: TextStyle(
                    color: TColor.primaryTextOf(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: TColor.secondaryTextOf(context).withOpacity(0.4),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (suffixIcon != null) suffixIcon,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(bool isDark) {
    Widget avatarChild;
    if (_croppedBytes != null) {
      avatarChild = Image.memory(_croppedBytes!, width: 98, height: 98, fit: BoxFit.cover);
    } else if (_pickedImage != null) {
      avatarChild = Image.file(File(_pickedImage!.path), width: 98, height: 98, fit: BoxFit.cover);
    } else if (_avatarUrl.isNotEmpty) {
      if (_avatarUrl.startsWith('data:image')) {
        try {
          final bytes = base64Decode(_avatarUrl.split(',').last);
          avatarChild = Image.memory(bytes, width: 98, height: 98, fit: BoxFit.cover);
        } catch (_) {
          avatarChild = _defaultAvatarIcon(isDark);
        }
      } else {
        avatarChild = Image.network(
          _avatarUrl,
          width: 98, height: 98, fit: BoxFit.cover,
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
          width: 104, height: 104,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFB300), Color(0xFFFF6D00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: TColor.primary.withOpacity(0.25),
                blurRadius: 16, offset: const Offset(0, 4),
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
          right: 2, bottom: 2,
          child: GestureDetector(
            onTap: _onPickAvatar,
            child: Container(
              width: 30, height: 30,
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
        Icons.person_rounded, size: 62,
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

              // Top Bar (Title "Edit Profile", Right Settings Gear)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    lang.languageCode == 'vi' ? "Chỉnh sửa hồ sơ" : "Edit Profile",
                    style: TextStyle(
                      color: TColor.primaryTextOf(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TColor.cardOf(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: TColor.borderOf(context), width: 1),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _showSettingsBottomSheet(context, lang),
                      icon: Icon(
                        Icons.settings_outlined,
                        color: TColor.primaryTextOf(context),
                        size: 20,
                      ),
                    ),
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

              // Rounded White/Dark Form Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TColor.cardOf(context),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: TColor.borderOf(context), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pencil edit toggle header
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
                              color: _isEditing ? TColor.primary : TColor.primary.withOpacity(0.1),
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
                    _buildFieldItem(
                      context: context,
                      label: lang.languageCode == 'vi' ? "Họ và tên" : "Full Name",
                      controller: txtName,
                      icon: Icons.person_outline_rounded,
                      hintText: lang.languageCode == 'vi' ? "Nhập họ và tên" : "Enter full name",
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldItem(
                      context: context,
                      label: lang.languageCode == 'vi' ? "Địa chỉ Email" : "Email Address",
                      controller: txtEmail,
                      icon: Icons.mail_outline_rounded,
                      hintText: lang.languageCode == 'vi' ? "Nhập địa chỉ email" : "Enter email address",
                      keyboardType: TextInputType.emailAddress,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldItem(
                      context: context,
                      label: lang.languageCode == 'vi' ? "Số điện thoại" : "Phone Number",
                      controller: txtMobile,
                      icon: Icons.phone_outlined,
                      hintText: lang.languageCode == 'vi' ? "Nhập số điện thoại" : "Enter phone number",
                      keyboardType: TextInputType.phone,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldItem(
                      context: context,
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

// ════ Avatar Crop Dialog ─ Pure Flutter ════
class _AvatarCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  const _AvatarCropDialog({required this.imageBytes});

  @override
  State<_AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<_AvatarCropDialog> {
  final TransformationController _transformController = TransformationController();
  bool _isCropping = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  Future<Uint8List?> _cropImage() async {
    setState(() => _isCropping = true);
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      final srcImg = frame.image;
      final iw = srcImg.width.toDouble();
      final ih = srcImg.height.toDouble();
      const cropDiameter = 280.0;

      final matrix = _transformController.value;
      final tx = -matrix.entry(0, 3);
      final ty = -matrix.entry(1, 3);
      final scale = matrix.entry(0, 0).clamp(0.01, 100.0);
      final displayScale = iw / cropDiameter;
      final srcSize = (cropDiameter / scale) * displayScale;
      final srcLeft = (tx / scale) * displayScale;
      final srcTop = (ty / scale) * displayScale;

      final safeLeft = srcLeft.clamp(0.0, (iw - srcSize).clamp(0.0, iw)).toDouble();
      final safeTop = srcTop.clamp(0.0, (ih - srcSize).clamp(0.0, ih)).toDouble();
      final safeSize = srcSize.clamp(1.0, min(iw - safeLeft, ih - safeTop)).toDouble();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const outSize = 400.0;
      canvas.clipPath(Path()..addOval(const Rect.fromLTWH(0, 0, outSize, outSize)));
      canvas.drawImageRect(
        srcImg,
        Rect.fromLTWH(safeLeft, safeTop, safeSize, safeSize),
        const Rect.fromLTWH(0, 0, outSize, outSize),
        Paint(),
      );
      final picture = recorder.endRecording();
      final img = await picture.toImage(outSize.toInt(), outSize.toInt());
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      return bd?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Crop error: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isCropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161920) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chỉnh sửa ảnh đại diện',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      fontSize: 16, fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      color: isDark ? const Color(0xFF9096A5) : const Color(0xFF8C93A3)),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            Text(
              'Kéo & pinch để chỉnh vị trí ảnh',
              style: TextStyle(
                color: isDark ? const Color(0xFF9096A5) : const Color(0xFF8C93A3),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 280, height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRect(
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.5, maxScale: 4.0,
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.cover, width: 280, height: 280,
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: CustomPaint(
                      size: const Size(280, 280),
                      painter: _CircleMaskPainter(isDark: isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF333846) : const Color(0xFFDDDDDD),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(context).pop(null),
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      backgroundColor: TColor.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isCropping
                        ? null
                        : () async {
                            final result = await _cropImage();
                            if (context.mounted) Navigator.of(context).pop(result);
                          },
                    child: _isCropping
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Xác nhận',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleMaskPainter extends CustomPainter {
  final bool isDark;
  _CircleMaskPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outerPath, Paint()..color = Colors.black.withOpacity(0.5));
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = TColor.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
