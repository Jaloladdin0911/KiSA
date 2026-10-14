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

  /// Oylik to'lovning asl kuni (1..31). Qisqa oylarda oyning oxirgi kuniga
  /// tushadi, keyingi oyda yana asl kunga qaytadi (31-yan → 28-fev → 31-mar).
  final int anchorDay;

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
    int? anchorDay,
  }) : anchorDay = anchorDay ?? nextDate.day;

  /// Keyingi takrorlanish sanasi.
  DateTime advance(DateTime from) {
    switch (frequency) {
      case 'daily':
        return DateTime(from.year, from.month, from.day + 1);
      case 'weekly':
        return DateTime(from.year, from.month, from.day + 7);
      default: // monthly
        // DateTime(y, m + 2, 0) — keyingi oyning oxirgi kuni
        final lastDay = DateTime(from.year, from.month + 2, 0).day;
        final day = anchorDay < lastDay ? anchorDay : lastDay;
        return DateTime(from.year, from.month + 1, day);
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
        'anchorDay': anchorDay,
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
        anchorDay: m['anchorDay'] as int?,
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
        anchorDay: anchorDay,
      );
}
