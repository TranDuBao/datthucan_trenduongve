import 'package:flutter/material.dart';

class TColor {
  static Color get primary => const Color(0xffFC6011);
  static Color get primaryText => const Color(0xff4A4B4D);
  static Color get secondaryText => const Color(0xff7C7D7E);
  static Color get textfield => const Color(0xffF2F2F2);
  static Color get placeholder => const Color(0xffB6B7B7);
  static Color get white => const Color(0xffffffff);

  // Theme-aware dynamic getters matching ultra-premium Dark Mode
  static Color primaryTextOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xffFFFFFF)
        : const Color(0xff4A4B4D);
  }

  static Color secondaryTextOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff9E9EA0)
        : const Color(0xff7C7D7E);
  }

  static Color bgOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff0D0F14)
        : const Color(0xffF6F6F6);
  }

  static Color cardOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff171B26)
        : const Color(0xffFFFFFF);
  }

  static Color borderOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff232836)
        : const Color(0xffEFEFEF);
  }

  static Color textfieldOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff171B26)
        : const Color(0xffF2F2F2);
  }

  static Color navBgOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xff11141D)
        : const Color(0xffFFFFFF);
  }
}