import 'dart:io';

import 'package:flutter/material.dart';
import 'package:food_delivery/common/globs.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/common_widget/round_button.dart';
import 'package:image_picker/image_picker.dart';

import '../../common/color_extension.dart';
import '../../common_widget/round_textfield.dart';
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
  TextEditingController txtPassword = TextEditingController();
  TextEditingController txtConfirmPassword = TextEditingController();

  String displayGreeting = "Xin chào!";

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

    var userObj = payload["user"] as Map? ?? payload;
    var khachHangObj = payload["khachHang"] as Map? ?? payload;

    String name = khachHangObj["hoTen"]?.toString() ??
        payload["fullName"]?.toString() ??
        payload["name"]?.toString() ??
        userObj["tenDangNhap"]?.toString() ??
        "";
    String email = khachHangObj["email"]?.toString() ??
        payload["email"]?.toString() ??
        userObj["tenDangNhap"]?.toString() ??
        "";
    String phone = khachHangObj["sdt"]?.toString() ??
        payload["phone"]?.toString() ??
        payload["mobile"]?.toString() ??
        "";
    String address = khachHangObj["diaChi"]?.toString() ??
        payload["address"]?.toString() ??
        "";

    txtName.text = name;
    txtEmail.text = email;
    txtMobile.text = phone;
    txtAddress.text = address;

    if (name.isNotEmpty) {
      displayGreeting = "Xin chào, $name!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(
            height: 46,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Thông tin cá nhân",
                  style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyOrderView()));
                  },
                  icon: Image.asset(
                    "assets/img/shopping_cart.png",
                    width: 25,
                    height: 25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: TColor.placeholder,
              borderRadius: BorderRadius.circular(50),
            ),
            alignment: Alignment.center,
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image.file(File(image!.path),
                        width: 100, height: 100, fit: BoxFit.cover),
                  )
                : Icon(
                    Icons.person,
                    size: 65,
                    color: TColor.secondaryText,
                  ),
          ),
          TextButton.icon(
            onPressed: () async {
              image = await picker.pickImage(source: ImageSource.gallery);
              setState(() {});
            },
            icon: Icon(
              Icons.edit,
              color: TColor.primary,
              size: 12,
            ),
            label: Text(
              "Đổi ảnh đại diện",
              style: TextStyle(color: TColor.primary, fontSize: 12),
            ),
          ),
          Text(
            displayGreeting,
            style: TextStyle(
                color: TColor.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          TextButton(
            onPressed: () {
              ServiceCall.showLogoutDialog(context);
            },
            child: Text(
              "Đăng xuất",
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: RoundTitleTextfield(
              title: "Họ và tên",
              hintText: "Nhập họ tên",
              controller: txtName,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: RoundTitleTextfield(
              title: "Email",
              hintText: "Nhập email",
              keyboardType: TextInputType.emailAddress,
              controller: txtEmail,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: RoundTitleTextfield(
              title: "Số điện thoại",
              hintText: "Nhập số điện thoại",
              controller: txtMobile,
              keyboardType: TextInputType.phone,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: RoundTitleTextfield(
              title: "Địa chỉ",
              hintText: "Nhập địa chỉ",
              controller: txtAddress,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: RoundTitleTextfield(
              title: "Mật khẩu mới",
              hintText: "* * * * * *",
              obscureText: true,
              controller: txtPassword,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
            child: RoundTitleTextfield(
              title: "Xác nhận mật khẩu",
              hintText: "* * * * * *",
              obscureText: true,
              controller: txtConfirmPassword,
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RoundButton(
              title: "Lưu thay đổi",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã lưu thông tin tài khoản thành công!")),
                );
              },
            ),
          ),
          const SizedBox(
            height: 20,
          ),
        ]),
      ),
    ));
  }
}
