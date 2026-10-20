import 'package:flutter/material.dart';
import '../common_widget/custom_modal_alert.dart';

extension StateExtension on State {
  void mdShowAlert(
    String title,
    String message,
    VoidCallback onPressed, {
    String buttonTitle = "Hoàn tất",
    TextAlign messageTextAlign = TextAlign.center,
    bool isError = true,
    String? infoTag,
  }) {
    CustomModalAlert.show(
      context: context,
      title: title,
      message: message,
      buttonTitle: buttonTitle,
      isError: isError,
      infoTag: infoTag,
      onConfirm: onPressed,
    );
  }

  void endEditing() {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}

extension StringExtension on String {
  bool get isEmail {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(this);
  }
}
