import 'dart:io';

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
  XFile? image;

  TextEditingController txtName = TextEditingController();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtMobile = TextEditingController();
  TextEditingController txtAddress = TextEditingController();

  String userName = "Alex Johnson";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    var payload = ServiceCall.userPayload;
    if (payload.isEmpty) {
      payload = Globs.udValue(Globs.userPayload);
    }
    if (payload.isNotEmpty) {
      ServiceCall.userPayload = payload;
      Globs.udBoolSet(true, Globs.userLogin);
    }

    var userObj = payload["user"] as Map? ?? payload;
    var khachHangObj = payload["khachHang"] as Map? ?? payload;

    String name = khachHangObj["hoTen"]?.toString() ??
        payload["fullName"]?.toString() ??
        payload["name"]?.toString() ??
        userObj["tenDangNhap"]?.toString() ??
        "Alex Johnson";
    String email = khachHangObj["email"]?.toString() ??
        payload["email"]?.toString() ??
        userObj["tenDangNhap"]?.toString() ??
        "alex.johnson@example.com";
    String phone = khachHangObj["sdt"]?.toString() ??
        payload["phone"]?.toString() ??
        payload["mobile"]?.toString() ??
        "+1 (555) 382-9910";
    String address = khachHangObj["diaChi"]?.toString() ??
        payload["address"]?.toString() ??
        "742 Evergreen Terrace, Suite 4";

    txtName.text = name;
    txtEmail.text = email;
    txtMobile.text = phone;
    txtAddress.text = address;
    userName = name;
  }

  void _saveProfile(LanguageProvider lang) {
    String name = txtName.text.trim();
    String email = txtEmail.text.trim();
    String phone = txtMobile.text.trim();
    String address = txtAddress.text.trim();

    if (name.isEmpty) {
      CustomModalAlert.show(
        context: context,
        title: lang.languageCode == 'vi' ? "Thông báo" : "Notice",
        message: lang.languageCode == 'vi' ? "Vui lòng nhập họ và tên!" : "Please enter full name!",
        buttonTitle: "OK",
      );
      return;
    }

    var rawPayload = ServiceCall.userPayload.isEmpty
        ? Globs.udValue(Globs.userPayload)
        : ServiceCall.userPayload;
    var payload = Map<String, dynamic>.from(rawPayload is Map ? rawPayload : {});

    payload["fullName"] = name;
    payload["name"] = name;
    payload["email"] = email;
    payload["phone"] = phone;
    payload["mobile"] = phone;
    payload["address"] = address;

    if (payload["user"] is Map) {
      var userMap = Map<String, dynamic>.from(payload["user"]);
      userMap["fullName"] = name;
      userMap["email"] = email;
      userMap["phone"] = phone;
      userMap["address"] = address;
      payload["user"] = userMap;
    }

    if (payload["khachHang"] is Map) {
      var khMap = Map<String, dynamic>.from(payload["khachHang"]);
      khMap["hoTen"] = name;
      khMap["email"] = email;
      khMap["sdt"] = phone;
      khMap["diaChi"] = address;
      payload["khachHang"] = khMap;
    }

    // 1. Save local state & flag user login active so reload persists
    ServiceCall.userPayload = payload;
    Globs.udSet(payload, Globs.userPayload);
    Globs.udBoolSet(true, Globs.userLogin);

    setState(() {
      userName = name;
    });

    // 2. Persist directly to backend database
    Globs.showHUD();
    ServiceCall.post({
      "userId": payload["id"] ?? payload["maTaiKhoan"] ?? 1,
      "fullName": name,
      "name": name,
      "email": email,
      "phone": phone,
      "sdt": phone,
      "address": address,
      "diaChi": address,
    }, SVKey.svUpdateProfile, withSuccess: (responseObj) async {
      Globs.hideHUD();
      if (responseObj[KKey.status] == "1") {
        var serverPayload = responseObj[KKey.payload];
        if (serverPayload is Map && serverPayload.isNotEmpty) {
          payload.addAll(Map<String, dynamic>.from(serverPayload));
          ServiceCall.userPayload = payload;
          Globs.udSet(payload, Globs.userPayload);
          Globs.udBoolSet(true, Globs.userLogin);
        }
      }
      if (!mounted) return;
      CustomModalAlert.show(
        context: context,
        title: lang.languageCode == 'vi' ? "Thành công!" : "Success!",
        message: lang.languageCode == 'vi'
            ? "Đã lưu thông tin tài khoản vào cơ sở dữ liệu!\nThông tin của bạn đã được cập nhật an toàn."
            : "Profile details saved to database successfully!\nYour details have been updated on system.",
        infoTag: lang.languageCode == 'vi' ? "Đã lưu vào Cơ sở dữ liệu" : "Saved to Database",
        buttonTitle: lang.languageCode == 'vi' ? "Hoàn tất" : "Complete",
      );
    }, failure: (err) async {
      Globs.hideHUD();
      if (!mounted) return;
      CustomModalAlert.show(
        context: context,
        title: lang.languageCode == 'vi' ? "Thành công!" : "Success!",
        message: lang.languageCode == 'vi'
            ? "Đã lưu thông tin bộ nhớ thiết bị thành công!"
            : "Saved profile info to local storage!",
        infoTag: lang.languageCode == 'vi' ? "Đã lưu bộ nhớ thiết bị" : "Saved Locally",
        buttonTitle: lang.languageCode == 'vi' ? "Hoàn tất" : "Complete",
      );
    });
  }

  void _showSettingsBottomSheet(BuildContext context, LanguageProvider lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                iconBg: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFFF6D00),
                title: lang.languageCode == 'vi' ? "Thay đổi mật khẩu" : "Change Password",
                subtitle: lang.languageCode == 'vi'
                    ? "Cập nhật mật khẩu bảo mật tài khoản"
                    : "Update your account security password",
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _showChangePasswordModal(context, lang);
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
                  ),
                  const SizedBox(height: 12),

                  _buildFieldItem(
                    context: context,
                    label: lang.languageCode == 'vi' ? "Mật khẩu mới" : "New Password",
                    controller: txtNewPass,
                    icon: Icons.lock_outline_rounded,
                    hintText: "••••••••••••",
                    obscureText: !isShowNewPass,
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
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFF9096A5) : const Color(0xFF8C93A3);

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
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF13161F) : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF232836) : const Color(0xFFEBECEF),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDark ? const Color(0xFF6C727F) : const Color(0xFFA0A5B1),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
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

              // Avatar Header with Golden Ring & Camera Edit Badge
              Stack(
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
                          color: TColor.primary.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: image != null
                          ? Image.file(
                              File(image!.path),
                              width: 98,
                              height: 98,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: isDark ? const Color(0xFF232836) : const Color(0xFFEAEBED),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.person_rounded,
                                size: 62,
                                color: isDark ? const Color(0xFF6C727F) : const Color(0xFFA0A5B1),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: GestureDetector(
                      onTap: () async {
                        image = await picker.pickImage(source: ImageSource.gallery);
                        setState(() {});
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: TColor.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF171B26) : Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // User Name Title
              Text(
                userName,
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
                    _buildFieldItem(
                      context: context,
                      label: lang.languageCode == 'vi' ? "Họ và tên" : "Full Name",
                      controller: txtName,
                      icon: Icons.person_outline_rounded,
                      hintText: "Enter full name",
                    ),
                    const SizedBox(height: 14),

                    _buildFieldItem(
                      context: context,
                      label: lang.languageCode == 'vi' ? "Địa chỉ Email" : "Email Address",
                      controller: txtEmail,
                      icon: Icons.mail_outline_rounded,
                      hintText: "Enter email address",
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldItem(
                      context: context,
                      label: lang.languageCode == 'vi' ? "Số điện thoại" : "Phone Number",
                      controller: txtMobile,
                      icon: Icons.phone_outlined,
                      hintText: "Enter phone number",
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    _buildFieldItem(
                      context: context,
                      label: lang.languageCode == 'vi' ? "Địa chỉ giao hàng" : "Delivery Address",
                      controller: txtAddress,
                      icon: Icons.location_on_outlined,
                      hintText: "Enter delivery address",
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
