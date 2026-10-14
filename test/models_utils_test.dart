import 'package:flutter_test/flutter_test.dart';
import 'package:kisa/models/recurring_model.dart';
import 'package:kisa/utils/formatters.dart';

RecurringModel _monthly(DateTime start) => RecurringModel(
      id: '1',
      type: 'expense',
      amount: 100,
      category: 'Boshqa',
      place: 'card',
      currency: 'UZS',
      note: '',
      frequency: 'monthly',
      nextDate: start,
    );

void main() {
  group('Money.parse', () {
    test('plain() natijasini qayta o\'qiy oladi (U+202F ajratuvchi)', () {
      expect(Money.parse(Money.plain(1270000)), 1270000);
      expect(Money.parse(Money.plain(1500.5, currency: 'USD')), 1500.5);
    });

    test('oddiy, NBSP bo\'shliq va vergulli kasr', () {
      expect(Money.parse('1 250 000'), 1250000);
      expect(Money.parse('1 250'), 1250);
      expect(Money.parse('12,5'), 12.5);
    });

    test('bo\'sh yoki noto\'g\'ri matn', () {
      expect(Money.parse(''), isNull);
      expect(Money.parse('   '), isNull);
      expect(Money.parse('abc'), isNull);
    });
  });

  group('RecurringModel.advance (monthly)', () {
    test('31-sana qisqa oyda oxirgi kunga tushadi va keyin qaytadi', () {
      final r = _monthly(DateTime(2026, 1, 31));
      final feb = r.advance(DateTime(2026, 1, 31));
      expect(feb, DateTime(2026, 2, 28));
      final mar = r.copyWith(nextDate: feb).advance(feb);
      expect(mar, DateTime(2026, 3, 31));
      expect(r.advance(mar), DateTime(2026, 4, 30));
    });

    test('kabisa yili', () {
      final r = _monthly(DateTime(2028, 1, 30));
      expect(r.advance(DateTime(2028, 1, 30)), DateTime(2028, 2, 29));
    });

    test('dekabrdan yanvarga o\'tish', () {
      final r = _monthly(DateTime(2026, 12, 15));
      expect(r.advance(DateTime(2026, 12, 15)), DateTime(2027, 1, 15));
    });

    test('anchorDay JSON orqali saqlanadi; eski yozuvda nextDate kunidan', () {
      final r = _monthly(DateTime(2026, 1, 31)).copyWith(
        nextDate: DateTime(2026, 2, 28),
      );
      final back = RecurringModel.fromJson(r.toJson());
      expect(back.anchorDay, 31);

      final legacy = r.toJson()..remove('anchorDay');
      expect(RecurringModel.fromJson(legacy).anchorDay, 28);
    });
  });

  group('Money.format', () {
    test('so\'m va dollar', () {
      expect(Money.format(-1250000, 'UZS'), '−1 250 000 so\'m');
      expect(Money.format(1250.5, 'USD'), '\$1 250.50');
    });
  });
}
