import 'package:cloud_firestore/cloud_firestore.dart';

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

  final bool isSynced; // Firebase ga sync bo'lganmi

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
    this.isSynced = false,
  });

  /// Hisoblar orasidagi harakatmi (o'tkazma yoki ayirboshlash).
  bool get isMovement => type == 'transfer' || type == 'exchange';

  // SQLite (Hive) uchun
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
        'is_synced': isSynced ? 1 : 0,
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
        isSynced: map['is_synced'] == 1,
      );

  // Firebase uchun
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'type': type,
        'amount': amount,
        'category': category,
        'date': Timestamp.fromDate(date),
        'note': note,
        'place': place,
        'currency': currency,
        'toPlace': toPlace,
        'toCurrency': toCurrency,
        'toAmount': toAmount,
      };

  factory TransactionModel.fromFirestore(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      TransactionModel(
        id: doc.id,
        userId: doc.data()?['userId'] ?? '',
        type: doc.data()?['type'] ?? 'expense',
        amount: (doc.data()?['amount'] as num).toDouble(),
        category: doc.data()?['category'] ?? '',
        date: (doc.data()?['date'] as Timestamp).toDate(),
        note: doc.data()?['note'] ?? '',
        place: doc.data()?['place'] ?? 'cash',
        currency: doc.data()?['currency'] ?? 'UZS',
        toPlace: doc.data()?['toPlace'],
        toCurrency: doc.data()?['toCurrency'],
        toAmount: (doc.data()?['toAmount'] as num?)?.toDouble(),
        isSynced: true,
      );

  TransactionModel copyWith({bool? isSynced}) => TransactionModel(
        id: id,
        userId: userId,
        type: type,
        amount: amount,
        category: category,
        date: date,
        note: note,
        place: place,
        currency: currency,
        toPlace: toPlace,
        toCurrency: toCurrency,
        toAmount: toAmount,
        isSynced: isSynced ?? this.isSynced,
      );
}
