class TransactionModel {
  final String id;
  final String userId;
  final String type; // 'income' | 'expense' | 'transfer' | 'exchange'
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  // Hamyon: joy (naqd/karta) va valyuta (UZS/USD).
  // Kirim/chiqim uchun — bu yagona hamyon (manba).
  // O'tkazma/ayirboshlash uchun — manba hamyon.
  final String place; // 'cash' | 'card'
  final String currency; // 'UZS' | 'USD'

  // Faqat o'tkazma/ayirboshlashda to'ldiriladi — qabul qiluvchi hamyon.
  final String? toPlace;
  final String? toCurrency;
  final double? toAmount;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    required this.note,
    this.place = 'cash',
    this.currency = 'UZS',
    this.toPlace,
    this.toCurrency,
    this.toAmount,
  });

  /// Hisoblar orasidagi harakatmi (o'tkazma yoki ayirboshlash).
  bool get isMovement => type == 'transfer' || type == 'exchange';

  // Hive (lokal) uchun
  Map<String, dynamic> toSqlite() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
        'place': place,
        'currency': currency,
        'to_place': toPlace,
        'to_currency': toCurrency,
        'to_amount': toAmount,
      };

  factory TransactionModel.fromSqlite(Map<String, dynamic> map) =>
      TransactionModel(
        id: map['id'],
        userId: map['user_id'] ?? '',
        type: map['type'],
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] ?? '',
        date: DateTime.parse(map['date']),
        note: map['note'] ?? '',
        place: map['place'] ?? 'cash',
        currency: map['currency'] ?? 'UZS',
        toPlace: map['to_place'],
        toCurrency: map['to_currency'],
        toAmount: (map['to_amount'] as num?)?.toDouble(),
      );
}
