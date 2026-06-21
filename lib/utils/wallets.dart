import 'package:flutter/material.dart';

/// Hamyon tizimi — joy (naqd/karta) × valyuta (so'm/dollar).
/// Jami 4 hamyon: naqd so'm, naqd $, karta so'm, karta $.
class Wallets {
  Wallets._();

  static const cash = 'cash';
  static const card = 'card';
  static const places = [cash, card];

  static const uzs = 'UZS';
  static const usd = 'USD';
  static const currencies = [uzs, usd];

  static IconData placeIcon(String place) =>
      place == card ? Icons.credit_card_rounded : Icons.payments_rounded;

  /// Joy nomi uchun l10n kaliti.
  static String placeKey(String place) =>
      place == card ? 'wallet_card' : 'wallet_cash';

  static IconData currencyIcon(String currency) =>
      currency == usd ? Icons.attach_money_rounded : Icons.money_rounded;
}
