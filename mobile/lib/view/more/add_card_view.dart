import 'package:flutter/material.dart';
import 'package:food_route/common/color_extension.dart';
import 'package:food_route/common/format_utils.dart';
import 'package:food_route/common_widget/round_icon_button.dart';
import 'package:food_route/common_widget/round_textfield.dart';

class AddCardView extends StatefulWidget {
  const AddCardView({super.key});

  @override
  State<AddCardView> createState() => _AddCardViewState();
}

class _AddCardViewState extends State<AddCardView> {
  TextEditingController txtCardNumber = TextEditingController();
  TextEditingController txtCardMonth = TextEditingController();
  TextEditingController txtCardYear = TextEditingController();
  TextEditingController txtCardCode = TextEditingController();
  TextEditingController txtFirstName = TextEditingController();
  TextEditingController txtLastName = TextEditingController();
  bool isAnyTime = false;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return  Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        width: media.width,
        decoration: BoxDecoration(
            color: TColor.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.addCardTitle,
                  style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.close,
                    color: TColor.primaryText,
                    size: 25,
                  ),
                )
              ],
            ),
            Divider(
              color: TColor.secondaryText.withValues(alpha: 0.4),
              height: 1,
            ),
            const SizedBox(
              height: 15,
            ),
            RoundTextfield(
              hintText: context.l10n.addCardNumberHint,
              controller: txtCardNumber,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(
              height: 15,
            ),
            Row(
              children: [
                Text(
                  context.l10n.addCardExpiryLabel,
                  style: TextStyle(
                      color: TColor.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  child: RoundTextfield(
                    hintText: context.l10n.addCardMonthHint,
                    controller: txtCardMonth,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 25),
                SizedBox(
                  width: 100,
                  child: RoundTextfield(
                    hintText: context.l10n.addCardYearHint,
                    controller: txtCardYear,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            RoundTextfield(
              hintText: context.l10n.addCardSecurityCodeHint,
              controller: txtCardCode,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(
              height: 15,
            ),
            RoundTextfield(
              hintText: context.l10n.addCardFirstNameHint,
              controller: txtFirstName,
            ),
            const SizedBox(
              height: 15,
            ),
            RoundTextfield(
              hintText: context.l10n.addCardLastNameHint,
              controller: txtLastName,
            ),
            const SizedBox(
              height: 15,
            ),
            Row(children: [
              Expanded(
                child: Text(
                  context.l10n.addCardRemoveAnytime,
                  style: TextStyle(
                      color: TColor.secondaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Switch(
                  value: isAnyTime,
                  activeColor: TColor.primary,
                  onChanged: (newVal) {
                    setState(() {
                      isAnyTime = newVal;
                    });
                  })
            ]),
            const SizedBox(
              height: 25,
            ),
            RoundIconButton(
                title: context.l10n.addCardButton,
                icon: "assets/img/add.png",
                color: TColor.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                onPressed: () {}),
            const SizedBox(
              height: 25,
            ),
          ],
        ),
      
    );
  }
}
