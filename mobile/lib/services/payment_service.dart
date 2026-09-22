import 'dart:convert';
import '../common/globs.dart';

class PaymentMethodModel {
  final String id;
  final String cardType;
  final String cardNumber;
  final String expiryDate;
  final String bankName;
  final bool isDefault;

  PaymentMethodModel({
    required this.id,
    required this.cardType,
    required this.cardNumber,
    required this.expiryDate,
    this.bankName = '',
    this.isDefault = false,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] ?? '',
      cardType: json['cardType'] ?? 'VISA',
      cardNumber: json['cardNumber'] ?? '',
      expiryDate: json['expiryDate'] ?? '',
      bankName: json['bankName'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardType': cardType,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'bankName': bankName,
      'isDefault': isDefault,
    };
  }
}

class PaymentService {
  static const String _storageKey = "saved_user_payment_cards";

  static Future<List<PaymentMethodModel>> getSavedPaymentMethods() async {
    try {
      final jsonStr = Globs.udValueString(_storageKey);
      if (jsonStr.isNotEmpty) {
        final List<dynamic> list = json.decode(jsonStr);
        return list.map((item) => PaymentMethodModel.fromJson(item)).toList();
      }
    } catch (_) {}

    // STRICT RULE: No hardcoded fake data! Return empty list if no cards saved in DB/Session.
    return [];
  }

  static Future<void> savePaymentMethods(List<PaymentMethodModel> cards) async {
    final list = cards.map((c) => c.toJson()).toList();
    Globs.udStringSet(json.encode(list), _storageKey);
  }

  static Future<void> addCard(PaymentMethodModel card) async {
    final list = await getSavedPaymentMethods();
    list.add(card);
    await savePaymentMethods(list);
  }

  static Future<void> deleteCard(String cardId) async {
    final list = await getSavedPaymentMethods();
    list.removeWhere((c) => c.id == cardId);
    await savePaymentMethods(list);
  }
}
