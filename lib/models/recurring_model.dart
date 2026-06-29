/// Takroriy to'lov shabloni (oylik maosh, ijara, obuna...).
/// Ilova ochilganda muddati kelganlari avtomatik tranzaksiyaga aylanadi.
class RecurringModel {
  final String id;
  final String type; // 'income' | 'expense'
  final double amount;
  final String category;
  final String place; // 'cash' | 'card'
  final String currency; // 'UZS' | 'USD'
  final String note;
  final String frequency; // 'daily' | 'weekly' | 'monthly'
  final DateTime nextDate;

  RecurringModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.place,
    required this.currency,
    required this.note,
    required this.frequency,
    required this.nextDate,
  });

  /// Keyingi takrorlanish sanasi.
  DateTime advance(DateTime from) {
    switch (frequency) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        return from.add(const Duration(days: 7));
      default: // monthly
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'category': category,
        'place': place,
        'currency': currency,
        'note': note,
        'frequency': frequency,
        'nextDate': nextDate.toIso8601String(),
      };

  factory RecurringModel.fromJson(Map<String, dynamic> m) => RecurringModel(
        id: m['id'],
        type: m['type'] ?? 'expense',
        amount: (m['amount'] as num).toDouble(),
        category: m['category'] ?? 'Boshqa',
        place: m['place'] ?? 'card',
        currency: m['currency'] ?? 'UZS',
        note: m['note'] ?? '',
        frequency: m['frequency'] ?? 'monthly',
        nextDate: DateTime.parse(m['nextDate']),
      );

  RecurringModel copyWith({DateTime? nextDate}) => RecurringModel(
        id: id,
        type: type,
        amount: amount,
        category: category,
        place: place,
        currency: currency,
        note: note,
        frequency: frequency,
        nextDate: nextDate ?? this.nextDate,
      );
}
